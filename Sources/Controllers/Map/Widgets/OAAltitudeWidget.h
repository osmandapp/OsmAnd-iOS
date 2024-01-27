//
//  OAAltitudeWidget.h
//  OsmAnd
//
//  Created by Skalii on 19.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//
#import "OASimpleWidget.h"

#define ALTITUDE_MAP_CENTER @"altitude_map_center"

typedef NS_ENUM(NSInteger, EOAAltitudeWidgetType) {
    EOAAltitudeWidgetTypeMyLocation = 0,
    EOAAltitudeWidgetTypeMapCenter
};

@interface OAAltitudeWidget : OASimpleWidget

- (instancetype _Nonnull)initWithType:(EOAAltitudeWidgetType)widgetType
                    customId:(NSString *_Nullable)customId
                     appMode:(OAApplicationMode * _Nonnull)appMode;

@end
