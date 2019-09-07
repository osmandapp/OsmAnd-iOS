//
//  OAShowHideOSMBugAction.m
//  OsmAnd
//
//  Created by Paul on 8/14/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAShowHideOSMBugAction.h"
#import "OAAppSettings.h"

@implementation OAShowHideOSMBugAction

- (instancetype)init
{
    return [super initWithType:EOAQuickActionTypeToggleOsmNotes];
}

- (void)execute
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    [settings setMapSettingShowOnlineNotes:!settings.mapSettingShowOnlineNotes];
}

- (BOOL)isActionWithSlash
{
    return [OAAppSettings sharedManager].mapSettingShowOnlineNotes;
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_toggle_notes_descr");
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"hide_notes") : OALocalizedString(@"show_notes");
}

@end
