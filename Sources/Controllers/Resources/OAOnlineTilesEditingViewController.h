//
//  OAOnlineTilesEditingViewController.h
//  OsmAnd Maps
//
//  Created by igor on 23.01.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"
#import "OAResourcesBaseViewController.h"

typedef NS_ENUM(NSInteger, EOASourceFormat)
{
    EOASourceFormatSQLite = 0,
    EOASourceFormatOnline
};

@protocol OAOnlineTilesEditingViewControllerDelegate <NSObject>

- (void) onTileSourceSaved;

@end

@class OAResourcesBaseViewController;

@interface OAOnlineTilesEditingViewController : OACompoundViewController<UITableViewDelegate, UITableViewDataSource>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UILabel *titleView;
@property (strong, nonatomic) IBOutlet UIButton *saveButton;
@property (strong, nonatomic) IBOutlet UIButton *backButton;
@property (strong, nonatomic) IBOutlet UIView *navBarView;

@property (nonatomic) id<OAOnlineTilesEditingViewControllerDelegate> delegate;

- (instancetype) initWithLocalItem:(LocalResourceItem *)item baseController: (OAResourcesBaseViewController *)baseController;
- (instancetype) initWithUrlParameters:(NSDictionary *)params;

@end

