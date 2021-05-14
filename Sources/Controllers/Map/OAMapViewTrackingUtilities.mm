//
//  OAMapViewTrackingUtilities.m
//  OsmAnd
//
//  Created by Alexey Kulish on 25/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAMapViewTrackingUtilities.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAMapRendererView.h"
#import "OAMapViewController.h"
#import "OAAutoObserverProxy.h"
#import "OARoutingHelper.h"
#import "OATargetPointsHelper.h"
#import "Localization.h"
#import "OATargetPointView.h"
#import "OARootViewController.h"
#import "OANativeUtilities.h"

#include <commonOsmAndCore.h>

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/QKeyValueIterator.h>

@interface OAMapViewTrackingUtilities ()

@end

@implementation OAMapViewTrackingUtilities
{
    NSTimeInterval _lastTimeAutoZooming;
    OAMapViewController *_mapViewController;
    OAMapRendererView *_mapView;
    OAAppSettings *_settings;
    OsmAndAppInstance _app;
    BOOL _followingMode;
    BOOL _routePlanningMode;
    BOOL _isUserZoomed;
    BOOL _showRouteFinishDialog;
    BOOL _drivingRegionUpdated;
    
    OAAutoObserverProxy *_locationServicesStatusObserver;
    OAAutoObserverProxy *_locationServicesUpdateObserver;
    OAAutoObserverProxy *_mapModeObserver;
    
    OAMapMode _lastMapMode;
    bool _lastPositionTrackStateCaptured;
    float _lastAzimuthInPositionTrack;
    float _lastZoom;
    float _lastElevationAngle;
    
    BOOL _isIn3dMode;
    BOOL _forceZoom;
    
    NSTimeInterval _startChangingMapModeTime;
}

+ (OAMapViewTrackingUtilities *)instance
{
    static dispatch_once_t once;
    static OAMapViewTrackingUtilities * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _lastTimeAutoZooming = 0;
        _showViewAngle = NO;
        _isUserZoomed = NO;
        _showRouteFinishDialog = NO;
        _drivingRegionUpdated = NO;
        _movingToMyLocation = NO;
        
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _myLocation = _app.locationServices.lastKnownLocation;

        _lastPositionTrackStateCaptured = false;
        if ([[NSUserDefaults standardUserDefaults] objectForKey:kUDLastMapModePositionTrack])
        {
            OAMapMode mapMode = (OAMapMode)[[NSUserDefaults standardUserDefaults] integerForKey:kUDLastMapModePositionTrack];
            if (mapMode == OAMapModeFollow)
            {
                _lastAzimuthInPositionTrack = 0.0f;
                _lastZoom = kMapModePositionTrackingDefaultZoom;
                _lastElevationAngle = kMapModePositionTrackingDefaultElevationAngle;
                _lastPositionTrackStateCaptured = true;
            }
        }
        
        _lastMapMode = _app.mapMode;

        _mapModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                     withHandler:@selector(onMapModeChanged)
                                                      andObserve:_app.mapModeObservable];

        _locationServicesStatusObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(onLocationServicesStatusChanged)
                                                                     andObserve:_app.locationServices.statusObservable];

        _locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(onLocationServicesUpdate)
                                                                     andObserve:_app.locationServices.updateObserver];

        //addTargetPointListener(app);
        //addMapMarkersListener(app);
        //[[OARoutingHelper sharedInstance] addListener:self];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMapGestureAction:) name:kNotificationMapGestureAction object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProfileSettingSet:) name:kNotificationSetProfileSetting object:nil];
    }
    return self;
}

