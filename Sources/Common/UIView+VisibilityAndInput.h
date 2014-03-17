//
//  UIView+VisibilityAndInput.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/17/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (VisibilityAndInput)

- (void)hideAndDisableInput;
- (void)showAndEnableInput;
- (BOOL)isGone;

@end
