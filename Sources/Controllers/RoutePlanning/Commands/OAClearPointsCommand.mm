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
#import "OAApplicationMode.h"

@implementation OAClearPointsCommand
{
    NSArray<OASWptPt *> *_points;
    NSDictionary<NSArray<OASWptPt *> *, OARoadSegmentData *> *_roadSegmentData;
    EOAClearPointsMode _clearMode;
    NSInteger _pointPosition;
    OAApplicationMode *_appMode;
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
    OAMeasurementEditingContext *ctx = [self getEditingCtx];
    if (ctx == nil)
        return NO;
    _pointPosition = ctx.selectedPointPosition;
    if (_clearMode != EOAClearPointsModeAll
        && (_pointPosition < 0 || _pointPosition >= ctx.getAllPoints.count))
        return NO;
    _points = [ctx.getAllPoints copy];
    _roadSegmentData = [ctx.roadSegmentData copy];
    _appMode = ctx.appMode;
    [self executeCommand];
    return YES;
}

- (void) executeCommand
{
    OAMeasurementEditingContext *ctx = [self getEditingCtx];
    switch (_clearMode) {
        case EOAClearPointsModeAll:
        {
            [ctx clearPoints];
            [ctx clearSegments];
            [self.measurementLayer resetLayer];
            break;
        }
        case EOAClearPointsModeBefore:
        {
            [ctx trimBefore:_pointPosition];
            [ctx splitSegments:ctx.getAllPoints.count];
            [self.measurementLayer updateLayer];
            break;
        }
        case EOAClearPointsModeAfter:
        {
            [ctx trimAfter:_pointPosition];
            [ctx splitSegments:ctx.getAllPoints.count];
            OASWptPt *lastPoint = ctx.getAllPoints.lastObject;
            if (lastPoint && !lastPoint.isGap)
                ctx.appMode = [OAApplicationMode valueOfStringKey:lastPoint.getProfileType def:OAApplicationMode.DEFAULT];
            [self.measurementLayer updateLayer];
            break;
        }
    }
}

- (void) undo
{
    OAMeasurementEditingContext *ctx = [self getEditingCtx];
    [ctx clearSegments];
    ctx.roadSegmentData = [_roadSegmentData mutableCopy];
    ctx.appMode = _appMode;
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
