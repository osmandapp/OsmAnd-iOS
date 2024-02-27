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
    OAWidgetType *_widgetType;
    OAAppSettings *_settings;
    OACommonInteger *_preference;
    OACommonInteger *_sunPositionPreference;
}

- (instancetype)initWithWidgetType:(OAWidgetType *)widgetType
                                   customId:(NSString *)customId;
{
    self = [super init];
    if (self)
    {
        self.customId = customId;
        _widgetType = widgetType;
        _settings = [OAAppSettings sharedManager];
        _preference = [self registerPreference:customId];
        _sunPositionPreference = [self registerSunPositionPreference:customId];
    }
    return self;
}

- (OAWidgetType *)getWidgetType
{
    return _widgetType;
}

- (OACommonInteger *)getSunPositionPreference {
    return _sunPositionPreference;
}

- (BOOL) isSunriseMode
{
    return _widgetType == OAWidgetType.sunrise;
}

- (NSString *)getTitleForSunPositionMode:(SunPositionMode)mode
{
    switch (mode)
    {
        case SunPositionModeSunPositionMode:
            return OALocalizedString(@"shared_string_next_event");
        case SunPositionModeSunsetMode:
            return OALocalizedString(@"map_widget_sunset");
        case SunPositionModeSunriseMode:
            return OALocalizedString(@"map_widget_sunrise");
    }
}

- (NSString *)getWidgetIconName {
    SunPositionMode sunPositionMode = (SunPositionMode)[_sunPositionPreference get];
    
    NSString *sunsetStringId = @"widget_sunset";
    NSString *sunriseStringId = @"widget_sunrise";
    
    if (OAWidgetType.sunset == _widgetType || (OAWidgetType.sunPosition == _widgetType && sunPositionMode == SunPositionModeSunsetMode)) {
        return sunsetStringId;
    } else if (OAWidgetType.sunPosition == _widgetType && sunPositionMode == SunPositionModeSunPositionMode) {
        return _lastIsDayTime ? sunsetStringId : sunriseStringId;
    } else {
        return sunriseStringId;
    }
}

- (NSString *)getMenuTitle
{
    if (_widgetType == OAWidgetType.sunPosition)
    {
        SunPositionMode sunPositionMode = (SunPositionMode)[_sunPositionPreference get];
        return [NSString stringWithFormat:@"%@: %@", _widgetType.title, [self getTitleForSunPositionMode:sunPositionMode]];
    }
    return _widgetType.title;
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
    return [_widgetType iconName];
}

- (NSString *) getMenuItemId
{
    return @((EOASunriseSunsetMode) [[self getPreference] get]).stringValue;
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

- (NSString *)getPrefId {
    NSString *prefId;
    if (_widgetType == OAWidgetType.sunset)
    {
        prefId = @"show_sunset_info";
    } else if (_widgetType == OAWidgetType.sunrise)
    {
        prefId = @"show_sunrise_info";
    } else if (_widgetType == OAWidgetType.sunPosition)
    {
        prefId = @"show_sun_position_info";
    }
    return prefId;
}

- (OACommonInteger *)registerPreference:(NSString *)customId
{
    NSString *prefId = [self getPrefId];
    if (customId && customId.length > 0)
        prefId = [prefId stringByAppendingString:customId];

    return [[_settings registerIntPreference:prefId defValue:EOASunriseSunsetTimeLeft] makeProfile];
}

- (OACommonInteger *)registerSunPositionPreference:(NSString *)customId {
    NSString *prefId = @"sun_position_widget_mode";
    if (customId && customId.length > 0)
        prefId = [prefId stringByAppendingString:customId];

    return [[_settings registerIntPreference:prefId defValue:SunPositionModeSunPositionMode] makeProfile];
}


@end
