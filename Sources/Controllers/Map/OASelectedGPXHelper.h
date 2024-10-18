//
//  OASelectedGPXHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 24/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <OsmAndCore.h>

NS_ASSUME_NONNULL_BEGIN

@class OASGpxFile, OASWptPt;

@interface OASelectedGPXHelper : NSObject

+ (OASelectedGPXHelper *)instance;

- (BOOL)buildGpxList;
- (void)markTrackForReload:(NSString *)filePath;
- (nullable OASGpxFile *)getSelectedGpx:(OASWptPt *)gpxWpt;
- (BOOL)isShowingAnyGpxFiles;
- (void)clearAllGpxFilesToShow:(BOOL) backupSelection;
- (void)restoreSelectedGpxFiles;
- (nullable NSString *) getSelectedGPXFilePath:(NSString *)fileName;

+ (void)renameVisibleTrack:(NSString *)oldPath newPath:(NSString *) newPath;

- (NSDictionary<NSString *, OASGpxFile *> *)activeGpx;
- (void)removeGpxFileWith:(NSString *)path;
- (nullable OASGpxFile *)getGpxFileFor:(NSString *)path;
- (BOOL)containsGpxFileWith:(NSString *)path;
- (void)addGpxFile:(OASGpxFile *)file for:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
