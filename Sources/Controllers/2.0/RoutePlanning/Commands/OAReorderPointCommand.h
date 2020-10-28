//
//  OAReorderPointCommand.h
//  OsmAnd
//
//  Created by Paul on 28.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMeasurementModeCommand.h"

@class OAMeasurementToolLayer;

@interface OAReorderPointCommand : OAMeasurementModeCommand

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer from:(NSInteger)from to:(NSInteger)to;

@end
