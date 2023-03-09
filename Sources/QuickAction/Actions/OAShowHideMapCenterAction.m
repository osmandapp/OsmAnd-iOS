//
//  OAShowHideMapCenterAction.m
//  OsmAnd Maps
//
//  Created by nnngrach on 09.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAShowHideMapCenterAction.h"
#import "OAQuickActionType.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"



static OAQuickActionType *TYPE;

@implementation OAShowHideMapCenterAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    [settings.showMapCenterCoordinatesWidget set:![settings.showMapCenterCoordinatesWidget get]];
    [[[OsmAndApp instance].data destinationsChangeObservable] notifyEventWithKey:nil];
}

- (BOOL)isActionWithSlash
{
    return [[OAAppSettings sharedManager].showMapCenterCoordinatesWidget get];
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"hide_map_center") : OALocalizedString(@"show_map_center");
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_map_center_widget_descr");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:36 stringId:@"coordinates.showhide" class:self.class name:OALocalizedString(@"toggle_map_center") category:CONFIGURE_SCREEN iconName:@"ic_custom_coordinates" secondaryIconName:nil editable:NO];
       
    return TYPE;
}

@end
