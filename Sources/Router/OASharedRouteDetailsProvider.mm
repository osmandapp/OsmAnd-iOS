//
//  OASharedRouteDetailsProvider.mm
//  OsmAnd Maps
//

#import "OASharedRouteDetailsProvider.h"

#import <CoreLocation/CoreLocation.h>

#import "OAAlarmInfo.h"
#import "Localization.h"
#import "OALocationPointWrapper.h"
#import "OARouteCalculationResult.h"
#import "OARouteCalculationResultSnapshotAdapter.h"
#import "OARouteDirectionInfo.h"
#import "OsmAndSharedWrapper.h"

namespace
{

OASKotlinIntArray *OACopySharedDistances(NSArray<NSNumber *> *distances)
{
    OASKotlinIntArray *result = [OASKotlinIntArray arrayWithSize:(int32_t) distances.count];
    for (NSUInteger index = 0; index < distances.count; index++)
        [result setIndex:(int32_t) index value:distances[index].intValue];
    return result;
}

NSArray<OASRouteManeuver *> *OACopySharedManeuvers(NSArray<OARouteDirectionInfo *> *directions)
{
    NSMutableArray<OASRouteManeuver *> *result = [NSMutableArray arrayWithCapacity:directions.count];
    for (OARouteDirectionInfo *direction in directions)
    {
        [result addObject:[OARouteCalculationResultSnapshotAdapter copyManeuver:direction]];
    }
    return result;
}

} // namespace

@interface OALocationAccessor : NSObject <OASILocationAccessor>

- (instancetype)initWithLocations:(NSArray<CLLocation *> *)locations;

@end

@implementation OALocationAccessor
{
    NSArray<CLLocation *> *_locations;
}

- (instancetype)initWithLocations:(NSArray<CLLocation *> *)locations
{
    self = [super init];
    if (self)
        _locations = locations;
    return self;
}

- (int32_t)getLocationsCount
{
    return (int32_t) _locations.count;
}

- (double)getLatitudeIndex:(int32_t)index
{
    return _locations[index].coordinate.latitude;
}

- (double)getLongitudeIndex:(int32_t)index
{
    return _locations[index].coordinate.longitude;
}

@end

@interface OAManeuverMetricsAccessor : NSObject <OASIManeuverMetricsAccessor>

- (instancetype)initWithDirections:(NSArray<OARouteDirectionInfo *> *)directions;

@end

@implementation OAManeuverMetricsAccessor
{
    NSArray<OARouteDirectionInfo *> *_directions;
}

- (instancetype)initWithDirections:(NSArray<OARouteDirectionInfo *> *)directions
{
    self = [super init];
    if (self)
        _directions = directions;
    return self;
}

- (int32_t)getManeuversCount
{
    return (int32_t) _directions.count;
}

- (int32_t)getDistanceMetersIndex:(int32_t)index
{
    return _directions[index].distance;
}

- (int32_t)getExpectedTimeSecondsIndex:(int32_t)index
{
    return (int32_t) [_directions[index] getExpectedTime];
}

@end

@implementation OASharedRouteDetailsProvider

+ (NSArray<NSNumber *> *)calculateDistancesToFinish:(NSArray<CLLocation *> *)locations
{
    NSMutableArray<NSNumber *> *result = [NSMutableArray arrayWithCapacity:locations.count];
    [self calculateDistancesToFinish:locations result:result];
    return [result copy];
}

+ (void)calculateDistancesToFinish:(NSArray<CLLocation *> *)locations
                              result:(NSMutableArray<NSNumber *> *)result
{
    OASKotlinIntArray *distances = [OASKotlinIntArray arrayWithSize:(int32_t) locations.count];
    [OASRouteGeometryCalculator.shared
        calculateIntoAccessor:[[OALocationAccessor alloc] initWithLocations:locations]
        distanceToFinishMeters:distances];
    [result removeAllObjects];
    for (int32_t index = 0; index < distances.size; index++)
        [result addObject:@([distances getIndex:index])];
}

