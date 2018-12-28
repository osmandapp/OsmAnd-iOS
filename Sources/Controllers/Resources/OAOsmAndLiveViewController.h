//
//  OAOsmAndLiveViewController.h
//  OsmAnd
//
//  Created by Paul on 11/29/18.
//  Copyright (c) 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OACompoundViewController.h"
#import "OAWorldRegion.h"
#import "OAResourcesBaseViewController.h"


@interface OAOsmAndLiveViewController : OACompoundViewController
@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *donationSettings;

- (void) setLocalResources:(NSArray *)localResources;
@end
