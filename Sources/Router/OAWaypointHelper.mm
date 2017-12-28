//
//  OAWaypointHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 07/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAWaypointHelper.h"
#import "OARouteCalculationResult.h"
#import "OAApplicationMode.h"
#import "OALocationPointWrapper.h"
#import "OALocationPoint.h"
#import "OAAmenityLocationPoint.h"
#import "OAAppSettings.h"
#import "OATargetPointsHelper.h"
#import "OARTargetPoint.h"
#import "OARoutingHelper.h"
#import "OAAlarmInfo.h"
#import "OAVoiceRouter.h"
#import "OALocationPoint.h"
#import "OAMapUtils.h"
#import "OAFavoritesHelper.h"
#import "OsmAndApp.h"
#import "OAPOI.h"
#import "OAPOIFilter.h"
#import "OAPOIFiltersHelper.h"
#import "OAPOIUIFilter.h"

#define NOT_ANNOUNCED 0
#define ANNOUNCED_ONCE 1
#define ANNOUNCED_DONE 2

#define LONG_ANNOUNCE_RADIUS 700
#define SHORT_ANNOUNCE_RADIUS 150
#define ALARMS_ANNOUNCE_RADIUS 150

// don't annoy users by lots of announcements
#define APPROACH_POI_LIMIT 1
#define ANNOUNCE_POI_LIMIT 3

@implementation OAWaypointHelper
{
    int searchDeviationRadius;
    int poiSearchDeviationRadius;

    NSMutableArray<NSMutableArray<OALocationPointWrapper *> *> *locationPoints;
    NSMapTable<id<OALocationPoint>, NSNumber *> *locationPointsStates;
    NSMutableArray<NSNumber *> *pointsProgress;
    OARouteCalculationResult *route;
    
    long announcedAlarmTime;
    OAApplicationMode *appMode;
}

+ (OAWaypointHelper *) sharedInstance
{
    static OAWaypointHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OAWaypointHelper alloc] init];
    });
    return _sharedInstance;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        searchDeviationRadius = 500;
        poiSearchDeviationRadius = 100;
        
        locationPoints = [NSMutableArray array];
        pointsProgress = [NSMutableArray array];
        locationPointsStates = [NSMapTable strongToStrongObjectsMapTable];
        
        appMode = [OAAppSettings sharedManager].applicationMode;
    }
    return self;
}

- (NSArray<OALocationPointWrapper *> *) getWaypoints:(int)type
{
    if (type == LPW_TARGETS)
        return [self getTargets:[NSMutableArray array]];
    
    if (type >= locationPoints.count)
        return @[];
    
    return locationPoints[type];
}

- (void) locationChanged:(CLLocation *)location
{
    [self announceVisibleLocations];
}

- (int) getRouteDistance:(OALocationPointWrapper *)point
{
    return [route getDistanceToPoint:point.routeIndex];
}

- (NSMutableArray<OALocationPointWrapper *> *) getTargets:(NSMutableArray<OALocationPointWrapper *> *)points
{
    NSArray<OARTargetPoint *> *wts = [[OATargetPointsHelper sharedInstance] getIntermediatePointsWithTarget];
    for (int k = 0; k < (int)wts.count; k++)
    {
        int index = (int)wts.count - k - 1;
        OARTargetPoint *tp = wts[index];
        int routeIndex;
        if (!route)
            routeIndex = k == 0 ? INT_MAX : index;
        else
            routeIndex = k == 0 ? (int)[route getImmutableAllLocations].count - 1 : [route getIndexOfIntermediate:k - 1];
        
        [points addObject:[[OALocationPointWrapper alloc] initWithRouteCalculationResult:route type:LPW_TARGETS point:tp deviationDistance:0 routeIndex:routeIndex]];
    }
    return [[[points reverseObjectEnumerator] allObjects] mutableCopy];
}

