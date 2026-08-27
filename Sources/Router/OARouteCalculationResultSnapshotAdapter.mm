//
//  OARouteCalculationResultSnapshotAdapter.mm
//  OsmAnd Maps
//

#import "OARouteCalculationResultSnapshotAdapter.h"

#import <CoreLocation/CoreLocation.h>

#import "OAAlarmInfo.h"
#import "OAAppSettings.h"
#import "OAExitInfo.h"
#import "OALocationSimulation.h"
#import "OARouteDirectionInfo.h"
#import "OsmAndSharedWrapper.h"

#include <algorithm>
#include <cmath>
#include <routeSegmentResult.h>

namespace
{

NSString * _Nullable OAStringFromStdString(const std::string &value)
{
    return [NSString stringWithUTF8String:value.c_str()];
}

NSArray<OASRoutePoint *> *OACopyPoints(NSArray<CLLocation *> *locations,
                                      NSArray<NSNumber *> *listDistance)
{
    NSMutableArray<OASRoutePoint *> *points = [NSMutableArray arrayWithCapacity:locations.count];
    for (NSUInteger index = 0; index < locations.count; index++)
    {
        CLLocation *location = locations[index];
        int distanceToFinish = index < listDistance.count ? listDistance[index].intValue : 0;
        OASDouble *altitude = location.verticalAccuracy >= 0 && std::isfinite(location.altitude)
            ? [OASDouble numberWithDouble:location.altitude]
            : nil;
        OASFloat *speed = location.speed >= 0 && std::isfinite(location.speed)
            ? [OASFloat numberWithFloat:location.speed]
            : nil;
        int64_t timeMillis = (int64_t) (location.timestamp.timeIntervalSince1970 * 1000.0);
        NSString *provider = [location isKindOfClass:OALocation.class]
            ? [((OALocation *) location).provider copy]
            : nil;
        OASKLatLon *latLon = [[OASKLatLon alloc] initWithLatitude:location.coordinate.latitude
                                                       longitude:location.coordinate.longitude];
        [points addObject:[[OASRoutePoint alloc] initWithLocation:latLon
                                          distanceToFinishMeters:distanceToFinish
                                                  altitudeMeters:altitude
                                           speedMetersPerSecond:speed
                                                      timeMillis:timeMillis
                                                        provider:provider]];
    }
    return [points copy];
}

NSArray<OASRouteTypeAttribute *> *OACopyRouteTypes(const std::shared_ptr<RouteDataObject> &road)
{
    if (!road || !road->region)
        return @[];

    NSMutableArray<OASRouteTypeAttribute *> *routeTypes = [NSMutableArray arrayWithCapacity:road->types.size()];
    for (uint32_t type : road->types)
    {
        if (type >= road->region->routeEncodingRules.size())
            continue;

        const auto &rule = road->region->quickGetEncodingRule(type);
        NSString *tag = OAStringFromStdString(rule.getTag());
        NSString *value = OAStringFromStdString(rule.getValue());
        if (tag && value)
            [routeTypes addObject:[[OASRouteTypeAttribute alloc] initWithTag:tag value:value]];
    }
    return [routeTypes copy];
}

NSArray<OASFloat *> *OACopyHeightValues(const std::shared_ptr<RouteSegmentResult> &segment)
{
    const std::vector<double> heightValues = segment->getHeightValues();
    NSMutableArray<OASFloat *> *result = [NSMutableArray arrayWithCapacity:heightValues.size()];
    for (double value : heightValues)
        [result addObject:[OASFloat numberWithFloat:(float) value]];
    return [result copy];
}

OASRouteSegment *OACopySegment(const std::shared_ptr<RouteSegmentResult> &segment,
                              int routePointStartIndex,
                              int routePointEndIndex)
{
    const std::shared_ptr<RouteDataObject> &road = segment->object;
    bool forward = segment->isForwardDirection();
    std::string language;
    return [[OASRouteSegment alloc]
        initWithRoutePointStartIndex:routePointStartIndex
             routePointEndIndex:routePointEndIndex
            nativeStartPointIndex:segment->getStartPointIndex()
              nativeEndPointIndex:segment->getEndPointIndex()
                   distanceMeters:segment->distance
                segmentTimeSeconds:segment->segmentTime
     segmentSpeedMetersPerSecond:segment->segmentSpeed
                            roadId:road->getId()
                           forward:forward
                          roadName:OAStringFromStdString(road->getName())
                               ref:OAStringFromStdString(road->getRef(language, false, forward))
                   destinationName:OAStringFromStdString(road->getDestinationName(language, false, forward))
                    destinationRef:OAStringFromStdString(road->getDestinationRef(forward))
                           highway:OAStringFromStdString(road->getHighway())
      maximumSpeedMetersPerSecond:road->getMaximumSpeed(forward)
                             lanes:road->getLanes()
                   oneWayDirection:road->getOneway()
                        roundabout:road->roundabout()
                            tunnel:road->tunnel()
                        routeTypes:OACopyRouteTypes(road)
                      heightValues:OACopyHeightValues(segment)];
}

NSArray<OASRouteSegment *> *OACopySegments(
    const std::vector<std::shared_ptr<RouteSegmentResult>> &pointAlignedSegments,
    int routePointCount)
{
    if (pointAlignedSegments.empty() || routePointCount == 0)
        return @[];

    NSMutableArray<OASRouteSegment *> *result = [NSMutableArray array];
    int runStart = 0;
    while (runStart < (int) pointAlignedSegments.size() && runStart < routePointCount)
    {
        const std::shared_ptr<RouteSegmentResult> &segment = pointAlignedSegments[runStart];
        int runEnd = runStart + 1;
        while (runEnd < (int) pointAlignedSegments.size() && pointAlignedSegments[runEnd] == segment)
            runEnd++;

        if (segment && segment->object)
        {
            int routePointStartIndex;
            int routePointEndIndex;
            [OARouteCalculationResultSnapshotAdapter
                routePointRangeWithNativeStartPointIndex:segment->getStartPointIndex()
                nativeEndPointIndex:segment->getEndPointIndex()
                runStart:runStart
                runEnd:runEnd
                routePointCount:routePointCount
                routePointStartIndexOut:&routePointStartIndex
                routePointEndIndexOut:&routePointEndIndex];
            [result addObject:[OARouteCalculationResultSnapshotAdapter
                copySegment:segment
                routePointStartIndex:routePointStartIndex
                routePointEndIndex:routePointEndIndex]];
        }
        runStart = runEnd;
    }
    return [result copy];
}

NSArray<OASInt *> * _Nullable OACopyLanes(const std::shared_ptr<TurnType> &turn)
{
    if (!turn || turn->getLanes().empty())
        return nil;

    NSMutableArray<OASInt *> *lanes = [NSMutableArray arrayWithCapacity:turn->getLanes().size()];
    for (int lane : turn->getLanes())
        [lanes addObject:[OASInt numberWithInt:lane]];
    return [lanes copy];
}

OASRouteExitInfo * _Nullable OACopyExitInfo(OAExitInfo * _Nullable exitInfo)
{
    if (!exitInfo)
        return nil;
    return [[OASRouteExitInfo alloc] initWithRef:[exitInfo.ref copy]
                                  exitStreetName:[exitInfo.exitStreetName copy]];
}

OASRouteManeuver *OACopyManeuver(OARouteDirectionInfo *direction)
{
    const std::shared_ptr<TurnType> &turn = direction.turnType;
    return [[OASRouteManeuver alloc]
        initWithTurnTypeValue:turn ? turn->getValue() : 0
             routePointOffset:direction.routePointOffset
          routeEndPointOffset:direction.routeEndPointOffset
                distanceMeters:direction.distance
            expectedTimeSeconds:(int) [direction getExpectedTime]
           afterLeftTimeSeconds:(int) direction.afterLeftTime
  averageSpeedMetersPerSecond:direction.averageSpeed
             turnAngleDegrees:turn ? turn->getTurnAngle() : 0
                    exitNumber:turn ? turn->getExitOut() : 0
                          lanes:OACopyLanes(turn)
                   skipToSpeak:turn ? turn->isSkipToSpeak() : NO
              possibleLeftTurn:turn ? turn->isPossibleLeftTurn() : NO
             possibleRightTurn:turn ? turn->isPossibleRightTurn() : NO
                otherTurnAngles:nil
                    streetName:[direction.streetName copy]
                           ref:[direction.ref copy]
               destinationName:[direction.destinationName copy]
                destinationRef:[direction.destinationRef copy]
                      exitInfo:OACopyExitInfo(direction.exitInfo)];
}

NSArray<OASRouteManeuver *> *OACopyManeuvers(NSArray<OARouteDirectionInfo *> *directions)
{
    NSMutableArray<OASRouteManeuver *> *result = [NSMutableArray arrayWithCapacity:directions.count];
    for (OARouteDirectionInfo *direction in directions)
        [result addObject:OACopyManeuver(direction)];
    return [result copy];
}

OASRouteEventType * _Nullable OASharedEventType(EOAAlarmInfoType type)
{
    switch (type)
    {
        case AIT_SPEED_CAMERA:
            return OASRouteEventType.speedCamera;
        case AIT_SPEED_LIMIT:
            return OASRouteEventType.speedLimit;
        case AIT_BORDER_CONTROL:
            return OASRouteEventType.borderControl;
        case AIT_RAILWAY:
            return OASRouteEventType.railway;
        case AIT_TRAFFIC_CALMING:
            return OASRouteEventType.trafficCalming;
        case AIT_TOLL_BOOTH:
            return OASRouteEventType.tollBooth;
        case AIT_STOP:
            return OASRouteEventType.stop;
        case AIT_PEDESTRIAN:
            return OASRouteEventType.pedestrian;
        case AIT_TUNNEL:
            return OASRouteEventType.tunnel;
        case AIT_HAZARD:
            return OASRouteEventType.hazard;
        case AIT_MAXIMUM:
            return OASRouteEventType.maximum;
        case AIT_RED_LIGHT_CAMERA:
            return OASRouteEventType.redLightCamera;
    }
    return nil;
}

BOOL OASRouteEventTypeEquals(OASRouteEventType *type, OASRouteEventType *expected)
{
    return type == expected || [type isEqual:expected];
}

BOOL OAAlarmTypeFromShared(OASRouteEventType *type, EOAAlarmInfoType *alarmType)
{
    if (OASRouteEventTypeEquals(type, OASRouteEventType.speedCamera))
        *alarmType = AIT_SPEED_CAMERA;
    else if (OASRouteEventTypeEquals(type, OASRouteEventType.speedLimit))
        *alarmType = AIT_SPEED_LIMIT;
    else if (OASRouteEventTypeEquals(type, OASRouteEventType.borderControl))
        *alarmType = AIT_BORDER_CONTROL;
    else if (OASRouteEventTypeEquals(type, OASRouteEventType.railway))
        *alarmType = AIT_RAILWAY;
    else if (OASRouteEventTypeEquals(type, OASRouteEventType.trafficCalming))
        *alarmType = AIT_TRAFFIC_CALMING;
    else if (OASRouteEventTypeEquals(type, OASRouteEventType.tollBooth))
        *alarmType = AIT_TOLL_BOOTH;
    else if (OASRouteEventTypeEquals(type, OASRouteEventType.stop))
        *alarmType = AIT_STOP;
    else if (OASRouteEventTypeEquals(type, OASRouteEventType.pedestrian))
        *alarmType = AIT_PEDESTRIAN;
    else if (OASRouteEventTypeEquals(type, OASRouteEventType.tunnel))
        *alarmType = AIT_TUNNEL;
    else if (OASRouteEventTypeEquals(type, OASRouteEventType.hazard))
        *alarmType = AIT_HAZARD;
    else if (OASRouteEventTypeEquals(type, OASRouteEventType.maximum))
        *alarmType = AIT_MAXIMUM;
    else if (OASRouteEventTypeEquals(type, OASRouteEventType.redLightCamera))
        *alarmType = AIT_RED_LIGHT_CAMERA;
    else
        return NO;
    return YES;
}

OASRouteEvent * _Nullable OACopyEvent(OAAlarmInfo *alarm)
{
    OASRouteEventType *type = OASharedEventType(alarm.type);
    if (!type)
        return nil;
    OASKLatLon *location = [[OASKLatLon alloc] initWithLatitude:alarm.coordinate.latitude
                                                     longitude:alarm.coordinate.longitude];
    return [[OASRouteEvent alloc] initWithType:type
                                     location:location
                                locationIndex:alarm.locationIndex
                            lastLocationIndex:alarm.lastLocationIndex
                                     intValue:alarm.intValue
                                   floatValue:alarm.floatValue];
}

OAAlarmInfo * _Nullable OACopyAlarmInfo(OASRouteEvent *event)
{
    EOAAlarmInfoType type;
    if (!OAAlarmTypeFromShared(event.type, &type))
        return nil;
    OAAlarmInfo *alarm = [[OAAlarmInfo alloc] initWithType:type locationIndex:event.locationIndex];
    alarm.coordinate = CLLocationCoordinate2DMake(event.location.latitude, event.location.longitude);
    alarm.lastLocationIndex = event.lastLocationIndex;
    alarm.intValue = event.intValue;
    alarm.floatValue = event.floatValue;
    return alarm;
}

NSArray<OASRouteEvent *> *OACopyEvents(NSArray<OAAlarmInfo *> *alarms)
{
    NSMutableArray<OASRouteEvent *> *result = [NSMutableArray arrayWithCapacity:alarms.count];
    for (OAAlarmInfo *alarm in alarms)
    {
        OASRouteEvent *event = OACopyEvent(alarm);
        if (event)
            [result addObject:event];
    }
    return [result copy];
}

OASRouteServiceType * _Nullable OASharedRouteService(NSNumber * _Nullable routeProvider)
{
    if (!routeProvider)
        return nil;

    switch ((EOARouteService) routeProvider.integerValue)
    {
        case OSMAND:
            return OASRouteServiceType.osmand;
        case DIRECT_TO:
            return OASRouteServiceType.directTo;
        case STRAIGHT:
            return OASRouteServiceType.straight;
    }
    return nil;
}

NSArray<OASInt *> *OACopyIntermediateRoutePointOffsets(
    NSArray<NSNumber *> *intermediateDirectionIndexes,
    NSArray<OARouteDirectionInfo *> *directions,
    int routePointCount)
{
    if (routePointCount == 0)
        return @[];

    NSMutableArray<OASInt *> *result = [NSMutableArray arrayWithCapacity:intermediateDirectionIndexes.count];
    for (NSNumber *directionIndexValue in intermediateDirectionIndexes)
    {
        int directionIndex = directionIndexValue.intValue;
        int routePointOffset = directionIndex >= 0 && directionIndex < (int) directions.count
            ? directions[directionIndex].routePointOffset
            : 0;
        [result addObject:[OASInt numberWithInt:routePointOffset]];
    }
    return [result copy];
}

} // namespace

