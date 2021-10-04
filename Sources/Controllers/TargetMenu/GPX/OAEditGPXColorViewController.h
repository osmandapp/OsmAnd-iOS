//
//  OAEditGPXColorViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"
#import "OAGPXAppearanceCollection.h"

@protocol OAEditGPXColorViewControllerDelegate <NSObject>

@required

- (void)trackColorChanged:(NSInteger)colorIndex;

@end

@interface OAEditGPXColorViewController : OACompoundViewController<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) id<OAEditGPXColorViewControllerDelegate> delegate;

- (id)initWithColorValue:(NSInteger)colorValue colorsCollection:(OAGPXAppearanceCollection *)collection;

@end
