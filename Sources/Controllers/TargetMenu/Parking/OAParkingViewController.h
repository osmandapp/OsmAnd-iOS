//
//  OAParkingViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class OAParkingViewController;
@class OADestination;

@protocol OAParkingDelegate <NSObject>

@optional
- (void)addParking:(OAParkingViewController *)sender;
- (void)cancelParking:(OAParkingViewController *)sender;

@end

@interface OAParkingViewController : OATargetMenuViewController<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, readonly) CLLocationCoordinate2D coord;
@property (nonatomic, readonly) BOOL timeLimitActive;
@property (nonatomic, readonly) BOOL addToCalActive;
@property (nonatomic, readonly) NSDate *date;

@property (nonatomic, readonly) BOOL isNew;

@property (weak, nonatomic) id<OAParkingDelegate> parkingDelegate;

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate;
- (instancetype)initWithParking;

@end
