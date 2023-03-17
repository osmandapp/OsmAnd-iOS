//
//  OASunriseSunsetWidgetState.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 13.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OASunriseSunsetWidgetState.h"
#import "Localization.h"
#import "OAMapWidgetRegistry.h"
#import "OARootViewController.h"
#import "OAAppSettings.h"
#import "OASunriseSunsetWidget.h"

typedef NS_ENUM(NSInteger, EOASunriseSunsetWidgetType)
{
    SUNRISE_TYPE = 0,
    SUNSET_TYPE
};

@implementation OASunriseSunsetWidgetState
{
    OACommonInteger *_sunriseSunsetMode;
    EOASunriseSunsetWidgetType _type;
}

- (instancetype) initWithType:(BOOL)sunriseMode
{
    self = [super init];
    if (self)
    {
        _type = sunriseMode ? SUNRISE_TYPE : SUNSET_TYPE;
        _sunriseSunsetMode = sunriseMode ? [OAAppSettings sharedManager].sunriseMode : [OAAppSettings sharedManager].sunsetMode;
    }
    return self;
}

- (BOOL) isSunriseMode
{
    return _type == SUNRISE_TYPE;
}

- (NSString *) getMenuTitle
{
    if (_type == SUNRISE_TYPE)
        return OALocalizedString(@"map_widget_sunrise");
    else
        return OALocalizedString(@"map_widget_sunset");
}

- (NSString *)getMenuDescription
{
    if (_type == SUNRISE_TYPE)
        return OALocalizedString(@"map_widget_sunrise_desc");
    else
        return OALocalizedString(@"map_widget_sunset_desc");
}

- (NSString *) getMenuIconId
{
    if (_type == SUNRISE_TYPE)
        return @"widget_sunrise_day";
    else
        return @"widget_sunset_day";
}

- (NSString *) getMenuItemId
{
    return @((EOASunriseSunsetMode) [_sunriseSunsetMode get]).stringValue;
}

- (NSArray<NSString *> *) getMenuTitles
{
    switch (_type)
    {
        case SUNRISE_TYPE:
            return @[
                [OASunriseSunsetMode getTitle:EOASunriseSunsetHide isSunrise:YES],
                [OASunriseSunsetMode getTitle:EOASunriseSunsetTimeLeft isSunrise:YES],
                [OASunriseSunsetMode getTitle:EOASunriseSunsetNext isSunrise:YES]
            ];
        case SUNSET_TYPE:
            return @[
                [OASunriseSunsetMode getTitle:EOASunriseSunsetHide isSunrise:NO],
                [OASunriseSunsetMode getTitle:EOASunriseSunsetTimeLeft isSunrise:NO],
                [OASunriseSunsetMode getTitle:EOASunriseSunsetNext isSunrise:NO]
            ];
        default:
            return @[@""];
    }
}

- (NSArray<NSString *> *) getMenuDescriptions
{
    switch (_type)
    {
        case SUNRISE_TYPE:
            return @[
                [OASunriseSunsetWidget getDescription:EOASunriseSunsetHide isSunrise:YES],
                [OASunriseSunsetWidget getDescription:EOASunriseSunsetTimeLeft isSunrise:YES],
                [OASunriseSunsetWidget getDescription:EOASunriseSunsetNext isSunrise:YES]
            ];
        case SUNSET_TYPE:
            return @[
                [OASunriseSunsetWidget getDescription:EOASunriseSunsetHide isSunrise:NO],
                [OASunriseSunsetWidget getDescription:EOASunriseSunsetTimeLeft isSunrise:NO],
                [OASunriseSunsetWidget getDescription:EOASunriseSunsetNext isSunrise:NO]
            ];
        default:
            return @[@""];
    }
}

- (NSArray<NSString *> *) getMenuItemIds
{
    return @[
        @(EOASunriseSunsetHide).stringValue,
        @(EOASunriseSunsetTimeLeft).stringValue,
        @(EOASunriseSunsetNext).stringValue
    ];
}

- (void) changeState:(NSString *)stateId
{
    [_sunriseSunsetMode set:stateId.intValue];
}

@end
