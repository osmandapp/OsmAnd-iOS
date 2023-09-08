//
//  TravelGuidesState.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 08.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation


@objc(OATravelGuidesState)
@objcMembers
class TravelGuidesState : NSObject {
    
    static let shared = TravelGuidesState()
    
    var wasWatchingGpx: Bool = false
    
    //Tabs VC
    var mainMenuSelectedTab: Int = 0
    
    //Explore Tab
    var exploreTabTableData: OATableDataModel?
    var lastSelectedIndexPath: IndexPath?
    var downloadingResources: [OAResourceSwiftItem] = []
    var cachedPreviewImages: ImageCache?
    
    //Article view
    var article: TravelArticle?
    var articleId: TravelArticleIdentifier?
    var selectedLang: String?
    var langs: [String]?
    var nightMode = false
    var historyArticleIds: [TravelArticleIdentifier] = []
    var historyLangs: [String] = []
    var gpxFile: OAGPXDocumentAdapter?
    var gpx: OAGPX?
    
    private override init() {
    }
    
    func resetData() {
        wasWatchingGpx = false
        mainMenuSelectedTab = 0
        exploreTabTableData = nil
        lastSelectedIndexPath = nil
        downloadingResources = []
        cachedPreviewImages = nil
        article = nil
        articleId = nil
        selectedLang = nil
        langs = nil
        nightMode = false
        historyArticleIds = []
        historyLangs = []
        gpxFile = nil
        gpx = nil
    }
    
}
