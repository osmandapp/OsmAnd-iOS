//
//  OASharedRouteDetailsProvider.mm
//  OsmAnd Maps
//

#import "OASharedRouteDetailsProvider.h"

#import <CoreLocation/CoreLocation.h>

#import "OARouteCalculationResult.h"
#import "OARouteCalculationResultSnapshotAdapter.h"
#import "OARouteDirectionInfo.h"
#import "OsmAndSharedWrapper.h"

namespace
{

NSArray<OASKLatLon *> *OACopySharedLocations(NSArray<CLLocation *> *locations)
{
    NSMutableArray<OASKLatLon *> *result = [NSMutableArray arrayWithCapacity:locations.count];
    for (CLLocation *location in locations)
    {
        [result addObject:[[OASKLatLon alloc] initWithLatitude:location.coordinate.latitude
                                                    longitude:location.coordinate.longitude]];
    }
    return [result copy];
}

NSArray<OASInt *> *OACopySharedDistances(NSArray<NSNumber *> *distances)
{
    NSMutableArray<OASInt *> *result = [NSMutableArray arrayWithCapacity:distances.count];
    for (NSNumber *distance in distances)
        [result addObject:[OASInt numberWithInt:distance.intValue]];
    return [result copy];
}

NSArray<OASRouteManeuver *> *OACopySharedManeuvers(NSArray<OARouteDirectionInfo *> *directions)
{
    NSMutableArray<OASRouteManeuver *> *result = [NSMutableArray arrayWithCapacity:directions.count];
    for (OARouteDirectionInfo *direction in directions)
    {
        [result addObject:[OARouteCalculationResultSnapshotAdapter copyManeuver:direction]];
    }
    return [result copy];
}

} // namespace

@implementation OASharedRouteDetailsProvider

+ (OASRouteDetailsSnapshot *)getSnapshot:(OARouteCalculationResult *)route
{
    return route.routeDetailsSnapshot;
}

+ (OASRouteSummary *)getSummary:(OARouteCalculationResult *)route
{
    return route.routeDetailsSnapshot.summary;
}

+ (NSArray<NSNumber *> *)calculateDistancesToFinish:(NSArray<CLLocation *> *)locations
{
    OASRouteGeometryCalculation *geometry = [OASRouteGeometryCalculator.shared
        calculateLocations:OACopySharedLocations(locations)];
    NSMutableArray<NSNumber *> *result = [NSMutableArray arrayWithCapacity:geometry.distanceToFinishMeters.count];
    for (OASInt *distance in geometry.distanceToFinishMeters)
        [result addObject:@(distance.intValue)];
    return [result copy];
}

+ (void)updateDirectionDistancesAndTimes:(NSArray<OARouteDirectionInfo *> *)directions
                  distanceToFinishMeters:(NSArray<NSNumber *> *)distanceToFinishMeters
{
    OASRouteGeometryCalculation *geometry = [[OASRouteGeometryCalculation alloc]
        initWithDistanceToFinishMeters:OACopySharedDistances(distanceToFinishMeters)];
    NSArray<OASRouteManeuver *> *updated = [OASRouteManeuverCalculator.shared
        updateDistancesAndTimesManeuvers:OACopySharedManeuvers(directions)
        geometry:geometry];
    NSUInteger count = MIN(directions.count, updated.count);
    for (NSUInteger index = 0; index < count; index++)
    {
        OARouteDirectionInfo *direction = directions[index];
        OASRouteManeuver *maneuver = updated[index];
        direction.distance = maneuver.distanceMeters;
        direction.afterLeftTime = maneuver.afterLeftTimeSeconds;
    }
}

+ (CLLocation *)getRouteLocationByDistance:(NSArray<CLLocation *> *)locations
                    currentRoutePointIndex:(int)currentRoutePointIndex
                           distanceMeters:(int)distanceMeters
{
    NSArray<OASKLatLon *> *sharedLocations = OACopySharedLocations(locations);
    OASKLatLon *location = [OASRouteGeometryCalculator.shared
        locationByDistanceLocations:sharedLocations
        currentRoutePointIndex:currentRoutePointIndex
        distanceMeters:distanceMeters];
    if (!location)
        return nil;

    NSUInteger index = [sharedLocations indexOfObjectIdenticalTo:location];
    return index == NSNotFound ? nil : locations[index];
}

@end
