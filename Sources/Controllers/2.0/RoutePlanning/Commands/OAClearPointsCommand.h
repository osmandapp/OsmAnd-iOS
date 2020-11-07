//
//  OAClearPointsCommand.h
//  OsmAnd
//
//  Created by Paul on 05.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMeasurementModeCommand.h"

typedef NS_ENUM(NSInteger, EOAClearPointsMode) {
    EOAClearPointsModeAll = 0,
    EOAClearPointsModeBefore,
    EOAClearPointsModeAfter
};

@interface OAClearPointsCommand : OAMeasurementModeCommand

- (instancetype) initWithMeasurementLayer:(OAMeasurementToolLayer *)layer mode:(EOAClearPointsMode)mode;

@end
