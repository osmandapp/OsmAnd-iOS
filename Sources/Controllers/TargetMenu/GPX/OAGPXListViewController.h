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
#import "OAGPXListDeletingBottomSheet.h"

@interface OAGPXListViewController : OACompoundViewController<UITableViewDataSource, UITableViewDelegate, OAGPXListDeletingBottomSheetDelegate>

@property (weak, nonatomic) IBOutlet UITableView *gpxTableView;
@property (weak, nonatomic) IBOutlet UIView *editToolbarView;
@property (weak, nonatomic) IBOutlet UIButton *exportButton;
@property (weak, nonatomic) IBOutlet UIButton *showOnMapButton;
@property (weak, nonatomic) IBOutlet UIButton *uploadToOSMButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

- (instancetype)initWithActiveTrips;
- (instancetype)initWithAllTrips;

- (void)prepareProcessUrl:(NSURL *)url showAlerts:(BOOL)showAlerts openGpxView:(BOOL)openGpxView completion:(void (^)(BOOL success))completion;

- (void)setShouldPopToParent:(BOOL)shouldPop;

+ (BOOL)popToParent;

@end
