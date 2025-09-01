//
//  OATopTextView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 13/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OABaseWidgetView.h"

NS_ASSUME_NONNULL_BEGIN

static const int MAX_SHIELDS_QUANTITY = 3;

@interface OATopTextView : OABaseWidgetView

- (instancetype)initWithCustomId:(nullable NSString *)customId
                    widgetParams:(nullable NSDictionary *)widgetParams;

- (void)updateTextColor:(UIColor *)textColor
        textShadowColor:(UIColor *)textShadowColor
                   bold:(BOOL)bold
           shadowRadius:(float)shadowRadius
              nightMode:(BOOL)nightMode;

@end

NS_ASSUME_NONNULL_END

