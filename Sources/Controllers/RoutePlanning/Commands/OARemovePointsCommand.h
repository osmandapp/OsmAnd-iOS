//
//  OARemovePointsCommand.h
//  OsmAnd Maps
//
//  Created by OsmAnd on 10.10.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAMeasurementModeCommand.h"

@class OAMeasurementToolLayer;

// Removes several points as one undo step
@interface OARemovePointsCommand : OAMeasurementModeCommand

- (instancetype)initWithLayer:(OAMeasurementToolLayer *)measurementLayer
                    positions:(NSArray<NSNumber *> *)positions;

@end
