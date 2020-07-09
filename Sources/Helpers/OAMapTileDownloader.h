//
//  OAMapTileDownloader.h
//  OsmAnd
//
//  Created by Paul on 26.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAResourceItem;

typedef NS_ENUM (NSInteger, EOATileRequestType)
{
    EOATileRequestTypeUndefined = 0,
    EOATileRequestTypeFile,
    EOATileRequestTypeSqlite
};

@protocol OATileDownloadDelegate <NSObject>

- (void) onTileDownloaded:(BOOL)updateUI;

@end

@interface OAMapTileDownloader : NSObject

@property (nonatomic, weak) id<OATileDownloadDelegate> delegate;

- (instancetype) initWithItem:(OAResourceItem *)item minZoom:(int)minZoom maxZoom:(int)maxZoom;

- (void) startDownload;
- (void) cancellAllRequests;

@end

NS_ASSUME_NONNULL_END
