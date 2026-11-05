//
//  OAFreeRegionHelper.h
//  OsmAnd
//
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAWorldRegion;

NS_ASSUME_NONNULL_BEGIN

/**
 * Free version: all maps of one region are free, instead of 7 map downloads.
 *
 * The free region is a country - the region right under a continent, so Germany with all its Länder
 * is one region. In the big federations it is a first-level region (a US state), otherwise one free
 * region would be tens of GB.
 *
 * Only new downloads of standard maps are counted; updates of installed maps are always free. Maps in
 * an area bought with the old region in-apps (Europe, Asia... All World) are never counted and never
 * deleted, as are the world maps and the maps of plugins.
 */
@interface OAFreeRegionHelper : NSObject

+ (BOOL) isFreeVersion;
+ (nullable OAWorldRegion *) getFreeRegion;
+ (void) setFreeRegion:(OAWorldRegion *)region;

/** The free-version region a map of this region counts against, nil when the map is free for everyone. */
+ (nullable OAWorldRegion *) getFreeRegionOf:(nullable OAWorldRegion *)region;

/** YES when a new map of the region may be downloaded without asking. */
+ (BOOL) isDownloadFree:(nullable OAWorldRegion *)region;

/** The first-start screen never asks: the region of its map becomes the free region. */
+ (void) chooseFreeRegionOf:(nullable OAWorldRegion *)region;

/** Called when a standard map is installed: the first map chooses the free region. */
+ (void) onMapInstalled:(nullable OAWorldRegion *)region;

/** Installed standard maps by free-version region id. */
+ (NSDictionary<NSString *, NSArray<NSString *> *> *) collectLocalMaps;

+ (BOOL) shouldShowUpdateWarning;
+ (void) setUpdateWarningShown;

@end

@interface OAFreeRegionDialogs : NSObject

/** A map of another region: replace the free region (the server decides) or get Maps+. */
+ (void) showOtherRegion:(OAWorldRegion *)region onReplaced:(dispatch_block_t)onReplaced;

/** Once after the update of the app, when there are maps older than the new search. */
+ (void) showUpdateMapsWarningIfNeeded;

@end

NS_ASSUME_NONNULL_END
