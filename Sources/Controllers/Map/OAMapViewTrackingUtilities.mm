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
#import "OALocationServices.h"
#import "OAMapViewController.h"
#import "OAMapPanelViewController.h"
#import "OAAutoObserverProxy.h"
#import "OARoutingHelper.h"
#import "OATargetPointsHelper.h"
#import "OAWorldRegion.h"
#import "Localization.h"
#import "OATargetPointView.h"
#import "OARootViewController.h"
#import "OANativeUtilities.h"
#import "OAAutoZoomBySpeedHelper.h"
#import "OAZoom.h"
#import "OAAppDelegate.h"
#import "OARouteCalculationResult.h"
#import "OAMapUtils.h"
#import "OARoutingHelperUtils.h"
#import "OAMapLayers.h"
#import "OAObservable.h"
#import "CLLocation+Extension.h"

#include <commonOsmAndCore.h>
#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/QKeyValueIterator.h>

static double const COMPASS_REQUEST_TIME_INTERVAL = 5;
static double const AUTO_ZOOM_DEFAULT_CHANGE_ZOOM = 4.5;
static double const MOVE_ANIMATION_TIME = 0.5;
static double const NAV_ANIMATION_TIME = 1.0;
static double const SKIP_ANIMATION_TIMEOUT = 10.0;
static double const ROTATION_MOVE_ANIMATION_TIME = 1.0;
static double const SKIP_ANIMATION_DP_THRESHOLD = 20.0;

@interface OAMapViewTrackingUtilities ()

@end

@implementation OAMapViewTrackingUtilities
{
    NSTimeInterval _lastTimeAutoZooming;
    NSTimeInterval _lastTimeManualZooming;
    OAMapViewController *_mapViewController;
    OAMapRendererView *_mapView;
    OAAppSettings *_settings;
    OsmAndAppInstance _app;
    OAAutoZoomBySpeedHelper *_autoZoomBySpeedHelper;
    OARoutingHelper *_routingHelper;
    BOOL _followingMode;
    BOOL _routePlanningMode;
    BOOL _isUserZoomed;
    BOOL _showRouteFinishDialog;
    BOOL _drivingRegionUpdated;
    
    OAAutoObserverProxy *_locationServicesStatusObserver;
    OAAutoObserverProxy *_locationUpdateObserver;
    OAAutoObserverProxy *_headingUpdateObserver;
    OAAutoObserverProxy *_mapModeObserver;
    
    OAMapMode _lastMapMode;
    float _lastAzimuthInPositionTrack;
    float _lastZoom;
    
    BOOL _forceZoom;
    
    BOOL _needsLocationUpdate;
    
    NSTimeInterval _startChangingMapModeTime;
    NSTimeInterval _compassRequest;

    CLLocation *_myLocation;
    CLLocationDirection _heading;
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
        _heading = -1;
        _autoZoomBySpeedHelper = [[OAAutoZoomBySpeedHelper alloc] init];
        _routingHelper = [OARoutingHelper sharedInstance];
        
        _lastMapMode = _app.mapMode;

        _mapModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                     withHandler:@selector(onMapModeChanged)
                                                      andObserve:_app.mapModeObservable];

        _locationServicesStatusObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(onLocationServicesStatusChanged)
                                                                     andObserve:_app.locationServices.statusObservable];

        _locationUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                            withHandler:@selector(onLocationUpdate)
                                                             andObserve:_app.locationServices.updateLocationObserver];
        _headingUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onHeadingUpdate)
                                                            andObserve:_app.locationServices.updateHeadingObserver];

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
                });
                break;
            }
            case OAMapModePositionTrack:
            {
                if (newLocation)
                {
                    // Fly to last-known position without changing anything but target

                    _mapView.mapAnimator->pause();

                    for (const auto &animation : _mapView.mapAnimator->getAllAnimations())
                    {
                        if (animation->getAnimatedValue() != OsmAnd::Animator::AnimatedValue::ElevationAngle)
                            _mapView.mapAnimator->cancelAnimation(animation);
                    }

                    OsmAnd::PointI newTarget31(
                                               OsmAnd::Utilities::get31TileNumberX(newLocation.coordinate.longitude),
                                               OsmAnd::Utilities::get31TileNumberY(newLocation.coordinate.latitude));

                    
                    BOOL zoomMap = _mapView.zoom < kGoToMyLocationZoom && (forceZoom || autoZoomMap);
                    if ([_mapViewController screensToFly:[OANativeUtilities convertFromPointI:newTarget31]] <= kScreensToFlyWithAnimation)
                    {
                        _mapView.mapAnimator->animateTargetTo(newTarget31,
                                                           kFastAnimationTime,
                                                           OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                           kUserInteractionAnimationKey);

                        if (zoomMap)
                            _mapView.mapAnimator->animateZoomTo(kGoToMyLocationZoom,
                                                             kFastAnimationTime,
                                                             OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                                             kUserInteractionAnimationKey);
                        if (direction >= 0)
                            _mapView.mapAnimator->animateAzimuthTo(direction,
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
                    }
                    

                    _mapView.mapAnimator->resume();
                }
                break;
            }

            default:
                return;
        }
        
        _lastMapMode = _app.mapMode;
    });
}

