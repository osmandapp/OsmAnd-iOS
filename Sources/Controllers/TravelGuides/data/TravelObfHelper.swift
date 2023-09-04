//
//  TravelObfHelper.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 08.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OATravelObfHelper)
@objcMembers
class TravelObfHelper : NSObject {
//class TravelObfHelper : NSObject, TravelHelper {
    
    static let shared = TravelObfHelper()
    
    let WORLD_WIKIVOYAGE_FILE_NAME = "World_wikivoyage.travel.obf"
    let DEFAULT_WIKIVOYAGE_TRAVEL_OBF = "Default_wikivoyage.travel.obf"
    let ARTICLE_SEARCH_RADIUS = 50 * 1000
    let SAVED_ARTICLE_SEARCH_RADIUS = 30 * 1000
    let MAX_SEARCH_RADIUS = 800 * 1000
    
    let TRAVEL_GPX_CONVERT_FIRST_LETTER: Character = "A"
    let TRAVEL_GPX_CONVERT_FIRST_DIST = 5000
    let TRAVEL_GPX_CONVERT_MULT_1 = 2
    let TRAVEL_GPX_CONVERT_MULT_2 = 5
    
    private var popularArticles = PopularArticles()
    private var cachedArticles: [TravelArticleIdentifier : [String:TravelArticle] ] = [:]
    private let localDataHelper: TravelLocalDataHelper
    private var searchRadius: Int
    private var foundAmenitiesIndex: Int = 0
    private var foundAmenities: [OAFoundAmenity] = []
    
    private override init() {
//        this.app = app;
//        collator = OsmAndCollator.primaryCollator();
        localDataHelper = TravelLocalDataHelper();
        searchRadius = ARTICLE_SEARCH_RADIUS
    }
    
//    func getBookmarksHelper() -> TravelLocalDataHelper {
//        <#code#>
//    }
//
//    func initializeDataOnAppStartup() {
//        <#code#>
//    }
    
    func initializeDataToDisplay(resetData: Bool) {
        if resetData {
            foundAmenities.removeAll()
            foundAmenitiesIndex = 0
            popularArticles.clear()
            searchRadius = ARTICLE_SEARCH_RADIUS
        }
        localDataHelper.refreshCachedData();
        loadPopularArticles()
    }
    
    func loadPopularArticles() -> PopularArticles {
        let lang = OAUtilities.currentLang()
        let popularArticles = PopularArticles(artcles: popularArticles)
        if isAnyTravelBookPresent() {
            var articlesLimitReached = false
            repeat {
                if foundAmenities.count - foundAmenitiesIndex < PopularArticles.ARTICLES_PER_PAGE {
                    
                    //var location = OARootViewController.instance().mapPanel.mapViewController.getMapLocation()
                    let location = OATravelGuidesHelper.getMapCenter()
                    
                    for reader in getReaders() {
                        foundAmenities.append(contentsOf: searchAmenity(lat: location!.coordinate.latitude, lon: location!.coordinate.longitude, reader: reader, searchRadius: searchRadius, zoom: -1, searchFilter: ROUTE_ARTICLE, lang: lang!) )
                        //foundAmenities.append(contentsOf: searchAmenity(lat: location!.coordinate.latitude, lon: location!.coordinate.longitude, reader: reader, searchRadius: searchRadius / 5, zoom: 15, searchFilter: ROUTE_TRACK, lang: nil) )
                    }
                    
                    if foundAmenities.count > 0 {
                        foundAmenities.sort { a, b in
                            let d1 = location!.distance(from: CLLocation(latitude: a.amenity.latitude(), longitude: a.amenity.longitude()))
                            let d2 = location!.distance(from: CLLocation(latitude: b.amenity.latitude(), longitude: b.amenity.longitude()))
                            
                            //TODO: check. Invert if needed
                            return d1 < d2
                        }
                    }
                }
                searchRadius *= 2
                while foundAmenitiesIndex < foundAmenities.count - 1 {
                    let fileAmenity = foundAmenities[foundAmenitiesIndex]
                    let file = fileAmenity.file!
                    let amenity = fileAmenity.amenity!
                    if amenity.name() != nil && amenity.name().length > 0 {
                        let routeId = amenity.getAdditionalInfo()[ROUTE_ID] ?? ""
                        if !popularArticles.containsByRouteId(routeId: routeId) {
                            let article = cacheTravelArticles(file: file, amenity: amenity, lang: lang!, readPoints: false, callback: nil)
                            if article != nil && !popularArticles.contains(article: article!) {
                                if !popularArticles.add(article: article!) {
                                    articlesLimitReached = true
                                    break
                                }
                            }
                        }
                    }
                    foundAmenitiesIndex += 1
                }
            } while !articlesLimitReached && searchRadius < MAX_SEARCH_RADIUS
        }
        self.popularArticles = popularArticles
        return popularArticles
    }
    