- (void) onMapModeChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_mapViewController || ![_mapViewController isViewLoaded])
            return;
        
        _startChangingMapModeTime = CACurrentMediaTime();
        
        CLLocation* newLocation = _app.locationServices.lastKnownLocation;
        CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;
        
        int currentMapRotation = [_settings.rotateMap get];
        CLLocationDirection direction = [self calculateDirectionWithLocation:newLocation heading:newHeading applyViewAngleVisibility:YES];
        BOOL autoZoomMap = [_settings.autoZoomMap get];
        BOOL forceZoom = _forceZoom;
        _forceZoom = NO;
        
        if (currentMapRotation == ROTATE_MAP_NONE && direction < 0)
            direction = 0;
        
        switch (_app.mapMode)
        {
            case OAMapModeFree:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setMapLinkedToLocation:NO];
                    if (![_settings.settingAllow3DView get] && _mapView.elevationAngle != kMapModePositionTrackingDefaultElevationAngle)
                    {
                        _isIn3dMode = NO;
                        _lastElevationAngle = kMapModePositionTrackingDefaultElevationAngle;
                        [_mapView setElevationAngle:kMapModePositionTrackingDefaultElevationAngle];
                    }
                    
                });
                break;
            }
            case OAMapModePositionTrack:
            {
                if (_lastMapMode == OAMapModeFollow)
                    _isIn3dMode = NO;
                
                if (newLocation)
                {
                    // Fly to last-known position without changing anything but target
                    
                    _mapView.animator->pause();
                    _mapView.animator->cancelAllAnimations();
                    
                    OsmAnd::PointI newTarget31(
                                               OsmAnd::Utilities::get31TileNumberX(newLocation.coordinate.longitude),
                                               OsmAnd::Utilities::get31TileNumberY(newLocation.coordinate.latitude));
                    
                    // In case previous mode was Follow, restore last azimuth, elevation angle and zoom
                    // used in PositionTrack mode
                    if (_lastMapMode == OAMapModeFollow && _lastPositionTrackStateCaptured)
                    {
                        _mapView.animator->animateTargetTo(newTarget31,
                                                           kFastAnimationTime,
                                                           OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                           kLocationServicesAnimationKey);
                        _mapView.animator->animateAzimuthTo(_lastAzimuthInPositionTrack,
                                                            kFastAnimationTime,
                                                            OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                            kLocationServicesAnimationKey);
                        _mapView.animator->animateElevationAngleTo(_lastElevationAngle,
                                                                   kOneSecondAnimatonTime,
                                                                   OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                                   kLocationServicesAnimationKey);
                        _mapView.animator->animateZoomTo(_lastZoom,
                                                         kFastAnimationTime,
                                                         OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                         kLocationServicesAnimationKey);
                        _lastPositionTrackStateCaptured = false;
                    }
                    else
                    {
                        BOOL zoomMap = _mapView.zoom < kGoToMyLocationZoom && (forceZoom || autoZoomMap);
                        if ([_mapViewController screensToFly:[OANativeUtilities convertFromPointI:newTarget31]] <= kScreensToFlyWithAnimation)
                        {
                            _mapView.animator->animateTargetTo(newTarget31,
                                                               kFastAnimationTime,
                                                               OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                               kUserInteractionAnimationKey);
                            
                            if (_mapView.elevationAngle != kMapModePositionTrackingDefaultElevationAngle)
                                _mapView.animator->animateElevationAngleTo(kMapModePositionTrackingDefaultElevationAngle,
                                                                           kOneSecondAnimatonTime,
                                                                           OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                                           kLocationServicesAnimationKey);
                            
                            if (zoomMap)
                                _mapView.animator->animateZoomTo(kGoToMyLocationZoom,
                                                                 kFastAnimationTime,
                                                                 OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                                 kUserInteractionAnimationKey);
                            if (direction >= 0)
                                _mapView.animator->animateAzimuthTo(direction,
                                                                    kFastAnimationTime,
                                                                    OsmAnd::MapAnimator::TimingFunction::Linear,
                                                                    kLocationServicesAnimationKey);
                        }
                        else
                        {
                            [_mapView setTarget31:newTarget31];
                            if (zoomMap)
                                [_mapView setZoom:kGoToMyLocationZoom];
                            
                            if (direction >= 0)
                                [_mapView setAzimuth:direction];
                            
                            if (_mapView.elevationAngle != kMapModePositionTrackingDefaultElevationAngle)
                                [_mapView setElevationAngle:kMapModePositionTrackingDefaultElevationAngle];
                        }
                    }
                    
                    _mapView.animator->resume();
                }
                break;
            }
                
            case OAMapModeFollow:
            {
                // In case previous mode was PositionTrack, remember azimuth, elevation angle and zoom
                if (_lastMapMode == OAMapModePositionTrack && !_isIn3dMode)
                {
                    _lastAzimuthInPositionTrack = _mapView.azimuth;
                    _lastZoom = _mapView.zoom;
                    _lastElevationAngle = kMapModePositionTrackingDefaultElevationAngle;
                    _lastPositionTrackStateCaptured = true;
                    _isIn3dMode = YES;
                }
                
                _mapView.animator->pause();
                _mapView.animator->cancelAllAnimations();
                
                _mapView.animator->animateZoomTo(kMapModeFollowDefaultZoom,
                                                 kFastAnimationTime,
                                                 OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                 kLocationServicesAnimationKey);
                
                _mapView.animator->animateElevationAngleTo(kMapModeFollowDefaultElevationAngle,
                                                           kFastAnimationTime,
                                                           OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                           kLocationServicesAnimationKey);
                
                if (newLocation)
                {
                    OsmAnd::PointI newTarget31(OsmAnd::Utilities::get31TileNumberX(newLocation.coordinate.longitude),
                                               OsmAnd::Utilities::get31TileNumberY(newLocation.coordinate.latitude));
                    
                    _mapView.animator->animateTargetTo(newTarget31,
                                                       kFastAnimationTime,
                                                       OsmAnd::MapAnimator::TimingFunction::Linear,
                                                       kLocationServicesAnimationKey);
                    
                    if (direction >= 0)
                        _mapView.animator->animateAzimuthTo(direction,
                                                            kFastAnimationTime,
                                                            OsmAnd::MapAnimator::TimingFunction::Linear,
                                                            kLocationServicesAnimationKey);
                }
                
                _mapView.animator->resume();
                break;
            }
                
            default:
                return;
        }
        
        _lastMapMode = _app.mapMode;
    });
}

