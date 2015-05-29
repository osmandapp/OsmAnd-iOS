//
//  OASetParkingViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 06/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class OASetParkingViewController;

@protocol OASetParkingDelegate <NSObject>

@optional
- (void)addParkingPoint:(OASetParkingViewController *)sender;

@end

@interface OASetParkingViewController : OASuperViewController<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *buttonCancel;
@property (weak, nonatomic) IBOutlet UIButton *buttonAdd;
@property (weak, nonatomic) IBOutlet UIView *mapView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, readonly) CLLocationCoordinate2D coord;
@property (nonatomic, readonly) BOOL timeLimitActive;
@property (nonatomic, readonly) BOOL addToCalActive;
@property (nonatomic, readonly) NSDate *date;

@property (weak, nonatomic) id<OASetParkingDelegate> delegate;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate isPopup:(BOOL)isPopup;

@end