    func searchGpx(latLon: CLLocationCoordinate2D, filter: String?, ref: String?) -> TravelGpx? {
        var foundAmenities = [OAFoundAmenity]()
        var searchRadius = ARTICLE_SEARCH_RADIUS
        var travelGpx: TravelGpx? = nil
        
        repeat {
            
            for reader in getReaders() {
                foundAmenities.append(contentsOf: searchAmenity(lat: latLon.latitude, lon: latLon.longitude, reader: reader, searchRadius: searchRadius, zoom: 15, searchFilter: filter!, lang: nil) )
            }
            
            if foundAmenities.count > 0 {
                for foundGpx in foundAmenities {
                    let amenity = foundGpx.amenity!
                    if amenity.getRouteId() == filter ||
                        amenity.name() == filter ||
                        amenity.getRef() == ref {
                        travelGpx = getTravelGpx(file:foundGpx.file!, amenity: amenity)
                        break
                    }
                }
            }
            searchRadius *= 2
        } while travelGpx == nil && searchRadius < MAX_SEARCH_RADIUS
        return travelGpx
    }
    
    func searchAmenity(lat: Double, lon: Double, reader: String, searchRadius: Int, zoom: Int, searchFilter: String, lang: String?) -> [OAFoundAmenity] {
        
        var results: [OAFoundAmenity] = []
        func publish(poi: OAPOIAdapter?) -> Bool {
            if lang == nil || lang?.length == 0 || poi!.getNamesMap(true)!.keys.contains(lang!) {
                results.append(OAFoundAmenity(file: reader, amenity: poi))
            }
            return false
        }
        
        OATravelGuidesHelper.searchAmenity(lat, lon: lon, reader: reader, radius: Int32(searchRadius), searchFilter: searchFilter, publish:publish)
        return results
    }
    
    func cacheTravelArticles(file: String?, amenity: OAPOIAdapter, lang: String?, readPoints: Bool, callback: GpxReadCallback?) -> TravelArticle? {
        var article: TravelArticle? = nil
        var articles: [String: TravelArticle]? = [:]
        if amenity.subtype() == ROUTE_TRACK {
            articles = readRoutePoint(file: file!, amenity: amenity)
        } else {
            articles = readArticles(file: file!, amenity: amenity)
        }
        if articles != nil && articles!.count > 0 {
            var i = articles!.values.makeIterator()
            let newArticleId = i.next()!.generateIdentifier()
            cachedArticles[newArticleId] = articles
            article = getCachedArticle(articleId: newArticleId, lang: lang, readGpx: readPoints, callback: callback)
        }
        return article
    }
    
    func readRoutePoint(file: String, amenity: OAPOIAdapter) -> [String : TravelArticle] {
        var articles: [String : TravelArticle] = [:]
        var res = getTravelGpx(file:file, amenity: amenity)
        articles[""] = res
        return articles
    }
    
