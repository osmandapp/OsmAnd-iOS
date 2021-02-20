//
//  OARouteCalculationResult.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARouteCalculationResult.h"
#import "OAAlarmInfo.h"
#import "OARouteDirectionInfo.h"
#import "OARouteCalculationParams.h"
#import "Localization.h"
#import "OALocationServices.h"
#import "OAAppSettings.h"
#import "OARoutingHelper.h"
#import "OAUtilities.h"
#import "QuadRect.h"
#import "OAExitInfo.h"

#define distanceClosestToIntermediate 400.0
#define distanceThresholdToIntroduceFirstAndLastPoints 50

// Evaluates street name that the route follows after turn within specified distance.
// It is useful to find names for short segments on intersections and roundabouts.
#define distanceSeekStreetName 150.0

@implementation OANextDirectionInfo

@end

@implementation OARouteCalculationResult
{
    // could not be null and immodifiable!
    NSMutableArray<CLLocation *> *_locations;
    NSMutableArray<OARouteDirectionInfo *> *_directions;
    std::vector<std::shared_ptr<RouteSegmentResult>> _segments;
    NSMutableArray<NSNumber *> *_listDistance;
    NSMutableArray<NSNumber *> *_intermediatePoints;
    
    int _cacheCurrentTextDirectionInfo;
    NSMutableArray<OARouteDirectionInfo *> *_cacheAgreggatedDirections;
    
    // Note always currentRoute > get(currentDirectionInfo).routeOffset,
    //         but currentRoute <= get(currentDirectionInfo+1).routeOffset
    int _currentDirectionInfo;
    int _nextIntermediate;
    int _currentWaypointGPX;
    int _lastWaypointGPX;
    int _currentStraightAngleRoute;
}


- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _cacheCurrentTextDirectionInfo = -1;
        _locationPoints = [NSMutableArray array];

        _currentDirectionInfo = 0;
        _currentRoute = 0;
        _nextIntermediate = 0;
        _currentWaypointGPX = 0;
        _lastWaypointGPX = 0;
        _routeRecalcDistance = 0;
        _routeVisibleAngle = 0;
        _currentStraightAngleRoute = -1;
    }
    return self;
}

- (instancetype) initWithErrorMessage:(NSString *)errorMessage
{
    self = [[OARouteCalculationResult alloc] init];
    if (self)
    {
        _errorMessage = errorMessage;
        _routingTime = 0;
        _intermediatePoints = [NSMutableArray array];
        _locations = [NSMutableArray array];
        _listDistance = [NSMutableArray array];
        _directions = [NSMutableArray array];
        _alarmInfo = [NSMutableArray array];
    }
    return self;
}

- (NSArray<CLLocation *> *) getRouteLocations
{
    if (_currentRoute < _locations.count)
        return [_locations subarrayWithRange:NSMakeRange(_currentRoute, _locations.count - _currentRoute)];
                                                         
    return [NSArray array];
}

- (std::shared_ptr<RouteSegmentResult>) getCurrentSegmentResult
{
    int cs = _currentRoute > 0 ? _currentRoute - 1 : 0;
    if (cs < _segments.size())
        return _segments[cs];
    
    return nullptr;
}

- (std::shared_ptr<RouteSegmentResult>) getNextStreetSegmentResult
{
    int cs = _currentRoute > 0 ? _currentRoute - 1 : 0;
    while (cs < _segments.size())
    {
        auto segmentResult = _segments[cs];
        string name = segmentResult->object->getName();
        if (!name.empty())
            return segmentResult;

        cs++;
    }
    return nullptr;
}

- (std::vector<std::shared_ptr<RouteSegmentResult>>) getUpcomingTunnel:(float)distToStart
{
    int cs = _currentRoute > 0 ? _currentRoute - 1 : 0;
    if (cs < _segments.size())
    {
        std::shared_ptr<RouteSegmentResult> prev = nullptr;
        BOOL tunnel = NO;
        while (cs < _segments.size() && distToStart > 0)
        {
            auto segment = _segments[cs];
            if (segment != prev )
            {
                if (segment->object->tunnel())
                {
                    tunnel = YES;
                    break;
                }
                else
                {
                    distToStart -= segment->distance;
                    prev = segment;
                }
            }
            cs++;
        }
        if (tunnel)
        {
            std::vector<std::shared_ptr<RouteSegmentResult>> list;
            while (cs < _segments.size())
            {
                auto segment = _segments[cs];
                if (segment != prev )
                {
                    if (segment->object->tunnel())
                        list.push_back(segment);
                    else
                        break;
                    
                    prev = segment;
                }
                cs++;
            }
            return list;
        }
    }
    
    return std::vector<std::shared_ptr<RouteSegmentResult>>();
}

- (float) getCurrentMaxSpeed
{
    auto res = [self getCurrentSegmentResult];
    if (res)
        return res->object->getMaximumSpeed(res->isForwardDirection());
    
    return 0;
}

- (int) getWholeDistance
{
    if (_listDistance.count > 0)
        return _listDistance[0].intValue;
    
    return 0;
}

- (BOOL) isCalculated
{
    return _locations.count > 0;
}

- (BOOL) isEmpty
{
    return _locations.count == 0 || _currentRoute >= _locations.count;
}

- (void) updateCurrentRoute:(int)currentRoute
{
    _currentRoute = currentRoute;
    while (_currentDirectionInfo < _directions.count - 1
           && _directions[_currentDirectionInfo + 1].routePointOffset < currentRoute
           && _directions[_currentDirectionInfo + 1].routeEndPointOffset < currentRoute)
    {
        _currentDirectionInfo++;
    }
    while (_nextIntermediate < _intermediatePoints.count)
    {
        OARouteDirectionInfo *dir = _directions[_intermediatePoints[_nextIntermediate].intValue];
        if (dir.routePointOffset < currentRoute)
            _nextIntermediate ++;
        else
            break;
    }
}

- (void) passIntermediatePoint
{
    _nextIntermediate++;
}

- (int) getNextIntermediate
{
    return _nextIntermediate;
}

- (CLLocation *) getLocationFromRouteDirection:(OARouteDirectionInfo *)i
{
    if (i && _locations && i.routePointOffset < _locations.count)
        return _locations[i.routePointOffset];
    
    return nil;
}

