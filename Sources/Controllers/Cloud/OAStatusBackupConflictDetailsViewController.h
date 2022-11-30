//
//  OAStatusBackupConflictDetailsViewController.h
//  OsmAnd
//
//  Created by Skalii on 27.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#import "OANetworkSettingsHelper.h"

@class OALocalFile, OARemoteFile;

@protocol OAStatusBackupDelegate;

@interface OAStatusBackupConflictDetailsViewController : OASuperViewController

- (instancetype)initWithLocalFile:(OALocalFile *)localeFile
                       remoteFile:(OARemoteFile *)remoteFile
                        operation:(EOABackupSyncOperationType)operation;

@property(nonatomic, weak) id<OAStatusBackupDelegate> delegate;

@end
