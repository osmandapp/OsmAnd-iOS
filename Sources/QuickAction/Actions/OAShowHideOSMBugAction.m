//
//  OAShowHideOSMBugAction.m
//  OsmAnd
//
//  Created by Paul on 8/14/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAShowHideOSMBugAction.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OAShowHideOSMBugAction
{
    OAAppSettings *_settings;
}

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsShowHideOsmBugActionId
                                            stringId:@"osmbug.showhide"
                                                  cl:self.class]
               name:OALocalizedString(@"osm_notes")]
              nameAction:OALocalizedString(@"quick_action_verb_show_hide")]
              iconName:@"ic_action_osm_note"]
             category:QuickActionTypeCategoryConfigureMap]
            nonEditable];
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

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
