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

@class OAMeasurementEditingContext;

@interface OARoutePlanningHudViewController : OABaseScrollableHudViewController

- (instancetype) initWithFileName:(NSString *)fileName;
- (instancetype) initWithInitialPoint:(CLLocation *)latLon;
- (instancetype) initWithEditingContext:(OAMeasurementEditingContext *)editingCtx followTrackMode:(BOOL)followTrackMode;

- (void) cancelModes;

@end