- (BOOL) is3DMode
{
    return [OARootViewController instance].mapPanel.mapViewController.mapView.elevationAngle < 89;
}

- (BOOL)isDefaultElevationAngle {
    return ceil([OARootViewController instance].mapPanel.mapViewController.mapView.elevationAngle) == kDefaultElevationAngle;
}

- (void)startTilting:(float)elevationAngle
{
    float initialElevationAngle = [OARootViewController instance].mapPanel.mapViewController.mapView.elevationAngle;
    float elevationAngleDiff = elevationAngle - initialElevationAngle;
    float animationTime = fabsf(elevationAngleDiff) * 5;
    
    _mapView.mapAnimator->pause();
    
    float duration = animationTime / 1000.0f;
    const auto elevationAnimation = _mapView.mapAnimator->getCurrentAnimation(kUserInteractionAnimationKey,
                                                                              OsmAnd::MapAnimator::AnimatedValue::ElevationAngle);
    if (elevationAnimation)
    {
        _mapView.mapAnimator->cancelAnimation(elevationAnimation);
        _mapView.mapAnimator->cancelCurrentAnimation(kUserInteractionAnimationKey, OsmAnd::MapAnimator::AnimatedValue::ElevationAngle);
    }
    _mapView.mapAnimator->animateElevationAngleTo(elevationAngle,
                                                  duration,
                                                  OsmAnd::MapAnimator::TimingFunction::Linear,
                                                  kUserInteractionAnimationKey);
    _mapView.mapAnimator->resume();
}

- (void)switchMap3dMode
{
    BOOL defaultElevationAngle = [self isDefaultElevationAngle];
    float tiltAngle = defaultElevationAngle ? [self getElevationAngle:floor(_mapView.zoom)] : kDefaultElevationAngle;
    [self startTilting:tiltAngle];
}

