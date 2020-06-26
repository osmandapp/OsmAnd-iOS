//
//  OAMapTileDownloader.m
//  OsmAnd
//
//  Created by Paul on 26.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMapTileDownloader.h"
#import "OASQLiteTileSource.h"

@implementation OAMapTileDownloader
{
    NSURLSession *_urlSession;
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
        backgroundSessionConfiguration.timeoutIntervalForRequest = 3000.0;
        backgroundSessionConfiguration.timeoutIntervalForResource = 6000.0;
        backgroundSessionConfiguration.HTTPMaximumConnectionsPerHost = 50;
        _urlSession = [NSURLSession sessionWithConfiguration:backgroundSessionConfiguration
                                                               delegate:nil
                                                          delegateQueue:[NSOperationQueue mainQueue]];
    }
    return self;
}

- (void) downloadTile:(NSURL *) url toPath:(NSString *) path
{
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
    }];
    [task resume];
}

- (void) downloadTile:(NSURL *) url x:(int)x y:(int)y zoom:(int)zoom tileSource:(OASQLiteTileSource *) tileSource
{
    NSURLSessionDownloadTask *task = [_urlSession downloadTaskWithURL:url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSData *data = [NSData dataWithContentsOfFile:location.path];
        if (data)
        {
            [tileSource insertImage:x y:y zoom:zoom data:data];
            [NSFileManager.defaultManager removeItemAtURL:url error:nil];
            if (_delegate)
                [_delegate onTileDownloaded];
        }
    }];
    [task resume];
}

@end
