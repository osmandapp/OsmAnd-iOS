//
//  OAQuickSearchCoordinatesViewController.h
//  OsmAnd
//
//  Created by nnngrach on 25.08.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseTableViewController.h"
#import <CoreLocation/CoreLocation.h>

@class OASearchResult;

@interface OAQuickSearchCoordinatesViewController : OABaseTableViewController

- (instancetype) initWithLat:(double)lat lon:(double)lon;

+ (NSArray<OASearchResult *> *)searchCities:(NSString *)text
                             searchLocation:(CLLocation *)searchLocation
                                       view:(UIView *)view
                                 onComplete:(void (^)(NSMutableArray *amenities))onComplete;
@end
