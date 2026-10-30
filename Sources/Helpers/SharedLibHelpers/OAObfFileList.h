//
//  OAObfFileList.h
//  OsmAnd
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The installed obf files the shared travel code reads, by full path.

 Both lists come back in the order android consults them: the newest build of a region first, world
 files after the ordinary ones. That order decides which file answers first when two hold the same
 route, so it has to be the same on both platforms.
 */
@interface OAObfFileList : NSObject

/** Wikivoyage: the installed `.travel.obf` files. */
+ (NSArray<NSString *> *)travelFilePaths;

/**
 Everything that may hold gpx tracks: travel files and ordinary map regions. OSM routes and gpx
 collections live in ordinary map files, not only in travel ones.
 */
+ (NSArray<NSString *> *)travelAndMapFilePaths;

/**
 What the search reads, by resource id: map regions, their wikipedia and live update files, and travel
 files if asked for. In the order of `sortedForSearch:`.
 */
+ (NSArray<NSString *> *)searchResourceIdsIncludingTravel:(BOOL)includeTravel;

/** The same files as `searchResourceIdsIncludingTravel:`, by full path, those that are on disk. */
+ (NSArray<NSString *> *)searchFilePathsIncludingTravel:(BOOL)includeTravel;

/**
 Resource ids of obf files in the order the search reads them: regions by name, each after its live
 updates, the newest update first. The same order whatever order the ids come in.
 */
+ (NSArray<NSString *> *)sortedForSearch:(NSArray<NSString *> *)resourceIds;

/**
 The same files nearest first, for a search around a point: by `distance`, each region still right after
 its live updates, the newest first. Updates whose region is not among the files come last.
 */
+ (NSArray<NSString *> *)sortedForSearch:(NSArray<NSString *> *)resourceIds distance:(double (^)(NSString *resourceId))distance;

/**
 The installed file with this name, by full path, or nil when it is not installed.

 The saved articles keep the bare file name, the obf readers are keyed by path, so the two are
 matched up here.
 */
+ (nullable NSString *)pathForFileName:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
