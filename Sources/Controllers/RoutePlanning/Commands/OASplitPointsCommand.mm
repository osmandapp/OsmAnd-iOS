//
//  OASplitPointsCommand.m
//  OsmAnd
//
//  Created by Anna Bibyk on 21.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASplitPointsCommand.h"
#import "OAGPXDocumentPrimitives.h"
#import "OARoadSegmentData.h"
#import "OAMeasurementEditingContext.h"

@implementation OASplitPointsCommand
{
    BOOL _after;
    NSArray<OAWptPt *> *_points;
    NSMutableDictionary<NSArray<OAWptPt *> *, OARoadSegmentData *> *_roadSegmentData;
    NSInteger _pointPosition;
}

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer after:(BOOL)after
{
    self = [super initWithLayer:measurementLayer];
    if (self)
    {
        _after = after;
        OAMeasurementEditingContext *editingCtx = [self getEditingCtx];
        _pointPosition = editingCtx.selectedPointPosition;
        if (_pointPosition == -1)
        {
            _after = YES;
            _pointPosition = (NSInteger) [editingCtx getPoints].count - 1;
        }
    }
    return self;
}

- (BOOL) execute
{
    [self executeCommand];
    return YES;
}

- (void) executeCommand
{
    OAMeasurementEditingContext *editingCtx = [self getEditingCtx];
    _points = [NSArray arrayWithArray:editingCtx.getPoints];
    _roadSegmentData = editingCtx.roadSegmentData;
    [editingCtx splitPoints:_pointPosition after:_after];
    [self refreshMap];
}

- (void) undo
{
    OAMeasurementEditingContext *editingCtx = [self getEditingCtx];
    [editingCtx clearSegments];
    [editingCtx setRoadSegmentData:_roadSegmentData];
    [editingCtx addPoints:_points];
    [self refreshMap];
}

- (void) redo
{
    [self executeCommand];
}

- (EOAMeasurementCommandType)getType
{
    return SPLIT_POINTS;
}

@end
