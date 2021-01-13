//
//  OANavRemoveNextDestination.m
//  OsmAnd
//
//  Created by nnngrach on 24.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OANavRemoveNextDestination.h"
#import "OAQuickActionType.h"
#import "OATargetPointsHelper.h"
#import "OARootViewController.h"

static OAQuickActionType *TYPE;

@implementation OANavRemoveNextDestination

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    OATargetPointsHelper *targetPointsHelper = [OATargetPointsHelper sharedInstance];
    
    if ([targetPointsHelper getIntermediatePoints].count > 0)
        [targetPointsHelper removeWayPoint:YES index:0];
    else
        [[OARootViewController instance].mapPanel stopNavigation];
    
    //TODO: show "You have arrived" bottom sheet
    //DestinationReachedMenu.show(activity);
}

- (NSString *)getIconResName
{
    return @"ic_action_intermediate";
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_remove_next_destination_descr");
}

- (BOOL)isActionWithSlash
{
    return NO;
}

- (NSString *)getActionStateName
{
    return OALocalizedString(@"quick_action_remove_next_destination");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:34 stringId:@"nav.destination.remove" class:self.class name:OALocalizedString(@"quick_action_remove_next_destination") category:NAVIGATION iconName:@"ic_action_intermediate" secondaryIconName:@"ic_custom_compound_action_remove" editable:NO];
    
    return TYPE;
}

@end
