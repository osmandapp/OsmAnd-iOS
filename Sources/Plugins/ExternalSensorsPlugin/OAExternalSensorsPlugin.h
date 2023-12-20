//
//  OAWeatherPlugin.h
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 03.11.2023.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAPlugin.h"

FOUNDATION_EXPORT NSString * _Nonnull const OATrackRecordingNone;
FOUNDATION_EXPORT NSString * _Nonnull const OATrackRecordingAnyConnected;

@class OACommonString, OAApplicationMode, OAGPXTrackAnalysis, OAWptPt, OAPointAttributes;

@interface OAExternalSensorsPlugin : OAPlugin

- (NSArray<OAWidgetType *> * _Nonnull)getExternalSensorTrackDataType;
- (OACommonString * _Nullable)getWriteToTrackDeviceIdPref:(OAWidgetType * _Nonnull)dataType;
- (void)saveDeviceId:(NSString *_Nonnull)deviceID widgetType:(OAWidgetType *_Nonnull)widgetType appMode:(OAApplicationMode *_Nonnull)appMode;
- (NSString *_Nonnull)getDeviceIdForWidgetType:(OAWidgetType *_Nonnull)widgetType appMode:(OAApplicationMode *_Nonnull)appMode;
+ (void)onAnalysePoint:(OAGPXTrackAnalysis *)analysis point:(OAWptPt *)point attribute:(OAPointAttributes *)attribute;

@end
