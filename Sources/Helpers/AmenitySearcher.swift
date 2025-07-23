//
//  AmenitySearcher.swift
//  OsmAnd
//
//  Created by Max Kojin on 18/07/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

// OsmAnd-java/src/main/java/net/osmand/search/AmenitySearcher.java
// git revision c3d7a8a378dc84251eb7ca72dd10958af86d2225

@objcMembers
final class AmenitySearcherRequest: NSObject {
    var latLon: CLLocation?
    var osmId: Int64
    var type: String?
    var wikidata: String?
    var names = [String]()
    
    init(mapObject: OAMapObject) {
        osmId = ObfConstants.getOsmObjectId(mapObject)
        type = ObfConstants.getOsmEntityType(mapObject)
        
        if let poi = mapObject as? OAPOI {
            latLon = poi.getLocation()
            wikidata = poi.getWikidata()
            if let name = poi.name {
                names.append(name)
            }
            if let localizedNames = poi.localizedNames.allValues as? [String] {
                names.append(contentsOf:localizedNames)
            }
        } else if let renderedObject = mapObject as? OARenderedObject {
            latLon = renderedObject.getLocation()
            if latLon == nil || latLon?.coordinate.latitude == 0 && latLon?.coordinate.latitude == 0 {
                latLon = renderedObject.labelLatLon
            }
            if let localizedNames = renderedObject.localizedNames.allValues as? [String] {
                names.append(contentsOf:localizedNames)
            }
            if let value = renderedObject.tags[WIKIDATA_TAG] as? String {
                wikidata = value
            }
        } else if let stop = mapObject as? OATransportStop {
            stop.findAmenityDataIfNeeded()
            latLon = stop.getLocation();
            if let name = stop.name {
                names.append(name)
            }
            if let localizedNames = stop.localizedNames.allValues as? [String] {
                names.append(contentsOf:localizedNames)
            }
            
        } else {
            latLon = mapObject.getLocation()
            wikidata = nil
            if let localizedNames = mapObject.localizedNames.allValues as? [String] {
                names.append(contentsOf:localizedNames)
            }
        }
    }
    
    convenience init(mapObject: OAMapObject, names: [String]) {
        self.init(mapObject: mapObject)
        self.names = names
    }
}

@objcMembers
final class AmenitySearcher: NSObject {
    
    private let AMENITY_SEARCH_RADIUS = 50;
    private let AMENITY_SEARCH_RADIUS_FOR_RELATION = 500;
    
    func searchAmenities(filter: OASearchPoiTypeFilter, searchLatLon: CLLocation, radius: Int, includeTravel: Bool) -> [OAPOI] {
        OAPOIHelper.findPOI(OASearchPoiTypeFilter.acceptAll(), additionalFilter: nil, lat: searchLatLon.coordinate.latitude, lon: searchLatLon.coordinate.longitude, radius: Int32(radius), includeTravel: includeTravel, matcher: nil, publish: nil)
    }
    
    func searchDetailedObject(_ request: AmenitySearcherRequest) -> BaseDetailsObject? {
        guard let latLon = request.latLon else { return nil }
        let osmId = request.osmId
        let wikidata = request.wikidata
        let names = request.names
        
        let searchRadius = request.type == kEntityTypeRelation ? AMENITY_SEARCH_RADIUS_FOR_RELATION : AMENITY_SEARCH_RADIUS
        
        let amenities = searchAmenities(filter: OASearchPoiTypeFilter.acceptAll(), searchLatLon: latLon, radius: searchRadius, includeTravel: true)
        
        var filtered = [OAPOI]()
        if osmId > 0 || wikidata != nil {
            filtered = filterByOsmIdOrWikidata(amenities: amenities, osmId: osmId, point: latLon, wikidata: wikidata)
        }
        if filtered.isEmpty {
            if let amenity = findByName(amenities: amenities, names: names, searchLatLon: latLon) {
                if amenity.getOsmId() > 0 {
                    filtered = filterByOsmIdOrWikidata(amenities: amenities, osmId: amenity.getOsmId(), point: amenity.getLocation(), wikidata: amenity.getWikidata())
                } else {
                    // Don't exist in android. Bugfix for invalid obfId values from cpp
                    filtered.append(amenity)
                }
            }
        }
        if !filtered.isEmpty {
            return BaseDetailsObject(amenities: filtered, lang: OAAppSettings.sharedManager().settingPrefMapLanguage.get())
        }
        return nil
    }
    
