//
//  OAMeasurementEditingContext.m
//  OsmAnd
//
//  Created by Paul on 22.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMeasurementEditingContext.h"
#import "OAApplicationMode.h"
#import "OAMeasurementCommandManager.h"
#import "OAGpxData.h"
#import "OAGPXDocument.h"
#import "OAGPXMutableDocument.h"
#import "OAGPXDocumentPrimitives.h"
#import "OARoadSegmentData.h"
#import "OARouteImporter.h"
#import "OARoutingHelper.h"
#import "OARouteCalculationParams.h"
#import "OARouteExporter.h"
#import "OAGpxRouteApproximation.h"

#include <CommonCollections.h>
#include <commonOsmAndCore.h>

#include <routeSegmentResult.h>
#include <routeCalculationProgress.h>
#include <routePlannerFrontEnd.h>

static OAApplicationMode *DEFAULT_APP_MODE;

@interface OAMeasurementEditingContext() <OARouteCalculationProgressCallback, OARouteCalculationResultListener>

@end

@implementation OAMeasurementEditingContext
{
    OAGpxTrkSeg *_before;
    NSMutableArray<OAGpxTrkSeg *> *_beforeSegments;
    NSMutableArray<OAGpxTrkSeg *> *_beforeSegmentsForSnap;
    OAGpxTrkSeg *_after;
    NSMutableArray<OAGpxTrkSeg *> *_afterSegments;
    NSMutableArray<OAGpxTrkSeg *> *_afterSegmentsForSnap;
    
    NSInteger _calculatedPairs;
    NSInteger _pointsToCalculateSize;
    
    OARouteCalculationParams *_params;
    NSArray<OAGpxTrkPt *> *_currentPair;
    
    std::shared_ptr<RouteCalculationProgress> _calculationProgress;
}

+ (void) initialize
{
    DEFAULT_APP_MODE = OAApplicationMode.DEFAULT;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _commandManager = [[OAMeasurementCommandManager alloc] init];
        _selectedPointPosition = -1;
        _selectedSegment = -1;
        _lastCalculationMode = WHOLE_TRACK;
        _appMode = DEFAULT_APP_MODE;
        _addPointMode = EOAAddPointModeUndefined;
        
        _before = [[OAGpxTrkSeg alloc] init];
        _before.points = @[];
        _beforeSegments = [NSMutableArray new];
        _after = [[OAGpxTrkSeg alloc] init];
        _after.points = @[];
        _afterSegments = [NSMutableArray new];
        
        _roadSegmentData = [NSMutableDictionary new];
    }
    return self;
}


- (BOOL) hasChanges
{
    return [_commandManager hasChanges];
}

- (void) setChangesSaved
{
    [_commandManager resetChangesCounter];
}

- (BOOL) isAddNewSegmentAllowed
{
    return _beforeSegments.count > 0 && _beforeSegments.lastObject.points.count >= 2;
}

- (BOOL) isApproximationNeeded
{
    BOOL hasDefaultPointsOnly = NO;
    BOOL newData = self.isNewData;
    if (!newData)
    {
        NSArray<OAGpxTrkPt *> *points = self.getPoints;
        hasDefaultPointsOnly = YES;
        for (OAGpxTrkPt *point in points)
        {
            if (point.hasProfile)
            {
                hasDefaultPointsOnly = NO;
                break;
            }
        }
    }
    return !newData && hasDefaultPointsOnly && self.getPoints.count > 2;
}


- (BOOL) isNewData
{
    return !_gpxData;
}

- (BOOL) hasRoutePoints
{
    return _gpxData != nil && _gpxData.gpxFile != nil && _gpxData.gpxFile.hasRtePt;
}

- (BOOL) hasSavedRoute
{
    return _gpxData != nil && _gpxData.gpxFile != nil && _gpxData.gpxFile.tracks.count > 0;
}

//void setProgressListener(SnapToRoadProgressListener progressListener) {
//    this.progressListener = progressListener;
//}

- (void) resetAppMode
{
    _appMode = DEFAULT_APP_MODE;
}

- (double) getRouteDistance
{
    double distance = 0;
    for (NSArray<OAGpxTrkPt *> *points in @[_before.points, _after.points])
    {
        if (points.count == 0)
            continue;
        
        for (NSUInteger i = 0; i < points.count - 1; i++)
        {
            OAGpxTrkPt *first = points[i];
            OAGpxTrkPt *second = points[i + 1];
            OARoadSegmentData *data = _roadSegmentData[@[first, second]];
            
            if (data == nil)
            {
                if (_appMode != OAApplicationMode.DEFAULT || !first.lastPoint || !second.firstPoint)
                {
                    double localDist = getDistance(first.getLatitude, first.getLongitude,
                                                   second.getLatitude, second.getLongitude);
                    if(!isnan(first.elevation) && !isnan(second.elevation) &&
                       first.elevation != 0 && second.elevation != 0)
                    {
                        double h = fabs(first.elevation - second.elevation);
                        localDist = sqrt(localDist * localDist + h * h);
                    }
                    distance += localDist;
                }
            }
            else
            {
                distance += data.distance;
            }
        }
    }
    return distance;
}

- (BOOL) hasRoute
{
    return _roadSegmentData.count > 0;
}

- (void) clearSnappedToRoadPoints
{
    [_roadSegmentData removeAllObjects];
}

- (NSArray<OAGpxTrkSeg *> *) getBeforeTrkSegmentLine
{
    if (_beforeSegmentsForSnap != nil)
        return _beforeSegmentsForSnap;
    return _beforeSegments;
}

- (NSArray<OAGpxTrkSeg *> *) getAfterTrkSegmentLine
{
    if (_afterSegmentsForSnap != nil)
        return _afterSegmentsForSnap;
    return _afterSegments;
}

