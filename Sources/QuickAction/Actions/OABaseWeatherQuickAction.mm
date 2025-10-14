//
//  OABaseWeatherQuickAction.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 14.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OABaseWeatherQuickAction.h"
#import "Localization.h"
#import "OAWeatherHelper.h"
#import "OAWeatherPlugin.h"
#import "OAPluginsHelper.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OABaseWeatherQuickAction

- (instancetype)init
{
    return [super initWithActionType:self.class.getQuickActionType];
}

- (instancetype)initWithAction:(OAQuickAction *)action
{
    return [super initWithAction:action];
}

- (instancetype)initWithActionType:(QuickActionType *)type
{
    return [super initWithActionType:type];
}

- (void)execute
{
    OAWeatherHelper *helper = [OAWeatherHelper sharedInstance];
    OAWeatherBand *band = [helper getWeatherBand:[self weatherBandIndex]];
    OAWeatherPlugin *plugin = (OAWeatherPlugin *)[OAPluginsHelper getPlugin:OAWeatherPlugin.class];
    if (!band || !plugin)
        return;
    
    BOOL visible = ![band isBandVisible];
    if (visible && ![OAPluginsHelper isEnabled:OAWeatherPlugin.class])
        [OAPluginsHelper enablePlugin:plugin enable:YES];
    
    [band setSelectBand:visible];
    BOOL anyVisible = ![helper allLayersAreDisabled];
    [plugin weatherChanged:anyVisible];
}

- (NSString *)getActionStateName
{
    NSString *nameRes = [self.class getQuickActionType].name;
    NSString *actionName = OALocalizedString([self isActionWithSlash] ? @"shared_string_hide" : @"shared_string_show");
    return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_dash"), actionName, nameRes ?: @""];
}

- (BOOL)isActionWithSlash
{
    OAWeatherBand *band = [[OAWeatherHelper sharedInstance] getWeatherBand:[self weatherBandIndex]];
    return band ? [band isBandVisible] : NO;
}

- (EOAWeatherBand)weatherBandIndex {
    return WEATHER_BAND_NOTHING;
}

@end
