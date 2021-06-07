//
//  OARouteProvider.m
//  OsmAnd
//
//  Created by Alexey Kulish on 27/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARouteProvider.h"
#import "OAGPXDocument.h"
#import "OAGPXDocumentPrimitives.h"
#import "OARouteDirectionInfo.h"
#import "OsmAndApp.h"
#import "OAApplicationMode.h"
#import "OARouteImporter.h"
#import "OARouteCalculationResult.h"
#import "OARouteCalculationParams.h"
#import "QuadRect.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OAMapUtils.h"

#include <precalculatedRouteDirection.h>
#include <routePlannerFrontEnd.h>
#include <routingConfiguration.h>
#include <routingContext.h>
#include <routeSegmentResult.h>

#define OSMAND_ROUTER @"OsmAndRouter"
#define OSMAND_ROUTER_V2 @"OsmAndRouterV2"
#define MIN_DISTANCE_FOR_INSERTING_ROUTE_SEGMENT 60
#define ADDITIONAL_DISTANCE_FOR_START_POINT 300
#define MIN_STRAIGHT_DIST 50000

@interface OARouteProvider()

+ (NSArray<OARouteDirectionInfo *> *) parseOsmAndGPXRoute:(NSMutableArray<CLLocation *> *)res
                                                  gpxFile:(OAGPXDocument *)gpxFile
                                         segmentEndPoints:(NSMutableArray<CLLocation *> *)segmentEndPoints
                                             osmandRouter:(BOOL)osmandRouter
                                                 leftSide:(BOOL)leftSide
                                                 defSpeed:(float)defSpeed
                                          selectedSegment:(NSInteger)selectedSegment;

+ (std::vector<std::shared_ptr<RouteSegmentResult>>) parseOsmAndGPXRoute:(NSMutableArray<CLLocation *> *)points
                                                                 gpxFile:(OAGPXDocument *)gpxFile
                                                        segmentEndpoints:(NSMutableArray<CLLocation *> *)segmentEndpoints
                                                         selectedSegment:(NSInteger)selectedSegment;

+ (void) collectSegmentPointsFromGpx:(OAGPXDocument *)gpxFile points:(NSMutableArray<CLLocation *> *)points
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
    OAGPXDocument *file = builder.file;
    _reverse = builder.reverse;
    self.passWholeRoute = builder.passWholeRoute;
    self.calculateOsmAndRouteParts = builder.calculateOsmAndRouteParts;
    self.useIntermediatePointsRTE = builder.useIntermediatePointsRTE;
    builder.calculateOsmAndRoute = NO; // Disabled temporary builder.calculateOsmAndRoute;
    if (file.locationMarks.count > 0)
    {
        self.wpt = [NSArray arrayWithArray:file.locationMarks];
    }
    NSInteger selectedSegment = builder.selectedSegment;
    if ([OSMAND_ROUTER_V2 isEqualToString:file.creator])
    {
        NSMutableArray<CLLocation *> *points = [NSMutableArray arrayWithArray:_points];
        NSMutableArray<CLLocation *> *endPoints = [NSMutableArray arrayWithArray:_segmentEndPoints];
        _route = [OARouteProvider parseOsmAndGPXRoute:points gpxFile:file segmentEndpoints:endPoints selectedSegment:selectedSegment];
        _points = points;
        _segmentEndPoints = endPoints;
        
        if (selectedSegment == -1)
            _routePoints = [file getRoutePoints];
        else
            _routePoints = [file getRoutePoints:selectedSegment];
        
        if (_reverse)
        {
            _points = [[points reverseObjectEnumerator] allObjects];
            _routePoints = [[_routePoints reverseObjectEnumerator] allObjects];
            _segmentEndPoints = [[_segmentEndPoints reverseObjectEnumerator] allObjects];
        }
        _addMissingTurns = _route.empty();
    }
    else if ([file isCloudmadeRouteFile] || [OSMAND_ROUTER isEqualToString:file.creator])
    {
        NSMutableArray<CLLocation *> *points = [NSMutableArray arrayWithArray:self.points];
        NSMutableArray<CLLocation *> *endPoints = [NSMutableArray arrayWithArray:self.segmentEndPoints];
        self.directions = [OARouteProvider parseOsmAndGPXRoute:points gpxFile:file segmentEndPoints:endPoints osmandRouter:[OSMAND_ROUTER isEqualToString:file.creator] leftSide:builder.leftSide defSpeed:10 selectedSegment:selectedSegment];
        self.points = [NSArray arrayWithArray:points];
        _segmentEndPoints = endPoints;
        if ([OSMAND_ROUTER isEqualToString:file.creator])
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
            for (OAGpxRte *rte in file.routes)
            {
                for (OAGpxRtePt *pt in rte.points)
                {
                    CLLocation *loc = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(pt.position.latitude, pt.position.longitude) altitude:pt.elevation horizontalAccuracy:pt.horizontalDilutionOfPrecision verticalAccuracy:pt.verticalDilutionOfPrecision course:0 speed:pt.speed timestamp:[NSDate dateWithTimeIntervalSince1970:pt.time]];
                    
                    [points addObject:loc];
                }
            }
        }
        if (_reverse)
        {
            self.points = [[points reverseObjectEnumerator] allObjects];
            _segmentEndPoints = [[_segmentEndPoints reverseObjectEnumerator] allObjects];
        }
    }
    return self;
}

