//
//  OATextInfoWidget.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "OABaseWidgetView.h"

#define kTextInfoWidgetWidth 94
#define kTextInfoWidgetHeight 32

#define UPDATE_INTERVAL_MILLIS 1000

@class OAWidgetType;

@interface OATextInfoWidget : OABaseWidgetView

@property (nonatomic, readonly) UIFont *primaryFont;
@property (nonatomic, readonly) UIColor *primaryColor;
@property (nonatomic, readonly) UIColor *primaryShadowColor;
@property (nonatomic, readonly) UIFont *unitsFont;
@property (nonatomic, readonly) UIColor *unitsColor;
@property (nonatomic, readonly) UIColor *unitsShadowColor;
@property (nonatomic, readonly) float shadowRadius;

@property (nonatomic) UILabel *textView;
@property (nonatomic) UILabel *textShadowView;
@property (nonatomic) UIImageView *imageView;

@property (nonatomic) NSLayoutConstraint *topTextAnchor;

@property (strong) BOOL(^updateInfoFunction)();
@property (strong) void(^onClickFunction)(id sender);

- (void) setImage:(UIImage *)image;
- (void) setImage:(UIImage *)image withColor:(UIColor *)color;
- (void) setImageHidden:(BOOL)visible;
- (void) setTimeText:(NSTimeInterval)time;
- (BOOL) isNight;
- (BOOL) setIconForWidgetType:(OAWidgetType *)widgetType;
- (BOOL) setIcon:(NSString *)widgetIcon;
- (NSString *) getIconName;

- (void) setContentDescription:(NSString *)text;
- (void) setContentTitle:(NSString *)text;
- (void) setText:(NSString *)text subtext:(NSString *)subtext;
- (void) setTextNoUpdateVisibility:(NSString *)text subtext:(NSString *)subtext;

- (BOOL) updateVisibility:(BOOL)visible;
- (BOOL) isVisible;
- (void) addAccessibilityLabelsWithValue:(NSString *)value;

- (BOOL) isUpdateNeeded;
- (BOOL) isMetricSystemDepended;
- (BOOL) isAngularUnitsDepended;
- (void) setMetricSystemDepended:(BOOL)newValue;
- (void) setAngularUnitsDepended:(BOOL)newValue;
- (BOOL) isExplicitlyVisible;
- (void) setExplicitlyVisible:(BOOL)explicitlyVisible;
- (void) updateIconMode:(BOOL)night;
- (void) updateTextColor:(UIColor *)textColor textShadowColor:(UIColor *)textShadowColor bold:(BOOL)bold shadowRadius:(float)shadowRadius;

- (CGFloat) getWidgetHeight;
- (void) adjustViewSize;

@end
