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

@class OATableRowData;

typedef NS_ENUM(NSInteger, EOARecentChangesType)
{
    EOARecentChangesLocal = 0,
    EOARecentChangesRemote,
    EOARecentChangesConflicts
};

@protocol OAStatusBackupDelegate

- (void)setRowIcon:(OATableRowData *)rowData item:(OASettingsItem *)item;
- (NSString *)getDescriptionForItemType:(EOASettingsItemType)type fileName:(NSString *)fileName summary:(NSString *)summary;
- (NSString *)generateTimeString:(long)timeMs summary:(NSString *)summary;
- (void (^)(NSString *message, NSString *details))showErrorToast;

@end

@interface OAStatusBackupTableViewController : UITableViewController

- (instancetype)initWithTableType:(EOARecentChangesType)type;

- (BOOL) hasItems;

@end
