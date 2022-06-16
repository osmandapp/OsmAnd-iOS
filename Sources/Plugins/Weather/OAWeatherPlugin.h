//
//  OAWeatherPlugin.h
//  OsmAnd
//
//  Created by Skalii on 30.03.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAPlugin.h"

#define kWeatherTemp @"weather_temp"
#define kWeatherPressure @"weather_pressure"
#define kWeatherWind @"weather_wind"
#define kWeatherCloud @"weather_cloud"
#define kWeatherPrecip @"weather_precip"

@interface OAWeatherPlugin : OAPlugin

- (void)weatherChanged:(BOOL)isOn;

+ (NSArray<NSString *> *)getWeatherSettingKeys;

@end
