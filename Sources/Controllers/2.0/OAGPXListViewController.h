//
//  OAGPXListViewController.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 04.12.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#import "OAObservable.h"
#import "OAAutoObserverProxy.h"

@interface OAGPXListViewController : OASuperViewController<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UITableView *gpxTableView;

@property (weak, nonatomic) IBOutlet UIView *toolbarView;
@property (weak, nonatomic) IBOutlet UIButton *activeTripsButtonView;
@property (weak, nonatomic) IBOutlet UIButton *allTripsButtonView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

- (instancetype)initWithActiveTrips;
- (instancetype)initWithAllTrips;
- (instancetype)initWithImportGPXItem:(NSURL*)url;

+ (BOOL)popToParent;

@end
