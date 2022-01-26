//
//  OAEditDescriptionViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 03/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

#import <WebKit/WebKit.h>

@protocol OAEditDescriptionViewControllerDelegate <NSObject>

@optional
- (void) descriptionChanged;

@end

@interface OAEditDescriptionViewController : OACompoundViewController

@property (weak, nonatomic) IBOutlet UIView *toolbarView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) id delegate;

@property (nonatomic, copy) NSString *desc;

-(id)initWithDescription:(NSString *)desc isNew:(BOOL)isNew isEditing:(BOOL)isEditing readOnly:(BOOL)readOnly;

@end
