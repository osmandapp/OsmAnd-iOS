//
//  OAImpassableRoadViewController.h
//  OsmAnd
//
//  Created by Paul on 17/12/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OARouteBaseViewController.h"
#import "OATrackMenuHudViewController.h"

@interface OARouteDetailsGraphViewController : OARouteBaseViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (instancetype)initWithGpxData:(NSDictionary *)data
          trackMenuControlState:(OATargetMenuViewControllerState *)trackMenuControlState;

- (void)onNewModeSelected:(EOARouteStatisticsMode)mode;

@end
