//
//  OADownloadTask_AFDownloadRequestOperation.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/17/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AFDownloadRequestOperation.h>

#import "OADownloadTask.h"

@class OADownloadsManager;

@interface OADownloadTask_AFDownloadRequestOperation : NSObject <OADownloadTask>

- (instancetype)initWithOwner:(OADownloadsManager*)owner
                   andRequest:(NSURLRequest*)request
                andTargetPath:(NSString*)targetPath
                       andKey:(NSString*)key
                      andName:(NSString*)name;

@property(readonly) AFDownloadRequestOperation* operation;

@end
