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
final class TravelObfHelper : NSObject {
    
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
        localDataHelper = TravelLocalDataHelper.shared;
        searchRadius = ARTICLE_SEARCH_RADIUS
    }
    
    func getBookmarksHelper() -> TravelLocalDataHelper {
        localDataHelper
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
                    guard let location = OATravelGuidesHelper.getMapCenter() else {continue}
                    
                    for reader in getReaders() {
                        foundAmenities.append(contentsOf: searchAmenity(lat: location.coordinate.latitude, lon: location.coordinate.longitude, reader: reader, searchRadius: searchRadius, zoom: -1, searchFilter: ROUTE_ARTICLE, lang: lang!) )
                        foundAmenities.append(contentsOf: searchAmenity(lat: location.coordinate.latitude, lon: location.coordinate.longitude, reader: reader, searchRadius: searchRadius / 5, zoom: 15, searchFilter: ROUTE_TRACK, lang: nil) )
                    }
                    
                    if !foundAmenities.isEmpty {
                        foundAmenities.sort { a, b in
                            let d1 = location.distance(from: CLLocation(latitude: a.amenity.latitude, longitude: a.amenity.longitude))
                            let d2 = location.distance(from: CLLocation(latitude: b.amenity.latitude, longitude: b.amenity.longitude))
                            return d1 < d2
                        }
                    }
                }
                searchRadius *= 2
                while foundAmenitiesIndex < foundAmenities.count - 1 {
                    let fileAmenity = foundAmenities[foundAmenitiesIndex]
                    if let file = fileAmenity.file {
                        let amenity = fileAmenity.amenity!
                        if let name = amenity.getName(lang, transliterate: false), name.length > 0 {
                            let routeId = amenity.getAdditionalInfo()[ROUTE_ID] ?? ""
                            if !popularArticles.containsByRouteId(routeId: routeId) {
                                if let article = cacheTravelArticles(file: file, amenity: amenity, lang: lang!, readPoints: false, callback: nil) {
                                    if !popularArticles.contains(article: article) {
                                        if !popularArticles.add(article: article) {
                                            articlesLimitReached = true
                                            break
                                        }
                                    }
                                }
                            }
                        }
                    }
                    foundAmenitiesIndex += 1
                }
            } while (!articlesLimitReached && searchRadius < MAX_SEARCH_RADIUS)
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
                if let filter {
                    foundAmenities.append(contentsOf: searchAmenity(lat: latLon.latitude, lon: latLon.longitude, reader: reader, searchRadius: searchRadius, zoom: 15, searchFilter: filter, lang: nil) )
                }
            }
            
            if !foundAmenities.isEmpty {
                for foundGpx in foundAmenities {
                    if let amenity = foundGpx.amenity {
                        if amenity.getRouteId() == filter ||
                            amenity.name == filter ||
                            amenity.getRef() == ref {
                            travelGpx = getTravelGpx(file:foundGpx.file!, amenity: amenity)
                            break
                        }
                    }
                }
            }
            searchRadius *= 2
        } while travelGpx == nil && searchRadius < MAX_SEARCH_RADIUS
        return travelGpx
    }
    
    func searchAmenity(lat: Double, lon: Double, reader: String, searchRadius: Int, zoom: Int, searchFilter: String, lang: String?) -> [OAFoundAmenity] {
        
        var results: [OAFoundAmenity] = []
        func publish(poi: OAPOI?) -> Bool {
            if let poi {
                if lang == nil {
                    results.append(OAFoundAmenity(file: reader, amenity: poi))
                }
                if let lang, let namesMap = poi.getNamesMap(true), namesMap.keys.contains(lang) {
                    results.append(OAFoundAmenity(file: reader, amenity: poi))
                }
            }
            return false
        }
        
        OATravelGuidesHelper.searchAmenity(lat, lon: lon, reader: reader, radius: Int32(searchRadius), searchFilters: [searchFilter], publish:publish)
        return results
    }
    
    func cacheTravelArticles(file: String?, amenity: OAPOI, lang: String?, readPoints: Bool, callback: GpxReadDelegate?) -> TravelArticle? {
        var article: TravelArticle? = nil
        var articles: [String: TravelArticle]? = [:]
        guard let file else {return nil}
        if amenity.subType == ROUTE_TRACK {
            articles = readRoutePoint(file: file, amenity: amenity)
        } else {
            articles = readArticles(file: file, amenity: amenity)
        }
        if let articles, !articles.isEmpty {
            var i = articles.values.makeIterator()
            if let next = i.next() {
                let newArticleId = next.generateIdentifier()
                cachedArticles[newArticleId.hashValue] = articles
                article = getCachedArticle(articleId: newArticleId, lang: lang, readGpx: readPoints, callback: callback)
            }
        }
        return article
    }
    
    func readRoutePoint(file: String, amenity: OAPOI) -> [String : TravelArticle] {
        var articles: [String : TravelArticle] = [:]
        var res = getTravelGpx(file:file, amenity: amenity)
        articles[""] = res
        return articles
    }
    
    func getTravelGpx(file: String?, amenity: OAPOI) -> TravelGpx {
        var travelGpx = TravelGpx()
        travelGpx.file = file
        let title = amenity.name
        
        travelGpx.lat = amenity.latitude
        travelGpx.lon = amenity.longitude
        travelGpx.descr = amenity.getTagContent(DESCRIPTION_TAG)

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
        
        if let radius: String = amenity.getTagContent(TravelGpx.ROUTE_RADIUS) {
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
    
    func readArticles(file: String, amenity: OAPOI) -> [String : TravelArticle] {
        var articles: [String : TravelArticle] = [:]
        var langs = getLanguages(amenity: amenity)
        for lang in langs {
            articles[lang] = readArticle(file: file, amenity: amenity, lang: lang)
        }
        return articles
    }
    
    func readArticle(file: String, amenity: OAPOI, lang: String) -> TravelArticle {
        
        var res = TravelArticle()
        res.file = file
        var title = amenity.getName(lang, transliterate: false)
        if title == nil || (title ?? "").isEmpty {
            title = amenity.getName("en", transliterate: false)
            if title == nil || (title ?? "").isEmpty {
                title = amenity.name
            }
        }
        res.title = title
        res.content = amenity.getDescription(lang)
        res.isPartOf = amenity.getTagContent(IS_PART, lang:lang) ?? ""
        res.isParentOf = amenity.getTagContent(IS_PARENT_OF, lang:lang) ?? ""
        res.lat = amenity.latitude
        res.lon = amenity.longitude
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
        !getReaders().isEmpty
    }
    
    func isOnlyDefaultTravelBookPresent() -> Bool {
        let books = TravelObfHelper.shared.getReaders()
        if books.isEmpty ||
            books.count == 1 && books[0].lowercased() == DEFAULT_WIKIVOYAGE_TRAVEL_OBF.lowercased() {
            return true
        }
        return false
    }
    
    func search(searchQuery: String) -> [TravelSearchResult] {
        var res = [TravelSearchResult]()
        let appLang = OAUtilities.currentLang() ?? ""
        
        var amenities = [OAPOI]()
        var amenityMap = [String : [OAPOI]]()
        
        func publishCallback(amenity: OAPOI?) -> Bool {
            if let amenity {
                amenities.append(amenity)
            }
            return false
        }
        
        for reader in getReaders() {
            amenities = [OAPOI]()
            OATravelGuidesHelper.searchAmenity(searchQuery, categoryNames: [ROUTE_ARTICLE], radius: -1, lat: -1, lon: -1, reader: reader, publish: publishCallback)
            if !amenities.isEmpty {
                amenityMap[reader] = Array(amenities)
            }
        }
        
        if !amenityMap.isEmpty {
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
    
    func getLanguages(amenity: OAPOI) -> Set<String> {
        var langs: Set<String> = []
        let descrStart = DESCRIPTION_TAG + ":"
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
        guard let lang = article.lang else {return [:]}
        guard let title = article.title else {return [:]}
        if lang.isEmpty || title.isEmpty {
            return [:]
        }
        
        var parts = [String]()
        if let aggregatedPartOf = article.aggregatedPartOf {
            if !aggregatedPartOf.isEmpty {
                let originalParts = aggregatedPartOf.split(separator: ",")
                if originalParts.count > 1 {
                    parts = [String].init(repeating: "", count: originalParts.count)
                    for i in 0..<originalParts.count {
                        parts[i] = String(originalParts[originalParts.count - i - 1])
                    }
                } else {
                    parts[0] = String(originalParts[0])
                }
            }
        } else {
            parts = []
        }
        
        var navMap = [String : [TravelSearchResult]]()
        var headers = [String]()
        var headerObjs = [String : TravelSearchResult]()
        if !parts.isEmpty {
            headers.append(contentsOf: parts)
            if let isParentOf = article.isParentOf, !isParentOf.isEmpty {
                headers.append(title)
            }
        }
        
        for header in headers {
            
            guard let parentArticle = getParentArticleByTitle(title: header, lang: lang, lat: article.lat, lon: article.lon) else {continue}

            navMap[header] = [TravelSearchResult]()
            if let unseparatedText = parentArticle.isParentOf {
                let isParentOf = unseparatedText.split(separator: ";")
                for childSubsequence in isParentOf {
                    let childTitle = String(childSubsequence)
                    if !childTitle.isEmpty {
                        let searchResult = TravelSearchResult(routeId: "", articleTitle: childTitle, isPartOf: nil, imageTitle: nil, langs: [lang])
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
    
    func getParentArticleByTitle(title: String, lang: String, lat: Double, lon: Double) -> TravelArticle? {
        var article: TravelArticle? = nil
        var amenities = [OAPOI]()
        
        for reader in getReaders() {
            OATravelGuidesHelper.searchAmenity(title, categoryNames: [ROUTE_ARTICLE], radius: -1, lat: lat, lon: lon, reader: reader) { amenity in
                if let amenity, title == amenity.getName(lang, transliterate: false) {
                    amenities.append(amenity)
                    return true
                }
                return false
            }
            
            if !amenities.isEmpty {
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
        let articles = cachedArticles[articleId.hashValue]
        if let articles {
            if lang == nil || lang!.length == 0 {
                let ac = articles.values
                if !ac.isEmpty {
                    var it = ac.makeIterator()
                    article = it.next()
                }
            } else {
                article = articles[lang!]
                if article == nil {
                    article = articles[""]
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
            callback?.isGpxReading = true
            let task = GpxFileReader(article: article, callback: callback, readers: getReaders())
            task.execute()
        } else if callback != nil && article.gpxFileRead {
            callback?.isGpxReading = false
            callback?.onGpxFileRead(gpxFile: article.gpxFile, article: article)
        }
    }
    
    func findArticleById(articleId: TravelArticleIdentifier, lang: String?, readGpx: Bool, callback: GpxReadDelegate?) -> TravelArticle? {
        var article: TravelArticle? = nil
        let isDbArticle = articleId.file != nil && articleId.file!.hasSuffix(BINARY_WIKIVOYAGE_MAP_INDEX_EXT)
        var amenities: [OAPOI] = []
        
        for reader in getReaders() {
            if articleId.file != nil && articleId.file != reader && !isDbArticle {
                continue
            }
            
            func publishCallback(amenity: OAPOI?) -> Bool {
                var done = false
                if let amenity {
                    if articleId.routeId == amenity.getTagContent(ROUTE_ID) || isDbArticle {
                        amenities.append(amenity)
                        done =  true
                    }
                }
                return done
            }
            
            if !articleId.lat.isNaN {
                if articleId.title != nil && articleId.title!.length > 0 {
                    let title = articleId.title ?? ""
                    OATravelGuidesHelper.searchAmenity(title, categoryNames:[ROUTE_ARTICLE], radius:Int32(ARTICLE_SEARCH_RADIUS), lat:articleId.lat, lon:articleId.lon, reader: reader, publish:publishCallback)
                } else {
                    OATravelGuidesHelper.searchAmenity(articleId.lat, lon: articleId.lon, reader: reader, radius: Int32(ARTICLE_SEARCH_RADIUS), searchFilters: [ROUTE_ARTICLE], publish:publishCallback)
                    
                }
            } else {
                OATravelGuidesHelper.searchAmenity(Double.nan, lon: Double.nan, reader: reader, radius: -1, searchFilters: [ROUTE_ARTICLE], publish:publishCallback)
            }
            
            if !amenities.isEmpty {
                article = cacheTravelArticles(file: reader, amenity: amenities[0], lang: lang, readPoints: readGpx, callback: callback)
            }
        }
        return article
    }
    

    func findSavedArticle(savedArticle: TravelArticle) -> TravelArticle? {
        var amenities: [(String, OAPOI)] = []
        var article: TravelArticle? = nil
        let articleId = savedArticle.generateIdentifier()
        let lang = savedArticle.lang ?? ""
        let lastModified = savedArticle.lastModified
        let finalArticleId = articleId
        
        amenities = findSavedArticlesForWholeWorld(savedArticle: savedArticle, articleId: articleId, finalArticleId: finalArticleId, lastModified: lastModified, lang: lang)
        
        if amenities.isEmpty && articleId.title != nil && articleId.title!.length > 0 {
            amenities = findSavedArticlesInAreaByName(savedArticle: savedArticle, articleId: articleId, finalArticleId: finalArticleId, lastModified: lastModified, lang: lang)
        }
        
        if amenities.isEmpty {
            amenities = findSavedArticlesInAreaByRouteId(savedArticle: savedArticle, articleId: articleId, finalArticleId: finalArticleId, lastModified: lastModified, lang: lang)
        }
        
        if !amenities.isEmpty {
            article = cacheTravelArticles(file: amenities[0].0, amenity: amenities[0].1, lang: lang, readPoints: false, callback: nil)
        }
        return article
    }
    
    private func findSavedArticlesForWholeWorld(savedArticle: TravelArticle, articleId: TravelArticleIdentifier, finalArticleId: TravelArticleIdentifier, lastModified: TimeInterval, lang: String) -> [(String, OAPOI)] {
        var amenities: [(String, OAPOI)] = []
        
        var filterFunction: ((OAPOI?) -> Bool)? = nil
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
                    
                    func publish(poi: OAPOI?) -> Bool {
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
                    
                    func publish(poi: OAPOI?) -> Bool {
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
            
            if let filterFunction {
                if !articleId.lat.isNaN {
                    if articleId.title != nil && articleId.title!.length > 0 {
                        OATravelGuidesHelper.searchAmenity(articleId.title, categoryNames: [ROUTE_ARTICLE, ROUTE_TRACK], radius: Int32(radius), lat: lat, lon: lon, reader: reader, publish: filterFunction)
                    } else {
                        OATravelGuidesHelper.searchAmenity(lat, lon: lon, reader: reader, radius: Int32(radius), searchFilters: [ROUTE_ARTICLE, ROUTE_TRACK], publish: filterFunction)
                    }
                } else {
                    OATravelGuidesHelper.searchAmenity(lat, lon: lon, reader: reader, radius: Int32(radius), searchFilters: [ROUTE_ARTICLE, ROUTE_TRACK], publish: filterFunction)
                }
                break
            }
        }
        return amenities
    }
    
    private func findSavedArticlesInAreaByName(savedArticle: TravelArticle, articleId: TravelArticleIdentifier, finalArticleId: TravelArticleIdentifier, lastModified: TimeInterval, lang: String) -> [(String, OAPOI)] {
        var amenities: [(String, OAPOI)] = []
        for reader in getReaders() {
            let lat = articleId.lat
            let lon = articleId.lon
            let radius = SAVED_ARTICLE_SEARCH_RADIUS
            
            func publish(poi: OAPOI?) -> Bool {
                if let poi {
                    let name = poi.getName(lang, transliterate: false) ?? ""
                    if finalArticleId.title == name {
                        amenities.append((reader, poi))
                        return true
                    }
                }
                return false
            }
            let filterFunction = publish
            
            if !articleId.lat.isNaN {
                OATravelGuidesHelper.searchAmenity(articleId.title, categoryNames: [ROUTE_ARTICLE, ROUTE_TRACK], radius: Int32(radius), lat: lat, lon: lon, reader: reader, publish: filterFunction)
            } else {
                OATravelGuidesHelper.searchAmenity(lat, lon: lon, reader: reader, radius: Int32(radius), searchFilters: [ROUTE_ARTICLE, ROUTE_TRACK], publish: filterFunction)
            }
        }
        return amenities
    }
    
    private func findSavedArticlesInAreaByRouteId(savedArticle: TravelArticle, articleId: TravelArticleIdentifier, finalArticleId: TravelArticleIdentifier, lastModified: TimeInterval, lang: String) -> [(String, OAPOI)] {
        var amenities: [(String, OAPOI)] = []
        for reader in getReaders() {
            let lat = articleId.lat
            let lon = articleId.lon
            let radius = SAVED_ARTICLE_SEARCH_RADIUS
            
            func publish(poi: OAPOI?) -> Bool {
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
            let filterFunction = publish
            
            if !articleId.lat.isNaN {
                if articleId.title != nil && articleId.title!.length > 0 {
                    OATravelGuidesHelper.searchAmenity(articleId.title, categoryNames: [ROUTE_ARTICLE, ROUTE_TRACK], radius: Int32(radius), lat: lat, lon: lon, reader: reader, publish: filterFunction)
                } else {
                    OATravelGuidesHelper.searchAmenity(lat, lon: lon, reader: reader, radius: Int32(radius), searchFilters: [ROUTE_ARTICLE, ROUTE_TRACK], publish: filterFunction)
                }
            } else {
                OATravelGuidesHelper.searchAmenity(lat, lon: lon, reader: reader, radius: Int32(radius), searchFilters: [ROUTE_ARTICLE, ROUTE_TRACK], publish: filterFunction)
            }
            break
        }
        return amenities
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
        getArticleByTitle(title: title, rect: QuadRect(), lang: lang, readGpx: readGpx, callback: callback)
    }

    func getArticleByTitle(title: String, rect: QuadRect, lang: String, readGpx: Bool, callback: GpxReadDelegate?) -> TravelArticle? {
        var article: TravelArticle? = nil
        var amenities: [OAPOI] = []
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
            OATravelGuidesHelper.searchAmenity(title, x: x, y: y, left: left, right: right, top: top, bottom: bottom, reader: reader, searchFilters: [ROUTE_ARTICLE]) { amenity in
                if let amenity, title == amenity.getName(lang, transliterate: false) {
                    amenities.append(amenity)
                    return true
                }
                return false
            }
            if !amenities.isEmpty {
                article = cacheTravelArticles(file: reader, amenity: amenities[0], lang: lang, readPoints: readGpx, callback: callback)
                break
            }
        }
        return article
    }
    
    func getReaders() -> [String] {
        OATravelGuidesHelper.getTravelGuidesObfList()
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
            if let article = getArticleByTitle(title: title, lang: lang, readGpx: false, callback: nil) {
                a = article
            }
        }
        return a != nil ? a!.generateIdentifier() : nil
    }
    
    func getArticleLangs(articleId: TravelArticleIdentifier) -> [String] {
        var res = [String]()
        if let article = getArticleById(articleId: articleId, lang: "en", readGpx: false, callback: nil) {
            if let articles = cachedArticles[article.generateIdentifier().hashValue] {
                res.append(contentsOf: articles.keys)
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
        let title = article.title ?? ""
        return title
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "'/'", with: "_")
            .replacingOccurrences(of: "\"", with: "_") + ".gpx"
    }
    
    func createGpxFile(article: TravelArticle) -> String {
        let fileName = getGPXName(article: article)
        return OATravelGuidesHelper.createGpxFile(article, fileName: fileName)
    }
    
    func getSelectedTravelBookName() -> String? {
        nil
    }
    
    func getWikivoyageFileName() -> String? {
        WORLD_WIKIVOYAGE_FILE_NAME
    }
    
    func saveOrRemoveArticle(article: TravelArticle, save: Bool) {
        if save {
            localDataHelper.addArticleToSaved(article: article)
        } else {
            localDataHelper.removeArticleFromSaved(article: article)
        }
    }
    
    func buildGpxFile(readers: [String], article: TravelArticle) -> OAGPXDocumentAdapter {
        OATravelGuidesHelper.buildGpxFile(getReaders(), article: article)
    }
    
    func createTitle(name: String) -> String {
        OAUtilities.capitalizeFirstLetter(name)
    }
    
}


final class GpxFileReader {
    
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
        DispatchQueue.global(qos: .default).async {
            let file = self.doInBackground()
            DispatchQueue.main.async {
                self.onPostExecute(gpxFile: file)
            }
        }
    }
    
    func onPreExecute() {
        if let callback {
            callback.onGpxFileReading?()
        }
    }
    
    func doInBackground() -> OAGPXDocumentAdapter? {
        if let readers, let article {
            return TravelObfHelper.shared.buildGpxFile(readers: readers, article: article)
        }
        return nil
    }
    
    func onPostExecute(gpxFile: OAGPXDocumentAdapter?) {
        if let article {
            article.gpxFileRead = true
            article.gpxFile = gpxFile
            if let callback {
                callback.onGpxFileRead(gpxFile: gpxFile, article: article)
            }
        }
    }
}
