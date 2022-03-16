//
//  OARendererRegistry.m
//  OsmAnd Maps
//
//  Created by Paul on 20.05.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OARendererRegistry.h"
#import "OsmAndApp.h"
#import "OAIndexConstants.h"

#include <OsmAndCore/Map/MapStylesCollection.h>
#include <OsmAndCore/Map/UnresolvedMapStyle.h>

static NSDictionary<NSString *, NSString *> *externalRenderers;
static NSDictionary<NSString *, NSString *> *internalRenderers;
static NSDictionary<NSString *, NSString *> *stylesTitlesOffline;

@implementation OARendererRegistry

+ (NSDictionary<NSString *, NSString *> *)getInternalRenderers
{
    if (!internalRenderers || internalRenderers.count == 0)
    {
        internalRenderers = @{
                DEFAULT_RENDER: DEFAULT_RENDER_FILE_PATH,
                TOURING_VIEW: [NSString stringWithFormat:@"Touring-view_(more-contrast-and-details)%@", RENDERER_INDEX_EXT],
                TOPO_RENDER: [NSString stringWithFormat:@"topo%@", RENDERER_INDEX_EXT],
                MAPNIK_RENDER: [NSString stringWithFormat:@"mapnik%@", RENDERER_INDEX_EXT],
                LIGHTRS_RENDER: [NSString stringWithFormat:@"LightRS%@", RENDERER_INDEX_EXT],
                UNIRS_RENDER: [NSString stringWithFormat:@"UniRS%@", RENDERER_INDEX_EXT],
                NAUTICAL_RENDER: [NSString stringWithFormat:@"nautical%@", RENDERER_INDEX_EXT],
                WINTER_SKI_RENDER: [NSString stringWithFormat:@"skimap%@", RENDERER_INDEX_EXT],
                OFFROAD_RENDER: [NSString stringWithFormat:@"offroad%@", RENDERER_INDEX_EXT],
                DESERT_RENDER: [NSString stringWithFormat:@"desert%@", RENDERER_INDEX_EXT],
                SNOWMOBILE_RENDER: [NSString stringWithFormat:@"snowmobile%@", RENDERER_INDEX_EXT]
        };
    }
    return internalRenderers;
}

+ (NSDictionary<NSString *, NSString *> *)getExternalRenderers
{
    if (!externalRenderers || externalRenderers.count == 0)
    {
        NSMutableDictionary<NSString *, NSString *> *res = [NSMutableDictionary dictionary];
        [self fetchExternalRenderers:[OsmAndApp instance].documentsPath acceptedItems:res];
        externalRenderers = res;
    }
    return externalRenderers;
}

+ (void)fetchExternalRenderers:(NSString *)basePath
                 acceptedItems:(NSMutableDictionary<NSString *, NSString *> *)acceptedItems
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSArray<NSString *> *items = [fileManager contentsOfDirectoryAtPath:basePath error:nil];
    for (NSString *item in items)
    {
        if ([item hasSuffix:RENDERER_INDEX_EXT])
            acceptedItems[[item stringByReplacingOccurrencesOfString:RENDERER_INDEX_EXT withString:@""]] = [basePath stringByAppendingPathComponent:item];
        else if ([item isEqualToString:RENDERERS_DIR])
            [self fetchExternalRenderers:[basePath stringByAppendingPathComponent:item] acceptedItems:acceptedItems];
    }
}

+ (NSArray<NSString *> *)getPathExternalRenderers
{
    return [self getExternalRenderers].allValues;
}

