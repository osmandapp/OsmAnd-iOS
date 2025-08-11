//
//  TravelHelper.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 11.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAGpxReadDelegate)
protocol GpxReadDelegate {
    var isGpxReading : Bool { get set }
    @objc optional func onGpxFileReading()
    func onGpxFileRead(gpxFile: OAGPXDocumentAdapter?, article: TravelArticle)
}


protocol TravelHelper {
    func getBookmarksHelper() -> TravelLocalDataHelper
    func initializeDataOnAppStartup()
    func initializeDataToDisplay(resetData: Bool)
    func isAnyTravelBookPresent() -> Bool
    func search(searchQuery: String) -> [TravelSearchResult]
    func getPopularArticles() -> [TravelArticle]
    func getNavigationMap(article: TravelArticle) -> [TravelSearchResult : [TravelSearchResult]]
    func getArticleById(articleId: TravelArticleIdentifier, lang: String?, readGpx: Bool, callback: GpxReadDelegate?) -> TravelArticle?
    func findSavedArticle(savedArticle: TravelArticle) -> TravelArticle?
    func getArticleByTitle(title: String, lang: String, readGpx: Bool, callback: GpxReadDelegate?) -> TravelArticle?
    func getArticleByTitle(title: String, latLon:CLLocationCoordinate2D, lang: String, readGpx: Bool, callback: GpxReadDelegate?) -> TravelArticle?
    func getArticleByTitle(title: String, rect: QuadRect, lang: String, readGpx: Bool, callback: GpxReadDelegate?) -> TravelArticle?
    func getArticleId(title: String, lang: String) -> TravelArticleIdentifier?
    func getArticleLangs(articleId: TravelArticleIdentifier) -> [String]
    func isTravelGpxTags(_ tags: [String: String]) -> Bool
    func searchGpx(latLon:CLLocationCoordinate2D, filter: String?, ref: String?) -> TravelGpx?
    func openTrackMenu(article: TravelArticle, gpxFileName: String, latLon:CLLocationCoordinate2D)
    func getGPXName(article: TravelArticle) -> String
    func createGpxFile(article: TravelArticle) -> String    
    func saveOrRemoveArticle(article: TravelArticle, save: Bool)
}
