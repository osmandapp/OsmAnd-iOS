//
//  OAWeatherPlugin.h
//  OsmAnd
//
//  Created by Skalii on 30.03.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAPlugin.h"

static NSString * const kWeatherTemp = @"weather_temp";
static NSString * const kWeatherPressure = @"weather_pressure";
static NSString * const kWeatherWind = @"weather_wind";
static NSString * const kWeatherCloud = @"weather_cloud";
static NSString * const kWeatherPrecip = @"weather_precip";

@interface OAWeatherPlugin : OAPlugin

- (void)weatherChanged:(BOOL)isOn;
- (void)updateWidgetsInfo;

@end
