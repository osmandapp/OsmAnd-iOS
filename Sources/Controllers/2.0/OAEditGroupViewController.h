//
//  OAEditGroupViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@protocol OAEditGroupViewControllerDelegate <NSObject>

@optional
- (void) groupChanged;

@end

@interface OAEditGroupViewController : OACompoundViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSString* groupName;
@property (nonatomic, readonly) BOOL saveChanges;

@property (weak, nonatomic) id delegate;

-(id)initWithGroupName:(NSString *)groupName groups:(NSArray *)groups;

@end
