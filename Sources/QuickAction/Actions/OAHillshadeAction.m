//
//  OAHillshadeAction.m
//  OsmAnd Maps
//
//  Created by igor on 19.11.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAHillshadeAction.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OAAppData.h"

@implementation OAHillshadeAction


- (instancetype) init
{
    return [super initWithType:EOAQuickActionTypeToggleHillshade];
}

- (void)execute
{
    OAAppData *data = [OsmAndApp instance].data;
    BOOL isOn = [data hillshade];
    [data setHillshade:!isOn];
}

- (NSString *)getIconResName
{
    return @"ic_custom_hillshade";
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_hillshade_descr");
}

- (BOOL)isActionWithSlash
{
    return [[OsmAndApp instance].data hillshade];
}

- (NSString *)getActionStateName
{
    return [[OsmAndApp instance].data hillshade] ? OALocalizedString(@"hide_hillshade") : OALocalizedString(@"show_hillshade");
}

@end
