//
//  OAJoinPointsCommand.h
//  OsmAnd
//
//  Created by Anna Bibyk on 21.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//
// OsmAnd/src/net/osmand/plus/measurementtool/command/JoinPointsCommand.java
// git revision 53de5bf80e53d259b2a84a44af56591c5590f3b2

#import "OAMeasurementModeCommand.h"

@class OAMeasurementToolLayer;

@interface OAJoinPointsCommand : OAMeasurementModeCommand

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer;

@end
