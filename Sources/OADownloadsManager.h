//
//  OADownloadsManager.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/14/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OADownloadTask;

@interface OADownloadsManager : NSObject

- (instancetype)init;

//- (NSData*)serializeState;
//- (void*)deserializeStateFrom:(NSData*)state;

@property(readonly, copy) NSArray* downloadTasks;

- (OADownloadTask*)downloadTaskWithRequest:(NSURLRequest*)request
                             andTargetPath:(NSString*)targetPath;

@end
