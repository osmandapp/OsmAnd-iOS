//
//  OAHillshadeAction.m
//  OsmAnd Maps
//
//  Created by igor on 19.11.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OATerrainAction.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OAAppData.h"

@implementation OATerrainAction


- (instancetype) init
{
    return [super initWithType:EOAQuickActionTypeToggleHillshade];
}

- (void)execute
{
    OAAppData *data = [OsmAndApp instance].data;
    BOOL isOn = [data terrainType] != EOATerrainTypeDisabled;
    if (isOn)
    {
        [data setTerrainType:data.lastTerrainType];
    }
    else
    {
        [data setLastTerrainType:data.terrainType];
        [data setTerrainType:EOATerrainTypeDisabled];
    }
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
    return [[OsmAndApp instance].data terrainType] != EOATerrainTypeDisabled;
}

- (NSString *)getActionStateName
{
    return [[OsmAndApp instance].data terrainType] != EOATerrainTypeDisabled ? OALocalizedString(@"hide_terrain") : OALocalizedString(@"show_terrain");
}

@end
