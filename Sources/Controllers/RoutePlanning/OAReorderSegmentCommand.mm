//
//  OAReorderSegmentCommand.mm
//  OsmAnd Maps
//
//  Created by OsmAnd on 07.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAReorderSegmentCommand.h"
#import "OAMeasurementToolLayer.h"
#import "OAMeasurementEditingContext.h"
#import "OAGPXDocumentPrimitives.h"

@implementation OAReorderSegmentCommand
{
    NSInteger _from;
    NSInteger _to;
}

- (instancetype)initWithLayer:(OAMeasurementToolLayer *)measurementLayer
                         from:(NSInteger)from
                           to:(NSInteger)to
{
    self = [super initWithLayer:measurementLayer];
    if (self)
    {
        _from = from;
        _to = to;
    }
    return self;
}

- (BOOL)execute
{
    [self applyReorderFrom:_from to:_to];
    return YES;
}

- (void)undo
{
    [self applyReorderFrom:_to to:_from];
}

- (void)redo
{
    [self applyReorderFrom:_from to:_to];
}

- (void)applyReorderFrom:(NSInteger)from to:(NSInteger)to
{
    OAMeasurementEditingContext *editingCtx = self.getEditingCtx;
    NSMutableArray<OASWptPt *> *allPoints = [NSMutableArray arrayWithArray:editingCtx.getPoints];
    NSInteger totalPoints = (NSInteger)allPoints.count;
    if (totalPoints == 0)
        return;

    NSMutableArray<NSMutableArray<OASWptPt *> *> *segments = [NSMutableArray array];
    NSMutableArray<OASWptPt *> *current = [NSMutableArray array];
    for (NSInteger i = 0; i < totalPoints; i++)
    {
        OASWptPt *pt = allPoints[i];
        [current addObject:pt];
        if (pt.isGap || i == totalPoints - 1)
        {
            [segments addObject:current];
            current = [NSMutableArray array];
        }
    }

    NSInteger segCount = (NSInteger)segments.count;
    if (from < 0 || from >= segCount || to < 0 || to >= segCount || from == to)
        return;

    NSMutableArray<OASWptPt *> *segToMove = segments[from];
    [segments removeObjectAtIndex:from];
    [segments insertObject:segToMove atIndex:to];

    NSInteger lastIdx = segCount - 1;
    for (NSInteger i = 0; i < segCount; i++)
    {
        OASWptPt *lastPt = segments[i].lastObject;
        if (i < lastIdx)
        {
            if (!lastPt.isGap)
                [lastPt setGap];
        }
        else
        {
            if (lastPt.isGap)
                [lastPt removeProfileType];
        }
    }

    NSMutableArray<OASWptPt *> *newPoints = [NSMutableArray array];
    for (NSMutableArray<OASWptPt *> *seg in segments)
        [newPoints addObjectsFromArray:seg];

    [editingCtx setPoints:newPoints];
    [editingCtx updateSegmentsForSnap];
    [self.measurementLayer updateLayer];
}

@end
