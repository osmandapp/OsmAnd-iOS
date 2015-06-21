//
//  OAGPXPointListViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 18/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#import "OAObservable.h"
#import "OAAutoObserverProxy.h"

typedef enum
{
    EPointsSortingTypeGrouped = 0,
    EPointsSortingTypeDistance
    
} EPointsSortingType;

@interface OAGPXPointListViewController : OASuperViewController<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *sortButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (assign, nonatomic) EPointsSortingType sortingType;

- (void)doViewAppear;
- (void)doViewDisappear;

- (void)resetData;
- (void)doSortClick:(UIButton *)button;

@property (strong, nonatomic) OAAutoObserverProxy* locationServicesUpdateObserver;
@property CGFloat azimuthDirection;

@property NSTimeInterval lastUpdate;

- (id)initWithLocationMarks:(NSArray *)locationMarks;

@end
