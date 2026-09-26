//
//  OATransportStopsBaseController.m
//  OsmAnd Maps
//
//  Created by Paul on 17.01.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OATransportStopsBaseController.h"
#import "OATransportStopRoute.h"
#import "OAAppSettings.h"
#import "OATransportStop.h"
#import "OATransportStop+cpp.h"
#import "OATransportStopAggregated.h"
#import "OsmAndApp.h"
#import "OAPOI.h"
#import "OAPOIType.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Search/TransportStopsInAreaSearch.h>
#include <OsmAndCore/ObfDataInterface.h>
#include <OsmAndCore/Data/ObfTransportSectionInfo.h>
#include <OsmAndCore/Data/TransportStopExit.h>

static NSInteger const ROUNDING_ERROR = 3;
static NSInteger const SHOW_STOPS_RADIUS_METERS_UI = 150;
static NSInteger const SHOW_STOPS_RADIUS_METERS = SHOW_STOPS_RADIUS_METERS_UI * 6 / 5;
static NSInteger const SHOW_SUBWAY_STOPS_FROM_ENTRANCES_RADIUS_METERS = 400;
static NSInteger const MAX_DISTANCE_BETWEEN_AMENITY_AND_LOCAL_STOPS = 20;

// Same normalization Android sorts obf files by, see Algorithms.simplifyFileName
static QString transportSectionSortKey(const std::shared_ptr<const OsmAnd::TransportStop>& stop)
{
    if (!stop->obfSection)
        return QString();

    auto name = stop->obfSection->name.toLower();
    const auto dotIndex = name.indexOf(QLatin1Char('.'));
    if (dotIndex != -1)
        name = name.left(dotIndex);
    if (name.endsWith(QLatin1String("_2")))
        name.chop(2);

    return name;
}

@implementation OATransportStopsBaseController

- (void)processTransportStop:(const std::shared_ptr<OsmAnd::ObfDataInterface> &)dataInterface isSubwayEntrance:(BOOL)isSubwayEntrance localRoutes:(NSMutableArray<OATransportStopRoute *> *)localRoutes nearbyRoutes:(NSMutableArray<OATransportStopRoute *> *)nearbyRoutes prefLang:(NSString *)prefLang stops:(NSMutableArray<OATransportStop *> *)stops transliterate:(BOOL)transliterate {
    OATransportStop *localStop = nil;
    NSMutableArray<OATransportStop *> *nearbyStops = [NSMutableArray array];
    for (OATransportStop *stop in stops)
    {
        if (localStop != nil && [stop isEqual:self.transportStop])
        {
            localStop = stop;
        }
        else
        {
            [nearbyStops addObject:stop];
        }
    }
    localStop = localStop ? localStop : self.transportStop;
    
    if (localStop)
    {
        auto dist = OsmAnd::Utilities::distance(localStop.longitude, localStop.latitude, self.getLocation.longitude, self.getLocation.latitude);
        [self addRoutes:localRoutes dataInterface:dataInterface transportStop:localStop lang:prefLang transliterate:transliterate dist:dist isSubwayEntrance:isSubwayEntrance otherRoutes:nearbyRoutes];
    }
    
    for (OATransportStop *stop in nearbyStops)
    {
        auto dist = OsmAnd::Utilities::distance(stop.longitude, stop.latitude, self.getLocation.longitude, self.getLocation.latitude);
        [self addRoutes:nearbyRoutes dataInterface:dataInterface transportStop:stop lang:prefLang transliterate:transliterate dist:dist isSubwayEntrance:isSubwayEntrance otherRoutes:localRoutes];
    }
}

