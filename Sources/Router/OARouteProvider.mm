//
//  OARouteProvider.m
//  OsmAnd
//
//  Created by Alexey Kulish on 27/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARouteProvider.h"
#import "OAGPXDocumentPrimitives.h"
#import "OARouteDirectionInfo.h"
#import "OsmAndApp.h"
#import "OAApplicationMode.h"
#import "OARouteImporter.h"
#import "OARouteCalculationResult.h"
#import "OARouteCalculationParams.h"
#import "QuadRect.h"
#import "OALocationServices.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OAMapUtils.h"
#import "OALocationsHolder.h"
#import "OAResultMatcher.h"
#import "OAGpxRouteApproximation.h"
#import "OATargetPointsHelper.h"
#import "OAIndexConstants.h"
#import "MissingMapsCalculator.h"
#import "OAMissingMapsResult.h"
#import "OARTargetPoint.h"
#import "CLLocation+Extension.h"
#import "OsmAndSharedWrapper.h"
#import "OACppRouteConverter.h"
#import "OACppRouteCalculationProgress.h"
#import "OAGpxApproximationHelper.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAWorldRegion.h"
#import "OAAvoidSpecificRoads.h"
#import "OAAvoidRoadInfo.h"

#include <exception>
#include <new>

#include <precalculatedRouteDirection.h>
#include <routePlannerFrontEnd.h>
#include <routingConfiguration.h>
#include <routingContext.h>
#include <routeSegmentResult.h>
#include <routeResultPreparation.h>
#include <gpxRouteApproximation.h>

#define OSMAND_ROUTER @"OsmAndRouter"
#define OSMAND_ROUTER_V2 @"OsmAndRouterV2"
#define MIN_DISTANCE_FOR_INSERTING_ROUTE_SEGMENT 60
#define ADDITIONAL_DISTANCE_FOR_START_POINT 300
#define MIN_STRAIGHT_DIST 50000
#define MIN_INTERMEDIATE_DIST 10
#define NEAREST_POINT_EXTRA_SEARCH_DISTANCE 300

#define GPX_CALC_DIST_THRESHOLD 1000000

static NSString * const kRouteCalculationOutOfMemoryError = @"Not enough memory to calculate route.";
static NSString * const kRouteCalculationFailedError = @"Route calculation failed.";

static BOOL OAHasValidExternalTimestamps(OALocationsHolder *locationsHolder)
{
    if (locationsHolder.size == 0)
        return NO;

    int64_t lastTimestamp = 0;
    for (NSInteger index = 0; index < locationsHolder.size; index++)
    {
        int64_t timestamp = [locationsHolder timeAtIndex:index];
        if (timestamp == 0 || timestamp < lastTimestamp)
            return NO;
        lastTimestamp = timestamp;
    }
    return YES;
}

static float OACalculateExternalSpeed(const SHARED_PTR<GpxPoint> &gpxPoint,
                                      const SHARED_PTR<RouteSegmentResult> &segment,
                                      OALocationsHolder *locationsHolder)
{
    NSInteger startIndex = gpxPoint->ind;
    NSInteger endIndex = gpxPoint->targetInd;
    if (endIndex == -1 && startIndex >= 0 && startIndex + 1 < locationsHolder.size)
        endIndex = startIndex + 1;

    if (startIndex < 0 || endIndex <= 0 || startIndex >= endIndex || endIndex >= locationsHolder.size)
        return segment->segmentSpeed;

    int64_t duration = [locationsHolder timeAtIndex:endIndex] - [locationsHolder timeAtIndex:startIndex];
    if (duration <= 0)
        return segment->segmentSpeed;

    double distance = 0;
    for (NSInteger index = startIndex; index < endIndex; index++)
    {
        distance += getDistance([locationsHolder getLatitude:index],
                                [locationsHolder getLongitude:index],
                                [locationsHolder getLatitude:index + 1],
                                [locationsHolder getLongitude:index + 1]);
    }
    return distance > 0 ? (float)(distance / (duration / 1000.0)) : segment->segmentSpeed;
}

static void OARecalculateTimeAndDistance(const vector<SHARED_PTR<RouteSegmentResult>> &segments)
{
    for (const auto &segment : segments)
    {
        float speed = segment->segmentSpeed;
        if (speed == 0)
            continue;

        BOOL isForward = segment->getStartPointIndex() < segment->getEndPointIndex();
        double distance = 0;
        for (NSInteger index = segment->getStartPointIndex(); index != segment->getEndPointIndex();)
        {
            NSInteger nextIndex = isForward ? index + 1 : index - 1;
            distance += measuredDist31(segment->object->getPoint31XTile((int)index),
                                       segment->object->getPoint31YTile((int)index),
                                       segment->object->getPoint31XTile((int)nextIndex),
                                       segment->object->getPoint31YTile((int)nextIndex));
            index = nextIndex;
        }
        segment->segmentTime = (float)(distance / speed);
        segment->segmentSpeed = speed;
        segment->distance = (float)distance;
    }
}

static void OAApplyExternalTimestamps(const SHARED_PTR<GpxRouteApproximation> &approximation,
                                      OALocationsHolder *locationsHolder)
{
    if (approximation == nullptr || !OAHasValidExternalTimestamps(locationsHolder))
        return;

    for (const auto &gpxPoint : approximation->finalPoints)
    {
        for (const auto &segment : gpxPoint->routeToTarget)
            segment->segmentSpeed = OACalculateExternalSpeed(gpxPoint, segment, locationsHolder);
        OARecalculateTimeAndDistance(gpxPoint->routeToTarget);
    }
}

static NSString *RouteCalculationErrorMessage(const std::exception &exception)
{
    const char *what = exception.what();
    if (what && what[0] != '\0')
    {
        NSString *message = [NSString stringWithUTF8String:what];
        if (message.length > 0)
            return message;
    }
    return kRouteCalculationFailedError;
}

@interface OARouteProvider()

+ (NSArray<OARouteDirectionInfo *> *) parseOsmAndGPXRoute:(NSMutableArray<CLLocation *> *)res
                                                  gpxFile:(OASGpxFile *)gpxFile
                                         segmentEndPoints:(NSMutableArray<CLLocation *> *)segmentEndPoints
                                             osmandRouter:(BOOL)osmandRouter
                                                 leftSide:(BOOL)leftSide
                                                 defSpeed:(float)defSpeed
                                          selectedSegment:(NSInteger)selectedSegment;

+ (NSArray<OASRouteSegmentResult *> *) parseOsmAndGPXRoute:(NSMutableArray<CLLocation *> *)points
                                                   gpxFile:(OASGpxFile *)gpxFile
                                          segmentEndpoints:(NSMutableArray<CLLocation *> *)segmentEndpoints
                                           selectedSegment:(NSInteger)selectedSegment;

+ (NSArray<OASRouteSegmentResult *> *) parseOsmAndGPXRoute:(NSMutableArray<CLLocation *> *)points
                                                   gpxFile:(OASGpxFile *)gpxFile
                                          segmentEndpoints:(NSMutableArray<CLLocation *> *)segmentEndpoints
                                           selectedSegment:(NSInteger)selectedSegment
                                                  leftSide:(BOOL)leftSide;

+ (void) collectSegmentPointsFromGpx:(OASGpxFile *)gpxFile points:(NSMutableArray<CLLocation *> *)points
                    segmentEndPoints:(NSMutableArray<CLLocation *> *)segmentEndPoints
                     selectedSegment:(NSInteger)selectedSegment;

@end

@interface OARouteService()

@property (nonatomic) EOARouteService service;

@end

@implementation OARouteService

+ (instancetype)withService:(EOARouteService)service
{
    OARouteService *obj = [[OARouteService alloc] init];
    if (obj)
    {
        obj.service = service;
    }
    return obj;
}

+ (NSString *)getName:(EOARouteService)service
{
    switch (service)
    {
        case OSMAND:
            return @"OsmAnd (offline)";
//        case YOURS:
//            return @"YOURS";
//        case OSRM:
//            return @"OSRM (only car)";
//        case BROUTER:
//            return @"BRouter (offline)";
        case STRAIGHT:
            return @"Straight line";
        case DIRECT_TO:
            return @"Direct to point";
        default:
            return @"";
    }
}

+ (BOOL) isOnline:(EOARouteService)service
{
    return NO;/*service != OSMAND && service != BROUTER*/;
}

+ (BOOL) isAvailable:(EOARouteService)service
{
//    if (service == BROUTER) {
//        return NO; //ctx.getBRouterService() != null;
//    }
    return YES;
}

+ (NSArray<OARouteService *> *) getAvailableRouters
{
    NSMutableArray<OARouteService *> *res = [NSMutableArray array];
    if ([OARouteService isAvailable:OSMAND])
        [res addObject:[OARouteService withService:OSMAND]];
//    if ([OARouteService isAvailable:YOURS])
//        [res addObject:[OARouteService withService:YOURS]];
//    if ([OARouteService isAvailable:OSRM])
//        [res addObject:[OARouteService withService:OSRM]];
//    if ([OARouteService isAvailable:BROUTER])
//        [res addObject:[OARouteService withService:BROUTER]];
    if ([OARouteService isAvailable:STRAIGHT])
        [res addObject:[OARouteService withService:STRAIGHT]];
    if ([OARouteService isAvailable:DIRECT_TO])
    [res addObject:[OARouteService withService:DIRECT_TO]];
    return [NSArray arrayWithArray:res];
}

@end

@interface OAGPXRouteParams()

@end

@implementation OAGPXRouteParams

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _addMissingTurns = YES;
        _segmentEndPoints = @[];
        _points = @[];
        _routePoints = [NSMutableArray new];
    }
    return self;
}

- (OAGPXRouteParams *) prepareGPXFile:(OAGPXRouteParamsBuilder *)builder
{
    _gpxFile = builder.file;
    _reverse = builder.reverse;
    _approximationParams = builder.approximationParams;
    self.passWholeRoute = builder.passWholeRoute;
    self.useIntermediatePointsRTE = builder.useIntermediatePointsRTE;
    self.connectPointsStraightly = builder.connectPointsStraightly;
    builder.calculateOsmAndRoute = NO; // Disabled temporary builder.calculateOsmAndRoute;
    if (_gpxFile.getPointsList.count > 0)
    {
        self.wpt = [NSArray arrayWithArray:_gpxFile.getPointsList];
    }
    NSInteger selectedSegment = builder.selectedSegment;
    if ([OSMAND_ROUTER_V2 isEqualToString:_gpxFile.author])
    {
        NSMutableArray<CLLocation *> *points = [NSMutableArray arrayWithArray:_points];
        NSMutableArray<CLLocation *> *endPoints = [NSMutableArray arrayWithArray:_segmentEndPoints];
        _route = [OARouteProvider parseOsmAndGPXRoute:points gpxFile:_gpxFile segmentEndpoints:endPoints selectedSegment:selectedSegment leftSide:builder.leftSide];
        _points = points;
        _segmentEndPoints = endPoints;
        
        if (selectedSegment == -1)
            _routePoints = [_gpxFile getRoutePoints];
        else
            _routePoints = [_gpxFile getRoutePointsRouteIndex:(int)selectedSegment];
        
        if (_reverse)
        {
            _points = [[points reverseObjectEnumerator] allObjects];
            _routePoints = [[_routePoints reverseObjectEnumerator] allObjects];
            _segmentEndPoints = [[_segmentEndPoints reverseObjectEnumerator] allObjects];
        }
        _addMissingTurns = _route.count == 0;
    }
    else if ([_gpxFile isCloudmadeRouteFile] || [OSMAND_ROUTER isEqualToString:_gpxFile.author])
    {
        NSMutableArray<CLLocation *> *points = [NSMutableArray arrayWithArray:self.points];
        NSMutableArray<CLLocation *> *endPoints = [NSMutableArray arrayWithArray:self.segmentEndPoints];
        self.directions = [OARouteProvider parseOsmAndGPXRoute:points gpxFile:_gpxFile segmentEndPoints:endPoints osmandRouter:[OSMAND_ROUTER isEqualToString:_gpxFile.author] leftSide:builder.leftSide defSpeed:10 selectedSegment:selectedSegment];
        self.points = [NSArray arrayWithArray:points];
        _segmentEndPoints = endPoints;
        if ([OSMAND_ROUTER isEqualToString:_gpxFile.author])
        {
            // For files generated by OSMAND_ROUTER use directions contained unaltered
            self.addMissingTurns = NO;
        }
        if (_reverse)
        {
            // clear directions all turns should be recalculated
            self.directions = nil;
            self.points = [[self.points reverseObjectEnumerator] allObjects];
            _segmentEndPoints = [[_segmentEndPoints reverseObjectEnumerator] allObjects];
            self.addMissingTurns = YES;
        }
    }
    else
    {
        NSMutableArray<CLLocation *> *points = [NSMutableArray arrayWithArray:self.points];
        NSMutableArray<CLLocation *> *endPoints = [NSMutableArray arrayWithArray:self.segmentEndPoints];
        // first of all check tracks
        if (!self.useIntermediatePointsRTE)
        {
            [OARouteProvider collectSegmentPointsFromGpx:_gpxFile points:points segmentEndPoints:endPoints selectedSegment:selectedSegment];
            self.points = points;
            _segmentEndPoints = endPoints;
        }
        if (points.count == 0)
        {
            for (OASRoute *rte in _gpxFile.routes)
            {
                for (OASWptPt *pt in rte.points)
                {
                    CLLocation *loc = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(pt.position.latitude, pt.position.longitude) altitude:pt.ele horizontalAccuracy:pt.hdop verticalAccuracy:0 course:0 speed:pt.speed timestamp:[NSDate dateWithTimeIntervalSince1970:pt.time / 1000.0]];

                    [points addObject:loc];
                }
            }
        }
        if (_reverse)
        {
            self.points = [[points reverseObjectEnumerator] allObjects];
            _segmentEndPoints = [[_segmentEndPoints reverseObjectEnumerator] allObjects];
        }
        else
        {
            self.points = points;
            _segmentEndPoints = endPoints;
        }
    }
    self.calculateOsmAndRouteParts = builder.calculateOsmAndRouteParts && [self isStartPointClose];
    return self;
}

