//
//  OAGpxApproximationHelper.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 13.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAGpxApproximationHelper.h"

@interface OAGpxApproximationHelper () <OAGpxApproximationProgressDelegate>

@end

@implementation OAGpxApproximationHelper
{
    NSMutableDictionary<OALocationsHolder *, OAGpxRouteApproximation *> *_resultMap;
    NSArray<OALocationsHolder *> *_locationsHolders;
    OAGpxApproximator *_gpxApproximator;
    OAApplicationMode *_appMode;
    float _distanceThreshold;
}

- (instancetype)initWithLocations:(NSArray<OALocationsHolder *> *)locations initialAppMode:(OAApplicationMode *)appMode initialThreshold:(float)threshold
{
    self = [super init];
    if (self)
    {
        _locationsHolders = [locations copy];
        _resultMap = [[NSMutableDictionary alloc] init];
        _appMode = appMode;
        _distanceThreshold = threshold;
    }
    
    return self;
}

- (void)updateAppMode:(OAApplicationMode *)appMode
{
    _appMode = appMode;
}

- (void)updateDistanceThreshold:(float)threshold
{
    _distanceThreshold = threshold;
}

- (BOOL)calculateGpxApproximation:(BOOL)newCalculation
{
    if (newCalculation)
    {
        if (_gpxApproximator != nil)
        {
            [_gpxApproximator cancelApproximation];
            _gpxApproximator = nil;
        }
        
        [_resultMap removeAllObjects];
        if (self.delegate)
            [self.delegate didStartProgress];
    }
    
    OAGpxApproximator *gpxApproximator = nil;
    for (OALocationsHolder *locationsHolder in _locationsHolders)
    {
        if (!_resultMap[locationsHolder])
        {
            gpxApproximator = [self getNewGpxApproximator:locationsHolder];
            break;
        }
    }
    
    if (gpxApproximator != nil)
    {
        _gpxApproximator = gpxApproximator;
        _gpxApproximator.mode = _appMode;
        _gpxApproximator.pointApproximation = _distanceThreshold;
        [self approximateGpx:_gpxApproximator];
        return YES;
    }
    
    return NO;
}

- (OAGpxApproximator *)getNewGpxApproximator:(OALocationsHolder *)locationsHolder
{
    OAGpxApproximator *gpxApproximator = [[OAGpxApproximator alloc] initWithApplicationMode:_appMode pointApproximation:_distanceThreshold locationsHolder:locationsHolder];
    gpxApproximator.progressDelegate = self;
    return gpxApproximator;
}

- (void) approximateGpx:(OAGpxApproximator *)gpxApproximator
{
    if (self.delegate)
        [self.delegate didApproximationStarted];
    
    [gpxApproximator calculateGpxApproximation:[[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OAGpxRouteApproximation *__autoreleasing *object) {
        if (!gpxApproximator.isCancelled)
        {
            if (*object)
                _resultMap[gpxApproximator.locationsHolder] = *object;
            if (![self calculateGpxApproximation:NO])
                [self onApproximationFinished];
        }
        return YES;
    } cancelledFunc:^BOOL {
        return NO;
    }]];
}

- (void)onApproximationFinished
{
    if (self.delegate)
        [self.delegate didFinishProgress];
    
    NSMutableArray<OAGpxRouteApproximation *> *approximations = [NSMutableArray array];
    NSMutableArray<NSArray<OASWptPt *> *> *points = [NSMutableArray array];
    for (OALocationsHolder *locationsHolder in _locationsHolders)
    {
        OAGpxRouteApproximation *approximation = _resultMap[locationsHolder];
        if (approximation != nil)
        {
            [approximations addObject:approximation];
            [points addObject:locationsHolder.getWptPtList];
        }
    }
    
    if (self.delegate)
        [self.delegate didFinishAllApproximationsWithResults:approximations points:points];
}

// MARK: OAGpxApproximationProgressDelegate

- (void)start:(OAGpxApproximator *)approximator
{
}

- (void)updateProgress:(OAGpxApproximator *)approximator progress:(NSInteger)progress
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (approximator == _gpxApproximator)
        {
            float partSize = 100. / _locationsHolders.count;
            float p = _resultMap.count * partSize + (progress / 100.) * partSize;
            if (self.delegate)
                [self.delegate didUpdateProgress:(int)p];
        }
    });
}

- (void)finish:(OAGpxApproximator *)approximator
{
}

@end
