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
