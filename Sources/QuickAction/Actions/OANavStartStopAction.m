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
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OANavStartStopAction
{
    OARoutingHelper *_helper;
}

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsNavStartStopActionId
                                            stringId:@"nav.startstop"
                                                  cl:self.class]
               name:OALocalizedString(@"shared_string_navigation")]
               nameAction:OALocalizedString(@"quick_action_verb_start_stop")]
              iconName:@"ic_custom_navigation_arrow"]
             category:QuickActionTypeCategoryNavigation]
            nonEditable];
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

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
