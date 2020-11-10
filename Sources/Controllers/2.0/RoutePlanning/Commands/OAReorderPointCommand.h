//
//  OAReorderPointCommand.h
//  OsmAnd
//
//  Created by Paul on 28.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//
// OsmAnd/src/net/osmand/plus/measurementtool/command/ReorderPointCommand.java
// git revision b1d714a62c513b96bdc616ec5531cff8231c6f43

#import "OAMeasurementModeCommand.h"

@class OAMeasurementToolLayer;

@interface OAReorderPointCommand : OAMeasurementModeCommand

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer from:(NSInteger)from to:(NSInteger)to;

@end
