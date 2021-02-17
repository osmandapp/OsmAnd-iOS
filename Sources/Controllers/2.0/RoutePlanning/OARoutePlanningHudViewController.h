//
//  OARoutePlanningHudViewController.h
//  OsmAnd
//
//  Created by Paul on 10/16/20.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "OABaseScrollableHudViewController.h"

@interface OARoutePlanningHudViewController : OABaseScrollableHudViewController

- (instancetype) initWithFileName:(NSString *)filePath;
- (instancetype) initWithInitialPoint:(CLLocation *)latLon;

- (void) cancelModes;

@end
