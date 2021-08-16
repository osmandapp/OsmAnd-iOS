//
//  OAEditGPXColorViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"
#import "OAGPXTrackColorCollection.h"

@protocol OAEditGPXColorViewControllerDelegate <NSObject>

@optional
- (void) trackColorChanged;

@end

@interface OAEditGPXColorViewController : OACompoundViewController<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (assign, nonatomic) NSInteger colorIndex;
@property (nonatomic, readonly) BOOL saveChanges;

@property (weak, nonatomic) id delegate;

- (id) initWithColorValue:(NSInteger)colorValue colorsCollection:(OAGPXTrackColorCollection *)collection;

@end