- (void)processPoiTransportStop:(const std::shared_ptr<OsmAnd::ObfDataInterface> &)dataInterface isSubwayEntrance:(BOOL)isSubwayEntrance localRoutes:(NSMutableArray<OATransportStopRoute *> *)localRoutes nearbyRoutes:(NSMutableArray<OATransportStopRoute *> *)nearbyRoutes prefLang:(NSString *)prefLang stops:(NSMutableArray<OATransportStop *> *)stops transliterate:(BOOL)transliterate
{
    const auto amenityLocation = OsmAnd::LatLon(self.poi.latitude, self.poi.longitude);
    NSMutableArray<OATransportStop *> *localStops = [NSMutableArray array];
    NSMutableArray<OATransportStop *> *nearbyStops = [NSMutableArray array];
    for (OATransportStop *stop in stops)
    {
        BOOL stopOnSameExitAdded = NO;
        for (CLLocation *loc in stop.exitLocations)
        {
            const auto exitDist = OsmAnd::Utilities::distance(loc.coordinate.longitude, loc.coordinate.latitude, amenityLocation.longitude, amenityLocation.latitude);
            if (exitDist < ROUNDING_ERROR)
            {
                stopOnSameExitAdded = YES;
                [localStops addObject:stop];
                break;
            }
        }
        const auto dist = OsmAnd::Utilities::distance(stop.longitude, stop.latitude, amenityLocation.longitude, amenityLocation.latitude);
        if (!stopOnSameExitAdded && dist <= SHOW_SUBWAY_STOPS_FROM_ENTRANCES_RADIUS_METERS)
        {
            [nearbyStops addObject:stop];
        }
    }
    [self.class sortTransportStopsExits:amenityLocation stops:localStops];
    [self.class sortTransportStopsExits:amenityLocation stops:nearbyStops];
    [self addTransportStopRoutes:dataInterface isSubwayEntrance:isSubwayEntrance localRoutes:localRoutes localStops:localStops nearbyRoutes:nearbyRoutes nearbyStops:nearbyStops prefLang:prefLang transliterate:transliterate];
}

- (void) processTransportStop
{
    NSMutableArray<OATransportStopRoute *> *localRoutes = [NSMutableArray array];
    NSMutableArray<OATransportStopRoute *> *nearbyRoutes = [NSMutableArray array];

    NSString *prefLang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
    BOOL transliterate = [OAAppSettings sharedManager].settingMapLanguageTranslit.get;
    BOOL isSubwayEntrance = [self.poi.type.name isEqualToString:@"subway_entrance"];
    const auto& point31 = OsmAnd::Utilities::convertLatLonTo31(self.getLocation);
    auto bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(isSubwayEntrance ? SHOW_SUBWAY_STOPS_FROM_ENTRANCES_RADIUS_METERS : SHOW_STOPS_RADIUS_METERS, point31);

    OsmAndAppInstance app = [OsmAndApp instance];
    const auto& obfsCollection = app.resourcesManager->obfsCollection;
    const int zoomShift = 31 - OsmAnd::TransportStopsInAreaSearch::TRANSPORT_STOP_ZOOM;
    auto tbbox31 = OsmAnd::AreaI(bbox31.top() >> zoomShift, bbox31.left() >> zoomShift, bbox31.bottom() >> zoomShift, bbox31.right() >> zoomShift);
    const auto dataInterface = obfsCollection->obtainDataInterface(&tbbox31, OsmAnd::MinZoomLevel, OsmAnd::MaxZoomLevel, OsmAnd::ObfDataTypesMask().set(OsmAnd::ObfDataType::Transport), false);
    if (self.transportStop.transportStopAggregated)
    {
        NSMutableArray<OATransportStop *> *localStops = self.transportStop.transportStopAggregated.localTransportStops;
        NSMutableArray<OATransportStop *> *nearbyStops = self.transportStop.transportStopAggregated.nearbyTransportStops;
        [self addTransportStopRoutes:dataInterface isSubwayEntrance:isSubwayEntrance localRoutes:localRoutes localStops:localStops nearbyRoutes:nearbyRoutes nearbyStops:nearbyStops prefLang:prefLang transliterate:transliterate];
    }
    else
    {
        NSMutableArray<OATransportStop *> *stops = [self searchTransportStopsIn:bbox31];

        if (self.transportStop && !isSubwayEntrance)
        {
            [self processTransportStop:dataInterface isSubwayEntrance:isSubwayEntrance localRoutes:localRoutes nearbyRoutes:nearbyRoutes prefLang:prefLang stops:stops transliterate:transliterate];
        }
        if (self.poi)
        {
            [self processPoiTransportStop:dataInterface isSubwayEntrance:isSubwayEntrance localRoutes:localRoutes nearbyRoutes:nearbyRoutes prefLang:prefLang stops:stops transliterate:transliterate];
        }
    }
    
    NSComparisonResult(^comparator)(OATransportStopRoute* _Nonnull o1, OATransportStopRoute* _Nonnull o2) = ^NSComparisonResult(OATransportStopRoute* _Nonnull o1, OATransportStopRoute* _Nonnull o2){
        if (o1.distance != o2.distance)
            return [OAUtilities compareInt:o1.distance y:o2.distance];
        
        int i1 = [OAUtilities extractFirstIntegerNumber:o1.desc];
        int i2 = [OAUtilities extractFirstIntegerNumber:o2.desc];
        if (i1 != i2)
            return [OAUtilities compareInt:i1 y:i2];
        
        return [o1.desc compare:o2.desc];
    };
    [localRoutes sortUsingComparator:comparator];
    [nearbyRoutes sortUsingComparator:comparator];
    if (!_stopType && localRoutes && localRoutes.count > 0)
    {
        _stopType = localRoutes[0].type;
    }
    self.localRoutes = localRoutes;
    self.nearbyRoutes = nearbyRoutes;
}

