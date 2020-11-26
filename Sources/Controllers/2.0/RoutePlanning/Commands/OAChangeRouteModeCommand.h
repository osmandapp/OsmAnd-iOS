//
//  OAChangeRouteModeCommand.h
//  OsmAnd
//
//  Created by Paul on 25.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMeasurementModeCommand.h"

typedef NS_ENUM(NSInteger, EOAChangeRouteType)
{
    LAST_SEGMENT = 0,
    WHOLE_ROUTE,
    NEXT_SEGMENT,
    ALL_NEXT_SEGMENTS,
    PREV_SEGMENT,
    ALL_PREV_SEGMENTS
};

@interface OAChangeRouteModeCommand : OAMeasurementModeCommand

@end
