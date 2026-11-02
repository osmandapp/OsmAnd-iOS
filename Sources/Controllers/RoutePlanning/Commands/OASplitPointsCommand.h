//
//  OASplitPointsCommand.h
//  OsmAnd
//
//  Created by Anna Bibyk on 21.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//
// OsmAnd/src/net/osmand/plus/measurementtool/command/AddPointCommand.java
// git revision e0189c904fd6cafede06a20c49478ee1b9eab0c3

#import "OAMeasurementModeCommand.h"

@class OAMeasurementToolLayer;
@class OAApplicationMode;

@interface OASplitPointsCommand : OAMeasurementModeCommand

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer after:(BOOL)after;
- (instancetype)initWithLayer:(OAMeasurementToolLayer *)measurementLayer after:(BOOL)after appMode:(OAApplicationMode *)appMode;

@end
