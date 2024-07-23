//
//  OANavReplaceDestinationAction.m
//  OsmAnd
//
//  Created by Paul on 8/13/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OANavReplaceDestinationAction.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OATargetPointsHelper.h"
#import "OAPointDescription.h"
#import "OAMapActions.h"
#import "OsmAndApp.h"
#import "OAAppData.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OANavReplaceDestinationAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsNavReplaceDestinationActionId
                                             stringId:@"nav.destination.replace"
                                                   cl:self.class]
                name:OALocalizedString(@"quick_action_replace_destination")]
               iconName:@"ic_action_target"]
              secondaryIconName:@"ic_custom_compound_action_replace"]
             category:QuickActionTypeCategoryNavigation]
            nonEditable];
}

- (void)execute
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    CLLocation *latLon = [self getMapLocation];

    OATargetPointsHelper *targetPointsHelper = [OATargetPointsHelper sharedInstance];
    [targetPointsHelper navigateToPoint:latLon updateRoute:YES intermediate:-1 historyName:[[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION name:@""]];
    if (![[OsmAndApp instance].data restorePointToStart])
        [mapPanel.mapActions enterRoutePlanningModeGivenGpx:nil from:nil fromName:nil useIntermediatePointsByDefault:YES showDialog:YES];
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_replace_dest_descr");
}

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
