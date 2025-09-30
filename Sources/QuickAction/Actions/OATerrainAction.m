//
//  OAHillshadeAction.m
//  OsmAnd Maps
//
//  Created by igor on 19.11.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OATerrainAction.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

static QuickActionType *TYPE;

@implementation OATerrainAction
{
    OASRTMPlugin *_plugin;
}

- (instancetype)init
{
    return [super initWithActionType:self.class.getQuickActionType];
}

- (void)commonInit
{
    _plugin = (OASRTMPlugin *) [OAPluginsHelper getPlugin:OASRTMPlugin.class];
}

+ (void)initialize
{
    TYPE = [[[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsTerrainActionId
                                            stringId:@"terrain.showhide"
                                                  cl:self.class]
               name:OALocalizedString(@"shared_string_terrain")]
              nameAction:OALocalizedString(@"quick_action_verb_show_hide")]
              iconName:ACImageNameIcCustomHillshade]
             category:QuickActionTypeCategoryConfigureMap]
            nonEditable];
}

- (void)execute
{
    [_plugin setTerrainLayerEnabled:![_plugin isTerrainLayerEnabled]];
}

- (NSString *)getIconResName
{
    return ACImageNameIcCustomHillshade;
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_hillshade_descr");
}

- (BOOL)isActionWithSlash
{
    return [_plugin isTerrainLayerEnabled];
}

- (NSString *)getActionStateName
{
    return [_plugin isTerrainLayerEnabled] ? OALocalizedString(@"hide_terrain") : OALocalizedString(@"show_terrain");
}

+ (QuickActionType *)getQuickActionType
{
    return TYPE;
}

@end
