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
#import "OATransportStopAggregated.h"
#import "OsmAndApp.h"
#import "OAPOI.h"
#import "OAPOIType.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Search/TransportStopsInAreaSearch.h>
#include <OsmAndCore/ObfDataInterface.h>
#include <OsmAndCore/Data/TransportStopExit.h>

static NSInteger const ROUNDING_ERROR = 3;
static NSInteger const SHOW_STOPS_RADIUS_METERS = 150;
static NSInteger const SHOW_SUBWAY_STOPS_FROM_ENTRANCES_RADIUS_METERS = 400;
static NSInteger const MAX_DISTANCE_BETWEEN_AMENITY_AND_LOCAL_STOPS = 20;

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
        auto dist = OsmAnd::Utilities::distance(localStop.stop->location.longitude, localStop.stop->location.latitude, self.getLocation.longitude, self.getLocation.latitude);
        [self addRoutes:localRoutes dataInterface:dataInterface s:localStop.stop lang:prefLang transliterate:transliterate dist:dist isSubwayEntrance:isSubwayEntrance otherRoutes:nearbyRoutes];
    }
    
    for (OATransportStop *stop in nearbyStops)
    {
        auto dist = OsmAnd::Utilities::distance(stop.stop->location.longitude, stop.stop->location.latitude, self.getLocation.longitude, self.getLocation.latitude);
        [self addRoutes:nearbyRoutes dataInterface:dataInterface s:stop.stop lang:prefLang transliterate:transliterate dist:dist isSubwayEntrance:isSubwayEntrance otherRoutes:localRoutes];
    }
}

