//
//  OAClearPointsCommand.m
//  OsmAnd
//
//  Created by Paul on 05.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAClearPointsCommand.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAMeasurementEditingContext.h"
#import "OAMeasurementToolLayer.h"
#import "OARoadSegmentData.h"

@implementation OAClearPointsCommand
{
    NSArray<OAGpxTrkPt *> *_points;
    NSMutableDictionary<NSArray<OAGpxTrkPt *> *, OARoadSegmentData *> *_roadSegmentData;
    EOAClearPointsMode _clearMode;
    NSInteger _pointPosition;
}

- (instancetype) initWithMeasurementLayer:(OAMeasurementToolLayer *)layer mode:(EOAClearPointsMode)mode
{
    self = [super initWithLayer:layer];
    if (self) {
        _clearMode = mode;
    }
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
    switch (_clearMode) {
        case EOAClearPointsModeAll:
        {
            [ctx clearPoints];
            [ctx clearSegments];
            break;
        }
        case EOAClearPointsModeBefore:
        {
            [ctx trimBefore:_pointPosition];
            break;
        }
        case EOAClearPointsModeAfter:
        {
            [ctx trimAfter:_pointPosition];
        }
    }
    [self.measurementLayer updateLayer];
}

- (void) undo
{
    OAMeasurementEditingContext *ctx = [self getEditingCtx];
    [ctx clearSegments];
    ctx.roadSegmentData = _roadSegmentData;
    [ctx addPoints:_points];
    [self.measurementLayer updateLayer];
}

- (void) redo
{
    [self executeCommand];
}

- (EOAMeasurementCommandType)getType
{
    return CLEAR_POINTS;
}

@end
