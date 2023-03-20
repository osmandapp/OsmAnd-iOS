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
    EOASunriseSunsetWidgetType _type;
    OAAppSettings *_settings;
    OACommonInteger *_preference;
}

- (instancetype) initWithType:(BOOL)sunriseMode customId:(NSString *)customId
{
    self = [super init];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
        _type = sunriseMode ? SUNRISE_TYPE : SUNSET_TYPE;
        _preference = [self registerPreference:customId];
    }
    return self;
}

- (BOOL) isSunriseMode
{
    return _type == SUNRISE_TYPE;
}

- (NSString *) getMenuTitle
{
    if ([self isSunriseMode])
        return OALocalizedString(@"map_widget_sunrise");
    else
        return OALocalizedString(@"map_widget_sunset");
}

- (NSString *)getMenuDescription
{
    if ([self isSunriseMode])
        return OALocalizedString(@"map_widget_sunrise_desc");
    else
        return OALocalizedString(@"map_widget_sunset_desc");
}

- (NSString *) getMenuIconId
{
    if ([self isSunriseMode])
        return @"widget_sunrise_day";
    else
        return @"widget_sunset_day";
}

- (NSString *) getMenuItemId
{
    return @((EOASunriseSunsetMode) [[self getPreference] get]).stringValue;
}

- (NSArray<NSString *> *) getMenuTitles
{
    switch (_type)
    {
        case SUNRISE_TYPE:
            return @[
                [OASunriseSunsetWidget getTitle:EOASunriseSunsetHide isSunrise:YES],
                [OASunriseSunsetWidget getTitle:EOASunriseSunsetTimeLeft isSunrise:YES],
                [OASunriseSunsetWidget getTitle:EOASunriseSunsetNext isSunrise:YES]
            ];
        case SUNSET_TYPE:
            return @[
                [OASunriseSunsetWidget getTitle:EOASunriseSunsetHide isSunrise:NO],
                [OASunriseSunsetWidget getTitle:EOASunriseSunsetTimeLeft isSunrise:NO],
                [OASunriseSunsetWidget getTitle:EOASunriseSunsetNext isSunrise:NO]
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

- (OACommonInteger *) getPreference
{
    return _preference;
}

- (void) changeState:(NSString *)stateId
{
    [_preference set:stateId.intValue];
}

- (void) copyPrefs:(OAApplicationMode *)appMode customId:(NSString *)customId
{
    [[self registerPreference:customId] set:[_preference get:appMode] mode:appMode];
}

- (OACommonInteger *) registerPreference:(NSString *)customId
{
    NSString *prefId = [self isSunriseMode] ? @"show_sunrise_info" : @"show_sunset_info";
    if (customId && customId.length >0)
        prefId = [prefId stringByAppendingString:customId];

    return [_settings registerIntPreference:prefId defValue:EOASunriseSunsetHide];
}

@end
