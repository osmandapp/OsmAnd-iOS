//
//  OAShowHideOSMBugAction.m
//  OsmAnd
//
//  Created by Paul on 8/14/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAShowHideOSMBugAction.h"
#import "OAAppSettings.h"
#import "OAQuickActionType.h"

static OAQuickActionType *TYPE;

@implementation OAShowHideOSMBugAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    [settings setShowOnlineNotes:![settings.mapSettingShowOnlineNotes get]];
}

- (BOOL)isActionWithSlash
{
    return [[OAAppSettings sharedManager].mapSettingShowOnlineNotes get];
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_toggle_notes_descr");
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"hide_notes") : OALocalizedString(@"show_notes");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:24 stringId:@"osmbug.showhide" class:self.class name:OALocalizedString(@"toggle_online_notes") category:CONFIGURE_MAP iconName:@"ic_action_osm_note" secondaryIconName:nil editable:NO];
       
    return TYPE;
}

@end