- (void)addTransportStopRoutes:(const std::shared_ptr<OsmAnd::ObfDataInterface> &)dataInterface isSubwayEntrance:(BOOL)isSubwayEntrance localRoutes:(NSMutableArray<OATransportStopRoute *> *)localRoutes localStops:(NSMutableArray<OATransportStop *> *)localStops nearbyRoutes:(NSMutableArray<OATransportStopRoute *> *)nearbyRoutes nearbyStops:(NSMutableArray<OATransportStop *> *)nearbyStops prefLang:(NSString *)prefLang transliterate:(BOOL)transliterate {
    for (OATransportStop *stop in localStops)
    {
        auto dist = OsmAnd::Utilities::distance(stop.longitude, stop.latitude, self.getLocation.longitude, self.getLocation.latitude);
        [self addRoutes:localRoutes dataInterface:dataInterface transportStop:stop lang:prefLang transliterate:transliterate dist:dist isSubwayEntrance:isSubwayEntrance otherRoutes:nearbyRoutes];
    }
    for (OATransportStop *stop in nearbyStops)
    {
        auto dist = OsmAnd::Utilities::distance(stop.longitude, stop.latitude, self.getLocation.longitude, self.getLocation.latitude);
        [self addRoutes:nearbyRoutes dataInterface:dataInterface transportStop:stop lang:prefLang transliterate:transliterate dist:dist isSubwayEntrance:isSubwayEntrance otherRoutes:localRoutes];
    }
}

- (const OsmAnd::LatLon) getLocation
{
    double stopLat = self.poi ? self.poi.latitude : self.transportStop.latitude;
    double stopLon = self.poi ? self.poi.longitude : self.transportStop.longitude;
    return OsmAnd::LatLon(stopLat, stopLon);
}

