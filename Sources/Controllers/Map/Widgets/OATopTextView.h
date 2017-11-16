//
//  OATopTextView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 13/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OATopTextView;

@protocol OATopTextViewListener <NSObject>

@required
- (void) topTextViewChanged:(OATopTextView *)topTextView;
- (void) topTextViewVisibilityChanged:(OATopTextView *)topTextView visible:(BOOL)visible;
- (void) topTextViewClicked:(OATopTextView *)topTextView;

@end

@interface OATopTextView : UIView

@property (nonatomic, weak) id<OATopTextViewListener> delegate;

- (void) updateTextColor:(UIColor *)textColor textShadowColor:(UIColor *)textShadowColor bold:(BOOL)bold shadowRadius:(float)shadowRadius nightMode:(BOOL)nightMode;
- (BOOL) updateInfo;

@end
