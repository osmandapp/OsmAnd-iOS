//
//  OACompassModeWidgetState.mm
//  OsmAnd
//
//  Created by Skalii on 30.06.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OACompassModeWidgetState.h"
#import "OARootViewController.h"
#import "Localization.h"

@implementation OACompassModeWidgetState
{
    OACommonInteger *_compassMode;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _compassMode = [OAAppSettings sharedManager].compassMode;
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
    return [OACompassMode getIconName:(EOACompassMode) [_compassMode get]];
}

- (NSString *)getMenuItemId
{
    return @((EOACompassMode) [_compassMode get]).stringValue;
}

- (NSArray<NSString *> *)getMenuTitles
{
    return @[
            [OACompassMode getTitle:EOACompassVisible],
            [OACompassMode getTitle:EOACompassHidden],
            [OACompassMode getTitle:EOACompassRotated]
    ];
}

- (NSArray<NSString *> *) getMenuDescriptions
{
    return @[
            [OACompassMode getDescription:EOACompassVisible],
            [OACompassMode getDescription:EOACompassHidden],
            [OACompassMode getDescription:EOACompassRotated]
    ];
}

- (NSArray<NSString *> *)getMenuIconIds
{
    return @[
            [OACompassMode getIconName:EOACompassVisible],
            [OACompassMode getIconName:EOACompassHidden],
            [OACompassMode getIconName:EOACompassRotated]
    ];
}

- (NSArray<NSString *> *)getMenuItemIds
{
    return @[
            @(EOACompassVisible).stringValue,
            @(EOACompassHidden).stringValue,
            @(EOACompassRotated).stringValue
    ];
}

- (void)changeState:(NSString *)stateId
{
    [_compassMode set:stateId.intValue];
}

@end
