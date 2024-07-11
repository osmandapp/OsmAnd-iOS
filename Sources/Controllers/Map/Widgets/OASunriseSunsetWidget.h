//
//  OASunriseSunsetWidget.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 09.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OASimpleWidget.h"

NS_ASSUME_NONNULL_BEGIN

@class OACommonInteger, OAApplicationMode, OASunriseSunsetWidgetState;

@interface OASunriseSunsetWidget : OASimpleWidget

- (instancetype _Nonnull)initWithState:(OASunriseSunsetWidgetState *)state
                      appMode:(OAApplicationMode *)appMode
                 widgetParams:(nullable NSDictionary *)widgetParams;

- (OACommonInteger *)getPreference;

@end

NS_ASSUME_NONNULL_END