- (NSArray<OAGpxTrkSeg *> *)getBeforeSegments
{
    return _beforeSegments;
}

- (NSArray<OAGpxTrkSeg *> *)getAfterSegments
{
    return _afterSegments;
}


- (NSArray<OAGpxTrkPt *> *) getAllPoints
{
    return [_before.points arrayByAddingObjectsFromArray:_after.points];
}

- (NSArray<OAGpxTrkPt *> *) getPoints
{
    return [self getBeforePoints];
}

- (NSArray<NSArray<OAGpxTrkPt *> *> *) getPointsSegments:(BOOL)plain route:(BOOL)route
{
	NSMutableArray<NSArray<OAGpxTrkPt *> *> *res = [NSMutableArray array];
	NSArray<OAGpxTrkPt *> *allPoints = self.getPoints;
	NSMutableArray<OAGpxTrkPt *> *segment = [NSMutableArray array];
	NSString *prevProfileType = nil;
	for (OAGpxTrkPt *point in allPoints)
	{
		NSString *profileType = point.getProfileType;
		BOOL isGap = point.isGap;
		BOOL plainPoint = profileType.length == 0 || (isGap && prevProfileType.length == 0);
		BOOL routePoint = !plainPoint;
		if ((plain && plainPoint) || (route && routePoint))
		{
			[segment addObject:point];
			if (isGap)
			{
				[res addObject:segment];
				segment = [NSMutableArray array];
			}
		}
		prevProfileType = profileType;
	}
	if (segment.count > 0)
		[res addObject:segment];
	return res;
}

- (NSArray<OAGpxTrkPt *> *) getBeforePoints
{
    return _before.points;
}

- (NSArray<OAGpxTrkPt *> *) getAfterPoints
{
    return _after.points;
}

- (NSInteger) getPointsCount
{
    return _before.points.count;
}

- (void) clearPoints
{
    _before.points = [NSArray new];
}

- (void) splitSegments:(NSInteger)position
{
    NSMutableArray<OAGpxTrkPt *> *points = [NSMutableArray new];
    [points addObjectsFromArray:_before.points];
    [points addObjectsFromArray:_after.points];
    
    _before.points = [points subarrayWithRange:NSMakeRange(0, position)];
    _after.points = [points subarrayWithRange:NSMakeRange(position, points.count - position)];
    
    [self updateSegmentsForSnap:YES];
}

- (void) preAddPoint:(NSInteger)position mode:(EOAAddPointMode)mode point:(OAGpxTrkPt *)point
{
    switch (mode) {
        case EOAAddPointModeUndefined:
        {
            if (_appMode != DEFAULT_APP_MODE)
            {
                [point setProfileType:_appMode.stringKey];
            }
            break;
        }
        case EOAAddPointModeAfter:
        {
            NSArray<OAGpxTrkPt *> *points = self.getBeforePoints;
            if (position > 0 && position <= points.count)
            {
                OAGpxTrkPt *prevPt = points.lastObject;
                if (prevPt.isGap)
                {
                    if (position == points.count && self.getAfterPoints.count == 0)
                    {
                        if (_appMode != DEFAULT_APP_MODE)
                        {
                            [point setProfileType:_appMode.stringKey];
                        }
                    }
                    else
                    {
                        [point setGap];
                        if (position > 1)
                        {
                            OAGpxTrkPt *pt = points[position - 2];
                            if ([pt hasProfile])
                            {
                                [prevPt setProfileType:pt.getProfileType];
                            }
                            else
                            {
                                [prevPt removeProfileType];
                            }
                        }
                    }
                }
                else if ([prevPt hasProfile])
                {
                    [point setProfileType:prevPt.getProfileType];
                }
            }
            else if (_appMode != DEFAULT_APP_MODE)
            {
                [point setProfileType:_appMode.stringKey];
            }
            break;
        }
        case EOAAddPointModeBefore: {
            NSArray<OAGpxTrkPt *> *points = self.getAfterPoints;
            if (position >= -1 && position + 1 < points.count)
            {
                OAGpxTrkPt *nextPt = points[position + 1];
                if ([nextPt hasProfile])
                {
                    [point setProfileType:nextPt.getProfileType];
                }
            }
            else if (_appMode != DEFAULT_APP_MODE)
            {
                [point setProfileType:_appMode.stringKey];
            }
            break;
        }
    }
}

- (void) addPoint:(OAGpxTrkPt *)pt
{
    [self addPoint:pt mode:EOAAddPointModeUndefined];
}

- (void) addPoint:(OAGpxTrkPt *)pt mode:(EOAAddPointMode)mode
{
    if (mode == EOAAddPointModeAfter || mode == EOAAddPointModeBefore)
        [self preAddPoint:(mode == EOAAddPointModeBefore ? -1 : self.getBeforePoints.count) mode:mode point:pt];
    _before.points = [_before.points arrayByAddingObject:pt];
    [self updateSegmentsForSnap:NO];
}

- (void) addPoint:(NSInteger)position pt:(OAGpxTrkPt *)pt
{
    [self addPoint:position point:pt mode:EOAAddPointModeUndefined];
}

- (void) addPoint:(NSInteger)position point:(OAGpxTrkPt *)pt mode:(EOAAddPointMode)mode
{
    if (mode == EOAAddPointModeAfter || mode == EOAAddPointModeBefore)
        [self preAddPoint:position mode:mode point:pt];
    NSMutableArray<OAGpxTrkPt *> *points = [NSMutableArray arrayWithArray:_before.points];
    [points insertObject:pt atIndex:position];
    _before.points = points;
    [self updateSegmentsForSnap:false];
}