- (float) getElevationAngle:(int)zoom
{
    float map3DModeElevationAngle = ceil([[OARootViewController instance].mapPanel.mapViewController getMap3DModeElevationAngle]);
    if (map3DModeElevationAngle != 90)
    {
        return map3DModeElevationAngle;
    }
    else
    {
        if (zoom < kMinZoomLevelToAjustCameraTilt)
            zoom = kMinZoomLevelToAjustCameraTilt;
        else if (zoom > kMaxZoomLimit)
            zoom = kMaxZoomLimit;
        
        return 90 - (zoom - 2) * 5;
    }
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

- (void) onLocationUpdate
{
    if ([_settings.useV1AutoZoom get])
    {
        [self onLocationServicesUpdateV1];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (!_mapViewController || ![_mapViewController isViewLoaded])
        {
            _needsLocationUpdate = YES;
            return;
        }
        
        CLLocation *location = _app.locationServices.lastKnownLocation;
        CLLocationDirection heading = _app.locationServices.lastKnownHeading;
        CLLocation *prevLocation = _myLocation;
        NSTimeInterval movingTime = (prevLocation && location) ? (location.timestamp.timeIntervalSince1970 - prevLocation.timestamp.timeIntervalSince1970) : 0;
        _myLocation = location;
        BOOL showViewAngle = NO;
       
        if (location)
        {
            if (_myLocation && ![_myLocation hasBearing])
                _myLocation = [_myLocation locationWithBearing:_app.locationServices.lastKnownHeading];
            
            OAAppDelegate *appDelegate = (OAAppDelegate *)[[UIApplication sharedApplication] delegate];
            if ([_settings.drivingRegionAutomatic get] && !_drivingRegionUpdated && ![appDelegate isAppInitializing])
            {
                _drivingRegionUpdated = true;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [OARoutingHelperUtils updateDrivingRegionIfNeeded:location force:YES];
                });
            }
        }

        if (_mapViewController)
        {
            if ([self isMapLinkedToLocation] && location)
            {
                double rotation = NAN;
                BOOL pendingRotation = NO;
                int currentMapRotation = [_settings.rotateMap get];
                BOOL smallSpeedForCompass = [self isSmallSpeedForCompass:location];
                
                showViewAngle = (![location hasBearing] || smallSpeedForCompass) && [OANativeUtilities containsLatLon:location];
                if (currentMapRotation == ROTATE_MAP_BEARING)
                {
                    // special case when bearing equals to zero (we don't change anything)
                    if ([location hasBearing] && location.course != 0)
                    {
                        rotation = -location.course;
                    }
                    if (isnan(rotation) && prevLocation)
                    {
                        CGFloat distDp = [location distanceFromLocation:prevLocation] / _mapView.currentPixelsToMetersScaleFactor / UIScreen.mainScreen.scale;
                        if (distDp > SKIP_ANIMATION_DP_THRESHOLD)
                        {
                            movingTime = 0;
                        }
                    }
                }
                else if (currentMapRotation == ROTATE_MAP_COMPASS)
                {
                    showViewAngle = _routePlanningMode;  // disable compass rotation in that mode
                    pendingRotation = YES;
                }
                else if (currentMapRotation == ROTATE_MAP_NONE)
                {
                    rotation = 0;
                    pendingRotation = YES;
                }
                else if (currentMapRotation == ROTATE_MAP_MANUAL)
                {
                    pendingRotation = YES;
                }
                
                [self setMyLocationV2:location timeDiff:movingTime rotation:rotation];
            }
            else if (location)
            {
                showViewAngle = (![location hasBearing] || [self isSmallSpeedForCompass:location]) && [OANativeUtilities containsLatLon:location];
            }
            
            _showViewAngle = showViewAngle;
            _followingMode = _routingHelper.isFollowingMode;
            if (_routePlanningMode != [_routingHelper isRoutePlanningMode])
            {
                [self switchToRoutePlanningMode];
            }
        }
        
        [_mapViewController updateLocation:location heading:heading];
    });
}

- (void) setMyLocationV2:(CLLocation *)location timeDiff:(NSTimeInterval)timeDiff rotation:(double)rotation
{
    BOOL animateMyLocation = [self animateMyLocation:location];
    
    OAComplexZoom *autoZoom = nil;
    if ([self shouldAutoZoom:location autoZoomFrequency:0])
    {
        if (animateMyLocation)
        {
            [self stopAnimatingSync];
        }
        
        autoZoom = [_autoZoomBySpeedHelper calculateZoomBySpeedToAnimate:_mapView myLocation:location rotationToAnimate:rotation nextTurn:[self getNextTurn]];
    }
    
    NSTimeInterval movingTime;
    if (animateMyLocation)
    {
        movingTime = timeDiff;
    }
    else
    {
        if ([_settings.doNotUseAnimations get])
        {
            movingTime = 0;
        }
        else
        {
            movingTime = _movingToMyLocation ? MIN(timeDiff * 0.7, MOVE_ANIMATION_TIME) : MOVE_ANIMATION_TIME;
        }
    }
    
    float fixedZoomDuration = animateMyLocation ? -1 : NAV_ANIMATION_TIME;
    OAAutoZoomDTO *zoomParams = autoZoom != nil ? [_autoZoomBySpeedHelper getAutoZoomParams:_mapView.zoom autoZoom:autoZoom fixedDurationMillis:fixedZoomDuration] : nil;
    
    [self startMoving:location.coordinate.latitude finalLon:location.coordinate.longitude zoomParams:zoomParams pendingRotation:NO finalRotation:rotation movingTime:movingTime notifyListener:NO finishAnimationCallback:^{
        _movingToMyLocation = NO;
    }];
}

