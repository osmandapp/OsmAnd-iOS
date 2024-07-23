//
//  OABaseWidgetView.h
//  OsmAnd Maps
//
//  Created by Paul on 20.08.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class OABaseWidgetView, OAWidgetType, OAWidgetState, OAWidgetsPanel, OAApplicationMode, OACommonBoolean, OACommonPreference, OATableDataModel, OATextState;

@protocol OAWidgetListener <NSObject>

@required
- (void) widgetChanged:(nullable OABaseWidgetView *)widget;
- (void) widgetVisibilityChanged:(OABaseWidgetView *)widget visible:(BOOL)visible;
- (void) widgetClicked:(OABaseWidgetView *)widget;

@end

@protocol OAWidgetListener;

@interface OABaseWidgetView : UIView

@property (nonatomic, nullable) OAWidgetType *widgetType;
@property (nonatomic, readonly, assign) BOOL nightMode;
@property (nonatomic, assign) BOOL isSimpleLayout;
@property (nonatomic, assign) BOOL isVerticalStackImageTitleSubtitleLayout;
@property (nonatomic, assign) BOOL isFullRow;

@property (nonatomic, weak, nullable) id<OAWidgetListener> delegate;

- (instancetype)initWithType:(OAWidgetType *)type;
- (void)initSeparatorsView;

- (BOOL)updateInfo;
- (void)updateColors:(OATextState *)textState;
- (BOOL)isNightMode;
- (BOOL)isTopText;
- (BOOL)isTextInfo;
- (void)updateSimpleLayout;
- (void)updateVerticalStackImageTitleSubtitleLayout;
- (void)updatesSeparatorsColor:(UIColor *)color;

- (void)updateHeightConstraintWithRelation:(NSLayoutRelation)relation constant:(CGFloat)constant priority:(UILayoutPriority)priority;
- (void)updateHeightConstraint:(nullable NSLayoutConstraint *)constraint;

- (nullable OACommonBoolean *) getWidgetVisibilityPref;
- (nullable OACommonPreference *) getWidgetSettingsPrefToReset:(OAApplicationMode *)appMode;
- (void) copySettings:(OAApplicationMode *)appMode customId:(nullable NSString *)customId;
- (nullable OAWidgetState *) getWidgetState;
- (BOOL)isExternal;
- (nullable OATableDataModel *)getSettingsData:(OAApplicationMode *)appMode;
- (nullable OATableDataModel *)getSettingsDataForSimpleWidget:(OAApplicationMode *)appMode;

- (void)showBottomSeparator:(BOOL)show;
- (void)showRightSeparator:(BOOL)show;
- (void)adjustViewSize;
- (void)attachView:(UIView *)container specialContainer:(nullable UIView *)specialContainer order:(NSInteger)order followingWidgets:(nullable NSArray<OABaseWidgetView *> *)followingWidgets;
- (void)detachView:(OAWidgetsPanel *)widgetsPanel;

@end

NS_ASSUME_NONNULL_END
