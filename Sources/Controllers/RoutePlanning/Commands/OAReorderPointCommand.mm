//
//  OAReorderPointCommand.m
//  OsmAnd
//
//  Created by Paul on 28.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAReorderPointCommand.h"
#import "OAMeasurementToolLayer.h"
#import "OAMeasurementEditingContext.h"
#import "OAGPXDocumentPrimitives.h"

@implementation OAReorderPointCommand
{
    NSInteger _from;
    NSInteger _to;
    BOOL _move;
}

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer from:(NSInteger)from to:(NSInteger)to
{
    return [self initWithLayer:measurementLayer from:from to:to move:NO];
}

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer from:(NSInteger)from to:(NSInteger)to move:(BOOL)move
{
    self = [super initWithLayer:measurementLayer];
    if (self) {
        _from = from;
        _to = to;
        _move = move;
    }
    return self;
}

- (BOOL)execute
{
    [self reorder:_from to:_to];
    [self.measurementLayer updateLayer];
    return YES;
}

- (void)undo
{
    if (_move)
        [self reorder:_to to:_from];
    else
        [self reorder:_from to:_to];
}

- (void)redo
{
    if (_move)
        [self reorder:_from to:_to];
    else
        [self reorder:_to to:_from];
}

- (void)reorder:(NSInteger)from to:(NSInteger)to
{
    OAMeasurementEditingContext *editingCtx = self.getEditingCtx;
    NSMutableArray<OASWptPt *> *points = [NSMutableArray arrayWithArray:editingCtx.getPoints];
    if (from < 0 || to < 0 || from >= (NSInteger) points.count || to >= (NSInteger) points.count)
        return;
    if (_move)
    {
        OASWptPt *point = points[from];
        [points removeObjectAtIndex:from];
        [points insertObject:point atIndex:to];
    }
    else
    {
        [points exchangeObjectAtIndex:from withObjectAtIndex:to];
    }
    [editingCtx setPoints:points];
    [editingCtx updateSegmentsForSnap];
    [self.measurementLayer updateLayer];
}

@end