- (void) addPoints:(NSArray<OAGpxTrkPt *> *)points
{
    NSMutableArray<OAGpxTrkPt *> *pnts = [NSMutableArray arrayWithArray:_before.points];
    [pnts addObjectsFromArray:points];
    _before.points = pnts;
    [self updateSegmentsForSnap:NO];
}

- (void) setPoints:(NSArray<OAGpxTrkPt *> *)points
{
    _before.points = points;
}

- (OAGpxTrkPt *) removePoint:(NSInteger)position updateSnapToRoad:(BOOL)updateSnapToRoad
{
    if (position < 0 || position >= _before.points.count)
        return [[OAGpxTrkPt alloc] init];
    NSMutableArray<OAGpxTrkPt *> *points = [NSMutableArray arrayWithArray:_before.points];
    OAGpxTrkPt *pt = points[position];
    if (position > 0 && pt.isGap)
    {
        OAGpxTrkPt *prevPt = _before.points[position - 1];
        if (!prevPt.isGap)
            [prevPt setGap];
    }
    [points removeObjectAtIndex:position];
    _before.points = points;
    if (updateSnapToRoad)
        [self updateSegmentsForSnap:NO];
    return pt;
}

- (void) trimBefore:(NSInteger)selectedPointPosition
{
    [self splitSegments:selectedPointPosition];
    [self clearBeforeSegments];
}

- (void) trimAfter:(NSInteger)selectedPointPosition
{
    [self splitSegments:selectedPointPosition + 1];
    [self clearAfterSegments];
}

- (void) splitPoints:(NSInteger) selectedPointPosition after:(BOOL)after
{
    NSInteger pointIndex = after ? selectedPointPosition : selectedPointPosition - 1;
    if (pointIndex >=0 && pointIndex < _before.points.count)
    {
        OAGpxTrkPt *point = _before.points[pointIndex];
        OAGpxTrkPt *nextPoint = _before.points.count > pointIndex + 1 ? _before.points[pointIndex + 1] : nil;
        OAGpxTrkPt *newPoint = [[OAGpxTrkPt alloc] initWithPoint:point];
        [newPoint copyExtensions:point];
        [newPoint setGap];
        
        NSMutableArray<OAGpxTrkPt *> *points = [NSMutableArray arrayWithArray:_before.points];
        [points removeObjectAtIndex:pointIndex];
        [points insertObject:newPoint atIndex:pointIndex];
        _before.points = points;
        
        if (newPoint)
            [_roadSegmentData removeObjectForKey:[NSArray arrayWithObjects:point, nextPoint, nil]];
        [self updateSegmentsForSnap:NO];
    }
}

- (void) joinPoints:(NSInteger) selectedPointPosition
{
    OAGpxTrkPt *gapPoint = [[OAGpxTrkPt alloc] init];
    NSInteger gapIndex = -1;
    if ([self isFirstPointSelected:selectedPointPosition outer:NO])
    {
        if (selectedPointPosition - 1 >= 0)
        {
            gapPoint = _before.points[selectedPointPosition - 1];
            gapIndex = selectedPointPosition - 1;
        }
    }
    else if ([self isLastPointSelected:selectedPointPosition outer:NO])
    {
        gapPoint = _before.points[selectedPointPosition];
        gapIndex = selectedPointPosition;
    }
    if (gapPoint)
    {
        OAGpxTrkPt *newPoint = [[OAGpxTrkPt alloc] initWithPoint:gapPoint];
        [newPoint copyExtensions:gapPoint];
        [newPoint removeProfileType];

        NSMutableArray<OAGpxTrkPt *> *points = [NSMutableArray arrayWithArray:_before.points];
        [points removeObjectAtIndex:gapIndex];
        [points insertObject:newPoint atIndex:gapIndex];
        _before.points = points;
        
        [self updateSegmentsForSnap:NO];
    }
}

- (void) clearSegments
{
    [self clearBeforeSegments];
    [self clearAfterSegments];
    [self clearSnappedToRoadPoints];
}

- (void) clearBeforeSegments
{
    _before.points = [NSArray new];
    [_beforeSegments removeAllObjects];
    if (_beforeSegmentsForSnap != nil)
        [_beforeSegmentsForSnap removeAllObjects];
}

- (void) clearAfterSegments
{
    _after.points = [NSArray new];
    [_afterSegments removeAllObjects];
    if (_afterSegmentsForSnap != nil)
        [_afterSegmentsForSnap removeAllObjects];
}

- (BOOL) isFirstPointSelected
{
    return _selectedPointPosition == 0;
}

- (BOOL) isLastPointSelected
{
    return _selectedPointPosition == (NSInteger) [self getPoints].count - 1;
}

- (BOOL) isFirstPointSelected:(BOOL)outer
{
    return [self isFirstPointSelected:_selectedPointPosition outer:outer];
}

- (BOOL) isFirstPointSelected:(NSInteger)selectedPointPosition outer:(BOOL)outer
{
    if (outer)
        return _selectedPointPosition == 0;
    else
        return [self isBorderPointSelected:selectedPointPosition first:YES];
}

- (BOOL) isLastPointSelected:(BOOL)outer
{
    return [self isLastPointSelected:_selectedPointPosition outer:outer];
}

- (BOOL) isLastPointSelected:(NSInteger)selectedPointPosition outer:(BOOL)outer
{
    if (outer)
        return _selectedPointPosition == (NSInteger) [self getPoints].count - 1;
    else
        return [self isBorderPointSelected:selectedPointPosition first:NO];
}