    func getTravelGpx(file: String?, amenity: OAPOIAdapter) -> TravelGpx {
        
        var travelGpx = TravelGpx()
        //TODO: check it
        travelGpx.file = file
        //TODO: check it
        //String title = amenity.getName("en");
        let title = amenity.name()
        
        travelGpx.lat = amenity.latitude()
        travelGpx.lon = amenity.longitude()
        travelGpx.description = amenity.getTagContent(DESCRIPTION)
    
        travelGpx.routeId = amenity.getTagContent(ROUTE_ID)
        travelGpx.user = amenity.getTagContent(TravelGpx.USER)
        travelGpx.activityType = amenity.getTagContent(TravelGpx.ACTIVITY_TYPE)
        travelGpx.ref = amenity.getRef()
        
        travelGpx.totalDistance = Float(amenity.getTagContent(TravelGpx.DISTANCE)) ?? 0
        travelGpx.diffElevationUp = Double(amenity.getTagContent(TravelGpx.DIFF_ELEVATION_UP)) ?? 0
        travelGpx.diffElevationDown = Double(amenity.getTagContent(TravelGpx.DIFF_ELEVATION_DOWN)) ?? 0
        travelGpx.maxElevation = Double(amenity.getTagContent(TravelGpx.MAX_ELEVATION)) ?? 0
        travelGpx.minElevation = Double(amenity.getTagContent(TravelGpx.MIN_ELEVATION)) ?? 0
        travelGpx.avgElevation = Double(amenity.getTagContent(TravelGpx.AVERAGE_ELEVATION)) ?? 0
        
        let radius: String = amenity.getTagContent(TravelGpx.ROUTE_RADIUS)
        if radius != nil {
            OAUtilities.convertChar(toDist: String(radius[0]), firstLetter: String(TRAVEL_GPX_CONVERT_FIRST_LETTER), firstDist: Int32(TRAVEL_GPX_CONVERT_MULT_1), mult1: 0, mult2: Int32(TRAVEL_GPX_CONVERT_MULT_2))
            
        }
        return travelGpx
    }
    
    func getSearchFilter(filterSubcategoryies: [String]) -> OASearchPoiTypeFilter {
        return OASearchPoiTypeFilter { type, subcategory in
            for filterSubcategory in filterSubcategoryies {
                return filterSubcategory == filterSubcategory
            }
            return false
        } emptyFunction: {
            return false
        } getTypesFunction: {
            return nil
        }
    }
    
    func readArticles(file: String, amenity: OAPOIAdapter) -> [String : TravelArticle] {
        var articles: [String : TravelArticle] = [:]
        var langs = getLanguages(amenity: amenity)
        for lang in langs {
            articles[lang] = readArticle(file: file, amenity: amenity, lang: lang)
        }
        return articles
    }
    
    func readArticle(file: String, amenity: OAPOIAdapter, lang: String) -> TravelArticle {
        
        var res = TravelArticle()
        res.file = file
        var title = amenity.getNames(lang, defTag: "en").first
        if title == nil || title!.length == 0 {
            title = amenity.name()
        }
        res.title = title
        res.content = amenity.getDescription(lang)
        res.isPartOf = amenity.getTagContent(IS_PART, lang:lang) ?? ""
        res.isParentOf = amenity.getTagContent(IS_PARENT_OF, lang:lang) ?? ""
        res.lat = amenity.latitude()
        res.lon = amenity.longitude()
        res.imageTitle = amenity.getTagContent(IMAGE_TITLE) ?? ""
        res.routeId = amenity.getTagContent(ROUTE_ID) ?? ""
        res.routeSource = amenity.getTagContent(ROUTE_SOURCE) ?? ""
        res.originalId = 0
        res.lang = lang
        res.contentsJson = amenity.getLocalizedContent(CONTENT_JSON, lang:lang) ?? ""
        res.aggregatedPartOf = amenity.getStrictTagContent(IS_AGGR_PART, lang: lang)
        return res
    }
    
    func isAnyTravelBookPresent() -> Bool {
        return getReaders().count > 0
    }
    
    func isOnlyDefaultTravelBookPresent() -> Bool {
        let books = TravelObfHelper.shared.getReaders()
        if (books.count == 0 ||
            books.count == 1 && books[0] == DEFAULT_WIKIVOYAGE_TRAVEL_OBF) {
            return true
        }
        return false
    }
    
    func search(searchQuery: String) -> [TravelSearchResult] {
       
        //TODO: implement
        return []
    }
    