@implementation OARouteCalculationResultSnapshotAdapter

+ (OASRouteSegment *)copySegment:(const std::shared_ptr<RouteSegmentResult> &)segment
            routePointStartIndex:(int)routePointStartIndex
              routePointEndIndex:(int)routePointEndIndex
{
    return OACopySegment(segment, routePointStartIndex, routePointEndIndex);
}

+ (OASRouteManeuver *)copyManeuver:(OARouteDirectionInfo *)direction
{
    return OACopyManeuver(direction);
}

+ (OASRouteEvent *)copyEvent:(OAAlarmInfo *)alarm
{
    return OACopyEvent(alarm);
}

+ (OAAlarmInfo *)copyAlarmInfo:(OASRouteEvent *)event
{
    return OACopyAlarmInfo(event);
}

+ (OASRouteDetailsSnapshot *)createWithLocations:(NSArray<CLLocation *> *)locations
                                      directions:(NSArray<OARouteDirectionInfo *> *)directions
                                         segments:(const std::vector<std::shared_ptr<RouteSegmentResult>> &)segments
                                            alarms:(NSArray<OAAlarmInfo *> *)alarms
                                      listDistance:(NSArray<NSNumber *> *)listDistance
                      intermediateDirectionIndexes:(NSArray<NSNumber *> *)intermediateDirectionIndexes
                                         profileId:(NSString * _Nullable)profileId
                                     routeProvider:(NSNumber * _Nullable)routeProvider
                                       routingTime:(float)routingTime
                                initialCalculation:(BOOL)initialCalculation
                            currentRoutePointIndex:(int)currentRoutePointIndex
                             currentDirectionIndex:(int)currentDirectionIndex
                             nextIntermediateIndex:(int)nextIntermediateIndex
{
    NSArray<OASRoutePoint *> *points = OACopyPoints(locations, listDistance);
    NSArray<OASRouteManeuver *> *maneuvers = OACopyManeuvers(directions);
    int totalDistance = listDistance.count > 0 ? listDistance.firstObject.intValue : 0;
    int totalTime = directions.count > 0 ? (int) directions.firstObject.afterLeftTime : 0;
    OASRouteSummary *summary = [[OASRouteSummary alloc]
        initWithTotalDistanceMeters:totalDistance
                  totalTimeSeconds:totalTime
                          profileId:[profileId copy]
                       routeService:OASharedRouteService(routeProvider)
                 routingTimeSeconds:routingTime
             calculationTimeSeconds:0
                    visitedSegments:0
                         loadedTiles:0
                  initialCalculation:initialCalculation];

    return [[OASRouteDetailsSnapshot alloc]
        initWithSchemaVersion:OASRouteDetailsSnapshot.companion.CURRENT_SCHEMA_VERSION
                       points:points
                     segments:OACopySegments(segments, (int) locations.count)
                    maneuvers:maneuvers
                       events:OACopyEvents(alarms)
                      summary:summary
                   statistics:@[]
       currentRoutePointIndex:currentRoutePointIndex
        currentDirectionIndex:currentDirectionIndex
        nextIntermediateIndex:nextIntermediateIndex
intermediateRoutePointOffsets:OACopyIntermediateRoutePointOffsets(
                                      intermediateDirectionIndexes,
                                      directions,
                                      (int) locations.count)];
}

