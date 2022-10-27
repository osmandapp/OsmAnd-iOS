//
//  OACloudRecentChangesViewController.h
//  OsmAnd
//
//  Created by Skalii on 16.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@class OAPrepareBackupResult, OABackupStatus;

@protocol OABackupTypesDelegate;

@interface OAStatusBackupViewController : OACompoundViewController

- (instancetype) initWithBackup:(OAPrepareBackupResult *)backup status:(OABackupStatus *)status;
- (instancetype) initWithBackup:(OAPrepareBackupResult *)backup status:(OABackupStatus *)status openConflicts:(BOOL)openConflicts;

@property (nonatomic, weak) id<OABackupTypesDelegate> delegate;

@end
