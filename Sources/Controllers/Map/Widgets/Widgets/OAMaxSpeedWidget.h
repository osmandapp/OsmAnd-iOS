//
//  OAMaxSpeedWidget.h
//  OsmAnd Maps
//
//  Created by Paul on 15.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OASimpleWidget.h"

NS_ASSUME_NONNULL_BEGIN

@interface OAMaxSpeedWidget : OASimpleWidget

- (instancetype _Nonnull)initWithCustomId:(NSString *_Nullable)customId
                                  appMode:(OAApplicationMode * _Nonnull)appMode
                             widgetParams:(NSDictionary * _Nullable)widgetParams;

@end

NS_ASSUME_NONNULL_END