- (void) commitPointsRemoval:(NSMutableArray<NSNumber *> *)checkedIntermediates
{
    int cnt = 0;
    for (int i = (int)checkedIntermediates.count - 1; i >= 0; i--)
    {
        if (![checkedIntermediates[i] boolValue])
            cnt++;
    }
    if (cnt > 0)
    {
        OATargetPointsHelper *targets = [OATargetPointsHelper sharedInstance];
        BOOL changeDestinationFlag = ![checkedIntermediates[checkedIntermediates.count - 1] boolValue];
        if (cnt == checkedIntermediates.count)
        { // there is no alternative destination if all points are to be
            // removed?
            [targets removeAllWayPoints:YES clearBackup:YES];
        }
        else
        {
            for (int i = (int)checkedIntermediates.count - 2; i >= 0; i--)
            { // skip the destination until a retained
                // waypoint is found
                if ([checkedIntermediates[i] boolValue] && changeDestinationFlag)
                { // Find a valid replacement for the
                    // destination
                    [targets makeWayPointDestination:cnt == 0 index:i];
                    changeDestinationFlag = false;
                }
                else if (![checkedIntermediates[i] boolValue])
                {
                    cnt--;
                    [targets removeWayPoint:cnt == 0 index:i];
                }
            }
        }
    }
}

- (void) removeVisibleLocationPoint:(OALocationPointWrapper *)lp
{
    if (lp.type < locationPoints.count)
        [locationPoints[lp.type] removeObject:lp];
}

- (void) removeVisibleLocationPoints:(NSMutableArray<OALocationPointWrapper *> *)points
{
    NSArray<OARTargetPoint *> *ps = [[OATargetPointsHelper sharedInstance] getIntermediatePointsWithTarget];
    NSMutableArray<NSNumber *> *checkedIntermediates = nil;
    for (OALocationPointWrapper *lp in points)
    {
        if (lp.type == LPW_TARGETS)
        {
            if (!checkedIntermediates)
            {
                checkedIntermediates = [NSMutableArray arrayWithCapacity:ps.count];
                for (int i = 0; i < ps.count; i++)
                     [checkedIntermediates addObject:@YES];
            }
            if (((OARTargetPoint *) lp.point).intermediate)
                checkedIntermediates[((OARTargetPoint *) lp.point).index] = @NO;
            else
                checkedIntermediates[ps.count - 1] = @NO;
        }
        else if (lp.type < locationPoints.count)
        {
            [locationPoints[lp.type] removeObject:lp];
        }
    }
    if (checkedIntermediates)
        [self commitPointsRemoval:checkedIntermediates];
}

- (OALocationPointWrapper *) getMostImportantLocationPoint:(NSMutableArray<OALocationPointWrapper *> *)list
{
    //Location lastProjection = app.getRoutingHelper().getLastProjection();
    if (list)
        [list removeAllObjects];
    
    OALocationPointWrapper *found = nil;
    for (int type = 0; type < locationPoints.count; type++)
    {
        if (type == LPW_ALARMS || type == LPW_TARGETS)
            continue;
        
        int kIterator = pointsProgress[type].intValue;
        NSArray<OALocationPointWrapper *> *lp = locationPoints[type];
        while (kIterator < lp.count)
        {
            OALocationPointWrapper *lwp = lp[kIterator];
            if (lp[kIterator].routeIndex < route.currentRoute)
            {
                // skip
            }
            else
            {
                if ([route getDistanceToPoint:lwp.routeIndex] <= LONG_ANNOUNCE_RADIUS)
                {
                    if (!found || found.routeIndex < lwp.routeIndex)
                    {
                        found = lwp;
                        if (list)
                            [list addObject:lwp];
                    }
                }
                break;
            }
            kIterator++;
        }
    }
    return found;
}

+ (OAAlarmInfo *) createSpeedAlarm:(EOAMetricsConstant)mc mxspeed:(float)mxspeed loc:(CLLocation *)loc delta:(float)delta
{
    OAAlarmInfo *speedAlarm = nil;
    if (mxspeed != 0 && loc && loc.speed >= 0 && mxspeed != 40.f/*NONE_MAX_SPEED*/)
    {
        if (loc.speed > mxspeed + delta)
        {
            int speed;
            if (mc == KILOMETERS_AND_METERS)
                speed = roundf(mxspeed * 3.6f);
            else
                speed = roundf(mxspeed * 3.6f / 1.6f);
            
            speedAlarm = [OAAlarmInfo createSpeedLimit:speed coordinate:loc.coordinate];
        }
    }
    return speedAlarm;
}

