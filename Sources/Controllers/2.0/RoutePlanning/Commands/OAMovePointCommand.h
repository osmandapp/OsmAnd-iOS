//
//  OAMovePointCommand.h
//  OsmAnd
//
//  Created by Paul on 03.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//
// OsmAnd/src/net/osmand/plus/measurementtool/command/MovePointCommand.java
// git revision b1d714a62c513b96bdc616ec5531cff8231c6f43

#import "OAMeasurementModeCommand.h"

@class OAMeasurementToolLayer, OAGpxTrkPt;

@interface OAMovePointCommand : OAMeasurementModeCommand

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer oldPoint:(OAGpxTrkPt *)oldPoint newPoint:(OAGpxTrkPt *)newPoint position:(NSInteger)position;

@end

