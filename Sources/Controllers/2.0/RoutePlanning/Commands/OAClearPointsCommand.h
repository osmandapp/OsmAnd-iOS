//
//  OAClearPointsCommand.h
//  OsmAnd
//
//  Created by Paul on 05.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//
// OsmAnd/src/net/osmand/plus/measurementtool/command/ClearPointsCommand.java
// git revision b1d714a62c513b96bdc616ec5531cff8231c6f43

#import "OAMeasurementModeCommand.h"

typedef NS_ENUM(NSInteger, EOAClearPointsMode) {
    EOAClearPointsModeAll = 0,
    EOAClearPointsModeBefore,
    EOAClearPointsModeAfter
};

@interface OAClearPointsCommand : OAMeasurementModeCommand

- (instancetype) initWithMeasurementLayer:(OAMeasurementToolLayer *)layer mode:(EOAClearPointsMode)mode;

@end
