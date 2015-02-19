//
//  OAGPXPointViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 19/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#import "OAGpxWptItem.h"


@interface OAGPXPointViewController : OASuperViewController<UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) OAGpxWptItem* wptItem;

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIView *mapView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIView *distanceDirectionHolderView;
@property (weak, nonatomic) IBOutlet UILabel *itemDistance;
@property (weak, nonatomic) IBOutlet UIImageView *itemDirection;

@property (weak, nonatomic) IBOutlet UIButton *favoritesButtonView;
@property (weak, nonatomic) IBOutlet UIButton *gpxButtonView;

@property (weak, nonatomic) IBOutlet UIView *toolbarView;

- (id)initWithWptItem:(OAGpxWptItem*)wptItem;

- (IBAction)menuFavoriteClicked:(id)sender;
- (IBAction)menuGPXClicked:(id)sender;


@end
