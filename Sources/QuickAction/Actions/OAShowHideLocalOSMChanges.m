//
//  OAShowHideLocalOSMChanges.m
//  OsmAnd
//
//  Created by Paul on 8/14/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAShowHideLocalOSMChanges.h"
#import "OAAppSettings.h"
#import "OAQuickActionType.h"

static OAQuickActionType *TYPE;

@implementation OAShowHideLocalOSMChanges

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    [settings setShowOfflineEdits:![settings.showOSMEdits get]];
}

- (BOOL)isActionWithSlash
{
    return [[OAAppSettings sharedManager].showOSMEdits get];
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_toggle_edits_descr");
}

- (NSString *)getActionStateName
{
    return [self isActionWithSlash] ? OALocalizedString(@"hide_edits") : OALocalizedString(@"show_edits");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:31 stringId:@"osmedit.showhide" class:self.class name:OALocalizedString(@"toggle_local_edits") category:CONFIGURE_MAP iconName:@"ic_custom_osm_edits" secondaryIconName:nil editable:NO];
       
    return TYPE;
}

@end
