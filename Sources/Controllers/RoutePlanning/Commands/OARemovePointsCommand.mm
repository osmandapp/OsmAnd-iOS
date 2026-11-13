//
//  OARemovePointsCommand.mm
//  OsmAnd Maps
//
//  Created by OsmAnd on 10.10.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OARemovePointsCommand.h"
#import <OsmAndShared/OsmAndShared.h>
#import "OAMeasurementToolLayer.h"
#import "OAMeasurementEditingContext.h"
#import "OAApplicationMode.h"

@implementation OARemovePointsCommand
{
    NSArray<NSNumber *> *_positions; // descending
    NSMutableArray<OASWptPt *> *_points; // removed, in _positions order
    NSMutableArray *_previousPointProfiles; // NSString or NSNull, in _positions order
    OAApplicationMode *_previousGroupMode;
    OAApplicationMode *_appMode;
}

- (instancetype)initWithLayer:(OAMeasurementToolLayer *)measurementLayer
                    positions:(NSArray<NSNumber *> *)positions
{
    return [self initWithLayer:measurementLayer positions:positions previousGroupMode:nil];
}

- (instancetype)initWithLayer:(OAMeasurementToolLayer *)measurementLayer
                    positions:(NSArray<NSNumber *> *)positions
            previousGroupMode:(OAApplicationMode *)previousGroupMode
{
    self = [super initWithLayer:measurementLayer];
    if (self)
    {
        _positions = [[NSSet setWithArray:positions].allObjects sortedArrayUsingComparator:^NSComparisonResult(NSNumber *a, NSNumber *b) {
            return [b compare:a];
        }];
        _previousGroupMode = previousGroupMode;
    }
    return self;
}

- (BOOL)execute
{
    NSInteger count = self.getEditingCtx.getPoints.count;
    if (_positions.count == 0 || _positions.lastObject.integerValue < 0 || _positions.firstObject.integerValue >= count)
        return NO;
    _appMode = self.getEditingCtx.appMode;
    [self removePoints];
    return YES;
}

- (void)undo
{
    OAMeasurementEditingContext *ctx = self.getEditingCtx;
    NSMutableArray<OASWptPt *> *points = [NSMutableArray arrayWithArray:ctx.getPoints];
    for (NSInteger i = (NSInteger)_positions.count - 1; i >= 0; i--)
    {
        NSInteger position = _positions[i].integerValue;
        if (position > 0 && position <= (NSInteger)points.count)
        {
            id previousPointProfile = _previousPointProfiles[i];
            if (previousPointProfile != NSNull.null)
                [points[position - 1] setProfileTypeProfileType:previousPointProfile];
            else
                [points[position - 1] removeProfileType];
        }
        [points insertObject:_points[i] atIndex:MIN(position, (NSInteger)points.count)];
    }
    [ctx setPoints:points];
    ctx.appMode = _appMode;
    [ctx updateSegmentsForSnap:NO];
    [self.measurementLayer updateLayer];
}

- (void)redo
{
    [self removePoints];
}

// same steps as OARemovePointCommand per point, with one segment and layer update
- (void)removePoints
{
    OAMeasurementEditingContext *ctx = self.getEditingCtx;
    NSMutableArray<OASWptPt *> *points = [NSMutableArray arrayWithArray:ctx.getPoints];
    _points = [NSMutableArray arrayWithCapacity:_positions.count];
    _previousPointProfiles = [NSMutableArray arrayWithCapacity:_positions.count];
    for (NSNumber *positionNumber in _positions)
    {
        NSInteger position = positionNumber.integerValue;
        OASWptPt *point = points[position];
        OASWptPt *previousPoint = position > 0 ? points[position - 1] : nil;
        [_previousPointProfiles addObject:[previousPoint.getProfileType copy] ?: NSNull.null];
        if (point.isGap && previousPoint && !previousPoint.isGap)
            [previousPoint setGap];
        [points removeObjectAtIndex:position];
        [_points addObject:point];
    }
    NSInteger previousIndex = _positions.lastObject.integerValue - 1;
    if (_previousGroupMode && previousIndex >= 0 && !points[previousIndex].isGap)
    {
        if (_previousGroupMode == OAApplicationMode.DEFAULT)
            [points[previousIndex] removeProfileType];
        else
            [points[previousIndex] setProfileTypeProfileType:_previousGroupMode.stringKey];
    }
    [ctx setPoints:points];
    OASWptPt *lastPoint = ctx.getAllPoints.lastObject;
    if (lastPoint && !lastPoint.isGap)
        ctx.appMode = [OAApplicationMode valueOfStringKey:lastPoint.getProfileType def:OAApplicationMode.DEFAULT];
    [ctx updateSegmentsForSnap:NO];
    [self.measurementLayer updateLayer];
}

@end
