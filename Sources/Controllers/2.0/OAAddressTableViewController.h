//
//  OAAddressTableViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 23/05/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "OAQuickSearchTableController.h"

@protocol OAAddressTableDelegate

@required

- (void) reloadAddressData;

@end

@interface OAAddressTableViewController : UITableViewController

@property (nonatomic, readonly) BOOL searchNearMapCenter;
@property (nonatomic, readonly) CLLocationCoordinate2D mapCenterCoordinate;
@property (nonatomic, assign) OAQuickSearchType searchType;

@property (weak, nonatomic) id<OAAddressTableDelegate> delegate;
@property (weak, nonatomic) id<OAQuickSearchTableDelegate> tableDelegate;

- (instancetype)initWithFrame:(CGRect)frame;

- (void) setMapCenterCoordinate:(CLLocationCoordinate2D)mapCenterCoordinate;
- (void) resetMapCenterSearch;
- (void) updateDistanceAndDirection;

- (void) setData:(NSArray<NSArray<OAQuickSearchListItem *> *> *)rows;
- (void) reloadData;

@end
