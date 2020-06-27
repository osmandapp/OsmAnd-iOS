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

typedef NS_ENUM (NSInteger, EOATileRequestType)
{
    EOATileRequestTypeFile = 0,
    EOATileRequestTypeSqlite
};

@interface OATileDownloadRequest : NSObject

@property (nonatomic) EOATileRequestType type;
@property (nonatomic) NSURL *url;
@property (nonatomic) NSString *destPath;
@property (nonatomic) int x;
@property (nonatomic) int y;
@property (nonatomic) int zoom;
@property (nonatomic) OASQLiteTileSource *tileSource;

@end

@protocol OATileDownloadDelegate <NSObject>

- (void) onTileDownloaded;

@end

@interface OAMapTileDownloader : NSObject

@property (nonatomic, weak) id<OATileDownloadDelegate> delegate;

+ (OAMapTileDownloader *) sharedInstance;

- (void) enqueTileDownload:(OATileDownloadRequest *) request;
- (void) cancellAllRequests;

@end

NS_ASSUME_NONNULL_END