- (BOOL) isStartPointClose
{
    if (self.points.count > 0)
    {
        OARTargetPoint *start = OATargetPointsHelper.sharedInstance.getPointToStart;
        CLLocation *startLocation;
        if (start)
            startLocation = start.point;
        else
            startLocation = OsmAndApp.instance.locationServices.lastKnownLocation;
        
        if (startLocation)
            return [_points.firstObject distanceFromLocation:startLocation] < GPX_CALC_DIST_THRESHOLD;
    }
    return YES;
}

@end

@interface OAGPXRouteParamsBuilder()

@end

@implementation OAGPXRouteParamsBuilder

- (instancetype)initWithDoc:(OASGpxFile *)document
{
    self = [super init];
    if (self) {
        _file = document;
        _leftSide = [OADrivingRegion isLeftHandDriving:[[OAAppSettings sharedManager].drivingRegion get]];
    }
    return self;
}

- (instancetype)initWithFile:(OASGpxFile *)gpxFile params:(OAGPXRouteParams *)params
{
    self = [super init];
    if (self) {
        _file = gpxFile;
        _calculateOsmAndRoute = params.calculateOsmAndRoute;
        _leftSide =  [OADrivingRegion isLeftHandDriving:[[OAAppSettings sharedManager].drivingRegion get]];
        _reverse = params.reverse;
        _passWholeRoute = params.passWholeRoute;
        _calculateOsmAndRouteParts = params.calculateOsmAndRouteParts;
        _connectPointsStraightly = params.connectPointsStraightly;
        _useIntermediatePointsRTE = params.useIntermediatePointsRTE;
        _selectedSegment = OAAppSettings.sharedManager.gpxRouteSegment.get;
        _approximationParams = params.approximationParams;
    }
    return self;
}

- (OAGPXRouteParams *) build:(CLLocation *)start
{
    OAGPXRouteParams *res = [[OAGPXRouteParams alloc] init];
    [res prepareGPXFile:self];
    //			if (passWholeRoute && start != null) {
    //				res.points.add(0, start);
    //			}
    return res;
}

- (NSArray<CLLocation *> *) getPoints
{
    OAGPXRouteParams *copy = [[OAGPXRouteParams alloc] init];
    [copy prepareGPXFile:self];
    return copy.points;
}

- (NSArray<OASimulatedLocation *> *)getSimulatedLocations
{
    NSMutableArray<OASimulatedLocation *> *locationList = [NSMutableArray array];
    for (CLLocation *l in [self getPoints])
    {
        [locationList addObject:[[OASimulatedLocation alloc] initWithLocation:l]];
    }
    
    return [NSArray arrayWithArray:locationList];
}

- (void)setApproximationParams:(OAGpxApproximationParams *)approximationParams
{
    _approximationParams = approximationParams;
}

@end

@implementation OARoutingEnvironment

- (instancetype)initWithRouter:(std::shared_ptr<RoutePlannerFrontEnd>)router context:(std::shared_ptr<RoutingContext>)ctx complextCtx:(std::shared_ptr<RoutingContext>)complexCtx precalculated:(std::shared_ptr<PrecalculatedRouteDirection>)precalculated
{
    self = [super init];
    if (self) {
        _router = router;
        _ctx = ctx;
        _complexCtx = complexCtx;
        _precalculated = precalculated;
    }
    return self;
}

- (instancetype)initWithSharedRouter:(OASRoutePlannerFrontEnd *)router context:(OASRoutingContext *)ctx
{
    self = [super init];
    if (self) {
        _sharedRouter = router;
        _sharedCtx = ctx;
    }
    return self;
}

@end


@implementation OARouteProvider
{
    NSMutableSet<NSString *> *_nativeFiles;
    MissingMapsCalculator *_missingMapsCalculator;
    NSObject *_nativeRoutingLock;
    OAWorldRegion *_or;

    // The last route the C++ router produced, and the result built from it. The router takes its own
    // segments back when only the start point moved, and the result no longer carries them; both go
    // when the C++ router does.
    OARouteCalculationResult *_previousCppResult;
    std::vector<std::shared_ptr<RouteSegmentResult>> _previousCppRoute;

    // The OsmAndShared readers of the files in _nativeFiles, and the ones a running search may still
    // be holding when the installed maps change.
    NSMutableDictionary<NSString *, OASBinaryMapIndexReader *> *_sharedReaders;
    NSMutableArray<OASBinaryMapIndexReader *> *_staleSharedReaders;

    // The OsmAndShared routing environments still in use: a track approximation keeps one for as
    // long as its screen is open, and its readers have to outlive a change of the installed maps.
    NSHashTable<OARoutingEnvironment *> *_liveSharedEnvironments;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _nativeFiles = [NSMutableSet set];
        _nativeRoutingLock = [[NSObject alloc] init];
        _sharedReaders = [NSMutableDictionary dictionary];
        _staleSharedReaders = [NSMutableArray array];
        _liveSharedEnvironments = [NSHashTable weakObjectsHashTable];
        
        [OsmAndApp instance].resourcesManager->localResourcesChangeObservable.attach(
                                                                                     reinterpret_cast<OsmAnd::IObservable::Tag>((__bridge const void*)self),
                                                                                     [self](const OsmAnd::ResourcesManager* const resourcesManager,
                                                                                            const QList<QString>& added,
                                                                                            const QList<QString>& removed,
                                                                                            const QList<QString>& updated) {
                                                                                                [self onLocalResourcesChanged];
                                                                                            });
        _or = OsmAndApp.instance.worldRegion;
    }
    return self;
}

- (void) onLocalResourcesChanged
{
    @synchronized(self)
    {
        _nativeFiles = [NSMutableSet set];
        [_staleSharedReaders addObjectsFromArray:_sharedReaders.allValues];
        [_sharedReaders removeAllObjects];
    }
}

+ (NSString *)getExtensionValue:(NSDictionary<NSString *, NSString *> *)dic key:(NSString *)key
{
    return [dic objectForKey:key];

}

+ (NSArray<OASRouteSegmentResult *> *) parseOsmAndGPXRoute:(NSMutableArray<CLLocation *> *)points
                                                   gpxFile:(OASGpxFile *)gpxFile
                                          segmentEndpoints:(NSMutableArray<CLLocation *> *)segmentEndpoints
                                           selectedSegment:(NSInteger)selectedSegment
                                                  leftSide:(BOOL)leftSide
{
    NSArray<OASTrkSegment *> *segments = [gpxFile getNonEmptyTrkSegmentsRoutesOnly:NO];
    if (selectedSegment != -1 && segments.count > selectedSegment)
    {
        OASTrkSegment *segment = segments[selectedSegment];
        for (OASWptPt *p in segment.points)
        {
            [points addObject:[self createLocation:p]];
        }
        OARouteImporter *routeImporter = [[OARouteImporter alloc] initWithTrkSeg:segment segmentRoutePoints:[gpxFile getRoutePointsRouteIndex:(int)selectedSegment]];
        return [routeImporter importRoute];
    }
    else
    {
        [self collectPointsFromSegments:segments points:points segmentEndpoints:segmentEndpoints];
        OARouteImporter *routeImporter = [[OARouteImporter alloc] initWithGpxFile:gpxFile leftSide:leftSide];
        return [routeImporter importRoute];
    }
}

+ (NSArray<OASRouteSegmentResult *> *) parseOsmAndGPXRoute:(NSMutableArray<CLLocation *> *)points
                                                   gpxFile:(OASGpxFile *)gpxFile
                                          segmentEndpoints:(NSMutableArray<CLLocation *> *)segmentEndpoints
                                           selectedSegment:(NSInteger)selectedSegment
{
    return [self parseOsmAndGPXRoute:points gpxFile:gpxFile segmentEndpoints:segmentEndpoints selectedSegment:selectedSegment leftSide:false];
}

+ (void) collectSegmentPointsFromGpx:(OASGpxFile *)gpxFile points:(NSMutableArray<CLLocation *> *)points
                    segmentEndPoints:(NSMutableArray<CLLocation *> *)segmentEndPoints
                     selectedSegment:(NSInteger)selectedSegment
{
    NSArray<OASTrkSegment *> *segments = [gpxFile getNonEmptyTrkSegmentsRoutesOnly:NO];
    if (selectedSegment != -1 && segments.count > selectedSegment)
    {
        OASTrkSegment *segment = segments[selectedSegment];
        for (OASWptPt *wptPt in segment.points)
        {
            [points addObject:[self createLocation:wptPt]];
        }
    }
    else
    {
        [self collectPointsFromSegments:segments points:points segmentEndpoints:segmentEndPoints];
    }
}

+ (void)collectPointsFromSegments:(NSArray<OASTrkSegment *> *)segments points:(NSMutableArray<CLLocation *> *)points segmentEndpoints:(NSMutableArray<CLLocation *> *)segmentEndpoints
{
    CLLocation *lastPoint = nil;
    for (NSInteger i = 0; i < segments.count; i++)
    {
        OASTrkSegment *segment = segments[i];
        for (OASWptPt *wptPt in segment.points)
        {
            [points addObject:[self createLocation:wptPt]];
        }
        if (i <= (NSInteger) segments.count - 1 && lastPoint != nil) {
            [segmentEndpoints addObject:lastPoint];
            [segmentEndpoints addObject:points[points.count - segment.points.count]];
        }
        lastPoint = points.lastObject;
    }
}

+ (CLLocation *) createLocation:(OASWptPt *)pt
{
    CLLocation *loc = [[CLLocation alloc] initWithCoordinate:pt.position altitude:isnan(pt.ele) ? 0. : pt.ele horizontalAccuracy:isnan(pt.hdop) ? 0. : pt.hdop verticalAccuracy:0. course:0. speed:pt.speed timestamp:[NSDate dateWithTimeIntervalSince1970:pt.time / 1000.0]];
    return loc;
}

+ (NSArray<CLLocation *> *) locationsFromWpts:(NSArray<OASWptPt *> *)wpts
{
    NSMutableArray<CLLocation *> *locations = [NSMutableArray array];
    for (OASWptPt *pt in wpts)
        [locations addObject:[self createLocation:pt]];
    return [NSArray arrayWithArray:locations];
}

+ (NSArray<OARouteDirectionInfo *> *) parseOsmAndGPXRoute:(NSMutableArray<CLLocation *> *)res gpxFile:(OASGpxFile *)gpxFile segmentEndPoints:(NSMutableArray<CLLocation *> *)segmentEndPoints osmandRouter:(BOOL)osmandRouter leftSide:(BOOL)leftSide defSpeed:(float)defSpeed selectedSegment:(NSInteger)selectedSegment
{
    NSMutableArray<OARouteDirectionInfo *> *directions = nil;
    if (!osmandRouter)
    {
        for (OASWptPt *pt in gpxFile.getPointsList)
        {
            CLLocation *loc = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(pt.position.latitude, pt.position.longitude) altitude:pt.ele horizontalAccuracy:pt.hdop verticalAccuracy:0 course:0 speed:pt.speed timestamp:[NSDate dateWithTimeIntervalSince1970:pt.time / 1000.0]];
            
            [res addObject:loc];
        }
    }
    else
    {
        [self collectSegmentPointsFromGpx:gpxFile points:res segmentEndPoints:segmentEndPoints selectedSegment:selectedSegment];
    }
    NSMutableArray<NSNumber *> *distanceToEnd  = [NSMutableArray arrayWithObject:@(0) count:res.count];
    for (int i = (int)res.count - 2; i >= 0; i--)
    {
        distanceToEnd[i] = @(distanceToEnd[i + 1].floatValue + [res[i] distanceFromLocation:res[i + 1]]);
    }
    
    OASRoute *route = nil;
    if (gpxFile.routes.count > 0)
    {
        route = gpxFile.routes[0];
    }
    //OALocationServices *locationServices = [OsmAndApp instance].locationServices;
    OARouteDirectionInfo *previous = nil;
    if (route && route.points.count > 0)
    {
        directions = [NSMutableArray array];
        for (int i = 0; i < route.points.count; i++)
        {
            OASWptPt *item = route.points[i];
            try
            {
                NSString *stime = [OARouteProvider getExtensionValue:item.extensions key:@"time"];
                int time  = 0;
                if (stime)
                    time = [stime intValue];
                
                int offset = [[OARouteProvider getExtensionValue:item.extensions key:@"offset"] intValue];
                
                if (directions.count > 0)
                {
                    OARouteDirectionInfo *last = directions[directions.count - 1];
                    // update speed using time and idstance
                    if (distanceToEnd.count > last.routePointOffset && distanceToEnd.count > offset)
                    {
                        float lastDistanceToEnd = distanceToEnd[last.routePointOffset].floatValue;
                        float currentDistanceToEnd = distanceToEnd[offset].floatValue;
                        last.averageSpeed = ((lastDistanceToEnd - currentDistanceToEnd) / last.averageSpeed);
                        last.distance = (int) round(lastDistanceToEnd - currentDistanceToEnd);
                    }
                }
                // save time as a speed because we don't know distance of the route segment
                float avgSpeed = time;
                if (i == (int) route.points.count - 1 && time > 0)
                {
                    if (distanceToEnd.count > offset)
                        avgSpeed = distanceToEnd[offset].floatValue / time;
                    else
                        avgSpeed = defSpeed;
                }
                NSString *stype = [OARouteProvider getExtensionValue:item.extensions key:@"turn"];
                OASTurnType *turnType;
                if (stype)
                    turnType = [OASTurnType.companion fromStringS:[stype uppercaseString] leftSide:leftSide];
                else
                    turnType = [OASTurnType.companion straight];
                
                NSString *sturn = [OARouteProvider getExtensionValue:item.extensions key:@"turn-angle"];
                if (sturn)
                    turnType.turnAngle = [sturn floatValue];
                
                NSString *slanes = [OARouteProvider getExtensionValue:item.extensions key:@"lanes"];
                if (slanes)
                {
                    turnType.lanes = [self stringToIntArray:slanes];
                }
                
                OARouteDirectionInfo *dirInfo = [[OARouteDirectionInfo alloc] initWithAverageSpeed:avgSpeed turnType:turnType];
                [dirInfo setDescriptionRoute:item.desc];
                dirInfo.routePointOffset = offset;
                
                // Issue #2894
                NSString *sref = [OARouteProvider getExtensionValue:item.extensions key:@"ref"];
                if (sref && ![@"null" isEqualToString:sref])
                    dirInfo.ref = sref;

                NSString *sstreetname = [OARouteProvider getExtensionValue:item.extensions key:@"street-name"];
                if (sstreetname && ![@"null" isEqualToString:sstreetname])
                    dirInfo.streetName = sstreetname;
                
                NSString *sdest = [OARouteProvider getExtensionValue:item.extensions key:@"dest"];
                if (sdest && ![@"null" isEqualToString:sdest])
                    dirInfo.destinationName = sdest;
                
                if (previous && OASTurnType.companion.C != previous.turnType.value && !osmandRouter)
                {
                    // calculate angle
                    if (previous.routePointOffset > 0)
                    {
                        double bearing = [res[previous.routePointOffset - 1] bearingTo:res[previous.routePointOffset]];
                        float paz = bearing;
                        float caz;
                        if ([previous.turnType isRoundAbout] && dirInfo.routePointOffset < (int) res.count - 1)
                        {
                            bearing = [res[previous.routePointOffset] bearingTo:res[previous.routePointOffset + 1]];
                            caz = bearing;
                        }
                        else
                        {
                            bearing = [res[previous.routePointOffset - 1] bearingTo:res[previous.routePointOffset]];
                            caz = bearing;
                        }
                        float angle = caz - paz;
                        if (angle < 0)
                            angle += 360;
                        else if (angle > 360)
                            angle -= 360;
                        
                        // that magic number helps to fix some errors for turn
                        angle += 75;
                        
                        if (previous.turnType.turnAngle < 0.5f) {
                            previous.turnType.turnAngle = angle;
                        }
                    }
                }
                
                [directions addObject:dirInfo];
                
                previous = dirInfo;
            } catch (NSException *e) {
            }
        }
    }
    
    if (previous && OASTurnType.companion.C != previous.turnType.value)
    {
        // calculate angle
        if (previous.routePointOffset > 0 && previous.routePointOffset < (int) res.count - 1)
        {
            double bearing = [res[previous.routePointOffset - 1] bearingTo:res[previous.routePointOffset]];
            float paz = bearing;

            bearing = [res[previous.routePointOffset] bearingTo:res[res.count - 1]];
            float caz = bearing;
            
            float angle = caz - paz;
            if (angle < 0)
                angle += 360;
            
            if (previous.turnType.turnAngle < 0.5f)
                previous.turnType.turnAngle = angle;
        }
    }
    return directions;
}