- (void) onHeadingUpdate
{
    if ([_settings.useV1AutoZoom get])
    {
        [self onLocationServicesUpdateV1];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{

        if (!_mapViewController || ![_mapViewController isViewLoaded])
        {
            _needsLocationUpdate = YES;
            return;
        }

        _needsLocationUpdate = NO;

        CLLocation* newLocation = _app.locationServices.lastKnownLocation;
        CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;
        bool sameHeading = _heading == newHeading;
        _heading = newHeading;

        if (_mapViewController && (!sameHeading))
        {
            // Wait for Map Mode changing animation if any, to prevent animation lags
            if (!newLocation || (CACurrentMediaTime() - _startChangingMapModeTime < kHalfSecondAnimatonTime))
            {
                [_mapViewController.mapLayers.myPositionLayer updateLocation:newLocation heading:newHeading];
                return;
            }
            if ([_settings.rotateMap get] == ROTATE_MAP_COMPASS)
            {
                _mapView.mapAnimator->pause();

                CLLocationDirection direction = [self calculateDirectionWithLocation:newLocation heading:newHeading applyViewAngleVisibility:YES];

                const auto azimuthAnimation = _mapView.mapAnimator->getCurrentAnimation(kLocationServicesAnimationKey, OsmAnd::MapAnimator::AnimatedValue::Azimuth);
                _mapView.mapAnimator->cancelCurrentAnimation(kUserInteractionAnimationKey, OsmAnd::MapAnimator::AnimatedValue::Azimuth);

                NSTimeInterval timeSinceLasGestureRotating = [NSDate now].timeIntervalSince1970 - _mapViewController.lastRotatingByGestureTime.timeIntervalSince1970;

                if (direction >= 0 && timeSinceLasGestureRotating > 1)
                {
                    if (azimuthAnimation)
                    {
                        _mapView.mapAnimator->cancelAnimation(azimuthAnimation);
                        _mapView.mapAnimator->animateAzimuthTo(direction, azimuthAnimation->getDuration() - azimuthAnimation->getTimePassed(), OsmAnd::MapAnimator::TimingFunction::Linear, kLocationServicesAnimationKey);
                    }
                    else
                    {
                        _mapView.mapAnimator->animateAzimuthTo(direction,
                                                            kOneSecondAnimatonTime,
                                                            OsmAnd::MapAnimator::TimingFunction::Linear,
                                                            kLocationServicesAnimationKey);
                    }
                }

                _mapView.mapAnimator->resume();
            }
            [_mapViewController.mapLayers.myPositionLayer updateLocation:newLocation heading:newHeading];
        }
    });
}

- (void) stopAnimatingSync
{
    _mapView.mapAnimator->pause();
}


- (void) startMoving:(double)finalLat finalLon:(double)finalLon zoomParams:(OAAutoZoomDTO *)zoomParams pendingRotation:(BOOL)pendingRotation finalRotation:(double)finalRotation movingTime:(NSTimeInterval)movingTime notifyListener:(BOOL)notifyListener finishAnimationCallback:(void (^)(void))finishAnimationCallback
{
    [self stopAnimatingSync];
    
    float startZoom = _mapView.zoom;
    float startRotation = _mapView.azimuth;
    
    float zoom;
    float rotation;
    if (zoomParams)
        zoom = zoomParams.zoomValue.base + zoomParams.zoomValue.floatPart;
    else
        zoom = startZoom;
    
    if (!isnan(finalRotation))
        rotation = finalRotation;
    else
        rotation = startRotation;
    
    BOOL skipAnimation = movingTime == 0 || movingTime > SKIP_ANIMATION_TIMEOUT || ![OANativeUtilities containsLatLon:finalLat lon:finalLon];
    if (skipAnimation)
    {
        [_mapView setTarget31:[OANativeUtilities getPoint31FromLatLon:finalLat lon:finalLon]];
        [_mapView setZoom:zoom];
        [_mapView setAzimuth:rotation];
        if (finishAnimationCallback)
            finishAnimationCallback();

        return;
    }
    
    float animationDuration = max(movingTime, NAV_ANIMATION_TIME / 4);
    BOOL animateZoom = zoomParams != nil && (zoom != startZoom);
    float rotationDiff = !isnan(finalRotation) ? abs([OAMapUtils unifyRotationDiff:rotation targetRotate:startRotation]) : 0;
    BOOL animateRotation = rotationDiff > 0.1;
    BOOL animateTarget;
    
    const auto& animator = _mapView.mapAnimator;
    if (animator)
    {
        const auto targetAnimation = animator->getCurrentAnimation(kLocationServicesAnimationKey, OsmAnd::MapAnimator::AnimatedValue::Target);
        auto zoomAnimation = animator->getCurrentAnimation(kLocationServicesAnimationKey, OsmAnd::MapAnimator::AnimatedValue::Zoom);
        
        animator->cancelCurrentAnimation(kUserInteractionAnimationKey, OsmAnd::MapAnimator::AnimatedValue::Target);
        
        if (!animateZoom)
            zoomAnimation = nullptr;
        if (zoomAnimation)
        {
            animator->cancelAnimation(zoomAnimation);
            animator->cancelCurrentAnimation(kUserInteractionAnimationKey, OsmAnd::MapAnimator::AnimatedValue::Zoom);
        }
        
        const auto azimuthAnimation = animator->getCurrentAnimation(kLocationServicesAnimationKey, OsmAnd::MapAnimator::AnimatedValue::Azimuth);
        if (!isnan(finalRotation))
        {
            animator->cancelCurrentAnimation(kUserInteractionAnimationKey, OsmAnd::MapAnimator::AnimatedValue::Azimuth);
            if (azimuthAnimation)
                animator->cancelAnimation(azimuthAnimation);
        }

        if (animateRotation)
        {
            animator->animateAzimuthTo(-rotation, MAX(animationDuration, ROTATION_MOVE_ANIMATION_TIME), OsmAnd::MapAnimator::TimingFunction::Linear, kLocationServicesAnimationKey);
        }
        
        OsmAnd::PointI start31 = [_mapView getTarget];
        OsmAnd::PointI finish31 = [OANativeUtilities calculateTarget31:finalLat longitude:finalLon applyNewTarget:NO];
        animateTarget = abs(finish31.x - start31.x) > 5 || abs(finish31.y - start31.y) > 5;
        if (animateTarget)
        {
            float duration = animationDuration; // sec or msecs?
            if (targetAnimation)
                animator->cancelAnimation(targetAnimation);

            animator->animateTargetTo(finish31, duration, OsmAnd::MapAnimator::TimingFunction::Linear, kLocationServicesAnimationKey);
        }
        
        if (animateZoom)
            animator->animateZoomTo(zoom, zoomParams.durationValue / 1000.0, OsmAnd::MapAnimator::TimingFunction::EaseOutQuartic, kLocationServicesAnimationKey);

        if (!animateZoom)
            [_mapView setZoom:zoom];

        if (!animateRotation && !isnan(finalRotation))
            [_mapView setAzimuth:rotation];

        if (!animateTarget)
            [_mapView setTarget31:[OANativeUtilities getPoint31FromLatLon:finalLat lon:finalLon]];

        animator->resume();
    }
}