+ (void)routePointRangeWithNativeStartPointIndex:(int)nativeStartPointIndex
                             nativeEndPointIndex:(int)nativeEndPointIndex
                                        runStart:(int)runStart
                                          runEnd:(int)runEnd
                                 routePointCount:(int)routePointCount
                         routePointStartIndexOut:(int *)routePointStartIndexOut
                           routePointEndIndexOut:(int *)routePointEndIndexOut
{
    int nativeEdgeCount = std::abs(nativeEndPointIndex - nativeStartPointIndex);
    int occurrenceCount = runEnd - runStart;
    int routePointStartIndex;
    int routePointEndIndex;
    if (occurrenceCount == nativeEdgeCount && runEnd < routePointCount)
    {
        routePointStartIndex = runStart;
        routePointEndIndex = runEnd;
    }
    else if (occurrenceCount == nativeEdgeCount && runEnd >= routePointCount && runStart > 0)
    {
        routePointStartIndex = runStart - 1;
        routePointEndIndex = routePointCount - 1;
    }
    else
    {
        routePointStartIndex = runStart;
        routePointEndIndex = std::min(runEnd - 1, routePointCount - 1);
    }

    if (routePointStartIndexOut)
        *routePointStartIndexOut = routePointStartIndex;
    if (routePointEndIndexOut)
        *routePointEndIndexOut = routePointEndIndex;
}

@end
