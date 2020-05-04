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
#import "OADestination.h"
#import "OADestinationsHelper.h"

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
    
    NSString *_dayIcon;
    NSString *_nightIcon;
    NSString *_dayIconId;
    NSString *_nightIconId;
    NSString *_distance;
    NSString *_innerMarkerColor;
    OADestination *_markerDestination;
}

- (instancetype) initWithIcons:(NSString *)dayIconId nightIconId:(NSString *)nightIconId
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        
        _dayIconId = dayIconId;
        _nightIconId = nightIconId;
        
        self.colors = @[UIColorFromRGB(0xff9207),
                        UIColorFromRGB(0x00bcd4),
                        UIColorFromRGB(0x7fbd4d),
                        UIColorFromRGB(0xff444a),
                        UIColorFromRGB(0xcddc39)];
        
        self.markerNames = @[@"widget_marker_triangle_pin_1", @"widget_marker_triangle_pin_2", @"widget_marker_triangle_pin_3", @"widget_marker_triangle_pin_4", @"widget_marker_triangle_pin_5"];
        
        __weak OATextInfoWidget *selfWeak = self;
        selfWeak.onClickFunction = ^(id sender) {
            [self click];
        };
    }
    return self;
}

- (BOOL) updateInfo
{
    static BOOL firstWidget = YES;
    
    if ([OADestinationsHelper instance].sortedDestinations.count == 0 || ![_settings.distanceIndication get])
    {
        [self updateVisibility:NO];
        return NO;
    }
    
    CLLocation *currLoc = [_app.locationServices lastKnownLocation];
    NSArray *destinations = [OADestinationsHelper instance].sortedDestinations;
    
    if (firstWidget)
    {
        [self updateVisibility:YES];
        _markerDestination = (destinations.count >= 1 ? destinations[0] : nil);
        
        const auto dist = OsmAnd::Utilities::distance(_markerDestination.longitude, _markerDestination.latitude,
                                                      currLoc.coordinate.longitude, currLoc.coordinate.latitude);
        
        for (NSInteger i = 0; i < self.colors.count; i++)
            if ([_markerDestination.color isEqual:self.colors[i]])
                _innerMarkerColor = _markerNames[i];
        
        _distance = [_app getFormattedDistance:dist];
        [self setIcons:_dayIconId widgetNightIcon:_nightIconId];
        [self setText:_distance subtext:nil];
        firstWidget = NO;
    }
    else
    {
        if ([_settings.twoActiveMarker get] && destinations.count == 1)
        {
            [self updateVisibility:NO];
        }
        if ([_settings.twoActiveMarker get] && destinations.count > 1)
        {
            [self updateVisibility:YES];
            _markerDestination = (destinations.count >= 2 ? destinations[1] : nil);
            const auto dist = OsmAnd::Utilities::distance(_markerDestination.longitude, _markerDestination.latitude,
                                                          currLoc.coordinate.longitude, currLoc.coordinate.latitude);
            
            for (NSInteger i = 0; i < self.colors.count; i++)
                if ([_markerDestination.color isEqual:self.colors[i]])
                    _innerMarkerColor = _markerNames[i];
            
            _distance = [_app getFormattedDistance:dist];
            [self setIcons:_dayIconId widgetNightIcon:_nightIconId];
            [self setText:_distance subtext:nil];
        }
        firstWidget = YES;
    }
    
    return YES;
}

- (UIImage *) drawImage:(UIImage*) fgImage inImage:(UIImage*) bgImage
{
    UIGraphicsBeginImageContextWithOptions(bgImage.size, NO, 0.0);
    
    [bgImage drawInRect:CGRectMake( 0, 0, bgImage.size.width, bgImage.size.height)];
    [fgImage drawInRect:CGRectMake( 0.0, 0.0, fgImage.size.width, fgImage.size.height)];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (BOOL) setIcons:(NSString *)widgetDayIcon widgetNightIcon:(NSString *)widgetNightIcon
{
    _dayIcon = widgetDayIcon;
    _nightIcon = widgetNightIcon;
    UIImage *markerIcon = [self drawImage:[UIImage imageNamed:_innerMarkerColor] inImage:[UIImage imageNamed:(![self isNight] ? _dayIcon : _nightIcon)]];
    [self setImage:markerIcon];
    return YES;
}

- (void) click
{
    if (_markerDestination.hidden)
        [[OADestinationsHelper instance] showOnMap:_markerDestination];
    
    [[OARootViewController instance].mapPanel hideDestinationCardsView];
    [[OARootViewController instance].mapPanel openTargetViewWithDestination:_markerDestination];
    
}

- (CLLocation *) getPointToNavigate
{
    return nil;
}

- (CLLocationDistance) getDistance
{
    CLLocationDistance d = 0;
    
    return d;
}

@end