- (void) announceVisibleLocations
{
    OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
    CLLocation *lastKnownLocation = [routingHelper getLastProjection];
    if (lastKnownLocation && [routingHelper isFollowingMode])
    {
        for (int type = 0; type < (int)locationPoints.count; type++)
        {
            int currentRoute = route.currentRoute;
            NSMutableArray<OALocationPointWrapper *> *approachPoints = [NSMutableArray array];
            NSMutableArray<OALocationPointWrapper *> *announcePoints = [NSMutableArray array];
            NSMutableArray<OALocationPointWrapper *> *lp = locationPoints[type];
            if (lp)
            {
                int kIterator = pointsProgress[type].intValue;
                while (kIterator < lp.count && lp[kIterator].routeIndex < currentRoute)
                    kIterator++;
                
                pointsProgress[type] = @(kIterator);
                while (kIterator < lp.count)
                {
                    OALocationPointWrapper *lwp = lp[kIterator];
                    if (lwp.announce)
                    {
                        if ([route getDistanceToPoint:lwp.routeIndex] > LONG_ANNOUNCE_RADIUS * 2)
                            break;
                        
                        id<OALocationPoint> point = lwp.point;
                        double d1 = MAX(0.0, [lastKnownLocation distanceFromLocation:[[CLLocation alloc] initWithLatitude:[point getLatitude] longitude:[point getLongitude]]] - lwp.deviationDistance);
                        NSNumber *state = [locationPointsStates objectForKey:point];
                        if (state && state.intValue == ANNOUNCED_ONCE
                            && [[self getVoiceRouter] isDistanceLess:lastKnownLocation.speed dist:d1 etalon:SHORT_ANNOUNCE_RADIUS defSpeed:0.f])
                        {
                            [locationPointsStates setObject:@(ANNOUNCED_DONE) forKey:point];
                            [announcePoints addObject:lwp];
                        }
                        else if (type != LPW_ALARMS && (!state || state.intValue == NOT_ANNOUNCED)
                                 && [[self getVoiceRouter] isDistanceLess:lastKnownLocation.speed dist:d1 etalon:LONG_ANNOUNCE_RADIUS defSpeed:0.f])
                        {
                            [locationPointsStates setObject:@(ANNOUNCED_ONCE) forKey:point];
                            [approachPoints addObject:lwp];
                        }
                        else if (type == LPW_ALARMS && (!state || state.intValue == NOT_ANNOUNCED)
                                   && [[self getVoiceRouter] isDistanceLess:lastKnownLocation.speed dist:d1 etalon:ALARMS_ANNOUNCE_RADIUS defSpeed:0.f])
                        {
                            [locationPointsStates setObject:@(ANNOUNCED_ONCE) forKey:point];
                            [approachPoints addObject:lwp];
                        }
                    }
                    kIterator++;
                }
                /*
                if (announcePoints.count > 0)
                {
                    if (announcePoints.count > ANNOUNCE_POI_LIMIT)
                        announcePoints = announcePoints.subList(0, ANNOUNCE_POI_LIMIT);
                    
                    if (type == WAYPOINTS) {
                        getVoiceRouter().announceWaypoint(announcePoints);
                    } else if (type == POI) {
                        getVoiceRouter().announcePoi(announcePoints);
                    } else if (type == ALARMS) {
                        // nothing to announce
                    } else if (type == FAVORITES) {
                        getVoiceRouter().announceFavorite(announcePoints);
                    }
                }
                if (!approachPoints.isEmpty()) {
                    if (approachPoints.size() > APPROACH_POI_LIMIT) {
                        approachPoints = approachPoints.subList(0, APPROACH_POI_LIMIT);
                    }
                    if (type == WAYPOINTS) {
                        getVoiceRouter().approachWaypoint(lastKnownLocation, approachPoints);
                    } else if (type == POI) {
                        getVoiceRouter().approachPoi(lastKnownLocation, approachPoints);
                    } else if (type == ALARMS) {
                        EnumSet<AlarmInfoType> ait = EnumSet.noneOf(AlarmInfoType.class);
                        for (LocationPointWrapper pw : approachPoints) {
                            ait.add(((AlarmInfo) pw.point).getType());
                        }
                        for (AlarmInfoType t : ait) {
                            app.getRoutingHelper().getVoiceRouter().announceAlarm(new AlarmInfo(t, -1), lastKnownLocation.getSpeed());
                        }
                    } else if (type == FAVORITES) {
                        getVoiceRouter().approachFavorite(lastKnownLocation, approachPoints);
                    }
                }
                 */
            }
        }
    }
}

