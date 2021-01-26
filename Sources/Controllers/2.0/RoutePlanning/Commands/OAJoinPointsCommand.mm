//
//  OAJoinPointsCommand.m
//  OsmAnd
//
//  Created by Anna Bibyk on 21.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAJoinPointsCommand.h"
#import "OAGPXDocumentPrimitives.h"
#import "OARoadSegmentData.h"
#import "OAMeasurementEditingContext.h"

@implementation OAJoinPointsCommand
{
    NSArray<OAGpxTrkPt *> *_points;
    NSMutableDictionary<NSArray<OAGpxTrkPt *> *, OARoadSegmentData *> *_roadSegmentData;
    NSInteger _pointPosition;
}

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer
{
    self = [super initWithLayer:measurementLayer];
    return self;
}

- (BOOL) execute
{
    _pointPosition = [self getEditingCtx].selectedPointPosition;
    [self executeCommand];
    return YES;
}

- (void) executeCommand
{
    OAMeasurementEditingContext *ctx = [self getEditingCtx];
    _points = [NSArray arrayWithArray:ctx.getPoints];
    _roadSegmentData = ctx.roadSegmentData;
    [ctx joinPoints:_pointPosition];
    [self refreshMap];
}

- (void) undo
{
    OAMeasurementEditingContext *ctx = [self getEditingCtx];
    [ctx clearSegments];
    [ctx setRoadSegmentData:_roadSegmentData];
    [ctx addPoints:_points];
    [self refreshMap];
}

- (void) redo
{
    [self executeCommand];
}

- (EOAMeasurementCommandType)getType
{
    return JOIN_POINTS;
}

@end