    func getLanguages(amenity: OAPOIAdapter) -> Set<String> {
        var langs: Set<String> = []
        let descrStart = DESCRIPTION + ":"
        let partStart = IS_PART + ":"
        for infoTag in amenity.getAdditionalInfo().keys {
            if infoTag.hasPrefix(descrStart) {
                if infoTag.length > descrStart.length {
                    langs.insert( infoTag.substring(from: descrStart.length) )
                }
            } else if infoTag.hasPrefix(partStart) {
                if infoTag.length > partStart.length {
                    langs.insert( infoTag.substring(from: partStart.length) )
                }
            }
        }
        return langs
    }
    
    func sortSearchResults(results: [TravelSearchResult]) -> [TravelSearchResult] {
        var sortedResults = results
        sortedResults.sort { a, b in
            let titleA = a.getArticleTitle() ?? ""
            let titleB = b.getArticleTitle() ?? ""
            return titleA < titleB
        }
        return sortedResults
    }
    
    func getPopularArticles() -> [TravelArticle] {
        return popularArticles.getArticles()
    }
    
    func getNavigationMap(article: TravelArticle) -> [TravelSearchResult : [TravelSearchResult]] {
        let lang = article.lang
        let title = article.title
        if lang == nil || lang!.isEmpty || title == nil || title!.isEmpty {
            return [:]
        }
        
        var parts = [String]()
        let aggregatedPartOf = article.aggregatedPartOf
        if (aggregatedPartOf != nil && !aggregatedPartOf!.isEmpty) {
            let originalParts = aggregatedPartOf!.split(separator: ",")
            if (originalParts.count > 1) {
                parts = [String].init(repeating: "", count: originalParts.count)
                for i in 0..<originalParts.count {
                    parts[i] = String(originalParts[originalParts.count - i - 1])
                }
            } else {
                parts[0] = String(originalParts[0])
            }
        } else {
            parts = []
        }
        
        var navMap = [String : [TravelSearchResult]]()
        var headers = [String]()
        var headerObjs = [String : TravelSearchResult]()
        if parts.count > 0 {
            headers.append(contentsOf: parts)
            if article.isParentOf != nil && !article.isParentOf!.isEmpty {
                headers.append(title!)
            }
        }
        
        for header in headers {
            
            let parentArticle = getParentArticleByTitle(title: header, lang: lang!)
            if parentArticle == nil {
                continue
            }
            navMap[header] = [TravelSearchResult]()
            let isParentOf = parentArticle!.isParentOf!.split(separator: ";")
            for childSubsequence in isParentOf {
                let childTitle = String(childSubsequence)
                if !childTitle.isEmpty {
                    let searchResult = TravelSearchResult(routeId: "", articleTitle: childTitle, isPartOf: nil, imageTitle: nil, langs: [lang!])
                    var resultList = navMap[header]
                    if resultList == nil {
                        resultList = []
                    }
                    resultList!.append(searchResult)
                    navMap[header] = resultList
                    if headers.contains(childTitle) {
                        headerObjs[childTitle] = searchResult
                    }
                }
            }
        }
        
        var res: [TravelSearchResult : [TravelSearchResult]] = [:]
        for header in headers {
            var searchResult = headerObjs[header]
            var results = navMap[header]
            if results != nil {
                results = sortSearchResults(results: results!)
                let emptyResult = TravelSearchResult(routeId: "", articleTitle: header, isPartOf: nil, imageTitle: nil, langs: nil)
                searchResult = searchResult != nil ? searchResult : emptyResult
                res[searchResult!] = results
            }
        }
        
        return res
    }
    
    func getParentArticleByTitle(title: String, lang: String) -> TravelArticle? {
        var article: TravelArticle? = nil
        var amenities = [OAPOIAdapter]()
        
        for reader in getReaders() {
            OATravelGuidesHelper.searchAmenity(-1, lon: -1, reader: reader, radius: -1, searchFilter: ROUTE_ARTICLE) { amenity in
                if title == amenity!.getName(lang, transliterate: false) {
                    amenities.append(amenity!)
                    return true
                }
                return false
            }
            
            if amenities.count > 0 {
                article = readArticle(file: reader, amenity: amenities[0], lang: lang)
            }
        }
    
        return article
    }
    
