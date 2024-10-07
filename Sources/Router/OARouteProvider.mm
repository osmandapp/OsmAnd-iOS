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
#import "OARTargetPoint.h"
#import "CLLocation+Extension.h"
#import "OsmAndSharedWrapper.h"
#import "OsmAnd_Maps-Swift.h"

#include <precalculatedRouteDirection.h>
#include <routePlannerFrontEnd.h>
#include <routingConfiguration.h>
#include <routingContext.h>
#include <routeSegmentResult.h>
#include "routeResultPreparation.h"

#define OSMAND_ROUTER @"OsmAndRouter"
#define OSMAND_ROUTER_V2 @"OsmAndRouterV2"
#define MIN_DISTANCE_FOR_INSERTING_ROUTE_SEGMENT 60
#define ADDITIONAL_DISTANCE_FOR_START_POINT 300
#define MIN_STRAIGHT_DIST 50000
#define MIN_INTERMEDIATE_DIST 10
#define NEAREST_POINT_EXTRA_SEARCH_DISTANCE 300

#define GPX_CALC_DIST_THRESHOLD 1000000

@interface OARouteProvider()

+ (NSArray<OARouteDirectionInfo *> *) parseOsmAndGPXRoute:(NSMutableArray<CLLocation *> *)res
                                                  gpxFile:(OASGpxFile *)gpxFile
                                         segmentEndPoints:(NSMutableArray<CLLocation *> *)segmentEndPoints
                                             osmandRouter:(BOOL)osmandRouter
                                                 leftSide:(BOOL)leftSide
                                                 defSpeed:(float)defSpeed
                                          selectedSegment:(NSInteger)selectedSegment;

+ (std::vector<std::shared_ptr<RouteSegmentResult>>) parseOsmAndGPXRoute:(NSMutableArray<CLLocation *> *)points
                                                                 gpxFile:(OASGpxFile *)gpxFile
                                                        segmentEndpoints:(NSMutableArray<CLLocation *> *)segmentEndpoints
                                                         selectedSegment:(NSInteger)selectedSegment;

