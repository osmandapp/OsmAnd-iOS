//
//  TravelObfHelper.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 08.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

/// The travel guides, read out of the installed obf files.
///
/// The searching and the gpx building live in OsmAndShared now; what is left here is the app's side
/// of it: its own article model, which the screens are written against, and the background task with
/// the spinner that the shared helper has no notion of.
@objc(OATravelObfHelper)
@objcMembers
final class TravelObfHelper: NSObject {

    static let shared = TravelObfHelper()

    // Read by TravelGpx when the map layers build one out of an amenity they found themselves.
    let ARTICLE_SEARCH_RADIUS = 50 * 1000
    let TRAVEL_GPX_CONVERT_FIRST_LETTER: Character = "A"
    let TRAVEL_GPX_CONVERT_FIRST_DIST = 5000
    let TRAVEL_GPX_CONVERT_MULT_1 = 2
    let TRAVEL_GPX_CONVERT_MULT_2 = 5

    private let localDataHelper = TravelLocalDataHelper.shared

    private var helper: OsmAndShared.TravelObfHelper { SharedTravel.helper }

    private override init() {
        super.init()
    }

    func getBookmarksHelper() -> TravelLocalDataHelper {
        localDataHelper
    }

    func initializeDataOnAppStartup() {
        //override
    }

    func initializeDataToDisplay(resetData: Bool) {
        helper.initializeDataToDisplay(resetData: resetData)
    }

    /// One more page of popular articles. The shared helper keeps the radius it has reached, so
    /// asking again without resetting widens the search.
    func loadPopularArticles() {
        helper.initializeDataToDisplay(resetData: false)
    }

    func getPopularArticles() -> [TravelArticle] {
        helper.getPopularArticles().map { SharedTravelArticles.toApp($0) }
    }

    func isAnyTravelBookPresent() -> Bool {
        helper.isAnyTravelBookPresent()
    }

    func isTravelGpxTags(_ tags: [String: String]) -> Bool {
        helper.isTravelGpxTags(tags: tags)
    }

    // MARK: - Search

    /// Articles whose name starts with `searchQuery`, in the app language and then in english.
    ///
    /// Raising the request number first makes the search that is still running for the previous
    /// keystroke give up where it stands, instead of reading every travel file to the end.
    func search(searchQuery: String) -> [TravelSearchResult] {
        let reqNumber = helper.requestNumber &+ 1
        helper.requestNumber = reqNumber
        return helper.search(searchQuery: searchQuery, reqNumber: reqNumber)
            .map { SharedTravelArticles.toApp($0) }
    }

    /// The tree of parent and child articles shown in the article's navigation screen.
    func getNavigationMap(article: TravelArticle) -> [TravelSearchResult: [TravelSearchResult]] {
        var res = [TravelSearchResult: [TravelSearchResult]]()
        let navigationMap = helper.getNavigationMap(article: SharedTravelArticles.toShared(article))
        for (header, children) in navigationMap {
            res[SharedTravelArticles.toApp(header)] = children.map { SharedTravelArticles.toApp($0) }
        }
        return res
    }

    /// Whether a route subtype passes a travel filter. Called from the amenity searcher, which does
    /// its own reading through OsmAndCore and only needs the rule.
    func searchFilterShouldAccept(_ subcategory: String?, filterSubcategories: [String]?) -> Bool {
        guard let subcategory, let filterSubcategories else { return false }

        return filterSubcategories.contains {
            // include routes:routes_xxx with routes:route_track filter
            $0 == subcategory ||
            ($0 == ROUTE_TRACK && subcategory.hasPrefix(ROUTES_PREFIX))
        }
    }

