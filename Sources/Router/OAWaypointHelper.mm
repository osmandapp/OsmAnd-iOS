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

#include <binaryRead.h>

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
    int _searchDeviationRadius;
    int _poiSearchDeviationRadius;

    NSMutableArray<NSMutableArray<OALocationPointWrapper *> *> *_locationPoints;
    NSMapTable<id<OALocationPoint>, NSNumber *> *_locationPointsStates;
    NSMutableArray<NSNumber *> *_pointsProgress;
    OARouteCalculationResult *_route;
    
    long _announcedAlarmTime;
    OAApplicationMode *_appMode;
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

+ (int) TARGETS { return 0; }

+ (int) WAYPOINTS { return 1; }

+ (int) POI { return 2; }

+ (int) FAVORITES { return 3; }

+ (int) ALARMS { return 4; }

+ (int) MAX { return 5; }

+ (int) ANY { return 6; }

+ (NSArray<NSNumber *> *) SEARCH_RADIUS_VALUES
{
    static NSArray<NSNumber *> *_array = @[@50, @100, @200, @500, @1000, @2000, @5000];
    return _array;
}

+ (double) DISTANCE_IGNORE_DOUBLE_SPEEDCAMS
{
    return 150.0;
}
   
- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _searchDeviationRadius = 500;
        _poiSearchDeviationRadius = 100;
        
        _locationPoints = [NSMutableArray array];
        _pointsProgress = [NSMutableArray array];
        _locationPointsStates = [NSMapTable strongToStrongObjectsMapTable];
        _deletedPoints = [NSMutableArray array];
        
        _appMode = [OAAppSettings sharedManager].applicationMode;
        
    }
    return self;
}

- (NSArray<OALocationPointWrapper *> *) getWaypoints:(int)type
{
    if (type == LPW_TARGETS)
        return [self getTargets:[NSMutableArray array]];
    
    if (type >= _locationPoints.count)
        return @[];
    
    return _locationPoints[type];
}

- (void) locationChanged:(CLLocation *)location
{
    [self announceVisibleLocations];
}

- (int) getRouteDistance:(OALocationPointWrapper *)point
{
    return [_route getDistanceToPoint:point.routeIndex];
}

