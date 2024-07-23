//
//  OADayNightModeAction.m
//  OsmAnd
//
//  Created by Paul on 8/7/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OADayNightModeAction.h"
#import "OAAppSettings.h"
#import "OADayNightHelper.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OADayNightModeAction
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

+ (void)initialize
{
    TYPE = [[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsDayNightModeActionId
                                            stringId:@"daynight.switch"
                                                  cl:self.class]
               name:OALocalizedString(@"quick_action_switch_day_mode")]
              iconName:@"ic_custom_sun"]
             category:QuickActionTypeCategoryConfigureMap]
            nonEditable];
}

- (void)execute
{
    if (_settings.nightMode)
        [_settings.appearanceMode set:APPEARANCE_MODE_DAY];
    else
        [_settings.appearanceMode set:APPEARANCE_MODE_NIGHT];
    [[OADayNightHelper instance] forceUpdate];
}

- (NSString *)getIconResName
{
    if (_settings.nightMode)
        return @"ic_custom_sun";
    return @"ic_custom_moon";
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_day_night_descr");
}

- (NSString *)getActionStateName
{
    return _settings.nightMode ? OALocalizedString(@"quick_action_switch_day_mode") : OALocalizedString(@"quick_action_switch_night_mode");
}

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
