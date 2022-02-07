//
//  OAReversePointsCommand.m
//  OsmAnd
//
//  Created by Paul on 19.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAReversePointsCommand.h"
#import "OAGPXDocumentPrimitives.h"
#import "OARoadSegmentData.h"
#import "OAMeasurementEditingContext.h"
#import "OAApplicationMode.h"

@implementation OAReversePointsCommand
{
    NSArray<OAWptPt *> *_oldPoints;
    NSArray<OAWptPt *> *_newPoints;
    NSMutableDictionary<NSArray<OAWptPt *> *, OARoadSegmentData *> *_oldRoadSegmentData;
    OAApplicationMode *_oldMode;
}

- (instancetype)initWithLayer:(OAMeasurementToolLayer *)measurementLayer
{
    self = [super initWithLayer:measurementLayer];
    if (self) {
        _oldMode = self.getEditingCtx.appMode;
    }
    return self;
}

- (BOOL) execute
{
    OAMeasurementEditingContext *editingCtx = self.getEditingCtx;
    _oldPoints = [NSArray arrayWithArray:editingCtx.getPoints];
    _oldRoadSegmentData = editingCtx.roadSegmentData;
    NSMutableArray<OAWptPt *> *newPoints = [[NSMutableArray alloc] initWithCapacity:_oldPoints.count];
    
    for (NSInteger i = (NSInteger) _oldPoints.count - 1; i >= 0; i--)
    {
        OAWptPt *point = _oldPoints[i];
        OAWptPt *prevPoint = i > 0 ? _oldPoints[i - 1] : nil;
        [point copyExtensions:point];
        if (prevPoint != nil)
        {
            NSString *profileType = prevPoint.getProfileType;
            if (profileType != nil)
            {
                [point setProfileType:profileType];
            } else
            {
                [point removeProfileType];
            }
        }
        [newPoints addObject:point];
    }
    _newPoints = [NSArray arrayWithArray:newPoints];
    [self executeCommand];
    return YES;
}

- (void) executeCommand
{
    OAMeasurementEditingContext *editingCtx = self.getEditingCtx;
    [editingCtx clearSnappedToRoadPoints];
    [editingCtx clearPoints];
    [editingCtx addPoints:_newPoints];
    if (_newPoints.count > 0)
    {
        OAWptPt *lastPoint = _newPoints.lastObject;
        editingCtx.appMode = [OAApplicationMode valueOfStringKey:lastPoint.getProfileType def:OAApplicationMode.DEFAULT];
    }
    [editingCtx updateSegmentsForSnap];
}

- (void) undo
{
    OAMeasurementEditingContext *editingCtx = self.getEditingCtx;
    [editingCtx clearPoints];
    [editingCtx addPoints:_oldPoints];
    editingCtx.appMode = _oldMode;
    editingCtx.roadSegmentData = _oldRoadSegmentData;
    [editingCtx updateSegmentsForSnap];
    
}

- (void) redo
{
    [self executeCommand];
}

- (EOAMeasurementCommandType)getType
{
    return REVERSE_POINTS;
}

@end
