//
//  OAMapTileDownloader.m
//  OsmAnd
//
//  Created by Paul on 26.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMapTileDownloader.h"
#import "OASQLiteTileSource.h"

#define kMaxRequests 50

@implementation OATileDownloadRequest

@end

@implementation OAMapTileDownloader
{
    NSURLSession *_urlSession;
    
    NSMutableSet<NSString *> *_pendingToDownload;
    NSMutableSet<NSString *> *_currentlyDownloading;
    NSMutableArray<OATileDownloadRequest *> *_requests;
    NSLock *_lock;
}

+ (OAMapTileDownloader *)sharedInstance
{
    static OAMapTileDownloader *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OAMapTileDownloader alloc] init];
    });
    return _sharedInstance;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *backgroundSessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        backgroundSessionConfiguration.timeoutIntervalForRequest = 300.0;
        backgroundSessionConfiguration.timeoutIntervalForResource = 600.0;
        backgroundSessionConfiguration.HTTPMaximumConnectionsPerHost = 70;
        _urlSession = [NSURLSession sessionWithConfiguration:backgroundSessionConfiguration
                                                               delegate:nil
                                                          delegateQueue:[NSOperationQueue mainQueue]];
        _lock = [[NSLock alloc] init];
        _pendingToDownload = [NSMutableSet new];
        _currentlyDownloading = [NSMutableSet new];
        _requests = [NSMutableArray new];
    }
    return self;
}

- (void) addDownloadItem:(NSString *)item toCollection:(NSMutableSet<NSString *> *)collection
{
    [_lock lock];
    [collection addObject:item];
    [_lock unlock];
}

- (void) removeDownloadItem:(NSString *)item fromCollection:(NSMutableSet<NSString *> *)collection
{
    [_lock lock];
    [collection removeObject:item];
    [_lock unlock];
}

- (void) downloadTile:(NSURL *) url toPath:(NSString *) path
{
    [self removeDownloadItem:url.absoluteString fromCollection:_pendingToDownload];
    [self addDownloadItem:url.absoluteString toCollection:_currentlyDownloading];
    NSURLSessionDownloadTask *task = [_urlSession downloadTaskWithURL:url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSError *err = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *dir = [path stringByDeletingLastPathComponent];
        [fileManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSURL *targetURLDir = [NSURL fileURLWithPath:path];
        
        if (targetURLDir && location)
        {
            [fileManager moveItemAtURL:location
            toURL:targetURLDir
            error:&err];
            if (_delegate)
            {
                [_delegate onTileDownloaded];
            }
        }
        [self removeDownloadItem:url.absoluteString fromCollection:_currentlyDownloading];
        [self startNextDownload];
    }];
    [task resume];
}

- (void) downloadTile:(NSURL *) url x:(int)x y:(int)y zoom:(int)zoom tileSource:(OASQLiteTileSource *) tileSource
{
    [self removeDownloadItem:url.absoluteString fromCollection:_pendingToDownload];
    [self addDownloadItem:url.absoluteString toCollection:_currentlyDownloading];
    NSURLSessionDownloadTask *task = [_urlSession downloadTaskWithURL:url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSData *data = [NSData dataWithContentsOfFile:location.path];
        if (data)
        {
            [tileSource insertImage:x y:y zoom:zoom data:data];
            [NSFileManager.defaultManager removeItemAtURL:url error:nil];
            if (_delegate)
                [_delegate onTileDownloaded];
        }
        [self removeDownloadItem:url.absoluteString fromCollection:_currentlyDownloading];
        [self startNextDownload];
    }];
    [task resume];
}

- (void) cancellAllRequests
{
    [_requests removeAllObjects];
    [_pendingToDownload removeAllObjects];
    [_urlSession invalidateAndCancel];
    [_currentlyDownloading removeAllObjects];
}

- (void) enqueTileDownload:(OATileDownloadRequest *) request
{
    NSString *key = request.url.absoluteString;
    if (![_pendingToDownload containsObject:key] && ![_currentlyDownloading containsObject:key])
    {
        [_lock lock];
        [_requests addObject:request];
        [_pendingToDownload addObject:request.url.absoluteString];
        [_lock unlock];
        [self startNextDownload];
    }
}

- (void) startTileDownload:(OATileDownloadRequest *)request
{
    if (request.type == EOATileRequestTypeFile)
    {
        [self downloadTile:request.url toPath:request.destPath];
    }
    else if (request.type == EOATileRequestTypeSqlite)
    {
        [self downloadTile:request.url x:request.x y:request.y zoom:request.zoom tileSource:request.tileSource];
    }
}

- (void) startNextDownload
{
    if (_currentlyDownloading.count < kMaxRequests)
    {
        if (_requests.count > 0)
        {
            [_lock lock];
            [self startTileDownload:_requests.lastObject];
            [_requests removeLastObject];
            [_lock unlock];
        }
    }
}

@end
