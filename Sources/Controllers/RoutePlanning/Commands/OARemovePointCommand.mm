//
//  OARemovePointCommand.m
//  OsmAnd
//
//  Created by Paul on 28.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARemovePointCommand.h"
#import <OsmAndShared/OsmAndShared.h>
#import "OAMeasurementToolLayer.h"
#import "OAMeasurementEditingContext.h"
#import "OAApplicationMode.h"

@implementation OARemovePointCommand
{
    NSInteger _position;
    OASWptPt *_point;
    NSString *_previousPointProfile;
    OAApplicationMode *_appMode;
}

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer position:(NSInteger)position
{
    self = [super initWithLayer:measurementLayer];
    if (self) {
        _position = position;
    }
    return self;
}

- (BOOL)execute
{
    OAMeasurementEditingContext *ctx = self.getEditingCtx;
    NSArray<OASWptPt *> *points = ctx.getPoints;
    if (_position < 0 || _position >= points.count)
        return NO;
    if (_position > 0)
        _previousPointProfile = [points[_position - 1].getProfileType copy];
    _appMode = ctx.appMode;
    [self removePoint];
    return YES;
}

- (void)undo
{
    OAMeasurementEditingContext *ctx = self.getEditingCtx;
    if (_position > 0 && _position <= ctx.getPointsCount)
    {
        OASWptPt *previousPoint = ctx.getPoints[_position - 1];
        if (_previousPointProfile != nil)
            [previousPoint setProfileTypeProfileType:_previousPointProfile];
        else
            [previousPoint removeProfileType];
    }
    ctx.appMode = _appMode;
    [ctx addPoint:_position pt:_point];
    [self.measurementLayer updateLayer];
    [self.measurementLayer moveMapToPoint:_position];
}

- (void)redo
{
    [self removePoint];
}

- (void)removePoint
{
    OAMeasurementEditingContext *ctx = self.getEditingCtx;
    _point = [ctx removePoint:_position updateSnapToRoad:YES];
    OASWptPt *lastPoint = ctx.getAllPoints.lastObject;
    if (lastPoint && !lastPoint.isGap)
        ctx.appMode = [OAApplicationMode valueOfStringKey:lastPoint.getProfileType def:OAApplicationMode.DEFAULT];
    [self.measurementLayer updateLayer];
}

@end
