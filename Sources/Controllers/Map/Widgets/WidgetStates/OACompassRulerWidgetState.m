//
//  OACompassRulerWidgetState.m
//  OsmAnd
//
//  Created by nnngrach on 07.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//


#import "OACompassRulerWidgetState.h"
#import "OAAppSettings.h"
#import "Localization.h"

#define COMPASS_CONTROL_WIDGET_STATE_SHOW @"compass_ruler_control_widget_state_show"
#define COMPASS_CONTROL_WIDGET_STATE_HIDE @"compass_ruler_control_widget_state_hide"

@implementation OACompassRulerWidgetState
{
    BOOL _showCompass;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _showCompass = [OAAppSettings sharedManager].showCompassControlRuler;
    }
    return self;
}

- (NSString *) getMenuTitle
{
    return OALocalizedString(@"map_widget_ruler_control");
}

- (NSString *) getMenuIconId
{
    return @"ic_action_ruler_circle";
}

- (NSString *) getMenuItemId
{
    return _showCompass ? COMPASS_CONTROL_WIDGET_STATE_SHOW : COMPASS_CONTROL_WIDGET_STATE_HIDE;
}

- (NSArray<NSString *> *) getMenuTitles
{
    return @[ OALocalizedString(@"show_compass_ruler"), OALocalizedString(@"hide_compass_ruler") ];
}

- (NSArray<NSString *> *) getMenuIconIds
{
    return @[ @"ic_custom_compass_widget", @"ic_custom_compass_widget_hide" ];
}

- (NSArray<NSString *> *) getMenuItemIds
{
    return @[ COMPASS_CONTROL_WIDGET_STATE_SHOW, COMPASS_CONTROL_WIDGET_STATE_HIDE ];
}

- (void) changeState:(NSString *)stateId
{
    _showCompass  = [COMPASS_CONTROL_WIDGET_STATE_SHOW isEqualToString:stateId];
}

@end

