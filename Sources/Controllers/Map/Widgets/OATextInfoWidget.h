//
//  OATextInfoWidget.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OABaseWidgetView.h"

NS_ASSUME_NONNULL_BEGIN

#define kTextInfoWidgetWidth 94
#define kTextInfoWidgetHeight 34

#define UPDATE_INTERVAL_MILLIS 1000

@class OAWidgetType, OutlineLabel, OACommonWidgetSizeStyle, OAWidgetsPanel, OATextState;

@interface OATextInfoWidget : OABaseWidgetView

@property (nonatomic, readonly) UIFont *primaryFont;
@property (nonatomic, readonly) UIColor *primaryColor;
@property (nonatomic, readonly, nullable) UIColor *primaryOutlineColor;
@property (nonatomic, readonly) UIFont *unitsFont;
@property (nonatomic, readonly) UIColor *unitsColor;
@property (nonatomic, readonly, nullable) UIColor *unitsShadowColor;
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
@property (nonatomic, nullable) OACommonWidgetSizeStyle *widgetSizePref;

@property (strong) BOOL(^updateInfoFunction)();
@property (strong) void(^onClickFunction)(id sender);

- (void) setImage:(nullable UIImage *)image;
- (void) setImage:(nullable UIImage *)image withColor:(UIColor *)color;
- (void)setImage:(UIImage *)image withColor:(UIColor *)color iconName:(NSString *)iconName;

- (void) setImageHidden:(BOOL)visible;
- (void) setTimeText:(NSTimeInterval)time;
- (BOOL) isNight;
- (BOOL) setIconForWidgetType:(nullable OAWidgetType *)widgetType;
- (BOOL) setIcon:(NSString *)widgetIcon;
- (nullable NSString *) getIconName;

- (void) setContentDescription:(NSString *)text;
- (void) setContentTitle:(NSString *)text;
- (void) setText:(nullable NSString *)text subtext:(nullable NSString *)subtext;
- (void) setTextNoUpdateVisibility:(nullable NSString *)text subtext:(nullable NSString *)subtext;

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

- (void)updateTextWitState:(OATextState *)state;

- (CGFloat) getWidgetHeight;
- (void) adjustViewSize;

- (void)configurePrefsWithId:(nullable NSString *)id appMode:(OAApplicationMode *)appMode widgetParams:(nullable NSDictionary *)widgetParams;
- (void)configureSimpleLayout;
- (void)refreshLayout;
- (nullable OAApplicationMode *)getAppMode;
- (nullable OAWidgetsPanel *)getWidgetPanel;

@end

NS_ASSUME_NONNULL_END