- (BOOL) isBorderPointSelected:(NSInteger) selectedPointPosition first:(BOOL)first
{
    OAGpxTrkPt *selectedPoint = [self getPoints][selectedPointPosition];
    NSArray <OAGpxTrkSeg *> *segments = [NSArray arrayWithArray: [self getBeforeSegments]];
    NSInteger count = 0;
    for (OAGpxTrkSeg *segment in segments)
    {
        NSInteger i = [segment.points indexOfObject:selectedPoint];
        if (i != -1)
        {
            NSInteger segmentPosition = selectedPointPosition - count;
            return first ? segmentPosition == 0 : segmentPosition == (NSInteger) segment.points.count - 1;
        }
        else
        {
            count += segment.points.count;
        }
    }
    return NO;
}

- (BOOL)isInAddPointMode
{
    return _addPointMode != EOAAddPointModeUndefined;
}

- (OAApplicationMode *) getSelectedPointAppMode
{
    return [self getPointAppMode:_selectedPointPosition];
}

- (OAApplicationMode *) getBeforeSelectedPointAppMode
{
    return [self getPointAppMode:MAX(_selectedPointPosition - 1, 0)];
}

- (OAApplicationMode *) getPointAppMode:(NSInteger)pointPosition
{
    NSString *profileType = [self getPoints][pointPosition].getProfileType;
    return [OAApplicationMode valueOfStringKey:profileType def:OAApplicationMode.DEFAULT];
}

- (NSArray<NSArray<OAGpxTrkPt *> *> *) getPointsToCalculate
{
    NSMutableArray<NSArray<OAGpxTrkPt *> *> *res = [NSMutableArray new];
    for (NSArray<OAGpxTrkPt *> *points in @[_before.points, _after.points])
    {
        for (NSInteger i = 0; i < (NSInteger) points.count - 1; i++)
        {
            OAGpxTrkPt *startPoint = points[i];
            OAGpxTrkPt *endPoint = points[i + 1];
            NSArray<OAGpxTrkPt *> *pair = @[startPoint, endPoint];
            if (_roadSegmentData[pair] == nil && (startPoint.hasProfile || self.hasRoute))
                [res addObject:pair];
        }
    }
    return res;
}
//
//private List<Pair<WptPt, WptPt>> getOrderedRoadSegmentDataKeys() {
//    List<Pair<WptPt, WptPt>> keys = new ArrayList<>();
//    for (List<WptPt> points : Arrays.asList(before.points, after.points)) {
//        for (int i = 0; i < points.size() - 1; i++) {
//            keys.add(new Pair<>(points.get(i), points.get(i + 1)));
//        }
//    }
//    return keys;
//}

- (void) scheduleRouteCalculateIfNotEmpty
{
    if (_before.points.count == 0 && _after.points.count == 0)
        return;
    OARoutingHelper *routingHelper = OARoutingHelper.sharedInstance;
    if (/*progressListener != null &&*/!routingHelper.isRouteBeingCalculated)
    {
        OARouteCalculationParams *params = [self getParams:YES];
        if (params != nil)
        {
            [routingHelper startRouteCalculationThread:params paramsChanged:YES updateProgress:YES];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.progressDelegate)
                    [self.progressDelegate showProgressBar];
            });
        }
    }
}
  
- (void) recreateSegments:(NSMutableArray<OAGpxTrkSeg *> *)segments segmentsForSnap:(NSMutableArray<OAGpxTrkSeg *> *)segmentsForSnap points:(NSArray<OAGpxTrkPt *> *)points calculateIfNeeded:(BOOL)calculateIfNeeded
{
    NSMutableArray<NSNumber *> *roadSegmentIndexes = [NSMutableArray new];
    OAGpxTrkSeg *s = [[OAGpxTrkSeg alloc] init];
    s.points = [NSArray new];
    [segments addObject:s];
    BOOL defaultMode = YES;
    if (points.count > 1)
    {
        for (NSInteger i = 0; i < points.count; i++)
        {
            OAGpxTrkPt *point = points[i];
            s.points = [s.points arrayByAddingObject:point];
            NSString *profileType = point.getProfileType;
            if (profileType != nil)
            {
                BOOL isDefault = [profileType isEqualToString:OAApplicationMode.DEFAULT.stringKey];
                BOOL isGap = point.isGap;
                if (defaultMode && !isDefault && !isGap)
                {
                    [roadSegmentIndexes addObject:@(segments.count - 1)];
                    defaultMode = NO;
                }
                if (isGap)
                {
                    if (s.points.count > 0)
                    {
                        s = [[OAGpxTrkSeg alloc] init];
                        s.points = [NSArray new];
                        [segments addObject:s];
                        defaultMode = YES;
                    }
                }
            }
        }
    }
    else
    {
        s.points = [s.points arrayByAddingObjectsFromArray:points];
    }
    if (s.points.count == 0)
        [segments removeObject:s];
    
    if (segments.count > 0)
    {
        for (OAGpxTrkSeg *segment in segments)
        {
            OAGpxTrkSeg *segmentForSnap = [[OAGpxTrkSeg alloc] init];
            segmentForSnap.points = [NSArray new];
            for (NSInteger i = 0; i < (NSInteger) segment.points.count - 1; i++)
            {
                NSArray<OAGpxTrkPt *> *pair = @[segment.points[i], segment.points[i + 1]];
                OARoadSegmentData *data = _roadSegmentData[pair];
                NSArray<OAGpxTrkPt *> *pts = data != nil ? data.points : nil;
                if (pts != nil)
                {
                    segmentForSnap.points = [segmentForSnap.points arrayByAddingObjectsFromArray:pts];
                }
                else
                {
                    if (calculateIfNeeded && [roadSegmentIndexes containsObject:@(segmentsForSnap.count)])
                        [self scheduleRouteCalculateIfNotEmpty];
                    
                    segmentForSnap.points = [segmentForSnap.points arrayByAddingObjectsFromArray:pair];
                }
            }
            if (segmentForSnap.points.count == 0)
                segmentForSnap.points = [segmentForSnap.points arrayByAddingObjectsFromArray:segment.points];
            [segmentsForSnap addObject:segmentForSnap];
        }
    }
    else if (points.count > 0)
    {
        OAGpxTrkSeg *segmentForSnap = [[OAGpxTrkSeg alloc] init];
        segmentForSnap.points = points;
        [segmentsForSnap addObject:segmentForSnap];
    }
}

