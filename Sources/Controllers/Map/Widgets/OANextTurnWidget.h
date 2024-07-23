//
//  OANextTurnInfoWidget.h
//  OsmAnd
//
//  Created by Alexey Kulish on 02/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OATextInfoWidget.h"

NS_ASSUME_NONNULL_BEGIN

#define kNextTurnInfoWidgetHeight 112

@interface OANextTurnWidget : OATextInfoWidget

- (instancetype)initWithHorisontalMini:(BOOL)horisontalMini
                              nextNext:(BOOL)nextNext
                              customId:(nullable NSString *)customId
                               appMode:(OAApplicationMode *)appMode
                          widgetParams:(nullable NSDictionary *)widgetParams;

@end

NS_ASSUME_NONNULL_END
