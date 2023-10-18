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
    private var cachedArticles: [Int : [String:TravelArticle] ] = [:]
    private let localDataHelper: TravelLocalDataHelper
    private var searchRadius: Int
    private var foundAmenitiesIndex: Int = 0
    private var foundAmenities: [OAFoundAmenity] = []
    
    private override init() {
        localDataHelper = TravelLocalDataHelper();
        searchRadius = ARTICLE_SEARCH_RADIUS
    }
    
    func getBookmarksHelper() -> TravelLocalDataHelper {
        return localDataHelper
    }

    func initializeDataOnAppStartup() {
        //override
    }
    
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
                    let location = OATravelGuidesHelper.getMapCenter()
                    
                    for reader in getReaders() {
                        foundAmenities.append(contentsOf: searchAmenity(lat: location!.coordinate.latitude, lon: location!.coordinate.longitude, reader: reader, searchRadius: searchRadius, zoom: -1, searchFilter: ROUTE_ARTICLE, lang: lang!) )
                        foundAmenities.append(contentsOf: searchAmenity(lat: location!.coordinate.latitude, lon: location!.coordinate.longitude, reader: reader, searchRadius: searchRadius / 5, zoom: 15, searchFilter: ROUTE_TRACK, lang: nil) )
                    }
                    
                    if foundAmenities.count > 0 {
                        foundAmenities.sort { a, b in
                            let d1 = location!.distance(from: CLLocation(latitude: a.amenity.latitude(), longitude: a.amenity.longitude()))
                            let d2 = location!.distance(from: CLLocation(latitude: b.amenity.latitude(), longitude: b.amenity.longitude()))
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
    
    func cacheTravelArticles(file: String?, amenity: OAPOIAdapter, lang: String?, readPoints: Bool, callback: GpxReadDelegate?) -> TravelArticle? {
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
            cachedArticles[newArticleId.hashValue] = articles
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
        travelGpx.file = file
        let title = amenity.name()
        
        travelGpx.lat = amenity.latitude()
        travelGpx.lon = amenity.longitude()
        travelGpx.descr = amenity.getTagContent(DESCRIPTION)
    
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
        var res = [TravelSearchResult]()
        let appLang = OAUtilities.currentLang() ?? ""
        
        var amenities = [OAPOIAdapter]()
        var amenityMap = [String : [OAPOIAdapter]]()
        
        func publishCallback(amenity: OAPOIAdapter?) -> Bool {
            if amenity != nil {
                amenities.append(amenity!)
            }
            return false
        }
        
        for reader in getReaders() {
            amenities = [OAPOIAdapter]()
            OATravelGuidesHelper.searchAmenity(searchQuery, categoryName: ROUTE_ARTICLE, radius: -1, lat: -1, lon: -1, reader: reader, publish: publishCallback)
            if amenities.count > 0 {
                amenityMap[reader] = Array(amenities)
            }
        }
        
        if amenityMap.count > 0 {
            let appLangEn = appLang == "en"
            for entry in amenityMap {
                let file = entry.key
                for amenity in entry.value {
                    let nameLangs = getLanguages(amenity: amenity)
                    if nameLangs.contains(appLang) || appLang.length == 0 {
                        let article = readArticle(file: file, amenity: amenity, lang: appLang)
                        var langs = Array(nameLangs)
                        
                        langs = langs.sorted(by: { a, b in
                            var l1 = a
                            var l2 = b
                            if l1 == appLang {
                                l1 = "1";
                            }
                            if l2 == appLang {
                                l2 = "1";
                            }
                            if !appLangEn {
                                if l1 == "en" {
                                    l1 = "2";
                                }
                                if l2 == "en" {
                                    l2 = "2";
                                }
                            }
                            return l1 < l2
                        })
                        
                        let r = TravelSearchResult(arcticle: article, langs: langs)
                        res.append(r)
                        
                        cacheTravelArticles(file: file, amenity: amenity, lang: appLang, readPoints: false, callback: nil)
                    }
                }
                
                
            }
            res = sortSearchResults(results: res)
        }
        return res
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
    
    func getArticleById(articleId: TravelArticleIdentifier, lang: String?, readGpx: Bool, callback: GpxReadDelegate?) -> TravelArticle? {
        var article = getCachedArticle(articleId: articleId, lang: lang, readGpx: readGpx, callback: callback)
        if article == nil {
            article = localDataHelper.getSavedArticle(file: articleId.file ?? "", routeId: articleId.routeId ?? "", lang: lang ?? "")
            if let article {
                callback?.onGpxFileRead(gpxFile: article.gpxFile, article: article)
            }
        }
        return article
    }
    
    func getCachedArticle(articleId: TravelArticleIdentifier, lang: String?, readGpx: Bool, callback: GpxReadDelegate?) -> TravelArticle? {
        var article: TravelArticle? = nil
        var articles = cachedArticles[articleId.hashValue]
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
    
    func readGpxFile(article: TravelArticle, callback: GpxReadDelegate?) {
        if !article.gpxFileRead && callback != nil && callback!.isGpxReading == false   {
            callback!.isGpxReading = true
            let task = GpxFileReader(article: article, callback: callback, readers: getReaders())
            task.execute()
        } else if callback != nil && article.gpxFileRead {
            callback!.isGpxReading = false
            callback?.onGpxFileRead(gpxFile: article.gpxFile, article: article)
        }
    }
    
    func findArticleById(articleId: TravelArticleIdentifier, lang: String?, readGpx: Bool, callback: GpxReadDelegate?) -> TravelArticle? {
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
    
    //TODO: check it
    func findSavedArticle(savedArticle: TravelArticle) -> TravelArticle? {
        var amenities: [(String, OAPOIAdapter)] = []
        var article: TravelArticle? = nil
        let articleId = savedArticle.generateIdentifier()
        let lang = savedArticle.lang
        let lastModified = savedArticle.lastModified
        var finalArticleId = articleId
        
        var filterFunction: ((OAPOIAdapter?) -> Bool)? = nil
        var lat: Double = -1
        var lon: Double = -1
        var radius: Int = -1
        
        for reader in getReaders() {
            var resorceLastModified = getLastModifiedForResource(filename: reader)
            resorceLastModified = (resorceLastModified != nil) ? resorceLastModified : 0
            if articleId.file != nil && articleId.file == reader {
                if lastModified == resorceLastModified {
                    lat = articleId.lat
                    lon = articleId.lon
                    radius = ARTICLE_SEARCH_RADIUS
                    
                    func publish(poi: OAPOIAdapter?) -> Bool {
                        if let poi {
                            let routeId = poi.getTagContent(ROUTE_ID) ?? ""
                            if finalArticleId.routeId == routeId {
                                amenities.append((reader, poi))
                                return true
                            }
                        }
                        return false
                    }
                    filterFunction = publish
                } else {
                    lat = articleId.lat
                    lon = articleId.lon
                    radius = ARTICLE_SEARCH_RADIUS / 10
                    
                    func publish(poi: OAPOIAdapter?) -> Bool {
                        if let poi {
                            let name = poi.getName(lang, transliterate: false) ?? ""
                            if finalArticleId.title == name {
                                amenities.append((reader, poi))
                                return true
                            }
                        }
                        return false
                    }
                    filterFunction = publish
                }
            }
            
            if filterFunction != nil {
                if articleId.lat != Double.nan {
                    if articleId.title != nil && articleId.title!.length > 0 {
                        OATravelGuidesHelper.searchAmenity(articleId.title, categoryName: ROUTE_ARTICLE, radius: Int32(radius), lat: lat, lon: lon, reader: reader, publish: filterFunction)
                        OATravelGuidesHelper.searchAmenity(articleId.title, categoryName: ROUTE_TRACK, radius: Int32(radius), lat: lat, lon: lon, reader: reader, publish: filterFunction)
                    } else {
                        OATravelGuidesHelper.searchAmenity(lat, lon: lon, reader: reader, radius: Int32(radius), searchFilter: ROUTE_ARTICLE, publish: filterFunction)
                        OATravelGuidesHelper.searchAmenity(lat, lon: lon, reader: reader, radius: Int32(radius), searchFilter: ROUTE_TRACK, publish: filterFunction)
                    }
                } else {
                    OATravelGuidesHelper.searchAmenity(lat, lon: lon, reader: reader, radius: Int32(radius), searchFilter: ROUTE_ARTICLE, publish: filterFunction)
                    OATravelGuidesHelper.searchAmenity(lat, lon: lon, reader: reader, radius: Int32(radius), searchFilter: ROUTE_TRACK, publish: filterFunction)
                }
                break
            }
        }
        
        if amenities.count == 0 && articleId.title != nil && articleId.title!.length > 0 {
            for reader in getReaders() {
                lat = articleId.lat
                lon = articleId.lon
                radius = SAVED_ARTICLE_SEARCH_RADIUS
                
                func publish(poi: OAPOIAdapter?) -> Bool {
                    if let poi {
                        let name = poi.getName(lang, transliterate: false) ?? ""
                        if finalArticleId.title == name {
                            amenities.append((reader, poi))
                            return true
                        }
                    }
                    return false
                }
                filterFunction = publish
                
                if articleId.lat != Double.nan {
                    OATravelGuidesHelper.searchAmenity(articleId.title, categoryName: ROUTE_ARTICLE, radius: Int32(radius), lat: lat, lon: lon, reader: reader, publish: filterFunction)
                    OATravelGuidesHelper.searchAmenity(articleId.title, categoryName: ROUTE_TRACK, radius: Int32(radius), lat: lat, lon: lon, reader: reader, publish: filterFunction)
                } else {
                    OATravelGuidesHelper.searchAmenity(lat, lon: lon, reader: reader, radius: Int32(radius), searchFilter: ROUTE_ARTICLE, publish: filterFunction)
                    OATravelGuidesHelper.searchAmenity(lat, lon: lon, reader: reader, radius: Int32(radius), searchFilter: ROUTE_TRACK, publish: filterFunction)
                }
            }
        }
        
        if amenities.count == 0 {
            for reader in getReaders() {
                lat = articleId.lat
                lon = articleId.lon
                radius = SAVED_ARTICLE_SEARCH_RADIUS
                
                func publish(poi: OAPOIAdapter?) -> Bool {
                    if let poi {
                        let routeId = poi.getTagContent(ROUTE_ID) ?? ""
                        let routeSource = poi.getTagContent(ROUTE_SOURCE) ?? ""
                        if finalArticleId.routeId == routeId && finalArticleId.routeSource == routeSource {
                            amenities.append((reader, poi))
                            return true
                        }
                    }
                    return false
                }
                filterFunction = publish
                
                if articleId.lat != Double.nan {
                    if articleId.title != nil && articleId.title!.length > 0 {
                        OATravelGuidesHelper.searchAmenity(articleId.title, categoryName: ROUTE_ARTICLE, radius: Int32(radius), lat: lat, lon: lon, reader: reader, publish: filterFunction)
                        OATravelGuidesHelper.searchAmenity(articleId.title, categoryName: ROUTE_TRACK, radius: Int32(radius), lat: lat, lon: lon, reader: reader, publish: filterFunction)
                    } else {
                        OATravelGuidesHelper.searchAmenity(lat, lon: lon, reader: reader, radius: Int32(radius), searchFilter: ROUTE_ARTICLE, publish: filterFunction)
                        OATravelGuidesHelper.searchAmenity(lat, lon: lon, reader: reader, radius: Int32(radius), searchFilter: ROUTE_TRACK, publish: filterFunction)
                    }
                } else {
                    OATravelGuidesHelper.searchAmenity(lat, lon: lon, reader: reader, radius: Int32(radius), searchFilter: ROUTE_ARTICLE, publish: filterFunction)
                    OATravelGuidesHelper.searchAmenity(lat, lon: lon, reader: reader, radius: Int32(radius), searchFilter: ROUTE_TRACK, publish: filterFunction)
                }
                break
            }
        }
        
        if amenities.count > 0 {
            article = cacheTravelArticles(file: amenities[0].0, amenity: amenities[0].1, lang: lang, readPoints: false, callback: nil)
        }
        return article
    }
    
    func getLastModifiedForResource(filename: String) -> Double? {
        let dirPath = OsmAndApp.swiftInstance().documentsPath + "/Resources"
        let filePath = dirPath + "/" + filename
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: filePath)
            let date = attr[FileAttributeKey.modificationDate] as? Date
            return (date != nil) ? date!.timeIntervalSince1970 : nil
        } catch {
            return nil
        }
    }
    
    func getArticleByTitle(title: String, lang: String, readGpx: Bool, callback: GpxReadDelegate?) -> TravelArticle? {
        return getArticleByTitle(title: title, rect: QuadRect(), lang: lang, readGpx: readGpx, callback: callback)
    }

    func getArticleByTitle(title: String, rect: QuadRect, lang: String, readGpx: Bool, callback: GpxReadDelegate?) -> TravelArticle? {
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
        let article = getArticleById(articleId: articleId, lang: "en", readGpx: false, callback: nil)
        if article != nil {
            let articles = cachedArticles[article!.generateIdentifier().hashValue]
            if articles != nil {
                res.append(contentsOf: articles!.keys)
            }
        } else {
            let articles = localDataHelper.getSavedArticles(file: articleId.file ?? "", routeId: articleId.routeId ?? "")
            for a in articles {
                if let articleLang = a.lang {
                    res.append(articleLang)
                }
            }
        }
        return res
    }
    
    func getGPXName(article: TravelArticle) -> String {
        return article.title!
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "'/'", with: "_")
            .replacingOccurrences(of: "\"", with: "_") + ".gpx"
    }
    
    func createGpxFile(article: TravelArticle) -> String {
        let fileName = getGPXName(article: article)
        return OATravelGuidesHelper.createGpxFile(article, fileName: fileName)
    }
    
    func getSelectedTravelBookName() -> String? {
        return nil
    }
    
    func getWikivoyageFileName() -> String? {
        return WORLD_WIKIVOYAGE_FILE_NAME
    }
    
    func saveOrRemoveArticle(article: TravelArticle, save: Bool) {
        if save {
            localDataHelper.addArticleToSaved(article: article)
        } else {
            localDataHelper.removeArticleFromSaved(article: article)
        }
    }
    
    func buildGpxFile(readers: [String], article: TravelArticle) -> OAGPXDocumentAdapter {
        return OATravelGuidesHelper.buildGpxFile(getReaders(), article: article)
    }
    
    func createTitle(name: String) -> String {
        return OAUtilities.capitalizeFirstLetter(name)
    }
    
}


class GpxFileReader {
    
    var article: TravelArticle?
    var callback: GpxReadDelegate?
    var readers: [String]?
    
    init(article: TravelArticle, callback: GpxReadDelegate?, readers: [String]) {
        self.article = article
        self.callback = callback
        self.readers = readers
    }
    
    func execute() {
        onPreExecute()
        DispatchQueue.global(qos: .background).async {
            let file = self.doInBackground()
            DispatchQueue.main.async {
                self.onPostExecute(gpxFile: file)
            }
        }
    }
    
    func onPreExecute() {
        if callback != nil {
            callback!.onGpxFileReading()
        }
    }
    
    func doInBackground() -> OAGPXDocumentAdapter? {
        return TravelObfHelper.shared.buildGpxFile(readers: readers!, article: article!)
    }
    
    func onPostExecute(gpxFile: OAGPXDocumentAdapter?) {
        article!.gpxFileRead = true
        article!.gpxFile = gpxFile
        if callback != nil {
            callback!.onGpxFileRead(gpxFile: gpxFile, article: article!)
        }
    }
}