+ (OASKotlinIntArray *) stringToIntArray:(NSString *)str
{
    NSArray<NSString *> *components = [str componentsSeparatedByString:@","];
    OASKotlinIntArray *res = [OASKotlinIntArray arrayWithSize:(int) components.count];
    for (int i = 0; i < (int) components.count; i++)
        [res setIndex:i value:components[i].intValue];

    return res;
}

- (MissingMapsCalculator *)missingMapsCalculator
{
    return _missingMapsCalculator;
}

- (OARouteCalculationResult *) applicationModeNotSupported:(OARouteCalculationParams *)params
{
    return [[OARouteCalculationResult alloc] initWithErrorMessage:[NSString stringWithFormat:@"Application mode '%@' is not supported.", params.mode.variantKey]];
}

- (OARouteCalculationResult *) interrupted
{
    return [[OARouteCalculationResult alloc] initWithErrorMessage:@"Route calculation was interrupted"];
}

- (OARouteCalculationResult *) emptyResult
{
    return [[OARouteCalculationResult alloc] initWithErrorMessage:@"Empty result"];
}

- (std::shared_ptr<RoutingConfiguration>) initOsmAndRoutingConfig:(std::shared_ptr<RoutingConfigurationBuilder>)config params:(OARouteCalculationParams *)params generalRouter:(std::shared_ptr<GeneralRouter>)generalRouter
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    string derivedProfile(params.mode.getDerivedProfile.UTF8String);
    MAP_STR_STR paramsR;
    auto routerParams = generalRouter->getParameters(derivedProfile);
    auto it = routerParams.begin();
    for(;it != routerParams.end(); it++)
    {
        const auto& key = it->first;
        const auto& pr = it->second;

        string vl;
        NSString *attrName = @(key.c_str());
        if (key == GeneralRouterConstants::USE_SHORTEST_WAY)
        {
            BOOL b = ![settings.fastRouteMode get:params.mode];
            vl = b ? "true" : "";
        }
        else if (pr.type == RoutingParameterType::BOOLEAN)
        {
            OACommonBoolean *pref = [settings getCustomRoutingBooleanProperty:attrName defaultValue:pr.defaultBoolean];
            BOOL b = [pref get:params.mode];
            vl = b ? "true" : "";
        }
        else // NUMERIC
        {
            NSString *defaultNumericAsString = @(pr.getDefaultString().c_str());
            OACommonString *pref = [settings getCustomRoutingProperty:attrName defaultValue:defaultNumericAsString];
            NSString *s = [pref get:params.mode];
            if ([s doubleValue] != 0 || pr.defaultNumeric != 0)
            {
                vl = [s UTF8String];
            }
        }
        
        if (vl.length() > 0)
            paramsR[key] = vl;
    }
    double defaultSpeed = params.mode.getDefaultSpeed;
    if (defaultSpeed > 0)
        paramsR[GeneralRouterConstants::DEFAULT_SPEED] = [NSString stringWithFormat:@"%f", defaultSpeed].UTF8String;
    double minSpeed = params.mode.getMinSpeed;
    if (minSpeed > 0)
        paramsR[GeneralRouterConstants::MIN_SPEED] = [NSString stringWithFormat:@"%f", minSpeed].UTF8String;
    double maxSpeed = params.mode.getMaxSpeed;
    if (maxSpeed > 0)
        paramsR[GeneralRouterConstants::MAX_SPEED] = [NSString stringWithFormat:@"%f", maxSpeed].UTF8String;
    
    float mb = (1 << 20);
    natural_t freeMemory = [OAUtilities get_free_memory];
    long memoryLimit = (0.1 * ([NSProcessInfo processInfo].physicalMemory / mb));
    // make visible
    long memoryTotal = (long) ([NSProcessInfo processInfo].physicalMemory / mb);
    NSLog(@"Use %ld MB of %ld MB, free memory: %ld MB", memoryLimit, memoryTotal, (long)(freeMemory / mb));
    
    string routingProfile = derivedProfile == "default" ? params.mode.getRoutingProfile.UTF8String : derivedProfile;
    auto cf = config->build(routingProfile, params.start.course >= 0.0 ? params.start.course / 180.0 * M_PI : NO_DIRECTION, memoryLimit, paramsR);
    if ([OAAppSettings.sharedManager.enableTimeConditionalRouting get:params.mode])
    {
        cf->routeCalculationTime = [[NSDate date] timeIntervalSince1970];
    }
    return cf;
}

- (NSArray<CLLocation *> *) findStartAndEndLocationsFromRoute:(NSArray<CLLocation *> *)route startLoc:(CLLocation *)startLoc endLoc:(CLLocation *)endLoc startI:(NSMutableArray<NSNumber *> *)startI endI:(NSMutableArray<NSNumber *> *)endI
{
    float minDist = FLT_MAX;
    int start = 0;
    int end = (int)route.count;
    if (startLoc)
    {
        for (int i = 0; i < route.count; i++)
        {
            float d = [route[i] distanceFromLocation:startLoc];
            if (d < minDist)
            {
                start = i;
                minDist = d;
            }
        }
    }
    else
    {
        startLoc = route[0];
    }
    CLLocation *l = [[CLLocation alloc] initWithLatitude:endLoc.coordinate.latitude longitude:endLoc.coordinate.longitude];
    minDist = FLT_MAX;
    // get in reverse order taking into account ways with cycle
    for (int i = (int)route.count - 1; i >= start; i--)
    {
        float d = [route[i] distanceFromLocation:l];
        if (d < minDist)
        {
            end = i + 1;
            // slightly modify to allow last point to be added
            minDist = d - 40;
        }
    }
    NSArray<CLLocation *> *sublist = [route subarrayWithRange:NSMakeRange(start, end - start)];
    if (startI)
        startI[0] = @(start);
    
    if (endI)
        endI[0] = @(end);
    
    return sublist;
}

- (BOOL) containsData:(const QString &)localResourceId rect:(QuadRect *)rect desiredDataTypes:(OsmAnd::ObfDataTypesMask)desiredDataTypes zoomLevel:(OsmAnd::ZoomLevel)zoomLevel
{
    OsmAndAppInstance app = [OsmAndApp instance];
    const auto& localResource = app.resourcesManager->getLocalResource(localResourceId);
    if (localResource)
    {
        const auto& obfMetadata = std::static_pointer_cast<const OsmAnd::ResourcesManager::ObfMetadata>(localResource->metadata);
        if (obfMetadata)
        {
            OsmAnd::AreaI pBbox31;
            if (rect)
                pBbox31 = OsmAnd::AreaI((int)rect.top, (int)rect.left, (int)rect.bottom, (int)rect.right);
            
            if (zoomLevel == OsmAnd::InvalidZoomLevel)
                return obfMetadata->obfFile->obfInfo->containsDataFor(rect ? &pBbox31 : NULL, OsmAnd::MinZoomLevel, OsmAnd::MaxZoomLevel, desiredDataTypes);
            else
                return obfMetadata->obfFile->obfInfo->containsDataFor(rect ? &pBbox31 : NULL, zoomLevel, zoomLevel, desiredDataTypes);
        }
    }
    return NO;
}

- (void)checkInitialized:(int)zoom leftX:(int)leftX rightX:(int)rightX bottomY:(int)bottomY topY:(int)topY
{
    @synchronized (self)
    {
        OsmAndAppInstance app = [OsmAndApp instance];
        BOOL useOsmLiveForRouting = [OAAppSettings sharedManager].useOsmLiveForRouting;
        const auto& localResources = app.resourcesManager->getSortedLocalResources();
        QuadRect *rect;
        BOOL isEmptyRect = leftX == 0 && rightX == 0 && bottomY == 0 && topY == 0;
        if (!isEmptyRect)
        {
            rect = [[QuadRect alloc] initWithLeft:leftX top:topY right:rightX bottom:bottomY];
        }
       
        auto dataTypes = OsmAnd::ObfDataTypesMask();
        dataTypes.set(OsmAnd::ObfDataType::Map);
        dataTypes.set(OsmAnd::ObfDataType::Routing);
        for (const auto& resource : localResources)
        {
            if (resource->origin == OsmAnd::ResourcesManager::ResourceOrigin::Installed)
            {
                NSString *localPath = resource->localPath.toNSString();
                if (![localPath.lowerCase hasSuffix:BINARY_MAP_INDEX_EXT])
                    continue;
                if (![_nativeFiles containsObject:localPath] && [self containsData:resource->id rect:rect desiredDataTypes:dataTypes zoomLevel:(OsmAnd::ZoomLevel)zoom])
                {
                    [_nativeFiles addObject:localPath];
                    cacheBinaryMapFileIfNeeded(resource->localPath.toStdString(), true);
                    initBinaryMapFile(resource->localPath.toStdString(), useOsmLiveForRouting, true);
                }
            }
        }
        writeMapFilesCache(app.routingMapsCachePath.UTF8String);

        const auto openFilesSnapshot = getOpenFilesSnapshot();
        for (const auto& fileRef : openFilesSnapshot)
        {
            const auto* file = fileRef.get();
            BOOL hasLocal = NO;
            for (const auto& resource : localResources)
            {
                if (file->inputName == resource->localPath.toStdString())
                {
                    hasLocal = YES;
                    break;
                }
            }
            if (!hasLocal)
                closeBinaryMapFile(file->inputName);
        }
    }
}