- (NSArray<OAGpxTrkPt *> *) collectRoutePointsFromSegment:(OAGpxTrkSeg *)segment segmentInd:(NSInteger)segmentInd
{
    OARouteImporter *routeImporter = [[OARouteImporter alloc] initWithTrkSeg:segment];
    auto routeSegments = [routeImporter importRoute];
    NSArray<OAGpxRtePt *> *routePointsRte = [_gpxData.gpxFile getRoutePoints:segmentInd];
    NSMutableArray<OAGpxTrkPt *> *routePoints = [NSMutableArray new];
    NSArray<OAGpxTrkPt *> *points = segment.points;
    for (OAGpxRtePt *pt in routePointsRte)
        [routePoints addObject:[[OAGpxTrkPt alloc] initWithRtePt:pt]];
    NSInteger prevPointIndex = 0;
    if (routePoints.count == 0 && points.count > 1)
    {
        [routePoints addObject:points[0]];
        [routePoints addObject:points[points.count - 1]];
    }
    for (NSInteger i = 0; i < (NSInteger) routePoints.count - 1; i++)
    {
        NSArray<OAGpxTrkPt *> *pair = @[routePoints[i], routePoints[i + 1]];
        NSInteger startIndex = pair.firstObject.getTrkPtIndex;
        if (startIndex < 0 || startIndex < prevPointIndex || startIndex >= points.count)
            startIndex = [self findPointIndex:pair.firstObject points:points firstIndex:prevPointIndex];
        NSInteger endIndex = pair.lastObject.getTrkPtIndex;
        if (endIndex < 0 || endIndex < startIndex || endIndex >= points.count)
            endIndex = [self findPointIndex:pair.lastObject points:points firstIndex:startIndex];
        if (startIndex >= 0 && endIndex >= 0)
        {
            NSMutableArray<OAGpxTrkPt *> *pairPoints = [NSMutableArray new];
            for (NSInteger j = startIndex; j < endIndex && j < points.count; j++)
            {
                [pairPoints addObject:points[j]];
                prevPointIndex = j;
            }
            if (points.count > prevPointIndex + 1 && i == routePoints.count - 2)
                [pairPoints addObject:points[prevPointIndex + 1]];
            
            auto it = routeSegments.begin();
            NSInteger k = endIndex - startIndex - 1;
            std::vector<std::shared_ptr<RouteSegmentResult>> pairSegments;
            if (k == 0 && !routeSegments.empty())
            {
                const auto seg = routeSegments[0];
                pairSegments.push_back(seg);
                routeSegments.erase(routeSegments.begin());
            }
            else
            {
                while (it != routeSegments.end() && k > 0)
                {
                    const auto s = *it;
                    pairSegments.push_back(s);
                    it = routeSegments.erase(it);
                    k -= abs(s->getEndPointIndex() - s->getStartPointIndex());
                }
            }
            OAApplicationMode *appMode = [OAApplicationMode valueOfStringKey:pair.firstObject.getProfileType def:OAApplicationMode.DEFAULT];
            _roadSegmentData[pair] = [[OARoadSegmentData alloc] initWithAppMode:appMode start:pair.firstObject end:pair.lastObject points:pairPoints segments:pairSegments];
        }
    }
    return routePoints;
}

- (void) addPoints
{
    OAGpxData *gpxData = self.gpxData;
    if (gpxData == nil || gpxData.gpxFile == nil)
        return;
    NSArray<OAGpxTrkSeg *> *segments = [gpxData.gpxFile getNonEmptyTrkSegments:NO];
    if (segments.count == 0)
        return;

    if (_selectedSegment != -1 && segments.count > _selectedSegment)
    {
        OAGpxTrkSeg *seg = segments[_selectedSegment];
        if (seg.hasRoute)
            [self addPoints:[self collectRoutePointsFromSegment:seg segmentInd:_selectedSegment]];
        else
            [self addPoints:seg.points];
    }
    else
    {
        for (NSInteger si = 0; si < segments.count; si++)
        {
            OAGpxTrkSeg *segment = segments[si];
            if (segment.hasRoute)
            {
                NSArray<OAGpxTrkPt *> *routePoints = [self collectRoutePointsFromSegment:segment segmentInd:si];
                if (routePoints.count > 0 && si < segments.count - 1)
                    [routePoints[routePoints.count - 1] setGap];
                [self addPoints:routePoints];
            }
            else
            {
                NSArray<OAGpxTrkPt *> *points = segment.points;
                [self addPoints:points];
                if (points.count > 0 && si < segments.count - 1)
                    [points[points.count - 1] setGap];
            }
        }
    }
}

