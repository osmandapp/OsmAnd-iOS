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

@implementation OAChangeRouteModeCommand
{
    NSArray<OAGpxTrkPt *> *_oldPoints;
    NSArray<OAGpxTrkPt *> *_newPoints;
    NSMutableDictionary<NSArray<OAGpxTrkPt *> *, OARoadSegmentData *> *_oldRoadSegmentData;
    NSMutableDictionary<NSArray<OAGpxTrkPt *> *, OARoadSegmentData *> *_newRoadSegmentData;
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
    _oldPoints = [NSArray arrayWithArray:editingCtx.getPoints];
    _oldRoadSegmentData = [NSMutableDictionary dictionaryWithDictionary:editingCtx.roadSegmentData];
    _newPoints = [NSMutableArray arrayWithCapacity:_oldPoints.count];
    _newRoadSegmentData = [NSMutableDictionary dictionaryWithDictionary:_oldRoadSegmentData];;
    if (_oldPoints.count > 0)
    {
        for (OAGpxTrkPt *pt in _oldPoints)
        {
            OAGpxTrkPt *point = [[OAGpxTrkPt alloc] initWithPoint:pt];
            [point copyExtensions:pt];
            [_newPoints addObject:point];
        }
        switch (_changeRouteType)
        {
            case LAST_SEGMENT:
            {
                [self updateProfileType:newPoints[_newPoints.count - 1]];
                editingCtx.lastCalculationMode = NEXT_SEGMENT;
                _newRoadSegmentData = nil;
                break;
            }
            case WHOLE_ROUTE:
            {
                for (OAGpxTrkPt *pt in _newPoints)
                {
                    [self updateProfileType:pt];
                }
                editingCtx.lastCalculationMode = WHOLE_TRACK;
                [_newRoadSegmentData removeAllObjects];
                break;
            }
            case NEXT_SEGMENT:
            {
                if (_pointIndex >= 0 && _pointIndex < _newPoints.count)
                {
                    [self updateProfileType:_newPoints[_pointIndex]];
                }
                [_newRoadSegmentData removeObjectForKey:[self getPairAt:_pointIndex]];
                break;
            }
            case ALL_NEXT_SEGMENTS:
            {
                for (NSInteger i = _pointIndex; i >= 0 && i < newPoints.count; i++)
                {
                    [self updateProfileType:newPoints[i]];
                    [_newRoadSegmentData removeObjectForKey:[self getPairAt:i]];
                }
                break;
            }
            case PREV_SEGMENT:
            {
                if (_pointIndex > 0 && _pointIndex < newPoints.count)
                {
                    [self updateProfileType:_newPoints[pointIndex - 1]];
                    [_newRoadSegmentData removeObjectForKey:[self getPairAt:pointIndex - 1]];
                }
                break;
            }
            case ALL_PREV_SEGMENTS:
            {
                for (NSInteger i = 0; i < pointIndex && i < newPoints.count; i++)
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
}

    @Override
    public void undo() {
        
    }

    @Override
    public void redo() {
        executeCommand();
    }

    @Override
    public MeasurementCommandType getType() {
        return MeasurementCommandType.CHANGE_ROUTE_MODE;
    }

    private Pair<WptPt, WptPt> getPairAt(int pointIndex) {
        WptPt first = pointIndex >= 0 && pointIndex < newPoints.size() ? newPoints.get(pointIndex) : null;
        WptPt second = pointIndex >= 0 && pointIndex < newPoints.size() - 1 ? newPoints.get(pointIndex + 1) : null;
        return new Pair<>(first, second);
    }

    private void executeCommand() {
        MeasurementEditingContext editingCtx = getEditingCtx();
        editingCtx.getPoints().clear();
        editingCtx.addPoints(newPoints);
        if (newPoints.isEmpty()) {
            editingCtx.setAppMode(newMode);
        } else {
            WptPt lastPoint = newPoints.get(newPoints.size() - 1);
            editingCtx.setAppMode(ApplicationMode.valueOfStringKey(lastPoint.getProfileType(), DEFAULT_APP_MODE));
        }
        if (newRoadSegmentData != null) {
            editingCtx.setRoadSegmentData(newRoadSegmentData);
        }
        editingCtx.updateSegmentsForSnap();
    }

    private void updateProfileType(WptPt pt) {
        if (!pt.isGap()) {
            if (newMode != null && newMode != DEFAULT_APP_MODE) {
                pt.setProfileType(newMode.getStringKey());
            } else {
                pt.removeProfileType();
            }
        }
    }

@end
