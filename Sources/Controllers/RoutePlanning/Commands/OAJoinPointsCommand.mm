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
#import <OsmAndShared/OsmAndShared.h>

@implementation OAJoinPointsCommand
{
    NSArray<OASWptPt *> *_points;
    NSDictionary<NSArray<OASWptPt *> *, OARoadSegmentData *> *_roadSegmentData;
    OASWptPt *_gapPoint;
    NSString *_gapPointProfile;
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
    _roadSegmentData = [ctx.roadSegmentData copy];
    NSInteger gapIndex = -1;
    if ([ctx isFirstPointSelected:_pointPosition outer:NO])
        gapIndex = _pointPosition - 1;
    else if ([ctx isLastPointSelected:_pointPosition outer:NO])
        gapIndex = _pointPosition;
    _gapPoint = gapIndex >= 0 && gapIndex < _points.count ? _points[gapIndex] : nil;
    _gapPointProfile = [_gapPoint.getProfileType copy];
    [ctx joinPoints:_pointPosition];
    [self refreshMap];
}

- (void) undo
{
    OAMeasurementEditingContext *ctx = [self getEditingCtx];
    [ctx clearSegments];
    if (_gapPointProfile != nil)
        [_gapPoint setProfileTypeProfileType:_gapPointProfile];
    else
        [_gapPoint removeProfileType];
    [ctx setRoadSegmentData:[_roadSegmentData mutableCopy]];
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