- (OAVoiceRouter *) getVoiceRouter
{
    return [[OARoutingHelper sharedInstance] getVoiceRouter];
}

- (OAAlarmInfo *) getMostImportantAlarm:(EOAMetricsConstant)mc showCameras:(BOOL)showCameras
{
    CLLocation *lastProjection = [[OARoutingHelper sharedInstance] getLastProjection];
    float mxspeed = [route getCurrentMaxSpeed];
    float delta = [[OAAppSettings sharedManager].speedLimitExceed get] / 3.6f;
    OAAlarmInfo *speedAlarm = [self.class createSpeedAlarm:mc mxspeed:mxspeed loc:lastProjection delta:delta];
    if (speedAlarm)
        [[self getVoiceRouter] announceSpeedAlarm:speedAlarm.intValue speed:lastProjection.speed];
    
    OAAlarmInfo *mostImportant = speedAlarm;
    int value = speedAlarm ? [speedAlarm updateDistanceAndGetPriority:0 distance:0] : INT_MAX;
    if (LPW_ALARMS < pointsProgress.count)
    {
        int kIterator = pointsProgress[LPW_ALARMS].intValue;
        NSMutableArray<OALocationPointWrapper *> *lp = locationPoints[LPW_ALARMS];
        while (kIterator < lp.count)
        {
            OALocationPointWrapper *lwp = lp[kIterator];
            if (lp[kIterator].routeIndex < route.currentRoute)
            {
                // skip
            }
            else
            {
                int d = [route getDistanceToPoint:lwp.routeIndex];
                if (d > LONG_ANNOUNCE_RADIUS)
                    break;

                OAAlarmInfo *inf = (OAAlarmInfo *) lwp.point;
                float speed = lastProjection && lastProjection.speed >= 0 ? lastProjection.speed : 0;
                float time = speed > 0 ? d / speed : INT_MAX;
                int vl = [inf updateDistanceAndGetPriority:time distance:d];
                if (vl < value && (showCameras || inf.type != AIT_SPEED_CAMERA))
                {
                    mostImportant = inf;
                    value = vl;
                }
            }
            kIterator++;
        }
    }
    return mostImportant;
}

- (NSMutableArray<OALocationPointWrapper *> *) clearAndGetArray:(NSMutableArray<NSMutableArray<OALocationPointWrapper *> *> *)array ind:(int)ind
{
    while (array.count <= ind)
        [array addObject:[NSMutableArray array]];

    [array[ind] removeAllObjects];
    return array[ind];
}

- (float) dist:(id<OALocationPoint>)l locations:(NSArray<CLLocation *> *)locations ind:(int *)ind devDirRight:(BOOL *)devDirRight
{
    float dist = FLT_MAX;
    // Special iterations because points stored by pairs!
    for (int i = 1; i < locations.count; i++)
    {
        double ld = [OAMapUtils getOrthogonalDistance:[[CLLocation alloc] initWithLatitude:[l getLatitude] longitude:[l getLongitude]] fromLocation:locations[i - 1] toLocation:locations[i]];
        if (ld < dist)
        {
            if (ind != nullptr)
                *ind = i;
            
            dist = (float) ld;
        }
    }
    
    if (ind != nullptr && dist < FLT_MAX)
    {
        int i = *ind;
        *devDirRight = [OAMapUtils rightSide:[l getLatitude] lon:[l getLongitude] aLat:locations[i-1].coordinate.latitude aLon:locations[i-1].coordinate.longitude bLat:locations[i].coordinate.latitude bLon:locations[i].coordinate.longitude];
    }
    
    return dist;
}

- (int) getSearchDeviationRadius:(int)type
{
    return type == LPW_POI ? poiSearchDeviationRadius : searchDeviationRadius;
}

