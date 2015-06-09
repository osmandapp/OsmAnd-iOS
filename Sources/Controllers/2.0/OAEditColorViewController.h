//
//  OAEditColorViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"

@protocol OAEditColorViewControllerDelegate <NSObject>

@optional
- (void) colorChanged;

@end

@interface OAEditColorViewController : OASuperViewController<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (assign, nonatomic) NSInteger colorIndex;
@property (nonatomic, readonly) BOOL saveChanges;

@property (weak, nonatomic) id delegate;

- (id) initWithColor:(UIColor *)color;

@end