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

@protocol OATilesEditingViewControllerDelegate <NSObject>

- (void) onTileSourceSaved:(OALocalResourceItem *)item;

@end

@class OAResourcesBaseViewController;

@interface OAOnlineTilesEditingViewController : OACompoundViewController<UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIView *navBarView;

@property (nonatomic) id<OATilesEditingViewControllerDelegate> delegate;

- (instancetype) initWithLocalItem:(OALocalResourceItem *)item baseController: (OAResourcesBaseViewController *)baseController;
- (instancetype) initWithUrlParameters:(NSDictionary<NSString *, NSString *> *)params;
- (instancetype) initWithEmptyItem;

@end

