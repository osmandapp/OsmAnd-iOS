//
//  OACategoriesTableViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 17/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@class OAQuickSearchListItem;

@protocol OACategoryTableDelegate

@required

- (void) createPOIUIFIlter;

@end

@interface OACategoriesTableViewController : UITableViewController

@property (nonatomic) NSArray<OAQuickSearchListItem *> *dataArray;
@property (nonatomic, readonly) BOOL searchNearMapCenter;
@property (nonatomic, readonly) CLLocationCoordinate2D mapCenterCoordinate;

@property (weak, nonatomic) id<OACategoryTableDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame;

- (void) setMapCenterCoordinate:(CLLocationCoordinate2D)mapCenterCoordinate;
- (void) resetMapCenterSearch;

- (void) reloadData;

@end
