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
    [settings.showCoordinatesWidget set:![settings.showCoordinatesWidget get]];
    [[[OsmAndApp instance].data destinationsChangeObservable] notifyEventWithKey:nil];
}

- (BOOL)isActionWithSlash
{
    return [[OAAppSettings sharedManager].showCoordinatesWidget get];
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"hide_coordinates") : OALocalizedString(@"show_coordinates");
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_coordinates_widget_descr");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:35 stringId:@"coordinates.showhide" class:self.class name:OALocalizedString(@"toggle_coordinates") category:CONFIGURE_SCREEN iconName:@"ic_custom_coordinates" secondaryIconName:nil editable:NO];
       
    return TYPE;
}

@end