- (OATransportStop *) findNearestTransportStopForAmenity:(OAPOI *)amenity
{
    OATransportStopAggregated *stopAggregated;
    BOOL isSubwayEntrance = [amenity.type.name isEqualToString:@"subway_entrance"] ||
    [amenity.type.name isEqualToString:@"public_transport_station"];
    
    double lat = amenity.latitude;
    double lon = amenity.longitude;
    int radiusMeters = isSubwayEntrance ? SHOW_SUBWAY_STOPS_FROM_ENTRANCES_RADIUS_METERS : SHOW_STOPS_RADIUS_METERS;
    NSArray<OATransportStop *> *transportStops = [self findTransportStopsAt:lat lon:lon radiusMeters:radiusMeters];
    if (!transportStops)
        return nil;
    
    NSMutableArray *sortedStops = [NSMutableArray arrayWithArray:transportStops];
    [self.class sortTransportStops:OsmAnd::LatLon(lat, lon) stops:sortedStops];
    
    if (isSubwayEntrance)
    {
        stopAggregated = [self processTransportStopsForAmenity:sortedStops amenity:amenity];
    }
    else
    {
        stopAggregated = [[OATransportStopAggregated alloc] init];
        stopAggregated.amenity = amenity;
        OATransportStop *nearestStop = nil;
        NSString *amenityName = [[amenity name] lowercaseString];
        
        for (OATransportStop *stop in sortedStops)
        {
            [stop setTransportStopAggregated:stopAggregated];
            NSString *stopName = [[stop name] lowercaseString];
            auto dist = OsmAnd::Utilities::distance(stop.longitude, stop.latitude, lon, lat);
            
            if (([stopName containsString:amenityName] || [amenityName containsString:stopName])
                && dist < MAX_DISTANCE_BETWEEN_AMENITY_AND_LOCAL_STOPS
                && (!nearestStop
                    || [OAUtilities isCoordEqual:[nearestStop getLocation].coordinate destLat:[stop getLocation].coordinate]
                    || [OAUtilities isCoordEqual:[stop getLocation].coordinate destLat:CLLocationCoordinate2DMake(lat, lon)])
                )
            {
                [stopAggregated addLocalTransportStop:stop];
                if (!nearestStop)
                    nearestStop = stop;
            }
            else
            {
                [stopAggregated addNearbyTransportStop:stop];
            }
        }
    }
    
    NSMutableArray<OATransportStop *> *localStops = stopAggregated.localTransportStops;
    NSMutableArray<OATransportStop *> *nearbyStops = stopAggregated.nearbyTransportStops;
    if (localStops && localStops.count > 0)
    {
        return localStops[0];
    }
    else if (nearbyStops && nearbyStops.count > 0)
    {
        return nearbyStops[0];
    }
    return nil;
}

- (NSArray<OATransportStop *> *) findTransportStopsAt:(double)lat lon:(double)lon radiusMeters:(int)radiusMeters
{
    const auto& point31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
    const auto bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(radiusMeters, point31);
    return [self searchTransportStopsIn:bbox31];
}

