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
#import "OAAppSettings.h"

#define kTextInfoWidgetWidth 94
#define kTextInfoWidgetHeight 34

#define UPDATE_INTERVAL_MILLIS 1000

@class OAWidgetType, OutlineLabel;

@interface OATextInfoWidget : OABaseWidgetView

@property (nonatomic, readonly) UIFont *primaryFont;
@property (nonatomic, readonly) UIColor *primaryColor;
@property (nonatomic, readonly) UIColor *primaryOutlineColor;
@property (nonatomic, readonly) UIFont *unitsFont;
@property (nonatomic, readonly) UIColor *unitsColor;
@property (nonatomic, readonly) UIColor *unitsShadowColor;
@property (nonatomic, readonly) float textOutlineWidth;

@property (nonatomic) OutlineLabel *textView;
@property (nonatomic) UIImageView *imageView;

@property (nonatomic) NSLayoutConstraint *topTextAnchor;

// Simple Widget Layout
@property (nonatomic, strong, nullable) UIStackView *topNameUnitStackView;
@property (nonatomic, strong, nullable) UILabel *nameLabel;
@property (nonatomic, strong, nullable) UILabel *unitLabel;
@property (nonatomic, strong, nullable) UIView *unitView;
@property (nonatomic, strong, nullable) UIView *emptyViewRightPlaceholderFullRow;
@property (nonatomic, strong, nullable) UILabel *titleOrEmptyLabel;
@property (nonatomic, strong, nullable) UILabel *unitOrEmptyLabel;
@property (nonatomic, strong, nullable) UILabel *valueLabel;
@property (nonatomic, strong, nullable) UIView *iconWidgetView;
@property (nonatomic) OACommonInteger *widgetSizePref;

@property (strong) BOOL(^updateInfoFunction)();
@property (strong) void(^onClickFunction)(id sender);

- (void) setImage:(UIImage *)image;
- (void) setImage:(UIImage *)image withColor:(UIColor *)color;
- (void)setImage:(UIImage *_Nonnull)image withColor:(UIColor *_Nonnull)color iconName:(NSString *_Nonnull)iconName;

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
- (void)updateIcon;
- (void)setNightMode:(BOOL)night;

- (void)updateTextWitState:(OATextState *_Nonnull)state;

- (CGFloat) getWidgetHeight;
- (void) adjustViewSize;

- (void)configurePrefsWithId:(NSString * _Nullable)id appMode:(OAApplicationMode *_Nonnull)appMode widgetParams:(NSDictionary * _Nullable)widgetParams;
- (void)configureSimpleLayout;
- (void)refreshLayout;
- (OAApplicationMode *_Nonnull)getAppMode;
- (OAWidgetsPanel *_Nonnull)getWidgetPanel;

@end
