//
//  OADistanceToPointInfoControl.m
//  OsmAnd
//
//  Created by Alexey Kulish on 01/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OADistanceToPointWidget.h"
#import "OsmAndApp.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAUtilities.h"
#import "OANativeUtilities.h"
#import "OAOsmAndFormatter.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

@implementation OADistanceToPointWidget
{
    OsmAndAppInstance _app;
    CLLocationDistance _cachedMeters;
}

- (instancetype) initWithIcons:(NSString *)dayIconId nightIconId:(NSString *)nightIconId
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        
        if (dayIconId && nightIconId)
            [self setIcons:dayIconId widgetNightIcon:nightIconId];
        [self setText:nil subtext:nil];
        __weak OADistanceToPointWidget *selfWeak = self;
        self.onClickFunction = ^(id sender) {
            [selfWeak click];
        };
    }
    return self;
}

- (CLLocation *) getPointToNavigate
{
    return nil;
}

- (void) click
{
    OAMapViewController *map = [OARootViewController instance].mapPanel.mapViewController;
    float zoom = [map getMapZoom] < 15 ? 15 : [map getMapZoom];
    CLLocation *location = [self getPointToNavigate];
    if (location)
        [map goToPosition:[OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(location.coordinate.latitude, location.coordinate.longitude))] andZoom:zoom animated:YES];
}

- (CLLocationDistance) getDistance
{
    CLLocationDistance d = 0;
    CLLocation *l = [self getPointToNavigate];
    if (l)
    {
        OAMapViewController *map = [OARootViewController instance].mapPanel.mapViewController;
        d = [l distanceFromLocation:[map getMapLocation]];
    }
    return d;
}

- (BOOL) distChanged:(CLLocationDistance)oldDist dist:(CLLocationDistance)dist
{
    return oldDist == 0 || ABS(oldDist - dist) > 10;
}

- (BOOL) updateInfo
{
    CLLocationDistance d = [self getDistance];
    if ([self isUpdateNeeded] || [self distChanged:_cachedMeters dist:d])
    {
        _cachedMeters = d;
        if (_cachedMeters <= 20)
        {
            _cachedMeters = 0;
            [self setText:nil subtext:nil];
        }
        else
        {
            NSString *ds = [OAOsmAndFormatter.instance getFormattedDistance:_cachedMeters];
            int ls = [ds indexOf:@" "];
            if (ls == -1)
                [self setText:ds subtext:nil];
            else
                [self setText:[ds substringToIndex:ls] subtext:[ds substringFromIndex:ls + 1]];
        }
        return YES;
    }
    return NO;
}

@end
