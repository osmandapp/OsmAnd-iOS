//
//  OACloudRecentChangesTableViewController.h
//  OsmAnd
//
//  Created by Skalii on 16.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, EOARecentChangesTable)
{
    EOARecentChangesAll = 0,
    EOARecentChangesConflicts
};

@protocol OAStatusBackupTableDelegate


@end

@class OAPrepareBackupResult, OABackupStatus;

@interface OAStatusBackupTableViewController : UITableViewController

- (instancetype)initWithTableType:(EOARecentChangesTable)type backup:(OAPrepareBackupResult *)backup status:(OABackupStatus *)status;

@property (nonatomic, weak) id<OAStatusBackupTableDelegate> delegate;

@end