- (OANextDirectionInfo *) getNextRouteDirectionInfo:(OANextDirectionInfo *)info fromLoc:(CLLocation *)fromLoc toSpeak:(BOOL)toSpeak
{
    int dirInfo = _currentDirectionInfo;
    if (dirInfo < _directions.count)
    {
        // Locate next direction of interest
        int nextInd = dirInfo + 1;
        if (toSpeak)
        {
            while (nextInd < _directions.count)
            {
                OARouteDirectionInfo *i = _directions[nextInd];
                if (i.turnType && !i.turnType->isSkipToSpeak())
                    break;
                
                nextInd++;
            }
        }
        int dist = _listDistance[_currentRoute].intValue;
        if (fromLoc)
            dist += [fromLoc distanceFromLocation:_locations[_currentRoute]];
        
        if (nextInd < _directions.count)
        {
            info.directionInfo = _directions[nextInd];
            if (_directions[nextInd].routePointOffset <= _currentRoute
                && _currentRoute <= _directions[nextInd].routeEndPointOffset)
                // We are not into a puntual direction.
                dist -= _listDistance[_directions[nextInd].routeEndPointOffset].intValue;
            else
                dist -= _listDistance[_directions[nextInd].routePointOffset].intValue;
        }
        if (_intermediatePoints && _nextIntermediate < _intermediatePoints.count)
            info.intermediatePoint = _intermediatePoints[_nextIntermediate].intValue == nextInd;
        
        info.directionInfoInd = nextInd;
        info.distanceTo = dist;
        return info;
    }
    info.directionInfoInd = -1;
    info.distanceTo = -1;
    info.directionInfo = nil;
    return nil;
}

- (OANextDirectionInfo *) getNextRouteDirectionInfoAfter:(OANextDirectionInfo *)prev next:(OANextDirectionInfo *)next toSpeak:(BOOL)toSpeak
{
    int dirInfo = prev.directionInfoInd;
    if (dirInfo < _directions.count && prev.directionInfo)
    {
        int dist = _listDistance[prev.directionInfo.routePointOffset].intValue;
        int nextInd = dirInfo + 1;
        if (toSpeak)
        {
            while (nextInd < _directions.count)
            {
                OARouteDirectionInfo *i = _directions[nextInd];
                if (i.turnType && !i.turnType->isSkipToSpeak())
                    break;
                
                nextInd++;
            }
        }
        if (nextInd < _directions.count)
        {
            next.directionInfo = _directions[nextInd];
            dist -= _listDistance[_directions[nextInd].routePointOffset].intValue;
        }
        if (_intermediatePoints && _nextIntermediate < _intermediatePoints.count)
            next.intermediatePoint = _intermediatePoints[_nextIntermediate].intValue == nextInd;
        
        next.distanceTo = dist;
        next.directionInfoInd = nextInd;
        return next;
    }
    next.directionInfoInd = -1;
    next.distanceTo = -1;
    next.directionInfo = nil;
    return nil;
}

- (NSArray<OARouteDirectionInfo *> *) getRouteDirections
{
    if (_currentDirectionInfo < _directions.count - 1)
    {
        if (_cacheCurrentTextDirectionInfo != _currentDirectionInfo)
        {
            _cacheCurrentTextDirectionInfo = _currentDirectionInfo;
            NSArray<OARouteDirectionInfo *> *list = _currentDirectionInfo == 0 ? _directions : [_directions subarrayWithRange:NSMakeRange(_currentDirectionInfo + 1, _directions.count - (_currentDirectionInfo + 1))];
            _cacheAgreggatedDirections = [NSMutableArray array];
            OARouteDirectionInfo *p = nil;
            for (OARouteDirectionInfo *i in list)
            {
                //					if(p == null || !i.getTurnType().isSkipToSpeak() ||
                //							(!Algorithms.objectEquals(p.getRef(), i.getRef()) &&
                //									!Algorithms.objectEquals(p.getStreetName(), i.getStreetName()))) {
                if (!p || (i.turnType && !i.turnType->isSkipToSpeak()))
                {
                    p = [[OARouteDirectionInfo alloc] initWithAverageSpeed:i.averageSpeed turnType:i.turnType];
                    p.routePointOffset = i.routePointOffset;
                    p.routeEndPointOffset = i.routeEndPointOffset;
                    p.routeDataObject = i.routeDataObject;
                    p.destinationName = i.destinationName;
                    p.routeDataObject = i.routeDataObject;
                    p.ref = i.ref;
                    p.streetName = i.streetName;
                    [p setDescriptionRoute:[i getDescriptionRoutePart]];
                    [_cacheAgreggatedDirections addObject:p];
                }
                float time = [i getExpectedTime] + [p getExpectedTime];
                p.distance += i.distance;
                p.averageSpeed = (p.distance / time);
                p.afterLeftTime = i.afterLeftTime;
            }
        }
        return _cacheAgreggatedDirections;
    }
    return [NSArray array];
}

- (CLLocation *) getNextRouteLocation
{
    if (_currentRoute < _locations.count)
        return _locations[_currentRoute];
    
    return nil;
}

- (int) getDistanceToPoint:(int)locationIndex
{
    if (_listDistance && _currentRoute < _listDistance.count && locationIndex < _listDistance.count &&
       locationIndex > _currentRoute)
        return _listDistance[_currentRoute].intValue - _listDistance[locationIndex].intValue;
    
    return 0;
}

- (int) getDistanceToFinish:(CLLocation *)fromLoc
{
    CLLocation *ap = _currentStraightAnglePoint;
    int rp = MAX(_currentStraightAngleRoute, _currentRoute);
    if (_listDistance && rp < _listDistance.count)
    {
        int dist = _listDistance[rp].intValue;
        CLLocation *l = _locations[rp];
        if (ap)
        {
            if (fromLoc)
                dist += [fromLoc distanceFromLocation:ap];
            dist += [ap distanceFromLocation:l];
        }
        else if (fromLoc)
        {
            dist += [fromLoc distanceFromLocation:l];
        }
        return dist;
    }
    return 0;
}

- (void) updateNextVisiblePoint:(int) nextPoint location:(CLLocation *) mp
{
    _currentStraightAnglePoint = mp;
    _currentStraightAngleRoute = nextPoint;
}

- (int) getDistanceFromPoint:(int) locationIndex
{
    if(_listDistance && locationIndex < _listDistance.count) {
        return [_listDistance[locationIndex] intValue];
    }
    return 0;
}

- (BOOL) isPointPassed:(int)locationIndex
{
    return locationIndex < _currentRoute;
}

- (int) getListDistance:(int)index
{
    return _listDistance.count > index ? _listDistance[index].intValue : 0;
}