// Old version without any changes
- (void) onLocationServicesUpdateV1
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (!_mapViewController || ![_mapViewController isViewLoaded])
        {
            _needsLocationUpdate = YES;
            return;
        }
        
        _needsLocationUpdate = NO;
        // Obtain fresh location and heading
        CLLocation* newLocation = _app.locationServices.lastKnownLocation;
        CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;
        
        bool sameLocation = newLocation && [newLocation isEqual:_myLocation];
        bool sameHeading = _heading == newHeading;

        CLLocation* prevLocation = _myLocation;
        _myLocation = newLocation;
        _heading = newHeading;

        if (_mapViewController && (!sameLocation || !sameHeading))
        {
            // Wait for Map Mode changing animation if any, to prevent animation lags
            if (!newLocation || (CACurrentMediaTime() - _startChangingMapModeTime < kHalfSecondAnimatonTime))
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
            
            if (_app.mapMode == OAMapModePositionTrack || [_settings.rotateMap get] == ROTATE_MAP_COMPASS)
            {
                _mapView.mapAnimator->pause();
                
                float zoom = 0;
                if ([_settings.autoZoomMap get])
                    zoom = [self autozoomV1:newLocation];
                
                CLLocationDirection direction = [self calculateDirectionWithLocation:newLocation heading:newHeading applyViewAngleVisibility:YES];
                
                const auto targetAnimation = _mapView.mapAnimator->getCurrentAnimation(kLocationServicesAnimationKey, OsmAnd::MapAnimator::AnimatedValue::Target);
                auto zoomAnimation = _mapView.mapAnimator->getCurrentAnimation(kLocationServicesAnimationKey, OsmAnd::MapAnimator::AnimatedValue::Zoom);
                
                _mapView.mapAnimator->cancelCurrentAnimation(kUserInteractionAnimationKey, OsmAnd::MapAnimator::AnimatedValue::Target);
                
                if (zoom == 0)
                    zoomAnimation = nullptr;
                if (zoomAnimation)
                    _mapView.mapAnimator->cancelCurrentAnimation(kUserInteractionAnimationKey, OsmAnd::MapAnimator::AnimatedValue::Zoom);
                
                const auto azimuthAnimation = _mapView.mapAnimator->getCurrentAnimation(kLocationServicesAnimationKey, OsmAnd::MapAnimator::AnimatedValue::Azimuth);
                _mapView.mapAnimator->cancelCurrentAnimation(kUserInteractionAnimationKey, OsmAnd::MapAnimator::AnimatedValue::Azimuth);
                
                NSTimeInterval timeSinceLasGestureRotating = [NSDate now].timeIntervalSince1970 - _mapViewController.lastRotatingByGestureTime.timeIntervalSince1970;
                
                if (direction >= 0 && timeSinceLasGestureRotating > 1)
                {
                    if (azimuthAnimation)
                    {
                        _mapView.mapAnimator->cancelAnimation(azimuthAnimation);
                        _mapView.mapAnimator->animateAzimuthTo(direction, azimuthAnimation->getDuration() - azimuthAnimation->getTimePassed(), OsmAnd::MapAnimator::TimingFunction::Linear, kLocationServicesAnimationKey);
                    }
                    else
                    {
                        _mapView.mapAnimator->animateAzimuthTo(direction,
                                                            kOneSecondAnimatonTime,
                                                            OsmAnd::MapAnimator::TimingFunction::Linear,
                                                            kLocationServicesAnimationKey);
                    }
                }
                
                BOOL freeMapCenterMode = [_settings.rotateMap get] == ROTATE_MAP_COMPASS && !(_app.mapMode == OAMapModePositionTrack);
                
                // Update target
                if (!sameLocation && !freeMapCenterMode)
                {
                    if (![self.class isSmallSpeedForAnimation:newLocation] && _settings.animateMyLocation.get)
                    {
                        double duration = prevLocation ? [newLocation.timestamp timeIntervalSinceDate:prevLocation.timestamp] : 0;
                        duration = MAX(duration, kNavAnimatonTime / 4);
                        if (targetAnimation)
                        {
                            _mapView.mapAnimator->cancelAnimation(targetAnimation);
                            _mapView.mapAnimator->animateTargetTo(newTarget31,
                                                               duration,
                                                               OsmAnd::MapAnimator::TimingFunction::Linear,
                                                               kLocationServicesAnimationKey);
                        }
                        else
                        {
                            _mapView.mapAnimator->animateTargetTo(newTarget31,
                                                               duration,
                                                               OsmAnd::MapAnimator::TimingFunction::Linear,
                                                               kLocationServicesAnimationKey);
                        }
                    }
                    else
                    {
                        [_mapView setTarget31:newTarget31];
                    }
                }
                
                // Update zoom
                if (zoom > 0)
                {
                    if (zoomAnimation)
                    {
                        _mapView.mapAnimator->cancelAnimation(zoomAnimation);
                        _mapView.mapAnimator->animateZoomTo(zoom, zoomAnimation->getDuration() - zoomAnimation->getTimePassed(), OsmAnd::MapAnimator::TimingFunction::Linear, kLocationServicesAnimationKey);
                    }
                    else
                    {
                        _mapView.mapAnimator->animateZoomTo(zoom, kFastAnimationTime, OsmAnd::MapAnimator::TimingFunction::Linear, kLocationServicesAnimationKey);
                    }
                }
                
                _mapView.mapAnimator->resume();
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

// Old version without any changes
- (float) autozoomV1:(CLLocation *)location
{
    if (location.speed >= 0)
    {
        NSTimeInterval now = CACurrentMediaTime();
        float zdelta = [self defineZoomFromSpeedV1:location.speed];
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
                targetZoom = round(targetZoom * 3) / 3.f;
                return targetZoom;
            }
        }
    }
    return 0;
}

