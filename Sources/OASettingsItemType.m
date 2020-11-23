//
//  OASettingsItemType.m
//  OsmAnd
//
//  Created by Anna Bibyk on 23.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsItemType.h"

@implementation OASettingsItemType

+ (NSString * _Nullable) typeName:(EOASettingsItemType)type
{
    switch (type)
    {
        case EOASettingsItemTypeGlobal:
            return @"GLOBAL";
        case EOASettingsItemTypeProfile:
            return @"PROFILE";
        case EOASettingsItemTypePlugin:
            return @"PLUGIN";
        case EOASettingsItemTypeData:
            return @"DATA";
        case EOASettingsItemTypeFile:
            return @"FILE";
        case EOASettingsItemTypeQuickActions:
            return @"QUICK_ACTIONS";
        case EOASettingsItemTypePoiUIFilters:
            return @"POI_UI_FILTERS";
        case EOASettingsItemTypeMapSources:
            return @"MAP_SOURCES";
        case EOASettingsItemTypeAvoidRoads:
            return @"AVOID_ROADS";
        default:
            return nil;
    }
}

+ (EOASettingsItemType) parseType:(NSString *)typeName
{
    if ([typeName isEqualToString:@"GLOBAL"])
        return EOASettingsItemTypeGlobal;
    if ([typeName isEqualToString:@"PROFILE"])
        return EOASettingsItemTypeProfile;
    if ([typeName isEqualToString:@"PLUGIN"])
        return EOASettingsItemTypePlugin;
    if ([typeName isEqualToString:@"DATA"])
        return EOASettingsItemTypeData;
    if ([typeName isEqualToString:@"FILE"])
        return EOASettingsItemTypeFile;
    if ([typeName isEqualToString:@"QUICK_ACTIONS"])
        return EOASettingsItemTypeQuickActions;
    if ([typeName isEqualToString:@"POI_UI_FILTERS"])
        return EOASettingsItemTypePoiUIFilters;
    if ([typeName isEqualToString:@"MAP_SOURCES"])
        return EOASettingsItemTypeMapSources;
    if ([typeName isEqualToString:@"AVOID_ROADS"])
        return EOASettingsItemTypeAvoidRoads;
    
    return EOASettingsItemTypeUnknown;
}

@end
