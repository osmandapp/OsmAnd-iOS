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
- (void) descriptionChanged:(NSString *)descr;

@end

@interface OAEditDescriptionViewController : OACompoundViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) id delegate;

-(instancetype)initWithDescription:(NSString *)desc isNew:(BOOL)isNew isEditing:(BOOL)isEditing readOnly:(BOOL)readOnly;

-(instancetype)initWithDescription:(NSString *)desc isNew:(BOOL)isNew isEditing:(BOOL)isEditing isComment:(BOOL)isComment readOnly:(BOOL)readOnly;

@end
