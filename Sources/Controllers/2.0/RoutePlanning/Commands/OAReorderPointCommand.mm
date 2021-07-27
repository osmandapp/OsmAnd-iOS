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
}

- (instancetype) initWithLayer:(OAMeasurementToolLayer *)measurementLayer from:(NSInteger)from to:(NSInteger)to
{
    self = [super initWithLayer:measurementLayer];
    if (self) {
        _from = from;
        _to = to;
    }
    return self;
}

- (BOOL)execute
{
//    [self.getEditingCtx updateCacheForSnap];
    [self reorder:_from to:_to];
    [self.measurementLayer updateLayer];
    return YES;
}

- (void)undo
{
    [self reorder:_from to:_to];
}

- (void)redo
{
    [self reorder:_to to:_from];
}

- (void)reorder:(NSInteger)from to:(NSInteger)to
{
    OAMeasurementEditingContext *editingCtx = self.getEditingCtx;
    NSMutableArray<OAGpxTrkPt *> *points = [NSMutableArray arrayWithArray:editingCtx.getPoints];
    [points exchangeObjectAtIndex:from withObjectAtIndex:to];
    [editingCtx setPoints:points];
    [editingCtx updateSegmentsForSnap];
    [self.measurementLayer updateLayer];
}

@end
