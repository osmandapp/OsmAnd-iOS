//
//  OANavAutoZoomMapAction.m
//  OsmAnd
//
//  Created by Paul on 8/13/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OANavAutoZoomMapAction.h"
#import "OAAppSettings.h"
#import "OAQuickActionType.h"

static OAQuickActionType *TYPE;

@implementation OANavAutoZoomMapAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    [settings.autoZoomMap set:![settings.autoZoomMap get]];
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_autozoom_descr");
}

- (BOOL)isActionWithSlash
{
    return [[OAAppSettings sharedManager].autoZoomMap get];
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"auto_zoom_off") : OALocalizedString(@"auto_zoom_on");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:23 stringId:@"nav.autozoom" class:self.class name:OALocalizedString(@"quick_action_auto_zoom") category:NAVIGATION iconName:@"ic_navbar_search" secondaryIconName:nil editable:NO];
       
    return TYPE;
}

@end
