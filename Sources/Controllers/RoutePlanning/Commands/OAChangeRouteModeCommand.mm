//
//  OAChangeRouteModeCommand.m
//  OsmAnd
//
//  Created by Paul on 25.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAChangeRouteModeCommand.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAApplicationMode.h"
#import "OARoadSegmentData.h"
#import "OAMeasurementEditingContext.h"
#import "OAMeasurementToolLayer.h"

@implementation OAChangeRouteModeCommand
{
    NSMutableArray<OAWptPt *> *_oldPoints;
    NSMutableArray<OAWptPt *> *_newPoints;
    NSMutableDictionary<NSArray<OAWptPt *> *, OARoadSegmentData *> *_oldRoadSegmentData;
    NSMutableDictionary<NSArray<OAWptPt *> *, OARoadSegmentData *> *_newRoadSegmentData;
    OAApplicationMode *_oldMode;
    OAApplicationMode *_newMode;
    EOAChangeRouteType _changeRouteType;
    NSInteger _pointIndex;
}

- (instancetype)initWithLayer:(OAMeasurementToolLayer *)measurementLayer appMode:(OAApplicationMode *)appMode changeRouteType:(EOAChangeRouteType)changeRouteType pointIndex:(NSInteger)pointIndex
{
    self = [super initWithLayer:measurementLayer];
    if (self)
    {
        _newMode = appMode;
        _changeRouteType = changeRouteType;
        _pointIndex = pointIndex;
        _oldMode = self.getEditingCtx.appMode;
    }
    return self;
}

- (BOOL)execute
{
    OAMeasurementEditingContext *editingCtx = self.getEditingCtx;
    _oldPoints = [NSMutableArray arrayWithArray:editingCtx.getPoints];
    _oldRoadSegmentData = [NSMutableDictionary dictionaryWithDictionary:editingCtx.roadSegmentData];
    _newPoints = [NSMutableArray arrayWithCapacity:_oldPoints.count];
    _newRoadSegmentData = [NSMutableDictionary dictionaryWithDictionary:_oldRoadSegmentData];;
    if (_oldPoints.count > 0)
    {
        [_newPoints addObjectsFromArray:_oldPoints];
        switch (_changeRouteType)
        {
            case EOAChangeRouteLastSegment:
            {
                [self updateProfileType:_newPoints[_newPoints.count - 1]];
                editingCtx.lastCalculationMode = NEXT_SEGMENT;
                _newRoadSegmentData = nil;
                break;
            }
            case EOAChangeRouteWhole:
            {
                for (OAWptPt *pt in _newPoints)
                {
                    [self updateProfileType:pt];
                }
                editingCtx.lastCalculationMode = WHOLE_TRACK;
                [_newRoadSegmentData removeAllObjects];
                break;
            }
            case EOAChangeRouteNextSegment:
            {
                if (_pointIndex >= 0 && _pointIndex < _newPoints.count)
                {
                    [self updateProfileType:_newPoints[_pointIndex]];
                }
                [_newRoadSegmentData removeObjectForKey:[self getPairAt:_pointIndex]];
                break;
            }
            case EOAChangeRouteAllNextSegments:
            {
                for (NSInteger i = _pointIndex; i >= 0 && i < _newPoints.count; i++)
                {
                    [self updateProfileType:_newPoints[i]];
                    [_newRoadSegmentData removeObjectForKey:[self getPairAt:i]];
                }
                break;
            }
            case EOAChangeRoutePrevSegment:
            {
                if (_pointIndex > 0 && _pointIndex < _newPoints.count)
                {
                    [self updateProfileType:_newPoints[_pointIndex - 1]];
                    [_newRoadSegmentData removeObjectForKey:[self getPairAt:_pointIndex - 1]];
                }
                break;
            }
            case EOAChangeRouteAllPrevSegments:
            {
                for (NSInteger i = 0; i < _pointIndex && i < _newPoints.count; i++)
                {
                    [self updateProfileType:_newPoints[i]];
                    [_newRoadSegmentData removeObjectForKey:[self getPairAt:i]];
                }
                break;
            }
        }
    }
    [self executeCommand];
    return true;
}

- (void)undo
{
    OAMeasurementEditingContext *editingCtx = [self getEditingCtx];
    [editingCtx clearPoints];
    [editingCtx addPoints:_oldPoints];
    editingCtx.appMode = _oldMode;
    editingCtx.roadSegmentData = _oldRoadSegmentData;
    [editingCtx updateSegmentsForSnap];
    [self refreshMap];
}

- (void)redo
{
    [self executeCommand];
}

- (EOAMeasurementCommandType)getType
{
    return CHANGE_ROUTE_MODE;
}

- (NSArray<OAWptPt *> *) getPairAt:(NSInteger)pointIndex
{
    OAWptPt *first = pointIndex >= 0 && pointIndex < _newPoints.count ? _newPoints[pointIndex] : nil;
    OAWptPt *second = pointIndex >= 0 && pointIndex < _newPoints.count - 1 ? _newPoints[pointIndex + 1] : nil;
    return @[first, second];
}

- (void) executeCommand
{
    OAMeasurementEditingContext *editingCtx = [self getEditingCtx];
    [editingCtx clearPoints];
    [editingCtx addPoints:_newPoints];
    if (_newPoints.count == 0)
    {
        editingCtx.appMode = _newMode;
    }
    else
    {
        OAWptPt *lastPoint = _newPoints[_newPoints.count - 1];
        editingCtx.appMode = [OAApplicationMode valueOfStringKey:lastPoint.getProfileType def:OAApplicationMode.DEFAULT];
    }
    if (_newRoadSegmentData != nil)
        editingCtx.roadSegmentData = _newRoadSegmentData;
    [editingCtx updateSegmentsForSnap];
    [self refreshMap];
}

- (void) updateProfileType:(OAWptPt *)pt
{
    if (!pt.isGap)
    {
        if (_newMode != nil && _newMode != OAApplicationMode.DEFAULT)
            [pt setProfileType:_newMode.stringKey];
        else
            [pt removeProfileType];
    }
}

@end
