//
//  OALanesControl.h
//  OsmAnd
//
//  Created by Alexey Kulish on 07/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OABaseWidgetView.h"

NS_ASSUME_NONNULL_BEGIN

@interface OALanesControl : OABaseWidgetView

- (instancetype)initWithAppMode:(OAApplicationMode *)appMode widgetParams:(nullable NSDictionary<NSString *, id> *)widgetParams;
- (void) updateTextColor:(UIColor *)textColor textShadowColor:(UIColor *)textShadowColor bold:(BOOL)bold shadowRadius:(float)shadowRadius;

@end

NS_ASSUME_NONNULL_END
