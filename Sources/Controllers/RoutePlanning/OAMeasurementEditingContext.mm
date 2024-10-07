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
#import "OAGPXDocumentPrimitives.h"
#import "OARoadSegmentData.h"
#import "OARouteImporter.h"
#import "OARoutingHelper.h"
#import "OARouteCalculationParams.h"
#import "OARouteExporter.h"
#import "OAGpxRouteApproximation.h"
#import "OANativeUtilities.h"
#import "OsmAndSharedWrapper.h"

#include <CommonCollections.h>
#include <commonOsmAndCore.h>

#include <routeSegmentResult.h>
#include <routeCalculationProgress.h>
#include <routePlannerFrontEnd.h>
#include <gpxRouteApproximation.h>

static OAApplicationMode *DEFAULT_APP_MODE;

@interface OAMeasurementEditingContext() <OARouteCalculationProgressCallback, OARouteCalculationResultListener>

@end

@implementation OAMeasurementEditingContext
{
    OASTrkSegment *_before;
    NSMutableArray<OASTrkSegment *> *_beforeSegments;
    NSMutableArray<OASTrkSegment *> *_beforeSegmentsForSnap;
    OASTrkSegment *_after;
    NSMutableArray<OASTrkSegment *> *_afterSegments;
    NSMutableArray<OASTrkSegment *> *_afterSegmentsForSnap;
    
    NSInteger _calculatedPairs;
    NSInteger _pointsToCalculateSize;
    
    OARouteCalculationParams *_params;
    NSArray<OASWptPt *> *_currentPair;
    
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
        
        _before = [[OASTrkSegment alloc] init];
        _before.points = [@[] mutableCopy];
        _beforeSegments = [NSMutableArray new];
        _after = [[OASTrkSegment alloc] init];
        _after.points = [@[] mutableCopy];
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
        NSArray<OASWptPt *> *points = self.getPoints;
        hasDefaultPointsOnly = YES;
        for (OASWptPt *point in points)
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
    for (NSArray<OASWptPt *> *points in @[_before.points, _after.points])
    {
        if (points.count == 0)
            continue;
        
        for (NSUInteger i = 0; i < points.count - 1; i++)
        {
            OASWptPt *first = points[i];
            OASWptPt *second = points[i + 1];
            OARoadSegmentData *data = _roadSegmentData[@[first, second]];
            
            if (data == nil)
            {
                if (_appMode != OAApplicationMode.DEFAULT || !first.lastPoint || !second.firstPoint)
                {
                    double localDist = getDistance(first.getLatitude, first.getLongitude,
                                                   second.getLatitude, second.getLongitude);
                    if(!isnan(first.ele) && !isnan(second.ele) &&
                       first.ele != 0 && second.ele != 0)
                    {
                        double h = fabs(first.ele - second.ele);
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

- (NSArray<OASTrkSegment *> *) getBeforeTrkSegmentLine
{
    if (_beforeSegmentsForSnap != nil)
        return _beforeSegmentsForSnap;
    return _beforeSegments;
}

- (NSArray<OASTrkSegment *> *) getAfterTrkSegmentLine
{
    if (_afterSegmentsForSnap != nil)
        return _afterSegmentsForSnap;
    return _afterSegments;
}

- (NSArray<OASTrkSegment *> *)getBeforeSegments
{
    return _beforeSegments;
}

- (NSArray<OASTrkSegment *> *)getAfterSegments
{
    return _afterSegments;
}


- (NSArray<OASWptPt *> *) getAllPoints
{
    return [_before.points arrayByAddingObjectsFromArray:_after.points];
}

- (NSArray<OASWptPt *> *) getPoints
{
    return [self getBeforePoints];
}

- (NSArray<NSArray<OASWptPt *> *> *) getPointsSegments:(BOOL)plain route:(BOOL)route
{
	NSMutableArray<NSArray<OASWptPt *> *> *res = [NSMutableArray array];
	NSArray<OASWptPt *> *allPoints = self.getPoints;
	NSMutableArray<OASWptPt *> *segment = [NSMutableArray array];
	NSString *prevProfileType = nil;
	for (OASWptPt *point in allPoints)
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

- (NSArray<OASWptPt *> *) getBeforePoints
{
    return _before.points;
}

- (NSArray<OASWptPt *> *) getAfterPoints
{
    return _after.points;
}

- (NSInteger) getPointsCount
{
    return _before.points.count;
}

- (void) clearPoints
{
    _before.points = [@[] mutableCopy];
}

- (void) splitSegments:(NSInteger)position
{
    NSMutableArray<OASWptPt *> *points = [NSMutableArray new];
    [points addObjectsFromArray:_before.points];
    [points addObjectsFromArray:_after.points];
    
    _before.points = [[points subarrayWithRange:NSMakeRange(0, position)] mutableCopy];
    _after.points = [[points subarrayWithRange:NSMakeRange(position, points.count - position)] mutableCopy];
    
    [self updateSegmentsForSnap:YES];
}

- (void) preAddPoint:(NSInteger)position mode:(EOAAddPointMode)mode point:(OASWptPt *)point
{
    switch (mode) {
        case EOAAddPointModeUndefined:
        {
            if (_appMode != DEFAULT_APP_MODE)
            {
                [point setProfileTypeProfileType:_appMode.stringKey];
            }
            break;
        }
        case EOAAddPointModeAfter:
        {
            NSArray<OASWptPt *> *points = self.getBeforePoints;
            if (position > 0 && position <= points.count)
            {
                OASWptPt *prevPt = points.lastObject;
                if (prevPt.isGap)
                {
                    if (position == points.count && self.getAfterPoints.count == 0)
                    {
                        if (_appMode != DEFAULT_APP_MODE)
                        {
                            [point setProfileTypeProfileType:_appMode.stringKey];
                        }
                    }
                    else
                    {
                        [point setGap];
                        if (position > 1)
                        {
                            OASWptPt *pt = points[position - 2];
                            if ([pt hasProfile])
                            {
                                [prevPt setProfileTypeProfileType:pt.getProfileType];
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
                    [point setProfileTypeProfileType:prevPt.getProfileType];
                }
            }
            else if (_appMode != DEFAULT_APP_MODE)
            {
                [point setProfileTypeProfileType:_appMode.stringKey];
            }
            break;
        }
        case EOAAddPointModeBefore: {
            NSArray<OASWptPt *> *points = self.getAfterPoints;
            if (position >= -1 && position + 1 < points.count)
            {
                OASWptPt *nextPt = points[position + 1];
                if ([nextPt hasProfile])
                {
                    [point setProfileTypeProfileType:nextPt.getProfileType];
                }
            }
            else if (_appMode != DEFAULT_APP_MODE)
            {
                [point setProfileTypeProfileType:_appMode.stringKey];
            }
            break;
        }
    }
}

- (void) addPoint:(OASWptPt *)pt
{
    [self addPoint:pt mode:EOAAddPointModeUndefined];
}

- (void) addPoint:(OASWptPt *)pt mode:(EOAAddPointMode)mode
{
    if (mode == EOAAddPointModeAfter || mode == EOAAddPointModeBefore)
        [self preAddPoint:(mode == EOAAddPointModeBefore ? -1 : self.getBeforePoints.count) mode:mode point:pt];
    _before.points = [[_before.points arrayByAddingObject:pt] mutableCopy];
    [self updateSegmentsForSnap:NO];
}

- (void) addPoint:(NSInteger)position pt:(OASWptPt *)pt
{
    [self addPoint:position point:pt mode:EOAAddPointModeUndefined];
}

- (void) addPoint:(NSInteger)position point:(OASWptPt *)pt mode:(EOAAddPointMode)mode
{
    if (mode == EOAAddPointModeAfter || mode == EOAAddPointModeBefore)
        [self preAddPoint:position mode:mode point:pt];
    NSMutableArray<OASWptPt *> *points = [NSMutableArray arrayWithArray:_before.points];
    [points insertObject:pt atIndex:position];
    _before.points = points;
    [self updateSegmentsForSnap:false];
}

- (void) addPoints:(NSArray<OASWptPt *> *)points
{
    NSMutableArray<OASWptPt *> *pnts = [NSMutableArray arrayWithArray:_before.points];
    [pnts addObjectsFromArray:points];
    _before.points = pnts;
    [self updateSegmentsForSnap:NO];
}

- (void) setPoints:(NSArray<OASWptPt *> *)points
{
    _before.points =  [points mutableCopy];;
}

- (OASWptPt *) removePoint:(NSInteger)position updateSnapToRoad:(BOOL)updateSnapToRoad
{
    if (position < 0 || position >= _before.points.count)
        return [[OASWptPt alloc] init];
    NSMutableArray<OASWptPt *> *points = [NSMutableArray arrayWithArray:_before.points];
    OASWptPt *pt = points[position];
    if (updateSnapToRoad && position > 0 && pt.isGap)
    {
        OASWptPt *prevPt = _before.points[position - 1];
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
        OASWptPt *point = _before.points[pointIndex];
        OASWptPt *nextPoint = _before.points.count > pointIndex + 1 ? _before.points[pointIndex + 1] : nil;
        [point setGap];
        
        NSMutableArray<OASWptPt *> *points = [NSMutableArray arrayWithArray:_before.points];
        [points removeObjectAtIndex:pointIndex];
        [points insertObject:point atIndex:pointIndex];
        _before.points = points;
        
        if (point)
            [_roadSegmentData removeObjectForKey:[NSArray arrayWithObjects:point, nextPoint, nil]];
        [self updateSegmentsForSnap:NO];
    }
}

- (void) joinPoints:(NSInteger) selectedPointPosition
{
    OASWptPt *gapPoint = [[OASWptPt alloc] init];
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
        [gapPoint removeProfileType];

        NSMutableArray<OASWptPt *> *points = [NSMutableArray arrayWithArray:_before.points];
        [points removeObjectAtIndex:gapIndex];
        [points insertObject:gapPoint atIndex:gapIndex];
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
    _before.points = [@[] mutableCopy];
    [_beforeSegments removeAllObjects];
    if (_beforeSegmentsForSnap != nil)
        [_beforeSegmentsForSnap removeAllObjects];
}

- (void) clearAfterSegments
{
    _after.points = [@[] mutableCopy];
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
    return _selectedPointPosition == self.getPointsCount - 1;
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
        return _selectedPointPosition == self.getPointsCount - 1;
    else
        return [self isBorderPointSelected:selectedPointPosition first:NO];
}

- (BOOL) isBorderPointSelected:(NSInteger) selectedPointPosition first:(BOOL)first
{
    NSArray<OASWptPt *> *points = [self getPoints];
    if (selectedPointPosition < 0 || points.count < selectedPointPosition)
        return NO;

    OASWptPt *selectedPoint = points[selectedPointPosition];
    NSArray <OASTrkSegment *> *segments = [NSArray arrayWithArray: [self getBeforeSegments]];
    NSInteger count = 0;
    for (OASTrkSegment *segment in segments)
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

- (NSArray<NSArray<OASWptPt *> *> *) getPointsToCalculate
{
    NSMutableArray<NSArray<OASWptPt *> *> *res = [NSMutableArray new];
    for (NSArray<OASWptPt *> *points in @[_before.points, _after.points])
    {
        for (NSInteger i = 0; i < (NSInteger) points.count - 1; i++)
        {
            OASWptPt *startPoint = points[i];
            OASWptPt *endPoint = points[i + 1];
            NSArray<OASWptPt *> *pair = @[startPoint, endPoint];
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
  
- (void)recreateSegments:(NSMutableArray<OASTrkSegment *> *)segments segmentsForSnap:(NSMutableArray<OASTrkSegment *> *)segmentsForSnap points:(NSArray<OASWptPt *> *)points calculateIfNeeded:(BOOL)calculateIfNeeded
{
    NSMutableArray<NSNumber *> *roadSegmentIndexes = [NSMutableArray new];
    OASTrkSegment *s = [[OASTrkSegment alloc] init];
    NSMutableArray<OASWptPt *> *sPnts = [NSMutableArray array];
    [segments addObject:s];
    BOOL defaultMode = YES;
    if (points.count > 1)
    {
        for (NSInteger i = 0; i < points.count; i++)
        {
            OASWptPt *point = points[i];
            [sPnts addObject:point];
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
                    if (sPnts.count > 0)
                    {
                        s.points = sPnts;
                        s = [[OASTrkSegment alloc] init];
                        sPnts = [NSMutableArray array];
                        [segments addObject:s];
                        defaultMode = YES;
                    }
                }
            }
        }
    }
    else
    {
        [sPnts addObjectsFromArray:points];
    }
    s.points = sPnts;
    if (s.points.count == 0)
        [segments removeObject:s];
    
    if (segments.count > 0)
    {
        for (OASTrkSegment *segment in segments)
        {
            OASTrkSegment *segmentForSnap = [[OASTrkSegment alloc] init];
            NSMutableArray<OASWptPt *> *pnts = [NSMutableArray new];
            for (NSInteger i = 0; i < (NSInteger) segment.points.count - 1; i++)
            {
                NSArray<OASWptPt *> *pair = @[segment.points[i], segment.points[i + 1]];
                OARoadSegmentData *data = _roadSegmentData[pair];
                NSArray<OASWptPt *> *pts = data != nil ? data.gpxPoints : nil;
                if (pts != nil)
                {
                    [pnts addObjectsFromArray:pts];
                }
                else
                {
                    if (calculateIfNeeded && [roadSegmentIndexes containsObject:@(segmentsForSnap.count)])
                        [self scheduleRouteCalculateIfNotEmpty];
                    
                    [pnts addObjectsFromArray:pair];
                }
            }
            if (pnts.count == 0)
                [pnts addObjectsFromArray:segment.points];
            segmentForSnap.points = pnts;
            [segmentsForSnap addObject:segmentForSnap];
        }
    }
    else if (points.count > 0)
    {
        OASTrkSegment *segmentForSnap = [[OASTrkSegment alloc] init];
        segmentForSnap.points = [points mutableCopy];
        [segmentsForSnap addObject:segmentForSnap];
    }
}

- (NSArray<OASWptPt *> *)collectRoutePointsFromSegment:(OASTrkSegment *)segment segmentInd:(NSInteger)segmentInd
{
    NSArray<OASWptPt *> *routePointsRte = [_gpxData.gpxFile getRoutePointsRouteIndex:(int)segmentInd];
    NSMutableArray<OASWptPt *> *routePoints = [NSMutableArray arrayWithArray:routePointsRte];
    NSArray<OASWptPt *> *points = segment.points;
    NSInteger prevPointIndex = 0;
    if (routePoints.count == 0 && points.count > 1)
    {
        [routePoints addObject:points[0]];
        [routePoints addObject:points[points.count - 1]];
    }
    
    OARouteImporter *routeImporter = [[OARouteImporter alloc] initWithTrkSeg:segment segmentRoutePoints:routePoints];
    auto routeSegments = [routeImporter importRoute];
    
    for (NSInteger i = 0; i < (NSInteger) routePoints.count - 1; i++)
    {
        NSArray<OASWptPt *> *pair = @[routePoints[i], routePoints[i + 1]];
        NSInteger startIndex = pair.firstObject.getTrkPtIndex;
        if (startIndex < 0 || startIndex < prevPointIndex || startIndex >= points.count)
            startIndex = [self findPointIndex:pair.firstObject points:points firstIndex:prevPointIndex];
        NSInteger endIndex = pair.lastObject.getTrkPtIndex;
        if (endIndex < 0 || endIndex < startIndex || endIndex >= points.count)
            endIndex = [self findPointIndex:pair.lastObject points:points firstIndex:startIndex];
        if (startIndex >= 0 && endIndex >= 0)
        {
            NSMutableArray<OASWptPt *> *pairPoints = [NSMutableArray new];
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
    OASGpxFile *gpxFile = gpxData.gpxFile;
    if (gpxFile.hasRtePt && !gpxFile.hasTrkPt)
    {
        [self addPoints:gpxFile.getRoutePoints];
        return;
    }
    NSArray<OASTrkSegment *> *segments = [gpxData.gpxFile getNonEmptyTrkSegmentsRoutesOnly:NO];
    if (segments.count == 0)
        return;

    if (_selectedSegment != -1 && segments.count > _selectedSegment)
    {
        OASTrkSegment *seg = segments[_selectedSegment];
        if (seg.hasRoute)
            [self addPoints:[self collectRoutePointsFromSegment:seg segmentInd:_selectedSegment]];
        else
            [self addPoints:seg.points];
    }
    else
    {
        for (NSInteger si = 0; si < segments.count; si++)
        {
            OASTrkSegment *segment = segments[si];
            if (segment.hasRoute)
            {
                NSArray<OASWptPt *> *routePoints = [self collectRoutePointsFromSegment:segment segmentInd:si];
                if (routePoints.count > 0 && si < segments.count - 1)
                    [routePoints[routePoints.count - 1] setGap];
                [self addPoints:routePoints];
            }
            else
            {
                NSArray<OASWptPt *> *points = segment.points;
                [self addPoints:points];
                if (points.count > 0 && si < segments.count - 1)
                    [points[points.count - 1] setGap];
            }
        }
    }
}

- (NSArray<OASWptPt *> *) setPoints:(OAGpxRouteApproximation *)gpxApproximation originalPoints:(NSArray<OASWptPt *> *)originalPoints mode:(OAApplicationMode *)mode
{
	if (gpxApproximation == nil || gpxApproximation.gpxApproximation->finalPoints.size() == 0 || gpxApproximation.gpxApproximation->fullRoute.size() == 0)
		return nil;
	
	NSMutableArray<OASWptPt *> *routePoints = [NSMutableArray array];
	const auto gpxPoints = gpxApproximation.gpxApproximation->finalPoints;
	for (NSInteger i = 0; i < gpxPoints.size(); i++)
	{
		const auto& gp1 = gpxPoints[i];
		BOOL lastGpxPoint = [self isLastGpxPoint:gpxPoints index:i];
		NSMutableArray<OASWptPt *> *points = [NSMutableArray array];
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
			OASWptPt *wp1 = [[OASWptPt alloc] init];
            wp1.lat = gp1->lat;
            wp1.lon = gp1->lon;
			[wp1 setProfileTypeProfileType:mode.stringKey];
			[routePoints addObject:wp1];
			OASWptPt *wp2 = [[OASWptPt alloc] init];
			if (lastGpxPoint)
			{
                OASWptPt *lastObject = points.lastObject;
				wp2.lat = lastObject.lat;
                wp2.lon = lastObject.lon;
				[routePoints addObject:wp2];
			}
			else
			{
				const auto& gp2 = gpxPoints[i + 1];
                wp2.lat = gp2->lat;
                wp2.lon = gp2->lon;
			}
			[wp2 setProfileTypeProfileType:mode.stringKey];
			NSArray<OASWptPt *> *pair = @[wp1, wp2];
			_roadSegmentData[pair] = [[OARoadSegmentData alloc] initWithAppMode:_appMode start:pair.firstObject end:pair.lastObject points:points segments:segments];
		}
		if (lastGpxPoint)
		{
			break;
		}
	}
	OASWptPt *lastOriginalPoint = originalPoints.lastObject;
	OASWptPt *lastRoutePoint = routePoints.lastObject;
	if (lastOriginalPoint.isGap)
		[lastRoutePoint setGap];
	
	[self replacePoints:originalPoints points:routePoints];
	return routePoints;
}

- (void) replacePoints:(NSArray<OASWptPt *> *)originalPoints points:(NSArray<OASWptPt *> *)points
{
	if (originalPoints.count > 1)
	{
		NSInteger firstPointIndex = [_before.points indexOfObject:originalPoints.firstObject];
		NSInteger lastPointIndex = [_before.points indexOfObject:originalPoints.lastObject];
		NSMutableArray<OASWptPt *> *newPoints = [NSMutableArray array];
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
        _before.points = [points mutableCopy];
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

- (void) fillPointsArray:(NSMutableArray<OASWptPt *> *)points
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

- (void) addPointToArray:(NSMutableArray<OASWptPt *> *)points
					 seg:(const SHARED_PTR<RouteSegmentResult> &)seg
				   index:(NSInteger)index
			 heightArray:(const std::vector<double>&)heightArray
{
	LatLon l = seg->getPoint((int)index);
	OASWptPt *pt = [[OASWptPt alloc] init];
	if (heightArray.size() > index * 2 + 1)
		pt.ele = heightArray[index * 2 + 1];
    pt.lat = l.lat;
    pt.lon = l.lon;
	[points addObject:pt];
}

- (BOOL) canSplit:(BOOL)after
{
    NSArray<OASWptPt *> *points = [self getPoints];
    if (self.selectedPointPosition < 0 || points.count < self.selectedPointPosition)
        return NO;

    OASWptPt *selectedPoint = points[self.selectedPointPosition];
    NSArray<OASTrkSegment *> *segments = [self getBeforeSegments];
    for (OASTrkSegment *segment in segments)
    {
        NSInteger i = [segment.points indexOfObject:selectedPoint];
        if (i != NSNotFound)
        {
            return after ? i < segment.points.count - 2 : i > 1;
        }
    }
    return NO;
}

- (NSInteger) findPointIndex:(OASWptPt *)point points:(NSArray<OASWptPt *> *)points firstIndex:(NSInteger)firstIndex
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
    NSArray<NSArray<OASWptPt *> *> *pointsToCalculate = [self getPointsToCalculate];
    if (pointsToCalculate.count == 0)
        return nil;
    if (resetCounter)
    {
        _calculatedPairs = 0;
        _pointsToCalculateSize = pointsToCalculate.count;
    }
    NSArray<OASWptPt *> *currentPair = pointsToCalculate.firstObject;
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

- (NSArray<NSArray<OASWptPt *> *> *) getRoutePoints
{
    NSMutableArray<NSArray <OASWptPt *> *> *res = [NSMutableArray new];
    NSMutableArray<OASWptPt *> *plainPoints = [NSMutableArray arrayWithArray:_before.points];
    [plainPoints addObjectsFromArray:_after.points];
    NSMutableArray<OASWptPt *> *points = [NSMutableArray new];
    for (OASWptPt *point in plainPoints)
    {
        if (point.getTrkPtIndex != -1)
        {
            [points addObject:point];
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

- (OASGpxFile *) exportGpx:(NSString *)gpxName
{
    if (_before.points.count == 0)
        return nil;
    
    return [OARouteExporter exportRoute:gpxName trkSegments:[self getRouteSegments] points:nil];
}

- (NSArray<OASTrkSegment *> *) getRouteSegments
{
    NSMutableArray<OASTrkSegment *> *res = [NSMutableArray new];
    NSMutableArray<NSNumber *> *lastPointIndexes = [NSMutableArray new];
    for (NSInteger i = 0; i < _before.points.count; i++)
    {
        OASWptPt *pt = _before.points[i];
        if (pt.isGap)
            [lastPointIndexes addObject:@(i)];
    }
    if (lastPointIndexes.count == 0 || lastPointIndexes.lastObject.integerValue < _before.points.count - 1)
        [lastPointIndexes addObject:@(_before.points.count - 1)];
    NSInteger firstPointIndex = 0;
    for (NSNumber *lastPointIndex in lastPointIndexes)
    {
        OASTrkSegment *segment = [self getRouteSegment:firstPointIndex endPointIndex:lastPointIndex.integerValue];
        if (segment)
            [res addObject:segment];
        firstPointIndex = lastPointIndex.integerValue + 1;
    }
    return res;
}

- (OASTrkSegment *)getRouteSegment:(NSInteger)startPointIndex endPointIndex:(NSInteger)endPointIndex
{
    std::vector<std::shared_ptr<RouteSegmentResult>> route;
    NSMutableArray<CLLocation *> *locations = [NSMutableArray new];
    std::vector<int> routePointIndexes;
    routePointIndexes.push_back(0);
    for (NSInteger i = startPointIndex; i < endPointIndex; i++)
    {
        NSArray<OASWptPt *> *pair = @[_before.points[i], _before.points[i + 1]];
        OARoadSegmentData *data = _roadSegmentData[pair];
        NSArray<OASWptPt *> *dataPoints = data != nil ? data.gpxPoints : nil;
        std::vector<std::shared_ptr<RouteSegmentResult>> dataSegments;
        if (data)
            dataSegments = data.segments;
        if (dataPoints != nil && dataSegments.size() > 0)
        {
            for (OASWptPt *pt in dataPoints)
            {
                CLLocation *l = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(pt.getLatitude, pt.getLongitude) altitude:pt.ele horizontalAccuracy:0 verticalAccuracy:0 timestamp:NSDate.date];
                
                [locations addObject:l];
            }
            [pair.lastObject setTrkPtIndexIndex:(int)(i + 1 < _before.points.count - 1 ? locations.count : locations.count - 1)];
            route.insert(route.end(), dataSegments.begin(), dataSegments.end());
            routePointIndexes.push_back((int) (i + 1 == endPointIndex ? locations.count - 1 : locations.count));
        }
    }
    if (locations.count > 0 && route.size() > 0)
    {
        [_before.points[startPointIndex] setTrkPtIndexIndex:0];
        return [[[OARouteExporter alloc] initWithName:@"" route:route locations:locations routePointIndexes:routePointIndexes points:nil] generateRouteSegment];
    }
    else if (endPointIndex - startPointIndex >= 0)
    {
        OASTrkSegment *segment = [[OASTrkSegment alloc] init];
        segment.points = [[_before.points subarrayWithRange:NSMakeRange(startPointIndex, (endPointIndex + 1) - startPointIndex)] mutableCopy];
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

- (void)onRouteCalculated:(OARouteCalculationResult *)route
                  segment:(OAWalkingRouteSegment *)segment
                    start:(CLLocation *)start
                      end:(CLLocation *)end
{
    NSArray<CLLocation *> *locations = route.getRouteLocations;
    NSMutableArray<OASWptPt *> *pts = [NSMutableArray arrayWithCapacity:locations.count];
    double prevAltitude = NAN;
    for (CLLocation *loc in locations)
    {
        OASWptPt *pt = [[OASWptPt alloc] init];
        pt.lat = loc.coordinate.latitude;
        pt.lon = loc.coordinate.longitude;
        if (loc.altitude > 0)
        {
            prevAltitude = loc.altitude;
            pt.ele = prevAltitude;
        }
        else if (!isnan(prevAltitude))
        {
            pt.ele = prevAltitude;
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

- (std::vector<std::pair<double, double>>) waypointsToLocations:(NSArray<OASWptPt *> *)points
{
    std::vector<std::pair<double, double>> res;
    for (OASWptPt *pt in points)
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
        return [_appMode.getProfileColor toFColorARGB];
}

@end
