//
//  OABaseNavbarViewController.h
//  OsmAnd
//
//  Created by Skalii on 08.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OACompoundViewController.h"

@interface OABaseNavbarViewController : OACompoundViewController<UIScrollViewDelegate/*, UITableViewDelegate, UITableViewDataSource*/>

@property (weak, nonatomic) IBOutlet UIButton *leftNavbarButton;
@property (weak, nonatomic) IBOutlet UIButton *rightNavbarButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIView *separatorNavbarView;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