- (OARouteCalculationResult *) calcOfflineRouteImpl:(OARouteCalculationParams *)params router:(std::shared_ptr<RoutePlannerFrontEnd>)router ctx:(std::shared_ptr<RoutingContext>)ctx complexCtx:(std::shared_ptr<RoutingContext>)complexCtx st:(CLLocation *)st en:(CLLocation *)en inters:(NSArray<CLLocation *> *)inters precalculated:(std::shared_ptr<PrecalculatedRouteDirection>)precalculated
{
    try
    {
        std::vector<std::shared_ptr<RouteSegmentResult> > result;
        
        int startX = get31TileNumberX(st.coordinate.longitude);
        int startY = get31TileNumberY(st.coordinate.latitude);
        int endX = get31TileNumberX(en.coordinate.longitude);
        int endY = get31TileNumberY(en.coordinate.latitude);
        vector<int> intX;
        vector<int> intY;
        for (CLLocation *l in inters)
        {
            intX.push_back(get31TileNumberX(l.coordinate.longitude));
            intY.push_back(get31TileNumberY(l.coordinate.latitude));
        }
        
        bool oldRouting = [[OAAppSettings sharedManager].useOldRouting get];
        if (!oldRouting)
        {
            router->setDefaultRoutingConfig();
            // router->USE_ONLY_HH_ROUTING = hhRoutingOnly; // set true to debug HH routing
        }

        NSArray<CLLocation *> *targets = (inters.count > 0) ? [inters arrayByAddingObject:en] : @[en];

        if (router->CALCULATE_MISSING_MAPS)
        {
            if (!_missingMapsCalculator)
            {
                _missingMapsCalculator = [MissingMapsCalculator new];
            }
            params.missingMapsResult = [_missingMapsCalculator checkIfThereAreMissingMaps:ctx start:st targets:targets checkHHEditions:!oldRouting];
            if (params.missingMapsResult)
            {
                if (router->CONTINUE_ON_MISSING_MAPS)
                {
                    NSLog(@"%@", [params.missingMapsResult getErrorMessage]);
                }
                else
                {
                    return [[OARouteCalculationResult alloc] initWithErrorMessage:[params.missingMapsResult getErrorMessage]];
                }
            }
        }

        if (complexCtx)
        {
            try
            {
                [self calculateRegionsWithAllRoutePoints:complexCtx start:st targets:targets];
                result = router->searchRoute(complexCtx, startX, startY, endX, endY, intX, intY, precalculated);
                // discard ctx and replace with calculated
                ctx = complexCtx;
            }
            catch (NSException *e)
            {
                /* TODO toast
                params.ctx.runInUIThread(new Runnable() {
                    @Override
                    public void run() {
                        params.ctx.showToastMessage(R.string.complex_route_calculation_failed, e.getMessage());
                    }
                });
                 */
                [self calculateRegionsWithAllRoutePoints:ctx start:st targets:targets];
                result = router->searchRoute(ctx, startX, startY, endX, endY, intX, intY);
            }
        }
        else
        {
            [self calculateRegionsWithAllRoutePoints:ctx start:st targets:targets];
            result = router->searchRoute(ctx, startX, startY, endX, endY, intX, intY);
        }
        
        // the router raises this on its own progress as the search starts, and the route screen reads
        // it off the shared one; a search that ends before anything is polled publishes it here
        if (ctx->progress != nullptr && ctx->progress->requestPrivateAccessRouting)
            params.calculationProgress.requestPrivateAccessRouting = YES;

        if (result.empty())
        {
            if (ctx->progress->segmentNotFound == 0)
            {
                return [[OARouteCalculationResult alloc] initWithErrorMessage:OALocalizedString(@"starting_point_too_far")];
            }
            else if(ctx->progress->segmentNotFound == inters.count + 1)
            {
                return [[OARouteCalculationResult alloc] initWithErrorMessage:OALocalizedString(@"ending_point_too_far")];
            }
            else if(ctx->progress->segmentNotFound > 0)
            {
                return [[OARouteCalculationResult alloc] initWithErrorMessage:[NSString stringWithFormat:OALocalizedString(@"ending_point_too_far"), ctx->progress->segmentNotFound]];
            }
            if (ctx->progress->directSegmentQueueSize == 0)
            {
                return [[OARouteCalculationResult alloc] initWithErrorMessage:[NSString stringWithFormat:@"Route can not be found from start point (%f km)", ctx->progress->distanceFromBegin / 1000]];
            }
            else if(ctx->progress->reverseSegmentQueueSize == 0)
            {
                return [[OARouteCalculationResult alloc] initWithErrorMessage:[NSString stringWithFormat:@"Route can not be found from end point (%f km)", ctx->progress->distanceFromEnd / 1000]];
            }
            if (ctx->progress->isCancelled())
            {
                return [self interrupted];
            }
            
            // something really strange better to see that message on the scren
            return [self emptyResult];
        }
        else
        {
            float routingTime = 0;
            if (ctx->progress)
                routingTime = ctx->progress->routingCalculatedTime;
            
            OARouteCalculationResult *res = [[OARouteCalculationResult alloc] initWithSegmentResults:[OACppRouteConverter toSharedSegments:result] start:params.start end:params.end intermediates:params.intermediates leftSide:params.leftSide routingTime:routingTime waypoints:!params.gpxRoute ? nil : params.gpxRoute.wpt mode:params.mode calculateFirstAndLastPoint:YES initialCalculation:params.initialCalculation];
            // The C++ router takes the previous route back as its own segments when only the start
            // moved, so the one it just produced is kept beside the result built from it.
            _previousCppResult = res;
            _previousCppRoute = result;
            return res;
        }
    }
    catch (const std::bad_alloc &e)
    {
        NSLog(@"Failed to calculate route: %s", e.what());
        return [[OARouteCalculationResult alloc] initWithErrorMessage:kRouteCalculationOutOfMemoryError];
    }
    catch (const std::exception &e)
    {
        NSLog(@"Failed to calculate route: %s", e.what());
        return [[OARouteCalculationResult alloc] initWithErrorMessage:RouteCalculationErrorMessage(e)];
    }
    catch (NSException *e)
    {
        return [[OARouteCalculationResult alloc] initWithErrorMessage:e.reason];
    }
}

- (void) calculateRegionsWithAllRoutePoints:(std::shared_ptr<RoutingContext>)ctx
                                      start:(CLLocation *)start
                                    targets:(NSArray<CLLocation *> *)targets
{
    NSMutableDictionary<NSString*, NSNumber*> *regionCounter = [NSMutableDictionary dictionary];

    [self getRegionsOfPoint:start regionCounter:regionCounter];

    for (CLLocation *loc in targets) {
       [self getRegionsOfPoint:loc regionCounter:regionCounter];
    }

    int allPoints = 1 + (int)targets.count;

    std::vector<std::string> result;
    for (NSString *region in regionCounter) {
        if ([regionCounter[region] intValue] == allPoints) {
            result.emplace_back([region UTF8String]);
        }
    }
    ctx->regionsCoveringStartAndTargets = std::move(result);
}

- (void) getRegionsOfPoint:(CLLocation *) ll
             regionCounter:(NSMutableDictionary<NSString*, NSNumber*> *) regionCounter
{
    NSArray<OAWorldRegion *> *regionsArray = [_or getWorldRegionsAtWithoutSort:ll.coordinate.latitude longitude:ll.coordinate.longitude];
    for (OAWorldRegion *region in regionsArray)
    {
        NSString *name = region.downloadsIdPrefix;
        if ([name hasSuffix:@"."])
        {
            name = [name substringToIndex:[name length] - 1];
        }
        regionCounter[name] = @([regionCounter[name] integerValue] + 1);
    }
}

- (OARoutingEnvironment *) getRoutingEnvironment:(OAApplicationMode *)mode start:(CLLocation *)start end:(CLLocation *)end
{
	OARouteCalculationParams *params = [[OARouteCalculationParams alloc] init];
	params.mode = mode;
	params.start = start;
	params.end = end;
	if ([[OAAppSettings sharedManager].useSharedRouting get])
		return [self calculateSharedRoutingEnvironment:params];

	return [self calculateRoutingEnvironment:params calcGPXRoute:NO skipComplex:YES];
}

// Opens the obf files the route runs over, so that both planners search the same maps.
- (void) checkInitializedForParams:(OARouteCalculationParams *)params
{
    int leftX = get31TileNumberX(params.start.coordinate.longitude);
    int rightX = leftX;
    int bottomY = get31TileNumberY(params.start.coordinate.latitude);
    int topY = bottomY;
    for (CLLocation *l in params.intermediates)
    {
        leftX = MIN(get31TileNumberX(l.coordinate.longitude), leftX);
        rightX = MAX(get31TileNumberX(l.coordinate.longitude), rightX);
        bottomY = MAX(get31TileNumberY(l.coordinate.latitude), bottomY);
        topY = MIN(get31TileNumberY(l.coordinate.latitude), topY);
    }
    leftX = MIN(get31TileNumberX(params.end.coordinate.longitude), leftX);
    rightX = MAX(get31TileNumberX(params.end.coordinate.longitude), rightX);
    bottomY = MAX(get31TileNumberY(params.end.coordinate.latitude), bottomY);
    topY = MIN(get31TileNumberY(params.end.coordinate.latitude), topY);

    [self checkInitialized:15 leftX:leftX rightX:rightX bottomY:bottomY topY:topY];
}

- (std::vector<SHARED_PTR<GpxPoint>>) generateGpxPoints:(OARoutingEnvironment *)env gctx:(SHARED_PTR<GpxRouteApproximation>)gctx locationsHolder:(OALocationsHolder *)locationsHolder
{
    if (!env || !env.router || !locationsHolder || gctx == nullptr || gctx->ctx == nullptr || gctx->ctx->config == nullptr)
        return {};

    return env.router->generateGpxPoints(gctx, locationsHolder.getLatLonList);
}

- (SHARED_PTR<GpxRouteApproximation>)calculateGpxApproximation:(OARoutingEnvironment *)env
                                                         gctx:(SHARED_PTR<GpxRouteApproximation>)gctx
                                                       points:(std::vector<SHARED_PTR<GpxPoint>> &)points
                                              locationsHolder:(OALocationsHolder *)locationsHolder
                                         useExternalTimestamps:(BOOL)useExternalTimestamps
                                                resultMatcher:(OAResultMatcher<OAGpxRouteApproximation *> *)resultMatcher
{
    if (!env || !env.router || gctx == nullptr || gctx->ctx == nullptr || gctx->ctx->config == nullptr || gctx->ctx->progress == nullptr || points.empty())
    {
        [resultMatcher publish:nil];
        return nullptr;
    }

    @synchronized (_nativeRoutingLock) {
        const auto resultAcceptor =
        [resultMatcher, locationsHolder, useExternalTimestamps]
        (SHARED_PTR<GpxRouteApproximation> approximation) -> bool
        {
            if (approximation == nullptr)
            {
                [resultMatcher publish:nil];
                return true;
            }

            if (useExternalTimestamps)
                OAApplyExternalTimestamps(approximation, locationsHolder);
            OAGpxRouteApproximation *approx = [OACppRouteConverter toSharedApproximation:approximation];
            [resultMatcher publish:approx];
            return true;
        };

        env.router->setUseGeometryBasedApproximation(true);
        env.router->searchGpxRoute(gctx, points, resultAcceptor);

        return gctx;
    }
}

- (OARoutingEnvironment *) calculateRoutingEnvironment:(OARouteCalculationParams *)params calcGPXRoute:(BOOL)calcGPXRoute skipComplex:(BOOL)skipComplex
{
    auto router = std::make_shared<RoutePlannerFrontEnd>();
    OsmAndAppInstance app = [OsmAndApp instance];
    OAAppSettings *settings = [OAAppSettings sharedManager];
    router->setUseFastRecalculation(settings.useFastRecalculation);

    router->CALCULATE_MISSING_MAPS = !settings.ignoreMissingMaps;
    router->CONTINUE_ON_MISSING_MAPS = true; // unlike Android, false is never required

    auto config = [app getRoutingConfigForMode:params.mode];
    auto generalRouter = [app getRouter:config mode:params.mode];
    if (!generalRouter)
        return nil;
    
    auto cf = [self initOsmAndRoutingConfig:config params:params generalRouter:generalRouter];
    if (!cf)
        return nil;
    
    std::shared_ptr<PrecalculatedRouteDirection> precalculated = nullptr;
    if (calcGPXRoute)
    {
        NSArray<CLLocation *> *sublist = [self findStartAndEndLocationsFromRoute:params.gpxRoute.points startLoc:params.start endLoc:params.end startI:nil endI:nil];
        vector<int> x31;
        vector<int> y31(sublist.count);
        for (int k = 0; k < sublist.count; k ++)
        {
            x31.push_back(get31TileNumberX(sublist[k].coordinate.longitude));
            y31.push_back(get31TileNumberY(sublist[k].coordinate.latitude));
        }
        precalculated = PrecalculatedRouteDirection::build(x31, y31, generalRouter->getMaxSpeed());
        precalculated->followNext = true;
        //cf.planRoadDirection = 1;
    }
    // BUILD context
    // check loaded files
    [self checkInitializedForParams:params];

    auto ctx = router->buildRoutingContext(cf, RouteCalculationMode::NORMAL);
    
    std:shared_ptr<RoutingContext> complexCtx = nullptr;
    BOOL complex = !skipComplex && [params.mode isDerivedRoutingFrom:[OAApplicationMode CAR]] && !settings.disableComplexRouting && !precalculated;
    const auto progress = std::make_shared<OACppRouteCalculationProgress>(params.calculationProgress);
    ctx->leftSideNavigation = params.leftSide;
    ctx->progress = progress;
    ctx->setConditionalTime(cf->routeCalculationTime);
    if (params.previousToRecalculate && params.onlyStartPointChanged)
    {
        int currentRoute = params.previousToRecalculate.currentRoute;
        if (params.previousToRecalculate == _previousCppResult && currentRoute < (int) _previousCppRoute.size())
        {
            std::vector<std::shared_ptr<RouteSegmentResult>> prevCalcRoute(_previousCppRoute.begin() + currentRoute, _previousCppRoute.end());
            ctx->previouslyCalculatedRoute = prevCalcRoute;
        }
    }
    
    if (complex && router->getRecalculationEnd(ctx.get()))
        complex = false;
    
    if (complex)
    {
        complexCtx = router->buildRoutingContext(cf, RouteCalculationMode::COMPLEX);
        complexCtx->progress = progress;
        complexCtx->leftSideNavigation = params.leftSide;
        complexCtx->previouslyCalculatedRoute = ctx->previouslyCalculatedRoute;
        complexCtx->setConditionalTime(cf->routeCalculationTime);
    }
    
    return [[OARoutingEnvironment alloc] initWithRouter:router context:ctx complextCtx:complexCtx precalculated:precalculated];
}

#pragma mark - OsmAndShared routing

static BOOL OAProfilesContain(OASKotlinArray<NSString *> *profiles, NSString *profile)
{
    for (int i = 0; i < profiles.size; i++)
    {
        if ([[profiles getIndex:i] isEqualToString:profile])
            return YES;
    }
    return NO;
}

// The obf files the route covers, as OsmAndShared readers. Creating one reads the file's index, so
// they are kept open until the installed maps change; the ones a search may still be holding are
// closed here, on the routing thread, rather than under it.
- (NSArray<OASBinaryMapIndexReader *> *) sharedRouteReaders
{
    @synchronized (self)
    {
        [self closeStaleSharedReaders];

        NSMutableArray<OASBinaryMapIndexReader *> *readers = [NSMutableArray array];
        for (NSString *path in [_nativeFiles.allObjects sortedArrayUsingSelector:@selector(compare:)])
        {
            OASBinaryMapIndexReader *reader = _sharedReaders[path];
            if (!reader)
            {
                if (![NSFileManager.defaultManager fileExistsAtPath:path])
                    continue;
                reader = [[OASBinaryMapIndexReader alloc] initWithFilePath:path];
                _sharedReaders[path] = reader;
            }
            if ([reader containsRouteData])
                [readers addObject:reader];
        }
        return readers;
    }
}