- (void)processPoiTransportStop:(const std::shared_ptr<OsmAnd::ObfDataInterface> &)dataInterface isSubwayEntrance:(BOOL)isSubwayEntrance localRoutes:(NSMutableArray<OATransportStopRoute *> *)localRoutes nearbyRoutes:(NSMutableArray<OATransportStopRoute *> *)nearbyRoutes prefLang:(NSString *)prefLang stops:(NSMutableArray<OATransportStop *> *)stops transliterate:(BOOL)transliterate
{
    const auto amenityLocation = OsmAnd::LatLon(self.poi.latitude, self.poi.longitude);
    NSMutableArray<OATransportStop *> *localStops = [NSMutableArray array];
    NSMutableArray<OATransportStop *> *nearbyStops = [NSMutableArray array];
    for (OATransportStop *stop in stops)
    {
        const auto stopExits = stop.stop->exits;
        BOOL stopOnSameExitAdded = NO;
        for (const auto exit : stopExits)
        {
            const auto loc = exit->location;
            if (OsmAnd::Utilities::distance(loc, amenityLocation) < ROUNDING_ERROR)
            {
                stopOnSameExitAdded = YES;
                [localStops addObject:stop];
                break;
            }
        }
        if (!stopOnSameExitAdded && OsmAnd::Utilities::distance(stop.stop->location, amenityLocation)
            <= SHOW_SUBWAY_STOPS_FROM_ENTRANCES_RADIUS_METERS)
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
    const std::shared_ptr<OsmAnd::TransportStopsInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::TransportStopsInAreaSearch::Criteria>(new OsmAnd::TransportStopsInAreaSearch::Criteria);
    const auto& point31 = OsmAnd::Utilities::convertLatLonTo31(self.getLocation);
    auto bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(isSubwayEntrance ? SHOW_SUBWAY_STOPS_FROM_ENTRANCES_RADIUS_METERS : SHOW_STOPS_RADIUS_METERS, point31);
    searchCriteria->bbox31 = bbox31;

    OsmAndAppInstance app = [OsmAndApp instance];
    const auto& obfsCollection = app.resourcesManager->obfsCollection;
    const int zoomShift = 31 - OsmAnd::TransportStopsInAreaSearch::TRANSPORT_STOP_ZOOM;
    auto tbbox31 = OsmAnd::AreaI(bbox31.top() >> zoomShift, bbox31.left() >> zoomShift, bbox31.bottom() >> zoomShift, bbox31.right() >> zoomShift);
    const auto dataInterface = obfsCollection->obtainDataInterface(&tbbox31, OsmAnd::MinZoomLevel, OsmAnd::MaxZoomLevel, OsmAnd::ObfDataTypesMask().set(OsmAnd::ObfDataType::Transport));
    if (self.transportStop.transportStopAggregated)
    {
        NSMutableArray<OATransportStop *> *localStops = self.transportStop.transportStopAggregated.localTransportStops;
        NSMutableArray<OATransportStop *> *nearbyStops = self.transportStop.transportStopAggregated.nearbyTransportStops;
        [self addTransportStopRoutes:dataInterface isSubwayEntrance:isSubwayEntrance localRoutes:localRoutes localStops:localStops nearbyRoutes:nearbyRoutes nearbyStops:nearbyStops prefLang:prefLang transliterate:transliterate];
    }
    else
    {
    const auto search = std::make_shared<const OsmAnd::TransportStopsInAreaSearch>(obfsCollection);
    NSMutableArray<OATransportStop *> *stops = [NSMutableArray array];
    search->performSearch(*searchCriteria,
                          [stops]
                          (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                          {
                                [stops addObject:[[OATransportStop alloc] initWithStop:((OsmAnd::TransportStopsInAreaSearch::ResultEntry&)resultEntry).transportStop]];
                          });

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
        auto dist = OsmAnd::Utilities::distance(stop.stop->location.longitude, stop.stop->location.latitude, self.getLocation.longitude, self.getLocation.latitude);
        [self addRoutes:localRoutes dataInterface:dataInterface s:stop.stop lang:prefLang transliterate:transliterate dist:dist isSubwayEntrance:isSubwayEntrance otherRoutes:nearbyRoutes];
    }
    for (OATransportStop *stop in nearbyStops)
    {
        auto dist = OsmAnd::Utilities::distance(stop.stop->location.longitude, stop.stop->location.latitude, self.getLocation.longitude, self.getLocation.latitude);
        [self addRoutes:nearbyRoutes dataInterface:dataInterface s:stop.stop lang:prefLang transliterate:transliterate dist:dist isSubwayEntrance:isSubwayEntrance otherRoutes:localRoutes];
    }
}

- (const OsmAnd::LatLon) getLocation
{
    double stopLat = self.poi ? self.poi.latitude : self.transportStop.location.latitude;
    double stopLon = self.poi ? self.poi.longitude : self.transportStop.location.longitude;
    return OsmAnd::LatLon(stopLat, stopLon);
}

+ (OATransportStop *) findNearestTransportStopForAmenity:(OAPOI *)amenity
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
            
            if (([stopName containsString:amenityName] || [amenityName containsString:stopName])
                && OsmAnd::Utilities::distance(stop.stop->location,OsmAnd::LatLon(lat, lon)) < MAX_DISTANCE_BETWEEN_AMENITY_AND_LOCAL_STOPS
                && (!nearestStop
                    || [OAUtilities isCoordEqual:nearestStop.location destLat:stop.location]
                    || [OAUtilities isCoordEqual:stop.location destLat:CLLocationCoordinate2DMake(lat, lon)])
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

+ (NSArray<OATransportStop *> *) findTransportStopsAt:(double)lat lon:(double)lon radiusMeters:(int)radiusMeters
{
    NSMutableArray<OATransportStop *> *transportStops = [NSMutableArray array];
    
    const std::shared_ptr<OsmAnd::TransportStopsInAreaSearch::Criteria>& searchCriteria = std::shared_ptr<OsmAnd::TransportStopsInAreaSearch::Criteria>(new OsmAnd::TransportStopsInAreaSearch::Criteria);
    const auto& point31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon));
    searchCriteria->bbox31 = (OsmAnd::AreaI)OsmAnd::Utilities::boundingBox31FromAreaInMeters(radiusMeters, point31);
    
    OsmAndAppInstance app = [OsmAndApp instance];
    const auto& obfsCollection = app.resourcesManager->obfsCollection;
    const auto search = std::make_shared<const OsmAnd::TransportStopsInAreaSearch>(obfsCollection);
    search->performSearch(*searchCriteria,
                          [self, transportStops]
                          (const OsmAnd::ISearch::Criteria& criteria, const OsmAnd::ISearch::IResultEntry& resultEntry)
                          {
        const auto transportStop = ((OsmAnd::TransportStopsInAreaSearch::ResultEntry&)resultEntry).transportStop;
        OATransportStop *stop = [[OATransportStop alloc] initWithStop:transportStop];
        [transportStops addObject:stop];
    });
    
    return transportStops;
}

+ (OATransportStopAggregated *) processTransportStopsForAmenity:(NSArray<OATransportStop *> *)transportStops amenity:(OAPOI *)amenity
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
        const auto stopExits = stop.stop->exits;
        BOOL stopOnSameExitAdded = NO;
        if ([amenity.type.name isEqualToString:@"public_transport_station"] && ([stop.name isEqualToString:amenity.name] || [stop.poi.nameLocalized isEqualToString:amenity.nameLocalized]))
        {
            [stopAggregated addLocalTransportStop:stop];
            stopOnSameExitAdded = YES;
        }
        else
        {
            for (const auto exit : stopExits)
            {
                const auto exitLocation = exit->location;
                if (OsmAnd::Utilities::distance(exitLocation, amenityLocation) < ROUNDING_ERROR || [self.class hasCommonExit:exitLocation amenityStops:amenityStops])
                {
                    stopOnSameExitAdded = YES;
                    [stopAggregated addLocalTransportStop:stop];
                    break;
                }
                if (!stopOnSameExitAdded && OsmAnd::Utilities::distance(stop.stop->location, amenityLocation)
                    <= SHOW_SUBWAY_STOPS_FROM_ENTRANCES_RADIUS_METERS)
                {
                    [stopAggregated addNearbyTransportStop:stop];
                }
            }
        }
        if (!stopOnSameExitAdded && OsmAnd::Utilities::distance(stop.stop->location, amenityLocation)
            <= SHOW_SUBWAY_STOPS_FROM_ENTRANCES_RADIUS_METERS)
        {
            [stopAggregated addNearbyTransportStop:stop];
        }
    }
    
    [self.class sortTransportStopsExits:amenityLocation stops:stopAggregated.localTransportStops];
    [self.class sortTransportStopsExits:amenityLocation stops:stopAggregated.nearbyTransportStops];
    return stopAggregated;
}