- (NSArray<OAGpxTrkPt *> *) setPoints:(OAGpxRouteApproximation *)gpxApproximation originalPoints:(NSArray<OAGpxTrkPt *> *)originalPoints mode:(OAApplicationMode *)mode
{
	if (gpxApproximation == nil || gpxApproximation.gpxApproximation->finalPoints.size() == 0 || gpxApproximation.gpxApproximation->result.size() == 0)
		return nil;
	
	NSMutableArray<OAGpxTrkPt *> *routePoints = [NSMutableArray array];
	const auto gpxPoints = gpxApproximation.gpxApproximation->finalPoints;
	for (NSInteger i = 0; i < gpxPoints.size(); i++)
	{
		const auto& gp1 = gpxPoints[i];
		BOOL lastGpxPoint = [self isLastGpxPoint:gpxPoints index:i];
		NSMutableArray<OAGpxTrkPt *> *points = [NSMutableArray array];
		vector<SHARED_PTR<RouteSegmentResult>> segments;
		for (NSInteger k = 0; k < gp1->routeToTarget.size(); k++)
		{
			const auto& seg = gp1->routeToTarget[k];
			if (seg->getStartPointIndex() != seg->getEndPointIndex())
			{
				segments.push_back(seg);
			}
		}
		for (NSInteger k = 0; k < segments.size(); k++)
		{
			const auto& seg = segments[k];
			[self fillPointsArray:points seg:seg includeEndPoint:lastGpxPoint && k == segments.size() - 1];
		}
		if (points.count > 0)
		{
			OAGpxTrkPt *wp1 = [[OAGpxTrkPt alloc] init];
			wp1.position = CLLocationCoordinate2DMake(gp1->lat, gp1->lon);
			[wp1 setProfileType:mode.stringKey];
			[routePoints addObject:wp1];
			OAGpxTrkPt *wp2 = [[OAGpxTrkPt alloc] init];
			if (lastGpxPoint)
			{
				wp2.position = points.lastObject.position;
				[routePoints addObject:wp2];
			}
			else
			{
				const auto& gp2 = gpxPoints[i + 1];
				wp2.position = CLLocationCoordinate2DMake(gp2->lat, gp2->lon);
			}
			[wp2 setProfileType:mode.stringKey];
			NSArray<OAGpxTrkPt *> *pair = @[wp1, wp2];
			_roadSegmentData[pair] = [[OARoadSegmentData alloc] initWithAppMode:_appMode start:pair.firstObject end:pair.lastObject points:points segments:segments];
		}
		if (lastGpxPoint)
		{
			break;
		}
	}
	OAGpxTrkPt *lastOriginalPoint = originalPoints.lastObject;
	OAGpxTrkPt *lastRoutePoint = routePoints.lastObject;
	if (lastOriginalPoint.isGap)
		[lastRoutePoint setGap];
	
	[self replacePoints:originalPoints points:routePoints];
	return routePoints;
}

- (void) replacePoints:(NSArray<OAGpxTrkPt *> *)originalPoints points:(NSArray<OAGpxTrkPt *> *)points
{
	if (originalPoints.count > 1)
	{
		NSInteger firstPointIndex = [_before.points indexOfObject:originalPoints.firstObject];
		NSInteger lastPointIndex = [_before.points indexOfObject:originalPoints.lastObject];
		NSMutableArray<OAGpxTrkPt *> *newPoints = [NSMutableArray array];
		if (firstPointIndex != NSNotFound && lastPointIndex != NSNotFound)
		{
			[newPoints addObjectsFromArray:[_before.points subarrayWithRange:NSMakeRange(0, firstPointIndex)]];
			[newPoints addObjectsFromArray:points];
			if (_before.points.count > lastPointIndex + 1)
			{
				[newPoints addObjectsFromArray:[_before.points subarrayWithRange:NSMakeRange(lastPointIndex + 1,  _before.points.count - (lastPointIndex + 1))]];
			}
		}
		else
		{
			[newPoints addObjectsFromArray:points];
		}
		_before.points = newPoints;
	}
	else
	{
		_before.points = points;
	}
	[self updateSegmentsForSnap:NO];
}

- (BOOL) isLastGpxPoint:(std::vector<SHARED_PTR<GpxPoint>>)gpxPoints index:(NSInteger)index
{
	if (index == gpxPoints.size() - 1)
	{
		return YES;
	}
	else
	{
		for (NSInteger i = index + 1; i < gpxPoints.size(); i++)
		{
			const auto& gp = gpxPoints[i];
			for (NSInteger k = 0; k < gp->routeToTarget.size(); k++)
			{
				const auto& seg = gp->routeToTarget[k];
				if (seg->getStartPointIndex() != seg->getEndPointIndex())
				{
					return NO;
				}
			}
			
		}
	}
	return YES;
}

- (void) fillPointsArray:(NSMutableArray<OAGpxTrkPt *> *)points
					 seg:(const SHARED_PTR<RouteSegmentResult> &)seg
		 includeEndPoint:(BOOL)includeEndPoint
{
	NSInteger ind = seg->getStartPointIndex();
	BOOL plus = seg->isForwardDirection();
	const auto& heightArray = seg->object->calculateHeightArray();
	while (ind != seg->getEndPointIndex())
	{
		[self addPointToArray:points seg:seg index:ind heightArray:heightArray];
		ind = plus ? ind + 1 : ind - 1;
	}
	if (includeEndPoint)
		[self addPointToArray:points seg:seg index:ind heightArray:heightArray];
}

- (void) addPointToArray:(NSMutableArray<OAGpxTrkPt *> *)points
					 seg:(const SHARED_PTR<RouteSegmentResult> &)seg
				   index:(NSInteger)index
			 heightArray:(const std::vector<double>&)heightArray
{
	LatLon l = seg->getPoint((int)index);
	OAGpxTrkPt *pt = [[OAGpxTrkPt alloc] init];
	if (heightArray.size() > index * 2 + 1)
		pt.elevation = heightArray[index * 2 + 1];
	pt.position = CLLocationCoordinate2DMake(l.lat, l.lon);
	[points addObject:pt];
}