// The readers left over from a change of the installed maps. A routing environment that is still in
// use holds its own - a track being approximated searches over them between one calculation and the
// next - and reading through a closed reader throws inside OsmAndShared, where the exception cannot
// be caught, so those are kept until the environment is gone. Both locks are held here: the routing
// one by the caller, which keeps a running search away, and this object's, which guards the two
// collections.
- (void) closeStaleSharedReaders
{
    if (_staleSharedReaders.count == 0)
        return;

    NSMutableArray<OASBinaryMapIndexReader *> *inUse = [NSMutableArray array];
    for (OARoutingEnvironment *env in _liveSharedEnvironments)
    {
        if (env.sharedCtx)
            [inUse addObjectsFromArray:[env.sharedCtx getMaps]];
    }

    NSMutableArray<OASBinaryMapIndexReader *> *kept = [NSMutableArray array];
    for (OASBinaryMapIndexReader *reader in _staleSharedReaders)
    {
        if ([inUse indexOfObjectIdenticalTo:reader] == NSNotFound)
            [reader close];
        else
            [kept addObject:reader];
    }
    _staleSharedReaders = kept;
}

- (OASRoutingConfiguration *) buildSharedRoutingConfig:(OASRoutingConfigurationBuilder *)builder
                                                params:(OARouteCalculationParams *)params
                                         generalRouter:(OASGeneralRouter *)generalRouter
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    OASGeneralRouterCompanion *routerNames = OASGeneralRouter.companion;
    NSString *derivedProfile = params.mode.getDerivedProfile;
    NSMutableDictionary<NSString *, NSString *> *paramsR = [NSMutableDictionary dictionary];
    NSDictionary<NSString *, OASGeneralRouterRoutingParameter *> *routerParams = [generalRouter getParameters];
    for (NSString *key in routerParams)
    {
        OASGeneralRouterRoutingParameter *pr = routerParams[key];
        // the parameters of the derived profile, as RoutingHelperUtils.getParametersForDerivedProfile picks them
        OASKotlinArray<NSString *> *profiles = [pr getProfiles];
        if (profiles && !OAProfilesContain(profiles, derivedProfile))
            continue;

        NSString *vl = nil;
        if ([key isEqualToString:routerNames.USE_SHORTEST_WAY])
        {
            vl = [settings.fastRouteMode get:params.mode] ? nil : @"true";
        }
        else if ([[pr getType] isEqual:OASGeneralRouterRoutingParameterType.boolean])
        {
            OACommonBoolean *pref = [settings getCustomRoutingBooleanProperty:key defaultValue:[pr getDefaultBoolean]];
            vl = [pref get:params.mode] ? @"true" : nil;
        }
        else // NUMERIC
        {
            OACommonString *pref = [settings getCustomRoutingProperty:key defaultValue:[pr getDefaultString]];
            NSString *s = [pref get:params.mode];
            if (s.doubleValue != 0 || [pr getDefaultNumeric] != 0)
                vl = s;
        }

        if (vl.length > 0)
            paramsR[key] = vl;
    }
    double defaultSpeed = params.mode.getDefaultSpeed;
    if (defaultSpeed > 0)
        paramsR[routerNames.DEFAULT_SPEED] = [NSString stringWithFormat:@"%f", defaultSpeed];
    double minSpeed = params.mode.getMinSpeed;
    if (minSpeed > 0)
        paramsR[routerNames.MIN_SPEED] = [NSString stringWithFormat:@"%f", minSpeed];
    double maxSpeed = params.mode.getMaxSpeed;
    if (maxSpeed > 0)
        paramsR[routerNames.MAX_SPEED] = [NSString stringWithFormat:@"%f", maxSpeed];

    // the roads to avoid live on the C++ configs, which the app fills as they are added and removed
    [builder clearImpassableRoadLocations];
    for (OAAvoidRoadInfo *roadInfo in [OAAvoidSpecificRoads instance].getImpassableRoads)
    {
        if (roadInfo.roadId != 0)
            [builder addImpassableRoadRouteId:roadInfo.roadId];
    }

    float mb = (1 << 20);
    int memoryLimit = (int) (0.1 * (NSProcessInfo.processInfo.physicalMemory / mb));
    OASRoutingConfigurationRoutingMemoryLimits *memoryLimits =
        [[OASRoutingConfigurationRoutingMemoryLimits alloc] initWithMemoryLimitMb:memoryLimit nativeMemoryLimitMb:memoryLimit];

    NSString *routingProfile = [derivedProfile isEqualToString:@"default"] ? params.mode.getRoutingProfile : derivedProfile;
    OASDouble *direction = params.start.course >= 0.0 ? [OASDouble numberWithDouble:params.start.course / 180.0 * M_PI] : nil;
    OASRoutingConfiguration *cf = [builder buildRouter:routingProfile
                                             direction:direction
                                          memoryLimits:memoryLimits
                                                params:(OASMutableDictionary<NSString *, NSString *> *) paramsR];
    if ([settings.enableTimeConditionalRouting get:params.mode])
        cf.routeCalculationTime = (int64_t) (NSDate.date.timeIntervalSince1970 * 1000); // java reads the conditions off a millisecond clock
    return cf;
}

- (void) calculateSharedRegionsWithAllRoutePoints:(OASRoutingContext *)ctx
                                            start:(CLLocation *)start
                                          targets:(NSArray<CLLocation *> *)targets
{
    NSMutableDictionary<NSString *, NSNumber *> *regionCounter = [NSMutableDictionary dictionary];
    [self getRegionsOfPoint:start regionCounter:regionCounter];
    for (CLLocation *loc in targets)
        [self getRegionsOfPoint:loc regionCounter:regionCounter];

    int allPoints = 1 + (int) targets.count;
    NSMutableArray<NSString *> *result = [NSMutableArray array];
    for (NSString *region in regionCounter)
    {
        if (regionCounter[region].intValue == allPoints)
            [result addObject:region];
    }
    ctx.regionsCoveringStartAndTargets = [OASKotlinArray arrayWithSize:(int32_t) result.count init:^id(OASInt *index) {
        return result[index.intValue];
    }];
}

- (OARouteCalculationResult *) findSharedRoute:(OARouteCalculationParams *)params calcGPXRoute:(BOOL)calcGPXRoute
{
    [self checkInitializedForParams:params];

    OARouteCalculationResult *result = [self calcSharedRouteImpl:params calcGPXRoute:calcGPXRoute readers:[self sharedRouteReaders]];
    [_missingMapsCalculator attachResult:params.missingMapsResult toRouteCalculationResult:result];
    return result;
}

- (OARouteCalculationResult *) calcSharedRouteImpl:(OARouteCalculationParams *)params
                                      calcGPXRoute:(BOOL)calcGPXRoute
                                           readers:(NSArray<OASBinaryMapIndexReader *> *)readers
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    OsmAndAppInstance app = [OsmAndApp instance];

    OASRoutingConfigurationBuilder *builder = [app getSharedRoutingConfigForMode:params.mode];
    OASGeneralRouter *generalRouter = [app getSharedRouter:builder mode:params.mode];
    if (!generalRouter)
        return [self applicationModeNotSupported:params];

    OASRoutingConfiguration *cf = [self buildSharedRoutingConfig:builder params:params generalRouter:generalRouter];

    OASRoutePlannerFrontEnd *router = [[OASRoutePlannerFrontEnd alloc] init];
    [router setUseFastRecalculationUse:settings.useFastRecalculation];
    // Whether the maps the route needs are checked below, and how strictly the HH planner groups
    // the maps it uses.
    OASRoutePlannerFrontEnd.companion.CALCULATE_MISSING_MAPS = !settings.ignoreMissingMaps;
    if (![settings.useOldRouting get])
        [router setDefaultHHRoutingConfig];

    OASPrecalculatedRouteDirection *precalculated = nil;
    if (calcGPXRoute)
    {
        NSArray<CLLocation *> *sublist = [self findStartAndEndLocationsFromRoute:params.gpxRoute.points startLoc:params.start endLoc:params.end startI:nil endI:nil];
        NSArray<OASKLatLon *> *latLons = [self.class coordsToLatLons:sublist];
        OASKotlinArray<OASKLatLon *> *ls = [OASKotlinArray arrayWithSize:(int32_t) latLons.count init:^id(OASInt *index) {
            return latLons[index.intValue];
        }];
        precalculated = [OASPrecalculatedRouteDirection.companion buildLs:ls maxSpeed:[generalRouter getMaxSpeed]];
        [precalculated setFollowNextFollowNext:YES];
    }

    // BUILD context
    OASRouteCalculationProgress *progress = params.calculationProgress ?: [[OASRouteCalculationProgress alloc] init];
    OASRoutingContext *ctx = [router buildRoutingContextConfig:cf map:readers rm:OASRouteCalculationMode.normal];
    ctx.calculationProgress = progress;
    ctx.leftSideNavigation = params.leftSide;
    ctx.publicTransport = params.inPublicTransportMode;
    ctx.startTransportStop = params.startTransportStop;
    ctx.targetTransportStop = params.targetTransportStop;
    if (params.previousToRecalculate && params.onlyStartPointChanged)
    {
        int currentRoute = params.previousToRecalculate.currentRoute;
        NSArray<OASRouteSegmentResult *> *originalRoute = [params.previousToRecalculate getOriginalRoute];
        if (currentRoute < (int) originalRoute.count)
            ctx.previouslyCalculatedRoute = [originalRoute subarrayWithRange:NSMakeRange(currentRoute, originalRoute.count - currentRoute)];
    }

    BOOL complex = [params.mode isDerivedRoutingFrom:[OAApplicationMode CAR]] && !settings.disableComplexRouting
        && !precalculated && ![router getRecalculationEndCtx:ctx];
    OASRoutingContext *complexCtx = nil;
    if (complex)
    {
        complexCtx = [router buildRoutingContextConfig:cf map:readers rm:OASRouteCalculationMode.complex_];
        complexCtx.calculationProgress = progress;
        complexCtx.leftSideNavigation = params.leftSide;
        complexCtx.previouslyCalculatedRoute = ctx.previouslyCalculatedRoute;
    }

    OASKLatLon *st = [[OASKLatLon alloc] initWithLatitude:params.start.coordinate.latitude longitude:params.start.coordinate.longitude];
    OASKLatLon *en = [[OASKLatLon alloc] initWithLatitude:params.end.coordinate.latitude longitude:params.end.coordinate.longitude];
    NSArray<OASKLatLon *> *inters = params.intermediates ? [self.class coordsToLatLons:params.intermediates] : @[];
    NSArray<CLLocation *> *targets = params.intermediates.count > 0
        ? [params.intermediates arrayByAddingObject:params.end] : @[params.end];
    [self calculateSharedRegionsWithAllRoutePoints:ctx start:params.start targets:targets];
    if (complexCtx)
        [self calculateSharedRegionsWithAllRoutePoints:complexCtx start:params.start targets:targets];

    // java checks the maps inside the planner, which reads the region index through the host; here
    // the host runs the check itself, and the planner learns the answer from the routing status the
    // HH search reads out of the progress. Both contexts share that progress.
    if (OASRoutePlannerFrontEnd.companion.CALCULATE_MISSING_MAPS)
    {
        if (!_missingMapsCalculator)
            _missingMapsCalculator = [MissingMapsCalculator new];

        params.missingMapsResult = [_missingMapsCalculator checkIfThereAreMissingSharedMaps:ctx
                                                                                      start:params.start
                                                                                    targets:targets
                                                                            checkHHEditions:![settings.useOldRouting get]];
        if (params.missingMapsResult)
        {
            // the route is calculated anyway, as it is on the C++ planner, where iOS never sets
            // CONTINUE_ON_MISSING_MAPS to false; the outcome waits for the required maps screen
            NSLog(@"%@", [params.missingMapsResult getErrorMessage]);
        }
    }

    OASRouteCalcResult *result;
    OASRoutingContext *usedCtx;
    if (complexCtx)
    {
        // java falls back to the normal context when the complex search throws; a Kotlin exception
        // does not reach Objective-C, so there is nothing to fall back after
        result = [router searchRouteCtx:complexCtx start:st end:en intermediates:inters routeDirectionArg:precalculated];
        usedCtx = complexCtx;
    }
    else
    {
        result = [router searchRouteCtx:ctx start:st end:en intermediates:inters];
        usedCtx = ctx;
    }

    if (progress.isCancelled)
        return [self interrupted];

    NSArray<OASRouteSegmentResult *> *list = [result getList];
    if (list.count == 0)
    {
        if (progress.segmentNotFound == 0)
            return [[OARouteCalculationResult alloc] initWithErrorMessage:OALocalizedString(@"starting_point_too_far")];
        else if (progress.segmentNotFound == (int) inters.count + 1)
            return [[OARouteCalculationResult alloc] initWithErrorMessage:OALocalizedString(@"ending_point_too_far")];
        else if (progress.segmentNotFound > 0)
            return [[OARouteCalculationResult alloc] initWithErrorMessage:[NSString stringWithFormat:OALocalizedString(@"ending_point_too_far"), progress.segmentNotFound]];
        else if (progress.directSegmentQueueSize == 0)
            return [[OARouteCalculationResult alloc] initWithErrorMessage:[NSString stringWithFormat:@"Route can not be found from start point (%f km)", progress.distanceFromBegin / 1000]];
        else if (progress.reverseSegmentQueueSize == 0)
            return [[OARouteCalculationResult alloc] initWithErrorMessage:[NSString stringWithFormat:@"Route can not be found from end point (%f km)", progress.distanceFromEnd / 1000]];
        else if ([result getError_].length > 0)
            return [[OARouteCalculationResult alloc] initWithErrorMessage:[result getError_]];

        // something really strange better to see that message on the scren
        return [self emptyResult];
    }
    return [[OARouteCalculationResult alloc] initWithSegmentResults:list
                                                              start:params.start
                                                                end:params.end
                                                      intermediates:params.intermediates
                                                           leftSide:params.leftSide
                                                        routingTime:usedCtx.routingTime
                                                          waypoints:!params.gpxRoute ? nil : params.gpxRoute.wpt
                                                               mode:params.mode
                                         calculateFirstAndLastPoint:YES
                                                 initialCalculation:params.initialCalculation];
}

