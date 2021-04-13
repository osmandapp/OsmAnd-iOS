//
//  OAMapSourcesSettingsItem.mm
//  OsmAnd
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMapSourcesSettingsItem.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OASQLiteTileSource.h"
#import "OAMapCreatorHelper.h"
#import "OAResourcesUIHelper.h"
#import "OAMapStyleSettings.h"
#import "OATileSource.h"

#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

@interface OAMapSourcesSettingsItem()

@property (nonatomic) NSArray<OATileSource *> *items;
@property (nonatomic) NSMutableArray<OATileSource *> *appliedItems;

@end

@implementation OAMapSourcesSettingsItem
{
    NSArray<NSString *> *_existingItemNames;
}

@dynamic items, appliedItems;

- (void) initialization
{
    [super initialization];
    
    NSMutableArray<NSString *> *existingItemNames = [NSMutableArray array];
    
    OsmAndAppInstance app = [OsmAndApp instance];
    for (NSString *filePath in [OAMapCreatorHelper sharedInstance].files.allValues)
    {
        [existingItemNames addObject:[filePath.lastPathComponent stringByDeletingPathExtension]];
    }
    const auto& resource = app.resourcesManager->getResource(QStringLiteral("online_tiles"));
    if (resource != nullptr)
    {
        const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(resource->metadata)->sources;
        for(const auto& onlineTileSource : onlineTileSources->getCollection())
        {
            [existingItemNames addObject:onlineTileSource->name.toNSString()];
        }
    }
    _existingItemNames = existingItemNames;
}

- (instancetype) initWithItems:(NSArray<OATileSource *> *)items
{
    self = [super initWithItems:items];
    return self;
}

- (EOASettingsItemType) type
{
    return EOASettingsItemTypeMapSources;
}

- (void) apply
{
    NSArray<OATileSource *> *newItems = [self getNewItems];
    if (newItems.count > 0 || self.duplicateItems.count > 0)
    {
        OsmAndAppInstance app = [OsmAndApp instance];
        self.appliedItems = [NSMutableArray arrayWithArray:newItems];
        if ([self shouldReplace])
        {
            OAMapCreatorHelper *helper = [OAMapCreatorHelper sharedInstance];
            for (OATileSource *item in self.duplicateItems)
            {
                BOOL isSqlite = item.isSql;
                if (isSqlite)
                {
                    NSString *name = [item.name stringByAppendingPathExtension:@"sqlitedb"];
                    if (name && helper.files[name])
                    {
                        [[OAMapCreatorHelper sharedInstance] removeFile:name];
                        [self.appliedItems addObject:item];
                    }
                }
                else
                {
                    NSString *name = item.name;
                    if (name)
                    {
                        NSString *path = [app.cachePath stringByAppendingPathComponent:name];
                        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                        app.resourcesManager->uninstallTilesResource(QString::fromNSString(name));
                        [self.appliedItems addObject:item];
                    }
                }
            }
        }
        else
        {
            for (OATileSource *localItem in self.duplicateItems)
            {
                NSString *newName = [self getNewName:localItem.name];
                [self.appliedItems addObject:[[OATileSource alloc] initFromTileSource:localItem newName:newName]];
            }
        }
        for (OATileSource *localItem in self.appliedItems)
        {
            BOOL isSql = localItem.isSql;
            if (isSql)
            {
                NSString *path = [[NSTemporaryDirectory() stringByAppendingPathComponent:localItem.name] stringByAppendingPathExtension:@"sqlitedb"];
                if ([OASQLiteTileSource createNewTileSourceDbAtPath:path parameters:localItem.toSqlParams])
                    [[OAMapCreatorHelper sharedInstance] installFile:path newFileName:nil];
            }
            else
            {
                const auto result = localItem.toOnlineTileSource;
                OsmAnd::OnlineTileSources::installTileSource(result, QString::fromNSString(app.cachePath));
                app.resourcesManager->installTilesResource(result);
            }
        }
    }
}

- (NSString *) getNewName:(NSString *)oldName
{
    NSString *newName = @"";
    if (oldName)
    {
        int number = 0;
        while (true)
        {
            number++;
            
            newName = [NSString stringWithFormat:@"%@_%d", oldName, number];
            if (![self isDuplicateName:newName])
                return newName;
        }
    }
    return newName;
}

- (BOOL) isDuplicateName:(NSString *)name
{
    if (name)
        return [_existingItemNames containsObject:name];
    return NO;
}

- (NSString *) name
{
    return @"map_sources";
}

- (BOOL) shouldReadOnCollecting
{
    return YES;
}

- (BOOL)isDuplicate:(id)item
{
    for (NSString *name in _existingItemNames)
    {
        if ([name isEqualToString:((OATileSource *)item).name])
            return YES;
    }
    return NO;
}

- (OASettingsItemReader *) getReader
{
    return [self getJsonReader];
}

- (OASettingsItemWriter *)getWriter
{
    return [self getJsonWriter];
}

- (void) readItemsFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSArray* itemsJson = [json mutableArrayValueForKey:@"items"];
    if (itemsJson.count == 0)
        return;
    
    NSMutableArray<OATileSource *> *tileSources = [NSMutableArray new];
    for (NSDictionary *item in itemsJson)
    {
        [tileSources addObject:[OATileSource tileSourceWithParameters:item]];
    }
    self.items = tileSources;
}

- (NSDictionary *) getSettingsJson
{
    NSMutableDictionary *json = [NSMutableDictionary new];
    NSMutableArray *jsonArray = [NSMutableArray array];
    if (self.items.count > 0)
    {
        for (OATileSource *item in self.items)
        {
            NSMutableDictionary *jsonObject = [NSMutableDictionary dictionary];
            
            jsonObject[@"sql"] = @(item.isSql);
            if (item.name && item.name.length > 0)
                jsonObject[@"name"] = item.name;
                
            jsonObject[@"minZoom"] = @(item.minZoom);
            jsonObject[@"maxZoom"] = @(item.maxZoom);
            if (item.url)
                jsonObject[@"url"] = item.url;
            
            if (item.randoms && item.randoms.length > 0)
                jsonObject[@"randoms"] = item.randoms;
            jsonObject[@"ellipsoid"] = @(item.ellipsoid);
            jsonObject[@"inverted_y"] = @(item.invertedY);
            jsonObject[@"inversiveZoom"] = @(item.inversiveZoom);
            jsonObject[@"timesupported"] = @(item.timesupported);
            jsonObject[@"expire"] = @(item.expire);
            if (item.ext && item.ext.length > 0)
                jsonObject[@"ext"] = item.ext;
            
            jsonObject[@"tileSize"] = @(item.tileSize);
            jsonObject[@"bitDensity"] = @(item.bitDensity);
            jsonObject[@"avgSize"] = @(item.avgSize);
            if (item.rule && item.rule.length > 0)
                jsonObject[@"rule"] = item.rule;
            
            if (item.isSql && item.referer && item.referer.length > 0)
                jsonObject[@"referer"] = item.referer;
            [jsonArray addObject:jsonObject];
        }
        json[@"items"] = jsonArray;
    }
    return json;
}

@end