    func getArticleById(articleId: TravelArticleIdentifier, lang: String?, readGpx: Bool, callback: GpxReadCallback?) -> TravelArticle? {
        let article = getCachedArticle(articleId: articleId, lang: lang, readGpx: readGpx, callback: callback)
        if article == nil {
            
            //TODO: implement
//            article = localDataHelper.getSavedArticle(articleId.file, articleId.routeId, lang);
//            if (article != null && callback != null && readGpx) {
//                callback.onGpxFileRead(article.gpxFile);
//            }
        }
        return article
    }
    
    func getCachedArticle(articleId: TravelArticleIdentifier, lang: String?, readGpx: Bool, callback: GpxReadCallback?) -> TravelArticle? {
        var article: TravelArticle? = nil
        var articles = cachedArticles[articleId]
        if (articles != nil) {
            if (lang == nil || lang!.length == 0) {
                var ac = articles!.values
                if (!ac.isEmpty) {
                    var it = ac.makeIterator()
                    article = it.next()
                }
            } else {
                article = articles![lang!]
                if article == nil {
                    article = articles![""]
                }
            }
        }
        if article == nil && articles == nil {
            article = findArticleById(articleId: articleId, lang: lang, readGpx: readGpx, callback: callback)
        }
        if article != nil && readGpx && (lang != nil && lang!.length > 0) || article is TravelGpx {
            readGpxFile(article: article!, callback: callback)
        }
        return article
    }
    
    func openTrackMenu(article: TravelArticle, gpxFileName: String, latLon: CLLocationCoordinate2D) {
        //TODO: implement
    }
    
    func readGpxFile(article: TravelArticle, callback: GpxReadCallback?) {
        if !article.gpxFileRead {
            
            //TODO: implement
            //new GpxFileReader(article, callback, getReaders()).executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
            
        } else if callback != nil {
            callback?.onGpxFileRead(gpxFile: article.gpxFile)
        }
    }
    
    func findArticleById(articleId: TravelArticleIdentifier, lang: String?, readGpx: Bool, callback: GpxReadCallback?) -> TravelArticle? {
        var article: TravelArticle? = nil
        let isDbArticle = articleId.file != nil && articleId.file!.hasSuffix(BINARY_WIKIVOYAGE_MAP_INDEX_EXT)
        var amenities: [OAPOIAdapter] = []
        
        for reader in getReaders() {
            if articleId.file != nil && articleId.file != reader && !isDbArticle {
                continue
            }
            
            func publishCallback(amenity: OAPOIAdapter?) -> Bool {
                var done = false
                if articleId.routeId == amenity!.getTagContent(ROUTE_ID) || isDbArticle {
                    amenities.append(amenity!)
                    done =  true
                }
                return done
            }
            
            if !articleId.lat.isNaN {
                if articleId.title != nil && articleId.title!.length > 0 {
                    OATravelGuidesHelper.searchAmenity(articleId.title ?? "", categoryName:ROUTE_ARTICLE, radius:Int32(ARTICLE_SEARCH_RADIUS), lat:articleId.lat, lon:articleId.lon, reader: reader, publish:publishCallback)
                } else {
                    OATravelGuidesHelper.searchAmenity(articleId.lat, lon: articleId.lon, reader: reader, radius: Int32(ARTICLE_SEARCH_RADIUS), searchFilter: ROUTE_ARTICLE, publish:publishCallback)
                    
                }
            } else {
                OATravelGuidesHelper.searchAmenity(Double.nan, lon: Double.nan, reader: reader, radius: -1, searchFilter: ROUTE_ARTICLE, publish:publishCallback)
            }
            
            if amenities.count > 0 {
                article = cacheTravelArticles(file: reader, amenity: amenities[0], lang: lang, readPoints: readGpx, callback: callback)
            }
        }
        return article
    }
    
    func findSavedArticle(savedArticle: TravelArticle) -> TravelArticle? {
        //TODO: implement
        return TravelArticle()
    }
    
//    func getEqualsTitleRequest(articleId: TravelArticleIdentifier, lang: String?, amenities: [OAPOIAdapter]) {
//
//    }
    