    private func filterByOsmIdOrWikidata(amenities: [OAPOI], osmId: Int64, point: CLLocation, wikidata: String?) -> [OAPOI] {
        var result = [OAPOI]()
        var minDist = Double(AMENITY_SEARCH_RADIUS_FOR_RELATION * 4)
        
        for amenity in amenities {
            let initAmenityId = amenity.obfId
            if initAmenityId > 0 {
                let wiki = amenity.getWikidata()
                let wikiEqual = wiki != nil && wiki == wikidata
                let amenityOsmId = amenity.getOsmId()
                let idEqual = amenityOsmId > 0 && amenityOsmId == osmId
                
                if (idEqual || wikiEqual) && !amenity.isClosed() {
                    let dist = OAMapUtils.getDistance(amenity.getLocation().coordinate, second: point.coordinate)
                    if dist < minDist {
                        result.insert(amenity, at: 0) // to the top
                    } else {
                        result.append(amenity)
                    }
                }
            }
        }
        return result
    }
    
    private func findByName(amenities: [OAPOI], names: [String], searchLatLon: CLLocation) -> OAPOI? {
        guard !names.isEmpty, !amenities.isEmpty else { return nil }
        
        let sorted = amenities.filter { !$0.isClosed() && namesMatcher(amenity: $0, matchList: names, matchAllLanguagesAndAltNames: false) }
            .sorted { OAMapUtils.getDistance($0.getLocation().coordinate, second: searchLatLon.coordinate) < OAMapUtils.getDistance($1.getLocation().coordinate, second: searchLatLon.coordinate) }
        
        let found = sorted.first { amenity in
            guard let travelRouteId = amenity.getAdditionalInfo()["route_id"] as? String else { return false }
            return amenity.isRoutePoint() && amenity.name.isEmpty && names.contains(travelRouteId)
        }
        if let found {
            return found
        }
        
        return sorted.first { amenity in
            namesMatcher(amenity: amenity, matchList: names, matchAllLanguagesAndAltNames: true)
        }
    }
    
    private func namesMatcher(amenity: OAPOI, matchList: [String], matchAllLanguagesAndAltNames: Bool) -> Bool {
        guard let settings = OAAppSettings.sharedManager() else { return false }
        
        let lang = settings.settingPrefMapLanguage.get()
        let transliterate = settings.settingMapLanguageTranslit.get()
        
        if let poiSimpleFormat = OAPOIHelper.sharedInstance().getPoiStringWithoutType(amenity) {
            if matchList.contains(poiSimpleFormat) {
                return true
            }
        }

        if let amenityName = amenity.getName(lang, transliterate: transliterate), !amenityName.isEmpty {
            if let found = matchList.first(where: { $0.hasSuffix(amenityName) || $0 == amenityName }) {
                return true
            }
        }
        
        if let st = OAPOIHelper.sharedInstance().getAnyPoiType(byName: amenity.subType) {
            if let poiTypeName = st.nameLocalized, matchList.contains(poiTypeName) {
                return true
            }
        } else {
            if matchList.contains(amenity.subType) {
                return true
            }
        }

        if matchAllLanguagesAndAltNames {
            var allAmenityNames: Set<String> = []

            allAmenityNames.formUnion(amenity.getAltNamesMap().values)
            allAmenityNames.formUnion(amenity.getNamesMap(true).values)
            
            if let typeName = amenity.subType, !typeName.isEmpty {
                let withPoiTypes = allAmenityNames.map { "\(typeName) \($0)" }
                allAmenityNames.formUnion(withPoiTypes)
            }
            if matchList.first(where: { allAmenityNames.contains($0) }) != nil {
                return true
            }
        }
        return false
    }
}