- (BOOL) canSplit:(BOOL)after
{
    OAGpxTrkPt *selectedPoint = [self getPoints][self.selectedPointPosition];
    NSArray<OAGpxTrkSeg *> *segments = [self getBeforeSegments];
    for (OAGpxTrkSeg *segment in segments)
    {
        NSInteger i = [segment.points indexOfObject:selectedPoint];
        if (i != NSNotFound)
        {
            return after ? i < segment.points.count - 2 : i > 1;
        }
    }
    return NO;
}

- (NSInteger) findPointIndex:(OAGpxTrkPt *)point points:(NSArray<OAGpxTrkPt *> *)points firstIndex:(NSInteger)firstIndex
{
    double minDistance = DBL_MAX;
    NSInteger index = 0;
    for (NSInteger i = MAX(0, firstIndex); i < points.count; i++)
    {
        double distance = getDistance(point.getLatitude, point.getLongitude, points[i].getLatitude, points[i].getLongitude);
        if (distance < minDistance)
        {
            minDistance = distance;
            index = i;
        }
    }
    return index;
}

- (void) updateSegmentsForSnap
{
    [self updateSegmentsForSnap:YES];
}

- (void) updateSegmentsForSnap:(BOOL)both
{
    [self updateSegmentsForSnap:both calculateIfNeeded:YES];
}

- (void) updateSegmentsForSnap:(BOOL)both calculateIfNeeded:(BOOL)calculateIfNeeded
{
    _beforeSegments = [NSMutableArray new];
    _beforeSegmentsForSnap = [NSMutableArray new];
    [self recreateSegments:_beforeSegments
           segmentsForSnap:_beforeSegmentsForSnap
                    points:_before.points
         calculateIfNeeded:calculateIfNeeded];
    if (both)
    {
        _afterSegments = [NSMutableArray new];
        _afterSegmentsForSnap = [NSMutableArray new];
        [self recreateSegments:_afterSegments
               segmentsForSnap:_afterSegmentsForSnap
                        points:_after.points
             calculateIfNeeded:calculateIfNeeded];
    }
}


- (void) cancelSnapToRoad
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.progressDelegate)
            [self.progressDelegate hideProgressBar];
    });
    if (_calculationProgress != nullptr)
        _calculationProgress->cancelled = true;
}

- (OARouteCalculationParams *) getParams:(BOOL)resetCounter
{
    NSArray<NSArray<OAGpxTrkPt *> *> *pointsToCalculate = [self getPointsToCalculate];
    if (pointsToCalculate.count == 0)
        return nil;
    if (resetCounter)
    {
        _calculatedPairs = 0;
        _pointsToCalculateSize = pointsToCalculate.count;
    }
    NSArray<OAGpxTrkPt *> *currentPair = pointsToCalculate.firstObject;
    CLLocation *start = [[CLLocation alloc] initWithLatitude:currentPair.firstObject.getLatitude longitude:currentPair.firstObject.getLongitude];
    
    CLLocation *end = [[CLLocation alloc] initWithLatitude:currentPair.lastObject.getLatitude longitude:currentPair.lastObject.getLongitude];
    
//    RouteRegion reg = new RouteRegion();
//    reg.initRouteEncodingRule(0, "highway", RouteResultPreparation.UNMATCHED_HIGHWAY_TYPE);
    
    OARouteCalculationParams *params = [[OARouteCalculationParams alloc] init];
    params.inSnapToRoadMode = YES;
    params.start = start;
    
    OAApplicationMode *appMode = [OAApplicationMode valueOfStringKey:currentPair.firstObject.getProfileType def:OAApplicationMode.DEFAULT];
    params.end = end;
    [OARoutingHelper applyApplicationSettings:params appMode:appMode];
    params.mode = appMode;
    
    _calculationProgress = std::make_shared<RouteCalculationProgress>();
    params.calculationProgress = _calculationProgress;
    params.calculationProgressCallback = self;

    params.resultListener = self;
    
    _params = params;
    _currentPair = currentPair;
    
    return params;
}

- (NSArray<NSArray<OAGpxRtePt *> *> *) getRoutePoints
{
    NSMutableArray<NSArray <OAGpxRtePt *> *> *res = [NSMutableArray new];
    NSMutableArray<OAGpxTrkPt *> *plainPoints = [NSMutableArray arrayWithArray:_before.points];
    [plainPoints addObjectsFromArray:_after.points];
    NSMutableArray<OAGpxRtePt *> *points = [NSMutableArray new];
    for (OAGpxTrkPt *point in plainPoints)
    {
        if (point.getTrkPtIndex != -1)
        {
            [points addObject:[[OAGpxRtePt alloc] initWithTrkPt:point]];
            if (point.isGap)
            {
                [res addObject:[NSArray arrayWithArray:points]];
                [points removeAllObjects];
            }
        }
    }
    if (points.count > 0)
        [res addObject:points];
    return res;
}

- (OAGPXMutableDocument *) exportGpx:(NSString *)gpxName
{
    if (_before.points.count == 0)
        return nil;
    
    return [OARouteExporter exportRoute:gpxName trkSegments:[self getRouteSegments] points:nil];
}

- (NSArray<OAGpxTrkSeg *> *) getRouteSegments
{
    NSMutableArray<OAGpxTrkSeg *> *res = [NSMutableArray new];
    NSMutableArray<NSNumber *> *lastPointIndexes = [NSMutableArray new];
    for (NSInteger i = 0; i < _before.points.count; i++)
    {
        OAGpxTrkPt *pt = _before.points[i];
        if (pt.isGap)
            [lastPointIndexes addObject:@(i)];
    }
    if (lastPointIndexes.count == 0 || lastPointIndexes.lastObject.integerValue < _before.points.count - 1)
        [lastPointIndexes addObject:@(_before.points.count - 1)];
    NSInteger firstPointIndex = 0;
    for (NSNumber *lastPointIndex in lastPointIndexes)
    {
        OAGpxTrkSeg *segment = [self getRouteSegment:firstPointIndex endPointIndex:lastPointIndex.integerValue];
        if (segment)
            [res addObject:segment];
        firstPointIndex = lastPointIndex.integerValue + 1;
    }
    return res;
}

