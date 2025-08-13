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
#import "OAApplicationMode.h"
#import "OASunriseSunsetWidget.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OASunriseSunsetWidgetState
{
    OAWidgetType *_widgetType;
    OAAppSettings *_settings;
    OACommonInteger *_preference;
    OACommonSunPositionMode *_sunPositionPreference;
}

- (instancetype)initWithWidgetType:(OAWidgetType *)widgetType
                          customId:(NSString *)customId
                      widgetParams:(NSDictionary *)widgetParams;
{
    self = [super init];
    if (self)
    {
        self.customId = customId;
        _widgetType = widgetType;
        _settings = [OAAppSettings sharedManager];
        _preference = [self registerPreference:customId widgetParams:widgetParams];
        _sunPositionPreference = [self registerSunPositionPreference:customId widgetParams:widgetParams];
    }
    return self;
}

- (OAWidgetType *)getWidgetType
{
    return _widgetType;
}

- (OACommonSunPositionMode *)getSunPositionPreference {
    return _sunPositionPreference;
}

- (BOOL) isSunriseMode
{
    return _widgetType == OAWidgetType.sunrise;
}

- (NSString *)getTitleForSunPositionMode:(EOASunPositionMode)mode
{
    switch (mode)
    {
        case EOASunPositionModeSunPositionMode:
            return OALocalizedString(@"shared_string_next_event");
        case EOASunPositionModeSunsetMode:
            return OALocalizedString(@"map_widget_sunset");
        case EOASunPositionModeSunriseMode:
            return OALocalizedString(@"map_widget_sunrise");
    }
}

- (NSString *)getWidgetIconName {
    EOASunPositionMode sunPositionMode = (EOASunPositionMode)[_sunPositionPreference get];
    
    NSString *sunsetStringId = @"widget_sunset";
    NSString *sunriseStringId = @"widget_sunrise";
    
    if (OAWidgetType.sunset == _widgetType || (OAWidgetType.sunPosition == _widgetType && sunPositionMode == EOASunPositionModeSunsetMode)) {
        return sunsetStringId;
    } else if (OAWidgetType.sunPosition == _widgetType && sunPositionMode == EOASunPositionModeSunPositionMode) {
        return _lastIsDayTime ? sunsetStringId : sunriseStringId;
    } else {
        return sunriseStringId;
    }
}

- (NSString *)getMenuTitle
{
    if (_widgetType == OAWidgetType.sunPosition)
    {
        EOASunPositionMode sunPositionMode = (EOASunPositionMode)[_sunPositionPreference get];
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
    [[self registerPreference:customId widgetParams:nil] set:[_preference get:appMode] mode:appMode];
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

- (OACommonInteger *)registerPreference:(NSString *)customId widgetParams:(nullable NSDictionary *)widgetParams
{
    NSString *prefId = [self getPrefId];
    if (customId && customId.length > 0)
        prefId = [prefId stringByAppendingString:customId];
    
    OACommonInteger *preference = [[[OAAppSettings sharedManager] registerIntPreference:prefId defValue:EOASunriseSunsetTimeLeft] makeProfile];
    
    if (widgetParams)
    {
        NSNumber *widgetValue = widgetParams[[self getPrefId]];
        if (widgetValue)
            [preference set:widgetValue.intValue];
    }
    return preference;
}

- (OACommonSunPositionMode *)registerSunPositionPreference:(NSString *)customId widgetParams:(nullable NSDictionary *)widgetParams {
    NSString *prefId = @"sun_position_widget_mode";
    if (customId && customId.length > 0)
        prefId = [prefId stringByAppendingString:customId];
    
    // day_night_mode_sunset | day_night_mode_sunrise | day_night_mode_sun_position
    EOASunPositionMode sunPositionMode = EOASunPositionModeSunPositionMode;
    if (widgetParams)
    {
        NSString *widgetValue = widgetParams[@"id"];
        if ([widgetValue isEqualToString:@"day_night_mode_sunset"])
        {
            sunPositionMode = EOASunPositionModeSunsetMode;
        }
        else if ([widgetValue isEqualToString:@"day_night_mode_sunrise"]) {
            sunPositionMode = EOASunPositionModeSunriseMode;
        }
    }
    OACommonSunPositionMode *preference = [[[OAAppSettings sharedManager] registerSunPositionModePreference:prefId defValue:(int)sunPositionMode] makeProfile];
      
    if (widgetParams)
    {
        NSNumber *widgetValue = widgetParams[@"sun_position_widget_mode"];
        if (widgetValue)
            [preference set:widgetValue.intValue];
    }
    return preference;
}

@end