+ (std::vector<std::shared_ptr<RouteSegmentResult>>) parseOsmAndGPXRoute:(NSMutableArray<CLLocation *> *)points
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
    OASGpxFile *file = builder.file;
    _reverse = builder.reverse;
    self.passWholeRoute = builder.passWholeRoute;
    self.useIntermediatePointsRTE = builder.useIntermediatePointsRTE;
    self.connectPointsStraightly = builder.connectPointsStraightly;
    builder.calculateOsmAndRoute = NO; // Disabled temporary builder.calculateOsmAndRoute;
    if (file.getAllPoints.count > 0)
    {
        self.wpt = [NSArray arrayWithArray:file.getAllPoints];
    }
    NSInteger selectedSegment = builder.selectedSegment;
    if ([OSMAND_ROUTER_V2 isEqualToString:file.author])
    {
        NSMutableArray<CLLocation *> *points = [NSMutableArray arrayWithArray:_points];
        NSMutableArray<CLLocation *> *endPoints = [NSMutableArray arrayWithArray:_segmentEndPoints];
        _route = [OARouteProvider parseOsmAndGPXRoute:points gpxFile:file segmentEndpoints:endPoints selectedSegment:selectedSegment leftSide:builder.leftSide];
        _points = points;
        _segmentEndPoints = endPoints;
        
        if (selectedSegment == -1)
            _routePoints = [file getRoutePoints];
        else
            _routePoints = [file getRoutePointsRouteIndex:(int)selectedSegment];
        
        if (_reverse)
        {
            _points = [[points reverseObjectEnumerator] allObjects];
            _routePoints = [[_routePoints reverseObjectEnumerator] allObjects];
            _segmentEndPoints = [[_segmentEndPoints reverseObjectEnumerator] allObjects];
        }
        _addMissingTurns = _route.empty();
    }
    else if ([file isCloudmadeRouteFile] || [OSMAND_ROUTER isEqualToString:file.author])
    {
        NSMutableArray<CLLocation *> *points = [NSMutableArray arrayWithArray:self.points];
        NSMutableArray<CLLocation *> *endPoints = [NSMutableArray arrayWithArray:self.segmentEndPoints];
        self.directions = [OARouteProvider parseOsmAndGPXRoute:points gpxFile:file segmentEndPoints:endPoints osmandRouter:[OSMAND_ROUTER isEqualToString:file.author] leftSide:builder.leftSide defSpeed:10 selectedSegment:selectedSegment];
        self.points = [NSArray arrayWithArray:points];
        _segmentEndPoints = endPoints;
        if ([OSMAND_ROUTER isEqualToString:file.author])
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
            [OARouteProvider collectSegmentPointsFromGpx:file points:points segmentEndPoints:endPoints selectedSegment:selectedSegment];
            self.points = points;
            _segmentEndPoints = endPoints;
        }
        if (points.count == 0)
        {
            for (OASRoute *rte in file.routes)
            {
                for (OASWptPt *pt in rte.points)
                {
                   // FIXME: pt.verticalDilutionOfPrecision
//                    CLLocation *loc = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(pt.position.latitude, pt.position.longitude) altitude:pt.ele horizontalAccuracy:pt.hdop verticalAccuracy:pt.verticalDilutionOfPrecision course:0 speed:pt.speed timestamp:[NSDate dateWithTimeIntervalSince1970:pt.time]];
//                    
//                    [points addObject:loc];
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

@end


@implementation OARouteProvider
{
    NSMutableSet<NSString *> *_nativeFiles;
    MissingMapsCalculator *_missingMapsCalculator;
    NSObject *_nativeRoutingLock;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _nativeFiles = [NSMutableSet set];
        _nativeRoutingLock = [[NSObject alloc] init];
        [OsmAndApp instance].resourcesManager->localResourcesChangeObservable.attach(reinterpret_cast<OsmAnd::IObservable::Tag>((__bridge const void*)self),
            [self]
            (const OsmAnd::ResourcesManager* const resourcesManager,
            const QList< QString >& added,
            const QList< QString >& removed,
            const QList< QString >& updated)
            {
                [self onLocalResourcesChanged];
            });
    }
    return self;
}

- (void) onLocalResourcesChanged
{
    @synchronized(self)
    {
        _nativeFiles = [NSMutableSet set];
    }
}

+ (NSString *)getExtensionValue:(NSDictionary<NSString *, NSString *> *)dic key:(NSString *)key
{
    return [dic objectForKey:key];;

}

+ (std::vector<std::shared_ptr<RouteSegmentResult>>) parseOsmAndGPXRoute:(NSMutableArray<CLLocation *> *)points
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

+ (std::vector<std::shared_ptr<RouteSegmentResult>>) parseOsmAndGPXRoute:(NSMutableArray<CLLocation *> *)points
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
    CLLocation *loc = [[CLLocation alloc] initWithCoordinate:pt.position altitude:isnan(pt.ele) ? 0. : pt.ele horizontalAccuracy:isnan(pt.hdop) ? 0. : pt.hdop verticalAccuracy:0. course:0. speed:pt.speed timestamp:[NSDate dateWithTimeIntervalSince1970:pt.time]];
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
        for (OASWptPt *pt in gpxFile.getAllPoints)
        {
            // FIXME: pt.verticalDilutionOfPrecision
//            CLLocation *loc = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(pt.position.latitude, pt.position.longitude) altitude:pt.ele horizontalAccuracy:pt.hdop verticalAccuracy:pt.verticalDilutionOfPrecision course:0 speed:pt.speed timestamp:[NSDate dateWithTimeIntervalSince1970:pt.time]];
            
 //           [res addObject:loc];
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
                std::shared_ptr<TurnType> turnType = nullptr;
                if (stype)
                    turnType = std::make_shared<TurnType>(TurnType::fromString([[stype uppercaseString] UTF8String], leftSide));
                else
                    turnType = TurnType::ptrStraight();
                
                NSString *sturn = [OARouteProvider getExtensionValue:item.extensions key:@"turn-angle"];
                if (sturn)
                    turnType->setTurnAngle([sturn floatValue]);
                
                NSString *slanes = [OARouteProvider getExtensionValue:item.extensions key:@"lanes"];
                if (slanes)
                {
                    turnType->setLanes([self stringToIntVector:slanes]);
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
                
                if (previous && TurnType::C != previous.turnType->getValue() && !osmandRouter)
                {
                    // calculate angle
                    if (previous.routePointOffset > 0)
                    {
                        double bearing = [res[previous.routePointOffset - 1] bearingTo:res[previous.routePointOffset]];
                        float paz = bearing;
                        float caz;
                        if (previous.turnType->isRoundAbout() && dirInfo.routePointOffset < (int) res.count - 1)
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
                        
                        if (previous.turnType->getTurnAngle() < 0.5f) {
                            previous.turnType->setTurnAngle(angle);
                        }
                    }
                }
                
                [directions addObject:dirInfo];
                
                previous = dirInfo;
            } catch (NSException *e) {
            }
        }
    }
    
    if (previous && TurnType::C != previous.turnType->getValue())
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
            
            if (previous.turnType->getTurnAngle() < 0.5f)
                previous.turnType->setTurnAngle(angle);
        }
    }
    return directions;
}

