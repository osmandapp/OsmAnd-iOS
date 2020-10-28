//
//  OARemovePointCommand.h
//  OsmAnd
//
//  Created by Paul on 28.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMeasurementModeCommand.h"

@class OAMeasurementToolLayer;

@interface OARemovePointCommand : OAMeasurementModeCommand

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer position:(NSInteger)position;

@end
