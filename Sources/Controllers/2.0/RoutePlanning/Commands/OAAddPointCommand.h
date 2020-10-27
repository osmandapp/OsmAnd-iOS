//
//  OAAddPointCommand.h
//  OsmAnd
//
//  Created by Paul on 24.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMeasurementModeCommand.h"
#import <CoreLocation/CoreLocation.h>

@class OAMeasurementToolLayer;

@interface OAAddPointCommand : OAMeasurementModeCommand

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer center:(BOOL)center;
- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer coordinate:(CLLocation *)latLon;

@end