+ (std::vector<int>) stringToIntVector:(NSString *)str
{
    vector<int> res;
    NSArray<NSString *> *components = [str componentsSeparatedByString:@","];
    for (NSString *component in components)
        res.push_back(component.intValue);
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
        if (key == GeneralRouterConstants::USE_SHORTEST_WAY)
        {
            BOOL b = ![settings.fastRouteMode get:params.mode];
            vl = b ? "true" : "";
        }
        else if (pr.type == RoutingParameterType::BOOLEAN)
        {
            OACommonBoolean *pref = [settings getCustomRoutingBooleanProperty:[NSString stringWithUTF8String:key.c_str()] defaultValue:pr.defaultBoolean];
            BOOL b = [pref get:params.mode];
            vl = b ? "true" : "";
        }
        else
        {
            vl = [[[settings getCustomRoutingProperty:[NSString stringWithUTF8String:key.c_str()] defaultValue:@""] get:params.mode] UTF8String];
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

        for (const auto* file : getOpenMapFiles())
        {
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

        if (router->CALCULATE_MISSING_MAPS)
        {
            if (!_missingMapsCalculator)
            {
                _missingMapsCalculator = [MissingMapsCalculator new];
            }
            NSArray<CLLocation *> *targets = (inters.count > 0) ? [inters arrayByAddingObject:en] : @[en];
            if ([_missingMapsCalculator checkIfThereAreMissingMaps:ctx start:st targets:targets checkHHEditions:!oldRouting])
            {
                OARouteCalculationResult *r = [[OARouteCalculationResult alloc] initWithErrorMessage:[_missingMapsCalculator getErrorMessage]];
                r.missingMaps = _missingMapsCalculator.missingMaps;
                r.mapsToUpdate = _missingMapsCalculator.mapsToUpdate;
                r.potentiallyUsedMaps = _missingMapsCalculator.potentiallyUsedMaps;
                [_missingMapsCalculator clearResult];
                return r;
            }
        }
    
        if (complexCtx)
        {
            try
            {
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
                result = router->searchRoute(ctx, startX, startY, endX, endY, intX, intY);
            }
        }
        else
        {
            result = router->searchRoute(ctx, startX, startY, endX, endY, intX, intY);
        }
        
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
                return [self interrupted];
            
            // something really strange better to see that message on the scren
            return [self emptyResult];
        }
        else
        {
            float routingTime = 0;
            if (ctx->progress)
                routingTime = ctx->progress->routingCalculatedTime;
            
            return [[OARouteCalculationResult alloc] initWithSegmentResults:result start:params.start end:params.end intermediates:params.intermediates leftSide:params.leftSide routingTime:routingTime waypoints:!params.gpxRoute ? nil : params.gpxRoute.wpt mode:params.mode calculateFirstAndLastPoint:YES initialCalculation:params.initialCalculation];
        }
    }
    catch (NSException *e)
    {
        return [[OARouteCalculationResult alloc] initWithErrorMessage:e.reason];
    }
}

- (OARoutingEnvironment *) getRoutingEnvironment:(OAApplicationMode *)mode start:(CLLocation *)start end:(CLLocation *)end
{
	OARouteCalculationParams *params = [[OARouteCalculationParams alloc] init];
	params.mode = mode;
	params.start = start;
	params.end = end;
	return [self calculateRoutingEnvironment:params calcGPXRoute:NO skipComplex:YES];
}

- (std::vector<SHARED_PTR<GpxPoint>>) generateGpxPoints:(OARoutingEnvironment *)env gctx:(SHARED_PTR<GpxRouteApproximation>)gctx locationsHolder:(OALocationsHolder *)locationsHolder
{
    return env.router->generateGpxPoints(gctx, locationsHolder.getLatLonList);
}