@end

@interface OAGPXRouteParamsBuilder()

@end

@implementation OAGPXRouteParamsBuilder

- (instancetype)initWithDoc:(OAGPXDocument *)document
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
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _nativeFiles = [NSMutableSet set];
    }
    return self;
}

+ (NSString *) getExtensionValue:(OAGpxExtensions *)exts key:(NSString *)key
{
    for (OAGpxExtension *e in exts.extensions) {
        if ([e.name isEqualToString:key]) {
            return e.value;
        }
    }
    return nil;
}

+ (std::vector<std::shared_ptr<RouteSegmentResult>>) parseOsmAndGPXRoute:(NSMutableArray<CLLocation *> *)points
                                                                 gpxFile:(OAGPXDocument *)gpxFile
                                                        segmentEndpoints:(NSMutableArray<CLLocation *> *)segmentEndpoints
                                                         selectedSegment:(NSInteger)selectedSegment
{
    NSArray<OAGpxTrkSeg *> *segments = [gpxFile getNonEmptyTrkSegments:NO];
    if (selectedSegment != -1 && segments.count > selectedSegment)
    {
        OAGpxTrkSeg *segment = segments[selectedSegment];
        for (OAGpxTrkPt *p in segment.points)
        {
            [points addObject:[self createLocation:p]];
        }
        OARouteImporter *routeImporter = [[OARouteImporter alloc] initWithTrkSeg:segment];
        return [routeImporter importRoute];
    }
    else
    {
        [self collectPointsFromSegments:segments points:points segmentEndpoints:segmentEndpoints];
        OARouteImporter *routeImporter = [[OARouteImporter alloc] initWithGpxFile:gpxFile];
        return [routeImporter importRoute];
    }
}

+ (void) collectSegmentPointsFromGpx:(OAGPXDocument *)gpxFile points:(NSMutableArray<CLLocation *> *)points
                    segmentEndPoints:(NSMutableArray<CLLocation *> *)segmentEndPoints
                     selectedSegment:(NSInteger)selectedSegment
{
    NSArray<OAGpxTrkSeg *> *segments = [gpxFile getNonEmptyTrkSegments:NO];
    if (selectedSegment != -1 && segments.count > selectedSegment)
    {
        OAGpxTrkSeg *segment = segments[selectedSegment];
        for (OAGpxTrkPt *wptPt in segment.points)
        {
            [points addObject:[self createLocation:wptPt]];
        }
    }
    else
    {
        [self collectPointsFromSegments:segments points:points segmentEndpoints:segmentEndPoints];
    }
}

+ (void) collectPointsFromSegments:(NSArray<OAGpxTrkSeg *> *)segments points:(NSMutableArray<CLLocation *> *)points segmentEndpoints:(NSMutableArray<CLLocation *> *)segmentEndpoints
{
    CLLocation *lastPoint = nil;
    for (NSInteger i = 0; i < segments.count; i++)
    {
        OAGpxTrkSeg *segment = segments[i];
        for (OAGpxTrkPt *wptPt in segment.points)
        {
            [points addObject:[self createLocation:wptPt]];
        }
        if (i <= segments.count - 1 && lastPoint != nil) {
            [segmentEndpoints addObject:lastPoint];
            [segmentEndpoints addObject:points[points.count - segment.points.count]];
        }
        lastPoint = points.lastObject;
    }
}