// Old version without any changes
- (float) defineZoomFromSpeedV1:(CLLocationSpeed)speed
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

- (BOOL) animateMyLocation:(CLLocation *)location
{
    return [_settings.animateMyLocation get] && ![self.class isSmallSpeedForAnimation:location] && !_movingToMyLocation;
}

- (BOOL) shouldAutoZoom:(CLLocation *)location autoZoomFrequency:(int)autoZoomFrequency
{
    if (![_settings.autoZoomMap get] || location.speed <= 0)
        return NO;
    
    NSTimeInterval now = [[NSDate now] timeIntervalSince1970];
    BOOL isUserZoomed = _lastTimeManualZooming > _lastTimeAutoZooming;

    if (isUserZoomed)
        return (now - _lastTimeManualZooming) > MAX([_settings.autoFollowRoute get], AUTO_ZOOM_DEFAULT_CHANGE_ZOOM);
    else
        return (now - _lastTimeAutoZooming) > autoZoomFrequency;
}

- (void) setZoomTime:(NSTimeInterval)time
{
    _lastTimeManualZooming = time;
    if (_autoZoomBySpeedHelper)
        [_autoZoomBySpeedHelper onManualZoomChange];
}

- (OANextDirectionInfo *) getNextTurn
{
    OANextDirectionInfo *directionInfo = [[OANextDirectionInfo alloc] init];
    [[OARoutingHelper sharedInstance] getNextRouteDirectionInfo:directionInfo toSpeak:YES];
    return (directionInfo.directionInfo != nil && directionInfo.distanceTo) > 0 ? directionInfo : nil;
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
    
    BOOL sva = location.course < 0;
    
    if (currentMapRotation == ROTATE_MAP_BEARING)
    {
        if (location.course >= 0)
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
        if ([_settings.rotateMap get] == ROTATE_MAP_COMPASS && !_routePlanningMode)
        {
            if (ABS(degreesDiff(_mapView.azimuth, heading)) > 1)
                direction = heading;
        }
    }
    return direction;
}