- (void) setSearchDeviationRadius:(int)type radius:(int)radius
{
    if (type == LPW_POI)
        poiSearchDeviationRadius = radius;
    else
        searchDeviationRadius = radius;
}

- (void) findLocationPoints:(OARouteCalculationResult *)rt type:(int)type locationPoints:(NSMutableArray<OALocationPointWrapper *> *)locationPoints points:(NSArray<id<OALocationPoint>> *)points announce:(BOOL)announce
{
    NSArray<CLLocation *> *immutableAllLocations = [rt getImmutableAllLocations];
    int ind = 0;
    BOOL devDirRight = NO;
    for (id<OALocationPoint> p in points)
    {
        float dist = [self dist:p locations:immutableAllLocations ind:&ind devDirRight:&devDirRight];
        int rad = [self getSearchDeviationRadius:type];
        if (dist <= rad)
        {
            OALocationPointWrapper *lpw = [[OALocationPointWrapper alloc] initWithRouteCalculationResult:rt type:type point:p deviationDistance:dist routeIndex:ind];
            lpw.deviationDirectionRight = devDirRight;
            [lpw setAnnounce:announce];
            [locationPoints addObject:lpw];
        }
    }
}

- (void) sortList:(NSMutableArray<OALocationPointWrapper *> *)list
{
    [list sortUsingComparator:^NSComparisonResult(OALocationPointWrapper* olhs, OALocationPointWrapper* orhs)
    {
        int lhs = olhs.routeIndex;
        int rhs = orhs.routeIndex;
        if (lhs == rhs)
        {
            float lhsf = olhs.deviationDistance;
            float rhsf = orhs.deviationDistance;

            if (lhsf == rhsf)
                return NSOrderedSame;
            else
                return lhsf < rhsf ? NSOrderedAscending : NSOrderedDescending;
        }
        return lhs < rhs ? NSOrderedAscending : NSOrderedDescending;
    }];
}

- (void) calculateAlarms:(OARouteCalculationResult *)route array:(NSMutableArray<OALocationPointWrapper *> *)array mode:(OAApplicationMode *)mode
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    for (OAAlarmInfo *i in route.alarmInfo)
    {
        if (i.type == AIT_SPEED_CAMERA)
        {
            if ([settings.showCameras get:mode] || [settings.speakCameras get:mode])
            {
                OALocationPointWrapper *lw = [[OALocationPointWrapper alloc] initWithRouteCalculationResult:route type:LPW_ALARMS point:i deviationDistance:0 routeIndex:i.locationIndex];
                [lw setAnnounce:[settings.speakCameras get:mode]];
                [array addObject:lw];
            }
        }
        else
        {
            if ([settings.showTrafficWarnings get:mode] || [settings.speakTrafficWarnings get:mode])
            {
                OALocationPointWrapper *lw = [[OALocationPointWrapper alloc] initWithRouteCalculationResult:route type:LPW_ALARMS point:i deviationDistance:0 routeIndex:i.locationIndex];
                [lw setAnnounce:[settings.speakTrafficWarnings get:mode]];
                [array addObject:lw];
            }
        }
    }
}

- (void) calculatePoi:(OARouteCalculationResult *)route locationPoints:(NSMutableArray<OALocationPointWrapper *> *)locationPoints announcePOI:(BOOL)announcePOI
{
    OAPOIFiltersHelper *helper = [OAPOIFiltersHelper sharedInstance];
    if ([helper isShowingAnyPoi])
    {
        NSArray<CLLocation *> *locs = [route getImmutableAllLocations];
        NSMutableArray<OAPOI *> *amenities = [NSMutableArray array];
        for (OAPOIUIFilter *pf in [helper getSelectedPoiFilters])
            [amenities addObjectsFromArray:[pf searchAmenitiesOnThePath:locs poiSearchDeviationRadius:poiSearchDeviationRadius]];

        for (OAPOI *a in amenities)
        {
            /*
            AmenityRoutePoint rp = a.getRoutePoint();
            int i = locs.indexOf(rp.pointA);
            if (i >= 0) {
                OALocationPointWrapper *lwp = new LocationPointWrapper(route, POI, new AmenityLocationPoint(a),
                                                                    (float) rp.deviateDistance, i);
                lwp.deviationDirectionRight = rp.deviationDirectionRight;
                lwp.setAnnounce(announcePOI);
                locationPoints.add(lwp);
            }
             */
        }
    }
}

