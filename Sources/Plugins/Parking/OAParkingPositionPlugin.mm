//
//  OAParkingPositionPlugin.m
//  OsmAnd
//
//  Created by Alexey Kulish on 01/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAParkingPositionPlugin.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OATextInfoWidget.h"
#import "OAApplicationMode.h"
#import "OAIAPHelper.h"
#import "OAMapPanelViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapInfoController.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "PXAlertView.h"
#import "OADestinationsHelper.h"
#import "OADestination.h"
#import "OARoutingHelper.h"
#import "OAMapViewController.h"
#import "OANativeUtilities.h"
#import "OAParkingAction.h"
#import "OAFavoritesHelper.h"
#import "OAFavoriteItem.h"
#import "OAOsmAndFormatter.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

#define PLUGIN_ID kInAppId_Addon_Parking

#define PARKING_TYPE @"parking_type"
#define PARKING_POINT_LAT @"parking_point_lat"
#define PARKING_POINT_LON @"parking_point_lon"
#define PARKING_TIME @"parking_limit_time"
#define PARKING_START_TIME @"parking_time"
#define PARKING_EVENT_ADDED @"parking_event_added"
#define PARKING_EVENT_ID @"parking_event_id"

@interface OAParkingPositionPlugin ()

@property (nonatomic) OsmAndAppInstance app;
@property (nonatomic) OAAppSettings *settings;
@property (nonatomic) OADestinationsHelper *helper;

@property (nonatomic) CLLocation *parkingPosition;

@end

@implementation OAParkingPositionPlugin
{
    OATextInfoWidget *_parkingPlaceControl;
    
    OACommonDouble *_parkingLat;
    OACommonDouble *_parkingLon;
    OACommonBoolean *_parkingType;
    OACommonBoolean *_parkingEvent;
    OACommonLong *_parkingTime;
    OACommonLong *_parkingStartTime;
    OACommonString *_parkingEventId;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _helper = [OADestinationsHelper instance];
        [OAApplicationMode regWidgetVisibility:PLUGIN_ID am:nil];
        
        _parkingLat = [[[OACommonDouble withKey:PARKING_POINT_LAT defValue:0.] makeShared] makeGlobal];
        _parkingLon = [[[OACommonDouble withKey:PARKING_POINT_LON defValue:0.] makeShared] makeGlobal];
        _parkingType = [[[OACommonBoolean withKey:PARKING_TYPE defValue:NO] makeShared] makeGlobal];
        _parkingEvent = [[[OACommonBoolean withKey:PARKING_EVENT_ADDED defValue:NO] makeShared] makeGlobal];
        _parkingTime = [[[OACommonLong withKey:PARKING_TIME defValue:-1] makeShared] makeGlobal];
        _parkingStartTime = [[[OACommonLong withKey:PARKING_START_TIME defValue:-1] makeShared] makeGlobal];
        _parkingEventId = [[[OACommonString withKey:PARKING_EVENT_ID defValue:nil] makeShared] makeGlobal];
        _parkingPosition = [self constructParkingPosition];
    }
    return self;
}

- (CLLocation *)constructParkingPosition
{
    double lat = _parkingLat.get;
    double lon = _parkingLon.get;
    if (lat == 0 && lon == 0)
        return nil;
    return [[CLLocation alloc] initWithLatitude:lat longitude:lon];
}

- (BOOL) getParkingType
{
    return _parkingType.get;
}

- (BOOL) isParkingEventAdded
{
    return _parkingEvent.get;
}

- (void) addOrRemoveParkingEvent:(BOOL)added
{
    [_parkingEvent set:added];
}

- (long) getParkingTime
{
    return _parkingTime.get;
}

- (long) getStartParkingTime
{
    return _parkingStartTime.get;
}

- (BOOL) clearParkingPosition
{
    [_parkingLat resetToDefault];
    [_parkingLon resetToDefault];
    [_parkingType resetToDefault];
    [_parkingTime resetToDefault];
    [_parkingEvent resetToDefault];
    [_parkingStartTime resetToDefault];
    [OAFavoritesHelper removeParkingReminderFromCalendar];
    _parkingPosition = nil;
    OAFavoriteItem *pnt = [OAFavoritesHelper getSpecialPoint:[OASpecialPointType PARKING]];
    if (pnt)
        [OAFavoritesHelper deleteFavoriteGroups:nil andFavoritesItems:@[pnt]];
    return YES;
}

- (void) setParkingPosition:(double)latitude longitude:(double)longitude limited:(BOOL)limited
{
    [self setParkingPosition:latitude longitude:longitude];
    [self setParkingType:limited];
    [self setParkingStartTime:NSDate.date.timeIntervalSince1970 * 1000];
}

- (BOOL) setParkingPosition:(double)latitude longitude:(double)longitude
{
    [_parkingLat set:latitude];
    [_parkingLon set:longitude];
    _parkingPosition = [self constructParkingPosition];
    return YES;
}

