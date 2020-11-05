//
//  OAMovePointCommand.h
//  OsmAnd
//
//  Created by Paul on 03.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMeasurementModeCommand.h"

@class OAMeasurementToolLayer, OAGpxTrkPt;

@interface OAMovePointCommand : OAMeasurementModeCommand

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer oldPoint:(OAGpxTrkPt *)oldPoint newPoint:(OAGpxTrkPt *)newPoint position:(NSInteger)position;

@end

