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
}

- (instancetype)initWithType:(OAWidgetType *)type
{
    self = [super init];
    if (self) {
        _widgetType = type;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = frame;
    }
    return self;
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

- (void)adjustViewSize
{
}

- (void) attachView:(UIView *)container order:(NSInteger)order followingWidgets:(NSArray<OABaseWidgetView *> *)followingWidgets
{
    [container addSubview:self];
}

- (void) detachView:(OAWidgetsPanel *)widgetsPanel
{
    if (self.superview)
        [self removeFromSuperview];
}

@end
