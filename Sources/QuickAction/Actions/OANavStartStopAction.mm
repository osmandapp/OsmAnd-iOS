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

#define KEY_DIALOG @"dialog"

@implementation OANavStartStopAction

- (instancetype)init
{
    return [super initWithType:EOAQuickActionTypeToggleNavigation];
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

@end
