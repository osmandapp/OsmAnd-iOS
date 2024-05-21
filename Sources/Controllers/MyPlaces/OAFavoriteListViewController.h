//
//  OAFavoriteListViewController.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 07.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"
#import "OAObservable.h"
#import "OAAutoObserverProxy.h"

@interface OAFavoriteListViewController : OACompoundViewController<UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *favoriteTableView;
@property (weak, nonatomic) IBOutlet UIView *editToolbarView;
@property (weak, nonatomic) IBOutlet UIButton *exportButton;
@property (weak, nonatomic) IBOutlet UIButton *groupButton;
@property (weak, nonatomic) IBOutlet UIButton *colorButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@property CGFloat azimuthDirection;

@property NSTimeInterval lastUpdate;

+ (BOOL)popToParent;

@end
