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

@implementation OABaseWidgetView
{
    BOOL _nightMode;
    UIView *_separatorView;
}

- (instancetype)initWithType:(OAWidgetType *)type
{
    self = [super init];
    if (self) {
        _widgetType = type;
        [self initSeparatorView];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = frame;
        [self initSeparatorView];
    }
    return self;
}

- (void)initSeparatorView
{
    _separatorView = [[UIView alloc] init];
    _separatorView.hidden = YES;
    _separatorView.backgroundColor = UIColorFromRGB(color_tint_gray);
    [self addSubview:_separatorView];
    
    _separatorView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [_separatorView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_separatorView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_separatorView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-0.5],
        [_separatorView.heightAnchor constraintEqualToConstant:.5]
    ]];
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

- (OATableDataModel *) getSettingsData:(OAApplicationMode *)appMode
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
}

//- (CGFloat)getHeightSimpleLayout
//{
//    return 44;
//}

- (void)showSeparator:(BOOL)show
{
    _separatorView.hidden = !show;
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