- (int) getDistanceToNextIntermediate:(CLLocation *)fromLoc
{
    int dist = [self getDistanceToFinish:fromLoc];
    if (_listDistance && _currentRoute < _listDistance.count)
    {
        if (_nextIntermediate >= _intermediatePoints.count)
        {
            return 0;
        }
        else
        {
            int directionInd = _intermediatePoints[_nextIntermediate].intValue;
            return dist - [self getListDistance:_directions[directionInd].routePointOffset];
        }
    }
    return 0;
}

- (int) getIndexOfIntermediate:(int)countFromLast
{
    int j = (int)_intermediatePoints.count - countFromLast - 1;
    if (j < _intermediatePoints.count && j >= 0)
    {
        int i = _intermediatePoints[j].intValue;
        return _directions[i].routePointOffset;
    }
    return -1;
}

- (int) getIntermediatePointsToPass
{
    if (_nextIntermediate >= _intermediatePoints.count)
        return 0;
    
    return (int)_intermediatePoints.count - _nextIntermediate;
}

- (int) getLeftTime:(CLLocation *)fromLoc
{
    int time = 0;
    if (_currentDirectionInfo < _directions.count)
    {
        OARouteDirectionInfo *current = _directions[_currentDirectionInfo];
        time = current.afterLeftTime;
        
        int distanceToNextTurn = _listDistance[_currentRoute].intValue;
        if (_currentDirectionInfo + 1 < _directions.count)
            distanceToNextTurn -= _listDistance[_directions[_currentDirectionInfo + 1].routePointOffset].intValue;
        
        CLLocation *l = _locations[_currentRoute];
        if (fromLoc)
            distanceToNextTurn += [fromLoc distanceFromLocation:l];
        
        if (!isnan(current.averageSpeed))
            time += distanceToNextTurn / current.averageSpeed;
    }
    return time;
}

- (int) getLeftTimeToNextIntermediate:(CLLocation *)fromLoc
{
    if (_nextIntermediate >= _intermediatePoints.count)
        return 0;
    
    return [self getLeftTime:fromLoc] - _directions[_intermediatePoints[_nextIntermediate].intValue].afterLeftTime;
}

- (NSArray<CLLocation *> *) getImmutableAllLocations
{
    return [NSArray arrayWithArray:_locations];
}

- (NSArray<OARouteDirectionInfo *> *) getImmutableAllDirections
{
    return [NSArray arrayWithArray:_directions];
}

- (std::vector<std::shared_ptr<RouteSegmentResult>>) getOriginalRoute
{
    return [self getOriginalRoute:0];
}

- (std::vector<std::shared_ptr<RouteSegmentResult>>) getOriginalRoute:(int)startIndex
{
    if (_segments.size() == 0)
        return std::vector<std::shared_ptr<RouteSegmentResult>>();
    
    std::vector<std::shared_ptr<RouteSegmentResult>> list;
    list.push_back(_segments[startIndex++]);
    for (int i = startIndex; i < _segments.size(); i++)
        if (_segments[i - 1] != _segments[i])
            list.push_back(_segments[i]);
    
    return list;
}

/**
 * PREPARATION
 * Check points for duplicates (it is very bad for routing) - cloudmade could return it
 */
+ (void) checkForDuplicatePoints:(NSMutableArray<CLLocation *> *)locations directions:(NSMutableArray<OARouteDirectionInfo *> *)directions
{
    for (int i = 0; i < locations.count - 1;)
    {
        if ([locations[i] distanceFromLocation:locations[i + 1]] == 0)
        {
            [locations removeObjectAtIndex:i];
            if (directions)
            {
                for (OARouteDirectionInfo *info in directions)
                {
                    if (info.routePointOffset > i)
                        info.routePointOffset--;
                }
            }
        }
        else
        {
            i++;
        }
    }
}

/**
 * PREPARATION
 * Remove unnecessary go straight from CloudMade.
 * Remove also last direction because it will be added after.
 */
- (void) removeUnnecessaryGoAhead:(NSMutableArray<OARouteDirectionInfo *> *)directions
{
    if (directions && directions.count > 1)
    {
        for (int i = 1; i < directions.count;)
        {
            OARouteDirectionInfo *r = directions[i];
            if (r.turnType->getValue() == TurnType::C)
            {
                OARouteDirectionInfo *prev = directions[i - 1];
                prev.averageSpeed = ((prev.distance + r.distance) / (prev.distance / prev.averageSpeed + r.distance / r.averageSpeed));
                prev.distance = prev.distance + r.distance;
                [directions removeObjectAtIndex:i];
            }
            else
            {
                i++;
            }
        }
    }
}

