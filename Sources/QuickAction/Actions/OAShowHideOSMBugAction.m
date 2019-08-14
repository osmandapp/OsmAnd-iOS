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

@end
