//
//  OAStatusBackupConflictDetailsViewController.h
//  OsmAnd
//
//  Created by Skalii on 27.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABaseBottomSheetViewController.h"

@class OALocalFile, OARemoteFile;

@protocol OAStatusBackupTableDelegate;

@interface OAStatusBackupConflictDetailsViewController : OABaseBottomSheetViewController

- (instancetype)initWithLocalFile:(OALocalFile *)localeFile
                       remoteFile:(OARemoteFile *)remoteFile
       backupExportImportListener:(id)backupExportImportListener;

@property(nonatomic, weak) id<OAStatusBackupTableDelegate> delegate;

@end
