//
//  OAGPXEditWptListViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 18/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAObservable.h"
#import "OAAutoObserverProxy.h"

@interface OAGPXEditWptListViewController : UITableViewController

- (void)doViewAppear;
- (void)doViewDisappear;

- (void)generateData;
- (void)resetData;

@property (strong, nonatomic) OAAutoObserverProxy* locationServicesUpdateObserver;
@property CGFloat azimuthDirection;

@property NSTimeInterval lastUpdate;

- (id)initWithLocationMarks:(NSArray *)locationMarks;
- (void)setPoints:(NSArray *)locationMarks;

@end
