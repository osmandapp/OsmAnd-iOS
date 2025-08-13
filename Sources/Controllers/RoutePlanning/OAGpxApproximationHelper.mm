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
#import "OAGpxApproximationParams.h"
#import "OAGPXDatabase.h"
#import "OAGpxData.h"

@interface OAGpxApproximationHelper () <OAGpxApproximationProgressDelegate>

@end

@implementation OAGpxApproximationHelper
{
    NSArray<OALocationsHolder *> *_locationsHolders;
    OAGpxApproximator *_currentApproximator;
    OAApplicationMode *_appMode;
    float _distanceThreshold;
}

- (instancetype)initWithLocations:(NSArray<OALocationsHolder *> *)locations initialAppMode:(OAApplicationMode *)appMode initialThreshold:(float)threshold
{
    self = [super init];
    if (self)
    {
        _locationsHolders = [locations copy];
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

- (void)calculateGpxApproximationAsync
{
    if (_currentApproximator != nil)
    {
        [_currentApproximator cancelApproximation];
        _currentApproximator = nil;
    }
    
    if (self.delegate)
        [self.delegate didStartProgress];
    
    NSMutableArray<OAGpxApproximator *> *approximateList = [NSMutableArray array];
    for (OALocationsHolder *locationsHolder in _locationsHolders)
    {
        OAGpxApproximator *approximate = [self getNewGpxApproximator:locationsHolder];
        if (approximate != nil)
            [approximateList addObject:approximate];
    }
    
    NSMutableDictionary<OALocationsHolder *, OAGpxRouteApproximation *> *approximateResult = [[NSMutableDictionary alloc] init];
    if (self.delegate)
        [self.delegate didApproximationStarted];
    
    @try {
        [self approximateMultipleGpxAsync:approximateList withResult:approximateResult];
    } @catch (NSException *exception) {
        NSLog(@"Error: %@, %@", exception.name, exception.reason);
    }
}

- (OAGpxApproximator *)getNewGpxApproximator:(OALocationsHolder *)locationsHolder
{
    OAGpxApproximator *gpxApproximator = [[OAGpxApproximator alloc] initWithApplicationMode:_appMode pointApproximation:_distanceThreshold locationsHolder:locationsHolder];
    gpxApproximator.progressDelegate = self;
    [gpxApproximator setMode:_appMode];
    [gpxApproximator setPointApproximation:_distanceThreshold];
    return gpxApproximator;
}

- (void)approximateMultipleGpxAsync:(NSMutableArray<OAGpxApproximator *> *)approximationsToDo withResult:(NSMutableDictionary<OALocationsHolder *, OAGpxRouteApproximation *> *)approximateResult
{
    if (approximationsToDo.count > 0)
    {
        OAGpxApproximator *gpxApproximator = approximationsToDo.firstObject;
        [approximationsToDo removeObjectAtIndex:0];
        _currentApproximator = gpxApproximator;
        [gpxApproximator calculateGpxApproximation:[[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OAGpxRouteApproximation *__autoreleasing *approxPtr) {
            OAGpxRouteApproximation *strongApprox = (approxPtr && *approxPtr) ? *approxPtr : nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!gpxApproximator.isCancelled)
                {
                    approximateResult[gpxApproximator.locationsHolder] = strongApprox;
                    [self approximateMultipleGpxAsync:approximationsToDo withResult:approximateResult];
                }
            });
            return YES;
        } cancelledFunc:^BOOL {
            return NO;
        }]];
    } else {
        if (approximateResult.count > 0)
        {
            NSArray *pair = [self processApproximationResults:approximateResult];
            if (self.delegate)
                [self.delegate didFinishAllApproximationsWithResults:pair.firstObject points:pair.lastObject];
        }
    }
}

- (OASGpxFile *)approximateGpxSync:(OASGpxFile *)gpxFile params:(OAGpxApproximationParams *)params
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
    NSMutableDictionary<OALocationsHolder *, OAGpxRouteApproximation *> *approximateResult = [[NSMutableDictionary alloc] init];
    for (OALocationsHolder *holder in _locationsHolders)
    {
        OAGpxApproximator *approximator = [self getNewGpxApproximator:holder];
        if (approximator)
        {
            [approximator calculateGpxApproximationSync:[[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OAGpxRouteApproximation *__autoreleasing *approximation) {
                if (approximation && *approximation)
                    approximateResult[holder] = *approximation;
                return YES;
            } cancelledFunc:^BOOL {
                return NO;
            }]];
        }
    }
    
    return [self processApproximationResults:approximateResult];
}

- (NSArray *)processApproximationResults:(NSDictionary<OALocationsHolder *, OAGpxRouteApproximation *> *)approximateResult
{
    NSMutableArray<OAGpxRouteApproximation *> *approximations = [NSMutableArray array];
    NSMutableArray<NSArray<OASWptPt *> *> *points = [NSMutableArray array];
    for (OALocationsHolder *holder in _locationsHolders)
    {
        OAGpxRouteApproximation *approximation = approximateResult[holder];
        if (approximation)
        {
            [approximations addObject:approximation];
            [points addObject:holder.getWptPtList];
        }
    }
    
    return @[approximations, points];
}

- (OASGpxFile *)createApproximatedGpx:(OAMeasurementEditingContext *)context params:(OAGpxApproximationParams *)params approximations:(NSArray<OAGpxRouteApproximation *> *)approximations points:(NSArray<NSArray<OASWptPt *> *> *)points
{
    for (NSUInteger i = 0; i < [approximations count]; i++)
    {
        OAGpxRouteApproximation *approximation = [approximations objectAtIndex:i];
        NSArray<OASWptPt *> *segment = [points objectAtIndex:i];
        [context setPoints:approximation originalPoints:segment mode:_appMode];
    }
    
    return [context exportGpx:context.gpxData.gpxFile.path.lastPathComponent.stringByDeletingPathExtension];
}

- (OAMeasurementEditingContext *)createEditingContext:(OASGpxFile *)gpxFile params:(OAGpxApproximationParams *)params
{
    OAMeasurementEditingContext *editingContext = [[OAMeasurementEditingContext alloc] init];
    editingContext.gpxData = [[OAGpxData alloc] initWithFile:gpxFile];
    editingContext.appMode = [params getAppMode];
    [editingContext addPoints];
    [params setTrackPoints:[editingContext getPointsSegments:YES route:YES]];
    _locationsHolders = params.locationsHolders;
    return editingContext;
}

// MARK: OAGpxApproximationProgressDelegate

- (void)updateProgress:(OAGpxApproximator *)approximator progress:(NSInteger)progress
{
    // UI Thread+
    if (approximator == _currentApproximator)
    {
        if (self.delegate)
            [self.delegate didUpdateProgress:progress];
    }
}

@end
