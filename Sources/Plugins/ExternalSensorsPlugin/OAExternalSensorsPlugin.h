//
//  OAWeatherPlugin.h
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 03.11.2023.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAPlugin.h"

@class OACommonString, OAApplicationMode;

@interface OAExternalSensorsPlugin : OAPlugin

- (NSArray<OAWidgetType *> * _Nonnull)getExternalSensorTrackDataType;
- (OACommonString * _Nullable)getWriteToTrackDeviceIdPref:(OAWidgetType * _Nonnull)dataType;
- (void)saveDeviceId:(NSString *_Nonnull)deviceID widgetType:(OAWidgetType *_Nonnull)widgetType appMode:(OAApplicationMode *_Nonnull)appMode;
- (NSString *_Nonnull)getDeviceIdForWidgetType:(OAWidgetType *_Nonnull)widgetType appMode:(OAApplicationMode *_Nonnull)appMode;
- (NSString * _Nullable)getWidgetDataFieldTypeNameByWidgetId:(NSString * _Nonnull)widgetId;
- (NSString * _Nonnull)getAnyConnectedDeviceId;

@end
