//
//  OADashboardScreen.h
//  OsmAnd
//
//  Created by Alexey Kulish on 02/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "OsmAndApp.h"
#import "OAAppSettings.h"

@class OADashboardViewController;

@protocol OADashboardScreen <NSObject, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) OADashboardViewController *vwController;
@property (nonatomic) UITableView *tblView;
@property (nonatomic) NSArray *tableData;

@property (nonatomic) NSString *title;

@optional
- (id) initWithTable:(UITableView *)tableView viewController:(OADashboardViewController *)viewController;
- (id) initWithTable:(UITableView *)tableView viewController:(OADashboardViewController *)viewController param:(id)param;

@required
- (void) initData;
- (void) setupView;

@optional
- (void) initView;
- (void) deinitView;
- (BOOL) backButtonPressed; // return YES to dismiss
- (BOOL) okButtonPressed; // return YES to dismiss

@end
