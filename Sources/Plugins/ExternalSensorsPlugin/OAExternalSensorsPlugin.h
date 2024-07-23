//
//  OAWeatherPlugin.h
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 03.11.2023.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@class OACommonString, OAApplicationMode, OAWidgetType;

@interface OAExternalSensorsPlugin : OAPlugin

- (NSArray<OAWidgetType *> *)getExternalSensorTrackDataType;
- (nullable OACommonString *)getWriteToTrackDeviceIdPref:(OAWidgetType *)dataType;
- (void)saveDeviceId:(NSString *)deviceID widgetType:(OAWidgetType *)widgetType appMode:(OAApplicationMode *)appMode;
- (NSString *)getDeviceIdForWidgetType:(OAWidgetType *)widgetType appMode:(OAApplicationMode *)appMode;
- (nullable NSString *)getWidgetDataFieldTypeNameByWidgetId:(NSString *)widgetId;
- (NSString *)getAnyConnectedDeviceId;

@end

NS_ASSUME_NONNULL_END