- (void) onLocationServicesStatusChanged
{
    if (_app.locationServices.status == OALocationServicesStatusInactive)
    {
        // If location services are stopped for any reason,
        // set map-mode to free, since location data no longer available
        _app.mapMode = OAMapModeFree;
    }
}

- (void) onLocationServicesUpdate
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (!_mapViewController || ![_mapViewController isViewLoaded])
            return;
        
        // Obtain fresh location and heading
        CLLocation* newLocation = _app.locationServices.lastKnownLocation;
        CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;
        
        bool sameLocation = newLocation && [newLocation isEqual:_myLocation];
        bool sameHeading = _heading == newHeading;

        _myLocation = newLocation;
        _heading = newHeading;

        if (_mapViewController && (!sameLocation || !sameHeading))
        {
            // Wait for Map Mode changing animation if any, to prevent animation lags
            if (!newLocation || (CACurrentMediaTime() - _startChangingMapModeTime < kOneSecondAnimatonTime))
            {
                [_mapViewController updateLocation:newLocation heading:newHeading];
                return;
            }
            
            if ([_settings.drivingRegionAutomatic get] && !_drivingRegionUpdated)
            {
                _drivingRegionUpdated = true;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self detectDrivingRegion:newLocation];
                });
            }
            
            const OsmAnd::PointI newTarget31(OsmAnd::Utilities::get31TileNumberX(newLocation.coordinate.longitude),
                                             OsmAnd::Utilities::get31TileNumberY(newLocation.coordinate.latitude));
            
            if (_app.mapMode == OAMapModePositionTrack || _app.mapMode == OAMapModeFollow)
            {
                _mapView.animator->pause();
                
                float zoom = 0;
                if ([_settings.autoZoomMap get])
                    zoom = [self autozoom:newLocation];
                
                CLLocationDirection direction = [self calculateDirectionWithLocation:newLocation heading:newHeading applyViewAngleVisibility:YES];
                
                const auto targetAnimation = _mapView.animator->getCurrentAnimation(kLocationServicesAnimationKey, OsmAnd::MapAnimator::AnimatedValue::Target);
                auto zoomAnimation = _mapView.animator->getCurrentAnimation(kLocationServicesAnimationKey, OsmAnd::MapAnimator::AnimatedValue::Zoom);
                
                _mapView.animator->cancelCurrentAnimation(kUserInteractionAnimationKey, OsmAnd::MapAnimator::AnimatedValue::Target);
                
                if (zoom == 0)
                    zoomAnimation = nullptr;
                if (zoomAnimation)
                    _mapView.animator->cancelCurrentAnimation(kUserInteractionAnimationKey, OsmAnd::MapAnimator::AnimatedValue::Zoom);
                
                const auto azimuthAnimation = _mapView.animator->getCurrentAnimation(kLocationServicesAnimationKey, OsmAnd::MapAnimator::AnimatedValue::Azimuth);
                _mapView.animator->cancelCurrentAnimation(kUserInteractionAnimationKey, OsmAnd::MapAnimator::AnimatedValue::Azimuth);
                
                if (direction >= 0)
                {
                    if (azimuthAnimation)
                    {
                        _mapView.animator->cancelAnimation(azimuthAnimation);
                        _mapView.animator->animateAzimuthTo(direction, azimuthAnimation->getDuration() - azimuthAnimation->getTimePassed(), OsmAnd::MapAnimator::TimingFunction::Linear, kLocationServicesAnimationKey);
                    }
                    else
                    {
                        _mapView.animator->animateAzimuthTo(direction,
                                                            kFastAnimationTime,
                                                            OsmAnd::MapAnimator::TimingFunction::Linear,
                                                            kLocationServicesAnimationKey);
                    }
                }
                
                // Update target
                if (!sameLocation)
                {
                    if (targetAnimation)
                    {
                        _mapView.animator->cancelAnimation(targetAnimation);
                        
                        double duration = targetAnimation->getDuration() - targetAnimation->getTimePassed();
                        _mapView.animator->animateTargetTo(newTarget31,
                                                           duration,
                                                           OsmAnd::MapAnimator::TimingFunction::Linear,
                                                           kLocationServicesAnimationKey);
                    }
                    else
                    {
                        _mapView.animator->animateTargetTo(newTarget31,
                                                           kFastAnimationTime,
                                                           OsmAnd::MapAnimator::TimingFunction::Linear,
                                                           kLocationServicesAnimationKey);
                    }
                }
                
                // Update zoom
                if (zoom > 0)
                {
                    if (zoomAnimation)
                    {
                        _mapView.animator->cancelAnimation(zoomAnimation);
                        _mapView.animator->animateZoomTo(zoom, zoomAnimation->getDuration() - zoomAnimation->getTimePassed(), OsmAnd::MapAnimator::TimingFunction::Linear, kLocationServicesAnimationKey);
                    }
                    else
                    {
                        _mapView.animator->animateZoomTo(zoom, kFastAnimationTime, OsmAnd::MapAnimator::TimingFunction::Linear, kLocationServicesAnimationKey);
                    }
                }
                
                _mapView.animator->resume();
            }
            _showViewAngle = (newLocation.course < 0 || [self.class isSmallSpeedForCompass:newLocation]);
            [_mapViewController updateLocation:newLocation heading:newHeading];

            OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
            _followingMode = [routingHelper isFollowingMode];
            if (_routePlanningMode != [routingHelper isRoutePlanningMode])
                [self switchToRoutePlanningMode];
        }
    });
}