- (BOOL) setParkingType:(BOOL)limited
{
    if (!limited)
        [_parkingTime set:-1];
    [_parkingType set:limited];
    return YES;
}

- (BOOL) setParkingTime:(long)timeInMillis
{
    [_parkingTime set:timeInMillis];
    return YES;
}

- (BOOL) setParkingStartTime:(long)timeInMillis
{
    [_parkingStartTime set:timeInMillis];
    return YES;
}

- (void) setEventIdentifier:(NSString *)eventId
{
    [_parkingEventId set:eventId];
}

- (NSString *) getEventIdentifier
{
    return [_parkingEventId get];
}

- (CLLocation *)getParkingPosition
{
    return self.parkingPosition;
}

- (NSString *) getId
{
    return PLUGIN_ID;
}

- (void) registerLayers
{
    [self registerWidget];
}

- (void) registerWidget
{
    OAMapInfoController *mapInfoController = [self getMapInfoController];
    if (mapInfoController)
    {
        _parkingPlaceControl = [self createParkingPlaceInfoControl];
        
        [mapInfoController registerSideWidget:_parkingPlaceControl imageId:@"ic_custom_parking" message:[self getName] key:PLUGIN_ID left:NO priorityOrder:10];
        [mapInfoController recreateControls];
    }
}

- (void) updateLayers
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self isActive])
        {
            if (!_parkingPlaceControl)
                [self registerWidget];
        }
        else
        {
            if (_parkingPlaceControl)
            {
                OAMapInfoController *mapInfoController = [self getMapInfoController];
                [mapInfoController removeSideWidget:_parkingPlaceControl];
                [mapInfoController recreateControls];
                _parkingPlaceControl = nil;
            }
        }
    });
}

- (OATextInfoWidget *) createParkingPlaceInfoControl
{
    _parkingPlaceControl = [[OATextInfoWidget alloc] init];
    __weak OATextInfoWidget *parkingPlaceControlWeak = _parkingPlaceControl;
    __weak OAParkingPositionPlugin *pluginWeak = self;
    
    CLLocationDistance __block cachedMeters = 0;
    _parkingPlaceControl.updateInfoFunction = ^BOOL{
        
        CLLocation *parking = pluginWeak.parkingPosition;
        if (parking)
        {
            OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
            CLLocation *parkingPoint = [[CLLocation alloc] initWithLatitude:parking.coordinate.latitude longitude:parking.coordinate.longitude];
            if (![routingHelper isFollowingMode])
            {
                CLLocation *mapLocation = [[pluginWeak getMapViewController] getMapLocation];
                CLLocationDistance d = [parkingPoint distanceFromLocation:mapLocation];

                if ([pluginWeak distChanged:cachedMeters dist:d])
                {
                    cachedMeters = d;
                    if (cachedMeters <= 20)
                    {
                        cachedMeters = 0;
                        [parkingPlaceControlWeak setText:nil subtext:nil];
                    }
                    else
                    {
                        NSString *ds = [OAOsmAndFormatter.instance getFormattedDistance:cachedMeters];
                        int ls = [ds indexOf:@" "];
                        if (ls == -1)
                            [parkingPlaceControlWeak setText:ds subtext:nil];
                        else
                            [parkingPlaceControlWeak setText:[ds substringToIndex:ls] subtext:[ds substringFromIndex:ls + 1]];
                    }
                    return YES;
                }
            }
            else if (cachedMeters != 0)
            {
                cachedMeters = 0;
                [parkingPlaceControlWeak setText:nil subtext:nil];
                return YES;
            }
        }
        else if (cachedMeters != 0)
        {
            cachedMeters = 0;
            [parkingPlaceControlWeak setText:nil subtext:nil];
            return YES;
        }
        return NO;
    };
    
    _parkingPlaceControl.onClickFunction = ^(id sender) {
        CLLocation *parking = pluginWeak.parkingPosition;
        if (parking)
        {
            OAMapViewController *map = [pluginWeak getMapViewController];
            float zoom = [map getMapZoom] < 15 ? 15 : [map getMapZoom];
            [map goToPosition:[OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(parking.coordinate.latitude, parking.coordinate.longitude))] andZoom:zoom animated:YES];
        }
    };
    
    [_parkingPlaceControl setText:nil subtext:nil];
    [_parkingPlaceControl setIcons:@"widget_parking_day" widgetNightIcon:@"widget_parking_night"];
    return _parkingPlaceControl;
}

- (BOOL) distChanged:(CLLocationDistance)oldDist dist:(CLLocationDistance)dist
{
    return oldDist == 0 || ABS(oldDist - dist) > 30;
}

- (NSArray *)getQuickActionTypes
{
    return @[OAParkingAction.TYPE];
}

@end
