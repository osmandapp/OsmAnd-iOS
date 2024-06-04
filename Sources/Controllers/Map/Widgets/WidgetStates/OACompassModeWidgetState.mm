//
//  OACompassModeWidgetState.mm
//  OsmAnd
//
//  Created by Skalii on 30.06.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OACompassModeWidgetState.h"
#import "OARootViewController.h"
#import "OAMapButtonsHelper.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OACompassModeWidgetState
{
    OACompassButtonState *_compassState;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _compassState = [[OAMapButtonsHelper sharedInstance] getCompassButtonState];
    }
    return self;
}

- (NSString *)getMenuTitle
{
    return OALocalizedString(@"map_widget_compass");
}

- (NSString *)getMenuDescription
{
    return OALocalizedString(@"compass_options_description");
}

- (NSString *)getMenuIconId
{
    return [EOACompassVisibilityWrapper getIconNameForType:[_compassState getVisibility]];
}

- (NSString *)getMenuItemId
{
    return @([_compassState getVisibility]).stringValue;
}

- (NSArray<NSString *> *)getMenuTitles
{
    return [EOACompassVisibilityWrapper getTitles];
}

- (NSArray<NSString *> *) getMenuDescriptions
{
    return [EOACompassVisibilityWrapper getDescs];
}

- (NSArray<NSString *> *)getMenuIconIds
{
    return [EOACompassVisibilityWrapper getIconNames];
}

- (NSArray<NSString *> *)getMenuItemIds
{
    return @[
            @(EOACompassVisibilityAlwaysVisible).stringValue,
            @(EOACompassVisibilityAlwaysHidden).stringValue,
            @(EOACompassVisibilityVisibleIfMapRotated).stringValue
    ];
}

- (void)changeState:(NSString *)stateId
{
    [_compassState.visibilityPref set:stateId.intValue];
}

@end