+ (CLLocation *) createLocation:(OAGpxTrkPt *)pt
{
    CLLocation *loc = [[CLLocation alloc] initWithCoordinate:pt.position altitude:isnan(pt.elevation) ? 0. : pt.elevation horizontalAccuracy:isnan(pt.horizontalDilutionOfPrecision) ? 0. : pt.horizontalDilutionOfPrecision verticalAccuracy:0. course:0. speed:pt.speed timestamp:[NSDate dateWithTimeIntervalSince1970:pt.time]];
    return loc;
}

+ (NSArray<OARouteDirectionInfo *> *) parseOsmAndGPXRoute:(NSMutableArray<CLLocation *> *)res gpxFile:(OAGPXDocument *)gpxFile segmentEndPoints:(NSMutableArray<CLLocation *> *)segmentEndPoints osmandRouter:(BOOL)osmandRouter leftSide:(BOOL)leftSide defSpeed:(float)defSpeed selectedSegment:(NSInteger)selectedSegment
{
    NSMutableArray<OARouteDirectionInfo *> *directions = nil;
    if (!osmandRouter)
    {
        for (OAGpxWpt *pt in gpxFile.locationMarks)
        {
            CLLocation *loc = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(pt.position.latitude, pt.position.longitude) altitude:pt.elevation horizontalAccuracy:pt.horizontalDilutionOfPrecision verticalAccuracy:pt.verticalDilutionOfPrecision course:0 speed:pt.speed timestamp:[NSDate dateWithTimeIntervalSince1970:pt.time]];
            
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
    
    OARoute *route = nil;
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
            OAGpxRtePt *item = route.points[i];
            try
            {
                OAGpxExtensions *exts = (OAGpxExtensions *)item.extraData;
                
                NSString *stime = [OARouteProvider getExtensionValue:exts key:@"time"];
                int time  = 0;
                if (stime)
                    time = [stime intValue];
                
                int offset = [[OARouteProvider getExtensionValue:exts key:@"offset"] intValue];
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
                if (i == route.points.count - 1 && time > 0)
                {
                    if (distanceToEnd.count > offset)
                        avgSpeed = distanceToEnd[offset].floatValue / time;
                    else
                        avgSpeed = defSpeed;
                }
                
                NSString *stype = [OARouteProvider getExtensionValue:exts key:@"turn"];
                std::shared_ptr<TurnType> turnType = nullptr;
                if (stype)
                    turnType = std::make_shared<TurnType>(TurnType::fromString([[stype uppercaseString] UTF8String], leftSide));
                else
                    turnType = TurnType::ptrStraight();
                
                NSString *sturn = [OARouteProvider getExtensionValue:exts key:@"turn-angle"];
                if (sturn)
                    turnType->setTurnAngle([sturn floatValue]);
                
                NSString *slanes = [OARouteProvider getExtensionValue:exts key:@"lanes"];
                if (slanes)
                {
                    turnType->setLanes([self stringToIntVector:slanes]);
                }
                
                OARouteDirectionInfo *dirInfo = [[OARouteDirectionInfo alloc] initWithAverageSpeed:avgSpeed turnType:turnType];
                [dirInfo setDescriptionRoute:item.desc];
                dirInfo.routePointOffset = offset;
                
                // Issue #2894
                NSString *sref = [OARouteProvider getExtensionValue:exts key:@"ref"];
                if (sref && ![@"null" isEqualToString:sref])
                    dirInfo.ref = sref;

                NSString *sstreetname = [OARouteProvider getExtensionValue:exts key:@"street-name"];
                if (sstreetname && ![@"null" isEqualToString:sstreetname])
                    dirInfo.streetName = sstreetname;
                
                NSString *sdest = [OARouteProvider getExtensionValue:exts key:@"dest"];
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
                        if (previous.turnType->isRoundAbout() && dirInfo.routePointOffset < res.count - 1)
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
        if (previous.routePointOffset > 0 && previous.routePointOffset < res.count - 1)
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
    MAP_STR_STR paramsR;
    auto& routerParams = generalRouter->getParameters();
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
    // make visible
    long memoryLimit = (0.1 * ([NSProcessInfo processInfo].physicalMemory / mb)); // TODO
    long memoryTotal = (long) ([NSProcessInfo processInfo].physicalMemory / mb);
    NSLog(@"Use %ld MB of %ld", memoryLimit, memoryTotal);
    
    auto cf = config->build(params.mode.getRoutingProfile.UTF8String, params.start.course >= 0.0 ? params.start.course / 180.0 * M_PI : -360, memoryLimit, paramsR);
    if ([OAAppSettings.sharedManager.enableTimeConditionalRouting get:params.mode])
    {
        cf->routeCalculationTime = [[NSDate date] timeIntervalSince1970] * 1000;
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

- (BOOL) containsData:(NSString *)localResourceId rect:(QuadRect *)rect desiredDataTypes:(OsmAnd::ObfDataTypesMask)desiredDataTypes zoomLevel:(OsmAnd::ZoomLevel)zoomLevel
{
    OsmAndAppInstance app = [OsmAndApp instance];
    const auto& localResource = app.resourcesManager->getLocalResource(QString::fromNSString([localResourceId lastPathComponent]));
    if (localResource)
    {
        const auto& obfMetadata = std::static_pointer_cast<const OsmAnd::ResourcesManager::ObfMetadata>(localResource->metadata);
        if (obfMetadata)
        {
            OsmAnd::AreaI pBbox31 = OsmAnd::AreaI((int)rect.top, (int)rect.left, (int)rect.bottom, (int)rect.right);
            if (zoomLevel == OsmAnd::InvalidZoomLevel)
                return obfMetadata->obfFile->obfInfo->containsDataFor(&pBbox31, OsmAnd::MinZoomLevel, OsmAnd::MaxZoomLevel, desiredDataTypes);
            else
                return obfMetadata->obfFile->obfInfo->containsDataFor(&pBbox31, zoomLevel, zoomLevel, desiredDataTypes);
        }
    }
    return NO;
}

- (void) checkInitialized:(int)zoom leftX:(int)leftX rightX:(int)rightX bottomY:(int)bottomY topY:(int)topY
{
    OsmAndAppInstance app = [OsmAndApp instance];
    BOOL useOsmLiveForRouting = [OAAppSettings sharedManager].useOsmLiveForRouting;
    const auto& localResources = app.resourcesManager->getSortedLocalResources();
    QuadRect *rect = [[QuadRect alloc] initWithLeft:leftX top:topY right:rightX bottom:bottomY];
    auto dataTypes = OsmAnd::ObfDataTypesMask();
    dataTypes.set(OsmAnd::ObfDataType::Map);
    dataTypes.set(OsmAnd::ObfDataType::Routing);
    for (const auto& resource : localResources)
    {
        if (resource->origin == OsmAnd::ResourcesManager::ResourceOrigin::Installed)
        {
            NSString *localPath = resource->localPath.toNSString();
            if (![_nativeFiles containsObject:localPath] && [self containsData:localPath rect:rect desiredDataTypes:dataTypes zoomLevel:(OsmAnd::ZoomLevel)zoom])
            {
                [_nativeFiles addObject:localPath];
                initBinaryMapFile(resource->localPath.toStdString(), useOsmLiveForRouting, true);
            }
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
            
            return [[OARouteCalculationResult alloc] initWithSegmentResults:result start:params.start end:params.end intermediates:params.intermediates leftSide:params.leftSide routingTime:routingTime waypoints:!params.gpxRoute ? nil : params.gpxRoute.wpt mode:params.mode calculateFirstAndLastPoint:YES];
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

// TODO: sync with Android in GPX task
//public List<GpxPoint> generateGpxPoints(RoutingEnvironment env, GpxRouteApproximation gctx, LocationsHolder locationsHolder) {
//    return env.router.generateGpxPoints(gctx, locationsHolder);
//}
//
//public GpxRouteApproximation calculateGpxPointsApproximation(RoutingEnvironment env, GpxRouteApproximation gctx, List<GpxPoint> points) throws IOException, InterruptedException {
//    if (points != null && points.size() > 1) {
//        if (!Algorithms.isEmpty(points)) {
//            return env.router.searchGpxRoute(gctx, points);
//        }
//    }
//    return null;
//}

- (OARoutingEnvironment *) calculateRoutingEnvironment:(OARouteCalculationParams *)params calcGPXRoute:(BOOL)calcGPXRoute skipComplex:(BOOL)skipComplex
{
    auto router = std::make_shared<RoutePlannerFrontEnd>();
    OsmAndAppInstance app = [OsmAndApp instance];
    OAAppSettings *settings = [OAAppSettings sharedManager];
    router->setUseFastRecalculation(settings.useFastRecalculation);
    
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

- (OARouteCalculationResult *) findVectorMapsRoute:(OARouteCalculationParams *)params calcGPXRoute:(BOOL)calcGPXRoute
{
    OARoutingEnvironment *env = [self calculateRoutingEnvironment:params calcGPXRoute:calcGPXRoute skipComplex:NO];
    
    if (!env)
        return [self applicationModeNotSupported:params];
    
    CLLocation *start = [[CLLocation alloc] initWithLatitude:params.start.coordinate.latitude longitude:params.start.coordinate.longitude];
    CLLocation *end = [[CLLocation alloc] initWithLatitude:params.end.coordinate.latitude longitude:params.end.coordinate.longitude];
    NSArray<CLLocation *> *inters = [NSArray new];
    
    if (params.intermediates)
        inters = [NSArray arrayWithArray:params.intermediates];
    
    return [self calcOfflineRouteImpl:params router:env.router ctx:env.ctx complexCtx:env.complexCtx st:start en:end inters:inters precalculated:env.precalculated];
}

- (OARouteCalculationResult *) calculateOsmAndRouteWithIntermediatePoints:(OARouteCalculationParams *)routeParams intermediates:(NSArray<CLLocation *> *)intermediates
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
    NSMutableArray<CLLocation *> *rpIntermediates = [NSMutableArray array];
    int closest = 0;
    double maxDist = DBL_MAX;
    for (int i = 0; i < intermediates.count; i++)
    {
        CLLocation *loc = intermediates[i];
        double dist = [loc distanceFromLocation:rp.start];
        if (dist <= maxDist)
        {
            closest = i;
            maxDist = dist;
        }
    }
    for (int i = closest; i < intermediates.count ; i++ )
    {
        CLLocation *w = intermediates[i];
        [rpIntermediates addObject:[[CLLocation alloc] initWithLatitude:w.coordinate.latitude longitude:w.coordinate.longitude]];
    }
    rp.intermediates = [NSArray arrayWithArray:rpIntermediates];
    return [self findVectorMapsRoute:rp calcGPXRoute:NO];
}

- (NSMutableArray<OARouteDirectionInfo *> *) calcDirections:(NSMutableArray<NSNumber *> *)startI endI:(NSMutableArray<NSNumber *> *)endI inputDirections:(NSArray<OARouteDirectionInfo *> *)inputDirections
{
    NSMutableArray<OARouteDirectionInfo *> *directions = [NSMutableArray array];
    if (inputDirections)
    {
        for (OARouteDirectionInfo *info in inputDirections)
        {
            if (info.routePointOffset >= startI[0].intValue && info.routePointOffset < endI[0].intValue)
            {
                OARouteDirectionInfo *ch = [[OARouteDirectionInfo alloc] initWithAverageSpeed:info.averageSpeed turnType:info.turnType];
                ch.routePointOffset = info.routePointOffset - startI[0].intValue;
                if (info.routeEndPointOffset != 0)
                    ch.routeEndPointOffset = info.routeEndPointOffset - startI[0].intValue;
                
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

- (OARouteCalculationResult *) findOfflineRouteSegment:(OARouteCalculationParams *)rParams start:(CLLocation *)start end:(CLLocation  *)end
{
    OARouteCalculationParams *newParams = [[OARouteCalculationParams alloc] init];
    newParams.start = start;
    newParams.end = end;
    newParams.calculationProgress = rParams.calculationProgress;
    newParams.mode = rParams.mode;
    newParams.leftSide = rParams.leftSide;
    OARouteCalculationResult *newRes = nil;
    try
    {
        if (rParams.mode.getRouterService == OSMAND)
        {
            newRes = [self findVectorMapsRoute:newParams calcGPXRoute:NO];
        }
//        else if (rParams.mode.getRouteService() == RouteService.BROUTER)
//        {
//            newRes= findBROUTERRoute(newParams);
//        }
        else if (rParams.mode.getRouterService == STRAIGHT ||
                   rParams.mode.getRouterService == DIRECT_TO)
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
    NSMutableArray<CLLocation *> *points = [NSMutableArray new];
    NSMutableArray<CLLocation *> *segments = [NSMutableArray new];
    [points addObject:[routeParams.start copy]];
    if(routeParams.intermediates) {
        for (CLLocation *l in routeParams.intermediates)
        {
            [points addObject:[l copy]];
        }
    }
    [points addObject:[routeParams.end copy]];
    CLLocation *lastAdded = nil;
    float speed = [routeParams.mode getDefaultSpeed];
    NSMutableArray<OARouteDirectionInfo *> *computeDirections = [NSMutableArray new];
    while(points.count > 0)
    {
        CLLocation *pl = points.firstObject;
        if (lastAdded == nil || [lastAdded distanceFromLocation:pl] < MIN_STRAIGHT_DIST)
        {
            lastAdded = points.firstObject;
            [points removeObjectAtIndex:0];
            if(lastAdded)
            {
                OARouteDirectionInfo *previousInfo = [[OARouteDirectionInfo alloc] initWithAverageSpeed:speed turnType:TurnType::ptrStraight()];
                previousInfo.routePointOffset = (int) segments.count;
                [previousInfo setDescriptionRoute:OALocalizedString(@"route_head")];
                [computeDirections addObject:previousInfo];
            }
            [segments addObject:lastAdded];
        }
        else
        {
            CLLocation *mp = [OAMapUtils calculateMidPoint:lastAdded s2:pl];
            [points insertObject:mp atIndex:0];
        }
    }
    return [[OARouteCalculationResult alloc] initWithLocations:segments directions:computeDirections params:routeParams waypoints:nil addMissingTurns:NO];
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
    // get the closest point to start and to end
    OAGPXRouteParams *gpxParams = routeParams.gpxRoute;
    BOOL calcWholeRoute = gpxParams.passWholeRoute && (routeParams.previousToRecalculate == nil || !routeParams.onlyStartPointChanged);
    BOOL calculateOsmAndRouteParts = gpxParams.calculateOsmAndRouteParts;
    BOOL reverseRoutePoints = gpxParams.reverse && gpxParams.routePoints.count > 1;
    auto gpxRouteResult = routeParams.gpxRoute.route;
    if (reverseRoutePoints)
    {
        NSMutableArray<CLLocation *> *gpxRouteLocations = [NSMutableArray new];
        std::vector<std::shared_ptr<RouteSegmentResult>> gpxRoute;
        OAGpxRtePt *firstGpxPoint = gpxParams.routePoints.firstObject;
        CLLocation *start = [[CLLocation alloc] initWithLatitude:firstGpxPoint.getLatitude longitude:firstGpxPoint.getLongitude];
        
        for (NSInteger i = 1; i < gpxParams.routePoints.count; i++)
        {
            OAGpxRtePt *gpxPoint = gpxParams.routePoints[i];
            OAGpxTrkPt *trackPoint = [[OAGpxTrkPt alloc] initWithRtePt:gpxPoint];
            OAApplicationMode *appMode = [OAApplicationMode valueOfStringKey:trackPoint.getProfileType def:OAApplicationMode.DEFAULT];
            CLLocation *end = [[CLLocation alloc] initWithLatitude:trackPoint.getLatitude longitude:trackPoint.getLongitude];
            
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
            return [[OARouteCalculationResult alloc] initWithSegmentResults:gpxRouteResult start:routeParams.start end:routeParams.end intermediates:routeParams.intermediates leftSide:routeParams.leftSide routingTime:0. waypoints:nil mode:routeParams.mode calculateFirstAndLastPoint:YES];
        }
        OARouteCalculationResult *result = [[OARouteCalculationResult alloc] initWithSegmentResults:gpxRouteResult start:routeParams.start end:routeParams.end intermediates:routeParams.intermediates leftSide:routeParams.leftSide routingTime:0. waypoints:nil mode:routeParams.mode calculateFirstAndLastPoint:NO];
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
                gpxRoute = [result getOriginalRoute:(int)nearestGpxPointInd];
                if (gpxRoute.size() > 0)
                {
                    gpxRoute.erase(gpxRoute.begin());
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
        return [[OARouteCalculationResult alloc] initWithSegmentResults:newGpxRoute start:routeParams.start end:routeParams.end intermediates:routeParams.intermediates leftSide:routeParams.leftSide routingTime:0. waypoints:nil mode:routeParams.mode calculateFirstAndLastPoint:YES];
    }
    
    if (routeParams.gpxRoute.useIntermediatePointsRTE)
        return [self calculateOsmAndRouteWithIntermediatePoints:routeParams intermediates:gpxParams.points];
    
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
    NSMutableArray<OARouteDirectionInfo *> *gpxDirections = [self calcDirections:startI endI:endI inputDirections:inputDirections];
    [self insertIntermediateSegments:routeParams points:gpxRoute directions:gpxDirections segmentEndpoints:gpxParams.segmentEndPoints calculateOsmAndRouteParts:calculateOsmAndRouteParts];
    [self insertInitialSegment:routeParams points:gpxRoute directions:gpxDirections calculateOsmAndRouteParts:calculateOsmAndRouteParts];
    [self insertFinalSegment:routeParams points:gpxRoute directions:gpxDirections calculateOsmAndRouteParts:calculateOsmAndRouteParts];
    
    for (OARouteDirectionInfo *info in gpxDirections)
    {
        // recalculate
        info.distance = 0;
        info.afterLeftTime = 0;
    }
    
    return [[OARouteCalculationResult alloc] initWithLocations:gpxRoute directions:gpxDirections params:routeParams waypoints:gpxParams.wpt addMissingTurns:routeParams.gpxRoute.addMissingTurns];
}

- (std::vector<std::shared_ptr<RouteSegmentResult>>) findRouteWithIntermediateSegments:(OARouteCalculationParams *)routeParams result:(OARouteCalculationResult *)result gpxRouteLocations:(NSArray<CLLocation *> *)gpxRouteLocations segmentEndpoints:(NSArray<CLLocation *> *)segmentEndpoints nearestGpxPointInd:(NSInteger)nearestGpxPointInd
{
    std::vector<std::shared_ptr<RouteSegmentResult>> newGpxRoute;
    
    NSInteger lastIndex = nearestGpxPointInd;
    for (NSInteger i = 0; i < (NSInteger) segmentEndpoints.count - 1; i++)
    {
        CLLocation *prevSegmentPoint = segmentEndpoints[i];
        CLLocation *newSegmentPoint = segmentEndpoints[i + 1];
        
        if ([prevSegmentPoint distanceFromLocation:newSegmentPoint] <= MIN_DISTANCE_FOR_INSERTING_ROUTE_SEGMENT)
            continue;

        NSInteger indexNew = [self findNearestGpxPointIndexFromRoute:gpxRouteLocations startLoc:newSegmentPoint calculateOsmAndRouteParts:routeParams.gpxRoute.calculateOsmAndRouteParts];
        NSInteger indexPrev = [self findNearestGpxPointIndexFromRoute:gpxRouteLocations startLoc:prevSegmentPoint calculateOsmAndRouteParts:routeParams.gpxRoute.calculateOsmAndRouteParts];
        if (indexPrev != -1 && indexPrev > nearestGpxPointInd && indexNew != -1)
        {
            const auto& origRoute = [result getOriginalRoute:(int)lastIndex endIndex:(int)indexPrev];
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
    newGpxRoute.insert(newGpxRoute.end(), origRoute.begin(), origRoute.end());
    
    return newGpxRoute;
}

- (void) insertIntermediateSegments:(OARouteCalculationParams *)routeParams points:(NSMutableArray<CLLocation *> *)points
                         directions:(NSMutableArray<OARouteDirectionInfo *> *)directions
                   segmentEndpoints:(NSArray<CLLocation *> *)segmentEndpoints
          calculateOsmAndRouteParts:(BOOL)calculateOsmAndRouteParts
{
    for (NSInteger i = 0; i < (NSInteger) segmentEndpoints.count - 1 && segmentEndpoints.count != 0; i++)
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
                    directionInfo.routePointOffset += points.count;
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
        NSMutableArray<OARouteDirectionInfo *> *directions = [self calcDirections:startI endI:endI inputDirections:[rcr getRouteDirections]];;
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
        NSLog(@"Start finding route from %@ to %@ using %@", params.start, params.end, [OARouteService getName:(EOARouteService)params.mode.getRouterService]);
        try
        {
            OARouteCalculationResult *res = nil;
            BOOL calcGPXRoute = params.gpxRoute && params.gpxRoute.points.count > 0;
            if (calcGPXRoute && !params.gpxRoute.calculateOsmAndRoute)
            {
                res = [self calculateGpxRoute:params];
            }
            else if (params.mode.getRouterService == OSMAND)
            {
                res = [self findVectorMapsRoute:params calcGPXRoute:calcGPXRoute];
            }
//            else if (params.mode.getRouterService == BROUTER)
//            {
//                //res = findBROUTERRoute(params);
//            }
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

@end
