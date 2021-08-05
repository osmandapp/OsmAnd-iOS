//
//  OARemovePointCommand.m
//  OsmAnd
//
//  Created by Paul on 28.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARemovePointCommand.h"
#import "OAMeasurementToolLayer.h"
#import "OAMeasurementEditingContext.h"

@implementation OARemovePointCommand
{
    NSInteger _position;
    OAGpxTrkPt *_point;
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
    _point = [self.getEditingCtx removePoint:_position updateSnapToRoad:YES];
    [self.measurementLayer updateLayer];
    return YES;
}

- (void)undo
{
    [self.getEditingCtx addPoint:_position pt:_point];
    [self.measurementLayer updateLayer];
    [self.measurementLayer moveMapToPoint:_position];
}

- (void)redo
{
    [self.getEditingCtx removePoint:_position updateSnapToRoad:YES];
    [self.measurementLayer updateLayer];
}

@end
