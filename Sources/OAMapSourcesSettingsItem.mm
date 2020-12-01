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

#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

@interface OAMapSourcesSettingsItem()

@property (nonatomic) NSArray<NSDictionary *> *items;
@property (nonatomic) NSMutableArray<NSDictionary *> *appliedItems;

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

- (instancetype) initWithItems:(NSArray<NSDictionary *> *)items
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
    NSArray<NSDictionary *> *newItems = [self getNewItems];
    if (newItems.count > 0 || self.duplicateItems.count > 0)
    {
        OsmAndAppInstance app = [OsmAndApp instance];
        self.appliedItems = [NSMutableArray arrayWithArray:newItems];
        if ([self shouldReplace])
        {
            OAMapCreatorHelper *helper = [OAMapCreatorHelper sharedInstance];
            for (NSDictionary *item in self.duplicateItems)
            {
                BOOL isSqlite = [item[@"sql"] boolValue];
                if (isSqlite)
                {
                    NSString *name = [item[@"name"] stringByAppendingPathExtension:@"sqlitedb"];
                    if (name && helper.files[name])
                    {
                        [[OAMapCreatorHelper sharedInstance] removeFile:name];
                        [self.appliedItems addObject:item];
                    }
                }
                else
                {
                    NSString *name = item[@"name"];
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
            for (NSDictionary *localItem in self.duplicateItems)
                [self.appliedItems addObject:[self renameItem:localItem]];
        }
        for (NSDictionary *localItem in self.appliedItems)
        {
            // TODO: migrate localItem to a custom class while extracting items into separate files
            BOOL isSql = [localItem[@"sql"] boolValue];
            
            NSString *name = localItem[@"name"];
            NSString *title = localItem[@"title"];
            if (title.length == 0)
                title = name;

            int minZoom = [localItem[@"minZoom"] intValue];
            int maxZoom = [localItem[@"maxZoom"] intValue];
            NSString *url = localItem[@"url"];
            NSString *randoms = localItem[@"randoms"];
            BOOL ellipsoid = localItem[@"ellipsoid"] ? [localItem[@"ellipsoid"] boolValue] : NO;
            BOOL invertedY = localItem[@"inverted_y"] ? [localItem[@"inverted_y"] boolValue] : NO;
            NSString *referer = localItem[@"referer"];
            BOOL timesupported = localItem[@"timesupported"] ? [localItem[@"timesupported"] boolValue] : NO;
            long expire = [localItem[@"expire"] longValue];
            BOOL inversiveZoom = localItem[@"inversiveZoom"] ? [localItem[@"inversiveZoom"] boolValue] : NO;
            NSString *ext = localItem[@"ext"];
            int tileSize = [localItem[@"tileSize"] intValue];
            int bitDensity = [localItem[@"bitDensity"] intValue];
            int avgSize = [localItem[@"avgSize"] intValue];
            NSString *rule = localItem[@"rule"];
            
            if (isSql)
            {
                NSString *path = [[NSTemporaryDirectory() stringByAppendingPathComponent:localItem[@"name"]] stringByAppendingPathExtension:@"sqlitedb"];
                NSMutableDictionary *params = [NSMutableDictionary new];
                params[@"minzoom"] = [NSString stringWithFormat:@"%d", minZoom];
                params[@"maxzoom"] = [NSString stringWithFormat:@"%d", maxZoom];
                params[@"url"] = url;
                params[@"title"] = title;
                params[@"ellipsoid"] = ellipsoid ? @(1) : @(0);
                params[@"inverted_y"] = invertedY ? @(1) : @(0);
                params[@"expireminutes"] = expire != -1 ? [NSString stringWithFormat:@"%ld", expire / 60000] : @"";
                params[@"timecolumn"] = timesupported ? @"yes" : @"no";
                params[@"rule"] = rule;
                params[@"randoms"] = randoms;
                params[@"referer"] = referer;
                params[@"inversiveZoom"] = inversiveZoom ? @(1) : @(0);
                params[@"ext"] = ext;
                params[@"tileSize"] = [NSString stringWithFormat:@"%d", tileSize];
                params[@"bitDensity"] = [NSString stringWithFormat:@"%d", bitDensity];
                if ([OASQLiteTileSource createNewTileSourceDbAtPath:path parameters:params])
                    [[OAMapCreatorHelper sharedInstance] installFile:path newFileName:nil];
            }
            else
            {
                const auto result = std::make_shared<OsmAnd::IOnlineTileSources::Source>(QString::fromNSString(localItem[@"name"]));

                result->urlToLoad = QString::fromNSString(url);
                result->minZoom = OsmAnd::ZoomLevel(minZoom);
                result->maxZoom = OsmAnd::ZoomLevel(maxZoom);
                result->expirationTimeMillis = expire;
                result->ellipticYTile = ellipsoid;
                //result->priority = _tileSource->priority;
                result->tileSize = tileSize;
                result->ext = QString::fromNSString(ext);
                result->avgSize = avgSize;
                result->bitDensity = bitDensity;
                result->invertedYTile = invertedY;
                result->randoms = QString::fromNSString(randoms);
                result->randomsArray = OsmAnd::OnlineTileSources::parseRandoms(result->randoms);
                result->rule = QString::fromNSString(rule);

                OsmAnd::OnlineTileSources::installTileSource(result, QString::fromNSString(app.cachePath));
                app.resourcesManager->installTilesResource(result);
            }
        }
    }
}

- (NSDictionary *) renameItem:(NSDictionary *)localItem
{
    NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:localItem];
    NSString *name = item[@"name"];
    if (name)
    {
        int number = 0;
        while (true)
        {
            number++;
            
            NSString *newName = [NSString stringWithFormat:@"%@_%d", name, number];
            NSMutableDictionary *newItem = [NSMutableDictionary dictionaryWithDictionary:item];
            newItem[@"name"] = newName;
            if (![self isDuplicate:newItem])
            {
                item = newItem;
                break;
            }
        }
    }
    return item;
}