+ (void)updateDirectionDistancesAndTimes:(NSArray<OARouteDirectionInfo *> *)directions
                  distanceToFinishMeters:(NSArray<NSNumber *> *)distanceToFinishMeters
{
    OASKotlinIntArray *sharedDistances = OACopySharedDistances(distanceToFinishMeters);
    NSArray<OASRouteManeuver *> *updated = [OASRouteManeuverCalculator.shared
        updateDistancesAndTimesManeuvers:OACopySharedManeuvers(directions)
        distanceToFinishMeters:sharedDistances];
    NSUInteger count = MIN(directions.count, updated.count);
    for (NSUInteger index = 0; index < count; index++)
    {
        OARouteDirectionInfo *direction = directions[index];
        OASRouteManeuver *maneuver = updated[index];
        direction.distance = maneuver.distanceMeters;
        direction.afterLeftTime = maneuver.afterLeftTimeSeconds;
    }
}

+ (NSArray<OASRouteCumulativeInfo *> *)getCumulativeInfoByPosition:(NSArray<OARouteDirectionInfo *> *)directions
{
    return [OASRouteManeuverCalculator.shared
        cumulativeInfoByPositionAccessor:
            [[OAManeuverMetricsAccessor alloc] initWithDirections:directions]];
}

+ (void)calculateIntermediateIndexesForLocations:(NSArray<CLLocation *> *)locations
                                     intermediates:(NSArray<CLLocation *> * _Nullable)intermediates
                                        directions:(NSMutableArray<OARouteDirectionInfo *> *)directions
                                intermediatePoints:(NSMutableArray<NSNumber *> *)intermediatePoints
{
    NSArray<OASRouteManeuver *> *originalManeuvers = OACopySharedManeuvers(directions);
    OASRouteIntermediateCalculation *calculation = [OASRouteManeuverCalculator.shared
        calculateIntermediateIndexesFromAccessorsRouteLocations:
            [[OALocationAccessor alloc] initWithLocations:locations]
        maneuvers:originalManeuvers
        intermediateLocations:[[OALocationAccessor alloc] initWithLocations:intermediates]];
    NSMutableArray<OARouteDirectionInfo *> *updatedDirections =
        [NSMutableArray arrayWithCapacity:calculation.maneuvers.count];
    NSUInteger originalIndex = 0;
    for (OASRouteManeuver *maneuver in calculation.maneuvers)
    {
        if (originalIndex < originalManeuvers.count
            && maneuver.routePointOffset == originalManeuvers[originalIndex].routePointOffset)
        {
            [updatedDirections addObject:directions[originalIndex]];
            originalIndex++;
        }
        else
        {
            OARouteDirectionInfo *toSplit = directions[originalIndex];
            OARouteDirectionInfo *direction = [[OARouteDirectionInfo alloc]
                initWithAverageSpeed:maneuver.averageSpeedMetersPerSecond
                turnType:TurnType::ptrStraight()];
            direction.ref = maneuver.ref;
            direction.streetName = maneuver.streetName;
            direction.routeDataObject = toSplit.routeDataObject;
            direction.destinationName = maneuver.destinationName;
            direction.routePointOffset = maneuver.routePointOffset;
            [direction setDescriptionRoute:OALocalizedString(@"route_head")];
            [updatedDirections addObject:direction];
        }
    }
    [directions setArray:updatedDirections];
    OASKotlinIntArray *intermediateDirectionIndices = calculation.intermediateDirectionIndices;
    for (int32_t index = 0; index < intermediateDirectionIndices.size; index++)
        intermediatePoints[index] = @([intermediateDirectionIndices getIndex:index]);
}

+ (CLLocation *)getRouteLocationByDistance:(NSArray<CLLocation *> *)locations
                    currentRoutePointIndex:(int)currentRoutePointIndex
                           distanceMeters:(int)distanceMeters
{
    int32_t index = [OASRouteGeometryCalculator.shared
        locationIndexByDistanceAccessor:[[OALocationAccessor alloc] initWithLocations:locations]
        currentRoutePointIndex:currentRoutePointIndex
        distanceMeters:distanceMeters];
    return index >= 0 ? locations[index] : nil;
}

