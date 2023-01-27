//
//  OANavStartStopAction.m
//  OsmAnd
//
//  Created by Paul on 8/14/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OANavStartStopAction.h"
#import "OARoutingHelper.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAQuickActionType.h"

#define KEY_DIALOG @"dialog"

static OAQuickActionType *TYPE;

@implementation OANavStartStopAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    OARoutingHelper *helper = [OARoutingHelper sharedInstance];
    if ([helper isPauseNavigation] || [helper isFollowingMode])
    {
        // No destination dilogue yet
//        if ([self.getParams[KEY_DIALOG] boolValue])
//            return;
//        else
        [[OARootViewController instance].mapPanel stopNavigation];
    }
    else
    {
        [[OARootViewController instance].mapPanel onNavigationClick:NO];
    }
}

- (BOOL)isActionWithSlash
{
    OARoutingHelper *rh = [OARoutingHelper sharedInstance];
    return rh.isPauseNavigation || rh.isFollowingMode;
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_start_stop_nav_descr");
}

- (NSString *)getActionStateName
{
    OARoutingHelper *helper = [OARoutingHelper sharedInstance];
    if (helper.isPauseNavigation || helper.isFollowingMode)
    {
        return OALocalizedString(@"cancel_navigation");
    }
    return OALocalizedString(@"start_navigation");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:25 stringId:@"nav.startstop" class:self.class name:OALocalizedString(@"quick_action_start_stop_navigation") category:NAVIGATION iconName:@"ic_custom_navigation_arrow" secondaryIconName:nil editable:NO];
       
    return TYPE;
}

@end
