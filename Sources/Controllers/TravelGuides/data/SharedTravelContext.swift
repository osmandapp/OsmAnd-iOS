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
        let saved = storage.getSavedArticle(file: file?.name() ?? "",
                                            routeId: routeId ?? "",
                                            lang: lang ?? "")
        return saved.map { SharedTravelArticles.toShared($0) }
    }

    func getSavedArticles(file: KFile?, routeId: String?) -> [OsmAndShared.TravelArticle] {
        storage.getSavedArticles(file: file?.name() ?? "", routeId: routeId ?? "")
            .map { SharedTravelArticles.toShared($0) }
    }

    func addArticleToSaved(article: OsmAndShared.TravelArticle) {
        storage.addArticleToSaved(article: SharedTravelArticles.toApp(article))
    }

    func removeArticleFromSaved(article: OsmAndShared.TravelArticle) {
        storage.removeArticleFromSaved(article: SharedTravelArticles.toApp(article))
    }
}

/// Copies an article, an identifier and a search result between the app's model and the shared one.
///
/// The two models carry the same fields under the same names. They differ in two places: a file is
/// a bare name here, because that is what the saved-articles database holds, and a full path there,
/// because that is how the obf readers are keyed; and `lastModified` is seconds here and
/// milliseconds there.
///
/// Every converted pair is remembered in both directions, because the objects are not
/// interchangeable copies. The app hangs the built gpx file off its article, and the shared article
/// carries a bounding box that no setter exposes and that copying would drop - without it the gpx
/// build would search every travel file whole.
enum SharedTravelArticles {

    private static let appBySharedArticle =
        NSMapTable<OsmAndShared.TravelArticle, TravelArticle>.weakToWeakObjects()
    private static let lock = NSLock()

    // MARK: - Articles

    static func toShared(_ article: TravelArticle) -> OsmAndShared.TravelArticle {
        if let known = article.sharedArticle {
            return known
        }
        let shared = copyToShared(article)
        remember(app: article, shared: shared)
        return shared
    }

    static func toApp(_ shared: OsmAndShared.TravelArticle) -> TravelArticle {
        if let known = knownApp(for: shared) {
            return known
        }
        let article = copyToApp(shared)
        remember(app: article, shared: shared)
        return article
    }

    private static func remember(app: TravelArticle, shared: OsmAndShared.TravelArticle) {
        app.sharedArticle = shared
        lock.lock()
        appBySharedArticle.setObject(app, forKey: shared)
        lock.unlock()
    }

    private static func knownApp(for shared: OsmAndShared.TravelArticle) -> TravelArticle? {
        lock.lock()
        defer { lock.unlock() }
        return appBySharedArticle.object(forKey: shared)
    }

    private static func copyToShared(_ article: TravelArticle) -> OsmAndShared.TravelArticle {
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
        shared.file = sharedFile(named: article.file)
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
        shared.lastModified = Int64(article.lastModified * 1000)
        shared.routeRadius = Int32(article.routeRadius)
        if let shortLinkTiles = article.shortLinkTiles {
            // the box the route covers. Without it the builder falls back to routeRadius, which for
            // a long route is a thousand kilometres, and every installed file then intersects the
            // search box and gets read through
            shared.doInitShortLinkTiles(shortLinkTiles: shortLinkTiles)
        }
        return shared
    }

    private static func copyToApp(_ shared: OsmAndShared.TravelArticle) -> TravelArticle {
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
        article.lastModified = TimeInterval(shared.lastModified) / 1000
        article.routeRadius = Int(shared.routeRadius)
        article.bbox31 = shared.getBbox31()
        return article
    }

    // MARK: - Identifiers and search results

    static func toShared(_ identifier: TravelArticleIdentifier) -> OsmAndShared.TravelArticleIdentifier {
        OsmAndShared.TravelArticleIdentifier(file: sharedFile(named: identifier.file),
                                             lat: identifier.lat,
                                             lon: identifier.lon,
                                             title: identifier.title,
                                             routeId: identifier.routeId,
                                             routeSource: identifier.routeSource)
    }

    static func toApp(_ identifier: OsmAndShared.TravelArticleIdentifier) -> TravelArticleIdentifier {
        TravelArticleIdentifier(file: identifier.file?.name(),
                                lat: identifier.lat,
                                lon: identifier.lon,
                                title: identifier.title,
                                routeId: identifier.routeId,
                                routeSource: identifier.routeSource)
    }

    static func toApp(_ result: OsmAndShared.WikivoyageSearchResult) -> TravelSearchResult {
        let converted = TravelSearchResult(routeId: result.getArticleRouteId() ?? "",
                                           articleTitle: result.getArticleTitle() ?? "",
                                           isPartOf: result.isPartOf,
                                           imageTitle: result.imageTitle,
                                           langs: result.langs)
        converted.articleId = toApp(result.articleId)
        return converted
    }

    /// The installed file that carries this name, by full path. An uninstalled one keeps its bare
    /// name: nothing will be found in it either way, and a saved article has to hold on to the name
    /// its database row was written with.
    private static func sharedFile(named name: String?) -> KFile? {
        guard let name, !name.isEmpty else { return nil }
        return KFile(filePath: OAObfFileList.path(forFileName: name) ?? name)
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
