//
//  OACurrentSpeedWidget.h
//  OsmAnd Maps
//
//  Created by Paul on 15.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OASimpleWidget.h"

NS_ASSUME_NONNULL_BEGIN

@interface OACurrentSpeedWidget : OASimpleWidget

- (instancetype _Nonnull)initWithCustomId:(nullable NSString *)customId
                                  appMode:(OAApplicationMode *)appMode
                             widgetParams:(nullable NSDictionary *)widgetParams;

@end

NS_ASSUME_NONNULL_END
