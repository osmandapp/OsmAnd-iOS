//
//  OAAbstractProgress.h
//  OsmAnd Maps
//
//  Created by Paul on 26.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^OAProgressStartTask)(NSString *taskName, int progress);
typedef void(^OAProgressStartWork)(int work);
typedef void(^OAProgressOnProgress)(int progress, int64_t deltaWork);
typedef void(^OAProgressRemainingWork)(double remainingWork);
typedef void(^OAProgressFinishTask)();
typedef void(^OAOnDownloadFinish)(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, NSURL *location);
typedef void(^OAOnDownloadError)(NSError *error);
typedef BOOL(^OAProgressIntermediate)();
typedef BOOL(^OAProgressInterrupted)();
typedef void(^OAProgressSetGeneralProgress)(NSString *genProgress);


@interface OAURLSessionProgress : NSObject <NSURLSessionDelegate>

@property (nonatomic) OAProgressStartTask onStart;
@property (nonatomic) OAProgressStartWork onStartWork;
@property (nonatomic) OAProgressOnProgress onProgress;
@property (nonatomic) OAProgressRemainingWork progressRemaining;
@property (nonatomic) OAProgressFinishTask onFinish;
@property (nonatomic) OAOnDownloadFinish onDownloadFinish;
@property (nonatomic) OAOnDownloadError onDownloadError;
@property (nonatomic) OAProgressIntermediate isIntermediate;
@property (nonatomic) OAProgressInterrupted isInterrupted;
@property (nonatomic) OAProgressSetGeneralProgress setGenProgress;

@end
