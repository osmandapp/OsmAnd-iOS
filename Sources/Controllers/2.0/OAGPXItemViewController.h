//
//  OAGPXItemViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 16/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"

@interface OAGPXItemViewController : OASuperViewController<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIButton *showPointsButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@property (weak, nonatomic) IBOutlet UIButton *favoritesButtonView;
@property (weak, nonatomic) IBOutlet UIButton *gpxButtonView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

- (IBAction)menuFavoriteClicked:(id)sender;
- (IBAction)menuGPXClicked:(id)sender;

- (IBAction)showPointsClicked:(id)sender;
- (IBAction)deleteClicked:(id)sender;

@end
