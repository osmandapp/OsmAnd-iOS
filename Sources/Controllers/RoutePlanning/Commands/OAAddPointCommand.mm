//
//  OAAddPointCommand.m
//  OsmAnd
//
//  Created by Paul on 24.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAAddPointCommand.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAMeasurementToolLayer.h"
#import "OAMeasurementEditingContext.h"

@implementation OAAddPointCommand
{
    NSInteger _position;
    OAWptPt *_point;
    NSString *_prevPointProfile;
    BOOL _center;
    BOOL _addPointBefore;
}

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer center:(BOOL)center
{
    self = [super initWithLayer:measurementLayer];
    if (self) {
        [self commonInit:nil center:center];
    }
    return self;
}

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer coordinate:(CLLocation *)latLon
{
    self = [super initWithLayer:measurementLayer];
    if (self) {
        [self commonInit:latLon center:NO];
    }
    return self;
}

- (void) commonInit:(CLLocation *)latLon center:(BOOL)center
{
    OAMeasurementEditingContext *ctx = self.getEditingCtx;
    if (latLon != nil)
    {
        _point = [[OAWptPt alloc] init];
        [_point setPosition:latLon.coordinate];
    }
    _center = center;
    _position = ctx.getPointsCount;
}


- (BOOL) execute
{
    OAMeasurementEditingContext *ctx = self.getEditingCtx;
    _addPointBefore = ctx.addPointMode == EOAAddPointModeBefore;
    NSArray<OAWptPt *> *points = ctx.getPoints;
    if (points.count > 0)
    {
        OAWptPt *prevPt = points.lastObject;
        _prevPointProfile = prevPt.getProfileType;
    }
    if (_point)
    {
        [ctx addPoint:_point mode:_addPointBefore ? EOAAddPointModeBefore : EOAAddPointModeAfter];
        [self.measurementLayer moveMapToPoint:_position];
    }
    else if (_center)
    {
        _point = [self.measurementLayer addCenterPoint:_addPointBefore];
    }
    else
    {
        _point = [self.measurementLayer addPoint:_addPointBefore];
    }
    [self refreshMap];
    return _point != nil;
}

- (void) undo
{
    OAMeasurementEditingContext *ctx = self.getEditingCtx;
    if (_position > 0) {
        OAWptPt *prevPt = ctx.getPoints[_position - 1];
        if (_prevPointProfile != nil)
        {
            [prevPt setProfileType:_prevPointProfile];
        }
        else
        {
            [prevPt removeProfileType];
        }
    }
    [ctx removePoint:_position updateSnapToRoad:YES];
    [self refreshMap];
}

- (void) redo
{
    [self.getEditingCtx addPoint:_position point:_point mode:_addPointBefore ? EOAAddPointModeBefore : EOAAddPointModeAfter];
    [self.measurementLayer updateLayer];
    [self.measurementLayer moveMapToPoint:_position];
}

- (EOAMeasurementCommandType) getType
{
    return ADD_POINT;
}

@end
