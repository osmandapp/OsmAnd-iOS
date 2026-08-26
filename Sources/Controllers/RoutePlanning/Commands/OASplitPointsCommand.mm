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
    NSArray<OASWptPt *> *_points;
    NSMutableDictionary<NSArray<OASWptPt *> *, OARoadSegmentData *> *_roadSegmentData;
    NSInteger _pointPosition;
    NSInteger _splitPointPosition;
    NSString *_pointProfileType;
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
        _splitPointPosition = _after ? _pointPosition : _pointPosition - 1;
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
    _points = [editingCtx.getPoints copy];
    _roadSegmentData = [editingCtx.roadSegmentData mutableCopy];
    _splitPointPosition = _after ? _pointPosition : _pointPosition - 1;
    _pointProfileType = _splitPointPosition >= 0 && _splitPointPosition < (NSInteger)_points.count
        ? [_points[_splitPointPosition].getProfileType copy]
        : nil;
    [editingCtx splitPoints:_pointPosition after:_after];
    [self refreshMap];
}

- (void) undo
{
    OAMeasurementEditingContext *editingCtx = [self getEditingCtx];
    [editingCtx clearSegments];
    if (_splitPointPosition >= 0 && _splitPointPosition < (NSInteger)_points.count)
    {
        OASWptPt *splitPoint = _points[_splitPointPosition];
        if (_pointProfileType != nil)
            [splitPoint setProfileTypeProfileType:_pointProfileType];
        else
            [splitPoint removeProfileType];
    }
    [editingCtx setRoadSegmentData:[_roadSegmentData mutableCopy]];
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
