//
//  OADistanceToMapMarkerControl.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 27.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADistanceToMapMarkerControl.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapPanelViewController.h"
#import "OALocationServices.h"
#import "OADestination.h"
#import "OADestinationsHelper.h"
#import "OAColors.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

@interface OADistanceToMapMarkerControl()

@property (nonatomic) NSArray *colors;
@property (nonatomic) NSArray *markerNames;

@end

@implementation OADistanceToMapMarkerControl
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    BOOL _firstWidget;
    
    NSString *_icon;
    NSString *_iconId;
    NSString *_distance;
    NSString *_innerMarkerColor;
    OADestination *_markerDestination;
}

- (instancetype) initWithIcon:(NSString *)iconId firstMarker:(BOOL)firstMarker
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _iconId = iconId;
        _firstWidget = firstMarker;
        self.colors = @[UIColorFromRGB(marker_pin_color_orange),
                        UIColorFromRGB(marker_pin_color_blue),
                        UIColorFromRGB(marker_pin_color_green),
                        UIColorFromRGB(marker_pin_color_red),
                        UIColorFromRGB(marker_pin_color_light_green)];
        self.markerNames = @[@"widget_marker_triangle_pin_1", @"widget_marker_triangle_pin_2", @"widget_marker_triangle_pin_3", @"widget_marker_triangle_pin_4", @"widget_marker_triangle_pin_5"];
        [self setText:nil subtext:nil];
        __weak OADistanceToMapMarkerControl *selfWeak = self;
        self.onClickFunction = ^(id sender) {
            [selfWeak onWidgetClicked];
        };
    }
    return self;
}

- (BOOL) updateInfo
{
    if ([OADestinationsHelper instance].sortedDestinations.count == 0)
    {
        [self updateVisibility:NO];
        return NO;
    }
    
    CLLocation *currLoc = [_app.locationServices lastKnownLocation];
    NSArray *destinations = [OADestinationsHelper instance].sortedDestinations;
    
    if (_firstWidget)
    {
        [self updateVisibility:YES];
        _markerDestination = (destinations.count >= 1 ? destinations[0] : nil);
        _distance = [_markerDestination distanceStr:currLoc.coordinate.latitude longitude:currLoc.coordinate.longitude];
       
        for (NSInteger i = 0; i < self.colors.count; i++)
            if ([_markerDestination.color isEqual:self.colors[i]])
                _innerMarkerColor = _markerNames[i];
        
        [self setIcon:_iconId];
        [self setText:_distance subtext:nil];
    }
    else
    {
        if ([_settings.activeMarkers get] == TWO_ACTIVE_MARKERS && destinations.count == 1)
            [self updateVisibility:NO];
        else if ([_settings.activeMarkers get] == TWO_ACTIVE_MARKERS && destinations.count > 1)
        {
            [self updateVisibility:YES];
            _markerDestination = (destinations.count >= 2 ? destinations[1] : nil);
            _distance = [_markerDestination distanceStr:currLoc.coordinate.latitude longitude:currLoc.coordinate.longitude];
            
            for (NSInteger i = 0; i < self.colors.count; i++)
                if ([_markerDestination.color isEqual:self.colors[i]])
                    _innerMarkerColor = _markerNames[i];

            [self setIcon:_iconId];
            [self setText:_distance subtext:nil];
        }
    }
    return YES;
}

- (UIImage *) drawImage:(UIImage*)fgImage inImage:(UIImage*)bgImage
{
    UIGraphicsBeginImageContextWithOptions(bgImage.size, NO, 0.0);
    
    [bgImage drawInRect:CGRectMake(0.0, 0.0, bgImage.size.width, bgImage.size.height)];
    if (fgImage)
        [fgImage drawInRect:CGRectMake(0.0, 0.0, fgImage.size.width, fgImage.size.height)];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (BOOL) setIcon:(NSString *)widgetIcon
{
    _icon = widgetIcon;
    UIImage *innerMarkerImage = _innerMarkerColor ? [UIImage imageNamed:_innerMarkerColor] : nil;
    UIImage *markerIcon = [self drawImage:innerMarkerImage inImage:[UIImage imageNamed:_icon]];
    [self setImage:markerIcon];
    return YES;
}

- (void) onWidgetClicked
{
    if (_markerDestination.hidden)
        [[OADestinationsHelper instance] showOnMap:_markerDestination];

    [[OARootViewController instance].mapPanel openTargetViewWithDestination:_markerDestination];
}

@end
