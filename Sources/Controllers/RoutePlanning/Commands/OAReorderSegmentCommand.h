//
//  OAReorderSegmentCommand.h
//  OsmAnd Maps
//
//  Created by OsmAnd on 07.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAMeasurementModeCommand.h"

@class OAMeasurementToolLayer;

@interface OAReorderSegmentCommand : OAMeasurementModeCommand

- (instancetype)initWithLayer:(OAMeasurementToolLayer *)measurementLayer
                         from:(NSInteger)from
                           to:(NSInteger)to;

@end