- (void) detectDrivingRegion:(CLLocation *)location
{
    OAWorldRegion *worldRegion = [_app.worldRegion findAtLat:location.coordinate.latitude lon:location.coordinate.longitude];
    if (worldRegion)
        [_app setupDrivingRegion:worldRegion];
}

- (CLLocationDirection) calculateDirectionWithLocation:(CLLocation *)location heading:(CLLocationDirection)heading applyViewAngleVisibility:(BOOL)applyViewAngleVisibility
{
    int currentMapRotation = [_settings.rotateMap get];
    double course = -1;

    double speedForDirectionOfMovement = [_settings.switchMapDirectionToCompass get];
    BOOL smallSpeedForDirectionOfMovement = speedForDirectionOfMovement != 0 && [self.class isSmallSpeedForDirectionOfMovement:location speedToDirectionOfMovement:speedForDirectionOfMovement];
    BOOL smallSpeedForCompass = [self.class isSmallSpeedForCompass:location];
    //BOOL smallSpeedForAnimation = [self.class isSmallSpeedForAnimation:newLocation];
    
    BOOL sva = (location.course < 0 || smallSpeedForCompass);
    
    if (currentMapRotation == ROTATE_MAP_BEARING)
    {
        if (smallSpeedForDirectionOfMovement)
        {
            sva = _routePlanningMode;
        }
        else if (location.course >= 0 && !smallSpeedForCompass)
        {
            // special case when bearing equals to zero (we don't change anything)
            if (location.course != 0)
                course = location.course;
        }
    }
    else if (currentMapRotation == ROTATE_MAP_COMPASS)
    {
        sva = _routePlanningMode; // disable compass rotation in that mode
    }
    
    if (applyViewAngleVisibility)
        _showViewAngle = sva;
    
    CLLocationDirection direction = course;
    if (direction < 0)
    {
        double speedForDirectionOfMovement = [_settings.switchMapDirectionToCompass get];
        BOOL smallSpeedForDirectionOfMovement = speedForDirectionOfMovement != 0 && location && [self.class isSmallSpeedForDirectionOfMovement:location speedToDirectionOfMovement:speedForDirectionOfMovement];
        if (([_settings.rotateMap get] == ROTATE_MAP_COMPASS || ([_settings.rotateMap get] == ROTATE_MAP_BEARING && smallSpeedForDirectionOfMovement)) && !_routePlanningMode)
        {
            if (ABS(degreesDiff(_mapView.azimuth, heading)) > 1)
                direction = heading;
        }
    }
    return direction;
}

