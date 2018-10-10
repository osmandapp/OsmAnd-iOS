//
//  OAMapInfoWidgetsFactory.m
//  OsmAnd
//
//  Created by Alexey Kulish on 27/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAMapInfoWidgetsFactory.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OATextInfoWidget.h"
#import "OAUtilities.h"
#import "OARulerWidget.h"
#import "OARootViewController.h"
#import "OAMapViewTrackingUtilities.h"

#include <OsmAndCore/Utilities.h>

@implementation OAMapInfoWidgetsFactory
{
    OsmAndAppInstance _app;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
    }
    return self;
}

- (OATextInfoWidget *) createAltitudeControl
{
    OATextInfoWidget *altitudeControl = [[OATextInfoWidget alloc] init];
    __weak OATextInfoWidget *altitudeControlWeak = altitudeControl;
    int __block cachedAlt = 0;
    altitudeControl.updateInfoFunction = ^BOOL{
        // draw speed
        CLLocation *loc = _app.locationServices.lastKnownLocation;
        if (loc && loc.verticalAccuracy >= 0)
        {
            CLLocationDistance compAlt = loc.altitude;
            if (cachedAlt != (int) compAlt)
            {
                cachedAlt = (int) compAlt;
                NSString *ds = [_app getFormattedAlt:cachedAlt];
                int ls = [ds indexOf:@" "];
                if (ls == -1)
                    [altitudeControlWeak setText:ds subtext:nil];
                else
                    [altitudeControlWeak setText:[ds substringToIndex:ls] subtext:[ds substringFromIndex:ls + 1]];
                
                return true;
            }
        }
        else if (cachedAlt != 0)
        {
            cachedAlt = 0;
            [altitudeControlWeak setText:nil subtext:nil];
            return true;
        }
        return false;

    };
    
    [altitudeControl setText:nil subtext:nil];
    [altitudeControl setIcons:@"widget_altitude_day" widgetNightIcon:@"widget_altitude_night"];
    return altitudeControl;
}

- (OATextInfoWidget *) createRulerControl
{
    NSString *title = @"-";
    OATextInfoWidget *rulerControl = [[OATextInfoWidget alloc] init];
    __weak OATextInfoWidget *rulerControlWeak = rulerControl;
    
    rulerControl.updateInfoFunction = ^BOOL{
        CLLocation *currentLocation = _app.locationServices.lastKnownLocation;
        CLLocation *centerLocation = [[OARootViewController instance].mapPanel.mapViewController getMapLocation];
        if (currentLocation && centerLocation) {
            OAMapViewTrackingUtilities *trackingUtilities = [OAMapViewTrackingUtilities instance];
            if ([trackingUtilities isMapLinkedToLocation]) {
                [rulerControlWeak setText:[_app getFormattedDistance:0] subtext:nil];
            }
            else {
                const auto distance = OsmAnd::Utilities::distance(currentLocation.coordinate.longitude, currentLocation.coordinate.latitude,
                                                                  centerLocation.coordinate.longitude, centerLocation.coordinate.latitude);
                NSString *formattedDistance = [_app getFormattedDistance:distance];
                NSUInteger ls = [formattedDistance rangeOfString:@" " options:NSBackwardsSearch].location;
                [rulerControlWeak setText:[formattedDistance substringToIndex:ls] subtext:[formattedDistance substringFromIndex:ls + 1]];
            }
        }
        return YES;
    };
    return rulerControl;
    //    final String title = "—";
    //    final TextInfoWidget rulerControl = new TextInfoWidget(map) {
    //        RulerControlLayer rulerLayer = map.getMapLayers().getRulerControlLayer();
    //        LatLon cacheFirstTouchPoint = new LatLon(0, 0);
    //        LatLon cacheSecondTouchPoint = new LatLon(0, 0);
    //        LatLon cacheSingleTouchPoint = new LatLon(0, 0);
    //        boolean fingerAndLocDistWasShown;
    //
    //        @Override
    //        public boolean updateInfo(DrawSettings drawSettings) {
    //            OsmandMapTileView view = map.getMapView();
    //            Location currentLoc = map.getMyApplication().getLocationProvider().getLastKnownLocation();
    //
    //            if (rulerLayer.isShowDistBetweenFingerAndLocation() && currentLoc != null) {
    //                if (!cacheSingleTouchPoint.equals(rulerLayer.getTouchPointLatLon())) {
    //                    cacheSingleTouchPoint = rulerLayer.getTouchPointLatLon();
    //                    setDistanceText(cacheSingleTouchPoint.getLatitude(), cacheSingleTouchPoint.getLongitude(),
    //                                    currentLoc.getLatitude(), currentLoc.getLongitude());
    //                    fingerAndLocDistWasShown = true;
    //                }
    //            } else if (rulerLayer.isShowTwoFingersDistance()) {
    //                if (!cacheFirstTouchPoint.equals(view.getFirstTouchPointLatLon()) ||
    //                    !cacheSecondTouchPoint.equals(view.getSecondTouchPointLatLon()) ||
    //                    fingerAndLocDistWasShown) {
    //                    cacheFirstTouchPoint = view.getFirstTouchPointLatLon();
    //                    cacheSecondTouchPoint = view.getSecondTouchPointLatLon();
    //                    setDistanceText(cacheFirstTouchPoint.getLatitude(), cacheFirstTouchPoint.getLongitude(),
    //                                    cacheSecondTouchPoint.getLatitude(), cacheSecondTouchPoint.getLongitude());
    //                    fingerAndLocDistWasShown = false;
    //                }
    //            } else {
    //                LatLon centerLoc = map.getMapLocation();
    //
    //                if (currentLoc != null && centerLoc != null) {
    //                    if (map.getMapViewTrackingUtilities().isMapLinkedToLocation()) {
    //                        setDistanceText(0);
    //                    } else {
    //                        setDistanceText(currentLoc.getLatitude(), currentLoc.getLongitude(),
    //                                        centerLoc.getLatitude(), centerLoc.getLongitude());
    //                    }
    //                } else {
    //                    setText(title, null);
    //                }
    //            }
    //            return true;
}

@end