- (OAGpxTrkSeg *) getRouteSegment:(NSInteger)startPointIndex endPointIndex:(NSInteger)endPointIndex
{
    std::vector<std::shared_ptr<RouteSegmentResult>> route;
    NSMutableArray<CLLocation *> *locations = [NSMutableArray new];
    for (NSInteger i = startPointIndex; i < endPointIndex; i++)
    {
        NSArray<OAGpxTrkPt *> *pair = @[_before.points[i], _before.points[i + 1]];
        OARoadSegmentData *data = _roadSegmentData[pair];
        NSArray<OAGpxTrkPt *> *dataPoints = data != nil ? data.points : nil;
        std::vector<std::shared_ptr<RouteSegmentResult>> dataSegments;
        if (data)
            dataSegments = data.segments;
        if (dataPoints != nil && dataSegments.size() > 0)
        {
            for (OAGpxTrkPt *pt in dataPoints)
            {
                CLLocation *l = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(pt.getLatitude, pt.getLongitude) altitude:pt.elevation horizontalAccuracy:0 verticalAccuracy:0 timestamp:NSDate.date];
                
                [locations addObject:l];
            }
            [pair.lastObject setTrkPtIndex:(i + 1 < _before.points.count - 1 ? locations.count : locations.count - 1)];
            route.insert(route.end(), dataSegments.begin(), dataSegments.end());
        }
    }
    if (locations.count > 0 && route.size() > 0)
    {
        [_before.points[startPointIndex] setTrkPtIndex:0];
        return [[[OARouteExporter alloc] initWithName:@"" route:route locations:locations points:nil] generateRouteSegment];
    }
    else if (endPointIndex - startPointIndex >= 0)
    {
        OAGpxTrkSeg *segment = [[OAGpxTrkSeg alloc] init];
        segment.points = [_before.points subarrayWithRange:NSMakeRange(startPointIndex, (endPointIndex + 1) - startPointIndex)];
        return segment;
    }
    return nil;
}

#pragma mark OARouteCalculationProgressCallback

- (void)finish {
    _calculatedPairs = 0;
    _pointsToCalculateSize = 0;
}

- (void)requestPrivateAccessRouting
{
}

- (void)startProgress
{
}

- (void)updateProgress:(int)progress
{
    NSInteger pairs = _pointsToCalculateSize;
    if (pairs != 0)
    {
        double pairProgress = 100. / pairs;
        progress = (int) (_calculatedPairs * pairProgress + (double) progress / pairs);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.progressDelegate)
           [self.progressDelegate updateProgress:progress];
    });
}

#pragma mark - OARouteCalculationResultListener

- (void)onRouteCalculated:(OARouteCalculationResult *)route segment:(OAWalkingRouteSegment *)segment
{
    NSArray<CLLocation *> *locations = route.getRouteLocations;
    NSMutableArray<OAGpxTrkPt *> *pts = [NSMutableArray arrayWithCapacity:locations.count];
    double prevAltitude = NAN;
    for (CLLocation *loc in locations)
    {
        OAGpxTrkPt *pt = [[OAGpxTrkPt alloc] init];
        pt.position = loc.coordinate;
        if (loc.altitude > 0)
        {
            prevAltitude = loc.altitude;
            pt.elevation = prevAltitude;
        }
        else if (!isnan(prevAltitude))
        {
            pt.elevation = prevAltitude;
        }
        [pts addObject:pt];
    }
    _calculatedPairs++;
    [_params.calculationProgressCallback updateProgress:0];
    auto originalRoute = route.getOriginalRoute;
    if (originalRoute.size() == 0)
        originalRoute = { RoutePlannerFrontEnd::generateStraightLineSegment(DEFAULT_APP_MODE.getDefaultSpeed, [self waypointsToLocations:pts]) };
    
    _roadSegmentData[_currentPair] = [[OARoadSegmentData alloc] initWithAppMode:route.appMode start:_currentPair.firstObject end:_currentPair.lastObject points:pts segments:originalRoute];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateSegmentsForSnap:YES calculateIfNeeded:NO];
        if (self.progressDelegate)
            [self.progressDelegate refresh];
        OARouteCalculationParams *params = [self getParams:NO];
        if (params)
            [OARoutingHelper.sharedInstance startRouteCalculationThread:params paramsChanged:YES updateProgress:YES];
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.progressDelegate)
                    [self.progressDelegate hideProgressBar];
            });
        }
    });
}

- (std::vector<std::pair<double, double>>) waypointsToLocations:(NSArray<OAGpxTrkPt *> *)points
{
    std::vector<std::pair<double, double>> res;
    for (OAGpxTrkPt *pt in points)
    {
        res.push_back({pt.getLatitude, pt.getLongitude});
    }
    return res;
}

- (OsmAnd::ColorARGB) getLineColor
{
    if (_appMode == DEFAULT_APP_MODE)
        return OsmAnd::ColorARGB(0xff, 0xff, 0x88, 0x00);
    else
    {
        UIColor *profileColor = UIColorFromRGB(_appMode.getIconColor);
        
        CGFloat red, green, blue, alpha;
        [profileColor getRed:&red green:&green blue:&blue alpha:&alpha];
        return OsmAnd::ColorARGB(alpha * 255, red * 255, green * 255, blue * 255);
    }
}

@end
