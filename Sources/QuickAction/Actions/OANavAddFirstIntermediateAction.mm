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
#import "OAMapRendererView.h"
#import "OATargetPoint.h"
#import "OATargetPointsHelper.h"
#import "OAPointDescription.h"
#import "OAMapActions.h"
#import "OsmAndApp.h"
#import "OAQuickActionType.h"

#include <OsmAndCore/Utilities.h>

static OAQuickActionType *TYPE;

@implementation OANavAddFirstIntermediateAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    const auto& latLon = OsmAnd::Utilities::convert31ToLatLon(mapPanel.mapViewController.mapView.target31);
    CLLocation *location = [[CLLocation alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude];
    
    OATargetPointsHelper *targetPointsHelper = [OATargetPointsHelper sharedInstance];
    [targetPointsHelper navigateToPoint:location updateRoute:YES intermediate:[OsmAndApp instance].data.pointToNavigate == nil ? 1 : 0 historyName:[[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION name:@""]];
    if (![[OsmAndApp instance].data restorePointToStart])
        [mapPanel.mapActions enterRoutePlanningModeGivenGpx:nil from:nil fromName:nil useIntermediatePointsByDefault:YES showDialog:YES];
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_first_intermediate_descr");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:22 stringId:@"nav.intermediate.add" class:self.class name:OALocalizedString(@"quick_action_add_first_intermediate") category:NAVIGATION iconName:@"ic_action_intermediate" secondaryIconName:@"ic_custom_compound_action_add" editable:NO];
       
    return TYPE;
}

@end
