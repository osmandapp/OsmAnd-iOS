//
//  OAObfFileList.mm
//  OsmAnd
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAObfFileList.h"
#import "OsmAndApp.h"

#import "OsmAndSharedWrapper.h"

#include <OsmAndCore/ResourcesManager.h>

@implementation OAObfFileList

+ (NSArray<NSString *> *)travelFilePaths
{
    return [self pathsIncludingMapRegions:NO];
}

+ (NSArray<NSString *> *)travelAndMapFilePaths
{
    return [self pathsIncludingMapRegions:YES];
}

+ (NSArray<NSString *> *)searchResourceIdsIncludingTravel:(BOOL)includeTravel
{
    return [self sortedForSearch:[self searchResourceIdsIncludingTravel:includeTravel paths:nil]];
}

+ (NSArray<NSString *> *)searchFilePathsIncludingTravel:(BOOL)includeTravel
{
    NSMutableDictionary<NSString *, NSString *> *pathsByResourceId = [NSMutableDictionary dictionary];
    NSArray<NSString *> *resourceIds = [self searchResourceIdsIncludingTravel:includeTravel paths:pathsByResourceId];
    NSMutableArray<NSString *> *paths = [NSMutableArray array];
    for (NSString *resourceId in [self sortedForSearch:resourceIds])
    {
        NSString *path = pathsByResourceId[resourceId];
        if (path.length > 0 && [NSFileManager.defaultManager fileExistsAtPath:path])
            [paths addObject:path];
    }
    return paths;
}

// in the order of the installed resources, which the sort starts from
+ (NSArray<NSString *> *)searchResourceIdsIncludingTravel:(BOOL)includeTravel
                                                    paths:(nullable NSMutableDictionary<NSString *, NSString *> *)pathsByResourceId
{
    OsmAndAppInstance app = OsmAndApp.instance;
    if (!app.resourcesManager)
        return @[];

    NSMutableArray<NSString *> *resourceIds = [NSMutableArray array];
    for (const auto& resource : app.resourcesManager->getLocalResources())
    {
        const auto type = resource->type;
        if (type == OsmAnd::ResourcesManager::ResourceType::MapRegion
            || type == OsmAnd::ResourcesManager::ResourceType::WikiMapRegion
            || type == OsmAnd::ResourcesManager::ResourceType::LiveUpdateRegion
            || (includeTravel && type == OsmAnd::ResourcesManager::ResourceType::Travel))
        {
            NSString *resourceId = resource->id.toNSString();
            [resourceIds addObject:resourceId];
            pathsByResourceId[resourceId] = resource->localPath.toNSString();
        }
    }
    return resourceIds;
}

// The key a file is ordered by: its region, 0 for a live update of it and 1 for anything else, and the
// date of the update. "germany_berlin_europe_25_10_28.live.obf" is (germany_berlin_europe, 0, 25_10_28).
static NSArray *orderKey(NSString *resourceId)
{
    NSString *name = [[resourceId stringByReplacingOccurrencesOfString:@".live.obf" withString:@""]
                                  stringByReplacingOccurrencesOfString:@".obf" withString:@""];
    NSRange date = [name rangeOfString:@"([0-9]+_){2}[0-9]+" options:NSRegularExpressionSearch];
    if (date.location != NSNotFound && date.location > 0)
        return @[[name substringToIndex:date.location - 1], @0, [name substringFromIndex:date.location]];
    return @[name, @1, @""];
}

+ (NSArray<NSString *> *)sortedForSearch:(NSArray<NSString *> *)resourceIds
{
    // one key per id, so that the order is the same whatever order the ids come in: the region, its
    // live updates before it, the newest of them first. The first file to give a poi claims its id,
    // so an update that removed the poi has to be read before the region and the older updates
    NSMutableDictionary<NSString *, NSArray *> *keys = [NSMutableDictionary dictionary];
    for (NSString *resourceId in resourceIds)
        keys[resourceId] = orderKey(resourceId);

    return [resourceIds sortedArrayUsingComparator:^NSComparisonResult(NSString *first, NSString *second) {
        NSArray *a = keys[first];
        NSArray *b = keys[second];
        NSComparisonResult result = [a[0] compare:b[0]];
        if (result == NSOrderedSame)
            result = [a[1] compare:b[1]];
        if (result == NSOrderedSame)
            result = [b[2] compare:a[2]];
        return result == NSOrderedSame ? [first compare:second] : result;
    }];
}

