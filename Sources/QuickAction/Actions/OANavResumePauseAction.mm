//
//  OANavResumePauseAction.m
//  OsmAnd
//
//  Created by Paul on 8/14/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OANavResumePauseAction.h"
#import "OAMapViewTrackingUtilities.h"
#import "OARoutingHelper.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"

@implementation OANavResumePauseAction

- (instancetype)init
{
    return [super initWithType:EOAQuickActionTypeResumePauseNavigation];
}

- (void)execute
{
    OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
    if (routingHelper.isRoutePlanningMode)
    {
        [routingHelper setRoutePlanningMode:NO];
        [routingHelper setFollowingMode:YES];
    }
    else
    {
        [routingHelper setRoutePlanningMode:YES];
        [routingHelper setFollowingMode:NO];
        [routingHelper setPauseNaviation:YES];
    }
    [[OAMapViewTrackingUtilities instance] switchToRoutePlanningMode];
    [[OARootViewController instance].mapPanel refreshMap];
}

- (BOOL)isActionEnabled
{
    return [OARoutingHelper sharedInstance].isRouteCalculated;
}

- (NSString *)getSecondaryIconName
{
    if ([OARoutingHelper sharedInstance].isRoutePlanningMode)
        return @"ic_custom_compound_action_pause";
    return @"ic_custom_compound_action_play";
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_pause_nav_descr");
}

@end
