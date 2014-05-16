//
//  OADownloadsManager_Private.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/16/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADownloadsManager.h"

@interface OADownloadsManager (Private)

- (void)removeTask:(id<OADownloadTask>)task;

@end
