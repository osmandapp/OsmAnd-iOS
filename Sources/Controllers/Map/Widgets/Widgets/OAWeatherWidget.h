//
//  OAWeatherWidget.h
//  OsmAnd Maps
//
//  Created by Paul on 08.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OASimpleWidget.h"
#import "OAWeatherBand.h"

NS_ASSUME_NONNULL_BEGIN

@class OAWidgetType;

@interface OAWeatherWidget : OASimpleWidget

@property (nonatomic, assign) BOOL shouldAlwaysSeparateValueAndUnitText;
@property (nonatomic, assign) BOOL useDashSymbolWhenTextIsEmpty;

- (instancetype _Nonnull)initWithType:(OAWidgetType *)type
                         band:(EOAWeatherBand)band
                     customId:(NSString *_Nullable)customId
                      appMode:(OAApplicationMode * _Nonnull)appMode
                 widgetParams:(NSDictionary *)widgetParams;

@end

NS_ASSUME_NONNULL_END
