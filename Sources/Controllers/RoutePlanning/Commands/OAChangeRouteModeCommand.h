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
    EOAChangeRouteLastSegment = 0,
    EOAChangeRouteWhole,
    EOAChangeRouteNextSegment,
    EOAChangeRouteAllNextSegments,
    EOAChangeRoutePrevSegment,
    EOAChangeRouteAllPrevSegments
};

@class OAApplicationMode;

@interface OAChangeRouteModeCommand : OAMeasurementModeCommand

- (instancetype)initWithLayer:(OAMeasurementToolLayer *)measurementLayer appMode:(OAApplicationMode *)appMode changeRouteType:(EOAChangeRouteType)changeRouteType pointIndex:(NSInteger)pointIndex;

@end