- (void) refreshLocation
{
    [self onLocationUpdate];
    _heading = -1;
    [self onHeadingUpdate];
}

+ (BOOL) isSmallSpeedForCompass:(CLLocation *)location
{
    return location.speed < 0.5;
}

+ (BOOL) isSmallSpeedForAnimation:(CLLocation *)location
{
    return ![location hasSpeed] || location.speed < 1.5;
}

- (BOOL) isSmallSpeedForCompass:(CLLocation *)location
{
    return ![location hasSpeed] || location.speed < 0.5;
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
        OAMapMode newMode = OAMapModePositionTrack;
        
        // If user have denied location services for the application, show notification about that and
        // don't change the mode
        if (_app.locationServices.denied && newMode == OAMapModePositionTrack)
        {
            [OALocationServices showDeniedAlert];
            return;
        }
        if (!_app.locationServices.lastKnownLocation && newMode == OAMapModePositionTrack)
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
}

- (void) setMapViewController:(OAMapViewController *)mapViewController
{
    _mapViewController = mapViewController;
    _mapView = _mapViewController.mapView;
    if (_needsLocationUpdate)
        [self onLocationUpdate];
}

- (void) switchToRoutePlanningMode
{
    OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
    _routePlanningMode = [routingHelper isRoutePlanningMode];
    [self updateSettings];
    if (!_routePlanningMode && _followingMode)
        [self backToLocationImpl];
}

- (void) switchRotateMapModeImpl
{
    int vl = ([_settings.rotateMap get] + 1) % 4;
    [_settings.rotateMap set:vl];
    [self onRotateMapModeChanged];
}

- (void) onRotateMapModeChanged
{
    NSString *rotMode = OALocalizedString(@"rotate_map_north_opt");
    if ([_settings.rotateMap get] == ROTATE_MAP_MANUAL)
        rotMode = OALocalizedString(@"rotate_map_manual_opt");
    else if ([_settings.rotateMap get] == ROTATE_MAP_BEARING)
        rotMode = OALocalizedString(@"rotate_map_bearing_opt");
    else if ([_settings.rotateMap get] == ROTATE_MAP_COMPASS)
        rotMode = OALocalizedString(@"rotate_map_compass_opt");
    
    rotMode = [NSString stringWithFormat:@"%@: %@", OALocalizedString(@"rotate_map_to"), rotMode];
    [OAUtilities showToast:nil details:rotMode duration:4 inView:OARootViewController.instance.view];

    [self updateSettings];
    if (_mapViewController)
        [_mapViewController refreshMap];
}

- (void) switchRotateMapMode
{
    if ([OARoutingHelper.sharedInstance isFollowingMode])
    {
        if (_compassRequest + COMPASS_REQUEST_TIME_INTERVAL > [NSDate.date timeIntervalSince1970])
        {
            _compassRequest = 0;
            [self switchRotateMapModeImpl];
        }
        else {
            _compassRequest = [NSDate.date timeIntervalSince1970];
            [OAUtilities showToast:nil details:OALocalizedString(@"press_again_to_change_the_map_orientation") duration:4 inView:OARootViewController.instance.view];
        }
    }
    else {
        _compassRequest = 0;
        [self switchRotateMapModeImpl];
    }
}

