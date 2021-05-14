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

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

#define PLUGIN_ID kInAppId_Addon_Parking
#define PARKING_TYPE @"parking_type"

@interface OAParkingPositionPlugin ()

@property (nonatomic) OsmAndAppInstance app;
@property (nonatomic) OAAppSettings *settings;
@property (nonatomic) OADestinationsHelper *helper;

@end

@implementation OAParkingPositionPlugin
{
    OATextInfoWidget *_parkingPlaceControl;
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
    }
    return self;
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
        
        OADestination *parking = [pluginWeak.helper getParkingPoint];
        if (parking)
        {
            OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
            CLLocation *parkingPoint = [[CLLocation alloc] initWithLatitude:parking.latitude longitude:parking.longitude];
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
                        NSString *ds = [pluginWeak.app getFormattedDistance:cachedMeters];
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
        OADestination *parking = [pluginWeak.helper getParkingPoint];
        if (parking)
        {
            OAMapViewController *map = [pluginWeak getMapViewController];
            float zoom = [map getMapZoom] < 15 ? 15 : [map getMapZoom];
            [map goToPosition:[OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(parking.latitude, parking.longitude))] andZoom:zoom animated:YES];
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
