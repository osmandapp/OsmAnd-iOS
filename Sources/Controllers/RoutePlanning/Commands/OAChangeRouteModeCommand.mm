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
#import "OsmAndSharedWrapper.h"

@interface OAChangeRouteModeCommand ()

- (NSArray *)profileTypesForPoints:(NSArray<OASWptPt *> *)points;
- (void)applyProfileTypes:(NSArray *)profileTypes toPoints:(NSArray<OASWptPt *> *)points;

@end

@implementation OAChangeRouteModeCommand
{
    NSMutableArray<OASWptPt *> *_oldPoints;
    NSMutableArray<OASWptPt *> *_newPoints;
    NSMutableDictionary<NSArray<OASWptPt *> *, OARoadSegmentData *> *_oldRoadSegmentData;
    NSMutableDictionary<NSArray<OASWptPt *> *, OARoadSegmentData *> *_newRoadSegmentData;
    NSArray *_oldProfileTypes;
    NSArray *_newProfileTypes;
    OAApplicationMode *_oldMode;
    OAApplicationMode *_newMode;
    EOAChangeRouteType _changeRouteType;
    NSInteger _pointIndex;
    NSArray<NSNumber *> *_pointIndexes;
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

- (instancetype)initWithLayer:(OAMeasurementToolLayer *)measurementLayer
                      appMode:(OAApplicationMode *)appMode
                 pointIndexes:(NSArray<NSNumber *> *)pointIndexes
{
    self = [super initWithLayer:measurementLayer];
    if (self)
    {
        _newMode = appMode;
        _pointIndexes = [pointIndexes copy];
        _oldMode = self.getEditingCtx.appMode;
    }
    return self;
}

- (BOOL)execute
{
    OAMeasurementEditingContext *editingCtx = self.getEditingCtx;
    _oldPoints = [NSMutableArray arrayWithArray:editingCtx.getPoints];
    _oldProfileTypes = [self profileTypesForPoints:_oldPoints];
    _oldRoadSegmentData = [NSMutableDictionary dictionaryWithDictionary:editingCtx.roadSegmentData];
    _newPoints = [NSMutableArray arrayWithCapacity:_oldPoints.count];
    _newRoadSegmentData = [NSMutableDictionary dictionaryWithDictionary:_oldRoadSegmentData];
    if (_oldPoints.count > 0)
    {
        [_newPoints addObjectsFromArray:_oldPoints];
        if (_pointIndexes != nil)
        {
            for (NSNumber *indexNumber in _pointIndexes)
            {
                NSInteger index = indexNumber.integerValue;
                if (index >= 0 && index < _newPoints.count)
                {
                    [self updateProfileType:_newPoints[index]];
                    [_newRoadSegmentData removeObjectForKey:[self getPairAt:index]];
                }
            }
        }
        else
        {
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
                    for (OASWptPt *pt in _newPoints)
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
    }
    _newProfileTypes = [self profileTypesForPoints:_newPoints];
    [self executeCommand];
    return true;
}

- (void)undo
{
    OAMeasurementEditingContext *editingCtx = [self getEditingCtx];
    [editingCtx cancelSnapToRoad];
    [self applyProfileTypes:_oldProfileTypes toPoints:_oldPoints];
    [editingCtx clearPoints];
    [editingCtx addPoints:_oldPoints];
    editingCtx.appMode = _oldMode;
    editingCtx.roadSegmentData = [_oldRoadSegmentData mutableCopy];
    [editingCtx updateSegmentsForSnap];
    [self refreshMap];
}

- (void)redo
{
    [[self getEditingCtx] cancelSnapToRoad];
    [self executeCommand];
}

- (EOAMeasurementCommandType)getType
{
    return CHANGE_ROUTE_MODE;
}

- (NSArray<OASWptPt *> *) getPairAt:(NSInteger)pointIndex
{
    NSMutableArray<OASWptPt *> *res = [NSMutableArray array];
    OASWptPt *first = pointIndex >= 0 && pointIndex < _newPoints.count ? _newPoints[pointIndex] : nil;
    if (first)
        [res addObject:first];
    OASWptPt *second = pointIndex >= 0 && pointIndex < _newPoints.count - 1 ? _newPoints[pointIndex + 1] : nil;
    if (second)
        [res addObject:second];

    return [NSArray arrayWithArray:res];
}

- (void) executeCommand
{
    OAMeasurementEditingContext *editingCtx = [self getEditingCtx];
    [self applyProfileTypes:_newProfileTypes toPoints:_newPoints];
    [editingCtx clearPoints];
    [editingCtx addPoints:_newPoints];
    if (_newPoints.count == 0)
    {
        editingCtx.appMode = _newMode;
    }
    else
    {
        OASWptPt *lastPoint = _newPoints[_newPoints.count - 1];
        if (lastPoint.isGap)
            editingCtx.appMode = _newMode;
        else
            editingCtx.appMode = [OAApplicationMode valueOfStringKey:lastPoint.getProfileType def:OAApplicationMode.DEFAULT];
    }
    if (_newRoadSegmentData != nil)
        editingCtx.roadSegmentData = [_newRoadSegmentData mutableCopy];
    [editingCtx updateSegmentsForSnap];
    [self refreshMap];
}

- (void) updateProfileType:(OASWptPt *)pt
{
    if (!pt.isGap)
    {
        if (_newMode != nil && _newMode != OAApplicationMode.DEFAULT)
            [pt setProfileTypeProfileType:_newMode.stringKey];
        else
            [pt removeProfileType];
    }
}

- (NSArray *)profileTypesForPoints:(NSArray<OASWptPt *> *)points
{
    NSMutableArray *profileTypes = [NSMutableArray arrayWithCapacity:points.count];
    for (OASWptPt *point in points)
        [profileTypes addObject:point.getProfileType ?: NSNull.null];
    return [profileTypes copy];
}

- (void)applyProfileTypes:(NSArray *)profileTypes toPoints:(NSArray<OASWptPt *> *)points
{
    NSInteger count = MIN(profileTypes.count, points.count);
    for (NSInteger index = 0; index < count; index++)
    {
        id profileType = profileTypes[index];
        if ([profileType isKindOfClass:NSString.class])
            [points[index] setProfileTypeProfileType:profileType];
        else
            [points[index] removeProfileType];
    }
}

@end
