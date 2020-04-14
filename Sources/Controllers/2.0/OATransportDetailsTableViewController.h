//
//  OATransportDetailsTableViewController.h
//  OsmAnd
//
//  Created by Paul on 20.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OATransportDetailsTableViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (instancetype)initWithRouteIndex:(NSInteger) routeIndex;

- (CGFloat) getMinimizedContentHeight;

@end
