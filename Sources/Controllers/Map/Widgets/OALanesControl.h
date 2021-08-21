//
//  OALanesControl.h
//  OsmAnd
//
//  Created by Alexey Kulish on 07/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OABaseWidgetView.h"

@interface OALanesControl : OABaseWidgetView

- (void) updateTextColor:(UIColor *)textColor textShadowColor:(UIColor *)textShadowColor bold:(BOOL)bold shadowRadius:(float)shadowRadius;

@end
