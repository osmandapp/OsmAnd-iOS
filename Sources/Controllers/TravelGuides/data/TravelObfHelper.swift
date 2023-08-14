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
    let ARTICLE_SEARCH_RADIUS = 50 * 1000
    let SAVED_ARTICLE_SEARCH_RADIUS = 30 * 1000
    let MAX_SEARCH_RADIUS = 800 * 1000
    
    private var popularArticles = PopularArticles()
    private var cachedArticles: [TravelArticleIdentifier : [String:TravelArticle] ] = [:]
    private let localDataHelper: TravelLocalDataHelper
    private var searchRadius: Int
    private var foundAmenitiesIndex: Int = 0
    private var foundAmenities: [OAPOIAdapter] = []
    
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
        var popularArticles = PopularArticles(artcles: popularArticles)
        if isAnyTravelBookPresent() {
            var articlesLimitReached = false
            repeat {
                if foundAmenities.count - foundAmenitiesIndex < PopularArticles.ARTICLES_PER_PAGE {
                    var location = OARootViewController.instance().mapPanel.mapViewController.getMapLocation()
                    foundAmenities.append(contentsOf: searchAmenity(lat: location!.coordinate.latitude, lon: location!.coordinate.longitude, searchRadius: searchRadius, zoom: -1, searchFilter: "route_article", lang: lang!) )
                    foundAmenities.append(contentsOf: searchAmenity(lat: location!.coordinate.latitude, lon: location!.coordinate.longitude, searchRadius: searchRadius / 5, zoom: 15, searchFilter: "route_track", lang: nil) )
                    
                    if foundAmenities.count > 0 {
                        foundAmenities.sort { a, b in
                            let d1 = location!.distance(from: CLLocation(latitude: a.latitude(), longitude: a.longitude()))
                            let d2 = location!.distance(from: CLLocation(latitude: b.latitude(), longitude: b.longitude()))
                            
                            //TODO: check. Invert if needed
                            return d1 <= d2
                        }
                    }
                }
                searchRadius *= 2
                while foundAmenitiesIndex < foundAmenities.count - 1 {
                    //Pair<File, Amenity> fileAmenity = foundAmenities.get(foundAmenitiesIndex);
                    //File file = fileAmenity.first;
                    let amenity = foundAmenities[foundAmenitiesIndex]
                    if amenity.name() != nil && amenity.name().length > 0 {
                        let routeId = amenity.getAdditionalInfo()["route_id"] ?? ""
                        if !popularArticles.containsByRouteId(routeId: routeId) {
                            //TravelArticle article = cacheTravelArticles(file, amenity, lang, false, null);
                            let article = cacheTravelArticles(file: nil, amenity: amenity, lang: lang!, readPoints: false, callback: nil)
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
        var foundAmenities = [OAPOIAdapter]()
        var searchRadius = ARTICLE_SEARCH_RADIUS
        var travelGpx: TravelGpx? = nil
        
        repeat {
            foundAmenities.append(contentsOf: searchAmenity(lat: latLon.latitude, lon: latLon.longitude, searchRadius: searchRadius, zoom: 15, searchFilter: filter!, lang: nil) )
            
            if foundAmenities.count > 0 {
                for amenity in foundAmenities {
                    if amenity.getRouteId() == filter ||
                        amenity.name() == filter ||
                        amenity.getRef() == ref {
                        
                        //travelGpx = getTravelGpx(foundGpx.first, amenity);
                        travelGpx = getTravelGpx(amenity: amenity)
                        break
                    }
                }
            }
            searchRadius *= 2
        } while travelGpx == nil && searchRadius < MAX_SEARCH_RADIUS
        return travelGpx
    }
    
    func searchAmenity(lat: Double, lon: Double, searchRadius: Int, zoom: Int, searchFilter: String, lang: String?) -> [OAPOIAdapter] {
        return OATravelGuidesHelper.searchAmenity(lat, lon: lon, radius: Int32(searchRadius), searchFilter: searchFilter)
    }
    
    func cacheTravelArticles(file: String?, amenity: OAPOIAdapter, lang: String, readPoints: Bool, callback: GpxReadCallback?) -> TravelArticle? {
        
        //TODO: implement
        return nil
    }
    
    func readRoutePoint(file: String, amenity: OAPOIAdapter) -> [String : TravelArticle] {
        
        //TODO: implement
        return [:]
    }
    
    func getTravelGpx(amenity: OAPOIAdapter) -> TravelGpx {
        
        //TODO: implement
        return TravelGpx()
    }
    
    func getSearchFilter(filterSubcategory: String) -> OASearchPoiTypeFilter {
        
        //TODO: implement
        return OASearchPoiTypeFilter()
    }
    
    func readArticles(file: String, amenity: OAPOIAdapter) -> [String : TravelArticle] {
        
        //TODO: implement
        return [:]
    }
    
    func readArticle(file: String, amenity: OAPOIAdapter, lang: String) -> TravelArticle {
        
        //TODO: implement
        return TravelArticle()
    }
    
    func isAnyTravelBookPresent() -> Bool {
        
        //TODO: implement
        return false
    }
    
    func search(searchQuery: String) -> [WikivoyageSearchResult] {
        
        //TODO: implement
        return []
    }
    
    func getLanguages(amenity: OAPOIAdapter) -> Set<String> {
        
        //TODO: implement
        return []
    }
    
    func sortSearchResults(results: [WikivoyageSearchResult]) {
        //TODO: implement
    }
    
    func getPopularArticles() -> [TravelArticle] {
        //TODO: implement
        return []
    }
    
    func getNavigationMap(article: TravelArticle) -> [WikivoyageSearchResult : [WikivoyageSearchResult]] {
        //TODO: implement
        return [:]
    }
    
    func getParentArticleByTitle(title: String, lang: String) -> TravelArticle {
        //TODO: implement
        return TravelArticle()
    }
    
    func getArticleById(articleId: TravelArticleIdentifier, lang: String?, readGpx: Bool, callback: GpxReadCallback?) -> TravelArticle? {
        //TODO: implement
        return nil
    }
    
    func getCachedArticle(articleId: TravelArticleIdentifier, lang: String?, readGpx: Bool, callback: GpxReadCallback?) -> TravelArticle {
        //TODO: implement
        return TravelArticle()
    }
    
    func openTrackMenu(article: TravelArticle, gpxFileName: String, latLon: CLLocationCoordinate2D) {
        //TODO: implement
    }
    
    func readGpxFile(article: TravelArticle, callback: GpxReadCallback?) {
        //TODO: implement
    }
    
    func findArticleById(articleId: TravelArticleIdentifier, lang: String?, readGpx: Bool, callback: GpxReadCallback?) -> TravelArticle {
        //TODO: implement
        return TravelArticle()
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
        return TravelArticle()
    }

    func getArticleByTitle(title: String, latLon: CLLocationCoordinate2D, lang: String, readGpx: Bool, callback: GpxReadCallback?) -> TravelArticle? {
        //TODO: implement
        return TravelArticle()
    }

    func getArticleByTitle(title: String, rect: QuadRect, lang: String, readGpx: Bool, callback: GpxReadCallback?) -> TravelArticle? {
        //TODO: implement
        return TravelArticle()
    }
    
    //private List<BinaryMapIndexReader> getReaders() {}
    
    func getArticleId(title: String, lang: String) -> TravelArticleIdentifier? {
        //TODO: implement
        return nil
    }
    
    func getArticleLangs(articleId: TravelArticleIdentifier) -> [String] {
        //TODO: implement
        return []
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
