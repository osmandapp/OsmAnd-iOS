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
    OAGpxTrkPt *_point;
    BOOL _center;
}

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer center:(BOOL)center
{
    self = [super initWithLayer:measurementLayer];
    if (self) {
        [self commonInit:measurementLayer location:nil center:center];
    }
    return self;
}

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer coordinate:(CLLocation *)latLon
{
    self = [super initWithLayer:measurementLayer];
    if (self) {
        [self commonInit:measurementLayer location:latLon center:NO];
    }
    return self;
}

- (void) commonInit:(OAMeasurementToolLayer *)measurementLayer location:(CLLocation *)latLon center:(BOOL)center
{
    if (latLon != nil)
    {
        _point = [[OAGpxTrkPt alloc] init];
        [_point setPosition:latLon.coordinate];
//        OAApplicationMode *appMode = measurementLayer.editingCtx.appMode;
//        if (appMode != MeasurementEditingContext.DEFAULT_APP_MODE) {
//            point.setProfileType(appMode.getStringKey());
//        }
    }
    _center = center;
    _position = measurementLayer.editingCtx.getPointsCount;
}


- (BOOL) execute
{
    if (_point != nil)
    {
        [[self getEditingCtx] addPoint:_point];
//        [self.measurementLayer moveMapToPoint:position];
    }
    else if (_center)
    {
        _point = [self.measurementLayer addCenterPoint];
    }
//    else
//    {
//        _point = [self.measurementLayer addPoint];
//    }
    // Skip unnecessary refresh if adding more points
    if (self.getEditingCtx.addPointMode == EOAAddPointModeUndefined)
        [self.measurementLayer updateLayer];
    return _point != nil;
}

- (void) undo
{
    [[self getEditingCtx] removePoint:_position updateSnapToRoad:NO];
    [self.measurementLayer updateLayer];
}

- (void) redo
{
    [[self getEditingCtx] addPoint:_position pt:_point];
    [self.measurementLayer updateLayer];
}

- (EOAMeasurementCommandType) getType
{
    return ADD_POINT;
}

@end
