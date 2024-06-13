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
    CompassButtonState *_compassState;
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
    return [CompassVisibilityWrapper getIconNameForType:[_compassState getVisibility]];
}

- (NSString *)getMenuItemId
{
    return @([_compassState getVisibility]).stringValue;
}

- (NSArray<NSString *> *)getMenuTitles
{
    return [CompassVisibilityWrapper getTitles];
}

- (NSArray<NSString *> *) getMenuDescriptions
{
    return [CompassVisibilityWrapper getDescs];
}

- (NSArray<NSString *> *)getMenuIconIds
{
    return [CompassVisibilityWrapper getIconNames];
}

- (NSArray<NSString *> *)getMenuItemIds
{
    return @[
            @(CompassVisibilityAlwaysVisible).stringValue,
            @(CompassVisibilityAlwaysHidden).stringValue,
            @(CompassVisibilityVisibleIfMapRotated).stringValue
    ];
}

- (void)changeState:(NSString *)stateId
{
    [_compassState.visibilityPref set:stateId.intValue];
}

@end
