//
//  OAShowHideCoordinatesAction.m
//  OsmAnd Maps
//
//  Created by nnngrach on 30.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAShowHideCoordinatesAction.h"
#import "OAQuickActionType.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"



static OAQuickActionType *TYPE;

@implementation OAShowHideCoordinatesAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    [settings.showCurrentLocationCoordinatesWidget set:![settings.showCurrentLocationCoordinatesWidget get]];
    [[[OsmAndApp instance].data destinationsChangeObservable] notifyEventWithKey:nil];
}

- (BOOL)isActionWithSlash
{
    return [[OAAppSettings sharedManager].showCurrentLocationCoordinatesWidget get];
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"hide_current_location") : OALocalizedString(@"show_current_location");
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_current_location_widget_descr");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:35 stringId:@"coordinates.current_location.showhide" class:self.class name:OALocalizedString(@"toggle_current_location") category:CONFIGURE_SCREEN iconName:@"ic_custom_coordinates_location" secondaryIconName:nil editable:NO];
       
    return TYPE;
}

@end
