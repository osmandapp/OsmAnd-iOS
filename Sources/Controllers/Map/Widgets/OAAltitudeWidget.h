//
//  OAAltitudeWidget.h
//  OsmAnd
//
//  Created by Skalii on 19.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//
#import "OASimpleWidget.h"

NS_ASSUME_NONNULL_BEGIN

#define ALTITUDE_MAP_CENTER @"altitude_map_center"

typedef NS_ENUM(NSInteger, EOAAltitudeWidgetType) {
    EOAAltitudeWidgetTypeMyLocation = 0,
    EOAAltitudeWidgetTypeMapCenter
};

@interface OAAltitudeWidget : OASimpleWidget

- (instancetype _Nonnull)initWithType:(EOAAltitudeWidgetType)widgetType
                    customId:(nullable NSString *)customId
                     appMode:(OAApplicationMode *)appMode
                widgetParams:(nullable NSDictionary *)widgetParams;

@end

NS_ASSUME_NONNULL_END
