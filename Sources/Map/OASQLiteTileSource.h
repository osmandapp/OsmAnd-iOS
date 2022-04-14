//
//  OASQLiteTileSource.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <OsmAndCore/QtExtensions.h>
#include <QList>
#include <QString>

@class QuadRect;

@interface OASQLiteTileSource : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *tileFormat;
@property (nonatomic, readonly) int tileSize;
@property (nonatomic, readonly) NSString *referer;
@property (nonatomic, readonly) NSString *urlTemplate;
@property (nonatomic, readonly) NSString *randoms;
@property (nonatomic, readonly) QList<QString> randomsArray;
@property (nonatomic, readonly) NSString *rule;

+ (BOOL) createNewTileSourceDbAtPath:(NSString *)path parameters:(NSDictionary *)parameters;
+ (BOOL) isOnlineTileSource:(NSString *)filePath;
+ (NSString *) getTitleOf:(NSString *)filePath;

- (instancetype) initWithFilePath:(NSString *)filePath;

- (int) bitDensity;
- (int) maximumZoomSupported;
- (int) minimumZoomSupported;

- (BOOL) exists:(int)x y:(int)y zoom:(int)zoom;
- (NSData* ) getBytes:(int)x y:(int)y zoom:(int)zoom timeHolder:(NSNumber**)timeHolder;
- (NSData *) getBytes:(int)x y:(int)y zoom:(int)zoom;
- (UIImage *) getImage:(int)x y:(int)y zoom:(int)zoom timeHolder:(NSNumber**)timeHolder;
- (void) deleteImage:(int)x y:(int)y zoom:(int)zoom;
- (void) deleteCache:(dispatch_block_t)block;
- (void) deleteImages:(OsmAnd::AreaI)area zoom:(int)zoom;
- (void) insertImage:(int)x y:(int)y zoom:(int)zoom filePath:(NSString *)filePath;
- (void) insertImage:(int)x y:(int)y zoom:(int)zoom data:(NSData *)data;
- (NSString *) getUrlToLoad:(int) x y:(int) y zoom:(int) zoom;
- (int) getFileZoom:(int)zoom;
- (BOOL) isEllipticYTile;
- (BOOL) isInvertedYTile;
- (BOOL) isInversiveZoom;
- (long) getExpirationTimeMinutes;
- (long) getExpirationTimeMillis;
- (BOOL) isTimeSupported;
- (BOOL) expired:(NSNumber *)time;
- (int) getTileSize;
- (BOOL) supportsTileDownload;
- (void) updateInfo:(long)expireTimeMillis url:(NSString *)url minZoom:(int)minZoom maxZoom:(int)maxZoom isEllipticYTile:(BOOL)isEllipticYTile title:(NSString *)title;
- (NSString *) getFilePath;

- (void) setTileSize:(int)tileSize;

@end
