//
//  OAFavoriteColorViewController.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 10.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#import "OAFavoriteItem.h"

@interface OAFavoriteColorViewController : OASuperViewController<UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) OAFavoriteItem* favorite;
@property (assign, nonatomic) NSInteger colorIndex;

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButtonView;
@property (weak, nonatomic) IBOutlet UIButton *gpxButtonView;

@property (weak, nonatomic) IBOutlet UIView *toolbarView;
@property (assign, nonatomic) BOOL hideToolbar;

-(id)initWithFavorite:(OAFavoriteItem*)item;

@end