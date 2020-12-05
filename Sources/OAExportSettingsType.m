//
//  OAExportSettingsType.m
//  OsmAnd
//
//  Created by Anna Bibyk on 23.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAExportSettingsType.h"

@implementation OAExportSettingsType

+ (NSString * _Nullable) typeName:(EOAExportSettingsType)type
{
    switch (type)
    {
        case EOAExportSettingsTypeProfile:
            return @"PROFILE";
        case EOAExportSettingsTypeQuickActions:
            return @"QUICK_ACTIONS";
        case EOAExportSettingsTypePoiTypes:
            return @"POI_TYPES";
        case EOAExportSettingsTypeMapSources:
            return @"MAP_SOURCES";
        case EOAExportSettingsTypeCustomRendererStyles:
            return @"CUSTOM_RENDER_STYLE";
        case EOAExportSettingsTypeCustomRouting:
            return @"CUSTOM_ROUTING";
        case EOAExportSettingsTypeGPX:
            return @"GPX";
        case EOAExportSettingsTypeMapFiles:
            return @"MAP_FILE";
        case EOAExportSettingsTypeAvoidRoads:
            return @"AVOID_ROADS";
        case EOAExportSettingsTypeOsmNotes:
            return @"OSM_NOTES";
        case EOAExportSettingsTypeOsmEdits:
            return @"OSM_EDITS";
        default:
            return nil;
    }
}

+ (EOAExportSettingsType) parseType:(NSString *)typeName
{
    if ([typeName isEqualToString:@"PROFILE"])
        return EOAExportSettingsTypeProfile;
    if ([typeName isEqualToString:@"QUICK_ACTIONS"])
        return EOAExportSettingsTypeQuickActions;
    if ([typeName isEqualToString:@"POI_TYPES"])
        return EOAExportSettingsTypePoiTypes;
    if ([typeName isEqualToString:@"MAP_SOURCES"])
        return EOAExportSettingsTypeMapSources;
    if ([typeName isEqualToString:@"CUSTOM_RENDER_STYLE"])
        return EOAExportSettingsTypeCustomRendererStyles;
    if ([typeName isEqualToString:@"CUSTOM_ROUTING"])
        return EOAExportSettingsTypeCustomRouting;
    if ([typeName isEqualToString:@"GPX"])
        return EOAExportSettingsTypeGPX;
    if ([typeName isEqualToString:@"MAP_FILE"])
        return EOAExportSettingsTypeMapFiles;
    if ([typeName isEqualToString:@"AVOID_ROADS"])
        return EOAExportSettingsTypeAvoidRoads;
    if ([typeName isEqualToString:@"OSM_NOTES"])
        return EOAExportSettingsTypeOsmNotes;
    if ([typeName isEqualToString:@"OSM_EDITS"])
        return EOAExportSettingsTypeOsmEdits;
    return EOAExportSettingsTypeUnknown;
}

@end
