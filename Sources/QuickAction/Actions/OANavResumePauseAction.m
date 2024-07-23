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
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OANavResumePauseAction
{
    OARoutingHelper *_helper;
}

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsNavResumePauseActionId
                                             stringId:@"nav.resumepause"
                                                   cl:self.class]
                name:OALocalizedString(@"quick_action_resume_pause_navigation")]
               iconName:@"ic_custom_navigation_arrow"]
              secondaryIconName:@"ic_custom_compound_action_add"]
             category:QuickActionTypeCategoryNavigation]
            nonEditable];
}

- (void)commonInit
{
    _helper = [OARoutingHelper sharedInstance];
}

- (void)execute
{
    if (_helper.isRoutePlanningMode)
    {
        [_helper setRoutePlanningMode:NO];
        [_helper setFollowingMode:YES];
    }
    else
    {
        [_helper setRoutePlanningMode:YES];
        [_helper setFollowingMode:NO];
        [_helper setPauseNaviation:YES];
    }
    [[OAMapViewTrackingUtilities instance] switchToRoutePlanningMode];
    [[OARootViewController instance].mapPanel refreshMap];
}

- (BOOL)isActionEnabled
{
    return _helper.isRouteCalculated;
}

- (NSString *)getSecondaryIconName
{
    if (_helper.isRoutePlanningMode)
        return @"ic_custom_compound_action_pause";
    return @"ic_custom_compound_action_play";
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_pause_nav_descr");
}

- (NSString *)getActionStateName
{
    if (!_helper.isRouteCalculated || _helper.isRoutePlanningMode)
        return OALocalizedString(@"resume_nav");

    return OALocalizedString(@"pause_nav");
}

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
