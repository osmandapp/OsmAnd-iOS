//
//  OAMapSettingsViewController.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 12.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#import "OACommonTypes.h"
#import "OsmAndApp.h"

#import "OAMapRendererViewProtocol.h"

@interface OAMapSettingsViewController : OASuperViewController<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIView *mapView;
@property (weak, nonatomic) IBOutlet UIScrollView *mapTypeScrollView;
@property (weak, nonatomic) IBOutlet UIButton *mapTypeButtonView;
@property (weak, nonatomic) IBOutlet UIButton *mapTypeButtonCar;
@property (weak, nonatomic) IBOutlet UIButton *mapTypeButtonWalk;
@property (weak, nonatomic) IBOutlet UIButton *mapTypeButtonBike;

@property (weak, nonatomic) IBOutlet UITableView *tableView;


@end
