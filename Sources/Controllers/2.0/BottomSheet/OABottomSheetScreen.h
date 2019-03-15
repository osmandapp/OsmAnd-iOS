//
//  OABottomSheetScreen.h
//  OsmAnd
//
//  Created by Alexey Kulish on 03/04/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "OsmAndApp.h"
#import "OAAppSettings.h"

@class OABottomSheetViewController;

@protocol OABottomSheetScreen <NSObject, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) OABottomSheetViewController *vwController;
@property (nonatomic) UITableView *tblView;
@property (nonatomic) NSArray *tableData;

@optional
- (id) initWithTable:(UITableView *)tableView viewController:(OABottomSheetViewController *)viewController;
- (id) initWithTable:(UITableView *)tableView viewController:(OABottomSheetViewController *)viewController param:(id)param;

@required
- (void) initData;
- (void) setupView;

@optional
- (void) initView;
- (void) deinitView;
- (BOOL) cancelButtonPressed; // return YES to dismiss
- (void) doneButtonPressed;

@end
