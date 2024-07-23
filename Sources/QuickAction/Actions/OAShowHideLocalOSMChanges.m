//
//  OAShowHideLocalOSMChanges.m
//  OsmAnd
//
//  Created by Paul on 8/14/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAShowHideLocalOSMChanges.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OAShowHideLocalOSMChanges
{
    OAAppSettings *_settings;
}

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsShowHideLocalOsmChangesActionId
                                            stringId:@"osmedit.showhide"
                                                  cl:self.class]
               name:OALocalizedString(@"osm_edits_title")]
              nameAction:OALocalizedString(@"quick_action_verb_show_hide")]
              iconName:@"ic_custom_osm_edits"]
             category:QuickActionTypeCategoryConfigureMap]
            nonEditable];
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

- (void)execute
{
    [_settings setShowOfflineEdits:![_settings.mapSettingShowOfflineEdits get]];
}

- (BOOL)isActionWithSlash
{
    return [_settings.mapSettingShowOfflineEdits get];
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_toggle_edits_descr");
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"hide_edits") : OALocalizedString(@"show_edits");
}

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