+ (OAAlarmInfo *)createSpeedLimit:(int)speed
                         latitude:(double)latitude
                        longitude:(double)longitude
             speedMetersPerSecond:(float)speedMetersPerSecond
{
    OASKLatLon *location = [[OASKLatLon alloc] initWithLatitude:latitude longitude:longitude];
    OASRouteEvent *event = [OASRouteEventBackend.shared createSpeedLimitSpeed:speed
                                                                     location:location
                                                  speedMetersPerSecond:speedMetersPerSecond];
    return [OARouteCalculationResultSnapshotAdapter copyAlarmInfo:event];
}

+ (OAAlarmInfo *)createAlarmInfoWithTag:(NSString * _Nullable)tag
                                   value:(NSString * _Nullable)value
                           locationIndex:(int)locationIndex
                                latitude:(double)latitude
                               longitude:(double)longitude
{
    OASKLatLon *location = [[OASKLatLon alloc] initWithLatitude:latitude longitude:longitude];
    OASRouteEvent *event = [OASRouteEventBackend.shared createFromRouteTagTag:tag
                                                                        value:value
                                                                locationIndex:locationIndex
                                                                     location:location];
    return event ? [OARouteCalculationResultSnapshotAdapter copyAlarmInfo:event] : nil;
}

+ (NSArray<OALocationPointWrapper *> *)selectAlarmWrappersForRoute:(OARouteCalculationResult *)route
                                             routingAlarmsEnabled:(BOOL)routingAlarmsEnabled
                                                       showCameras:(BOOL)showCameras
                                                speakSpeedCameras:(BOOL)speakSpeedCameras
                                                       showTunnels:(BOOL)showTunnels
                                                      speakTunnels:(BOOL)speakTunnels
                                                    showPedestrian:(BOOL)showPedestrian
                                                   speakPedestrian:(BOOL)speakPedestrian
                                              showTrafficWarnings:(BOOL)showTrafficWarnings
                                             speakTrafficWarnings:(BOOL)speakTrafficWarnings
{
    NSMutableArray<OASRouteEvent *> *events = [NSMutableArray arrayWithCapacity:route.alarmInfo.count];
    NSMapTable<OASRouteEvent *, OAAlarmInfo *> *alarmsByEvent = [[NSMapTable alloc]
        initWithKeyOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPointerPersonality
        valueOptions:NSPointerFunctionsStrongMemory
        capacity:route.alarmInfo.count];
    for (OAAlarmInfo *alarm in route.alarmInfo)
    {
        OASRouteEvent *event = [OARouteCalculationResultSnapshotAdapter copyEvent:alarm];
        if (event)
        {
            [events addObject:event];
            [alarmsByEvent setObject:alarm forKey:event];
        }
    }

    OASRouteEventSelectionOptions *options = [[OASRouteEventSelectionOptions alloc]
        initWithRoutingAlarmsEnabled:routingAlarmsEnabled
                         showCameras:showCameras
                   speakSpeedCameras:speakSpeedCameras
                         showTunnels:showTunnels
                        speakTunnels:speakTunnels
                      showPedestrian:showPedestrian
                     speakPedestrian:speakPedestrian
                showTrafficWarnings:showTrafficWarnings
               speakTrafficWarnings:speakTrafficWarnings];
    NSArray<OASRouteEventSelection *> *selections = [OASRouteEventBackend.shared
        selectEvents:events
        options:options];
    NSMutableArray<OALocationPointWrapper *> *result = [NSMutableArray arrayWithCapacity:selections.count];
    for (OASRouteEventSelection *selection in selections)
    {
        OAAlarmInfo *alarm = [alarmsByEvent objectForKey:selection.event];
        if (!alarm)
            continue;
        OALocationPointWrapper *wrapper = [[OALocationPointWrapper alloc]
            initWithRouteCalculationResult:route
            type:LPW_ALARMS
            point:alarm
            deviationDistance:0
            routeIndex:alarm.locationIndex];
        wrapper.announce = selection.announce;
        [result addObject:wrapper];
    }
    return [result copy];
}

@end
