//
//  OACategoriesTableViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 17/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "OAQuickSearchTableController.h"

@class OAQuickSearchListItem;
@class OAPOIUIFilter;

@protocol OACategoryTableDelegate

@required

- (void)showCreateFilterScreen;
- (void)showRearrangeCategoriesScreen:(NSArray<OAPOIUIFilter *> *)filters;
- (void)showDeleteFiltersScreen:(NSArray<OAPOIUIFilter *> *)filters;
- (NSArray<OAPOIUIFilter *> *)getCustomFilters;

@end

@interface OACategoriesTableViewController : UITableViewController

@property (nonatomic, readonly) BOOL searchNearMapCenter;
@property (nonatomic, readonly) CLLocationCoordinate2D mapCenterCoordinate;
@property (nonatomic, assign) OAQuickSearchType searchType;

@property (weak, nonatomic) id<OACategoryTableDelegate> delegate;
@property (weak, nonatomic) id<OAQuickSearchTableDelegate> tableDelegate;

- (instancetype)initWithFrame:(CGRect)frame;

- (void) setMapCenterCoordinate:(CLLocationCoordinate2D)mapCenterCoordinate;
- (void) resetMapCenterSearch;

- (void) reloadData;

@end
