//
//  OAGpxApproximationParams.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 25.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAGpxApproximationParams.h"
#import "OALocationsHolder.h"
#import "OAApplicationMode.h"

@implementation OAGpxApproximationParams

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _appMode = OAApplicationMode.CAR;
        _distanceThreshold = 50;
        _locationsHolders = [NSMutableArray array];
    }
    
    return self;
}

- (void)setTrackPoints:(NSArray<NSArray<OASWptPt *> *> *)points
{
    NSMutableArray<OALocationsHolder *> *locationsHolders = [NSMutableArray array];
    for (NSArray<OASWptPt *> *segment in points)
    {
        [locationsHolders addObject:[[OALocationsHolder alloc] initWithLocations:segment]];
    }
    
    _locationsHolders = locationsHolders;
}

- (BOOL)updateAppMode:(OAApplicationMode *)newAppMode
{
    if (newAppMode != nil && _appMode != newAppMode)
    {
        _appMode = newAppMode;
        return YES;
    }
    
    return NO;
}

- (BOOL)updateDistanceThreshold:(int)newThreshold
{
    if (_distanceThreshold != newThreshold)
    {
        _distanceThreshold = newThreshold;
        return YES;
    }
    
    return NO;
}

- (OAApplicationMode *)getAppMode
{
    return _appMode;
}

- (int)getDistanceThreshold
{
    return _distanceThreshold;
}

- (NSArray<OALocationsHolder *> *)getLocationsHolders
{
    return _locationsHolders;
}

@end