    func getArticleByTitle(title: String, lang: String, readGpx: Bool, callback: GpxReadCallback?) -> TravelArticle? {
        //TODO: implement
        return getArticleByTitle(title: title, rect: QuadRect(), lang: lang, readGpx: readGpx, callback: callback)
    }

    func getArticleByTitle(title: String, latLon: CLLocationCoordinate2D, lang: String, readGpx: Bool, callback: GpxReadCallback?) -> TravelArticle? {
        //TODO: implement
        return TravelArticle()
    }

    func getArticleByTitle(title: String, rect: QuadRect, lang: String, readGpx: Bool, callback: GpxReadCallback?) -> TravelArticle? {
        var article: TravelArticle? = nil
        var amenities: [OAPOIAdapter] = []
        var x: Int32 = 0
        var y: Int32 = 0
        var left: Int32 = 0
        var right: Int32 = Int32.max
        var top: Int32 = 0
        var bottom: Int32 = Int32.max
        if rect.height() > 0 && rect.width() > 0 {
            x = Int32(rect.centerX())
            y = Int32(rect.centerY())
            left = Int32(rect.left)
            right = Int32(rect.right)
            top = Int32(rect.top)
            bottom = Int32(rect.bottom)
        }
        
        for reader in getReaders() {
            
            OATravelGuidesHelper.searchAmenity(x, y: y, left: left, right: right, top: top, bottom: bottom, reader: reader, searchFilter: ROUTE_ARTICLE) { amenity in
                
                if title == amenity!.getName(lang, transliterate: false) {
                    amenities.append(amenity!)
                    return true
                }
                return false
            }
            
            if amenities.count > 0 {
                article = cacheTravelArticles(file: reader, amenity: amenities[0], lang: lang, readPoints: readGpx, callback: callback)
            }
            
        }
        
        return article
    }
    
    func getReaders() -> [String] {
        return OATravelGuidesHelper.getTravelGuidesObfList()
    }
    
    func getArticleId(title: String, lang: String) -> TravelArticleIdentifier? {
        var a: TravelArticle? = nil
        for articles in cachedArticles.values {
            for article in articles.values {
                if article.title == title {
                    a = article
                    break
                }
            }
        }
        if a == nil {
            var article = getArticleByTitle(title: title, lang: lang, readGpx: false, callback: nil)
            if article != nil {
                a = article
            }
        }
        return a != nil ? a!.generateIdentifier() : nil
    }
    
    func getArticleLangs(articleId: TravelArticleIdentifier) -> [String] {
        var res = [String]()
        let article = getArticleById(articleId: articleId, lang: "", readGpx: false, callback: nil)
        if article != nil {
            let articles = cachedArticles[article!.generateIdentifier()]
            if articles != nil {
                res.append(contentsOf: articles!.keys)
            }
        } else {
            //TODO: Implement localDataHelper
//            List<TravelArticle> articles = localDataHelper.getSavedArticles(articleId.file, articleId.routeId);
//            for (TravelArticle a : articles) {
//                res.add(a.getLang());
//            }
        }
        
        return res
    }
    
    func getGPXName(article: TravelArticle) -> String {
        //TODO: implement
        return ""
    }
    
    func createGpxFile(article: TravelArticle) -> String {
        //TODO: implement
        return ""
    }
    
    func getSelectedTravelBookName() -> String? {
        return nil
    }
    
    func getWikivoyageFileName() -> String? {
        return WORLD_WIKIVOYAGE_FILE_NAME
    }
    
    func saveOrRemoveArticle(article: TravelArticle, save: Bool) {
        //TODO: implement
    }
    
    func buildGpxFile(article: TravelArticle) -> OAGPXDocumentAdapter {
        //TODO: implement
        return OAGPXDocumentAdapter()
    }
    
    func createTitle(name: String) -> String {
        //TODO: implement
        return ""
    }
    
//    private class GpxFileReader extends AsyncTask<Void, Void, GPXFile> {}
    
}
