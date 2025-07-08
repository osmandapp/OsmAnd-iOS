//
//  BaseDetailsObject.swift
//  OsmAnd
//
//  Created by Max Kojin on 02/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation
import CoreLocation

private let MAX_DISTANCE_BETWEEN_AMENITY_AND_LOCAL_STOPS: Double = 30.0

private enum ObjectCompleteness: UInt {
    case empty = 0
    case combined = 1
    case full = 2
}

@objcMembers
final class BaseDetailsObject: NSObject {
    
    var osmIds: Set<Int>
    var wikidataIds: Set<String>
    var objects: Array<Any>
    var lang: String
    
    private var syntheticAmenity: OAPOI
    private var objectCompleteness: ObjectCompleteness
    private var searchResultResource: EOASearchResultResource
    private var obfResourceName: String?
    
    override init() {
        self.lang = "en"
        self.osmIds = Set<Int>()
        self.wikidataIds = Set<String>()
        self.objects = Array()
        self.syntheticAmenity = OAPOI()
        self.objectCompleteness = .empty
        self.searchResultResource = .detailed
        super.init()
    }
    
    convenience init(lang: String) {
        self.init()
        self.lang = lang
    }
    
    convenience init(object: Any, lang: String) {
        let effectiveLang = lang.isEmpty ? "en" : lang
        self.init(lang: effectiveLang)
        self.lang = effectiveLang
        self.addObject(object)
    }
    
    convenience init(amenities: [OAPOI], lang: String) {
        let effectiveLang = lang.isEmpty ? "en" : lang
        self.init(lang: effectiveLang)
        self.lang = effectiveLang
        
        for amenity in amenities {
            self.addObject(amenity)
        }
        
        self.objectCompleteness = .full
    }
    
    func setObfResourceName(_ obfName: String) {
        obfResourceName = obfName
    }
    
    func getSyntheticAmenity() -> OAPOI {
        syntheticAmenity
    }
    
    func getLocation() -> CLLocation? {
        syntheticAmenity.getLocation()
    }
    
    func getObjects() -> Array<Any> {
        objects
    }
    
    func isObjectFull() -> Bool {
        objectCompleteness == .full || objectCompleteness == .combined
    }
    
    func isObjectEmpty() -> Bool {
        objectCompleteness == .empty
    }
    
    
    func addObject(_ object: Any) -> Bool {
        guard isSupportedObjectType(object) else { return false }
        
        if let detailsObject = object as? BaseDetailsObject {
            for obj in detailsObject.getObjects() {
                addObject(obj)
            }
        } else {
            objects.append(object)
            let osmId = getOsmId(object)
            let wikidata = getWikidata(object)
            
            if osmId != -1 {
                osmIds.insert(Int(osmId))
            }
            if let wikidata, !wikidata.isEmpty {
                wikidataIds.insert(wikidata)
            }
        }
        combineData()
        return true
    }
    
    private func getWikidata(_ object: Any) -> String? {
        if let amenity = object as? OAPOI {
            return amenity.getWikidata()
        } else if let transportStop = object as? OATransportStop {
            let amenity = transportStop.poi
            return amenity?.getWikidata()
        } else if let renderedObject = object as? OARenderedObject {
            return renderedObject.tags[WIKIDATA_TAG] as? String
        }
        return nil
    }
    
    private func getOsmId(_ object: Any) -> Int64 {
        if let amenity = object as? OAPOI {
            return amenity.getOsmId()
        } else if let mapObject = object as? OAMapObject {
            return ObfConstants.getOsmObjectId(mapObject)
        }
        return -1
    }
    
    func overlapsWith(_ object: Any) -> Bool {
        let osmId = getOsmId(object)
        let wikidata = getWikidata(object)
        
        let osmIdEqual = osmId != -1 && osmIds.contains(Int(osmId))

        var wikidataEqual = false
        if let wikidata, !wikidata.isEmpty, wikidataIds.contains(wikidata) {
            wikidataEqual = true
        }
        
        if osmIdEqual || wikidataEqual {
            return true
        }
        
        if let renderedObject = object as? OARenderedObject {
            let stops = getTransportStops()
            return overlapPublicTransport([renderedObject], stops: stops)
        }
        
        if let transportStop = object as? OATransportStop {
            let renderedObjects = getRenderedObjects()
            return overlapPublicTransport(renderedObjects, stops: [transportStop])
        }
        
        return false
    }
    