- (float) defineZoomFromSpeed:(CLLocationSpeed)speed
{
    if (speed < 7.0 / 3.6)
        return 0;

    OsmAnd::AreaI bbox = [_mapView getVisibleBBox31];
    double visibleDist = OsmAnd::Utilities::distance31(OsmAnd::PointI(bbox.left() + bbox.width() / 2, bbox.top()), bbox.center());
    float time = 75.f; // > 83 km/h show 75 seconds
    if (speed < 83.f / 3.6)
        time = 60.f;
    
    time /= [OAAutoZoomMap getCoefficient:[_settings.autoZoomMapScale get]];
    double distToSee = speed * time;
    float zoomDelta = (float) (log(visibleDist / distToSee) / log(2.0f));
    // check if 17, 18 is correct?
    return zoomDelta;
}

- (float) autozoom:(CLLocation *)location
{
    if (location.speed >= 0)
    {
        NSTimeInterval now = CACurrentMediaTime();
        float zdelta = [self defineZoomFromSpeed:location.speed];
        if (ABS(zdelta) >= 0.5/*?Math.sqrt(0.5)*/)
        {
            // prevent ui hysteresis (check time interval for autozoom)
            if (zdelta >= 2)
            {
                // decrease a bit
                zdelta -= 1;
            }
            else if (zdelta <= -2)
            {
                // decrease a bit
                zdelta += 1;
            }
            double targetZoom = MIN(_mapView.zoom + zdelta, [OAAutoZoomMap getMaxZoom:[_settings.autoZoomMapScale get]]);
            int threshold = [_settings.autoFollowRoute get];
            if (now - _lastTimeAutoZooming > 4.5 && (now - _lastTimeAutoZooming > threshold || !_isUserZoomed))
            {
                _isUserZoomed = false;
                _lastTimeAutoZooming = now;
                //                    double settingsZoomScale = Math.log(mapView.getSettingsMapDensity()) / Math.log(2.0f);
                //                    double zoomScale = Math.log(tb.getMapDensity()) / Math.log(2.0f);
                //                    double complexZoom = tb.getZoom() + zoomScale + zdelta;
                // round to 0.33
                targetZoom = round(targetZoom * 3) / 3.f;
                return targetZoom;
            }
        }
    }
    return 0;
}