+ (NSDictionary *)getMapStyleInfo:(NSString *)renderer
{
    OsmAndAppInstance app = [OsmAndApp instance];
    NSMutableDictionary *mapStyleInfo = [NSMutableDictionary dictionary];

    BOOL isDefault = [renderer isEqualToString:@"default"] || [renderer isEqualToString:DEFAULT_RENDER];
    BOOL isTouringView = [renderer isEqualToString:@"Touring view"]
            || [renderer isEqualToString:TOURING_VIEW]
            || [renderer hasPrefix:@"Touring-view_(more-contrast-and-details)"];

    if (isDefault || isTouringView)
    {
        mapStyleInfo[@"title"] = isDefault ? DEFAULT_RENDER : TOURING_VIEW;
        mapStyleInfo[@"id"] = isDefault ? @"default" : @"Touring-view_(more-contrast-and-details)";
        mapStyleInfo[@"sort_index"] = @([self getSortIndexForTitle:mapStyleInfo[@"title"]]);
        return mapStyleInfo;
    }

    QList< std::shared_ptr<const OsmAnd::UnresolvedMapStyle> > mapStyleCollection = app.resourcesManager->mapStylesCollection->getCollection();
    for (auto mapStyle : mapStyleCollection)
    {
        NSString *title = mapStyle->title.toNSString();
        NSString *name = mapStyle->name.toNSString();
        NSString *id;
        if ([renderer compare:name] == NSOrderedSame || [renderer compare:title] == NSOrderedSame)
        {
            title = [self getMapStyleTitles][title];
            BOOL isExternal = NO;
            if (!title)
            {
                for (NSString *externalName in [self getExternalRenderers].allKeys)
                {
                    if ([externalName compare:name] == NSOrderedSame)
                    {
                        isExternal = YES;
                        title = externalName;
                        id = name; //[[self getExternalRenderers][externalName].lastPathComponent stringByReplacingOccurrencesOfString:RENDERER_INDEX_EXT withString:@""];
                        break;
                    }
                }
            }

            if (!isExternal)
                id = [[self getInternalRenderers][title] stringByReplacingOccurrencesOfString:RENDERER_INDEX_EXT withString:@""];

            if (title)
                mapStyleInfo[@"title"] = title;
            if (id)
                mapStyleInfo[@"id"] = id;

            break;
        }
    }

    if (![mapStyleInfo.allKeys containsObject:@"title"])
        mapStyleInfo[@"title"] = renderer;
    if (![mapStyleInfo.allKeys containsObject:@"id"])
        mapStyleInfo[@"id"] = renderer.lowercaseString;

    mapStyleInfo[@"sort_index"] = @([self getSortIndexForTitle:mapStyleInfo[@"title"]]);
    return mapStyleInfo;

}

+ (NSDictionary<NSString *, NSString *> *)getMapStyleTitles
{
    if (!stylesTitlesOffline || stylesTitlesOffline.count == 0)
    {
        stylesTitlesOffline = @{
                @"default" : DEFAULT_RENDER,
                @"nautical" : NAUTICAL_RENDER,
                @"Ski-map" : WINTER_SKI_RENDER,
                UNIRS_RENDER : UNIRS_RENDER,
                @"Touring-view_(more-contrast-and-details).render" : TOURING_VIEW,
                LIGHTRS_RENDER : LIGHTRS_RENDER,
                TOPO_RENDER : TOPO_RENDER,
                @"Offroad by ZLZK" : OFFROAD_RENDER,
                @"Depends-template" : MAPNIK_RENDER,
                DESERT_RENDER : DESERT_RENDER,
                SNOWMOBILE_RENDER : SNOWMOBILE_RENDER
        };
    }
    return stylesTitlesOffline;
}

+ (int)getSortIndexForTitle:(NSString *)title
{
    if ([title isEqualToString:DEFAULT_RENDER])
        return 0;
    else if ([title isEqualToString:UNIRS_RENDER])
        return 1;
    else if ([title isEqualToString:@"Touring view"] || [title isEqualToString:TOURING_VIEW])
        return 2;
    else if ([title isEqualToString:LIGHTRS_RENDER])
        return 3;
    else if ([title isEqualToString:WINTER_SKI_RENDER])
        return 4;
    else if ([title isEqualToString:NAUTICAL_RENDER])
        return 5;
    else if ([title isEqualToString:OFFROAD_RENDER])
        return 6;
    else if ([title isEqualToString:DESERT_RENDER])
        return 7;
    else if ([title isEqualToString:SNOWMOBILE_RENDER])
        return 8;
    else
        return 9;
}

@end