// A stop comes back once per obf that covers the area, live update files included. Merge the
// copies the way Android does: the route ids stored next to the route offsets tell what a copy
// adds, so every distinct route is read once instead of once per file.
- (NSMutableArray<OATransportStop *> *) searchTransportStopsIn:(const OsmAnd::AreaI &)bbox31
{
    OsmAndAppInstance app = [OsmAndApp instance];
    const auto& obfsCollection = app.resourcesManager->obfsCollection;
    const int zoomShift = 31 - OsmAnd::TransportStopsInAreaSearch::TRANSPORT_STOP_ZOOM;
    const auto tbbox31 = OsmAnd::AreaI(bbox31.top() >> zoomShift, bbox31.left() >> zoomShift, bbox31.bottom() >> zoomShift, bbox31.right() >> zoomShift);
    // Same query as TransportStopsInAreaSearch, but the menu does not wait for a map being installed or updated
    const auto stopsDataInterface = obfsCollection->obtainDataInterface(nullptr, OsmAnd::MinZoomLevel, OsmAnd::MaxZoomLevel, OsmAnd::ObfDataTypesMask().set(OsmAnd::ObfDataType::Transport), false);

    QList< std::shared_ptr<const OsmAnd::TransportStop> > foundStops;
    OsmAnd::ObfSectionInfo::StringTable stringTable;
    stopsDataInterface->searchTransportIndex(nullptr, &tbbox31, &stringTable,
                                        [&foundStops]
                                        (const std::shared_ptr<const OsmAnd::TransportStop>& transportStop) -> bool
                                        {
        foundStops.push_back(transportStop);
        return true;
    });

    // Files come back in QHash order, which is arbitrary, so the copy that ends up representing a
    // stop would differ between runs. Android sorts by file name descending, putting live updates
    // before the region map, so order the copies the same way before merging them.
    std::stable_sort(foundStops.begin(), foundStops.end(),
                     [](const std::shared_ptr<const OsmAnd::TransportStop>& l,
                        const std::shared_ptr<const OsmAnd::TransportStop>& r)
                     {
        return transportSectionSortKey(l) > transportSectionSortKey(r);
    });

    const auto dataInterface = obfsCollection->obtainDataInterface(&tbbox31, OsmAnd::MinZoomLevel, OsmAnd::MaxZoomLevel, OsmAnd::ObfDataTypesMask().set(OsmAnd::ObfDataType::Transport), false);

    QList<uint64_t> stopIds;
    QHash<uint64_t, OATransportStop *> stopsById;
    QHash<uint64_t, QSet<uint64_t>> knownRouteIds;
    QHash<uint64_t, QSet<uint64_t>> deletedRouteIds;
    QHash<uint64_t, QList< std::shared_ptr<const OsmAnd::TransportRoute> >> routesById;
    QSet<uint64_t> droppedStopIds;

    for (const auto& stop : foundStops)
    {
        const uint64_t stopId = stop->id.id;
        // Copies come newest first, so what an older one deletes may not undo what a newer one
        // already supplied: deletions only keep older copies from adding a route back
        const bool isNewestCopy = !stopsById.contains(stopId);
        if (!isNewestCopy && (droppedStopIds.contains(stopId) || stop->isDeleted() || stop->isMissingStop()))
            continue;

        for (const auto routeId : stop->deletedRoutesIds)
            deletedRouteIds[stopId].insert(routeId);

        QVector<uint32_t> pointersToRead;
        if (isNewestCopy)
        {
            stopIds.push_back(stopId);
            stopsById.insert(stopId, [[OATransportStop alloc] initWithStop:stop]);

            // the newest copy decides whether the stop is gone or only a placeholder
            if (stop->isDeleted() || stop->isMissingStop())
            {
                droppedStopIds.insert(stopId);
                continue;
            }

            for (const auto routeId : stop->routesIds)
                knownRouteIds[stopId].insert(routeId);
            pointersToRead = stop->referencesToRoutes;
        }
        else if (stop->routesIds.size() == stop->referencesToRoutes.size())
        {
            for (int i = 0; i < stop->routesIds.size(); i++)
            {
                const auto routeId = stop->routesIds[i];
                if (!knownRouteIds[stopId].contains(routeId) && !deletedRouteIds[stopId].contains(routeId))
                {
                    knownRouteIds[stopId].insert(routeId);
                    pointersToRead.push_back(stop->referencesToRoutes[i]);
                }
            }
        }
        else
        {
            // written before 08/2019, there are no route ids to compare against
            pointersToRead = stop->referencesToRoutes;
        }

        if (pointersToRead.isEmpty())
            continue;

        QList< std::shared_ptr<const OsmAnd::TransportRoute> > routes;
        auto stringTable = std::make_shared<OsmAnd::ObfSectionInfo::StringTable>();
        dataInterface->getTransportRoutes(stop, pointersToRead, &routes, stringTable.get(), nullptr, nullptr, true);
        for (const auto& route : routes)
        {
            if (!isNewestCopy && deletedRouteIds[stopId].contains(route->id.id))
                continue;

            knownRouteIds[stopId].insert(route->id.id);
            routesById[stopId].push_back(route);
        }
    }

    NSMutableArray<OATransportStop *> *stops = [NSMutableArray arrayWithCapacity:stopIds.size()];
    for (const auto stopId : stopIds)
    {
        if (droppedStopIds.contains(stopId))
            continue;

        OATransportStop *stop = stopsById[stopId];
        [stop setRoutes:routesById[stopId]];
        [stops addObject:stop];
    }

    return stops;
}

