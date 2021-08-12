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

@interface OAGPXListViewController : OACompoundViewController<UITableViewDataSource, UITableViewDelegate, OAGPXImportDelegate>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UITableView *gpxTableView;

@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *checkButton;
@property (weak, nonatomic) IBOutlet UIButton *mapButton;

- (instancetype)initWithActiveTrips;
- (instancetype)initWithAllTrips;

-(void)processUrl:(NSURL*)url;
-(void)processUrl:(NSURL*)url openGpxView:(BOOL)openGpxView;

- (void) setShouldPopToParent:(BOOL)shouldPop;

+ (BOOL)popToParent;

@end
