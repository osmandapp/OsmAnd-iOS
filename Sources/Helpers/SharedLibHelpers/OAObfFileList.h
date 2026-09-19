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
 The installed file with this name, by full path, or nil when it is not installed.

 The saved articles keep the bare file name, the obf readers are keyed by path, so the two are
 matched up here.
 */
+ (nullable NSString *)pathForFileName:(NSString *)fileName;

@end

NS_ASSUME_NONNULL_END
