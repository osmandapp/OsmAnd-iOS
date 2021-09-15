//
//  OAQuickSearchCoordinatesViewController.h
//  OsmAnd
//
//  Created by nnngrach on 25.08.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseTableViewController.h"
#import <CoreLocation/CoreLocation.h>

@interface OAQuickSearchCoordinatesViewController : OABaseTableViewController

- (instancetype) initWithLat:(double)lat lon:(double)lon;

@end
