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
#import "OAQuickActionType.h"

static OAQuickActionType *TYPE;

@implementation OANavResumePauseAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
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

- (NSString *)getActionStateName
{
    OARoutingHelper *helper = [OARoutingHelper sharedInstance];
    if (!helper.isRouteCalculated || helper.isRoutePlanningMode)
        return OALocalizedString(@"resume_nav");
    
    return OALocalizedString(@"pause_nav");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:26 stringId:@"nav.resumepause" class:self.class name:OALocalizedString(@"quick_action_resume_pause_navigation") category:NAVIGATION iconName:@"ic_custom_navigation_arrow" secondaryIconName:@"ic_custom_compound_action_add" editable:NO];
       
    return TYPE;
}

@end