- (OATransportStopAggregated *) processTransportStopsForAmenity:(NSArray<OATransportStop *> *)transportStops amenity:(OAPOI *)amenity
{
    OATransportStopAggregated *stopAggregated = [[OATransportStopAggregated alloc] init];
    stopAggregated.amenity = amenity;
    OsmAnd::LatLon amenityLocation = OsmAnd::LatLon(amenity.latitude, amenity.longitude);
    NSArray<OATransportStop *> *amenityStops = [NSMutableArray array];
    if ([amenity.type.name isEqualToString:@"subway_entrance"])
    {
        amenityStops = [self.class findSubwayStopsForAmenityExit:transportStops amenityExitLocation:amenityLocation];
    }
    for (OATransportStop *stop in transportStops)
    {
        stop.transportStopAggregated = stopAggregated;
        BOOL stopOnSameExitAdded = NO;
        if ([amenity.type.name isEqualToString:@"public_transport_station"] && ([stop.name isEqualToString:amenity.name] || [stop.poi.nameLocalized isEqualToString:amenity.nameLocalized]))
        {
            [stopAggregated addLocalTransportStop:stop];
            stopOnSameExitAdded = YES;
        }
        else
        {
            for (CLLocation *loc in stop.exitLocations)
            {
                const auto exitDist = OsmAnd::Utilities::distance(loc.coordinate.longitude, loc.coordinate.latitude, amenityLocation.longitude, amenityLocation.latitude);
                if (exitDist < ROUNDING_ERROR || [self.class hasCommonExit:loc.coordinate.latitude exitLon:loc.coordinate.longitude amenityStops:amenityStops])
                {
                    stopOnSameExitAdded = YES;
                    [stopAggregated addLocalTransportStop:stop];
                    break;
                }
                auto dist = OsmAnd::Utilities::distance(stop.longitude, stop.latitude, amenityLocation.longitude, amenityLocation.latitude);
                if (!stopOnSameExitAdded && dist <= SHOW_SUBWAY_STOPS_FROM_ENTRANCES_RADIUS_METERS)
                {
                    [stopAggregated addNearbyTransportStop:stop];
                }
            }
        }
        
        auto dist = OsmAnd::Utilities::distance(stop.longitude, stop.latitude, amenityLocation.longitude, amenityLocation.latitude);
        if (!stopOnSameExitAdded && dist <= SHOW_SUBWAY_STOPS_FROM_ENTRANCES_RADIUS_METERS)
        {
            [stopAggregated addNearbyTransportStop:stop];
        }
    }
    
    [self.class sortTransportStopsExits:amenityLocation stops:stopAggregated.localTransportStops];
    [self.class sortTransportStopsExits:amenityLocation stops:stopAggregated.nearbyTransportStops];
    return stopAggregated;
}

+ (BOOL) hasCommonExit:(double)exitLat exitLon:(double)exitLon amenityStops:(NSArray<OATransportStop *> *)amenityStops
{
    if (!amenityStops)
        return NO;
    for (OATransportStop *amenityStop in amenityStops)
    {
        for (CLLocation *loc in amenityStop.exitLocations)
        {
            const auto exitDist = OsmAnd::Utilities::distance(loc.coordinate.longitude, loc.coordinate.latitude, exitLon, exitLat);
            if (exitDist < ROUNDING_ERROR)
                return YES;
        }
    }
    return NO;
}

+ (NSArray<OATransportStop *> *) findSubwayStopsForAmenityExit:(NSArray<OATransportStop *> *)transportStops amenityExitLocation:(OsmAnd::LatLon)amenityExitLocation
{
    NSMutableArray<OATransportStop *> *foundStops = [NSMutableArray array];
    for (OATransportStop *stop in transportStops)
    {
        for (CLLocation *loc in stop.exitLocations)
        {
            const auto exitDist = OsmAnd::Utilities::distance(loc.coordinate.longitude, loc.coordinate.latitude, amenityExitLocation.longitude, amenityExitLocation.latitude);
            if (exitDist < ROUNDING_ERROR)
            {
                [foundStops addObject:stop];
                break;
            }
        }
    }
    return foundStops;
}

