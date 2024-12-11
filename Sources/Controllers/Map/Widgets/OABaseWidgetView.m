//
//  OABaseWidgetView.m
//  OsmAnd Maps
//
//  Created by Paul on 20.08.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseWidgetView.h"
#import "OAMapInfoController.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"
#import "OALog.h"

@implementation OABaseWidgetView
{
    BOOL _nightMode;
    UIView *_separatorBottomView;
    UIView *_separatorRightView;
    NSLayoutConstraint *_heightConstraint;
}

- (instancetype)initWithType:(OAWidgetType *)type
{
    self = [super init];
    if (self) {
        _widgetType = type;
        [self initSeparatorsView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = frame;
        [self initSeparatorsView];
    }
    return self;
}

- (void)initSeparatorsView
{
    _separatorBottomView = [[UIView alloc] init];
    _separatorBottomView.hidden = YES;
    [self addSubview:_separatorBottomView];
    
    _separatorBottomView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [_separatorBottomView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_separatorBottomView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_separatorBottomView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [_separatorBottomView.heightAnchor constraintEqualToConstant:1]
    ]];
    
    _separatorRightView = [UIView new];
    _separatorRightView.hidden = YES;
    [self addSubview:_separatorRightView];
    
    _separatorRightView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [_separatorRightView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_separatorRightView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [_separatorRightView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_separatorRightView.widthAnchor constraintEqualToConstant:1]
    ]];
}

- (void)updatesSeparatorsColor:(UIColor *)color
{
    _separatorBottomView.backgroundColor = _separatorRightView.backgroundColor = color;
}

- (void)replaceHeightConstraintWithRelation:(NSLayoutRelation)relation constant:(CGFloat)constant priority:(UILayoutPriority)priority
{
    if (_heightConstraint)
        _heightConstraint.active = NO;

    switch (relation)
    {
        case NSLayoutRelationLessThanOrEqual:
            _heightConstraint = [self.heightAnchor constraintLessThanOrEqualToConstant:constant];
            break;
        case NSLayoutRelationEqual:
            _heightConstraint = [self.heightAnchor constraintEqualToConstant:constant];
            break;
        case NSLayoutRelationGreaterThanOrEqual:
            _heightConstraint = [self.heightAnchor constraintGreaterThanOrEqualToConstant:constant];
            break;

        default:
            _heightConstraint = nil;
            break;
    }
    if (_heightConstraint)
    {
        _heightConstraint.priority = priority;
        _heightConstraint.active = YES;
    }
}

- (void)updateHeightConstraintWithRelation:(NSLayoutRelation)relation constant:(CGFloat)constant priority:(UILayoutPriority)priority
{
    if (_heightConstraint && _heightConstraint.isActive)
    {
        if (_heightConstraint.relation != relation || _heightConstraint.constant != constant || _heightConstraint.priority != priority)
            [self replaceHeightConstraintWithRelation:relation constant:constant priority:priority];
    }
    else
    {
        [self replaceHeightConstraintWithRelation:relation constant:constant priority:priority];
    }
}

- (void)updateHeightConstraint:(NSLayoutConstraint * _Nullable)constraint
{
    if (_heightConstraint)
        _heightConstraint.active = NO;

    _heightConstraint = constraint;
    if (_heightConstraint)
        _heightConstraint.active = YES;
}

- (OACommonBoolean * _Nullable ) getWidgetVisibilityPref {
    return nil;
}

/**
 * @return preference that needs to be reset after deleting widget
 */
- (OACommonPreference * _Nullable ) getWidgetSettingsPrefToReset:(OAApplicationMode *)appMode {
    return nil;
}

- (void) copySettings:(OAApplicationMode *)appMode customId:(NSString *)customId
{
    OAWidgetState *widgetState = [self getWidgetState];
    if (widgetState)
        [widgetState copyPrefs:appMode customId:customId];
}

- (OAWidgetState *) getWidgetState {
    return nil;
}

- (BOOL) isExternal
{
    return self.widgetType == nil;
}

- (OATableDataModel *)getSettingsData:(OAApplicationMode *)appMode
{
    return nil;
}

- (OATableDataModel *_Nullable)getSettingsDataForSimpleWidget:(OAApplicationMode * _Nonnull)appMode
{
    return nil;
}

- (BOOL)updateInfo
{
    return NO; // override
}

- (void)updateColors:(OATextState *)textState
{
    _nightMode = textState.night;
}

- (BOOL)isNightMode
{
    return _nightMode;
}

- (BOOL)isTopText
{
    return NO;
}

- (BOOL)isTextInfo
{
    return NO;
}

- (void)updateSimpleLayout
{
    OALog(@"call base updateSimpleLayout");
}

- (void)showBottomSeparator:(BOOL)show
{
    _separatorBottomView.hidden = !show;
}

- (void)showRightSeparator:(BOOL)show {
    _separatorRightView.hidden = !show;
}

- (void)adjustViewSize
{
}

- (void) attachView:(UIView *_Nonnull)container specialContainer:(UIView *_Nullable)specialContainer order:(NSInteger)order followingWidgets:(NSArray<OABaseWidgetView *> *)followingWidgets
{
    // Do not remove from superview since WidgetPageViewController populates stackView with widgets on update
    //[container addSubview:self];
}

- (void) detachView:(OAWidgetsPanel *)widgetsPanel
{
    // Do not remove from superview since WidgetPageViewController populates stackView with widgets on update
    //if (self.superview)
    //    [self removeFromSuperview];
}

@end
