//
//  OAWeatherPlugin.mm
//  OsmAnd
//
//  Created by Skalii on 30.03.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherPlugin.h"
#import "OAIAPHelper.h"
#import "OsmAndApp.h"

#define PLUGIN_ID kInAppId_Addon_Weather
#define kLastUsedWeatherKey @"lastUsedWeather"

static NSArray<NSString *> * const _weatherSettingKeys = @[kWeatherTemp, kWeatherPressure, kWeatherWind, kWeatherCloud, kWeatherPrecip];

@implementation OAWeatherPlugin
{
    OACommonBoolean *_lastUsedWeather;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _lastUsedWeather = [OACommonBoolean withKey:kLastUsedWeatherKey defValue:NO];
    }
    return self;
}

- (NSString *) getId
{
    return PLUGIN_ID;
}

- (void)disable
{
    [super disable];
    OAAppData *data = [OsmAndApp instance].data;
    [_lastUsedWeather set:data.weather];
    [data setWeather:NO];
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [[OsmAndApp instance].data setWeather:enabled ? [_lastUsedWeather get] : NO];
}

- (void)weatherChanged:(BOOL)isOn
{
    [_lastUsedWeather set:isOn];
    [[OsmAndApp instance].data setWeather:isOn];
}

+ (NSArray<NSString *> *)getWeatherSettingKeys
{
    return _weatherSettingKeys;
}

@end