- (NSMutableArray<OALocationPointWrapper *> *) getTargets:(NSMutableArray<OALocationPointWrapper *> *)points
{
    NSArray<OARTargetPoint *> *wts = [[OATargetPointsHelper sharedInstance] getIntermediatePointsWithTarget];
    for (int k = 0; k < (int)wts.count; k++)
    {
        int index = (int)wts.count - k - 1;
        OARTargetPoint *tp = wts[index];
        int routeIndex;
        if (!_route)
            routeIndex = k == 0 ? INT_MAX : index;
        else
            routeIndex = k == 0 ? (int)[_route getImmutableAllLocations].count - 1 : [_route getIndexOfIntermediate:k - 1];
        
        [points addObject:[[OALocationPointWrapper alloc] initWithRouteCalculationResult:_route type:LPW_TARGETS point:tp deviationDistance:0 routeIndex:routeIndex]];
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
    if (lp.type < _locationPoints.count)
        [_locationPoints[lp.type] removeObject:lp];
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
        else if (lp.type < _locationPoints.count)
        {
            [_locationPoints[lp.type] removeObject:lp];
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
    for (int type = 0; type < _locationPoints.count; type++)
    {
        if (type == LPW_ALARMS || type == LPW_TARGETS)
            continue;
        
        int kIterator = _pointsProgress[type].intValue;
        NSArray<OALocationPointWrapper *> *lp = _locationPoints[type];
        while (kIterator < lp.count)
        {
            OALocationPointWrapper *lwp = lp[kIterator];
            if (lp[kIterator].routeIndex < _route.currentRoute)
            {
                // skip
            }
            else
            {
                if ([_route getDistanceToPoint:lwp.routeIndex] <= LONG_ANNOUNCE_RADIUS)
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
        for (int type = 0; type < (int)_locationPoints.count; type++)
        {
            int currentRoute = _route.currentRoute;
            NSMutableArray<OALocationPointWrapper *> *approachPoints = [NSMutableArray array];
            NSMutableArray<OALocationPointWrapper *> *announcePoints = [NSMutableArray array];
            NSMutableArray<OALocationPointWrapper *> *lp = _locationPoints[type];
            if (lp)
            {
                int kIterator = _pointsProgress[type].intValue;
                while (kIterator < lp.count && lp[kIterator].routeIndex < currentRoute)
                    kIterator++;
                
                _pointsProgress[type] = @(kIterator);
                while (kIterator < lp.count)
                {
                    OALocationPointWrapper *lwp = lp[kIterator];
                    if (lwp.announce)
                    {
                        if ([_route getDistanceToPoint:lwp.routeIndex] > LONG_ANNOUNCE_RADIUS * 2)
                            break;
                        
                        id<OALocationPoint> point = lwp.point;
                        double d1 = MAX(0.0, [lastKnownLocation distanceFromLocation:[[CLLocation alloc] initWithLatitude:[point getLatitude] longitude:[point getLongitude]]] - lwp.deviationDistance);
                        NSNumber *state = [_locationPointsStates objectForKey:point];
                        if (state && state.intValue == ANNOUNCED_ONCE
                            && [[self getVoiceRouter] isDistanceLess:lastKnownLocation.speed dist:d1 etalon:SHORT_ANNOUNCE_RADIUS defSpeed:0.f])
                        {
                            [_locationPointsStates setObject:@(ANNOUNCED_DONE) forKey:point];
                            [announcePoints addObject:lwp];
                        }
                        else if (type != LPW_ALARMS && (!state || state.intValue == NOT_ANNOUNCED)
                                 && [[self getVoiceRouter] isDistanceLess:lastKnownLocation.speed dist:d1 etalon:LONG_ANNOUNCE_RADIUS defSpeed:0.f])
                        {
                            [_locationPointsStates setObject:@(ANNOUNCED_ONCE) forKey:point];
                            [approachPoints addObject:lwp];
                        }
                        else if (type == LPW_ALARMS && (!state || state.intValue == NOT_ANNOUNCED)
                                   && [[self getVoiceRouter] isDistanceLess:lastKnownLocation.speed dist:d1 etalon:ALARMS_ANNOUNCE_RADIUS defSpeed:0.f])
                        {
                            [_locationPointsStates setObject:@(ANNOUNCED_ONCE) forKey:point];
                            [approachPoints addObject:lwp];
                        }
                    }
                    kIterator++;
                }
                if (announcePoints.count > 0)
                {
                    if (announcePoints.count > ANNOUNCE_POI_LIMIT)
                        announcePoints = [NSMutableArray arrayWithArray:[announcePoints subarrayWithRange:NSMakeRange(0, ANNOUNCE_POI_LIMIT)]];
                    
                    if (type == LPW_WAYPOINTS)
                        [[self getVoiceRouter] announceWaypoint:announcePoints];
                    else if (type == LPW_POI)
                        [[self getVoiceRouter] announcePoi:announcePoints];
                    //else if (type == LPW_ALARMS)
                        // nothing to announce
                    else if (type == LPW_FAVORITES)
                        [[self getVoiceRouter] announceFavorite:announcePoints];
                }
                if (approachPoints.count > 0)
                {
                    if (approachPoints.count > APPROACH_POI_LIMIT)
                        approachPoints = [NSMutableArray arrayWithArray:[approachPoints subarrayWithRange:NSMakeRange(0, APPROACH_POI_LIMIT)]];
                    
                    if (type == LPW_WAYPOINTS)
                    {
                        [[self getVoiceRouter] approachWaypoint:lastKnownLocation points:approachPoints];
                    }
                    else if (type == LPW_POI)
                    {
                        [[self getVoiceRouter] approachPoi:lastKnownLocation points:approachPoints];
                    }
                    else if (type == LPW_ALARMS)
                    {
                        NSMutableSet<NSNumber *> *ait = [NSMutableSet set];
                        for (OALocationPointWrapper *pw in approachPoints)
                        {
                            [ait addObject:@(((OAAlarmInfo *) pw.point).type)];
                        }
                        for (NSNumber *n : ait)
                        {
                            EOAAlarmInfoType t = (EOAAlarmInfoType) n.intValue;
                            [[self getVoiceRouter] announceAlarm:[[OAAlarmInfo alloc] initWithType:t locationIndex:-1] speed:lastKnownLocation.speed];
                        }
                    }
                    else if (type == LPW_FAVORITES)
                    {
                        [[self getVoiceRouter] approachFavorite:lastKnownLocation points:approachPoints];
                    }
                }
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
    float mxspeed = [_route getCurrentMaxSpeed];
    float delta = [[OAAppSettings sharedManager].speedLimitExceed get] / 3.6f;
    OAAlarmInfo *speedAlarm = [self.class createSpeedAlarm:mc mxspeed:mxspeed loc:lastProjection delta:delta];
    if (speedAlarm)
        [[self getVoiceRouter] announceSpeedAlarm:speedAlarm.intValue speed:lastProjection.speed];
    
    OAAlarmInfo *mostImportant = speedAlarm;
    int value = speedAlarm ? [speedAlarm updateDistanceAndGetPriority:0 distance:0] : INT_MAX;
    if (LPW_ALARMS < _pointsProgress.count)
    {
        int kIterator = _pointsProgress[LPW_ALARMS].intValue;
        NSMutableArray<OALocationPointWrapper *> *lp = _locationPoints[LPW_ALARMS];
        while (kIterator < lp.count)
        {
            OALocationPointWrapper *lwp = lp[kIterator];
            if (lp[kIterator].routeIndex < _route.currentRoute)
            {
                // skip
            }
            else
            {
                int d = [_route getDistanceToPoint:lwp.routeIndex];
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
    return type == LPW_POI ? _poiSearchDeviationRadius : _searchDeviationRadius;
}

- (void) setSearchDeviationRadius:(int)type radius:(int)radius
{
    if (type == LPW_POI)
        _poiSearchDeviationRadius = radius;
    else
        _searchDeviationRadius = radius;
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
            [amenities addObjectsFromArray:[pf searchAmenitiesOnThePath:locs poiSearchDeviationRadius:_poiSearchDeviationRadius]];

        for (OAPOI *a in amenities)
        {
            OAPOIRoutePoint *rp = a.routePoint;
            NSInteger i = [locs indexOfObject:rp.pointA];
            if (i >= 0)
            {
                OALocationPointWrapper *lwp = [[OALocationPointWrapper alloc] initWithRouteCalculationResult:route type:LPW_POI point:[[OAAmenityLocationPoint alloc] initWithPoi:a] deviationDistance:rp.deviateDistance routeIndex:(int)i];
                lwp.deviationDirectionRight = rp.deviationDirectionRight;
                lwp.announce = announcePOI;
                [locationPoints addObject:lwp];
            }
        }
    }
}

- (void) recalculatePoints:(int)type
{
    [self recalculatePoints:_route type:type locationPoints:_locationPoints];
}

- (void) recalculatePoints:(OARouteCalculationResult *)route type:(int)type locationPoints:(NSMutableArray<NSMutableArray<OALocationPointWrapper *> *> *)locationPoints
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    BOOL all = type == -1;
    _appMode = settings.applicationMode;
    if (route && ![route isEmpty])
    {
        BOOL showWaypoints = settings.showGpxWpt; // global
        BOOL announceWaypoints = settings.announceWpt; // global
        
        if (route.appMode)
            _appMode = route.appMode;

        BOOL showPOI = [settings.showNearbyPoi get:_appMode];
        BOOL showFavorites = [settings.showNearbyFavorites get:_appMode];
        BOOL announceFavorites = [settings.announceNearbyFavorites get:_appMode];
        BOOL announcePOI = [settings.announceNearbyPoi get:_appMode];
        
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
                [self calculateAlarms:route array:array mode:_appMode];
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
        for (OALocationPointWrapper *lp in _deletedPoints)
        {
            if (lp.type < _locationPoints.count)
                [locationPoints[lp.type] removeObject:lp];
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
        [settings.showTrafficWarnings set:enable mode:_appMode];
        [settings.speakTrafficWarnings set:enable mode:_appMode];
        [settings.showPedestrian set:enable mode:_appMode];
        [settings.speakPedestrian set:enable mode:_appMode];
        //But do not implicitly change speed_cam settings here because of legal restrictions in some countries, so Nav settings must prevail
    }
    else if (type == LPW_POI)
    {
        [settings.showNearbyPoi set:enable mode:_appMode];
        [settings.announceNearbyPoi set:enable mode:_appMode];
    }
    else if (type == LPW_FAVORITES)
    {
        [settings.showNearbyFavorites set:enable mode:_appMode];
        [settings.announceNearbyFavorites set:enable mode:_appMode];
    }
    else if (type == LPW_WAYPOINTS)
    {
        settings.showGpxWpt = enable;
        settings.announceWpt = enable;
    }
    [self recalculatePoints:_route type:type locationPoints:_locationPoints];
}

- (BOOL) isWaypointGroupVisible:(int)waypointType route:(OARouteCalculationResult *)route
{
    if (waypointType == LPW_ALARMS)
        return route && route.alarmInfo.count > 0;
    else if (waypointType == LPW_WAYPOINTS)
        return route && route.locationPoints.count > 0;
    
    return true;
}

- (BOOL) isTypeConfigurable:(int)waypointType
{
    return waypointType != LPW_TARGETS;
}

- (BOOL) isTypeVisible:(int)waypointType
{
    BOOL vis = [self isWaypointGroupVisible:waypointType route:_route];
    if (!vis)
        return false;
    
    return vis;
}

- (BOOL) isTypeEnabled:(int)type
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    if (type == LPW_ALARMS)
        return [settings.showTrafficWarnings get:_appMode];
    else if (type == LPW_POI)
        return [settings.showNearbyPoi get:_appMode];
    else if (type == LPW_FAVORITES)
        return [settings.showNearbyFavorites get:_appMode];
    else if (type == LPW_WAYPOINTS)
        return settings.showGpxWpt;
    
    return true;
}


- (void) setLocationPoints:(NSMutableArray<NSMutableArray<OALocationPointWrapper *> *> *)locationPoints route:(OARouteCalculationResult *)route
{
    _locationPoints = locationPoints;
    _locationPointsStates = [NSMapTable strongToStrongObjectsMapTable];
    
    NSMutableArray *list = [NSMutableArray arrayWithCapacity:locationPoints.count];
    for (int i = 0; i < (int)locationPoints.count; i++)
        [list addObject:@0];
    
    _pointsProgress = list;
    _route = route;
}

- (void) setNewRoute:(OARouteCalculationResult *)route
{
    NSMutableArray<NSMutableArray<OALocationPointWrapper *> *> *locationPoints = [NSMutableArray array];
    [self recalculatePoints:route type:-1 locationPoints:locationPoints];
    [self setLocationPoints:locationPoints route:route];
}

- (OAAlarmInfo *) calculateMostImportantAlarm:(std::shared_ptr<RouteDataObject>)ro loc:(CLLocation *)loc mc:(EOAMetricsConstant)mc showCameras:(BOOL)showCameras
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    float mxspeed = ro->getMaximumSpeed(ro->bearingVsRouteDirection(loc.course));
    float delta = [settings.speedLimitExceed get] / 3.6f;
    OAAlarmInfo *speedAlarm = [self.class createSpeedAlarm:mc mxspeed:mxspeed loc:loc delta:delta];
    if (speedAlarm)
    {
        [[self getVoiceRouter] announceSpeedAlarm:speedAlarm.intValue speed:loc.speed];
        return speedAlarm;
    }
    for (int i = 0; i < ro->getPointsLength(); i++)
    {
        auto& pointTypes = ro->pointTypes[i];
        RoutingIndex *reg = ro->region;
        if (!pointTypes.empty())
        {
            for (int r = 0; r < pointTypes.size(); r++)
            {
                RouteTypeRule& typeRule = reg->quickGetEncodingRule(pointTypes[r]);
                OAAlarmInfo *info = [OAAlarmInfo createAlarmInfo:typeRule locInd:0 coordinate:loc.coordinate];
                
                // For STOP first check if it has directional info
                // Looks like has no effect here
                //if (info != null && info.getType() != null && info.getType() == AlarmInfoType.STOP) {
                //    if (!ro.isStopApplicable(ro.bearingVsRouteDirection(loc), i)) {
                //        info = null;
                //    }
                //}
                
                if (info)
                {
                    if (info.type != AIT_SPEED_CAMERA || showCameras)
                    {
                        long ms = CACurrentMediaTime() * 1000;
                        if (ms - _announcedAlarmTime > 50 * 1000) {
                            _announcedAlarmTime = ms;
                            [[self getVoiceRouter] announceAlarm:info speed:loc.speed];
                        }
                        return info;
                    }
                }
            }
        }
    }
    return nil;
}

- (BOOL) isRouteCalculated
{
    return _route && ![_route isEmpty];
}

- (NSArray<OALocationPointWrapper *> *) getAllPoints
{
    NSMutableArray<OALocationPointWrapper *> *points = [NSMutableArray array];
    NSMutableArray<NSMutableArray<OALocationPointWrapper *> *> *local = _locationPoints;
    NSMutableArray<NSNumber *> *ps = _pointsProgress;
    for (int i = 0; i < local.count; i++)
    {
        NSMutableArray<OALocationPointWrapper *> *loc = local[i];
        if (ps[i].intValue < loc.count)
            [points addObjectsFromArray:[loc subarrayWithRange:NSMakeRange(ps[i].intValue, loc.count - ps[i].intValue)]];
        
    }
    [self getTargets:points];
    [self sortList:points];
    return points;
}

@end