- (void) setRotationNoneToManual
{
    if ([_settings.rotateMap get] == ROTATE_MAP_NONE)
    {
        [_settings.rotateMap set:ROTATE_MAP_MANUAL];
        [OAUtilities showToast:nil details:[NSString stringWithFormat:@"%@: %@", OALocalizedString(@"rotate_map_to"), OALocalizedString(@"rotate_map_manual_opt")] duration:4 inView:OARootViewController.instance.view];
    }
}

- (void) updateSettings
{
    if (_mapViewController)
    {
        if ([_settings.rotateMap get] == ROTATE_MAP_NONE)
            [self animatedAlignAzimuthToNorth];
        else if ([_settings.rotateMap get] == ROTATE_MAP_MANUAL)
            [self animatedAlignAzimuth:[[OAAppSettings sharedManager].mapManuallyRotatingAngle get]];
        
        EOAPositionPlacement placement = (EOAPositionPlacement) [_settings.positionPlacementOnMap get];
        if (placement == EOAPositionPlacementAuto)
        {
            _mapViewController.mapPosition = ([_settings.rotateMap get] == ROTATE_MAP_BEARING && !_routePlanningMode ? BOTTOM_CONSTANT : CENTER_CONSTANT);
        }
        else
        {
            _mapViewController.mapPosition = (placement == EOAPositionPlacementCenter || _routePlanningMode ? CENTER_CONSTANT : BOTTOM_CONSTANT);
        }
    }
}

- (void) animatedAlignAzimuthToNorth
{
    [self animatedAlignAzimuth:0];
}

- (void) animatedAlignAzimuth:(CGFloat)azimuth
{
    if (!_mapViewController || ![_mapViewController isViewLoaded] || _mapView.azimuth == azimuth)
        return;
    
    _startChangingMapModeTime = CACurrentMediaTime();

    // When user gesture has began, stop all animations
    _mapView.mapAnimator->pause();
    _mapView.mapAnimator->cancelAllAnimations();
    
    // Animate azimuth change
    _mapView.mapAnimator->animateAzimuthTo(azimuth,
                                        kFastAnimationTime,
                                        OsmAnd::MapAnimator::TimingFunction::EaseOutQuadratic,
                                        kUserInteractionAnimationKey);
    _mapView.mapAnimator->resume();
}

- (CLLocation *) getDefaultLocation
{
    CLLocation *location = _app.locationServices.lastKnownLocation;
//    if (location == nil) {
//        getLocationProvider().getLastStaleKnownLocation();
//    }
    if (location != nil) {
        return location;
    }
    return [self getMapLocation];
}

- (CLLocation *) getMapLocation {
//    if (mapView == null) {
//        return settings.getLastKnownMapLocation();
//    }
    OsmAnd::LatLon centerLatLon = OsmAnd::Utilities::convert31ToLatLon(_mapView.target31);
    return [[CLLocation alloc] initWithLatitude:centerLatLon.latitude longitude:centerLatLon.longitude];
}

- (void) resetDrivingRegionUpdate
{
    _drivingRegionUpdated = NO;
    [self onLocationUpdate];
}

- (CGPoint) projectRatioToVisibleMapRect:(CGPoint)ratio
{
    if (!_mapView)
        return CGPointZero;
    
    CGRect visibleMapRect = [self calculateVisibleMapRect];
    CGSize viewSize = _mapView.bounds.size;
    float projectedRatioX = (visibleMapRect.origin.x + visibleMapRect.size.width * ratio.x) / viewSize.width;
    float projectedRatioY = (visibleMapRect.origin.y + visibleMapRect.size.height * ratio.y) / viewSize.height;

    return CGPointMake(projectedRatioX, projectedRatioY); //0.5  0.3887
}

- (CGRect) calculateVisibleMapRect
{
    OAMapRendererView *mapRenderer = [OARootViewController instance].mapPanel.mapViewController.mapView;
    CGSize windowSize = mapRenderer.bounds.size;

    CGFloat left = 0;
    CGFloat top = 0;
    CGFloat right = windowSize.width;
    CGFloat bottom = windowSize.height;

    //TODO: mock method. implement here code for splitting screen if needed. For now just return original screen size
    
    return CGRectMake(left, top, right, bottom);
}

- (void) onProfileSettingSet:(NSNotification *)notification
{
    OACommonPreference *obj = notification.object;
    OACommonInteger *centerPositionOnMap = [OAAppSettings sharedManager].positionPlacementOnMap;
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
