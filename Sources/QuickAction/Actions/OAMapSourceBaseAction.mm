//
//  OAOverUnderlayBaseAction.m
//  OsmAnd
//
//  Created by Paul on 8/10/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapSourceBaseAction.h"
#import "OAMapSource.h"
#import "OsmAndApp.h"
#import "OAMapCreatorHelper.h"

#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/UnresolvedMapStyle.h>
#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>
#include <OsmAndCore/ResourcesManager.h>

@implementation OAMapSourceBaseAction

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
    
    NSMutableArray *sqlitedbArr = [NSMutableArray array];
    for (NSString *fileName in [OAMapCreatorHelper sharedInstance].files.allKeys)
    {
        [sqlitedbArr addObject:[[OAMapSource alloc] initWithResource:fileName andVariant:@"" name:[fileName stringByReplacingOccurrencesOfString:@".sqlitedb" withString:@""]]];
    }
    
    [sqlitedbArr sortUsingComparator:^NSComparisonResult(OAMapSource *obj1, OAMapSource *obj2) {
        return [obj1.resourceId caseInsensitiveCompare:obj2.resourceId];
    }];
    
    [arr addObjectsFromArray:sqlitedbArr];
    _onlineMapSources = [NSArray arrayWithArray:arr];
}

- (NSString *)getTitle:(NSArray *)filters
{
    if (filters.count == 0)
        return @"";
    
    return filters.count > 1
    ? [NSString stringWithFormat:@"%@ +%ld", filters[0], filters.count - 1]
    : filters[0];
}

- (NSString *)getItemName:(NSArray<NSString *> *)item
{
    return item.lastObject;
}

- (NSArray *)getOnlineMapSources
{
    return _onlineMapSources;
}

- (NSString *)getActionText
{
    return OALocalizedString(@"quick_action_source_switch_descr");
}

@end