+ (void) addMissingTurnsToRoute:(NSArray<CLLocation *> *)locations originalDirections:(NSMutableArray<OARouteDirectionInfo *> *)originalDirections start:(CLLocation *)start end:(CLLocation *)end mode:(OAApplicationMode *)mode leftSide:(BOOL)leftSide
{
    if (locations.count == 0)
        return;
    
    // speed m/s
    float speed = [mode getDefaultSpeed];
    NSInteger minDistanceForTurn = mode.getMinDistanceForTurn;
    NSMutableArray<OARouteDirectionInfo *> *computeDirections = [NSMutableArray array];
    
    NSMutableArray<NSNumber *> *listDistance = [NSMutableArray arrayWithObject:@(0) count:locations.count];
    listDistance[locations.count - 1] = @(0);
    for (int i = (int)locations.count - 1; i > 0; i--)
    {
        listDistance[i - 1] = [NSNumber numberWithInt:round([locations[i - 1] distanceFromLocation:locations[i]])];
        listDistance[i - 1] = [NSNumber numberWithInt:[listDistance[i - 1] intValue] + [listDistance[i] intValue]];
    }
    
    int previousLocation = 0;
    int prevBearingLocation = 0;
    OARouteDirectionInfo *previousInfo = [[OARouteDirectionInfo alloc] initWithAverageSpeed:speed turnType:TurnType::ptrStraight()];
    previousInfo.routePointOffset = 0;
    previousInfo.descriptionRoute = OALocalizedString(@"route_head");
    [computeDirections addObject:previousInfo];
    
    int distForTurn = 0;
    double previousBearing = 0;
    int startTurnPoint = 0;
    
    for (int i = 1; i < locations.count - 1; i++)
    {
        CLLocation *next = locations[i + 1];
        CLLocation *current = locations[i];
        double bearing = [current bearingTo:next];
        // try to get close to current location if possible
        while (prevBearingLocation < i - 1)
        {
            if ([locations[prevBearingLocation + 1] distanceFromLocation:current] > 70) {
                prevBearingLocation++;
            } else {
                break;
            }
        }
        
        if (distForTurn == 0)
        {
            // measure only after turn
            previousBearing = [locations[prevBearingLocation] bearingTo:current];
            startTurnPoint = i;
        }
        
        std::shared_ptr<TurnType> type = nullptr;
        NSString *description = nil;
        float delta = previousBearing - bearing;
        while (delta < 0) {
            delta += 360;
        }
        while (delta > 360) {
            delta -= 360;
        }
        
        distForTurn += [locations[i] distanceFromLocation:locations[i + 1]];
        if (i < locations.count - 1 &&  distForTurn < minDistanceForTurn)
        {
            // For very smooth turn we try to accumulate whole distance
            // simply skip that turn needed for situation
            // 1) if you are going to have U-turn - not 2 left turns
            // 2) if there is a small gap between roads (turn right and after 4m next turn left) - so the direction head
            continue;
        }
        
        if (delta > 45 && delta < 315)
        {
            if (delta < 60)
            {
                type = TurnType::ptrValueOf(TurnType::TSLL, leftSide);
                description = OALocalizedString(@"route_tsll");
            }
            else if (delta < 120)
            {
                type = TurnType::ptrValueOf(TurnType::TL, leftSide);
                description = OALocalizedString(@"route_tl");
            }
            else if (delta < 150)
            {
                type = TurnType::ptrValueOf(TurnType::TSHL, leftSide);
                description = OALocalizedString(@"route_tshl");
            }
            else if (delta < 180)
            {
                if (leftSide)
                {
                    type = TurnType::ptrValueOf(TurnType::TSHL, leftSide);
                    description = OALocalizedString(@"route_tshl");
                }
                else
                {
                    type = TurnType::ptrValueOf(TurnType::TU, leftSide);
                    description = OALocalizedString(@"route_tu");
                }
            }
            else if (delta == 180)
            {
                type = TurnType::ptrValueOf(TurnType::TU, leftSide);
                description = OALocalizedString(@"route_tu");
            }
            else if (delta < 210)
            {
                if(leftSide) {
                    type = TurnType::ptrValueOf(TurnType::TU, leftSide);
                    description = OALocalizedString(@"route_tu");
                } else {
                    description = OALocalizedString(@"route_tshr");
                    type = TurnType::ptrValueOf(TurnType::TSHR, leftSide);
                }
            }
            else if (delta < 240)
            {
                description = OALocalizedString(@"route_tshr");
                type = TurnType::ptrValueOf(TurnType::TSHR, leftSide);
            }
            else if (delta < 300)
            {
                description = OALocalizedString(@"route_tr");
                type = TurnType::ptrValueOf(TurnType::TR, leftSide);
            }
            else
            {
                description = OALocalizedString(@"route_tslr");
                type = TurnType::ptrValueOf(TurnType::TSLR, leftSide);
            }
            
            // calculate for previousRoute
            previousInfo.distance = [listDistance[previousLocation] intValue] - [listDistance[i] intValue];
            type->setTurnAngle(360 - delta);
            previousInfo = [[OARouteDirectionInfo alloc] initWithAverageSpeed:speed turnType:type];
            previousInfo.descriptionRoute = description;
            previousInfo.routePointOffset = startTurnPoint;
            [computeDirections addObject:previousInfo];
            previousLocation = startTurnPoint;
            prevBearingLocation = i; // for bearing using current location
        }
        // clear dist for turn
        distForTurn = 0;
    }
    
    previousInfo.distance = [listDistance[previousLocation] intValue];
    if (originalDirections.count == 0)
    {
        [originalDirections addObjectsFromArray:computeDirections];
    }
    else
    {
        int currentDirection = 0;
        // one more
        for (int i = 0; i <= originalDirections.count && currentDirection < computeDirections.count; i++)
        {
            while (currentDirection < computeDirections.count) {
                int distanceAfter = 0;
                if (i < originalDirections.count) {
                    OARouteDirectionInfo *resInfo = originalDirections[i];
                    int r1 = computeDirections[currentDirection].routePointOffset;
                    int r2 = resInfo.routePointOffset;
                    distanceAfter = [listDistance[resInfo.routePointOffset] intValue];
                    float dist = [locations[r1] distanceFromLocation:locations[r2]];
                    // take into account that move roundabout is special turn that could be very lengthy
                    if (dist < 100)
                    {
                        // the same turn duplicate
                        currentDirection++;
                        continue; // while cycle
                    }
                    else if (computeDirections[currentDirection].routePointOffset > resInfo.routePointOffset)
                    {
                        // check it at the next point
                        break;
                    }
                }
                
                // add turn because it was missed
                OARouteDirectionInfo *toAdd = computeDirections[currentDirection];
                
                if (i > 0) {
                    // update previous
                    OARouteDirectionInfo *previous = originalDirections[i - 1];
                    toAdd.averageSpeed = previous.averageSpeed;
                }
                toAdd.distance = [listDistance[toAdd.routePointOffset] intValue] - distanceAfter;
                if (i < originalDirections.count) {
                    [originalDirections insertObject:toAdd atIndex:i];
                } else {
                    [originalDirections addObject:toAdd];
                }
                i++;
                currentDirection++;
            }
        }
    }
    
    int sum = 0;
    for (int i = (int)originalDirections.count - 1; i >= 0; i--)
    {
        originalDirections[i].afterLeftTime = sum;
        sum += [originalDirections[i] getExpectedTime];
    }
}

/**
 * PREPARATION
 * If beginning is too far from start point, then introduce GO Ahead
 * @param end
 */
