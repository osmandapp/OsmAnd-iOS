//
//  OAMapTileDownloader.h
//  OsmAnd
//
//  Created by Paul on 26.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OASQLiteTileSource;

@protocol OATileDownloadDelegate <NSObject>

- (void) onTileDownloaded;

@end

@interface OAMapTileDownloader : NSObject

@property (nonatomic, weak) id<OATileDownloadDelegate> delegate;

+ (OAMapTileDownloader *) sharedInstance;

- (void) downloadTile:(NSURL *) url toPath:(NSString *) path;
- (void) downloadTile:(NSURL *) url x:(int)x y:(int)y zoom:(int)zoom tileSource:(OASQLiteTileSource *) tileSource;

@end

NS_ASSUME_NONNULL_END