    private func overlapPublicTransport(_ renderedObjects: [OARenderedObject], stops: [OATransportStop]) -> Bool {
        let found = renderedObjects.first { renderedObject in
            overlapPublicTransport(withRenderedObject: renderedObject, stops: stops)
        }
        return found != nil
    }
    
    private func overlapPublicTransport(withRenderedObject renderedObject: OARenderedObject, stops: [OATransportStop]) -> Bool {
        let transportTypes = OAPOIHelper.sharedInstance().getPublicTransportTypes() as? [String]
        guard let transportTypes, !transportTypes.isEmpty, !stops.isEmpty else { return false }
        
        let tags = renderedObject.tags
        let name = renderedObject.name
        
        if let name, !name.isEmpty {
            var namesEqual = false
            for stop in stops {
                if let stopName = stop.name {
                    if stopName.contains(name) || name.contains(stopName) {
                        namesEqual = true
                        break
                    }
                }
            }
            if !namesEqual {
                return false
            }
        }
        
        var isStop = false
        if let tags, let keys = tags.allKeys as? [String] {
            for key in keys {
                if let value = tags[key] as? String {
                    let keyValueString = "\(key)_\(value)"
                    if transportTypes.contains(value) || transportTypes.contains(keyValueString) {
                        isStop = true
                        break
                    }
                }
            }
        }
        
        if isStop {
            for stop in stops {
                let distance = OAMapUtils.getDistance(stop.location, second: renderedObject.getLocation().coordinate)
                if distance < MAX_DISTANCE_BETWEEN_AMENITY_AND_LOCAL_STOPS {
                    return true
                }
            }
        }
        
        return false
    }
    
    func merge(_ object: Any) {
        if let detailsObject = object as? BaseDetailsObject {
            mergeBaseDetailsObject(detailsObject)
        }
        if let transportStop = object as? OATransportStop {
            mergeTransportStop(transportStop)
        }
        if let renderedObject = object as? OARenderedObject {
            mergeRenderedObject(renderedObject)
        }
    }
    
    private func mergeBaseDetailsObject(_ other: BaseDetailsObject) {
        osmIds.formUnion(other.osmIds)
        wikidataIds.formUnion(other.wikidataIds)
        objects.append(contentsOf: other.objects)
    }
    
    private func mergeTransportStop(_ transportStop: OATransportStop) {
        guard let transportStopPoi = transportStop.poi else { return }
        
        let osmId = ObfConstants.getOsmObjectId(transportStopPoi)
        osmIds.insert(Int(osmId))
        
        if let amenity = transportStop.poi {
            if let wikidata = amenity.getWikidata() {
                wikidataIds.insert(wikidata)
            }
        }
        objects.append(transportStop)
    }
    
    private func mergeRenderedObject(_ renderedObject: OARenderedObject) {
        let osmId = ObfConstants.getOsmObjectId(renderedObject)
        osmIds.insert(Int(osmId))
        
        if let wikidata = renderedObject.tags[WIKIDATA_TAG] as? String  {
            wikidataIds.insert(wikidata)
        }
        
        objects.append(renderedObject)
    }
    
    func combineData() {
        syntheticAmenity = OAPOI()
        sortObjects()
        
        var contentLocales = Set<String>()
        
        for object in objects {
            if let amenity = object as? OAPOI {
                processAmenity(amenity, contentLocales: &contentLocales)
            } else if let transportStop = object as? OATransportStop {
                if let poi = transportStop.poi {
                    processAmenity(poi, contentLocales: &contentLocales)
                } else {
                    // TODO: refactor OATransportStop to be a subclass of OAMapObject
                    // TODO: replace transportStop.poi -> transportStop
                    
                    processId(transportStop.poi)
                    syntheticAmenity.copyNames(transportStop.poi)
                    if syntheticAmenity.getLocation() == nil {
                        syntheticAmenity.latitude = transportStop.location.latitude
                        syntheticAmenity.longitude = transportStop.location.longitude
                    }
                }
            } else if let renderedObject = object as? OARenderedObject {
                let type = ObfConstants.getOsmEntityType(renderedObject)
                if let type {
                    let osmId = ObfConstants.getOsmObjectId(renderedObject)
                    let objectId = ObfConstants.createMapObjectIdFromOsmId(osmId, type: type)
                    
                    if syntheticAmenity.obfId == -1 && objectId > 0 {
                        syntheticAmenity.obfId = objectId
                    }
                }
                
                if syntheticAmenity.type == nil {
                    syntheticAmenity.copyAdditionalInfo(withMap: renderedObject.tags, overwrite: false)
                }
                
                syntheticAmenity.copyNames(renderedObject)
                if syntheticAmenity.getLocation() == nil {
                    syntheticAmenity.latitude = renderedObject.latitude
                    syntheticAmenity.longitude = renderedObject.longitude
                }
                
                processPolygonCoordinates(x: renderedObject.x, y: renderedObject.y)
            }
        }
        
        if contentLocales.count > 0 {
            syntheticAmenity.updateContentLocales(contentLocales)
        }
        
        if objectCompleteness != .full {
            objectCompleteness = syntheticAmenity.type != nil ? .combined : .empty
        }
        
        if syntheticAmenity.type == nil {
            syntheticAmenity.type = OAPOIHelper.sharedInstance().getDefaultOtherCategoryType()
            syntheticAmenity.subType = ""
            objectCompleteness = .empty
        }
    }
    