- (void) refreshLocation
{
    [self onLocationServicesUpdate];
}

+ (BOOL) isSmallSpeedForDirectionOfMovement:(CLLocation *)location speedToDirectionOfMovement:(double)speedToDirectionOfMovement
{
    return location.speed < speedToDirectionOfMovement;
}

+ (BOOL) isSmallSpeedForCompass:(CLLocation *)location
{
    return location.speed < 0.5;
}

+ (BOOL) isSmallSpeedForAnimation:(CLLocation *)location
{
    return location.speed < 1.5;
}

- (BOOL) isContextMenuVisible
{
    return [[OARootViewController instance].mapPanel isContextMenuVisible];
}

- (void) backToLocationImpl
{
    [self backToLocationImpl:15 forceZoom:YES];
}

- (void) backToLocationImpl:(int)zoom forceZoom:(BOOL)forceZoom
{
    if (_mapViewController)
    {
        if (![self isMapLinkedToLocation])
        {
            [self setMapLinkedToLocation:YES];
            
            /*
            CLLocation *lastKnownLocation = _app.locationServices.lastKnownLocation;
            if (lastKnownLocation)
            {
                AnimateDraggingMapThread thread = mapView.getAnimatedDraggingThread();
                int fZoom = mapView.getZoom() < zoom ? zoom : mapView.getZoom();
                _movingToMyLocation = YES;
                thread.startMoving(lastKnownLocation.getLatitude(), lastKnownLocation.getLongitude(),
                                   fZoom, false, new Runnable() {
                                       @Override
                                       public void run() {
                                           _movingToMyLocation = NO;
                                       }
                                   });
            }
            mapView.refreshMap();
             */
        }
        OAMapMode newMode = _app.mapMode;
        switch (_app.mapMode)
        {
            case OAMapModeFree:
                if (_app.prevMapMode == OAMapModeFollow)
                    newMode = OAMapModeFollow;
                else
                    newMode = OAMapModePositionTrack;
                
                break;
                
            case OAMapModePositionTrack:
                // Perform switch to follow-mode only in case location services have compass
                if (_app.locationServices.compassPresent && [_settings.settingAllow3DView get])
                    newMode = OAMapModeFollow;
                break;
                
            case OAMapModeFollow:
                newMode = OAMapModePositionTrack;
                break;
                
            default:
                return;
        }
        
        // If user have denied location services for the application, show notification about that and
        // don't change the mode
        if (_app.locationServices.denied && (newMode == OAMapModePositionTrack || newMode == OAMapModeFollow))
        {
            [OALocationServices showDeniedAlert];
            return;
        }
        if (!_app.locationServices.lastKnownLocation && (newMode == OAMapModePositionTrack || newMode == OAMapModeFollow))
            [_app showToastMessage:OALocalizedString(@"unknown_location")];
        
        _forceZoom = forceZoom;
        _app.mapMode = newMode;
    }
}

- (void) backToLocationWithDelayImpl
{
    if (_mapViewController && ![self isMapLinkedToLocation] && ![self isContextMenuVisible])
    {
        [_app showToastMessage:OALocalizedString(@"auto_follow_location_enabled")];
        [self backToLocationImpl:15 forceZoom:NO];
    }
}

