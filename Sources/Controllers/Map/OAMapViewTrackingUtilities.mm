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

#include <commonOsmAndCore.h>

@interface OAMapViewTrackingUtilities ()

@end

@implementation OAMapViewTrackingUtilities
{
    long _lastTimeAutoZooming;
    BOOL _sensorRegistered;
    OAMapViewController *_mapViewController;
    OAAppSettings *_settings;
    OsmAndAppInstance _app;
    BOOL _followingMode;
    BOOL _routePlanningMode;
    BOOL _isUserZoomed;
    BOOL _showRouteFinishDialog;
    BOOL _drivingRegionUpdated;
    
    OAAutoObserverProxy* _locationServicesUpdateObserver;
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

- (void) onLocationServicesUpdate
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Obtain fresh location and heading
        CLLocation* newLocation = _app.locationServices.lastKnownLocation;
        CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;
        
        _myLocation = newLocation;
        _heading = newHeading;
        if (_mapViewController && newHeading >= 0)
        {
            /*
            double speedForDirectionOfMovement = [_settings.switchMapDirectionToCompass get];
            BOOL smallSpeedForDirectionOfMovement = speedForDirectionOfMovement != 0 && _myLocation && [self.class isSmallSpeedForDirectionOfMovement:_mylocation speedToDirectionOfMovement:speedForDirectionOfMovement];
            if (([_settings.rotateMap get] == ROTATE_MAP_COMPASS || ([_settings.rotateMap get] == ROTATE_MAP_BEARING && smallSpeedForDirectionOfMovement)) && !_routePlanningMode)
            {
                if (ABS(degreesDiff(_mapView.azimuth, -newHeading)) > 1)
                    mapView.setRotate(-val);
            }
            else if (_showViewAngle)
            {
                //mapView.refreshMap();
            }
             */
        }
        
    });
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
            [_mapViewController animatedAlignAzimuthToNorth];
        
        _mapViewController.mapPosition = ([_settings.rotateMap get] == ROTATE_MAP_BEARING && !_routePlanningMode && ![_settings.centerPositionOnMap get] ? BOTTOM_CONSTANT : CENTER_CONSTANT);
    }
}

- (void) resetDrivingRegionUpdate
{
    _drivingRegionUpdated = NO;
}

@end
