//
//  OALocalResourceInformationViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/17/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OACompoundViewController.h"
#import "OAWorldRegion.h"
#import "OAResourcesBaseViewController.h"

@interface OALocalResourceInformationViewController : OACompoundViewController

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (strong, nonatomic) NSString *regionTitle;

@property (nonatomic, assign) BOOL openFromSplash;

@property (weak, nonatomic) OAResourcesBaseViewController *baseController;
@property (nonatomic) OALocalResourceItem* localItem;

- (void)initWithLocalResourceId:(NSString*)resourceId;
- (void)initWithLocalResourceId:(NSString*)resourceId
                              forRegion:(OAWorldRegion*)region;
- (void)initWithLocalSqliteDbItem:(OASqliteDbResourceItem *)item;
- (void)initWithLocalOnlineSourceItem:(OAOnlineTilesResourceItem *)item;

@end