+ (void) introduceFirstPointAndLastPoint:(NSMutableArray<CLLocation *> *)locations directions:(NSMutableArray<OARouteDirectionInfo *> *)directions segs:(std::vector<std::shared_ptr<RouteSegmentResult>>&)segs start:(CLLocation *)start end:(CLLocation *)end
{
    BOOL firstPointIntroduced = [self.class introduceFirstPoint:locations directions:directions segments:segs start:start];
    BOOL lastPointIntroduced = [self.class introduceLastPoint:locations directions:directions segments:segs end:end];
    if (firstPointIntroduced || lastPointIntroduced)
        [self.class checkForDuplicatePoints:locations directions:directions];
    
    OARouteDirectionInfo *lastDirInf = directions.count > 0 ? directions[directions.count - 1] : nil;
    if ((!lastDirInf || lastDirInf.routePointOffset < locations.count - 1) && locations.count - 1 > 0)
    {
        int type = TurnType::C;
        CLLocation *prevLast = locations[locations.count - 2];
        double lastBearing = [prevLast bearingTo:locations[locations.count - 1]];
        double bearingToEnd = [prevLast bearingTo:end];
        double diff = degreesDiff(lastBearing, bearingToEnd);
        if(abs(diff) > 10)
            type = diff > 0 ? TurnType::KL : TurnType::KR;
        
        // Wrong AvgSpeed for the last turn can cause significantly wrong total travel time if calculated route ends on a GPX route segment (then last turn is where GPX is joined again)
        OARouteDirectionInfo *info = [[OARouteDirectionInfo alloc] initWithAverageSpeed:lastDirInf ? lastDirInf.averageSpeed : 1 turnType:TurnType::ptrValueOf(type, false)];
        if (!segs.empty())
        {
            auto lastSegmentResult = segs[segs.size() - 1];
            auto routeDataObject = lastSegmentResult->object;
            
            NSString *lang = [[OAAppSettings sharedManager] settingPrefMapLanguage];
            if (!lang)
                lang = [OAUtilities currentLang];
            
            auto locale = std::string([lang UTF8String]);
            BOOL transliterate = [OAAppSettings sharedManager].settingMapLanguageTranslit;
            info.routeDataObject = routeDataObject;
            info.ref = [NSString stringWithUTF8String:routeDataObject->getRef(locale, transliterate, lastSegmentResult->isForwardDirection()).c_str()];
            info.streetName = [NSString stringWithUTF8String:routeDataObject->getName(locale, transliterate).c_str()];
            info.destinationName = [NSString stringWithUTF8String:routeDataObject->getDestinationName(locale, transliterate, lastSegmentResult->isForwardDirection()).c_str()];
        }
        info.distance = 0;
        info.afterLeftTime = 0;
        info.routePointOffset = (int)locations.count - 1;
        [directions addObject:info];
    }
}

+ (BOOL) introduceFirstPoint:(NSMutableArray<CLLocation *> *)locations directions:(NSMutableArray<OARouteDirectionInfo *> *)directions segments:(std::vector<std::shared_ptr<RouteSegmentResult>>&)segs start:(CLLocation *)start
{
    if (locations.count > 0 && [locations[0] distanceFromLocation:start] > distanceThresholdToIntroduceFirstAndLastPoints)
    {
        // add start point
        [locations insertObject:start atIndex:0];
        if (segs.size() > 0)
        {
            segs.insert(segs.begin(), segs[0]);
        }
        if (directions && directions.count > 0)
        {
            for (OARouteDirectionInfo *i in directions)
            {
                i.routePointOffset++;
            }
            OARouteDirectionInfo *info = [[OARouteDirectionInfo alloc] initWithAverageSpeed:directions[0].averageSpeed turnType:TurnType::ptrStraight()];
            info.routePointOffset = 0;
            // info.setDescriptionRoute(ctx.getString( R.string.route_head));//; //$NON-NLS-1$
            [directions insertObject:info atIndex:0];
        }
        return YES;
    }
    return NO;
}

+ (BOOL) introduceLastPoint:(NSMutableArray<CLLocation *> *)locations directions:(NSMutableArray<OARouteDirectionInfo *> *)directions segments:(std::vector<std::shared_ptr<RouteSegmentResult>>&)segs end:(CLLocation *)end
{
    if (locations.count > 0)
    {
        CLLocation *lastFoundLocation = locations[locations.count - 1];

        CLLocation *endLocation = [[CLLocation alloc] initWithLatitude:end.coordinate.latitude longitude:end.coordinate.longitude];

        if ([lastFoundLocation distanceFromLocation:endLocation] > distanceThresholdToIntroduceFirstAndLastPoints)
        {
            if (directions && directions.count > 0)
            {
                if (locations.count > 2)
                {
                    int type = TurnType::C;
                    CLLocation *prevLast = locations[locations.count - 2];
                    double lastBearing = [prevLast bearingTo:lastFoundLocation];
                    double bearingToEnd = [lastFoundLocation bearingTo:endLocation];
                    double diff = degreesDiff(lastBearing, bearingToEnd);
                    if (abs(diff) > 10)
                    {
                        if (abs(diff) < 60)
                        {
                            type = diff > 0 ? TurnType::TSLL : TurnType::TSLR;
                        }
                        else
                        {
                            type = diff > 0 ? TurnType::TL : TurnType::TR;
                        }
                    }

                    OARouteDirectionInfo *lastDirInf = directions[directions.count - 1];
                    OARouteDirectionInfo *info = [[OARouteDirectionInfo alloc] initWithAverageSpeed:lastDirInf ? lastDirInf.averageSpeed : 1 turnType:std::make_shared<TurnType>(TurnType::valueOf(type, false))];
                    info.routePointOffset = (int) locations.count - 1;
                    [directions addObject:info];
                }
            }
            // add end point
            [locations addObject:endLocation];
            if (segs.size() > 0)
            {
                segs.push_back(segs[segs.size() - 1]);
            }
            return YES;
        }
    }
    return NO;
}

/**
 * PREPARATION
 * At the end always update listDistance local vars and time
 */
+ (void) updateListDistanceTime:(NSMutableArray<NSNumber *> *)listDistance locations:(NSArray<CLLocation *> *)locations
{
    if (listDistance.count > 0)
    {
        listDistance[locations.count - 1] = @0;
        for (int i = (int)locations.count - 1; i > 0; i--)
        {
            listDistance[i - 1] = @((int) round([locations[i - 1] distanceFromLocation:locations[i]]));
            listDistance[i - 1] = @(listDistance[i - 1].intValue + listDistance[i].intValue);
        }
    }
}

/**
 * PREPARATION
 * At the end always update listDistance local vars and time
 */
+ (void) updateDirectionsTime:(NSMutableArray<OARouteDirectionInfo *> *)directions listDistance:(NSMutableArray<NSNumber *> *)listDistance
{
    int sum = 0;
    for (int i = (int)directions.count - 1; i >= 0; i--)
    {
        directions[i].afterLeftTime = sum;
        directions[i].distance = listDistance[directions[i].routePointOffset].intValue;
        if (i < directions.count - 1) {
            directions[i].distance -= listDistance[directions[i + 1].routePointOffset].intValue;
        }
        sum += [directions[i] getExpectedTime];
    }
}

+ (double) getDistanceToLocation:(NSArray<CLLocation *> *)locations p:(CLLocation *)p currentLocation:(int)currentLocation
{
    return [p distanceFromLocation:[[CLLocation alloc] initWithLatitude:locations[currentLocation].coordinate.latitude longitude:locations[currentLocation].coordinate.longitude]];
}

