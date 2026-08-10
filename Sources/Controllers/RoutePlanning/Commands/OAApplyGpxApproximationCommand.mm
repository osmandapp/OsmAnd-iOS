//
//  OAApplyGpxApproximationCommand.m
//  OsmAnd Maps
//
//  Created by Paul on 17.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAApplyGpxApproximationCommand.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGpxRouteApproximation.h"
#import "OARoadSegmentData.h"
#import "OAMeasurementEditingContext.h"

@interface OAApplyGpxApproximationCommand ()

@property (nonatomic) NSArray<OAGpxRouteApproximation *> *approximations;
@property (nonatomic) OAApplicationMode *mode;

@end

@implementation OAApplyGpxApproximationCommand
{
    NSArray<OASWptPt *> *_points;
    NSDictionary<NSArray<OASWptPt *> *, OARoadSegmentData *> *_roadSegmentData;
}

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer approximations:(NSArray<OAGpxRouteApproximation *> *)approximations segmentPointsList:(NSArray<NSArray<OASWptPt *> *> *)segmentPointsList appMode:(OAApplicationMode *)appMode
{
    self = [super initWithLayer:measurementLayer];
    if (self) {
        _approximations = approximations;
        _originalSegmentPointsList = [NSArray arrayWithArray:segmentPointsList];
        _mode = appMode;
    }
    return self;
}

- (EOAMeasurementCommandType)getType
{
    return APPROXIMATE_POINTS;
}

- (BOOL) execute
{
    OAMeasurementEditingContext *ctx = self.getEditingCtx;
    _points = [NSArray arrayWithArray:ctx.getPoints];
    _roadSegmentData = [ctx.roadSegmentData copy];
    [self applyAllApproximations];
    [self refreshMap];
    return true;
}

- (BOOL) update:(id<OACommand>)command
{
    if ([command isKindOfClass:self.class])
    {
        OAApplyGpxApproximationCommand *approxCommand = (OAApplyGpxApproximationCommand *) command;
        _approximations = approxCommand.approximations;
        _mode = approxCommand.mode;
        [self applyAllApproximations];
        [self refreshMap];
        return YES;
    }
    return NO;
}

- (void) undo
{
    OAMeasurementEditingContext *ctx = self.getEditingCtx;
    [ctx cancelSnapToRoad];
    [ctx resetAppMode];
    [ctx beginBatchPointUpdates];
    [self restoreOriginalState];
    [ctx endBatchPointUpdates];
    [self refreshMap];
}

- (void) redo
{
    [self applyAllApproximations];
    [self refreshMap];
}

- (void)restoreOriginalState
{
    OAMeasurementEditingContext *ctx = self.getEditingCtx;
    [ctx clearSegments];
    ctx.roadSegmentData = [NSMutableDictionary dictionaryWithDictionary:_roadSegmentData];
    [ctx setPoints:_points];
}

- (void)applyAllApproximations
{
    OAMeasurementEditingContext *ctx = self.getEditingCtx;
    [ctx cancelSnapToRoad];
    [ctx beginBatchPointUpdates];
    [self restoreOriginalState];
    ctx.appMode = _mode;
    NSInteger count = MIN(_approximations.count, _originalSegmentPointsList.count);
    for (NSInteger i = 0; i < count; i++)
    {
        OAGpxRouteApproximation *approximation = _approximations[i];
        NSArray<OASWptPt *> *segmentPoints = _originalSegmentPointsList[i];
        NSArray<OASWptPt *> *newSegmentPoints = [ctx setPoints:approximation originalPoints:segmentPoints mode:_mode];

        if (newSegmentPoints != nil && newSegmentPoints.count > 0)
        {
            int64_t initialTimestamp = segmentPoints.count == 0
            ? 0
            : [[segmentPoints firstObject] time];
            [[newSegmentPoints firstObject] setTime:initialTimestamp];
        }
    }
    [ctx endBatchPointUpdates];
}

@end
