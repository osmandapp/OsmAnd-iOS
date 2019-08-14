//
//  OAShowHideLocalOSMChanges.m
//  OsmAnd
//
//  Created by Paul on 8/14/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAShowHideLocalOSMChanges.h"
#import "OAAppSettings.h"

@implementation OAShowHideLocalOSMChanges

- (instancetype)init
{
    return [super initWithType:EOAQuickActionTypeToggleLocalEditsLayer];
}

- (void)execute
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    [settings setMapSettingShowOfflineEdits:!settings.mapSettingShowOfflineEdits];
}

- (BOOL)isActionWithSlash
{
    return [OAAppSettings sharedManager].mapSettingShowOfflineEdits;
}

@end