+ (NSArray<NSString *> *)sortedForSearch:(NSArray<NSString *> *)resourceIds distance:(double (^)(NSString *resourceId))distance
{
    NSArray<NSString *> *sorted = [self sortedForSearch:resourceIds];
    NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *updatesByRegion = [NSMutableDictionary dictionary];
    NSMutableArray<NSString *> *files = [NSMutableArray array];
    NSMutableDictionary<NSString *, NSNumber *> *distances = [NSMutableDictionary dictionary];
    for (NSString *resourceId in sorted)
    {
        NSArray *key = orderKey(resourceId);
        if ([key[1] isEqual:@0])
        {
            NSMutableArray<NSString *> *updates = updatesByRegion[key[0]] ?: (updatesByRegion[key[0]] = [NSMutableArray array]);
            [updates addObject:resourceId];
        }
        else
        {
            [files addObject:resourceId];
            distances[resourceId] = @(distance(resourceId));
        }
    }
    // stable: files as far away keep the order by name
    [files sortWithOptions:NSSortStable usingComparator:^NSComparisonResult(NSString *first, NSString *second) {
        return [distances[first] compare:distances[second]];
    }];

    NSMutableArray<NSString *> *result = [NSMutableArray arrayWithCapacity:sorted.count];
    for (NSString *file in files)
    {
        NSString *region = orderKey(file)[0];
        NSArray<NSString *> *updates = updatesByRegion[region];
        if (updates)
        {
            [result addObjectsFromArray:updates];
            [updatesByRegion removeObjectForKey:region];
        }
        [result addObject:file];
    }
    // updates of a region that is not among the files are still read, after the rest
    for (NSString *resourceId in sorted)
    {
        if (updatesByRegion[orderKey(resourceId)[0]] && [orderKey(resourceId)[1] isEqual:@0])
            [result addObject:resourceId];
    }
    return result;
}

+ (NSString *)pathForFileName:(NSString *)fileName
{
    if (fileName.length == 0)
        return nil;

    for (NSString *path in [self travelAndMapFilePaths])
    {
        if ([path.lastPathComponent isEqualToString:fileName])
            return path;
    }
    return nil;
}

+ (NSArray<NSString *> *)pathsIncludingMapRegions:(BOOL)includeMapRegions
{
    OsmAndAppInstance app = OsmAndApp.instance;
    if (!app.resourcesManager)
        return @[];

    NSMutableArray<NSString *> *paths = [NSMutableArray array];
    for (const auto& resource : app.resourcesManager->getLocalResources())
    {
        const auto type = resource->type;
        if (type != OsmAnd::ResourcesManager::ResourceType::Travel
            && !(includeMapRegions && type == OsmAnd::ResourcesManager::ResourceType::MapRegion))
            continue;

        NSString *path = resource->localPath.toNSString();
        if (path.length > 0 && [NSFileManager.defaultManager fileExistsAtPath:path])
            [paths addObject:path];
    }
    return [self sortedByVersion:paths];
}

// The order android's AmenitySearcher.getAmenityRepositories builds: newest build of a region
// first - which is what KAlgorithms.compareFileVersions does - and the world files after the rest,
// because a world file covers everything and would otherwise answer before the region that has the
// data.
+ (NSArray<NSString *> *)sortedByVersion:(NSArray<NSString *> *)paths
{
    OASKAlgorithms *algorithms = OASKAlgorithms.shared;
    NSArray<NSString *> *sorted = [paths sortedArrayUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        int32_t result = [algorithms compareFileVersionsF1:a.lastPathComponent f2:b.lastPathComponent];
        if (result < 0)
            return NSOrderedAscending;
        return result > 0 ? NSOrderedDescending : NSOrderedSame;
    }];

    NSMutableArray<NSString *> *regions = [NSMutableArray array];
    NSMutableArray<NSString *> *worldMaps = [NSMutableArray array];
    NSMutableArray<NSString *> *travelMaps = [NSMutableArray array];
    for (NSString *path in sorted)
    {
        NSString *name = path.lastPathComponent.lowercaseString;
        if ([name hasSuffix:@".travel.obf"])
            [travelMaps addObject:path];
        else if ([name hasPrefix:@"world_"] || [name containsString:@"basemap"])
            [worldMaps addObject:path];
        else
            [regions addObject:path];
    }

    NSMutableArray<NSString *> *result = [NSMutableArray arrayWithArray:regions];
    [result addObjectsFromArray:worldMaps];
    [result addObjectsFromArray:travelMaps];
    return result;
}

@end
