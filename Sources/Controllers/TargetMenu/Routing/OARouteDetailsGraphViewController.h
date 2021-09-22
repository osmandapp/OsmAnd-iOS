//
//  OAImpassableRoadViewController.h
//  OsmAnd
//
//  Created by Paul on 17/12/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OARouteBaseViewController.h"
#import "OATrackMenuViewController.h"

@interface OARouteDetailsGraphViewController : OARouteBaseViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) id<OATrackMenuViewControllerDelegate> trackMenuDelegate;

- (void)onNewModeSelected:(EOARouteStatisticsMode)mode;

@end
