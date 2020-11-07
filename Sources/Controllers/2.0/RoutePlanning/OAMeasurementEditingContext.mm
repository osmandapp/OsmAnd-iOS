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
#import "OAGPXDocumentPrimitives.h"

#include <CommonCollections.h>
#include <commonOsmAndCore.h>


// TODO: implement RoadSegmentData



static OAApplicationMode *DEFAULT_APP_MODE;

@implementation OAMeasurementEditingContext
{
    OAGpxTrkSeg *_before;
    OAGpxTrkSeg *_beforeCacheForSnap;
    OAGpxTrkSeg *_after;
    OAGpxTrkSeg *_afterCacheForSnap;
    
    NSInteger _calculatedPairs;
    NSInteger _pointsToCalculateSize;
    
    
    //    private SnapToRoadProgressListener progressListener;
    
    //    private RouteCalculationProgress calculationProgress;
    //    private Map<Pair<WptPt, WptPt>, RoadSegmentData> roadSegmentData = new ConcurrentHashMap<>();
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
        _lastCalculationMode = WHOLE_TRACK;
        _appMode = DEFAULT_APP_MODE;
        _addPointMode = EOAAddPointModeUndefined;
        
        _before = [[OAGpxTrkSeg alloc] init];
        _before.points = @[];
        _after = [[OAGpxTrkSeg alloc] init];
        _after.points = @[];
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

//- (void) updateCacheForSnap
//{
//    [self updateCacheForSnap:YES];
//}

//public List<WptPt> getOriginalTrackPointList() {
//    MeasurementModeCommand command = commandManager.getLastCommand();
//    if (command.getType() == APPROXIMATE_POINTS) {
//        return ((ApplyGpxApproximationCommand) command).getPoints();
//    }
//    return null;
//}


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
            //            RoadSegmentData data = this.roadSegmentData.get(pair);
            //            if (data == null) {
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
            //            }
//            else
//            {
//                distance += data.getDistance();
//            }
        }
    }
    return distance;
}

//public boolean hasRoute() {
//    return !roadSegmentData.isEmpty();
//}
//
//public void clearSnappedToRoadPoints() {
//    roadSegmentData.clear();
//}
//
- (OAGpxTrkSeg *) getBeforeTrkSegmentLine
{
    if (_beforeCacheForSnap != nil)
        return _beforeCacheForSnap;
    return _before;
}

- (OAGpxTrkSeg *) getAfterTrkSegmentLine
{
    if (_afterCacheForSnap != nil) {
        return _afterCacheForSnap;
    }
    return _after;
}

- (NSArray<OAGpxTrkPt *> *) getAllPoints
{
    return [_before.points arrayByAddingObjectsFromArray:_after.points];
}

