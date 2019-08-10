//
//  OAOverUnderlayBaseAction.m
//  OsmAnd
//
//  Created by Paul on 8/10/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOverUnderlayBaseAction.h"
#import "OAMapSource.h"
#import "OsmAndApp.h"

#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/UnresolvedMapStyle.h>
#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>
#include <OsmAndCore/ResourcesManager.h>

@implementation OAOverUnderlayBaseAction

- (void)commonInit
{
    OsmAndAppInstance app = [OsmAndApp instance];
    NSMutableArray<OAMapSource *> *arr = [NSMutableArray new];
    QList< std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > onlineTileSourcesResources;
    const auto localResources = app.resourcesManager->getLocalResources();
    for(const auto& localResource : localResources)
        if (localResource->type == OsmAnd::ResourcesManager::ResourceType::OnlineTileSources)
            onlineTileSourcesResources.push_back(localResource);

    for(const auto& resource : onlineTileSourcesResources)
    {
        const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(resource->metadata)->sources;
        NSString* resourceId = resource->id.toNSString();
        for(const auto& onlineTileSource : onlineTileSources->getCollection())
        {
            NSString *caption = onlineTileSource->name.toNSString();
            NSString *name = onlineTileSource->title.toNSString();
            
            [arr addObject:[[OAMapSource alloc] initWithResource:resourceId
                                                      andVariant:caption name:name]];
        }
    }
    _onlineMapSources = [NSArray arrayWithArray:arr];
}

- (NSString *)getTitle:(NSArray *)filters
{
    if (filters.count == 0)
        return @"";
    
    return filters.count > 1
    ? [NSString stringWithFormat:@"%@ +%ld", filters[0][1], filters.count - 1]
    : filters[0][1];
}

- (void)saveListToParams:(NSArray *)list
{
    NSMutableDictionary<NSString *, NSString *> *tmp = [NSMutableDictionary dictionaryWithDictionary:self.getParams];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:list options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [tmp setObject:jsonString forKey:self.getListKey];
    [self setParams:[NSDictionary dictionaryWithDictionary:tmp]];
}

- (NSArray *)loadListFromParams
{
    NSString *jsonStr = self.getParams[self.getListKey];
    if (!jsonStr || jsonStr.length == 0)
        return [NSArray new];
    return [NSJSONSerialization JSONObjectWithData:[jsonStr dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
}

- (NSString *)getItemName:(NSArray<NSString *> *)item
{
    return item.lastObject;
}

@end
