//
//  OAGpxRouteApproximation.m
//  OsmAnd Maps
//
//  Created by Paul on 15.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAGpxRouteApproximation.h"
#import "OsmAndSharedWrapper.h"

@implementation OAGpxRouteApproximation

- (instancetype) initWithApproximation:(OASGpxRouteApproximation *)approximation
{
    if (!approximation)
        return nil;

    return [self initWithFinalPoints:approximation.finalPoints fullRoute:approximation.fullRoute];
}

- (instancetype) initWithFinalPoints:(NSArray<OASGpxPoint *> *)finalPoints
                          fullRoute:(NSArray<OASRouteSegmentResult *> *)fullRoute
{
    self = [super init];
    if (self)
    {
        _finalPoints = finalPoints;
        _fullRoute = fullRoute;
    }
    return self;
}

@end
