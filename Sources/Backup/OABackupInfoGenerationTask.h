//
//  OABackupInfoGenerationTask.h
//  OsmAnd Maps
//
//  Created by Paul on 24.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OALocalFile, OARemoteFile, OABackupInfo;

@interface OABackupInfoGenerationTask : NSOperation

- (instancetype) initWithLocalFiles:(NSDictionary<NSString *, OALocalFile *> *)localFiles
                  uniqueRemoteFiles:(NSDictionary<NSString *, OARemoteFile *> *)uniqueRemoteFiles
                 deletedRemoteFiles:(NSDictionary<NSString *, OARemoteFile *> *)deletedRemoteFiles
                         onComplete:(void(^)(OABackupInfo *backupInfo, NSString *error))onComplete;

@end
