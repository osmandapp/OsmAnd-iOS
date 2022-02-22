//
//  OAGPXListViewController.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 04.12.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"
#import "OAObservable.h"
#import "OAAutoObserverProxy.h"
#import "OAImportGPXBottomSheetViewController.h"
#import "OAGPXListDeletingBottomSheet.h"

@interface OAGPXListViewController : OACompoundViewController<UITableViewDataSource, UITableViewDelegate, OAGPXImportDelegate, OAGPXListDeletingBottomSheetDelegate>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UITableView *gpxTableView;

@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *selectAllButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIButton *selectionModeButton;

@property (weak, nonatomic) IBOutlet UIView *editToolbarView;
@property (weak, nonatomic) IBOutlet UIButton *exportButton;
@property (weak, nonatomic) IBOutlet UIButton *showOnMapButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

- (instancetype)initWithActiveTrips;
- (instancetype)initWithAllTrips;

- (void)prepareProcessUrl:(NSURL *)url showAlerts:(BOOL)showAlerts openGpxView:(BOOL)openGpxView;

- (void)setShouldPopToParent:(BOOL)shouldPop;

+ (BOOL)popToParent;

@end
