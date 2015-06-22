//
//  OAGPXWptListViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 21/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAObservable.h"
#import "OAAutoObserverProxy.h"

typedef enum
{
    EPointsSortingTypeGrouped = 0,
    EPointsSortingTypeDistance
    
} EPointsSortingType;

@interface OAGPXWptListViewController : UITableViewController

@property (assign, nonatomic) EPointsSortingType sortingType;

- (void)doViewAppear;
- (void)doViewDisappear;

- (void)resetData;
- (void)doSortClick:(UIButton *)button;
- (void)updateSortButton:(UIButton *)button;

@property (strong, nonatomic) OAAutoObserverProxy* locationServicesUpdateObserver;
@property CGFloat azimuthDirection;

@property NSTimeInterval lastUpdate;

- (id)initWithLocationMarks:(NSArray *)locationMarks;

@end
