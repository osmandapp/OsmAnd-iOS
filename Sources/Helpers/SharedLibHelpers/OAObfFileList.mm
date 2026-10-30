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

+ (NSArray<NSString *> *)sortedForSearch:(NSArray<NSString *> *)resourceIds
{
    return [resourceIds sortedArrayUsingComparator:^NSComparisonResult(NSString *first, NSString *second) {
        first = [[first stringByReplacingOccurrencesOfString:@".live.obf" withString:@""]
                        stringByReplacingOccurrencesOfString:@".obf" withString:@""];
        second = [[second stringByReplacingOccurrencesOfString:@".live.obf" withString:@""]
                          stringByReplacingOccurrencesOfString:@".obf" withString:@""];

        NSRange rangeFirst  = [first rangeOfString:@"([0-9]+_){2}[0-9]+" options:NSRegularExpressionSearch];
        NSRange rangeSecond = [second rangeOfString:@"([0-9]+_){2}[0-9]+" options:NSRegularExpressionSearch];

        if (rangeFirst.location != NSNotFound && rangeSecond.location == NSNotFound)
        {
            if (rangeFirst.location == 0)
                return [first compare:second];

            NSString *base = [first substringToIndex:rangeFirst.location - 1];
            return [base isEqualToString:second] ? NSOrderedAscending : [second compare:base];
        }
        else if (rangeFirst.location == NSNotFound && rangeSecond.location != NSNotFound)
        {
            if (rangeSecond.location == 0)
                return [first compare:second];
            
            NSString *base = [second substringToIndex:rangeSecond.location - 1];
            return [base isEqualToString:first] ? NSOrderedDescending : [base compare:first];
        }

        return [first compare:second];
    }];
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
