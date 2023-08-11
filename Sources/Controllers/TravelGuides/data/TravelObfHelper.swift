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
    private var foundAmenities: [(file: String, amenity: OAPOIAdapter)] = []
    
    private override init() {
//        this.app = app;
//        collator = OsmAndCollator.primaryCollator();
        localDataHelper = TravelLocalDataHelper();
        searchRadius = ARTICLE_SEARCH_RADIUS
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
    
    
    //TODO: continue here
    
    
    
    func loadPopularArticles() -> PopularArticles {
        let lang = OAUtilities.currentLang()
        var popularArticles = PopularArticles(artcles: popularArticles)
        if isAnyTravelBookPresent() {
            var articlesLimitReached = false
            repeat {
                if foundAmenities.count - foundAmenitiesIndex < PopularArticles.ARTICLES_PER_PAGE {
                    var location = OARootViewController.instance().mapPanel.mapViewController.getMapLocation()
                    //foundAmenities = searchAmenity(...)
                    searchAmenity(lat: location!.coordinate.latitude, lon: location!.coordinate.longitude, searchRadius: searchRadius, zoom: -1, searchFilter: "route_article", lang: lang!)

                }
            } while true
        }
        
        

        //searchAmenity()
        
        return PopularArticles()
    }
    
    func searchAmenity(lat: Double, lon: Double, searchRadius: Int, zoom: Int, searchFilter: String, lang: String) {
        
//        OATravelGuidesHelper.search(
//        OATravelGuidesHelper.foo(lat, lon: lon)
    }
    
    
    
    
    
    
    
//    func getBookmarksHelper() -> TravelLocalDataHelper {
//        <#code#>
//    }
//
//    func initializeDataOnAppStartup() {
//        <#code#>
//    }
//
    func isAnyTravelBookPresent() -> Bool {
        //TODO: implement
        return false
    }
//
//    func search(searchQuery: String) -> [WikivoyageSearchResult] {
//        <#code#>
//    }
//
//    func getPopularArticles() -> [TravelArticle] {
//        <#code#>
//    }
//
//    func getNavigationMap(article: TravelArticle) -> [WikivoyageSearchResult : [WikivoyageSearchResult]] {
//        <#code#>
//    }
//
//    func getArticleById(articleId: TravelArticleIdentifier, lang: String?, readGpx: Bool, callback: GpxReadCallback?) -> TravelArticle? {
//        <#code#>
//    }
//
//    func findSavedArticle(savedArticle: TravelArticle) -> TravelArticle? {
//        <#code#>
//    }
//
//    func getArticleByTitle(title: String, lang: String, readGpx: Bool, callback: GpxReadCallback?) -> TravelArticle? {
//        <#code#>
//    }
//
//    func getArticleByTitle(title: String, latLon: CLLocationCoordinate2D, lang: String, readGpx: Bool, callback: GpxReadCallback?) -> TravelArticle? {
//        <#code#>
//    }
//
//    func getArticleByTitle(title: String, rect: QuadRect, lang: String, readGpx: Bool, callback: GpxReadCallback?) -> TravelArticle? {
//        <#code#>
//    }
//
//    func getArticleId(title: String, lang: String) -> TravelArticleIdentifier? {
//        <#code#>
//    }
//
//    func getArticleLangs(articleId: TravelArticleIdentifier) -> [String] {
//        <#code#>
//    }
//
//    func searchGpx(latLon: CLLocationCoordinate2D, fileName: String?, ref: String?) -> TravelGpx? {
//        <#code#>
//    }
//
//    func openTrackMenu(article: TravelArticle, gpxFileName: String, latLon: CLLocationCoordinate2D) {
//        <#code#>
//    }
//
//    func getGPXName(article: TravelArticle) -> String {
//        <#code#>
//    }
//
//    func createGpxFile(article: TravelArticle) -> String {
//        <#code#>
//    }
//
//    func saveOrRemoveArticle(article: TravelArticle, save: Bool) {
//        <#code#>
//    }
    
}
