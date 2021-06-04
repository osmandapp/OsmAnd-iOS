//
//  OATimeWidgetState.m
//  OsmAnd
//
//  Created by nnngrach on 01.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATimeWidgetState.h"
#import "OAAppSettings.h"
#import "Localization.h"

#define TIME_CONTROL_WIDGET_STATE_ARRIVAL_TIME @"time_control_widget_state_arrival_time"
#define TIME_CONTROL_WIDGET_STATE_TIME_TO_GO @"time_control_widget_state_time_to_go"

@implementation OATimeWidgetState
{
    OACommonBoolean *_showArrival;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _showArrival = [OAAppSettings sharedManager].showArrivalTime;
    }
    return self;
}

- (NSString *) getMenuTitle
{
    return [_showArrival get] ? OALocalizedString(@"access_arrival_time") : OALocalizedString(@"map_widget_time");
}

- (NSString *) getMenuIconId
{
    return [_showArrival get] ? @"ic_action_time" : @"ic_action_time_to_distance";
}

- (NSString *) getMenuItemId
{
    return [_showArrival get] ? TIME_CONTROL_WIDGET_STATE_ARRIVAL_TIME : TIME_CONTROL_WIDGET_STATE_TIME_TO_GO;
}

- (NSArray<NSString *> *) getMenuTitles
{
    return @[ @"access_arrival_time", @"map_widget_time" ];
}

- (NSArray<NSString *> *) getMenuIconIds
{
    return @[ @"ic_action_time", @"ic_action_time_to_distance" ];
}

- (NSArray<NSString *> *) getMenuItemIds
{
    return @[ TIME_CONTROL_WIDGET_STATE_ARRIVAL_TIME, TIME_CONTROL_WIDGET_STATE_TIME_TO_GO ];
}

- (void) changeState:(NSString *)stateId
{
    [_showArrival set:[TIME_CONTROL_WIDGET_STATE_ARRIVAL_TIME isEqualToString:stateId]];
}

@end