#pragma mark - OsmAndShared gpx approximation

// The twin of calculateRoutingEnvironment: - the same configuration and the same files, read by
// OsmAndShared. The track approximation is its only caller and it searches from no start to no
// target, so there is neither a complex context nor a precalculated direction to build.
- (OARoutingEnvironment *) calculateSharedRoutingEnvironment:(OARouteCalculationParams *)params
{
    OsmAndAppInstance app = [OsmAndApp instance];
    OAAppSettings *settings = [OAAppSettings sharedManager];

    OASRoutingConfigurationBuilder *builder = [app getSharedRoutingConfigForMode:params.mode];
    OASGeneralRouter *generalRouter = [app getSharedRouter:builder mode:params.mode];
    if (!generalRouter)
        return nil;

    OASRoutingConfiguration *cf = [self buildSharedRoutingConfig:builder params:params generalRouter:generalRouter];

    // the environment outlives this call and keeps searching over these readers, so it is built
    // where no other search is running and where the readers cannot be closed underneath it
    @synchronized (_nativeRoutingLock)
    {
        [self checkInitializedForParams:params];

        OASRoutePlannerFrontEnd *router = [[OASRoutePlannerFrontEnd alloc] init];
        [router setUseFastRecalculationUse:settings.useFastRecalculation];
        OASRoutePlannerFrontEnd.companion.CALCULATE_MISSING_MAPS = !settings.ignoreMissingMaps;

        OASRoutingContext *ctx = [router buildRoutingContextConfig:cf
                                                               map:[self sharedRouteReaders]
                                                                rm:OASRouteCalculationMode.normal];
        ctx.leftSideNavigation = params.leftSide;

        OARoutingEnvironment *env = [[OARoutingEnvironment alloc] initWithSharedRouter:router context:ctx];
        @synchronized (self)
        {
            [_liveSharedEnvironments addObject:env];
        }
        return env;
    }
}

- (NSArray<OASGpxPoint *> *) generateSharedGpxPoints:(OARoutingEnvironment *)env
                                                gctx:(OASGpxRouteApproximation *)gctx
                                     locationsHolder:(OALocationsHolder *)locationsHolder
{
    if (!env.sharedRouter || !gctx || locationsHolder.size == 0)
        return @[];

    // the times come along with the points: OsmAndShared reads the track's own timestamps off them
    // where the C++ side is handed the locations again afterwards
    NSMutableArray<OASKLatLon *> *locations = [NSMutableArray arrayWithCapacity:locationsHolder.size];
    OASKotlinLongArray *times = [OASKotlinLongArray arrayWithSize:(int32_t) locationsHolder.size];
    for (NSInteger i = 0; i < locationsHolder.size; i++)
    {
        [locations addObject:[[OASKLatLon alloc] initWithLatitude:[locationsHolder getLatitude:i]
                                                        longitude:[locationsHolder getLongitude:i]]];
        [times setIndex:(int32_t) i value:[locationsHolder timeAtIndex:i]];
    }
    return [env.sharedRouter generateGpxPointsGctx:gctx locations:locations times:times];
}

- (OASGpxRouteApproximation *) calculateSharedGpxApproximation:(OARoutingEnvironment *)env
                                                          gctx:(OASGpxRouteApproximation *)gctx
                                                        points:(NSArray<OASGpxPoint *> *)points
                                         useExternalTimestamps:(BOOL)useExternalTimestamps
                                                 resultMatcher:(OAResultMatcher<OAGpxRouteApproximation *> *)resultMatcher
{
    if (!env.sharedRouter || !gctx || !gctx.ctx.calculationProgress || points.count == 0)
    {
        [resultMatcher publish:nil];
        return nil;
    }

    @synchronized (_nativeRoutingLock)
    {
        [env.sharedRouter setUseGeometryBasedApproximationEnabled:YES];
        OASGpxRouteApproximation *result = [env.sharedRouter searchGpxRouteGctx:gctx
                                                                     gpxPoints:points
                                                                 resultMatcher:nil
                                                         useExternalTimestamps:useExternalTimestamps];
        // what the search's own result matcher would publish: nothing of a cancelled approximation
        BOOL cancelled = gctx.ctx.calculationProgress.isCancelled;
        [resultMatcher publish:cancelled ? nil : [[OAGpxRouteApproximation alloc] initWithApproximation:result]];
        return gctx;
    }
}

- (void) runSyncWithNativeRouting:(void (^)(void))runBlock
{
    @synchronized (_nativeRoutingLock)
    {
        if (runBlock)
            runBlock();
    }
}

- (OARouteCalculationResult *) findVectorMapsRoute:(OARouteCalculationParams *)params calcGPXRoute:(BOOL)calcGPXRoute
{
    @synchronized (_nativeRoutingLock)
    {
        if ([[OAAppSettings sharedManager].useSharedRouting get])
            return [self findSharedRoute:params calcGPXRoute:calcGPXRoute];

        OARoutingEnvironment *env = [self calculateRoutingEnvironment:params calcGPXRoute:calcGPXRoute skipComplex:NO];

        if (!env)
            return [self applicationModeNotSupported:params];

        CLLocation *start = [[CLLocation alloc] initWithLatitude:params.start.coordinate.latitude longitude:params.start.coordinate.longitude];
        CLLocation *end = [[CLLocation alloc] initWithLatitude:params.end.coordinate.latitude longitude:params.end.coordinate.longitude];
        NSArray<CLLocation *> *inters = [NSArray new];

        if (params.intermediates)
            inters = [NSArray arrayWithArray:params.intermediates];

        OARouteCalculationResult *result = [self calcOfflineRouteImpl:params router:env.router ctx:env.ctx complexCtx:env.complexCtx st:start en:end inters:inters precalculated:env.precalculated];
        [_missingMapsCalculator attachResult:params.missingMapsResult toRouteCalculationResult:result];

        return result;
    }
}

- (OARouteCalculationResult *) calculateOsmAndRouteWithIntermediatePoints:(OARouteCalculationParams *)routeParams intermediates:(NSArray<CLLocation *> *)intermediates connectRtePts:(BOOL)connectRtePts
{
    OARouteCalculationParams *rp = [[OARouteCalculationParams alloc] init];
    rp.calculationProgress = routeParams.calculationProgress;
    rp.mode = routeParams.mode;
    rp.start = routeParams.start;
    rp.end = routeParams.end;
    rp.leftSide = routeParams.leftSide;
    rp.fast = routeParams.fast;
    rp.onlyStartPointChanged = routeParams.onlyStartPointChanged;
    rp.previousToRecalculate =  routeParams.previousToRecalculate;
    rp.extraIntermediates = YES;
    NSMutableArray<CLLocation *> *rpIntermediates = [NSMutableArray array];
    
    NSInteger closest = [self findClosestIntermediate:routeParams intermediates:intermediates];
    for (NSInteger i = closest; i < intermediates.count; i++)
    {
        CLLocation *w = intermediates[i];
        [rpIntermediates addObject:[[CLLocation alloc] initWithLatitude:w.coordinate.latitude longitude:w.coordinate.longitude]];
    }
    rp.intermediates = [NSArray arrayWithArray:rpIntermediates];
    EOARouteService routeService = (EOARouteService) routeParams.mode.getRouterService;
//    if (routeService == RouteService.BROUTER) {
//        try {
//            return findBROUTERRoute(rp);
//        } catch (ParserConfigurationException | SAXException e) {
//            throw new IOException(e);
//        }
//    } else
    if (routeService == STRAIGHT || routeService == DIRECT_TO || connectRtePts)
        return [self findStraightRoute:rp];
    
    OARouteCalculationResult *res = [self findVectorMapsRoute:rp calcGPXRoute:NO];
    [routeParams takeMissingMapsResultFrom:rp];
    return res;
}

- (NSInteger) findClosestIntermediate:(OARouteCalculationParams *)params intermediates:(NSArray<CLLocation *> *)intermediates
{
    NSInteger closest = 0;
    if (!params.gpxRoute.passWholeRoute)
    {
        double maxDist = DBL_MAX;
        for (NSInteger i = 0; i < intermediates.count; i++)
        {
            CLLocation *loc = intermediates[i];
            double dist = [params.start distanceFromLocation:loc];
            if (dist <= MIN_INTERMEDIATE_DIST)
            {
                return i;
            }
            else if (dist < maxDist)
            {
                closest = i;
                maxDist = dist;
            }
        }
    }
    return closest;
}

- (NSMutableArray<OARouteDirectionInfo *> *) calcDirections:(NSNumber *)startI endI:(NSNumber *)endI inputDirections:(NSArray<OARouteDirectionInfo *> *)inputDirections
{
    NSMutableArray<OARouteDirectionInfo *> *directions = [NSMutableArray array];
    if (inputDirections)
    {
        for (OARouteDirectionInfo *info in inputDirections)
        {
            if (info.routePointOffset >= startI.intValue && info.routePointOffset < endI.intValue)
            {
                OARouteDirectionInfo *ch = [[OARouteDirectionInfo alloc] initWithAverageSpeed:info.averageSpeed turnType:info.turnType];
                ch.routePointOffset = info.routePointOffset - startI.intValue;
                if (info.routeEndPointOffset != 0)
                    ch.routeEndPointOffset = info.routeEndPointOffset - startI.intValue;
                
                [ch setDescriptionRoute:[info getDescriptionRoutePart]];
                ch.routeDataObject = info.routeDataObject;
                
                // Issue #2894
                if (info.ref && ![@"null" isEqualToString:info.ref])
                    ch.ref = info.ref;
                
                if (info.streetName && ![@"null" isEqualToString:info.streetName])
                    ch.streetName = info.streetName;
                
                if (info.destinationName && ![@"null" isEqualToString:info.destinationName])
                    ch.destinationName = info.destinationName;
                
                [directions addObject:ch];
            }
        }
    }
    return directions;
}

- (OARouteCalculationResult *) findOfflineRouteSegment:(OARouteCalculationParams *)params start:(CLLocation *)start end:(CLLocation  *)end
{
    OARouteCalculationParams *newParams = [[OARouteCalculationParams alloc] init];
    newParams.start = start;
    newParams.end = end;
    newParams.calculationProgress = params.calculationProgress;
    newParams.mode = params.mode;
    newParams.leftSide = params.leftSide;
    OARouteCalculationResult *newRes = nil;
    try
    {
        EOARouteService routeService = (EOARouteService) params.mode.getRouterService;
        if (routeService == OSMAND)
        {
            newRes = [self findVectorMapsRoute:newParams calcGPXRoute:NO];
        }
//        else if (routeService == RouteService.BROUTER)
//        {
//            newRes= findBROUTERRoute(newParams);
//        }
        else if (params.mode.getRouterService == STRAIGHT ||
                   params.mode.getRouterService == DIRECT_TO)
        {
            newRes = [self findStraightRoute:newParams];
        }
    }
    catch (NSException *e)
    {
    }
    [params takeMissingMapsResultFrom:newParams];
    return newRes;
}

- (void) insertFinalSegment:(OARouteCalculationParams *)routeParams points:(NSMutableArray<CLLocation *> *)points
                 directions:(NSMutableArray<OARouteDirectionInfo *> *)directions calculateOsmAndRouteParts:(BOOL)calculateOsmAndRouteParts
{
    if (points.count > 0)
    {
        CLLocation *routeEnd = points[points.count - 1];
        CLLocation *finalEnd = routeParams.end;
        if (finalEnd && [finalEnd distanceFromLocation:routeEnd] > MIN_DISTANCE_FOR_INSERTING_ROUTE_SEGMENT)
        {
            OARouteCalculationResult *newRes = nil;
            if (calculateOsmAndRouteParts)
                newRes = [self findOfflineRouteSegment:routeParams start:routeEnd end:finalEnd];
            
            NSArray<CLLocation *> *loct = nil;
            NSArray<OARouteDirectionInfo *> *dt = nil;
            if (newRes && [newRes isCalculated])
            {
                loct = [newRes getImmutableAllLocations];
                dt = [newRes getImmutableAllDirections];
            } else {
                NSMutableArray<CLLocation *> *lct = [NSMutableArray array];
                [lct addObject:finalEnd];
                dt = [NSArray array];
            }
            for (OARouteDirectionInfo *i in dt)
                i.routePointOffset += (int)points.count;
            
            [points addObjectsFromArray:loct];
            [directions addObjectsFromArray:dt];
        }
    }
}

- (void) insertInitialSegment:(OARouteCalculationParams *)routeParams points:(NSMutableArray<CLLocation *> *)points
                 directions:(NSMutableArray<OARouteDirectionInfo *> *)directions calculateOsmAndRouteParts:(BOOL)calculateOsmAndRouteParts
{
    CLLocation *realStart = routeParams.start;
    if (realStart && points.count > 0 && [realStart distanceFromLocation:points[0]] > MIN_DISTANCE_FOR_INSERTING_ROUTE_SEGMENT)
    {
        CLLocation *trackStart = points[0];
        OARouteCalculationResult *newRes = nil;
        if (calculateOsmAndRouteParts)
            newRes = [self findOfflineRouteSegment:routeParams start:realStart end:trackStart];

        NSArray<CLLocation *> *loct = nil;
        NSArray<OARouteDirectionInfo *> *dt = nil;
        if (newRes && [newRes isCalculated])
        {
            loct = [newRes getImmutableAllLocations];
            dt = [newRes getImmutableAllDirections];
        } else {
            NSMutableArray<CLLocation *> *lct = [NSMutableArray array];
            [lct addObject:realStart];
            dt = [NSArray array];
        }
        NSMutableIndexSet *inds = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, loct.count)];
        [points insertObjects:loct atIndexes:inds];
        inds = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, dt.count)];
        [directions insertObjects:dt atIndexes:inds];

        for (int i = (int)dt.count; i < directions.count; i++)
            directions[i].routePointOffset += (int)loct.count;
    }
}

