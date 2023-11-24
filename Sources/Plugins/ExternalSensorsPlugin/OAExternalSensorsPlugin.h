//
//  OAWeatherPlugin.h
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 03.11.2023.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAPlugin.h"

#define kDenyWriteSensorDataToTrackKey @"deny_write_sensor_data"

@class OACommonString;

@interface OAExternalSensorsPlugin : OAPlugin

- (NSArray<OAWidgetType *> *)getExternalSensorTrackDataType;
- (OACommonString *)getWriteToTrackDeviceIdPref:(OAWidgetType *)dataType;

@end
