//
//  OANavAddDestinationAction.m
//  OsmAnd
//
//  Created by Paul on 8/13/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OANavAddDestinationAction.h"
#import "OARootViewController.h"
#import "OAAppData.h"
#import "OAMapPanelViewController.h"
#import "OATargetPointsHelper.h"
#import "OAPointDescription.h"
#import "OAMapActions.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OANavAddDestinationAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsNavAddDestinationActionId
                                             stringId:@"nav.destination.add"
                                                   cl:self.class]
                name:OALocalizedString(@"quick_action_destination")]
               nameAction:OALocalizedString(@"shared_string_set")]
               iconName:@"ic_action_target"]
              secondaryIconName:@"ic_custom_compound_action_add"]
             category:QuickActionTypeCategoryNavigation]
            nonEditable];
}

- (void)execute
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    CLLocation *latLon = [self getMapLocation];
    
    OATargetPointsHelper *targetPointsHelper = [OATargetPointsHelper sharedInstance];
    [targetPointsHelper navigateToPoint:latLon updateRoute:YES intermediate:(int)([targetPointsHelper getIntermediatePoints].count + 1) historyName:[[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION name:@""]];
    if (![[OsmAndApp instance].data restorePointToStart])
        [mapPanel.mapActions enterRoutePlanningModeGivenGpx:nil from:nil fromName:nil useIntermediatePointsByDefault:YES showDialog:YES];
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_add_dest_descr");
}

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
