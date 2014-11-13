//
//  OAFavoriteGroupViewController.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 10.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#import "OAFavoriteItem.h"

@interface OAFavoriteGroupViewController : OASuperViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (strong, nonatomic) OAFavoriteItem* favorite;
@property (strong, nonatomic) NSString* groupName;

@property (weak, nonatomic) IBOutlet UILabel *titleView;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButtonView;
@property (weak, nonatomic) IBOutlet UIButton *gpxButtonView;

-(id)initWithFavorite:(OAFavoriteItem*)item;

@end