    private func processId(_ object: OAMapObject?) {
        guard let object else { return }
        if syntheticAmenity.obfId == -1 && ObfConstants.isOsmUrlAvailable(object) {
            syntheticAmenity.obfId = object.obfId
        }
    }
    
    private func processAmenity(_ amenity: OAPOI, contentLocales: inout Set<String>) {
        processId(amenity)
        
        if syntheticAmenity.latitude == 0 && syntheticAmenity.longitude == 0 &&
           amenity.latitude != 0 && amenity.longitude != 0 {
            syntheticAmenity.latitude = amenity.latitude
            syntheticAmenity.longitude = amenity.longitude
        }
        
        if let type = amenity.type, syntheticAmenity.type == nil {
            syntheticAmenity.type = type
        }
        
        if let subType = amenity.subType, syntheticAmenity.subType == nil {
            syntheticAmenity.subType = subType
        }
        
        if let mapIconName = amenity.mapIconName, syntheticAmenity.mapIconName == nil {
            syntheticAmenity.mapIconName = mapIconName
        }
        
        if let regionName = amenity.regionName, syntheticAmenity.regionName == nil {
            syntheticAmenity.regionName = regionName
        }
        
        // Android also reads here tagGroups.
        //Map<Integer, List<TagValuePair>> groups = amenity.getTagGroups();
        //if (syntheticAmenity.getTagGroups() == null && groups != null) {
        //    syntheticAmenity.setTagGroups(new HashMap<>(groups));
        //}
        
        let travelElo = amenity.getTravelEloNumber()
        if syntheticAmenity.getTravelEloNumber() == DEFAULT_ELO && travelElo != DEFAULT_ELO {
            syntheticAmenity.setTravelEloNumber(travelElo)
        }
        
        syntheticAmenity.copyNames(amenity)
        syntheticAmenity.copyAdditionalInfo(amenity, overwrite: false)
        processPolygonCoordinates(x: amenity.x, y: amenity.y)
        
        if syntheticAmenity.localizedContent == nil {
            syntheticAmenity.localizedContent = MutableOrderedDictionary<NSString, NSString>()
        }
        
        if amenity.localizedContent.count > 0 {
            let localizedContent = MutableOrderedDictionary<NSString, NSString>(dictionary: syntheticAmenity.localizedContent)
            localizedContent.addEntries(from: amenity.localizedContent as! [NSString : NSString])
            syntheticAmenity.localizedContent = localizedContent
        }
        
        contentLocales.formUnion(amenity.getSupportedContentLocales())
    }
    
    private func processPolygonCoordinates(x: NSMutableArray, y: NSMutableArray) {
        if syntheticAmenity.x.count > 0, x.count > 0 {
            syntheticAmenity.x.addObjects(from: x as! [Any])
        }
        if syntheticAmenity.y.count > 0 && y.count > 0 {
            syntheticAmenity.y.addObjects(from: y as! [Any])
        }
    }
    
    private func processPolygonCoordinates(_ object: Any) {
        if let amenity = object as? OAPOI {
            processPolygonCoordinates(x: amenity.x, y: amenity.y)
        }
        if let renderedObject = object as? OARenderedObject {
            processPolygonCoordinates(x: renderedObject.x, y: renderedObject.y)
        }
    }
    
