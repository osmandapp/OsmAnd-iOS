//
//  OAGpxApproximationHelper.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 13.01.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAGpxApproximationHelper.h"
#import "OAMeasurementEditingContext.h"
#import "OAGpxRouteApproximation.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAGpxApproximator.h"
#import "OALocationsHolder.h"
#import "OAApplicationMode.h"

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

- (OASGpxFile *)approximateGpxSync:(OASGpxFile *)gpxFile params:(OAGpxApproximator *)params
{
    OAMeasurementEditingContext *context = [self createEditingContext:gpxFile params:params];
    NSArray *pair = [self calculateGpxApproximationSync];
    OASGpxFile *approximatedGpx = [self createApproximatedGpx:context params:params approximations:pair.firstObject points:pair.lastObject];
    if (approximatedGpx != nil && [approximatedGpx isAttachedToRoads])
        return approximatedGpx;
    
    return gpxFile;
}

- (NSArray *)calculateGpxApproximationSync
{
    for (OALocationsHolder *holder in _locationsHolders)
    {
        OAGpxApproximator *approximator = [self getNewGpxApproximator:holder];
        if (approximator)
        {
            [approximator calculateGpxApproximationSync:[[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OAGpxRouteApproximation *__autoreleasing *approximation) {
                if (approximation && *approximation)
                    _resultMap[holder] = *approximation;
                return YES;
            } cancelledFunc:^BOOL {
                return NO;
            }]];
        }
    }
    
    return [self processApproximationResults];
}

- (NSArray *)processApproximationResults
{
    NSMutableArray<OAGpxRouteApproximation *> *approximations = [NSMutableArray array];
    NSMutableArray<NSArray<OASWptPt *> *> *points = [NSMutableArray array];
    for (OALocationsHolder *holder in _locationsHolders)
    {
        OAGpxRouteApproximation *approximation = _resultMap[holder];
        if (approximation)
        {
            [approximations addObject:approximation];
            [points addObject:holder.getWptPtList];
        }
    }
    
    return @[approximations, points];
}

- (OASGpxFile *)createApproximatedGpx:(OAMeasurementEditingContext *)context params:(OAGpxApproximator *)params approximations:(NSArray<OAGpxRouteApproximation *> *)approximations points:(NSArray<NSArray<OASWptPt *> *> *)points
{
    for (NSUInteger i = 0; i < [approximations count]; i++)
    {
        OAGpxRouteApproximation *approximation = [approximations objectAtIndex:i];
        NSArray<OASWptPt *> *segment = [points objectAtIndex:i];
        [context setPoints:approximation originalPoints:segment mode:_appMode];
    }
    
    return [context exportGpx:context.gpxData.gpxFile.path.lastPathComponent.stringByDeletingPathExtension];
}

- (OAMeasurementEditingContext *)createEditingContext:(OASGpxFile *)gpxFile params:(OAGpxApproximator *)params
{
    OAMeasurementEditingContext *editingContext = [[OAMeasurementEditingContext alloc] init];
    editingContext.gpxData = [[OAGpxData alloc] initWithFile:gpxFile];
    editingContext.appMode = params.mode;
    [editingContext addPoints];
    [params setTrackPoints:[editingContext getPointsSegments:YES route:YES]];
    _locationsHolders = params.locationsHolders;
    return editingContext;
}

// MARK: OAGpxApproximationProgressDelegate

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

@end