- (OARouteCalculationResult *) findStraightRoute:(OARouteCalculationParams *)routeParams
{
    NSMutableArray<OALocation *> *points = [NSMutableArray new];
    NSMutableArray<CLLocation *> *segments = [NSMutableArray new];
    [points addObject:[[OALocation alloc] initWithProvider:@"pnt" location:routeParams.start]];
    if(routeParams.intermediates) {
        for (CLLocation *l in routeParams.intermediates)
        {
            [points addObject:[[OALocation alloc] initWithProvider:routeParams.extraIntermediates ? @"" : @"pnt" location:l]];
        }
        if (routeParams.extraIntermediates)
        {
            routeParams.intermediates = nil;
        }
    }
    [points addObject:[[OALocation alloc] initWithProvider:@"" location:routeParams.end]];
    OALocation *lastAdded = nil;
    float speed = [routeParams.mode getDefaultSpeed];
    NSMutableArray<OARouteDirectionInfo *> *computeDirections = [NSMutableArray new];
    while(points.count > 0)
    {
        CLLocation *pl = points.firstObject;
        if (lastAdded == nil || [lastAdded distanceFromLocation:pl] < MIN_STRAIGHT_DIST)
        {
            lastAdded = points.firstObject;
            [points removeObjectAtIndex:0];
            if(lastAdded && [lastAdded.provider isEqualToString:@"pnt"])
            {
                OARouteDirectionInfo *previousInfo = [[OARouteDirectionInfo alloc] initWithAverageSpeed:speed turnType:[OASTurnType.companion straight]];
                previousInfo.routePointOffset = (int) segments.count;
                [previousInfo setDescriptionRoute:OALocalizedString(@"route_head")];
                [computeDirections addObject:previousInfo];
            }
            [segments addObject:(CLLocation *) lastAdded];
        }
        else
        {
            OALocation *mp = [[OALocation alloc] initWithProvider:@"" location:[OAMapUtils calculateMidPoint:lastAdded s2:pl]];
            [points insertObject:mp atIndex:0];
        }
    }
    return [[OARouteCalculationResult alloc] initWithLocations:segments directions:computeDirections params:routeParams waypoints:nil addMissingTurns:routeParams.extraIntermediates];
}

+ (NSArray<OASKLatLon *> *) coordsToLatLons:(NSArray<CLLocation *> *)points
{
    NSMutableArray<OASKLatLon *> *res = [NSMutableArray arrayWithCapacity:points.count];
    for (CLLocation *pt in points)
        [res addObject:[[OASKLatLon alloc] initWithLatitude:pt.coordinate.latitude longitude:pt.coordinate.longitude]];

    return res;
}

- (OARouteCalculationResult *) calculateGpxRoute:(OARouteCalculationParams *)routeParams
{
    OAGPXRouteParams *gpxParams = routeParams.gpxRoute;
    BOOL calcWholeRoute = gpxParams.passWholeRoute && (routeParams.previousToRecalculate == nil || !routeParams.onlyStartPointChanged);
    BOOL calculateOsmAndRouteParts = gpxParams.calculateOsmAndRouteParts;
    BOOL reverseRoutePoints = gpxParams.reverse && gpxParams.routePoints.count > 1;
    NSArray<OASRouteSegmentResult *> *gpxRouteResult = routeParams.gpxRoute.route;
    if (reverseRoutePoints)
    {
        NSMutableArray<CLLocation *> *gpxRouteLocations = [NSMutableArray new];
        NSMutableArray<OASRouteSegmentResult *> *gpxRoute = [NSMutableArray array];
        OASWptPt *firstGpxPoint = gpxParams.routePoints.firstObject;
        CLLocation *start = [[CLLocation alloc] initWithLatitude:firstGpxPoint.getLatitude longitude:firstGpxPoint.getLongitude];
        
        for (NSInteger i = 1; i < gpxParams.routePoints.count; i++)
        {
            OASWptPt *gpxPoint = gpxParams.routePoints[i];
            OAApplicationMode *appMode = [OAApplicationMode valueOfStringKey:gpxPoint.getProfileType def:OAApplicationMode.DEFAULT];
            CLLocation *end = [[CLLocation alloc] initWithLatitude:gpxPoint.getLatitude longitude:gpxPoint.getLongitude];
            
            OARouteCalculationParams *params = [[OARouteCalculationParams alloc] init];
            params.inSnapToRoadMode = YES;
            params.start = start;
            params.end = end;
            [OARoutingHelper applyApplicationSettings:params appMode:appMode];
            params.mode = appMode;
            params.calculationProgress = routeParams.calculationProgress;
            OARouteCalculationResult *result = [self findOfflineRouteSegment:params start:start end:end];
            [routeParams takeMissingMapsResultFrom:params];
            NSArray<CLLocation *> *locations = result.getRouteLocations;
            NSArray<OASRouteSegmentResult *> *route = result.getOriginalRoute;
            if (route.count == 0)
            {
                if (locations.count == 0)
                {
                    CLLocation *endLoc = [[CLLocation alloc] initWithLatitude:end.coordinate.latitude longitude:end.coordinate.longitude];
                    locations = @[start, endLoc];
                }
                route = @[[OASRoutePlannerFrontEnd.companion generateStraightLineSegmentAverageSpeed:routeParams.mode.getDefaultSpeed
                                                                                             points:[self.class coordsToLatLons:locations]]];
            }
            [gpxRouteLocations addObjectsFromArray:locations];
            if (gpxRouteLocations.count > 0)
                [gpxRouteLocations removeLastObject];
            
            [gpxRoute addObjectsFromArray:route];
            
            start = [[CLLocation alloc] initWithLatitude:end.coordinate.latitude longitude:end.coordinate.longitude];
        }
        gpxParams.points = gpxRouteLocations;
        gpxParams.route = gpxRoute;
        gpxRouteResult = gpxRoute;
    }
    
    if (gpxRouteResult.count > 0)
    {
        if (calcWholeRoute && !calculateOsmAndRouteParts)
        {
            return [[OARouteCalculationResult alloc] initWithSegmentResults:gpxRouteResult start:routeParams.start end:routeParams.end intermediates:routeParams.intermediates leftSide:routeParams.leftSide routingTime:0. waypoints:gpxParams.wpt mode:routeParams.mode calculateFirstAndLastPoint:YES initialCalculation:routeParams.initialCalculation];
        }
        OARouteCalculationResult *result = [[OARouteCalculationResult alloc] initWithSegmentResults:gpxRouteResult start:routeParams.start end:routeParams.end intermediates:routeParams.intermediates leftSide:routeParams.leftSide routingTime:0. waypoints:gpxParams.wpt mode:routeParams.mode calculateFirstAndLastPoint:NO initialCalculation:routeParams.initialCalculation];
        NSArray<CLLocation *> *gpxRouteLocations = [result getImmutableAllLocations];
        NSInteger nearestGpxPointInd = calcWholeRoute ? 0 : [self findNearestGpxPointIndexFromRoute:gpxRouteLocations startLoc:routeParams.start calculateOsmAndRouteParts:calculateOsmAndRouteParts];
        CLLocation *nearestGpxLocation = nil;
        CLLocation *gpxLastLocation = gpxRouteLocations.count > 0 ? gpxRouteLocations.lastObject : nil;
        
        NSArray<OASRouteSegmentResult *> *firstSegmentRoute = @[];
        NSArray<OASRouteSegmentResult *> *lastSegmentRoute = @[];
        NSArray<OASRouteSegmentResult *> *gpxRoute = @[];
        
        if (nearestGpxPointInd > 0)
        {
            nearestGpxLocation = gpxRouteLocations[nearestGpxPointInd];
        }
        else if (gpxRouteLocations.count > 0)
        {
            nearestGpxLocation = gpxRouteLocations.firstObject;
        }
        
        if (calculateOsmAndRouteParts && !reverseRoutePoints && gpxParams.segmentEndPoints.count > 0)
        {
            gpxRoute = [self findRouteWithIntermediateSegments:routeParams result:result gpxRouteLocations:gpxRouteLocations segmentEndpoints:gpxParams.segmentEndPoints nearestGpxPointInd:nearestGpxPointInd];
        }
        else
        {
            if (nearestGpxPointInd > 0)
            {
                gpxRoute = [result getOriginalRoute:(int)nearestGpxPointInd includeFirstSegment:NO];
                if (gpxRoute.count > 0)
                {
                    OASKLatLon *startPoint = [gpxRoute[0] getStartPoint];
                    nearestGpxLocation = [[CLLocation alloc] initWithLatitude:startPoint.latitude longitude:startPoint.longitude];
                }
                else
                {
                    nearestGpxLocation = [[CLLocation alloc] initWithLatitude:routeParams.end.coordinate.latitude longitude:routeParams.end.coordinate.longitude];
                }
            }
            else
            {
                gpxRoute = result.getOriginalRoute;
            }
        }
        
        if (calculateOsmAndRouteParts
            && routeParams.start != nil && nearestGpxLocation != nil
            && [nearestGpxLocation distanceFromLocation:routeParams.start] > MIN_DISTANCE_FOR_INSERTING_ROUTE_SEGMENT)
        {
            OARouteCalculationResult *firstSegmentResult = [self findOfflineRouteSegment:routeParams start:routeParams.start end:[[CLLocation alloc] initWithLatitude:nearestGpxLocation.coordinate.latitude longitude:nearestGpxLocation.coordinate.longitude]];
            firstSegmentRoute = firstSegmentResult.getOriginalRoute;
        }
        if (calculateOsmAndRouteParts
            && routeParams.end != nil && gpxLastLocation != nil
            && getDistance(gpxLastLocation.coordinate.latitude, gpxLastLocation.coordinate.longitude,
                                    routeParams.end.coordinate.latitude, routeParams.end.coordinate.longitude) > MIN_DISTANCE_FOR_INSERTING_ROUTE_SEGMENT)
        {
            OARouteCalculationResult *lastSegmentResult = [self findOfflineRouteSegment:routeParams start:gpxLastLocation end:routeParams.end];
            lastSegmentRoute = lastSegmentResult.getOriginalRoute;
        }
        NSMutableArray<OASRouteSegmentResult *> *newGpxRoute = [NSMutableArray array];
        [newGpxRoute addObjectsFromArray:firstSegmentRoute];
        [newGpxRoute addObjectsFromArray:gpxRoute];
        [newGpxRoute addObjectsFromArray:lastSegmentRoute];
        
        if ([routeParams recheckRouteNearestPoint])
        {
            newGpxRoute = [[self checkNearestSegmentOnRecalculate:routeParams.previousToRecalculate segments:newGpxRoute startLocation:routeParams.start] mutableCopy];
        }
        
        return [[OARouteCalculationResult alloc] initWithSegmentResults:newGpxRoute start:routeParams.start end:routeParams.end intermediates:routeParams.intermediates leftSide:routeParams.leftSide routingTime:0. waypoints:gpxParams.wpt mode:routeParams.mode calculateFirstAndLastPoint:YES initialCalculation:routeParams.initialCalculation];
    }
    
    if (routeParams.gpxRoute.useIntermediatePointsRTE)
        return [self calculateOsmAndRouteWithIntermediatePoints:routeParams intermediates:gpxParams.points connectRtePts:gpxParams.connectPointsStraightly];
    
    NSMutableArray<CLLocation *> *gpxRoute = [NSMutableArray array];
    NSMutableArray<NSNumber *> *startI = [NSMutableArray arrayWithObject:@(0)];
    NSMutableArray<NSNumber *> *endI = [NSMutableArray arrayWithObject:@(gpxParams.points.count)];
    if (calcWholeRoute)
    {
        gpxRoute = [NSMutableArray arrayWithArray:gpxParams.points];
    }
    else
    {
        gpxRoute = [NSMutableArray arrayWithArray:[self findStartAndEndLocationsFromRoute:gpxParams.points startLoc:routeParams.start endLoc:routeParams.end startI:startI endI:endI]];
    }
    NSArray<OARouteDirectionInfo *> *inputDirections = gpxParams.directions;
    NSMutableArray<OARouteDirectionInfo *> *gpxDirections = [self calcDirections:startI[0] endI:endI[0] inputDirections:inputDirections];
    [self insertIntermediateSegments:routeParams points:gpxRoute directions:gpxDirections segmentEndpoints:gpxParams.segmentEndPoints calculateOsmAndRouteParts:calculateOsmAndRouteParts];
    [self insertInitialSegment:routeParams points:gpxRoute directions:gpxDirections calculateOsmAndRouteParts:calculateOsmAndRouteParts];
    [self insertFinalSegment:routeParams points:gpxRoute directions:gpxDirections calculateOsmAndRouteParts:calculateOsmAndRouteParts];
    
    if ([routeParams recheckRouteNearestPoint])
    {
        auto index = [self findNearestPointIndexOnRecalculate:routeParams.previousToRecalculate routeLocations:gpxRoute startLocation:routeParams.start];
        if (index > 0)
        {
            gpxDirections = [self calcDirections:[NSNumber numberWithInteger:index] endI:[NSNumber numberWithInteger:gpxRoute.count] inputDirections:gpxDirections];
            gpxRoute = [NSMutableArray arrayWithArray:[gpxRoute subarrayWithRange:NSMakeRange(index, gpxRoute.count - index)]];
        }
    }
    
    for (OARouteDirectionInfo *info in gpxDirections)
    {
        // recalculate
        info.distance = 0;
        info.afterLeftTime = 0;
    }
    
    return [[OARouteCalculationResult alloc] initWithLocations:gpxRoute directions:gpxDirections params:routeParams waypoints:gpxParams.wpt addMissingTurns:routeParams.gpxRoute.addMissingTurns];
}