+ (BOOL) hasCommonExit:(OsmAnd::LatLon)exit amenityStops:(NSArray<OATransportStop *> *)amenityStops
{
    if (!amenityStops)
        return NO;
    for (OATransportStop *amenityStop in amenityStops)
    {
        for (const auto &amenityExit : amenityStop.stop->exits)
        {
            if (OsmAnd::Utilities::distance(exit, amenityExit->location) < ROUNDING_ERROR)
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
        for (const auto &exit : stop.stop->exits)
        {
            if (OsmAnd::Utilities::distance(exit->location, amenityExitLocation) < ROUNDING_ERROR)
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
        for (const auto &exit : transportStop.stop->exits)
        {
            int distance = (int) OsmAnd::Utilities::distance(latLon, exit->location);
            if (transportStop.distance > distance) {
                transportStop.distance = distance;
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
        transportStop.distance = (int) OsmAnd::Utilities::distance(latLon, transportStop.stop->location);
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

- (void) addRoutes:(NSMutableArray<OATransportStopRoute *> *)routes dataInterface:(std::shared_ptr<OsmAnd::ObfDataInterface>)dataInterface s:(std::shared_ptr<const OsmAnd::TransportStop>)s lang:(NSString *)lang transliterate:(BOOL)transliterate dist:(int)dist isSubwayEntrance:(BOOL)isSubwayEntrance otherRoutes:(NSMutableArray<OATransportStopRoute *> *)otherRoutes
{
    QList< std::shared_ptr<const OsmAnd::TransportRoute> > rts;
    auto stringTable = std::make_shared<OsmAnd::ObfSectionInfo::StringTable>();

    if (dataInterface->getTransportRoutes(s, &rts, stringTable.get()))
    {
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
            r.stop = s;
            if (self.transportStop && !isSubwayEntrance)
            {
                r.refStop = self.transportStop.stop;
            }
            else if ([OAUtilities isCoordEqual:self.getLocation.latitude srcLon:self.getLocation.longitude destLat:s->location.latitude destLon:s->location.longitude]
                     || (isSubwayEntrance && t.type == TST_SUBWAY))
            {
                r.refStop = s;
            }
            
            r.distance = dist;
            [r initStopIndex];
            [routes addObject:r];
        }
    }
}

@end
