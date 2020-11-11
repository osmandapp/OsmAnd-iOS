//
//  OARemovePointCommand.h
//  OsmAnd
//
//  Created by Paul on 28.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//
// OsmAnd/src/net/osmand/plus/measurementtool/command/RemovePointCommand.java
// git revision d97dfac152be459ea4f64123024f2f4aa3472dde

#import "OAMeasurementModeCommand.h"

@class OAMeasurementToolLayer;

@interface OARemovePointCommand : OAMeasurementModeCommand

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer position:(NSInteger)position;

@end
