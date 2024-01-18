//
//  OASunriseSunsetWidgetState.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 13.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OASunriseSunsetWidgetState.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAAppSettings.h"
#import "OASunriseSunsetWidget.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OASunriseSunsetWidgetState
{
    OAWidgetType *_type;
    OAAppSettings *_settings;
    OACommonInteger *_preference;
}

- (instancetype) initWithType:(BOOL)sunriseMode customId:(NSString *)customId
{
    self = [super init];
    if (self)
    {
        self.customId = customId;
        _settings = [OAAppSettings sharedManager];
        _type = sunriseMode ? OAWidgetType.sunrise : OAWidgetType.sunset;
        _preference = [self registerPreference:customId];
    }
    return self;
}

- (BOOL) isSunriseMode
{
    return _type == OAWidgetType.sunrise;
}

- (NSString *) getMenuTitle
{
    return _type.title;
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
        return @"widget_sunrise";
    else
        return @"widget_sunset";
}

- (NSString *)getSettingsIconId:(BOOL)nightMode
{
    return [_type iconName];
}

- (NSString *) getMenuItemId
{
    return @((EOASunriseSunsetMode) [[self getPreference] get]).stringValue;
}

- (NSArray<NSString *> *) getMenuTitles
{
    if (_type == OAWidgetType.sunrise)
    {
        return @[
            [OASunriseSunsetWidget getTitle:EOASunriseSunsetTimeLeft isSunrise:YES],
            [OASunriseSunsetWidget getTitle:EOASunriseSunsetNext isSunrise:YES]
        ];
    } else if (_type == OAWidgetType.sunset)
    {
        return @[
            [OASunriseSunsetWidget getTitle:EOASunriseSunsetTimeLeft isSunrise:NO],
            [OASunriseSunsetWidget getTitle:EOASunriseSunsetNext isSunrise:NO]
        ];
    }
    return @[@""];
}

- (NSArray<NSString *> *) getMenuDescriptions
{
    if (_type == OAWidgetType.sunrise)
    {
        return @[
            [OASunriseSunsetWidget getDescription:EOASunriseSunsetTimeLeft isSunrise:YES],
            [OASunriseSunsetWidget getDescription:EOASunriseSunsetNext isSunrise:YES]
        ];
    } else if (_type == OAWidgetType.sunset)
    {
        return @[
            [OASunriseSunsetWidget getDescription:EOASunriseSunsetTimeLeft isSunrise:NO],
            [OASunriseSunsetWidget getDescription:EOASunriseSunsetNext isSunrise:NO]
        ];
    }
    return @[@""];
}

- (NSArray<NSString *> *) getMenuItemIds
{
    return @[
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
    if (customId && customId.length > 0)
        prefId = [prefId stringByAppendingString:customId];

    return [_settings registerIntPreference:prefId defValue:EOASunriseSunsetTimeLeft];
}

@end
