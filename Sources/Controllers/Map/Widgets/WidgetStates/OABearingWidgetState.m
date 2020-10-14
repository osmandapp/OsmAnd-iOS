//
//  OABearingWidgetState.m
//  OsmAnd
//
//  Created by nnngrach on 01.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABearingWidgetState.h"
#import "OAAppSettings.h"
#import "Localization.h"

#define BEARING_WIDGET_STATE_RELATIVE_BEARING @"bearing_widget_state_relative_bearing"
#define BEARING_WIDGET_STATE_MAGNETIC_BEARING @"bearing_widget_state_magnetic_bearing"

@implementation OABearingWidgetState
{
    OAAppSettings *_settings;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

- (NSString *) getMenuTitle
{
    return [_settings.showRelativeBearing get] ? OALocalizedString(@"map_widget_bearing") : OALocalizedString(@"map_widget_magnetic_bearing");
}

- (NSString *) getMenuIconId
{
    return [_settings.showRelativeBearing get] ? @"ic_action_relative_bearing" : @"ic_action_bearing";
}

- (NSString *) getMenuItemId
{
    return [_settings.showRelativeBearing get] ? BEARING_WIDGET_STATE_RELATIVE_BEARING : BEARING_WIDGET_STATE_MAGNETIC_BEARING;
}

- (NSArray<NSString *> *) getMenuTitles
{
    return @[ @"map_widget_magnetic_bearing", @"map_widget_bearing" ];
}

- (NSArray<NSString *> *) getMenuIconIds
{
    return @[ @"ic_action_bearing", @"ic_action_relative_bearing" ];
}

- (NSArray<NSString *> *) getMenuItemIds
{
    return @[ BEARING_WIDGET_STATE_MAGNETIC_BEARING, BEARING_WIDGET_STATE_RELATIVE_BEARING ];
}

- (void) changeState:(NSString *)stateId
{
    [_settings.showRelativeBearing set:[BEARING_WIDGET_STATE_RELATIVE_BEARING isEqualToString:stateId]];
}

@end
