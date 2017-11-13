//
//  OATopTextView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 13/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OATopTextView : UIView

- (void) updateTextColor:(UIColor *)textColor textShadowColor:(UIColor *)textShadowColor bold:(BOOL)bold shadowRadius:(float)shadowRadius;
- (BOOL) updateInfo;

@end
