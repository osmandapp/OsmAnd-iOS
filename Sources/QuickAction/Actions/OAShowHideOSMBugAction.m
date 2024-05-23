//
//  OAShowHideOSMBugAction.m
//  OsmAnd
//
//  Created by Paul on 8/14/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAShowHideOSMBugAction.h"
#import "OAAppSettings.h"
#import "OsmAnd_Maps-Swift.h"

static OAQuickActionType *TYPE;

@implementation OAShowHideOSMBugAction
{
    OAAppSettings *_settings;
}

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

- (void)execute
{
    [_settings setShowOnlineNotes:![_settings.mapSettingShowOnlineNotes get]];
}

- (BOOL)isActionWithSlash
{
    return [_settings.mapSettingShowOnlineNotes get];
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
        TYPE = [[[[[[OAQuickActionType alloc] initWithId:EOAQuickActionIdsShowHideOsmBugActionId stringId:@"osmbug.showhide" cl:self.class] name:OALocalizedString(@"toggle_online_notes")] iconName:@"ic_action_osm_note"] category:EOAQuickActionTypeCategoryConfigureMap] nonEditable];
    return TYPE;
}

@end