- (SHARED_PTR<GpxRouteApproximation>) calculateGpxApproximation:(OARoutingEnvironment *)env
                                                           gctx:(SHARED_PTR<GpxRouteApproximation>)gctx
                                                         points:(std::vector<SHARED_PTR<GpxPoint>> &)points
                                                  resultMatcher:(OAResultMatcher<OAGpxRouteApproximation *> *)resultMatcher
{
    @synchronized (_nativeRoutingLock) {
        const auto resultAcceptor =
        [resultMatcher]
        (SHARED_PTR<GpxRouteApproximation> approximation) -> bool
        {
            OAGpxRouteApproximation *approx = [[OAGpxRouteApproximation alloc] initWithApproximation:approximation];
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
    int leftX = get31TileNumberX(params.start.coordinate.longitude);
    int rightX = leftX;
    int bottomY = get31TileNumberY(params.start.coordinate.latitude);
    int topY = bottomY;
    if (params.intermediates)
    {
        for (CLLocation *l in params.intermediates)
        {
            leftX = MIN(get31TileNumberX(l.coordinate.longitude), leftX);
            rightX = MAX(get31TileNumberX(l.coordinate.longitude), rightX);
            bottomY = MAX(get31TileNumberY(l.coordinate.latitude), bottomY);
            topY = MIN(get31TileNumberY(l.coordinate.latitude), topY);
        }
    }
    CLLocation *l = params.end;
    leftX = MIN(get31TileNumberX(l.coordinate.longitude), leftX);
    rightX = MAX(get31TileNumberX(l.coordinate.longitude), rightX);
    bottomY = MAX(get31TileNumberY(l.coordinate.latitude), bottomY);
    topY = MIN(get31TileNumberY(l.coordinate.latitude), topY);
    
    [self checkInitialized:15 leftX:leftX rightX:rightX bottomY:bottomY topY:topY];
    
    auto ctx = router->buildRoutingContext(cf, RouteCalculationMode::NORMAL);
    
    std:shared_ptr<RoutingContext> complexCtx = nullptr;
    BOOL complex = !skipComplex && [params.mode isDerivedRoutingFrom:[OAApplicationMode CAR]] && !settings.disableComplexRouting && !precalculated;
    ctx->leftSideNavigation = params.leftSide;
    ctx->progress = params.calculationProgress;
    ctx->setConditionalTime(cf->routeCalculationTime);
    if (params.previousToRecalculate && params.onlyStartPointChanged)
    {
        int currentRoute = params.previousToRecalculate.currentRoute;
        const auto& originalRoute = [params.previousToRecalculate getOriginalRoute];
        if (currentRoute < originalRoute.size())
        {
            std::vector<std::shared_ptr<RouteSegmentResult>> prevCalcRoute(originalRoute.begin() + currentRoute, originalRoute.end());
            ctx->previouslyCalculatedRoute = prevCalcRoute;
        }
    }
    
    if (complex && router->getRecalculationEnd(ctx.get()))
        complex = false;
    
    if (complex)
    {
        complexCtx = router->buildRoutingContext(cf, RouteCalculationMode::COMPLEX);
        complexCtx->progress = params.calculationProgress;
        complexCtx->leftSideNavigation = params.leftSide;
        complexCtx->previouslyCalculatedRoute = ctx->previouslyCalculatedRoute;
        complexCtx->setConditionalTime(cf->routeCalculationTime);
    }
    
    return [[OARoutingEnvironment alloc] initWithRouter:router context:ctx complextCtx:complexCtx precalculated:precalculated];
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
        OARoutingEnvironment *env = [self calculateRoutingEnvironment:params calcGPXRoute:calcGPXRoute skipComplex:NO];

        if (!env)
            return [self applicationModeNotSupported:params];

        CLLocation *start = [[CLLocation alloc] initWithLatitude:params.start.coordinate.latitude longitude:params.start.coordinate.longitude];
        CLLocation *end = [[CLLocation alloc] initWithLatitude:params.end.coordinate.latitude longitude:params.end.coordinate.longitude];
        NSArray<CLLocation *> *inters = [NSArray new];

        if (params.intermediates)
            inters = [NSArray arrayWithArray:params.intermediates];

        OARouteCalculationResult *result = [self calcOfflineRouteImpl:params router:env.router ctx:env.ctx complexCtx:env.complexCtx st:start en:end inters:inters precalculated:env.precalculated];
        NSMutableArray<CLLocation *> *points = [NSMutableArray array];
        [points addObject:start];
        [points addObjectsFromArray:inters];
        [points addObject:end];
        [result setMissingMaps:result.missingMaps
                  mapsToUpdate:result.mapsToUpdate
                      usedMaps:result.potentiallyUsedMaps
                           ctx:env.ctx
                        points:points];

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
    
    return [self findVectorMapsRoute:rp calcGPXRoute:NO];
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
                OARouteDirectionInfo *previousInfo = [[OARouteDirectionInfo alloc] initWithAverageSpeed:speed turnType:TurnType::ptrStraight()];
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

+ (std::vector<std::pair<double, double>>) coordsToLocations:(NSArray<CLLocation *> *)points
{
    std::vector<std::pair<double, double>> res;
    for (CLLocation *pt in points)
    {
        res.push_back({pt.coordinate.latitude, pt.coordinate.longitude});
    }
    return res;
}

- (OARouteCalculationResult *) calculateGpxRoute:(OARouteCalculationParams *)routeParams
{
    OAGPXRouteParams *gpxParams = routeParams.gpxRoute;
    BOOL calcWholeRoute = gpxParams.passWholeRoute && (routeParams.previousToRecalculate == nil || !routeParams.onlyStartPointChanged);
    BOOL calculateOsmAndRouteParts = gpxParams.calculateOsmAndRouteParts;
    BOOL reverseRoutePoints = gpxParams.reverse && gpxParams.routePoints.count > 1;
    auto gpxRouteResult = routeParams.gpxRoute.route;
    if (reverseRoutePoints)
    {
        NSMutableArray<CLLocation *> *gpxRouteLocations = [NSMutableArray new];
        std::vector<std::shared_ptr<RouteSegmentResult>> gpxRoute;
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
            NSArray<CLLocation *> *locations = result.getRouteLocations;
            auto route = result.getOriginalRoute;
            if (route.size() == 0)
            {
                if (locations.count == 0)
                {
                    CLLocation *endLoc = [[CLLocation alloc] initWithLatitude:end.coordinate.latitude longitude:end.coordinate.longitude];
                    locations = @[start, endLoc];
                }
                route = { RoutePlannerFrontEnd::generateStraightLineSegment(routeParams.mode.getDefaultSpeed, [self.class coordsToLocations:locations]) };
            }
            [gpxRouteLocations addObjectsFromArray:locations];
            if (gpxRouteLocations.count > 0)
                [gpxRouteLocations removeLastObject];
            
            gpxRoute.insert(gpxRoute.end(), route.begin(), route.end());
            
            start = [[CLLocation alloc] initWithLatitude:end.coordinate.latitude longitude:end.coordinate.longitude];
        }
        gpxParams.points = gpxRouteLocations;
        gpxParams.route = gpxRoute;
        gpxRouteResult = gpxRoute;
    }
    
    if (gpxRouteResult.size() > 0)
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
        
        std::vector<std::shared_ptr<RouteSegmentResult>> firstSegmentRoute;
        std::vector<std::shared_ptr<RouteSegmentResult>> lastSegmentRoute;
        std::vector<std::shared_ptr<RouteSegmentResult>> gpxRoute;
        
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
                if (gpxRoute.size() > 0)
                {
                    LatLon startPoint = gpxRoute[0]->getStartPoint();
                    nearestGpxLocation = [[CLLocation alloc] initWithLatitude:startPoint.lat longitude:startPoint.lon];
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
        std::vector<std::shared_ptr<RouteSegmentResult>> newGpxRoute;
        if (firstSegmentRoute.size() > 0)
        {
            newGpxRoute.insert(newGpxRoute.end(), firstSegmentRoute.begin(), firstSegmentRoute.end());
        }
        newGpxRoute.insert(newGpxRoute.end(), gpxRoute.begin(), gpxRoute.end());
        if (lastSegmentRoute.size() > 0)
        {
            newGpxRoute.insert(newGpxRoute.end(), lastSegmentRoute.begin(), lastSegmentRoute.end());
        }
        
        if ([routeParams recheckRouteNearestPoint])
        {
            newGpxRoute = [self checkNearestSegmentOnRecalculate:routeParams.previousToRecalculate segments:newGpxRoute startLocation:routeParams.start];
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
            gpxRoute = [NSMutableArray arrayWithArray:[gpxRoute subarrayWithRange:NSMakeRange(index, gpxRoute.count)]];
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

- (void) calculateGpxRouteTimeSpeed:(OARouteCalculationParams *)params gpxRouteResult:(std::vector<std::shared_ptr<RouteSegmentResult>>)gpxRouteResult
{
    OARoutingEnvironment *env = [self calculateRoutingEnvironment:params calcGPXRoute:NO skipComplex:YES];
    if (env)
    {
        calculateTimeSpeed(env.ctx.get(), gpxRouteResult);
    }
}

- (std::vector<std::shared_ptr<RouteSegmentResult>>) findRouteWithIntermediateSegments:(OARouteCalculationParams *)routeParams result:(OARouteCalculationResult *)result gpxRouteLocations:(NSArray<CLLocation *> *)gpxRouteLocations segmentEndpoints:(NSArray<CLLocation *> *)segmentEndpoints nearestGpxPointInd:(NSInteger)nearestGpxPointInd
{
    std::vector<std::shared_ptr<RouteSegmentResult>> newGpxRoute;
    
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
            const auto& origRoute = [result getOriginalRoute:(int)lastIndex endIndex:(int)indexPrev includeFirstSegment:YES];
            if (origRoute.size() > 0)
                newGpxRoute.insert(newGpxRoute.end(), origRoute.begin(), origRoute.end());
            lastIndex = indexNew;
            
            CLLocation *end = [[CLLocation alloc] initWithLatitude:newSegmentPoint.coordinate.latitude longitude:newSegmentPoint.coordinate.longitude];
            OARouteCalculationResult *newRes = [self findOfflineRouteSegment:routeParams start:prevSegmentPoint end:end];
            const auto& segmentResults = newRes.getOriginalRoute;
            if (segmentResults.size() > 0)
                newGpxRoute.insert(newGpxRoute.end(), segmentResults.begin(), segmentResults.end());
        }
    }
    const auto& origRoute = [result getOriginalRoute:(int)lastIndex];
    if (origRoute.size() > 0)
        newGpxRoute.insert(newGpxRoute.end(), origRoute.begin(), origRoute.end());
    
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
        NSMutableArray<OARouteDirectionInfo *> *directions = [self calcDirections:startI[0] endI:endI[0] inputDirections:[rcr getRouteDirections]];;
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
            BOOL calcGPXRoute = params.gpxRoute && (params.gpxRoute.points.count > 0 || (params.gpxRoute.reverse && params.gpxRoute.routePoints.count > 0));
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
    }
    return [[OARouteCalculationResult alloc] initWithErrorMessage:nil];
}

- (std::vector<std::shared_ptr<RouteSegmentResult>>) checkNearestSegmentOnRecalculate:(OARouteCalculationResult *)previousRoute
                                                                             segments:(std::vector<std::shared_ptr<RouteSegmentResult>>)segments
                                                                        startLocation:(CLLocation *)startLocation
{
    CGFloat previousDistanceToFinish = [previousRoute getRouteDistanceToFinish:0];
    CGFloat searchDistance = previousDistanceToFinish + NEAREST_POINT_EXTRA_SEARCH_DISTANCE;

    CGFloat minDistance = CGFLOAT_MAX;
    CGFloat checkedDistance = 0;

    NSInteger nearestSegmentIndex = 0;

    for (NSInteger segmentIndex = segments.size() - 1; segmentIndex >= 0 && checkedDistance < searchDistance; segmentIndex--) {
        const auto& segment = segments[segmentIndex];
        int step = segment->isForwardDirection() ? -1 : 1;
        int startIndex = segment->getEndPointIndex() + step;
        int endIndex = segment->getStartPointIndex() + step;

        for (int index = startIndex; index != endIndex && checkedDistance < searchDistance; index += step) {
            LatLon prevRoutePoint = segment->getPoint(index);
            LatLon nextRoutePoint = segment->getPoint(index - step);
            CLLocation *prevRouteLocation = [[CLLocation alloc] initWithLatitude:prevRoutePoint.lat longitude:prevRoutePoint.lon];
            CLLocation *nextRouteLocation = [[CLLocation alloc] initWithLatitude:nextRoutePoint.lat longitude:nextRoutePoint.lon];
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
        : std::vector<std::shared_ptr<RouteSegmentResult>>(segments.cbegin() + (int) nearestSegmentIndex, segments.cend());
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
