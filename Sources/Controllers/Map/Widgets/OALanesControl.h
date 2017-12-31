//
//  OALanesControl.h
//  OsmAnd
//
//  Created by Alexey Kulish on 07/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OAWidgetListener;

@interface OALanesControl : UIView

@property (nonatomic, weak) id<OAWidgetListener> delegate;

- (void) updateTextColor:(UIColor *)textColor textShadowColor:(UIColor *)textShadowColor bold:(BOOL)bold shadowRadius:(float)shadowRadius;
- (BOOL) updateInfo;

@end
