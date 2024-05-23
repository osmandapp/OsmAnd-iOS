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
#import "OsmAnd_Maps-Swift.h"

static NSString * const kDialog = @"dialog";

static OAQuickActionType *TYPE;

@implementation OANavStartStopAction
{
    OARoutingHelper *_helper;
}

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)commonInit
{
    _helper = [OARoutingHelper sharedInstance];
}

- (void)execute
{
    if ([_helper isPauseNavigation] || [_helper isFollowingMode])
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
    return _helper.isPauseNavigation || _helper.isFollowingMode;
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_start_stop_nav_descr");
}

- (NSString *)getActionStateName
{
    if (_helper.isPauseNavigation || _helper.isFollowingMode)
    {
        return OALocalizedString(@"cancel_navigation");
    }
    return OALocalizedString(@"start_navigation");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[[[[[OAQuickActionType alloc] initWithId:EOAQuickActionIdsNavStartStopActionId stringId:@"nav.startstop" cl:self.class] name:OALocalizedString(@"quick_action_start_stop_navigation")] iconName:@"ic_custom_navigation_arrow"] category:EOAQuickActionTypeCategoryNavigation] nonEditable];
    return TYPE;
}

@end