+ (void) calculateIntermediateIndexes:(NSArray<CLLocation *> *)locations intermediates:(NSArray<CLLocation *> *)intermediates localDirections:(NSMutableArray<OARouteDirectionInfo *> *)localDirections intermediatePoints:(NSMutableArray<NSNumber *> *)intermediatePoints
{
    if (intermediates && localDirections)
    {
        NSMutableArray<NSNumber *> *interLocations = [NSMutableArray arrayWithObject:@(0) count:intermediates.count];
        int currentIntermediate = 0;
        int currentLocation = 0;
        double distanceThreshold = 25;
        double prevDistance = distanceThreshold * 4;
        while((currentIntermediate < intermediates.count || prevDistance > distanceThreshold) && currentLocation < locations.count)
        {
            if (currentIntermediate < intermediates.count &&
                [self.class getDistanceToLocation:locations p:intermediates[currentIntermediate] currentLocation:currentLocation] < distanceClosestToIntermediate)
            {
                prevDistance = [self.class getDistanceToLocation:locations p:intermediates[currentIntermediate] currentLocation:currentLocation];
                interLocations[currentIntermediate] = @(currentLocation);
                currentIntermediate++;
            } else if (currentIntermediate > 0 && prevDistance > distanceThreshold && [self.class getDistanceToLocation:locations p:intermediates[currentIntermediate - 1] currentLocation:currentLocation] < prevDistance)
            {
                prevDistance = [self.class getDistanceToLocation:locations p:intermediates[currentIntermediate - 1] currentLocation:currentLocation];
                interLocations[currentIntermediate - 1] = @(currentLocation);
            }
            currentLocation ++;
        }
        int currentDirection = 0;
        currentIntermediate = 0;
        while (currentIntermediate < intermediates.count && currentDirection < localDirections.count)
        {
            int locationIndex = localDirections[currentDirection].routePointOffset;
            if (locationIndex >= interLocations[currentIntermediate].intValue)
            {
                // split directions
                if (locationIndex > interLocations[currentIntermediate].intValue && [self.class getDistanceToLocation:locations p:intermediates[currentIntermediate] currentLocation:locationIndex] > 50)
                {
                    OARouteDirectionInfo *toSplit = localDirections[currentDirection];
                    OARouteDirectionInfo *info = [[OARouteDirectionInfo alloc] initWithAverageSpeed:localDirections[currentDirection].averageSpeed turnType:TurnType::ptrStraight()];
                    info.ref = toSplit.ref;
                    info.streetName = toSplit.streetName;
                    info.routeDataObject = toSplit.routeDataObject;
                    info.destinationName = toSplit.destinationName;
                    info.routePointOffset = interLocations[currentIntermediate].intValue;
                    info.descriptionRoute = OALocalizedString(@"route_head");
                    [localDirections insertObject:info atIndex:currentDirection];
                }
                intermediatePoints[currentIntermediate] = @(currentDirection);
                currentIntermediate++;
            }
            currentDirection ++;
        }
    }
}

+ (void) attachAlarmInfo:(NSMutableArray<OAAlarmInfo *> *)alarms res:(std::shared_ptr<RouteSegmentResult>)res intId:(int)intId locInd:(int)locInd
{
    if (res->object->pointTypes.size() > intId) {
        const auto& pointTypes = res->object->pointTypes[intId];
        auto reg = res->object->region;
        for (int r = 0; r < pointTypes.size(); r++) {
            auto& typeRule = reg->quickGetEncodingRule(pointTypes[r]);
            auto x31 = res->object->pointsX[intId];
            auto y31 = res->object->pointsY[intId];
            CLLocation *loc = [[CLLocation alloc] initWithLatitude:get31LatitudeY(y31) longitude:get31LongitudeX(x31)];
            OAAlarmInfo *info = [OAAlarmInfo createAlarmInfo:typeRule locInd:locInd coordinate:loc.coordinate];
            // For STOP first check if it has directional info
            if (info && !(info.type == AIT_STOP && !res->object->isStopApplicable(res->isForwardDirection(), intId, res->getStartPointIndex(), res->getEndPointIndex()))) 
                [alarms addObject:info];
        }
    }
}

- (QuadRect *) getLocationsRect
{
    double left = 0, right = 0;
    double top = 0, bottom = 0;
    for (CLLocation *p in [self getImmutableAllLocations])
    {
        if (left == 0 && right == 0)
        {
            left = p.coordinate.longitude;
            right = p.coordinate.longitude;
            top = p.coordinate.latitude;
            bottom = p.coordinate.latitude;
        }
        else
        {
            left = MIN(left, p.coordinate.longitude);
            right = MAX(right, p.coordinate.longitude);
            top = MAX(top, p.coordinate.latitude);
            bottom = MIN(bottom, p.coordinate.latitude);
        }
    }
    return left == 0 && right == 0 ? nil : [[QuadRect alloc] initWithLeft:left top:top right:right bottom:bottom];
}

+ (NSString *) toString:(std::shared_ptr<TurnType>)type shortName:(BOOL)shortName
{
    if (type->isRoundAbout())
    {
        if (shortName) {
            return [NSString stringWithFormat:OALocalizedString(@"route_roundabout_short"), type->getExitOut()];
        } else {
            return [NSString stringWithFormat:OALocalizedString(@"route_roundabout"), type->getExitOut()];
        }
    } else if (type->getValue() == TurnType::C) {
        return OALocalizedString(@"route_head");
    } else if (type->getValue() == TurnType::TSLL) {
        return OALocalizedString(@"route_tsll");
    } else if (type->getValue() == TurnType::TL) {
        return OALocalizedString(@"route_tl");
    } else if (type->getValue() == TurnType::TSHL) {
        return OALocalizedString(@"route_tshl");
    } else if (type->getValue() == TurnType::TSLR) {
        return OALocalizedString(@"route_tslr");
    } else if (type->getValue() == TurnType::TR) {
        return OALocalizedString(@"route_tr");
    } else if (type->getValue() == TurnType::TSHR) {
        return OALocalizedString(@"route_tshr");
    } else if (type->getValue() == TurnType::TU) {
        return OALocalizedString(@"route_tu");
    } else if (type->getValue() == TurnType::TRU) {
        return OALocalizedString(@"route_tu");
    } else if (type->getValue() == TurnType::KL) {
        return OALocalizedString(@"route_kl");
    } else if (type->getValue() == TurnType::KR) {
        return OALocalizedString(@"route_kr");
    }
    return @"";
}

/**
 * PREPARATION
 */
