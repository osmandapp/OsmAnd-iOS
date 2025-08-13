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

@class OAMeasurementToolLayer, OASWptPt;

@interface OAMovePointCommand : OAMeasurementModeCommand

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer
                      oldPoint:(OASWptPt *)oldPoint
                      newPoint:(OASWptPt *)newPoint
                      position:(NSInteger)position;

@end

