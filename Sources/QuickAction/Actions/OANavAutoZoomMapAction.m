//
//  OANavAutoZoomMapAction.m
//  OsmAnd
//
//  Created by Paul on 8/13/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OANavAutoZoomMapAction.h"
#import "OAAppSettings.h"

@implementation OANavAutoZoomMapAction

- (instancetype)init
{
    return [super initWithType:EOAQuickActionTypeAutoZoomMap];
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

@end