+ (std::vector<std::shared_ptr<RouteSegmentResult>>) convertVectorResult:(NSMutableArray<OARouteDirectionInfo *> *)directions locations:(NSMutableArray<CLLocation *> *)locations list:(std::vector<std::shared_ptr<RouteSegmentResult>>&)list alarms:(NSMutableArray<OAAlarmInfo *> *)alarms
{
    float prevDirectionTime = 0;
    float prevDirectionDistance = 0;
    double lastHeight = RouteDataObject::HEIGHT_UNDEFINED;
    std::vector<std::shared_ptr<RouteSegmentResult>> segmentsToPopulate;
    OAAlarmInfo *tunnelAlarm = nil;
    for (int routeInd = 0; routeInd < list.size(); routeInd++)
    {
        auto s = list[routeInd];
        const auto& vls = s->object->calculateHeightArray();
        BOOL plus = s->getStartPointIndex() < s->getEndPointIndex();
        int i = s->getStartPointIndex();
        int prevLocationSize = (int)locations.count;
        if (s->object->tunnel())
        {
            if (!tunnelAlarm)
            {
                auto lat = get31LatitudeY(s->object->pointsY[i]);
                auto lon = get31LongitudeX(s->object->pointsX[i]);
                tunnelAlarm = [[OAAlarmInfo alloc] initWithType:AIT_TUNNEL locationIndex:prevLocationSize];
                tunnelAlarm.coordinate = CLLocationCoordinate2DMake(lat, lon);
                tunnelAlarm.floatValue = s->distance;
                [alarms addObject:tunnelAlarm];
            }
            else
            {
                tunnelAlarm.floatValue = tunnelAlarm.floatValue + s->distance;
            }
        }
        else
        {
            if (tunnelAlarm)
                tunnelAlarm.lastLocationIndex = (int)locations.count;

            tunnelAlarm = nil;
        }
        while (true)
        {
            if (i == s->getEndPointIndex() && routeInd != list.size() - 1)
                break;
            auto lat = get31LatitudeY(s->object->pointsY[i]);
            auto lon = get31LongitudeX(s->object->pointsX[i]);
            
            NSNumber *alt = nil;
            if (i * 2 + 1 < vls.size())
            {
                float h = vls[2 * i + 1];
                alt = @(h);
                if (lastHeight == RouteDataObject::HEIGHT_UNDEFINED && locations.count > 0) {
                    
                    for (int i = 0; i < locations.count; i++)
                    {
                        CLLocation *l = locations[i];
                        if (l.verticalAccuracy < 0) {
                            locations[i] = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(l.coordinate.latitude, l.coordinate.longitude) altitude:h horizontalAccuracy:0 verticalAccuracy:0 course:l.course speed:l.speed timestamp:l.timestamp];
                        }
                    }
                }
                lastHeight = h;
            }
            // FIXME: investigate gpx file
            if (s->object->pointsX[i] == 0 && s->object->pointsY[i] == 0)
            {
                if (locations.count > 0)
                {
                    CLLocation *prev = locations[locations.count - 1];
                    lat = prev.coordinate.latitude;
                    lon = prev.coordinate.longitude;
                    if (prev.altitude)
                        alt = @(prev.altitude);
                }
            }
            [locations addObject:[[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(lat, lon) altitude:alt? alt.doubleValue : NAN horizontalAccuracy:0 verticalAccuracy:0 timestamp:[NSDate date]]];

            [self.class attachAlarmInfo:alarms res:s intId:i locInd:(int)locations.count];
            segmentsToPopulate.push_back(s);
            if (i == s->getEndPointIndex())
                break;
            
            if (plus)
                i++;
            else
                i--;
        }
        auto turn = s->turnType;
        
        if (turn)
        {
            OARouteDirectionInfo *info = [[OARouteDirectionInfo alloc] initWithAverageSpeed:s->segmentSpeed turnType:turn];
            if (routeInd < list.size())
            {
                int lind = routeInd;
                if (turn->isRoundAbout())
                {
                    int roundAboutEnd = prevLocationSize ;
                    // take next name for roundabout (not roundabout name)
                    while (lind < list.size() - 1 && list[lind]->object->roundabout())
                    {
                        roundAboutEnd += abs(list[lind]->getEndPointIndex() - list[lind]->getStartPointIndex());
                        lind++;
                    }
                    // Consider roundabout end.
                    info.routeEndPointOffset = roundAboutEnd;
                }
                auto next = list[lind];
                
                NSString *lang = [[OAAppSettings sharedManager] settingPrefMapLanguage];
                if (!lang)
                    lang = [OAUtilities currentLang];
                
                auto locale = std::string([lang UTF8String]);
                BOOL transliterate = [OAAppSettings sharedManager].settingMapLanguageTranslit;
                
                NSString *ref = [NSString stringWithUTF8String:next->object->getRef(locale,
                                            transliterate, next->isForwardDirection()).c_str()];
                info.ref = ref;
                NSString *streetName = [NSString stringWithUTF8String:next->object->getName(locale,
                                            transliterate).c_str()];
                if (streetName.length == 0)
                {
                    // try to get street names from following segments
                    float distanceFromTurn = next->distance;
                    for (int n = lind + 1; n + 1 < list.size(); n++)
                    {
                        const auto& s1 = list[n];
                        // scan the list only until the next turn
                        if (s1->turnType != nullptr || distanceFromTurn > distanceSeekStreetName || streetName.length > 0)
                            break;

                        streetName = [NSString stringWithUTF8String:s1->object->getName(locale, transliterate).c_str()];
                        distanceFromTurn += s1->distance;
                    }
                }
                
                info.streetName = streetName;
                info.destinationName = [NSString stringWithUTF8String:next->object->getDestinationName(locale, transliterate, next->isForwardDirection()).c_str()];
                if (s->object->isExitPoint() && next->object->getHighway() == "motorway_link")
                {
                    OAExitInfo *exitInfo = [[OAExitInfo alloc] init];
                    exitInfo.ref = [NSString stringWithUTF8String:next->object->getExitRef().c_str()];
                    exitInfo.exitStreetName = [NSString stringWithUTF8String:next->object->getExitName().c_str()];
                    info.exitInfo = exitInfo;
                }
                
                if (ref)
                {
                    const auto& nextRoad = next->object;
                    info.routeDataObject = nextRoad;
                    
                    BOOL isNextShieldFound = nextRoad->hasNameTagStartsWith("road_ref");
                    for (int ind = lind; ind < list.size() && !isNextShieldFound; ind++) {
                        if (list[ind]->turnType != nullptr)
                        {
                            isNextShieldFound = YES;
                        } else {
                            const auto& obj = list[ind]->object;
                            if (obj->hasNameTagStartsWith("road_ref"))
                            {
                                info.routeDataObject = obj;
                                isNextShieldFound = YES;
                            }
                        }
                    }
                }
            }
            
            NSString *description = [[NSString stringWithFormat:@"%@ %@", [self.class toString:turn shortName:false],  [OARoutingHelper formatStreetName:info.streetName ref:info.ref destination:info.destinationName towards:OALocalizedString(@"towards")]] trim];
            
            if (s->object->pointNames.size() > s->getStartPointIndex())
            {
                const auto& pointNames = s->object->pointNames[s->getStartPointIndex()];
                if (!pointNames.empty())
                {
                    for (int t = 0; t < pointNames.size(); t++)
                    {
                        description = [description trim];
                        description = [description stringByAppendingString:[NSString stringWithFormat:@" %@", [NSString stringWithUTF8String:pointNames[t].c_str()]]];
                    }
                }
            }
            info.descriptionRoute = description;
            info.routePointOffset = prevLocationSize;
            if (directions.count > 0 && prevDirectionTime > 0 && prevDirectionDistance > 0)
            {
                OARouteDirectionInfo *prev = directions[directions.count - 1];
                prev.averageSpeed = (prevDirectionDistance / prevDirectionTime);
                prevDirectionDistance = 0;
                prevDirectionTime = 0;
            }
            [directions addObject:info];
        }
        prevDirectionDistance += s->distance;
        prevDirectionTime += s->segmentTime;
    }
    if (directions.count > 0 && prevDirectionTime > 0 && prevDirectionDistance > 0)
    {
        OARouteDirectionInfo *prev = directions[directions.count - 1];
        prev.averageSpeed = (prevDirectionDistance / prevDirectionTime);
    }
    return segmentsToPopulate;
}

