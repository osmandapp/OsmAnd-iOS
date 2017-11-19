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
    long _lastTimeAutoZooming;
    BOOL _sensorRegistered;
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
    
    BOOL _rotatingToNorth;
    BOOL _isIn3dMode;
    
    NSDate *_startChangingMapMode;
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
        _sensorRegistered = NO;
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
    }
    return self;
}

- (void) onMapModeChanged
{
    if (!_mapViewController || ![_mapViewController isViewLoaded])
        return;
    
    switch (_app.mapMode)
    {
        case OAMapModeFree:
            // Do nothing
            break;
            
        case OAMapModePositionTrack:
        {
            if (_lastMapMode == OAMapModeFollow && !_rotatingToNorth)
                _isIn3dMode = NO;
            
            CLLocation* newLocation = _app.locationServices.lastKnownLocation;
            if (newLocation && !_rotatingToNorth)
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
                    _startChangingMapMode = [NSDate date];
                    
                    _mapView.animator->animateTargetTo(newTarget31,
                                                       kOneSecondAnimatonTime,
                                                       OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                       kLocationServicesAnimationKey);
                    _mapView.animator->animateAzimuthTo(_lastAzimuthInPositionTrack,
                                                        kOneSecondAnimatonTime,
                                                        OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                        kLocationServicesAnimationKey);
                    _mapView.animator->animateElevationAngleTo(_lastElevationAngle,
                                                               kOneSecondAnimatonTime,
                                                               OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                               kLocationServicesAnimationKey);
                    _mapView.animator->animateZoomTo(_lastZoom,
                                                     kOneSecondAnimatonTime,
                                                     OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                     kLocationServicesAnimationKey);
                    _lastPositionTrackStateCaptured = false;
                }
                else
                {
                    if ([_mapViewController screensToFly:[OANativeUtilities convertFromPointI:newTarget31]] <= kScreensToFlyWithAnimation)
                    {
                        _startChangingMapMode = [NSDate date];
                        _mapView.animator->animateTargetTo(newTarget31,
                                                           kFastAnimationTime,
                                                           OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                           kUserInteractionAnimationKey);
                        if (_mapView.zoom < kGoToMyLocationZoom)
                            _mapView.animator->animateZoomTo(kGoToMyLocationZoom,
                                                             kFastAnimationTime,
                                                             OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                             kUserInteractionAnimationKey);
                    }
                    else
                    {
                        [_mapView setTarget31:newTarget31];
                        if (_mapView.zoom < kGoToMyLocationZoom)
                            [_mapView setZoom:kGoToMyLocationZoom];
                    }
                }
                
                _mapView.animator->resume();
            }
            _rotatingToNorth = NO;
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
            
            _startChangingMapMode = [NSDate date];
            
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
            
            CLLocation* newLocation = _app.locationServices.lastKnownLocation;
            if (newLocation)
            {
                OsmAnd::PointI newTarget31(OsmAnd::Utilities::get31TileNumberX(newLocation.coordinate.longitude),
                                           OsmAnd::Utilities::get31TileNumberY(newLocation.coordinate.latitude));
                
                _mapView.animator->animateTargetTo(newTarget31,
                                                   kFastAnimationTime,
                                                   OsmAnd::MapAnimator::TimingFunction::Linear,
                                                   kLocationServicesAnimationKey);
                
                const auto direction = _app.locationServices.lastKnownHeading;
                
                if (!isnan(direction) && direction >= 0)
                {
                    _mapView.animator->animateAzimuthTo(direction,
                                                        kFastAnimationTime,
                                                        OsmAnd::MapAnimator::TimingFunction::Linear,
                                                        kLocationServicesAnimationKey);
                }
            }
            
            _mapView.animator->resume();
            break;
        }
            
        default:
            return;
    }
    
    _lastMapMode = _app.mapMode;
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
        
        _myLocation = newLocation;
        _heading = newHeading;
        
        if (_mapViewController)
        {
            [_mapViewController updateLocation:newLocation heading:newHeading];
            
            // Wait for Map Mode changing animation if any, to prevent animation lags
            if (_startChangingMapMode && [[NSDate date] timeIntervalSinceDate:_startChangingMapMode] < kOneSecondAnimatonTime)
                return;
            
            const OsmAnd::PointI newTarget31(OsmAnd::Utilities::get31TileNumberX(newLocation.coordinate.longitude),
                                             OsmAnd::Utilities::get31TileNumberY(newLocation.coordinate.latitude));
            
            // If map mode is position-track or follow, move to that position
            if (_app.mapMode == OAMapModePositionTrack || _app.mapMode == OAMapModeFollow)
            {
                _mapView.animator->pause();
                
                const auto targetAnimation = _mapView.animator->getCurrentAnimation(kLocationServicesAnimationKey,
                                                                                    OsmAnd::MapAnimator::AnimatedValue::Target);
                
                _mapView.animator->cancelCurrentAnimation(kUserInteractionAnimationKey,
                                                          OsmAnd::MapAnimator::AnimatedValue::Target);
                
                // For "follow-me" mode azimuth is also controlled
                if (_app.mapMode == OAMapModeFollow)
                {
                    const auto azimuthAnimation = _mapView.animator->getCurrentAnimation(kLocationServicesAnimationKey,
                                                                                         OsmAnd::MapAnimator::AnimatedValue::Azimuth);
                    _mapView.animator->cancelCurrentAnimation(kUserInteractionAnimationKey,
                                                              OsmAnd::MapAnimator::AnimatedValue::Azimuth);
                    
                    // Update azimuth if there's one
                    const auto direction = newLocation.speed < 0.5 ? newHeading : newLocation.course;
                    if (!isnan(direction) && direction >= 0)
                    {
                        if (azimuthAnimation)
                        {
                            _mapView.animator->cancelAnimation(azimuthAnimation);
                            
                            _mapView.animator->animateAzimuthTo(direction,
                                                                azimuthAnimation->getDuration() - azimuthAnimation->getTimePassed(),
                                                                OsmAnd::MapAnimator::TimingFunction::Linear,
                                                                kLocationServicesAnimationKey);
                        }
                        else
                        {
                            _mapView.animator->animateAzimuthTo(direction,
                                                                kOneSecondAnimatonTime,
                                                                OsmAnd::MapAnimator::TimingFunction::Linear,
                                                                kLocationServicesAnimationKey);
                        }
                    }
                }
                
                // And also update target
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
                    if (_app.mapMode == OAMapModeFollow)
                    {
                        _mapView.animator->animateTargetTo(newTarget31,
                                                           kOneSecondAnimatonTime,
                                                           OsmAnd::MapAnimator::TimingFunction::Linear,
                                                           kLocationServicesAnimationKey);
                    }
                    else //if (_app.mapMode == OAMapModePositionTrack)
                    {
                        _mapView.animator->animateTargetTo(newTarget31,
                                                           kOneSecondAnimatonTime,
                                                           OsmAnd::MapAnimator::TimingFunction::Linear,
                                                           kLocationServicesAnimationKey);
                    }
                }
                
                _mapView.animator->resume();
            }
        }
    });
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
    [self backToLocationImpl:15];
}

- (void) backToLocationImpl:(int)zoom
{
    if (_mapViewController)
    {
        if (![self isMapLinkedToLocation])
        {
            [self setMapLinkedToLocation:YES];

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
                    if (_app.locationServices.compassPresent)
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
            
            _app.mapMode = newMode;
            
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
    }
}

- (void) backToLocationWithDelayImpl
{
    if (_mapViewController && ![self isMapLinkedToLocation] && ![self isContextMenuVisible])
    {
        [_app showToastMessage:OALocalizedString(@"auto_follow_location_enabled")];
        [self backToLocationImpl];
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
    if (!_mapViewController || ![_mapViewController isViewLoaded])
        return;
    
    // When user gesture has began, stop all animations
    _mapView.animator->pause();
    _mapView.animator->cancelAllAnimations();
    
    if (_lastMapMode == OAMapModeFollow)
    {
        _rotatingToNorth = YES;
        _app.mapMode = OAMapModePositionTrack;
    }
    
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
}

@end
