//
//  OABackupInfoGenerationTask.h
//  OsmAnd Maps
//
//  Created by Paul on 24.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OABackupInfo, OAPrepareBackupResult;

@interface OAGenerateBackupInfoTask : NSOperation

- (instancetype) initWithBackup:(OAPrepareBackupResult *)backup
                     onComplete:(void(^)(OABackupInfo *backupInfo, NSString *error))onComplete;

@end
