//
//  OATopTextView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 13/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OABaseWidgetView.h"

static const int MAX_SHIELDS_QUANTITY = 3;

@interface OATopTextView : OABaseWidgetView

- (void) updateTextColor:(UIColor *)textColor textShadowColor:(UIColor *)textShadowColor bold:(BOOL)bold shadowRadius:(float)shadowRadius nightMode:(BOOL)nightMode;

@end