- (NSArray<OAGpxTrkPt *> *) getPoints
{
    return [self getBeforePoints];
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

//public List<RouteSegmentResult> getAllRouteSegments() {
//    List<RouteSegmentResult> allSegments = new ArrayList<>();
//    for (Pair<WptPt, WptPt> key : getOrderedRoadSegmentDataKeys()) {
//        RoadSegmentData data = roadSegmentData.get(key);
//        if (data != null) {
//            List<RouteSegmentResult> segments = data.getSegments();
//            if (segments != null) {
//                allSegments.addAll(segments);
//            }
//        }
//    }
//    return allSegments.size() > 0 ? allSegments : null;
//}

- (void) splitSegments:(NSInteger)position
{
    NSMutableArray<OAGpxTrkPt *> *points = [NSMutableArray new];
    [points addObjectsFromArray:_before.points];
    [points addObjectsFromArray:_after.points];
    
    _before.points = [points subarrayWithRange:NSMakeRange(0, position)];
    _after.points = [points subarrayWithRange:NSMakeRange(position, points.count - position)];
    
//    [self updateCacheForSnap:YES];
}

//- (void) preAddPoint:(NSInteger)position mode:(EOAAddPointMode)mode point:(OAGpxTrkPt *)point
//{
//    switch (mode) {
//        case EOAAddPointModeUndefined:
//        {
//            //                if (appMode != MeasurementEditingContext.DEFAULT_APP_MODE) {
//            //                    point.setProfileType(appMode.getStringKey());
//            //                }
//            break;
//        }
//        case EOAAddPointModeAfter:
//        {
//            NSArray<OAGpxTrkPt *> *points = [self getBeforePoints];
//            if (position > 0 && position <= points.count)
//            {
//                OAGpxTrkPt *prevPt = points[position - 1];
//                //                    if (prevPt.isGap()) {
//                //                        point.setGap();
//                if (position > 1)
//                {
//                    OAGpxTrkPt *pt = points[position - 2];
//                    if (pt.hasProfile()) {
//                        prevPt.setProfileType(pt.getProfileType());
//                    } else {
//                        prevPt.removeProfileType();
//                    }
//                }
//                //                    } else if (prevPt.hasProfile()) {
//                //                        point.setProfileType(prevPt.getProfileType());
//                //                    }
//            } else if (appMode != MeasurementEditingContext.DEFAULT_APP_MODE) {
//                point.setProfileType(appMode.getStringKey());
//            }
//            break;
//        }
//        case EOAAddPointModeBefore: {
//            List<WptPt> points = getAfterPoints();
//            if (position >= -1 && position + 1 < points.size()) {
//                WptPt nextPt = points.get(position + 1);
//                if (nextPt.hasProfile()) {
//                    point.setProfileType(nextPt.getProfileType());
//                }
//            } else if (appMode != MeasurementEditingContext.DEFAULT_APP_MODE) {
//                point.setProfileType(appMode.getStringKey());
//            }
//            break;
//        }
//    }
//}

- (void) addPoint:(OAGpxTrkPt *)pt
{
    _before.points = [_before.points arrayByAddingObject:pt];
//    [self updateCacheForSnap:NO];
}

- (void) addPoint:(OAGpxTrkPt *)pt mode:(EOAAddPointMode)mode
{
//    if (mode == EOAAddPointModeAfter || mode == EOAAddPointModeBefore)
//        self preAddPoint:(additionMode == AdditionMode.ADD_BEFORE ? -1 : getBeforePoints().size(), additionMode, pt);

    _before.points = [_before.points arrayByAddingObject:pt];
//    updateSegmentsForSnap(false);
}

- (void) addPoint:(NSInteger)position pt:(OAGpxTrkPt *)pt
{
    NSMutableArray<OAGpxTrkPt *> *points = [NSMutableArray arrayWithArray:_before.points];
    [points insertObject:pt atIndex:position];
    _before.points = points;
//    [self updateCacheForSnap:NO];
}

- (void) addPoints:(NSArray<OAGpxTrkPt *> *)points
{
    NSMutableArray<OAGpxTrkPt *> *pnts = [NSMutableArray arrayWithArray:_before.points];
    [pnts addObjectsFromArray:points];
    _before.points = pnts;
//    [self updateCacheForSnap:NO];
}

- (OAGpxTrkPt *) removePoint:(NSInteger)position updateSnapToRoad:(BOOL)updateSnapToRoad
{
    if (position < 0 || position >= _before.points.count)
        return [[OAGpxTrkPt alloc] init];
    NSMutableArray<OAGpxTrkPt *> *points = [NSMutableArray arrayWithArray:_before.points];
    OAGpxTrkPt *pt = points[position];
    [points removeObjectAtIndex:position];
    _before.points = points;
//    if (updateSnapToRoad)
//        [self updateCacheForSnap:NO];
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

- (void) clearSegments
{
    [self clearBeforeSegments];
    [self clearAfterSegments];
//    [self clearSnappedToRoadPoints];
}

- (void) clearBeforeSegments
{
    _before.points = [NSArray new];
    if (_beforeCacheForSnap != nil)
        _beforeCacheForSnap.points = [NSArray new];
}

- (void) clearAfterSegments
{
    _after.points = [NSArray new];
    if (_afterCacheForSnap != nil)
        _afterCacheForSnap.points = [NSArray new];
}

- (BOOL) isFirstPointSelected
{
    return _selectedPointPosition == 0;
}

- (BOOL) isLastPointSelected
{
    return _selectedPointPosition == [self getPoints].count - 1;
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
    NSString *profileType = nil; //[self getPoints][pointPosition].profileType;
    return [OAApplicationMode valueOfStringKey:profileType def:OAApplicationMode.DEFAULT];
}

//public void scheduleRouteCalculateIfNotEmpty() {
//    if (application == null || (before.points.size() == 0 && after.points.size() == 0)) {
//        return;
//    }
//    RoutingHelper routingHelper = application.getRoutingHelper();
//    if (progressListener != null && !routingHelper.isRouteBeingCalculated()) {
//        RouteCalculationParams params = getParams(true);
//        if (params != null) {
//            routingHelper.startRouteCalculationThread(params, true, true);
//            application.runInUIThread(new Runnable() {
//                @Override
//                public void run() {
//                    progressListener.showProgressBar();
//                }
//            });
//        }
//    }
//}
//
//private List<Pair<WptPt, WptPt>> getPointsToCalculate() {
//    List<Pair<WptPt, WptPt>> res = new ArrayList<>();
//    for (List<WptPt> points : Arrays.asList(before.points, after.points)) {
//        for (int i = 0; i < points.size() - 1; i++) {
//            Pair<WptPt, WptPt> pair = new Pair<>(points.get(i), points.get(i + 1));
//            if (roadSegmentData.get(pair) == null) {
//                res.add(pair);
//            }
//        }
//    }
//    return res;
//}
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
//
//private void recreateCacheForSnap(TrkSegment cache, TrkSegment original, boolean calculateIfNeeded) {
//    boolean hasDefaultModeOnly = true;
//    if (original.points.size() > 1) {
//        for (int i = 0; i < original.points.size(); i++) {
//            String profileType = original.points.get(i).getProfileType();
//            if (profileType != null && !profileType.equals(DEFAULT_APP_MODE.getStringKey())) {
//                hasDefaultModeOnly = false;
//                break;
//            }
//        }
//    }
//    if (original.points.size() > 1) {
//        for (int i = 0; i < original.points.size() - 1; i++) {
//            Pair<WptPt, WptPt> pair = new Pair<>(original.points.get(i), original.points.get(i + 1));
//            RoadSegmentData data = this.roadSegmentData.get(pair);
//            List<WptPt> pts = data != null ? data.getPoints() : null;
//            if (pts != null) {
//                cache.points.addAll(pts);
//            } else {
//                if (calculateIfNeeded && !hasDefaultModeOnly) {
//                    scheduleRouteCalculateIfNotEmpty();
//                }
//                cache.points.addAll(Arrays.asList(pair.first, pair.second));
//            }
//        }
//    } else {
//        cache.points.addAll(original.points);
//    }
//}

- (void) addPoints
{
    OAGpxData *gpxData = _gpxData;
    if (gpxData == nil || gpxData.trkSegment == nil || gpxData.trkSegment.points.count == 0)
        return;
    
    NSArray<OAGpxTrkPt *> *points = gpxData.trkSegment.points;
//    if (isTrackSnappedToRoad()) {
//        RouteImporter routeImporter = new RouteImporter(gpxData.getGpxFile());
//        List<RouteSegmentResult> segments = routeImporter.importRoute();
//        List<WptPt> routePoints = gpxData.getGpxFile().getRoutePoints();
//        int prevPointIndex = 0;
//        if (routePoints.isEmpty() && points.size() > 1) {
//            routePoints.add(points.get(0));
//            routePoints.add(points.get(points.size() - 1));
//        }
//        for (int i = 0; i < routePoints.size() - 1; i++) {
//            Pair<WptPt, WptPt> pair = new Pair<>(routePoints.get(i), routePoints.get(i + 1));
//            int startIndex = pair.first.getTrkPtIndex();
//            if (startIndex < 0 || startIndex < prevPointIndex || startIndex >= points.size()) {
//                startIndex = findPointIndex(pair.first, points, prevPointIndex);
//            }
//            int endIndex = pair.second.getTrkPtIndex();
//            if (endIndex < 0 || endIndex < startIndex || endIndex >= points.size()) {
//                endIndex = findPointIndex(pair.second, points, startIndex);
//            }
//            if (startIndex >= 0 && endIndex >= 0) {
//                List<WptPt> pairPoints = new ArrayList<>();
//                for (int j = startIndex; j < endIndex && j < points.size(); j++) {
//                    pairPoints.add(points.get(j));
//                    prevPointIndex = j;
//                }
//                if (points.size() > prevPointIndex + 1) {
//                    pairPoints.add(points.get(prevPointIndex + 1));
//                }
//                Iterator<RouteSegmentResult> it = segments.iterator();
//                int k = endIndex - startIndex - 1;
//                List<RouteSegmentResult> pairSegments = new ArrayList<>();
//                if (k == 0 && !segments.isEmpty()) {
//                    pairSegments.add(segments.remove(0));
//                } else {
//                    while (it.hasNext() && k > 0) {
//                        RouteSegmentResult s = it.next();
//                        pairSegments.add(s);
//                        it.remove();
//                        k -= Math.abs(s.getEndPointIndex() - s.getStartPointIndex());
//                    }
//                }
//                ApplicationMode appMode = ApplicationMode.valueOfStringKey(pair.first.getProfileType(), DEFAULT_APP_MODE);
//                roadSegmentData.put(pair, new RoadSegmentData(appMode, pair.first, pair.second, pairPoints, pairSegments));
//            }
//        }
//        addPoints(routePoints);
//    } else {
    [self addPoints:points];
//    }
}

//- (void) setPoints(GpxRouteApproximation gpxApproximation, ApplicationMode mode) {
//    if (gpxApproximation == null || Algorithms.isEmpty(gpxApproximation.finalPoints) || Algorithms.isEmpty(gpxApproximation.result)) {
//        return;
//    }
//    roadSegmentData.clear();
//    List<WptPt> routePoints = new ArrayList<>();
//    List<GpxPoint> gpxPoints = gpxApproximation.finalPoints;
//    for (int i = 0; i < gpxPoints.size(); i++) {
//        GpxPoint gp1 = gpxPoints.get(i);
//        boolean lastGpxPoint = isLastGpxPoint(gpxPoints, i);
//        List<WptPt> points = new ArrayList<>();
//        List<RouteSegmentResult> segments = new ArrayList<>();
//        for (int k = 0; k < gp1.routeToTarget.size(); k++) {
//            RouteSegmentResult seg = gp1.routeToTarget.get(k);
//            if (seg.getStartPointIndex() != seg.getEndPointIndex()) {
//                segments.add(seg);
//            }
//        }
//        for (int k = 0; k < segments.size(); k++) {
//            RouteSegmentResult seg = segments.get(k);
//            fillPointsArray(points, seg, lastGpxPoint && k == segments.size() - 1);
//        }
//        if (!points.isEmpty()) {
//            WptPt wp1 = new WptPt();
//            wp1.lat = gp1.loc.getLatitude();
//            wp1.lon = gp1.loc.getLongitude();
//            wp1.setProfileType(mode.getStringKey());
//            routePoints.add(wp1);
//            WptPt wp2 = new WptPt();
//            if (lastGpxPoint) {
//                wp2.lat = points.get(points.size() - 1).getLatitude();
//                wp2.lon = points.get(points.size() - 1).getLongitude();
//                routePoints.add(wp2);
//            } else {
//                GpxPoint gp2 = gpxPoints.get(i + 1);
//                wp2.lat = gp2.loc.getLatitude();
//                wp2.lon = gp2.loc.getLongitude();
//            }
//            wp2.setProfileType(mode.getStringKey());
//            Pair<WptPt, WptPt> pair = new Pair<>(wp1, wp2);
//            roadSegmentData.put(pair, new RoadSegmentData(appMode, pair.first, pair.second, points, segments));
//        }
//        if (lastGpxPoint) {
//            break;
//        }
//    }
//    addPoints(routePoints);
//}

- (BOOL) isLastGpxPoint:(NSArray<OAGpxTrkPt *> *)gpxPoints index:(NSInteger)index
{
    if (index == gpxPoints.count - 1)
    {
        return YES;
    }
    else
    {
//        for (NSInteger i = index + 1; i < gpxPoints.count; i++)
//        {
//            GpxPoint gp = gpxPoints.get(i);
//            for (int k = 0; k < gp.routeToTarget.size(); k++) {
//                RouteSegmentResult seg = gp.routeToTarget.get(k);
//                if (seg.getStartPointIndex() != seg.getEndPointIndex()) {
//                    return false;
//                }
//            }
//
//        }
    }
    return YES;
}

//- (void) fillPointsArray:(List<WptPt> points, RouteSegmentResult seg, boolean includeEndPoint) {
//    int ind = seg.getStartPointIndex();
//    boolean plus = seg.isForwardDirection();
//    float[] heightArray = seg.getObject().calculateHeightArray();
//    while (ind != seg.getEndPointIndex()) {
//        addPointToArray(points, seg, ind, heightArray);
//        ind = plus ? ind + 1 : ind - 1;
//    }
//    if (includeEndPoint) {
//        addPointToArray(points, seg, ind, heightArray);
//    }
//}
//
//private void addPointToArray(List<WptPt> points, RouteSegmentResult seg, int index, float[] heightArray) {
//    LatLon l = seg.getPoint(index);
//    WptPt pt = new WptPt();
//    if (heightArray != null && heightArray.length > index * 2 + 1) {
//        pt.ele = heightArray[index * 2 + 1];
//    }
//    pt.lat = l.getLatitude();
//    pt.lon = l.getLongitude();
//    points.add(pt);
//}

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

- (BOOL) isTrackSnappedToRoad
{
    OAGpxData *gpxData = _gpxData;
    return gpxData != nil && gpxData.trkSegment != nil
    && gpxData.trkSegment.points.count > 0
    && gpxData.gpxFile.routes.count > 0;
}

//private void updateCacheForSnap(boolean both) {
//    recreateCacheForSnap(beforeCacheForSnap = new TrkSegment(), before, true);
//    if (both) {
//        recreateCacheForSnap(afterCacheForSnap = new TrkSegment(), after, true);
//    }
//}
//
//private void updateCacheForSnap(boolean both, boolean calculateIfNeeded) {
//    recreateCacheForSnap(beforeCacheForSnap = new TrkSegment(), before, calculateIfNeeded);
//    if (both) {
//        recreateCacheForSnap(afterCacheForSnap = new TrkSegment(), after, calculateIfNeeded);
//    }
//}


//void cancelSnapToRoad() {
//    progressListener.hideProgressBar();
//    if (calculationProgress != null) {
//        calculationProgress.isCancelled = true;
//    }
//}

//private RouteCalculationParams getParams(boolean resetCounter) {
//    List<Pair<WptPt, WptPt>> pointsToCalculate = getPointsToCalculate();
//    if (Algorithms.isEmpty(pointsToCalculate)) {
//        return null;
//    }
//    if (resetCounter) {
//        calculatedPairs = 0;
//        pointsToCalculateSize = pointsToCalculate.size();
//    }
//    final Pair<WptPt, WptPt> currentPair = pointsToCalculate.get(0);
//    Location start = new Location("");
//    start.setLatitude(currentPair.first.getLatitude());
//    start.setLongitude(currentPair.first.getLongitude());
//
//    LatLon end = new LatLon(currentPair.second.getLatitude(), currentPair.second.getLongitude());
//
//    RouteRegion reg = new RouteRegion();
//    reg.initRouteEncodingRule(0, "highway", RouteResultPreparation.UNMATCHED_HIGHWAY_TYPE);
//
//    final RouteCalculationParams params = new RouteCalculationParams();
//    params.inSnapToRoadMode = true;
//    params.start = start;
//
//    ApplicationMode appMode = ApplicationMode.valueOfStringKey(currentPair.first.getProfileType(), DEFAULT_APP_MODE);
//    params.end = end;
//    RoutingHelper.applyApplicationSettings(params, application.getSettings(), appMode);
//    params.mode = appMode;
//    params.ctx = application;
//    params.calculationProgress = calculationProgress = new RouteCalculationProgress();
//    params.calculationProgressCallback = new RouteCalculationProgressCallback() {
//
//        @Override
//        public void start() {
//        }
//
//        @Override
//        public void updateProgress(int progress) {
//            int pairs = pointsToCalculateSize;
//            if (pairs != 0) {
//                float pairProgress = 100f / pairs;
//                progress = (int)(calculatedPairs * pairProgress + (float) progress / pairs);
//            }
//            progressListener.updateProgress(progress);
//        }
//
//        @Override
//        public void requestPrivateAccessRouting() {
//        }
//
//        @Override
//        public void finish() {
//            calculatedPairs = 0;
//            pointsToCalculateSize = 0;
//        }
//    };
//    params.resultListener = new RouteCalculationResultListener() {
//        @Override
//        public void onRouteCalculated(RouteCalculationResult route) {
//            List<Location> locations = route.getRouteLocations();
//            ArrayList<WptPt> pts = new ArrayList<>(locations.size());
//            double prevAltitude = Double.NaN;
//            for (Location loc : locations) {
//                WptPt pt = new WptPt();
//                pt.lat = loc.getLatitude();
//                pt.lon = loc.getLongitude();
//                if (loc.hasAltitude()) {
//                    prevAltitude = loc.getAltitude();
//                    pt.ele = prevAltitude;
//                } else if (!Double.isNaN(prevAltitude)) {
//                    pt.ele = prevAltitude;
//                }
//                pts.add(pt);
//            }
//            calculatedPairs++;
//            params.calculationProgressCallback.updateProgress(0);
//            List<RouteSegmentResult> originalRoute = route.getOriginalRoute();
//            if (Algorithms.isEmpty(originalRoute)) {
//                originalRoute = Collections.singletonList(RoutePlannerFrontEnd.generateStraightLineSegment(
//                                                                                                           DEFAULT_APP_MODE.getDefaultSpeed(), new LocationsHolder(pts).getLatLonList()));
//            }
//            roadSegmentData.put(currentPair, new RoadSegmentData(route.getAppMode(), currentPair.first, currentPair.second, pts, originalRoute));
//            application.runInUIThread(new Runnable() {
//                @Override
//                public void run() {
//                    updateCacheForSnap(true, false);
//                    progressListener.refresh();
//                    RouteCalculationParams params = getParams(false);
//                    if (params != null) {
//                        application.getRoutingHelper().startRouteCalculationThread(params, true, true);
//                    } else {
//                        progressListener.hideProgressBar();
//                    }
//                }
//            });
//        }
//    };
//    return params;
//}

- (NSArray<OAGpxTrkPt *> *) getRoutePoints
{
    NSMutableArray<OAGpxTrkPt *> *res = [NSMutableArray new];
    NSMutableArray<OAGpxTrkPt *> *points = [NSMutableArray arrayWithArray:_before.points];
    [points addObjectsFromArray:_after.points];
    NSInteger size = points.count;
    for (NSInteger i = 0; i < size - 1; i++)
    {
//        Pair<WptPt, WptPt> pair = new Pair<>(points.get(i), points.get(i + 1));
//        RoadSegmentData data = this.roadSegmentData.get(pair);
//        if (data != null) {
//            res.addAll(data.points);
//        }
    }
    return res;
}

- (OAGPXDocument *) exportRouteAsGpx:(NSString *)gpxName
{
    if (_before.points.count == 0 /*|| ![self hasRoute]*/)
    {
        return nil;
    }
//    List<RouteSegmentResult> route = new ArrayList<>();
//    List<Location> locations = new ArrayList<>();
//    before.points.get(0).setTrkPtIndex(0);
//    int size = before.points.size();
//    for (int i = 0; i < size - 1; i++) {
//        Pair<WptPt, WptPt> pair = new Pair<>(before.points.get(i), before.points.get(i + 1));
//        RoadSegmentData data = this.roadSegmentData.get(pair);
//        if (data != null) {
//            for (WptPt pt : data.points) {
//                Location l = new Location("");
//                l.setLatitude(pt.getLatitude());
//                l.setLongitude(pt.getLongitude());
//                if (!Double.isNaN(pt.ele)) {
//                    l.setAltitude(pt.ele);
//                }
//                locations.add(l);
//            }
//            pair.second.setTrkPtIndex(i < size - 1 ? locations.size() : locations.size() - 1);
//            route.addAll(data.segments);
//        }
//    }
//    return new RouteExporter(gpxName, route, locations, null).exportRoute();
    return nil;
}

//interface SnapToRoadProgressListener {
//    
//    void showProgressBar();
//    
//    void updateProgress(int progress);
//    
//    void hideProgressBar();
//    
//    void refresh();
//}

@end
