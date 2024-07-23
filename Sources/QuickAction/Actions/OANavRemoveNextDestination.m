//
//  OANavRemoveNextDestination.m
//  OsmAnd
//
//  Created by nnngrach on 24.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OANavRemoveNextDestination.h"
#import "OATargetPointsHelper.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OANavRemoveNextDestination

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsNavRemoveNextDestinationActionId
                                             stringId:@"nav.destination.remove"
                                                   cl:self.class]
                name:OALocalizedString(@"quick_action_remove_next_destination")]
               nameAction:OALocalizedString(@"shared_string_remove")]
               iconName:@"ic_action_intermediate"]
              secondaryIconName:@"ic_custom_compound_action_remove"] 
             category:QuickActionTypeCategoryNavigation]
            nonEditable];
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

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
