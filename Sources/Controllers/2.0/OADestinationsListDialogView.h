//
//  OADestinationsListDialogView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OADestinationItemsListViewController.h"

@class OADestination;

@interface OADestinationsListDialogView : UIView

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, weak) id<OADestinationPointListDelegate> delegate;

@end
