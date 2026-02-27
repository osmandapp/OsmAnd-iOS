//
//  BaseDetailsObject.swift
//  OsmAnd
//
//  Created by Max Kojin on 02/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

// OsmAnd-java/src/main/java/net/osmand/data/BaseDetailsObject.java
// git revision 6760f7a070f136795c5f30c24157f3fa1e821522

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

    var osmIds: Set<UInt64>
    var wikidataIds: Set<String>
    var objects: [Any]
    var lang: String

    private(set) var syntheticAmenity: OAPOI
    private var objectCompleteness: ObjectCompleteness
    private var searchResultResource: EOASearchResultResource
    private var obfResourceName: String?

    override init() {
        self.lang = "en"
        self.osmIds = Set<UInt64>()
        self.wikidataIds = Set<String>()
        self.objects = [Any]()
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

    convenience init(mapObjects: [OAMapObject], lang: String) {
        let effectiveLang = lang.isEmpty ? "en" : lang
        self.init(lang: effectiveLang)
        self.lang = effectiveLang

        var containsAmenity = false
        for mapObject in mapObjects {
            self.addObject(mapObject)
            if mapObject is OAPOI {
                containsAmenity = true
            }
        }
        
        if !objects.isEmpty {
            objectCompleteness = containsAmenity ? .full : .combined
        }
    }

    func setObfResourceName(_ obfName: String) {
        obfResourceName = obfName
    }

    func getLocation() -> CLLocation? {
        syntheticAmenity.getLocation()
    }

    func isObjectFull() -> Bool {
        objectCompleteness == .full || objectCompleteness == .combined
    }

    func isObjectEmpty() -> Bool {
        objectCompleteness == .empty
    }

    @discardableResult
    func addObject(_ object: Any) -> Bool {
        guard isSupportedObjectType(object) else { return false }

        if let detailsObject = object as? BaseDetailsObject {
            for obj in detailsObject.objects {
                addObject(obj)
            }
        } else {
            objects.append(object)
            let osmId = getOsmId(object)
            let wikidata = getWikidata(object)

            if osmId > 0 {
                osmIds.insert(UInt64(osmId))
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
        } else if let detailsObject = object as? BaseDetailsObject {
            return detailsObject.syntheticAmenity.getWikidata()
        }
        return nil
    }

    private func getOsmId(_ object: Any) -> UInt64 {
        if let amenity = object as? OAPOI {
            return amenity.getOsmId()
        } else if let mapObject = object as? OAMapObject {
            return ObfConstants.getOsmObjectId(mapObject)
        } else if let detailsObject = object as? BaseDetailsObject {
            return detailsObject.syntheticAmenity.getOsmId()
        }
        return 0
    }

    func overlapsWith(_ object: Any) -> Bool {
        let osmId = getOsmId(object)
        let wikidata = getWikidata(object)

        let osmIdEqual = osmId > 0 && osmIds.contains(osmId)

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
        renderedObjects.contains { overlapPublicTransport(withRenderedObject: $0, stops: stops) }
    }

    private func overlapPublicTransport(withRenderedObject renderedObject: OARenderedObject, stops: [OATransportStop]) -> Bool {
        guard let transportTypes = OAPOIHelper.sharedInstance().getPublicTransportTypes() as? [String] else { return false }
        guard !transportTypes.isEmpty && !stops.isEmpty else { return false }

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
                let distance = OAMapUtils.getDistance(stop.getLocation().coordinate, second: renderedObject.getLocation().coordinate)
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
        osmIds.insert(UInt64(osmId))

        if let amenity = transportStop.poi {
            if let wikidata = amenity.getWikidata() {
                wikidataIds.insert(wikidata)
            }
        }
        objects.append(transportStop)
    }

    private func mergeRenderedObject(_ renderedObject: OARenderedObject) {
        let osmId = ObfConstants.getOsmObjectId(renderedObject)
        osmIds.insert(UInt64(osmId))

        if let wikidata = renderedObject.tags[WIKIDATA_TAG] as? String {
            wikidataIds.insert(wikidata)
        }

        objects.append(renderedObject)
    }

    func combineData() {
        syntheticAmenity = OAPOI()
        sortObjects()

        var contentLocales = Set<String>()

        for object in objects {
            mergeObject(object, contentLocales: &contentLocales, isSingleObject: objects.count == 1)
        }

        if contentLocales.count > 0 {
            syntheticAmenity.updateContentLocales(contentLocales)
        }

        if objectCompleteness.rawValue < ObjectCompleteness.full.rawValue {
            objectCompleteness = syntheticAmenity.type == nil ? .empty : .combined
        }

        if syntheticAmenity.type == nil {
            syntheticAmenity.type = OAPOIHelper.sharedInstance().getDefaultOtherCategoryType()
            syntheticAmenity.subType = ""
            objectCompleteness = .empty
        }
    }

    private func mergeObject(_ object: Any, contentLocales: inout Set<String>, isSingleObject: Bool) {
        if let amenity = object as? OAPOI {
            processAmenity(amenity, contentLocales: &contentLocales, isSingleObject: isSingleObject)
        } else if let transportStop = object as? OATransportStop {
            if let amenity = transportStop.poi {
                processAmenity(amenity, contentLocales: &contentLocales, isSingleObject: isSingleObject)
            } else {
                processId(transportStop)
                syntheticAmenity.copyNames(transportStop)
                if !syntheticAmenity.hasLocation() {
                    syntheticAmenity.latitude = transportStop.latitude
                    syntheticAmenity.longitude = transportStop.longitude
                }
            }
        } else if let renderedObject = object as? OARenderedObject {
            if let type = ObfConstants.getOsmEntityType(renderedObject) {
                let osmId = ObfConstants.getOsmObjectId(renderedObject)
                let objectId = ObfConstants.createMapObjectIdFromOsmId(osmId, type: type)

                if syntheticAmenity.obfId <= 0 && objectId > 0 {
                    syntheticAmenity.obfId = objectId
                }
            }
            if syntheticAmenity.type == nil {
                let converted = BaseDetailsObject.convertRenderedObjectToAmenity(renderedObject)
                syntheticAmenity.type = converted.type
                syntheticAmenity.subType = converted.subType
                syntheticAmenity.copyAdditionalInfo(withMap: renderedObject.tags, overwrite: false)
            }
            syntheticAmenity.copyNames(renderedObject)
            if !syntheticAmenity.hasLocation() {
                syntheticAmenity.latitude = renderedObject.latitude
                syntheticAmenity.longitude = renderedObject.longitude
            }
            if !syntheticAmenity.hasLocation() {
                syntheticAmenity.latitude = renderedObject.labelLatLon.coordinate.latitude
                syntheticAmenity.longitude = renderedObject.labelLatLon.coordinate.longitude
            }
            processPolygonCoordinates(x: renderedObject.x, y: renderedObject.y)
        }
    }

    private func processId(_ object: OAMapObject?) {
        guard let object else { return }
        if (syntheticAmenity.obfId >= 0) && ObfConstants.isOsmUrlAvailable(object) {
            syntheticAmenity.obfId = object.obfId
        }
    }

    private func updateAmenitySubTypes(_ amenity: OAPOI, _ subTypesToAdd: String) {
        guard let existing = amenity.subType, !existing.isEmpty else {
            amenity.subType = subTypesToAdd
            return
        }

        var updated = existing
        let existingParts = existing.split(separator: ";")

        for subType in subTypesToAdd.split(separator: ";") {
            var isUnique = true
            for s in existingParts where s == subType {
                isUnique = false
                break
            }
            if isUnique {
                updated += ";" + subType
            }
        }

        amenity.subType = updated
    }

    private func processAmenity(_ amenity: OAPOI, contentLocales: inout Set<String>, isSingleObject: Bool) {
        processId(amenity)

        if syntheticAmenity.latitude.isNaN && !amenity.latitude.isNaN {
            syntheticAmenity.latitude = amenity.latitude
            syntheticAmenity.longitude = amenity.longitude
        }

        if let type = amenity.type, syntheticAmenity.type == nil {
            syntheticAmenity.type = type
        }

        if let subType = amenity.subType {
            updateAmenitySubTypes(syntheticAmenity, subType)
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

        if let amenityContent = amenity.localizedContent, amenityContent.count > 0 {
            let localizedContent = MutableOrderedDictionary<NSString, NSString>(dictionary: syntheticAmenity.localizedContent!)
            localizedContent.addEntries(from: amenityContent as! [NSString : NSString])
            syntheticAmenity.localizedContent = localizedContent
        }

        contentLocales.formUnion(amenity.getSupportedContentLocales())
    }

    private func processPolygonCoordinates(x: NSMutableArray, y: NSMutableArray) {
        guard let xArray = x as? [Any], let yArray = y as? [Any], let syntXArray = syntheticAmenity.x as? [Any], let syntYArray = syntheticAmenity.y as? [Any] else { return }

        if !xArray.isEmpty, !syntXArray.isEmpty {
            syntheticAmenity.x.addObjects(from: xArray)
        }
        if !yArray.isEmpty, !syntYArray.isEmpty {
            syntheticAmenity.y.addObjects(from: yArray)
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
        objects.sort {
            Self.getResourceType($0).rawValue < Self.getResourceType($1).rawValue
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
        if let obfResourceName {
            if obfResourceName.contains("basemap") {
                return .basemap
            }
            if obfResourceName.contains("travel") || obfResourceName.contains("wikivoyage") {
                return .travel
            }
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

    func setMapIconName(_ mapIconName: String) {
        syntheticAmenity.mapIconName = mapIconName
    }

    func setX(_ x: [Int]) {
        syntheticAmenity.x = x as? NSMutableArray ?? []
    }

    func setY(_ y: [Int]) {
        syntheticAmenity.y = y as? NSMutableArray ?? []
    }

    func addX(_ x: NSNumber) {
        syntheticAmenity.x.add(x)
    }

    func addY(_ y: NSNumber) {
        syntheticAmenity.y.add(y)
    }

    func hasGeometry() -> Bool {
        syntheticAmenity.x.count > 0 && syntheticAmenity.y.count > 0
    }

    func getPointsLength() -> Int {
        syntheticAmenity.x.count
    }

    func clearGeometry() {
        syntheticAmenity.x.removeAllObjects()
        syntheticAmenity.y.removeAllObjects()
    }

    static func convertRenderedObjectToAmenity(_ renderedObject: OARenderedObject) -> OAPOI {
        let am = OAPOI()

        let mapPoiTypes = OAPOIHelper.sharedInstance()
        am.type = mapPoiTypes?.getDefaultOtherCategoryType()
        am.subType = ""

        var pt: OAPOIType?
        var otherPt: OAPOIType?
        var subtype: String?

        let additionalInfo = NSMutableDictionary()

        guard let tags = renderedObject.tags as? [String: String] else { return am }

        for (tag, value) in tags {
            if tag == "name" {
                am.name = value
                continue
            }

            if tag.hasPrefix("name:") {
                let langSuffix = String(tag.dropFirst("name:".count))
                am.setName(langSuffix, name: value)
                continue
            }

            if tag == "amenity" {
                if pt != nil {
                    otherPt = pt
                }
                pt = mapPoiTypes?.getPoiType(byKey: value)
            } else {
                var poiType = mapPoiTypes?.getPoiType(byKey: "\(tag)_\(value)")
                if poiType == nil {
                    poiType = mapPoiTypes?.getPoiType(byKey: tag)
                }

                if let foundType = poiType {
                    if pt != nil {
                        otherPt = foundType
                    } else {
                        pt = foundType
                        subtype = value
                    }
                }
            }

            if value.isEmpty && otherPt == nil {
                otherPt = mapPoiTypes?.getPoiType(byKey: tag)
            }

            if otherPt == nil {
                if let poiType = mapPoiTypes?.getPoiType(byKey: value), poiType.getOsmTag() == tag {
                    otherPt = poiType
                }
            }

            if !value.isEmpty {
                let translate = mapPoiTypes?.getTranslation("\(tag)_\(value)")
                let translate2 = mapPoiTypes?.getTranslation(value)

                if let t1 = translate, let t2 = translate2 {
                    additionalInfo[t1] = t2
                } else {
                    additionalInfo[tag] = value
                }
            }
        }

        if let primaryType = pt {
            am.type = primaryType
        } else if let secondaryType = otherPt {
            am.type = secondaryType
            am.subType = secondaryType.name
        }

        if let st = subtype {
            am.subType = st
        }

        if let type = ObfConstants.getOsmEntityType(renderedObject) {
            let osmId = ObfConstants.getOsmObjectId(renderedObject)
            let objectId = ObfConstants.createMapObjectIdFromOsmId(osmId, type: type)
            am.obfId = objectId
        }

        if let finalInfo = additionalInfo as? [String: String] {
            am.setAdditionalInfo(finalInfo)
        }
        am.x = renderedObject.x
        am.y = renderedObject.y

        return am
    }

    static func getLangForTravel(_ object: Any) -> String {
        var amenity: OAPOI?

        if let poi = object as? OAPOI {
            amenity = poi
        }
        if let detailsObject = object as? BaseDetailsObject {
            amenity = detailsObject.syntheticAmenity
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
        switch object {
        case is BaseDetailsObject:
            return 1
        case is OAPOI:
            return 2
        case is OATransportStop:
            return 3
        case is OARenderedObject:
            return 4
        default:
            return 5
        }
    }
}