+ (void) sortTransportStopsExits:(OsmAnd::LatLon)latLon stops:(NSMutableArray<OATransportStop *> *)stops
{
    for (OATransportStop *transportStop in stops)
    {
        for (CLLocation *loc in transportStop.exitLocations)
        {
            const auto exitDist = (int) OsmAnd::Utilities::distance(latLon.longitude, latLon.latitude, loc.coordinate.longitude, loc.coordinate.latitude);
            if (transportStop.distance > exitDist) {
                transportStop.distance = exitDist;
            }
        }
    }
    [stops sortUsingComparator:^NSComparisonResult(OATransportStop * _Nonnull obj1, OATransportStop * _Nonnull obj2) {
        return [@(obj1.distance) compare:@(obj2.distance)];
    }];
}

+ (void) sortTransportStops:(OsmAnd::LatLon)latLon stops:(NSMutableArray<OATransportStop *> *)stops
{
    for (OATransportStop *transportStop in stops)
    {
        transportStop.distance = (int) OsmAnd::Utilities::distance(latLon.longitude, latLon.latitude, transportStop.longitude, transportStop.latitude);
    }
    [stops sortUsingComparator:^NSComparisonResult(OATransportStop * _Nonnull obj1, OATransportStop * _Nonnull obj2) {
        return [@(obj1.distance) compare:@(obj2.distance)];
    }];
}

+ (BOOL)checkSameRoute:(NSArray<OATransportStopRoute *> *)stopRoutes withRoute:(std::shared_ptr<const OsmAnd::TransportRoute>)route
{
    for (OATransportStopRoute *stopRoute in stopRoutes) {
        if (stopRoute.route->compareRoute(route)) {
            return YES;
        }
    }
    return NO;
}

- (void) addRoutes:(NSMutableArray<OATransportStopRoute *> *)routes dataInterface:(std::shared_ptr<OsmAnd::ObfDataInterface>)dataInterface transportStop:(OATransportStop *)transportStop lang:(NSString *)lang transliterate:(BOOL)transliterate dist:(int)dist isSubwayEntrance:(BOOL)isSubwayEntrance otherRoutes:(NSMutableArray<OATransportStopRoute *> *)otherRoutes
{
    QList< std::shared_ptr<const OsmAnd::TransportRoute> > rts = [transportStop getRoutes];
    if (rts.isEmpty())
    {
        // the stop did not come from searchTransportStopsIn:, so its routes are not loaded yet
        auto stringTable = std::make_shared<OsmAnd::ObfSectionInfo::StringTable>();
        dataInterface->getTransportRoutes([transportStop getStopObject], &rts, stringTable.get(), nullptr, nullptr, true);
    }

    for (auto rs : rts)
    {
        OATransportStopRoute *r = [[OATransportStopRoute alloc] init];
        r.route = rs;
        OATransportStopType *t = [OATransportStopType findType:rs->type.toNSString()];
        if ([self.class checkSameRoute:routes withRoute:rs] || [self.class checkSameRoute:otherRoutes withRoute:rs]) {
            continue;
        }
        r.type = t;
        r.desc = rs->getName(QString::fromNSString(lang), transliterate).toNSString();
        r.stop = transportStop;
        if (self.transportStop && !isSubwayEntrance)
        {
            r.refStop = self.transportStop;
        }
        else if ([OAUtilities isCoordEqual:self.getLocation.latitude srcLon:self.getLocation.longitude destLat:transportStop.latitude destLon:transportStop.longitude]
                 || (isSubwayEntrance && t.type == TST_SUBWAY))
        {
            r.refStop = transportStop;
        }

        r.distance = dist;
        [r initStopIndex];
        [routes addObject:r];
    }
}

@end
