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
    NSArray<OAGpxTrkPt *> *_points;
    NSDictionary<NSArray<OAGpxTrkPt *> *, OARoadSegmentData *> *_roadSegmentData;
    NSMutableArray<NSArray<OAGpxTrkPt *> *> *_segmentPointsList;
}

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer approximations:(NSArray<OAGpxRouteApproximation *> *)approximations segmentPointsList:(NSArray<NSArray<OAGpxTrkPt *> *> *)segmentPointsList appMode:(OAApplicationMode *)appMode
{
    self = [super initWithLayer:measurementLayer];
    if (self) {
        _approximations = approximations;
        _segmentPointsList = [NSMutableArray arrayWithArray:segmentPointsList];
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
    _roadSegmentData = ctx.roadSegmentData;
    [self applyApproximation];
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
        [self applyApproximation];
        [self refreshMap];
        return YES;
    }
    return NO;
}

- (void) undo
{
    OAMeasurementEditingContext *ctx = self.getEditingCtx;
    [ctx resetAppMode];
    [ctx clearSegments];
    ctx.roadSegmentData = [NSMutableDictionary dictionaryWithDictionary:_roadSegmentData];
    [ctx addPoints:_points];
    _segmentPointsList = [NSMutableArray arrayWithCapacity:_originalSegmentPointsList.count];
    // Populate with empty data
    NSArray<OAGpxTrkPt *> *emptyArr = [NSArray array];
    for (NSInteger i = 0; i < _originalSegmentPointsList.count; i++)
        [_segmentPointsList addObject:emptyArr];
    [self refreshMap];
}


- (void) redo
{
    [self applyApproximation];
    [self refreshMap];
}

- (void) applyApproximation
{
    OAMeasurementEditingContext *ctx = self.getEditingCtx;
    ctx.appMode = _mode;
    for (NSInteger i = 0; i < _approximations.count; i++)
    {
        OAGpxRouteApproximation *approximation = _approximations[i];
        NSArray<OAGpxTrkPt *> *segmentPoints = _segmentPointsList[i];
        NSArray<OAGpxTrkPt *> *newSegmentPoints = [ctx setPoints:approximation originalPoints:segmentPoints mode:_mode];
        if (newSegmentPoints != nil)
            _segmentPointsList[i] = newSegmentPoints;
    }
}

@end
