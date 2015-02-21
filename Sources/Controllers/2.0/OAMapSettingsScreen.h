//
//  OAMapSettingsScreen.h
//  OsmAnd
//
//  Created by Alexey Kulish on 21/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "OAMapSettingsViewController.h"


@protocol OAMapSettingsScreen <NSObject, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) OAMapSettingsViewController *vwController;
@property (nonatomic) UITableView *tblView;
@property (nonatomic) NSArray *tableData;
@property (nonatomic, readonly) EMapSettingsScreen settingsScreen;

@property (nonatomic) NSString *title;

@property OsmAndAppInstance app;
@property OAAppSettings* settings;

- (id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController;
- (void)initData;
- (void)setupView;

@end
