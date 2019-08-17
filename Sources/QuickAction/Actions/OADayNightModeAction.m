//
//  OADayNightModeAction.m
//  OsmAnd
//
//  Created by Paul on 8/7/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OADayNightModeAction.h"
#import "OAAppSettings.h"

@implementation OADayNightModeAction

- (instancetype) init
{
    return [super initWithType:EOAQuickActionTypeToggleDayNight];
}

- (void)execute
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    if (settings.nightMode)
        [settings setSettingAppMode:APPEARANCE_MODE_DAY];
    else
        [settings setSettingAppMode:APPEARANCE_MODE_NIGHT];
}

- (NSString *)getIconResName
{
    if ([OAAppSettings sharedManager].nightMode)
        return @"ic_custom_sun";
    return @"ic_custom_moon";
}

@end
