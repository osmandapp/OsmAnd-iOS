//
//  OADayNightModeAction.m
//  OsmAnd
//
//  Created by Paul on 8/7/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OADayNightModeAction.h"
#import "OAAppSettings.h"
#import "OAQuickActionType.h"
#import "OADayNightHelper.h"

static OAQuickActionType *TYPE;

@implementation OADayNightModeAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

- (void)execute
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    if (settings.nightMode)
        [settings.appearanceMode set:APPEARANCE_MODE_DAY];
    else
        [settings.appearanceMode set:APPEARANCE_MODE_NIGHT];
    [[OADayNightHelper instance] forceUpdate];
}

- (NSString *)getIconResName
{
    if ([OAAppSettings sharedManager].nightMode)
        return @"ic_custom_sun";
    return @"ic_custom_moon";
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_day_night_descr");
}

- (NSString *)getActionStateName
{
    return [OAAppSettings sharedManager].nightMode ? OALocalizedString(@"day_mode") : OALocalizedString(@"night_mode");
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [[OAQuickActionType alloc] initWithIdentifier:27 stringId:@"daynight.switch" class:self.class name:OALocalizedString(@"day_mode") category:CONFIGURE_MAP iconName:@"ic_custom_sun" secondaryIconName:nil editable:NO];
       
    return TYPE;
}

@end