- (void) backToLocationWithDelay:(int)delay
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(backToLocationWithDelayImpl) object:nil];
    [self performSelector:@selector(backToLocationWithDelayImpl) withObject:nil afterDelay:delay];
}

- (BOOL) isMapLinkedToLocation
{
    return _app.mapMode != OAMapModeFree;
}

- (void) setMapLinkedToLocation:(BOOL)isMapLinkedToLocation
{
    if (![self isMapLinkedToLocation])
    {
        int autoFollow = [_settings.autoFollowRoute get];
        if (autoFollow > 0 && [[OARoutingHelper sharedInstance] isFollowingMode] && !_routePlanningMode)
            [self backToLocationWithDelay:autoFollow];
    }
}

- (void) onMapGestureAction:(NSNotification *)notification
{
    _app.mapMode = OAMapModeFree;
}

- (void) setMapViewController:(OAMapViewController *)mapViewController
{
    _mapViewController = mapViewController;
    _mapView = _mapViewController.mapView;
}

- (void) switchToRoutePlanningMode
{
    OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
    _routePlanningMode = [routingHelper isRoutePlanningMode];
    [self updateSettings];
    if (!_routePlanningMode && _followingMode)
        [self backToLocationImpl];
}

- (void) switchRotateMapMode
{
    NSString *rotMode = OALocalizedString(@"rotate_map_none_opt");
    if ([_settings.rotateMap get] == ROTATE_MAP_NONE && _mapViewController.mapView.azimuth != 0)
    {
        // reset manual rotation
    }
    else
    {
        int vl = ([_settings.rotateMap get] + 1) % 3;
        [_settings.rotateMap set:vl];
        _lastPositionTrackStateCaptured = false;
        
        if ([_settings.rotateMap get] == ROTATE_MAP_BEARING)
            rotMode = OALocalizedString(@"rotate_map_bearing_opt");
        else if ([_settings.rotateMap get] == ROTATE_MAP_COMPASS)
            rotMode = OALocalizedString(@"rotate_map_compass_opt");
    }
    rotMode = [NSString stringWithFormat:@"%@:\n%@", OALocalizedString(@"rotate_map_to_bearing"), rotMode];
    [_app showShortToastMessage:rotMode];
    [self updateSettings];
    if (_mapViewController)
        [_mapViewController refreshMap];
}

- (void) updateSettings
{
    if (_mapViewController)
    {
        if ([_settings.rotateMap get] == ROTATE_MAP_NONE || _routePlanningMode)
            [self animatedAlignAzimuthToNorth];
        
        _mapViewController.mapPosition = ([_settings.rotateMap get] == ROTATE_MAP_BEARING && !_routePlanningMode && ![_settings.centerPositionOnMap get] ? BOTTOM_CONSTANT : CENTER_CONSTANT);
    }
}

- (void) animatedAlignAzimuthToNorth
{
    if (!_mapViewController || ![_mapViewController isViewLoaded] || _mapView.azimuth == 0)
        return;
    
    _startChangingMapModeTime = CACurrentMediaTime();

    // When user gesture has began, stop all animations
    _mapView.animator->pause();
    _mapView.animator->cancelAllAnimations();
    
    // Animate azimuth change to north
    _mapView.animator->animateAzimuthTo(0.0f,
                                        kFastAnimationTime,
                                        OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                        kUserInteractionAnimationKey);
    _mapView.animator->resume();
}

- (void) resetDrivingRegionUpdate
{
    _drivingRegionUpdated = NO;
    [self onLocationServicesUpdate];
}

- (void) onProfileSettingSet:(NSNotification *)notification
{
    OAProfileSetting *obj = notification.object;
    OAProfileBoolean *centerPositionOnMap = [OAAppSettings sharedManager].centerPositionOnMap;
    if (obj)
    {
        if (obj == centerPositionOnMap)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateSettings];
            });
        }
    }
}

@end