    /// The track carrying `routeId`, looked for around `location`. Used when a route is tapped on
    /// the map and nothing but its id is known.
    func searchTravelGpx(location: CLLocation, routeId: String) -> TravelGpx? {
        guard !routeId.isEmpty else { return nil }

        let latLon = KLatLon(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        guard let found = helper.searchTravelGpx(location: latLon, routeId: routeId) else {
            NSLog("searchTravelGpx(%f %f, %@) failed", location.coordinate.latitude, location.coordinate.longitude, routeId)
            return nil
        }
        return SharedTravelArticles.toApp(found) as? TravelGpx
    }

    /// The tracks drawn under `location` that carry one of `osmRouteTypeNames`, read out of the map
    /// section. Used when a route is tapped on the map and the tap carries no route id: what is
    /// known is which route types the style is drawing.
    func searchTravelGpx(location: CLLocation, osmRouteTypeNames: Set<String>) -> [TravelGpx] {
        guard !osmRouteTypeNames.isEmpty else { return [] }

        let latLon = KLatLon(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        return helper.searchTravelGpxByRouteTypes(location: latLon, osmRouteTypeTags: osmRouteTypeNames)
            .compactMap { SharedTravelArticles.toApp($0) as? TravelGpx }
    }

    // MARK: - Articles

    func getArticleById(articleId: TravelArticleIdentifier, lang: String?, readGpx: Bool, callback: GpxReadDelegate?) -> TravelArticle? {
        let found = helper.getArticleById(articleId: SharedTravelArticles.toShared(articleId),
                                          lang: lang,
                                          readGpx: false)
        return converted(found, lang: lang, readGpx: readGpx, callback: callback)
    }

    func getArticleByTitle(title: String, lang: String, readGpx: Bool, callback: GpxReadDelegate?) -> TravelArticle? {
        let found = helper.getArticleByTitle(title: title, lang: lang, readGpx: false)
        return converted(found, lang: lang, readGpx: readGpx, callback: callback)
    }

    func getArticleBy(title: String, lang: String) -> TravelArticle? {
        localDataHelper.getArticle(title: title, lang: lang)
            ?? getArticleByTitle(title: title, lang: lang, readGpx: false, callback: nil)
    }

    func findSavedArticle(savedArticle: TravelArticle) -> TravelArticle? {
        guard let found = helper.findSavedArticle(savedArticle: SharedTravelArticles.toShared(savedArticle)) else {
            return nil
        }
        return SharedTravelArticles.toApp(found)
    }

    func getArticleId(title: String, lang: String) -> TravelArticleIdentifier? {
        guard let found = helper.getArticleId(title: title, lang: lang) else { return nil }
        return SharedTravelArticles.toApp(found)
    }

    func getArticleLangs(articleId: TravelArticleIdentifier) -> [String] {
        helper.getArticleLangs(articleId: SharedTravelArticles.toShared(articleId))
    }

    func getArticleByLangs(articleId: TravelArticleIdentifier) -> [String: TravelArticle] {
        helper.getArticleByLangs(articleId: SharedTravelArticles.toShared(articleId))
            .mapValues { SharedTravelArticles.toApp($0) }
    }

    /// The shared helper can build the gpx file itself, but it does it on the thread that asked, and
    /// these calls come from the screens. The file is built in the background instead, the way the
    /// travel screens expect: a spinner while it runs, the article handed back through the callback.
    private func converted(_ found: OsmAndShared.TravelArticle?, lang: String?, readGpx: Bool, callback: GpxReadDelegate?) -> TravelArticle? {
        guard let found else { return nil }

        let article = SharedTravelArticles.toApp(found)
        if readGpx && (!(lang ?? "").isEmpty || article is TravelGpx) {
            readGpxFile(article: article, callback: callback)
        }
        return article
    }

    // MARK: - Gpx files

    func readGpxFile(article: TravelArticle, callback: GpxReadDelegate?) {
        if !article.gpxFileRead && callback != nil && callback!.isGpxReading == false {
            callback?.isGpxReading = true
            GpxFileReader(article: article, callback: callback).execute()
        } else if callback != nil && article.gpxFileRead {
            callback?.isGpxReading = false
            callback?.onGpxFileRead(gpxFile: article.gpxFile, article: article)
        }
    }

    func buildGpxFile(article: TravelArticle) -> OAGPXDocumentAdapter? {
        guard let gpxFile = helper.readGpxFile(article: SharedTravelArticles.toShared(article)) else {
            return nil
        }
        let adapter = OAGPXDocumentAdapter()
        adapter.object = gpxFile
        return adapter
    }

    func getGPXName(article: TravelArticle) -> String {
        article.getGpxFileName() + GPX_FILE_EXT
    }

    func createGpxFile(article: TravelArticle) -> String {
        OATravelGuidesHelper.createGpxFile(article, fileName: getGPXName(article: article))
    }

    func getWikivoyageFileName() -> String? {
        helper.getWikivoyageFileName()
    }

    func saveOrRemoveArticle(article: TravelArticle, save: Bool) {
        if save {
            localDataHelper.addArticleToSaved(article: article)
        } else {
            localDataHelper.removeArticleFromSaved(article: article)
        }
    }

    func createTitle(name: String) -> String {
        OAUtilities.capitalizeFirstLetter(name) ?? ""
    }

    func openTrackMenu(article: TravelArticle, gpxFileName: String, latLon: CLLocation, adjustMapPosition: Bool) {
        let callback = OpenTrackMenuDelegate()
        callback.gpxFileName = gpxFileName
        callback.latLon = latLon
        readGpxFile(article: article, callback: callback)
    }
}

final private class OpenTrackMenuDelegate: GpxReadDelegate {
    
    var isGpxReading: Bool = false
    var latLon: CLLocation?
    var gpxFileName: String?
    
    func onGpxFileRead(gpxFile: OAGPXDocumentAdapter?, article: TravelArticle) {
        guard let latLon, let gpxFileName, let gpxFile, let file = gpxFile.object else { return }
        
        // For rotutes from map force use gpx data for Analysis.
        // Android replaces it on UI (TrackMenuFragment).
        var analysis: GpxTrackAnalysis?
        if let routeId = article.routeId, !routeId.isEmpty {
            analysis = gpxFile.object.getAnalysis(fileTimestamp: 0, fromDistance: nil, toDistance: nil, pointsAnalyzer: PlatformUtil.shared.getTrackPointsAnalyser())
        } else {
            analysis = article.getAnalysis()
        }
        guard let analysis else { return }
    
        let wptPt = WptPt()
        wptPt.lat = latLon.coordinate.latitude
        wptPt.lon = latLon.coordinate.longitude
        let safeFileName = gpxFileName.appending(GPX_FILE_EXT)
                
        OAGPXUIHelper.saveAndOpenGpx(gpxFileName, filepath: safeFileName, gpxFile: file, selectedPoint: wptPt, analysis: analysis, routeKey: nil, forceAdjustCentering: true)
    }
}

/// Builds an article's gpx file off the screen thread. Reading every travel file for the segments of
/// one route takes seconds on a large one.
final class GpxFileReader {
    
    var article: TravelArticle?
    var callback: GpxReadDelegate?
    
    init(article: TravelArticle, callback: GpxReadDelegate?) {
        self.article = article
        self.callback = callback
    }
    
    func execute() {
        onPreExecute()
        DispatchQueue.global(qos: .default).async {
            let file = self.doInBackground()
            DispatchQueue.main.async {
                self.onPostExecute(gpxFile: file)
            }
        }
    }
    
    func onPreExecute() {
        if let callback {
            OARootViewController.instance().view.addSpinner(inCenterOfCurrentView: true)
            callback.onGpxFileReading?()
        }
    }
    
    func doInBackground() -> OAGPXDocumentAdapter? {
        guard let article else { return nil }
        return TravelObfHelper.shared.buildGpxFile(article: article)
    }
    
    func onPostExecute(gpxFile: OAGPXDocumentAdapter?) {
        if let article {
            article.gpxFileRead = true
            article.gpxFile = gpxFile
            if let callback {
                callback.onGpxFileRead(gpxFile: gpxFile, article: article)
            }
        }
        OARootViewController.instance().view.removeSpinner()
    }
}
