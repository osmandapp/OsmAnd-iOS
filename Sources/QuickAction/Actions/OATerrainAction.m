//
//  OAHillshadeAction.m
//  OsmAnd Maps
//
//  Created by igor on 19.11.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OATerrainAction.h"
#import "OsmAndApp.h"
#import "OAAppData.h"
#import "OsmAnd_Maps-Swift.h"

static OAQuickActionType *TYPE;

@implementation OATerrainAction

- (instancetype)init
{
    return [super initWithActionType:self.class.TYPE];
}

+ (void)initialize
{
    TYPE = [[[[[[OAQuickActionType alloc] initWithId:EOAQuickActionIdsTerrainActionId
                                            stringId:@"terrain.showhide"
                                                  cl:self.class]
               name:OALocalizedString(@"toggle_hillshade")]
              iconName:@"ic_custom_hillshade"]
             category:EOAQuickActionTypeCategoryConfigureMap]
            nonEditable];
}

- (void)execute
{
    OAAppData *data = [OsmAndApp instance].data;
    BOOL isOn = [data terrainType] != EOATerrainTypeDisabled;
    if (isOn)
    {
        [data setLastTerrainType:data.terrainType];
        [data setTerrainType:EOATerrainTypeDisabled];
    }
    else
    {
        [data setTerrainType:data.lastTerrainType];
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

+ (OAQuickActionType *) TYPE
{
    return TYPE;
}

@end