- (void) recalculatePoints:(OARouteCalculationResult *)route type:(int)type locationPoints:(NSMutableArray<NSMutableArray<OALocationPointWrapper *> *> *)locationPoints
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    BOOL all = type == -1;
    OAApplicationMode *appMode_ = settings.applicationMode;
    if (route && ![route isEmpty])
    {
        BOOL showWaypoints = settings.showGpxWpt; // global
        BOOL announceWaypoints = settings.announceWpt; // global
        
        if (route.appMode)
            appMode_ = route.appMode;

        BOOL showPOI = [settings.showNearbyPoi get:appMode_];
        BOOL showFavorites = [settings.showNearbyFavorites get:appMode_];
        BOOL announceFavorites = [settings.announceNearbyFavorites get:appMode_];
        BOOL announcePOI = [settings.announceNearbyPoi get:appMode_];
        
        if (type == LPW_FAVORITES || all)
        {
            NSMutableArray<OALocationPointWrapper *> *array = [self clearAndGetArray:locationPoints ind:LPW_FAVORITES];
            if (showFavorites)
            {
                [self findLocationPoints:route type:LPW_FAVORITES locationPoints:array points:(NSArray<id<OALocationPoint>> *)[OAFavoritesHelper getVisibleFavoriteItems] announce:announceFavorites];
                [self sortList:array];
            }
        }
        if (type == LPW_ALARMS || all)
        {
            NSMutableArray<OALocationPointWrapper *> *array = [self clearAndGetArray:locationPoints ind:LPW_ALARMS];
            if (route.appMode)
            {
                [self calculateAlarms:route array:array mode:appMode_];
                [self sortList:array];
            }
        }
        if (type == LPW_WAYPOINTS || all)
        {
            NSMutableArray<OALocationPointWrapper *> *array = [self clearAndGetArray:locationPoints ind:LPW_WAYPOINTS];
            if (showWaypoints)
            {
                [self findLocationPoints:route type:LPW_WAYPOINTS locationPoints:array points:route.locationPoints announce:announceWaypoints];
                [self sortList:array];
            }
        }
        if (type == LPW_POI || all)
        {
            NSMutableArray<OALocationPointWrapper *> *array = [self clearAndGetArray:locationPoints ind:LPW_POI];
            if (showPOI)
            {
                [self calculatePoi:route locationPoints:array announcePOI:announcePOI];
                [self sortList:array];
            }
        }
    }
}

- (void) enableWaypointType:(int)type enable:(BOOL)enable
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    //An item will be displayed in the Waypoint list if either "Show..." or "Announce..." is selected for it in the Navigation settings
    //Keep both "Show..." and "Announce..." Nav settings in sync when user changes what to display in the Waypoint list, as follows:
    if (type == LPW_ALARMS)
    {
        [settings.showTrafficWarnings set:enable mode:appMode];
        [settings.speakTrafficWarnings set:enable mode:appMode];
        [settings.showPedestrian set:enable mode:appMode];
        [settings.speakPedestrian set:enable mode:appMode];
        //But do not implicitly change speed_cam settings here because of legal restrictions in some countries, so Nav settings must prevail
    }
    else if (type == LPW_POI)
    {
        [settings.showNearbyPoi set:enable mode:appMode];
        [settings.announceNearbyPoi set:enable mode:appMode];
    }
    else if (type == LPW_FAVORITES)
    {
        [settings.showNearbyFavorites set:enable mode:appMode];
        [settings.announceNearbyFavorites set:enable mode:appMode];
    }
    else if (type == LPW_WAYPOINTS)
    {
        settings.showGpxWpt = enable;
        settings.announceWpt = enable;
    }
    [self recalculatePoints:route type:type locationPoints:locationPoints];
}

- (void) setNewRoute:(OARouteCalculationResult *)route
{
    // TODO
    //List<List<LocationPointWrapper>> locationPoints = new ArrayList<List<LocationPointWrapper>>();
    //recalculatePoints(route, -1, locationPoints);
    //setLocationPoints(locationPoints, route);
}

@end
