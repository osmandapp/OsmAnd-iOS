//
//  OARouteCalculationParams.m
//  OsmAnd
//
//  Created by Alexey Kulish on 03/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARouteCalculationParams.h"

@implementation OARouteCalculationParams

- (BOOL) recheckRouteNearestPoint
{
    return self.previousToRecalculate && self.onlyStartPointChanged && self.start && self.gpxRoute;
}

- (void) takeMissingMapsResultFrom:(OARouteCalculationParams *)params
{
    if (!self.missingMapsResult)
        self.missingMapsResult = params.missingMapsResult;
}

@end