    private func sortObjects() {
        // Android uses sort with 3 gradations: ascending, same, descending
        // Swift sort() uses only 2: true/false.
        // So results can differ
        
        sortObjectsByLang()
        sortObjectsByResourceType()
        sortObjectsByClass()
    }
    
    private func sortObjectsByLang() {
        objects.sort { o1, o2 in
            let result: ComparisonResult
            
            let lang1 = Self.getLangForTravel(o1)
            let lang2 = Self.getLangForTravel(o2)

            let preferred1 = lang1 == lang
            let preferred2 = lang2 == lang

            if preferred1 == preferred2 {
                result = .orderedSame
            } else {
                result = preferred1 ? .orderedAscending : .orderedDescending
            }
            
            return result == .orderedAscending
        }
    }
    
    private func sortObjectsByResourceType() {
        objects.sort { o1, o2 in
            let result: ComparisonResult
            
            let ord1 = Self.getResourceType(o1).rawValue
            let ord2 = Self.getResourceType(o2).rawValue

            if ord1 != ord2 {
                result = ord1 > ord2 ? .orderedAscending : .orderedDescending
            } else {
                result = .orderedSame
            }
            
            return result == .orderedAscending
        }
    }
    
    private func sortObjectsByClass() {
        objects.sort { obj1, obj2 in
            let result: ComparisonResult
            
            let ord1 = Self.getClassOrder(obj1)
            let ord2 = Self.getClassOrder(obj2)
            
            if ord1 != ord2 {
                result = ord2 > ord1 ? .orderedAscending : .orderedDescending
            } else {
                result = .orderedSame
            }
            
            return result == .orderedAscending
        }
    }
    
    private func isSupportedObjectType(_ object: Any) -> Bool {
        return object is OAPOI ||
               object is OATransportStop ||
               object is OARenderedObject ||
               object is BaseDetailsObject
    }
    
    private func getObjects<T>(ofType type: T.Type) -> [T] {
       objects.compactMap { $0 as? T }
    }
    
    func getAmenities() -> [OAPOI] {
        getObjects(ofType: OAPOI.self)
    }
    
    func getTransportStops() -> [OATransportStop] {
        getObjects(ofType: OATransportStop.self)
    }
    
    func getRenderedObjects() -> [OARenderedObject] {
        getObjects(ofType: OARenderedObject.self)
    }
    
    static func findObfType(_ obfResourceName: String?, amenity: OAPOI) -> EOASearchResultResource {
        if let obfResourceName, obfResourceName.contains("basemap") {
            return .basemap
        }
        if let obfResourceName, (obfResourceName.contains("travel") || obfResourceName.contains("wikivoyage")) {
            return .travel
        }
        if amenity.type?.category.isWiki() == true {
            return .wikipedia
        }
        return .detailed
    }
    
    func getResourceType() -> EOASearchResultResource {
        searchResultResource = Self.findObfType(obfResourceName, amenity: syntheticAmenity)
        return searchResultResource
    }
    
    static func getResourceType(_ object: Any) -> EOASearchResultResource {
        if let detailsObject = object as? BaseDetailsObject {
            return detailsObject.getResourceType()
        }
        if let amenity = object as? OAPOI {
            return findObfType(amenity.regionName, amenity: amenity)
        }
        return .detailed
    }
    
    func setX(_ x: [Int]) {
        syntheticAmenity.x = x as? NSMutableArray
    }
    
    func setY(_ y: [Int]) {
        syntheticAmenity.y = y as? NSMutableArray
    }
    
    func addX(_ x: NSNumber) {
        syntheticAmenity.x.add(x)
    }
    
    func addY(_ y: NSNumber) {
        syntheticAmenity.y.add(y)
    }
    
    static func getLangForTravel(_ object: Any) -> String {
        var amenity: OAPOI?
        
        if let poi = object as? OAPOI {
            amenity = poi
        }
        if let detailsObject = object as? BaseDetailsObject {
            amenity = detailsObject.getSyntheticAmenity()
        }
        
        if let amenity, getResourceType(object) == .travel {
            let lang = amenity.getTagSuffix("\(LANG_YES):")
            if let lang {
                return lang
            }
        }
        
        return "en"
    }
    
    static func getClassOrder(_ object: Any) -> Int {
        if object is BaseDetailsObject {
            return 1
        }
        if object is OAPOI {
            return 2
        }
        if object is OATransportStop {
            return 3
        }
        if object is OARenderedObject {
            return 4
        }
        return 5
    }
} 
