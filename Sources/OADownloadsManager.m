//
//  OADownloadsManager.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/14/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADownloadsManager.h"

// For iOS [6.0, 7.0)
#import <AFDownloadRequestOperation.h>

// For iOS 7.0+
#import <AFURLSessionManager.h>

@implementation OADownloadsManager
{
    AFURLSessionManager* _sessionManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self ctor];
    }
    return self;
}

- (void)dealloc
{
    [self dtor];
}

- (void)ctor
{
    // Check what backend should be used
    const BOOL isSupported_NSURLSession =
        (NSClassFromString(@"NSURLSession") != nil) &&
        ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending);
    if (isSupported_NSURLSession)
    {
        _sessionManager = [[AFURLSessionManager alloc] init];
    }
    else
    {
        _sessionManager = nil;
    }
}

- (void)dtor
{

}

@synthesize downloadTasks = _downloadTasks;

- (OADownloadTask*)downloadTaskWithRequest:(NSURLRequest*)request
                             andTargetPath:(NSString*)targetPath
{
    /*if (_sessionManager)
    {
        NSURLSessionDownloadTask* backendTask = [_sessionManager downloadTaskWithRequest:request
    progress:<#(NSProgress *__autoreleasing *)#> destination:<#^NSURL *(NSURL *targetPath, NSURLResponse *response)destination#> completionHandler:<#^(NSURLResponse *response, NSURL *filePath, NSError *error)completionHandler#>]
    }
    else
    {
        
    }*/
}

@end
