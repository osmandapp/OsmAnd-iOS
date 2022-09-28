//
//  OACloudRecentChangesTableViewController.h
//  OsmAnd
//
//  Created by Skalii on 16.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OANetworkSettingsHelper.h"
#import "OASettingsItemType.h"

@class OATableViewRowData, OAPrepareBackupResult, OABackupStatus;

typedef NS_ENUM(NSInteger, EOARecentChangesTable)
{
    EOARecentChangesAll = 0,
    EOARecentChangesConflicts
};

@protocol OAStatusBackupTableDelegate

- (void)disableBottomButtons;
- (void)updateBackupStatus:(OAPrepareBackupResult *)backupResult;

- (void)setRowIcon:(OATableViewRowData *)rowData item:(OASettingsItem *)item;
- (NSString *)getDescriptionForItemType:(EOASettingsItemType)type fileName:(NSString *)fileName summary:(NSString *)summary;

@end

@interface OAStatusBackupTableViewController : UITableViewController <OABackupExportListener>

- (instancetype)initWithTableType:(EOARecentChangesTable)type backup:(OAPrepareBackupResult *)backup status:(OABackupStatus *)status;

- (void)setDelegate:(id<OAStatusBackupTableDelegate>)delegate;

@end