- (NSArray<OASRouteSegmentResult *> *) findRouteWithIntermediateSegments:(OARouteCalculationParams *)routeParams result:(OARouteCalculationResult *)result gpxRouteLocations:(NSArray<CLLocation *> *)gpxRouteLocations segmentEndpoints:(NSArray<CLLocation *> *)segmentEndpoints nearestGpxPointInd:(NSInteger)nearestGpxPointInd
{
    NSMutableArray<OASRouteSegmentResult *> *newGpxRoute = [NSMutableArray array];
    
    NSInteger lastIndex = nearestGpxPointInd;
    for (NSInteger i = 0; i < (NSInteger) segmentEndpoints.count - 1; i += 2)
    {
        CLLocation *prevSegmentPoint = segmentEndpoints[i];
        CLLocation *newSegmentPoint = segmentEndpoints[i + 1];
        
        if ([prevSegmentPoint distanceFromLocation:newSegmentPoint] <= MIN_DISTANCE_FOR_INSERTING_ROUTE_SEGMENT)
            continue;

        NSInteger indexNew = [self findNearestGpxPointIndexFromRoute:gpxRouteLocations startLoc:newSegmentPoint calculateOsmAndRouteParts:NO];
        NSInteger indexPrev = [self findNearestGpxPointIndexFromRoute:gpxRouteLocations startLoc:prevSegmentPoint calculateOsmAndRouteParts:NO];
        if (indexPrev != -1 && indexPrev > nearestGpxPointInd && indexNew != -1)
        {
            [newGpxRoute addObjectsFromArray:[result getOriginalRoute:(int)lastIndex endIndex:(int)indexPrev includeFirstSegment:YES]];
            lastIndex = indexNew;
            
            CLLocation *end = [[CLLocation alloc] initWithLatitude:newSegmentPoint.coordinate.latitude longitude:newSegmentPoint.coordinate.longitude];
            OARouteCalculationResult *newRes = [self findOfflineRouteSegment:routeParams start:prevSegmentPoint end:end];
            [newGpxRoute addObjectsFromArray:newRes.getOriginalRoute];
        }
    }
    [newGpxRoute addObjectsFromArray:[result getOriginalRoute:(int)lastIndex]];
    
    return newGpxRoute;
}

- (void) insertIntermediateSegments:(OARouteCalculationParams *)routeParams points:(NSMutableArray<CLLocation *> *)points
                         directions:(NSMutableArray<OARouteDirectionInfo *> *)directions
                   segmentEndpoints:(NSArray<CLLocation *> *)segmentEndpoints
          calculateOsmAndRouteParts:(BOOL)calculateOsmAndRouteParts
{
    for (NSInteger i = 0; i < (NSInteger) segmentEndpoints.count - 1; i += 2)
    {
        CLLocation *prevSegmentPoint = segmentEndpoints[i];
        CLLocation *newSegmentPoint = segmentEndpoints[i + 1];
        
        if ([prevSegmentPoint distanceFromLocation:newSegmentPoint] <= MIN_DISTANCE_FOR_INSERTING_ROUTE_SEGMENT)
            continue;
        
        NSInteger index = [points indexOfObject:newSegmentPoint];
        if (calculateOsmAndRouteParts && index != NSNotFound && [points containsObject:prevSegmentPoint])
        {
            CLLocation *end = [[CLLocation alloc] initWithLatitude:newSegmentPoint.coordinate.latitude longitude:newSegmentPoint.coordinate.longitude];
            OARouteCalculationResult *newRes = [self findOfflineRouteSegment:routeParams start:prevSegmentPoint end:end];
            
            if (newRes != nil && newRes.isCalculated)
            {
                NSArray<CLLocation *> *loct = newRes.getImmutableAllLocations;
                NSArray<OARouteDirectionInfo *> *dt = newRes.getImmutableAllDirections;
                
                for (OARouteDirectionInfo *directionInfo in dt)
                {
                    directionInfo.routePointOffset += (int)points.count;
                }
                [points insertObjects:loct atIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(index, loct.count)]];
                
                [directions addObjectsFromArray:dt];
            }
        }
    }
}

- (NSInteger) findNearestGpxPointIndexFromRoute:(NSArray<CLLocation *> *)route startLoc:(CLLocation *)startLoc calculateOsmAndRouteParts:(BOOL)calculateOsmAndRouteParts
{
    double minDist = DBL_MAX;
    NSInteger nearestPointIndex = 0;
    if (startLoc != nil)
    {
        for (NSInteger i = 0; i < route.count; i++)
        {
            double d = [route[i] distanceFromLocation:startLoc];
            if (d < minDist)
            {
                nearestPointIndex = i;
                minDist = d;
            }
        }
    }
    if (nearestPointIndex > 0 && calculateOsmAndRouteParts)
    {
        CLLocation *nearestLocation = route[nearestPointIndex];
        for (NSInteger i = nearestPointIndex + 1; i < route.count; i++)
        {
            CLLocation *nextLocation = route[i];
            if ([nextLocation distanceFromLocation:nearestLocation] >= ADDITIONAL_DISTANCE_FOR_START_POINT)
            {
                return i;
            }
        }
    }
    return nearestPointIndex;
}

- (OARouteCalculationResult *) recalculatePartOfflineRoute:(OARouteCalculationResult *)res params:(OARouteCalculationParams *)params
{
    OARouteCalculationResult *rcr = params.previousToRecalculate;
    NSMutableArray<CLLocation *> *locs = [NSMutableArray arrayWithArray:[rcr getRouteLocations]];
    try
    {
        NSMutableArray<NSNumber *> *startI = [NSMutableArray arrayWithObject:@(0)];
        NSMutableArray<NSNumber *> *endI = [NSMutableArray arrayWithObject:@(locs.count)];
        locs = [NSMutableArray arrayWithArray:[self findStartAndEndLocationsFromRoute:locs startLoc:params.start endLoc:params.end startI:startI endI:endI]];
        NSMutableArray<OARouteDirectionInfo *> *directions = [self calcDirections:startI[0] endI:endI[0] inputDirections:[rcr getRouteDirections]];
        [self insertInitialSegment:params points:locs directions:directions calculateOsmAndRouteParts:YES];
        res = [[OARouteCalculationResult alloc] initWithLocations:locs directions:directions params:params waypoints:nil addMissingTurns:YES];
    }
    catch (NSException *e)
    {
    }
    return res;
}

- (OARouteCalculationResult *) calculateRouteImpl:(OARouteCalculationParams *)params
{
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    if (params.start && params.end)
    {
//        params.calculationProgress->routeCalculationStartTime = time;
        NSLog(@"Start finding route from %@ to %@ using %@", params.start, params.end, [OARouteService getName:(EOARouteService)params.mode.getRouterService]);
        try
        {
            OARouteCalculationResult *res = nil;
            BOOL calcGPXRoute = [self shouldCalculateGpxRouteWithParams:params];
            if (calcGPXRoute && !params.gpxRoute.calculateOsmAndRoute)
            {
                res = [self calculateGpxRoute:params];
            }
            else if (params.mode.getRouterService == OSMAND)
            {
                res = [self findVectorMapsRoute:params calcGPXRoute:calcGPXRoute];
            }
            //else if (params.mode.getRouterService == BROUTER)
            //{
            //    res = findBROUTERRoute(params);
            //}
            //else if (params.mode.getRouteService() == RouteService.ONLINE)
            //{
            //    boolean useFallbackRouting = false;
            //    try {
            //        res = findOnlineRoute(params);
            //    } catch (IOException | JSONException e) {
            //        res = new RouteCalculationResult(null);
            //        params.initialCalculation = false;
            //        useFallbackRouting = true;
            //    }
            //    if (useFallbackRouting || !res.isCalculated()) {
            //        OnlineRoutingHelper helper = params.ctx.getOnlineRoutingHelper();
            //        String engineKey = params.mode.getRoutingProfile();
            //        OnlineRoutingEngine engine = helper.getEngineByKey(engineKey);
            //        if (engine != null && engine.useRoutingFallback()) {
            //            res = findVectorMapsRoute(params, calcGPXRoute);
            //        }
            //    }
            //}
            else if (params.mode.getRouterService == STRAIGHT || params.mode.getRouterService == DIRECT_TO)
            {
                res = [self findStraightRoute:params];
            }
            else
            {
                res = [[OARouteCalculationResult alloc] initWithErrorMessage:@"Selected route service is not available"];
            }

            if (res)
            {
                NSLog(@"Finding route contained %d points for %.3f s", (int)[res getImmutableAllLocations].count, [[NSDate date] timeIntervalSince1970] - time);
            }

            return res;
        }
        catch (NSException *e)
        {
            NSLog(@"Failed to find route %@", e.reason);
        }
        catch (const std::bad_alloc &e)
        {
            NSLog(@"Failed to find route: %s", e.what());
            return [[OARouteCalculationResult alloc] initWithErrorMessage:kRouteCalculationOutOfMemoryError];
        }
        catch (const std::exception &e)
        {
            NSLog(@"Failed to find route: %s", e.what());
            return [[OARouteCalculationResult alloc] initWithErrorMessage:RouteCalculationErrorMessage(e)];
        }
    }
    return [[OARouteCalculationResult alloc] initWithErrorMessage:nil];
}

- (BOOL)shouldCalculateGpxRouteWithParams:(OARouteCalculationParams *)params
{
    if (params.gpxRoute != nil)
    {
        OAGpxApproximationParams *approximationParams = params.gpxRoute.approximationParams;
        if (approximationParams != nil && ![params.gpxRoute.gpxFile isAttachedToRoads])
        {
            OAGpxApproximationHelper *approximationHelper = [[OAGpxApproximationHelper alloc] initWithLocations:approximationParams.locationsHolders initialAppMode:[[OARoutingHelper sharedInstance] getAppMode] initialThreshold:[[OAAppSettings sharedManager].gpxApproximationDistance get:[[OARoutingHelper sharedInstance] getAppMode]]];
            OASGpxFile *gpx = [approximationHelper approximateGpxSync:params.gpxRoute.gpxFile params:approximationParams];
            if (![gpx error] && [gpx isAttachedToRoads])
                params.gpxRoute = [[[OAGPXRouteParamsBuilder alloc] initWithFile:gpx params:params.gpxRoute] build:params.end];
        }
        
        return params.gpxRoute && (params.gpxRoute.points.count > 0 || (params.gpxRoute.reverse && params.gpxRoute.routePoints.count > 0));
    }
    
    return NO;
}

- (NSArray<OASRouteSegmentResult *> *) checkNearestSegmentOnRecalculate:(OARouteCalculationResult *)previousRoute
                                                              segments:(NSArray<OASRouteSegmentResult *> *)segments
                                                         startLocation:(CLLocation *)startLocation
{
    CGFloat previousDistanceToFinish = [previousRoute getRouteDistanceToFinish:0];
    CGFloat searchDistance = previousDistanceToFinish + NEAREST_POINT_EXTRA_SEARCH_DISTANCE;

    CGFloat minDistance = CGFLOAT_MAX;
    CGFloat checkedDistance = 0;

    NSInteger nearestSegmentIndex = 0;

    for (NSInteger segmentIndex = (NSInteger) segments.count - 1; segmentIndex >= 0 && checkedDistance < searchDistance; segmentIndex--) {
        OASRouteSegmentResult *segment = segments[segmentIndex];
        int step = [segment isForwardDirection] ? -1 : 1;
        int startIndex = [segment getEndPointIndex] + step;
        int endIndex = [segment getStartPointIndex] + step;

        for (int index = startIndex; index != endIndex && checkedDistance < searchDistance; index += step) {
            OASKLatLon *prevRoutePoint = [segment getPointI:index];
            OASKLatLon *nextRoutePoint = [segment getPointI:index - step];
            CLLocation *prevRouteLocation = [[CLLocation alloc] initWithLatitude:prevRoutePoint.latitude longitude:prevRoutePoint.longitude];
            CLLocation *nextRouteLocation = [[CLLocation alloc] initWithLatitude:nextRoutePoint.latitude longitude:nextRoutePoint.longitude];
            CGFloat distance = [OAMapUtils getOrthogonalDistance:startLocation fromLocation:prevRouteLocation toLocation:nextRouteLocation];
            
            if (distance < MIN(minDistance, MIN_DISTANCE_FOR_INSERTING_ROUTE_SEGMENT)) {
                minDistance = distance;
                nearestSegmentIndex = segmentIndex;
            }

            checkedDistance += [prevRouteLocation distanceFromLocation:nextRouteLocation];
        }
    }
    
    return nearestSegmentIndex == 0
        ? segments
        : [segments subarrayWithRange:NSMakeRange(nearestSegmentIndex, segments.count - nearestSegmentIndex)];
}

- (NSInteger) findNearestPointIndexOnRecalculate:(OARouteCalculationResult *)previousRoute
                                  routeLocations:(NSMutableArray<CLLocation *> *)routeLocations
                                   startLocation:(CLLocation *)startLocation
{
    CGFloat prevDistanceToFinish = [previousRoute getRouteDistanceToFinish:0];
    CGFloat searchDistance = prevDistanceToFinish + NEAREST_POINT_EXTRA_SEARCH_DISTANCE;
    CGFloat checkedDistance = 0;
    NSInteger newStartIndex = 0;
    CGFloat minDistance = CGFLOAT_MAX;

    for (NSInteger i = [routeLocations count] - 2; i >= 0 && checkedDistance < searchDistance; i--) {
        const auto& prevRouteLocation = routeLocations[i];
        const auto& nextRouteLocation = routeLocations[i + 1];
        CGFloat distance = [OAMapUtils getOrthogonalDistance:startLocation fromLocation:prevRouteLocation toLocation:nextRouteLocation];
        
        if (distance < MIN(minDistance, MIN_DISTANCE_FOR_INSERTING_ROUTE_SEGMENT)) {
            minDistance = distance;
            newStartIndex = i + 1;
        }

        checkedDistance += [prevRouteLocation distanceFromLocation:nextRouteLocation];
    }

    return newStartIndex;
}

@end
