//
//  OAMovePointCommand.m
//  OsmAnd
//
//  Created by Paul on 03.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMovePointCommand.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAMeasurementEditingContext.h"
#import "OAMeasurementToolLayer.h"

@implementation OAMovePointCommand
{
    OASWptPt *_oldPoint;
    OASWptPt *_newPoint;
    NSInteger _position;
}

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer oldPoint:(OASWptPt *)oldPoint newPoint:(OASWptPt *)newPoint position:(NSInteger)position
{
    self = [super initWithLayer:measurementLayer];
    if (self) {
        _oldPoint = oldPoint;
        _newPoint = newPoint;
        _position = position;
    }
    return self;
}

- (BOOL)execute
{
    return YES;
}

- (void) undo
{
    [[self getEditingCtx] removePoint:_position updateSnapToRoad:NO];
    [[self getEditingCtx] addPoint:_position pt:_oldPoint];
    [self.measurementLayer updateLayer];
}

- (void) redo
{
    [[self getEditingCtx] removePoint:_position updateSnapToRoad:NO];
    [[self getEditingCtx] addPoint:_position pt:_newPoint];
    [self.measurementLayer updateLayer];
}

- (EOAMeasurementCommandType)getType
{
    return MOVE_POINT;
}

@end
