//
//  OANavAddFirstIntermediateAction.m
//  OsmAnd
//
//  Created by Paul on 8/13/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OANavAddFirstIntermediateAction.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OATargetPointsHelper.h"
#import "OAPointDescription.h"
#import "OAMapActions.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OANavAddFirstIntermediateAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsNavAddFirstIntermediateActionId
                                             stringId:@"nav.intermediate.add"
                                                   cl:self.class]
                name:OALocalizedString(@"quick_action_add_first_intermediate")]
               iconName:@"ic_action_intermediate"]
              secondaryIconName:@"ic_custom_compound_action_add"]
             category:QuickActionTypeCategoryNavigation]
            nonEditable];
}

- (void)execute
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    CLLocation *latLon = [self getMapLocation];
    
    OATargetPointsHelper *targetPointsHelper = [OATargetPointsHelper sharedInstance];
    [targetPointsHelper navigateToPoint:latLon updateRoute:YES intermediate:[OsmAndApp instance].data.pointToNavigate == nil ? 1 : 0 historyName:[[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION name:@""]];
    if (![[OsmAndApp instance].data restorePointToStart])
        [mapPanel.mapActions enterRoutePlanningModeGivenGpx:nil from:nil fromName:nil useIntermediatePointsByDefault:YES showDialog:YES];
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_first_intermediate_descr");
}

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
