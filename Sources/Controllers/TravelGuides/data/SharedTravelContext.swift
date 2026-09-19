//
//  SharedTravelContext.swift
//  OsmAnd
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

/// What the shared `TravelObfHelper` asks of the app: which obf files to search, the language, and
/// where the map is looking.
///
/// Deciding which files are installed and in what order they are consulted stays here, because it
/// depends on downloads and map settings that OsmAndShared knows nothing about.
final class SharedTravelContext: NSObject, TravelObfContext {

    static let shared = SharedTravelContext()

    private override init() {
        super.init()
    }

    func getWikivoyageRepositories() -> [AmenityIndexRepository] {
        SharedObfReaders.shared.travelRepositories()
    }

    func getTravelGpxRepositories() -> [AmenityIndexRepository] {
        SharedObfReaders.shared.travelAndMapRepositories()
    }

    func getLanguage() -> String {
        OAUtilities.currentLang() ?? "en"
    }

    func getMapLocation() -> KLatLon? {
        guard let location = OATravelGuidesHelper.getMapCenter() else { return nil }
        return KLatLon(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }

    func getAppVersion() -> String {
        OAAppVersion.getFullVersionWithAppName()
    }
}

/// The saved articles, as the shared helper asks for them. The storage itself stays in
/// `TravelLocalDataHelper`, which speaks the app's own `TravelArticle`, so each article is
/// converted at this boundary.
final class SharedTravelBookmarks: NSObject, TravelBookmarks {

    static let shared = SharedTravelBookmarks()

    private var storage: TravelLocalDataHelper { TravelLocalDataHelper.shared }

    private override init() {
        super.init()
    }

    func refreshCachedData() {
        storage.refreshCachedData()
    }

    func getSavedArticle(file: KFile?, routeId: String?, lang: String?) -> OsmAndShared.TravelArticle? {
        guard let routeId, let lang else { return nil }
        let saved = storage.getSavedArticle(file: file?.name() ?? "", routeId: routeId, lang: lang)
        return saved.map(SharedTravelArticles.toShared)
    }

    func getSavedArticles(file: KFile?, routeId: String?) -> [OsmAndShared.TravelArticle] {
        guard let routeId else { return [] }
        return storage.getSavedArticles(file: file?.name() ?? "", routeId: routeId)
            .map(SharedTravelArticles.toShared)
    }

    func addArticleToSaved(article: OsmAndShared.TravelArticle) {
        storage.addArticleToSaved(article: SharedTravelArticles.toApp(article))
    }

    func removeArticleFromSaved(article: OsmAndShared.TravelArticle) {
        storage.removeArticleFromSaved(article: SharedTravelArticles.toApp(article))
    }
}

/// Copies an article between the app's model and the shared one, field for field.
///
/// The two carry the same fields under the same names; they differ in how they name a file - a path
/// here, a `KFile` there - and in the gpx they hold, which is not copied: it is built from the obf
/// files, never stored.
enum SharedTravelArticles {

    static func toShared(_ article: TravelArticle) -> OsmAndShared.TravelArticle {
        let shared: OsmAndShared.TravelArticle
        if let gpx = article as? TravelGpx {
            let sharedGpx = OsmAndShared.TravelGpx()
            sharedGpx.user = gpx.user
            sharedGpx.activityType = gpx.activityType ?? ""
            sharedGpx.totalDistance = gpx.totalDistance
            sharedGpx.diffElevationUp = gpx.diffElevationUp
            sharedGpx.diffElevationDown = gpx.diffElevationDown
            sharedGpx.maxElevation = gpx.maxElevation
            sharedGpx.minElevation = gpx.minElevation
            sharedGpx.avgElevation = gpx.avgElevation
            sharedGpx.isSuperRoute = gpx.isSuperRoute
            shared = sharedGpx
        } else {
            shared = OsmAndShared.TravelArticle()
        }
        shared.file = article.file.map { KFile(filePath: $0) }
        shared.title = article.title
        shared.content = article.content
        shared.isPartOf = article.isPartOf
        shared.isParentOf = article.isParentOf ?? ""
        shared.lat = article.lat
        shared.lon = article.lon
        shared.imageTitle = article.imageTitle
        shared.routeId = article.routeId
        shared.ref = article.ref
        shared.routeSource = article.routeSource ?? ""
        shared.originalId = Int64(bitPattern: article.originalId)
        shared.lang = article.lang
        shared.contentsJson = article.contentsJson
        shared.aggregatedPartOf = article.aggregatedPartOf
        shared.description_ = article.descr
        shared.lastModified = Int64(article.lastModified)
        shared.routeRadius = Int32(article.routeRadius)
        return shared
    }

    static func toApp(_ shared: OsmAndShared.TravelArticle) -> TravelArticle {
        let article: TravelArticle
        if let sharedGpx = shared as? OsmAndShared.TravelGpx {
            let gpx = TravelGpx()
            gpx.user = sharedGpx.user
            gpx.activityType = sharedGpx.activityType
            gpx.totalDistance = sharedGpx.totalDistance
            gpx.diffElevationUp = sharedGpx.diffElevationUp
            gpx.diffElevationDown = sharedGpx.diffElevationDown
            gpx.maxElevation = sharedGpx.maxElevation
            gpx.minElevation = sharedGpx.minElevation
            gpx.avgElevation = sharedGpx.avgElevation
            gpx.isSuperRoute = sharedGpx.isSuperRoute
            article = gpx
        } else {
            article = TravelArticle()
        }
        article.file = shared.file?.name()
        article.title = shared.title
        article.content = shared.content
        article.isPartOf = shared.isPartOf
        article.isParentOf = shared.isParentOf
        article.lat = shared.lat
        article.lon = shared.lon
        article.imageTitle = shared.imageTitle
        article.routeId = shared.routeId
        article.ref = shared.ref
        article.routeSource = shared.routeSource
        article.originalId = UInt64(bitPattern: shared.originalId)
        article.lang = shared.lang
        article.contentsJson = shared.contentsJson
        article.aggregatedPartOf = shared.aggregatedPartOf
        article.descr = shared.description_
        article.lastModified = TimeInterval(shared.lastModified)
        article.routeRadius = Int(shared.routeRadius)
        article.bbox31 = shared.getBbox31()
        return article
    }
}

/// The shared travel helper, built once the poi types are loaded.
@objcMembers
final class SharedTravel: NSObject {

    /// Reads poi_types.xml into the shared registry. The obf reader needs it to name the amenities
    /// it decodes, and the travel code needs it to read an activity back out of a route's subtype.
    /// `OAPOIHelper` parses the same file for the app's own model; the two live side by side until
    /// the search moves to OsmAndShared.
    static func initPoiTypes() {
        guard !MapPoiTypes.companion.getDefaultNoInit().isInit() else { return }
        guard let xml = PlatformUtil.shared.getOsmAndContext().getAssetAsString(name: "poi_types.xml") else {
            NSLog("SharedTravel: poi_types.xml is not in the bundle, travel search will not work")
            return
        }
        let types = MapPoiTypes(resourceName: nil)
        types.doInitFromString(xml: xml)
        MapPoiTypes.companion.setDefault(types: types)
    }

    static let helper: OsmAndShared.TravelObfHelper = {
        initPoiTypes()
        return OsmAndShared.TravelObfHelper(context: SharedTravelContext.shared,
                                            bookmarks: SharedTravelBookmarks.shared)
    }()
}