- (instancetype) initWithLocations:(NSArray<CLLocation *> *)list directions:(NSArray<OARouteDirectionInfo *> *)directions params:(OARouteCalculationParams *)params waypoints:(NSArray<id<OALocationPoint>> *)waypoints addMissingTurns:(BOOL)addMissingTurns
{
    self = [[OARouteCalculationResult alloc] init];
    if (self)
    {
        _routingTime = 0;
        _errorMessage = nil;
        _intermediatePoints = [NSMutableArray arrayWithObject:@(0) count:params.intermediates.count];
        NSMutableArray<CLLocation *> *locations = [NSMutableArray arrayWithArray:list];
        NSMutableArray<OARouteDirectionInfo *> *localDirections = [NSMutableArray arrayWithArray:directions];
        if (locations.count > 0)
            [self.class checkForDuplicatePoints:locations directions:localDirections];
        
        if (waypoints) {
            [_locationPoints addObjectsFromArray:waypoints];
        }
        if (addMissingTurns)
        {
            [self removeUnnecessaryGoAhead:localDirections];
            [self.class addMissingTurnsToRoute:locations originalDirections:localDirections start:params.start end:params.end mode:params.mode leftSide:params.leftSide];
            // if there is no closest points to start - add it
            std::vector<std::shared_ptr<RouteSegmentResult>> segs;
            [self.class introduceFirstPointAndLastPoint:locations directions:localDirections segs:segs start:params.start end:params.end];
        }
        _appMode = params.mode;
        _locations = locations;
        _segments = std::vector<std::shared_ptr<RouteSegmentResult>>();
        _listDistance = [NSMutableArray arrayWithObject:@(0) count:locations.count];
        [self.class updateListDistanceTime:_listDistance locations:_locations];
        _alarmInfo = [NSMutableArray array];
        [self.class calculateIntermediateIndexes:_locations intermediates:params.intermediates localDirections:localDirections intermediatePoints:_intermediatePoints];
        _directions = localDirections;
        [self.class updateDirectionsTime:_directions listDistance:_listDistance];
        _routeProvider = (EOARouteService) [OAAppSettings.sharedManager.routerService get:_appMode];
        
        OAAppSettings *settings = OAAppSettings.sharedManager;
        _routeRecalcDistance = [settings.routeRecalculationDistance get:_appMode];
        _routeVisibleAngle = _routeProvider == STRAIGHT ? [settings.routeStraightAngle get:_appMode] : 0;
    }
    return self;
}

- (instancetype) initWithSegmentResults:(std::vector<std::shared_ptr<RouteSegmentResult>>&)list start:(CLLocation *)start end:(CLLocation *)end intermediates:(NSArray<CLLocation *> *)intermediates leftSide:(BOOL)leftSide routingTime:(float)routingTime waypoints:(NSArray<id<OALocationPoint>> *)waypoints mode:(OAApplicationMode *)mode
{
    self = [[OARouteCalculationResult alloc] init];
    if (self)
    {
        _routingTime = routingTime;
        if (waypoints)
            [_locationPoints addObjectsFromArray:waypoints];
        
        NSMutableArray<OARouteDirectionInfo *> *computeDirections = [NSMutableArray array];
        _errorMessage = nil;
        _intermediatePoints = [NSMutableArray arrayWithObject:@(0) count:!intermediates ? 0 : intermediates.count];
        NSMutableArray<CLLocation *> *locations = [NSMutableArray array];
        NSMutableArray<OAAlarmInfo *> *alarms = [NSMutableArray array];
        std::vector<std::shared_ptr<RouteSegmentResult>> segments = [self.class convertVectorResult:computeDirections locations:locations list:list alarms:alarms];
        [self.class introduceFirstPointAndLastPoint:locations directions:computeDirections segs:segments start:start end:end];
        
        _locations = locations;
        _segments = segments;
        _listDistance = [NSMutableArray arrayWithObject:@(0) count:locations.count];
        [self.class calculateIntermediateIndexes:_locations intermediates:intermediates localDirections:computeDirections intermediatePoints:_intermediatePoints];;
        [self.class updateListDistanceTime:_listDistance locations:_locations];
        _appMode = mode;
        
        _directions = computeDirections;
        [self.class updateDirectionsTime:_directions listDistance:_listDistance];
        _alarmInfo = alarms;
        _routeProvider = (EOARouteService) [OAAppSettings.sharedManager.routerService get:_appMode];
        
        OAAppSettings *settings = OAAppSettings.sharedManager;
        _routeRecalcDistance = [settings.routeRecalculationDistance get:_appMode];
        _routeVisibleAngle = _routeProvider == STRAIGHT ? [settings.routeStraightAngle get:_appMode] : 0;
    }
    return self;
}

@end