- (BOOL) isDuplicate:(NSDictionary *)item
{
    NSString *itemName = item[@"name"];
    if (itemName)
        return [_existingItemNames containsObject:itemName];
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

- (OASettingsItemReader *) getReader
{
    return [self getJsonReader];
}

- (void) readItemsFromJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSArray* itemsJson = [json mutableArrayValueForKey:@"items"];
    if (itemsJson.count == 0)
        return;
    self.items = itemsJson;
}

- (void) writeItemsToJson:(id)json error:(NSError * _Nullable __autoreleasing *)error
{
    NSMutableArray *jsonArray = [NSMutableArray array];
    if (self.items.count > 0)
    {
        // TODO: fixme in export!
        for (NSDictionary *localItem in self.items)
        {
            NSMutableDictionary *jsonObject = [NSMutableDictionary dictionary];
            if ([localItem isKindOfClass:OASqliteDbResourceItem.class])
            {
                OASqliteDbResourceItem *item = (OASqliteDbResourceItem *)localItem;
                NSDictionary *params = localItem;
                // TODO: check if this writes true/false while implementing export
                jsonObject[@"sql"] = @(YES);
                jsonObject[@"name"] = item.title;
                jsonObject[@"minZoom"] = params[@"minzoom"];
                jsonObject[@"maxZoom"] = params[@"maxzoom"];
                jsonObject[@"url"] = params[@"url"];
                jsonObject[@"randoms"] = params[@"randoms"];
                jsonObject[@"ellipsoid"] = [@(1) isEqual:params[@"ellipsoid"]] ? @"true" : @"false";
                jsonObject[@"inverted_y"] = [@(1) isEqual:params[@"inverted_y"]] ? @"true" : @"false";
                jsonObject[@"referer"] = params[@"referer"];
                jsonObject[@"timesupported"] = params[@"timecolumn"];
                NSString *expMinStr = params[@"expireminutes"];
                jsonObject[@"expire"] = expMinStr ? [NSString stringWithFormat:@"%lld", expMinStr.longLongValue * 60000] : @"0";
                jsonObject[@"inversiveZoom"] = [@(1) isEqual:params[@"inversiveZoom"]] ? @"true" : @"false";
                jsonObject[@"ext"] = params[@"ext"];
                jsonObject[@"tileSize"] = params[@"tileSize"];
                jsonObject[@"bitDensity"] = params[@"bitDensity"];
                jsonObject[@"rule"] = params[@"rule"];
            }
            else if ([localItem isKindOfClass:OAOnlineTilesResourceItem.class])
            {
//                OAOnlineTilesResourceItem *item = (OAOnlineTilesResourceItem *)localItem;
//                const auto& source = _newSources[QString::fromNSString(item.title)];
//                if (source)
//                {
//                    jsonObject[@"sql"] = @(NO);
//                    jsonObject[@"name"] = item.title;
//                    jsonObject[@"minZoom"] = [NSString stringWithFormat:@"%d", source->minZoom];
//                    jsonObject[@"maxZoom"] = [NSString stringWithFormat:@"%d", source->maxZoom];
//                    jsonObject[@"url"] = source->urlToLoad.toNSString();
//                    jsonObject[@"randoms"] = source->randoms.toNSString();
//                    jsonObject[@"ellipsoid"] = source->ellipticYTile ? @"true" : @"false";
//                    jsonObject[@"inverted_y"] = source->invertedYTile ? @"true" : @"false";
//                    jsonObject[@"timesupported"] = source->expirationTimeMillis != -1 ? @"true" : @"false";
//                    jsonObject[@"expire"] = [NSString stringWithFormat:@"%ld", source->expirationTimeMillis];
//                    jsonObject[@"ext"] = source->ext.toNSString();
//                    jsonObject[@"tileSize"] = [NSString stringWithFormat:@"%d", source->tileSize];
//                    jsonObject[@"bitDensity"] = [NSString stringWithFormat:@"%d", source->bitDensity];
//                    jsonObject[@"avgSize"] = [NSString stringWithFormat:@"%d", source->avgSize];
//                    jsonObject[@"rule"] = source->rule.toNSString();
//                }
            }
            [jsonArray addObject:jsonObject];
        }
        json[@"items"] = jsonArray;
    }
}

@end
