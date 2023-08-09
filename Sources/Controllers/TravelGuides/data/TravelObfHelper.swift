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
    
    static let shared = TravelObfHelper()
    
    let WORLD_WIKIVOYAGE_FILE_NAME = "World_wikivoyage.travel.obf"
    let ARTICLE_SEARCH_RADIUS = 50 * 1000
    let SAVED_ARTICLE_SEARCH_RADIUS = 30 * 1000
    let MAX_SEARCH_RADIUS = 800 * 1000
    
    var popularArticles = PopularArticles()
    //private final Map<TravelArticleIdentifier, Map<String, TravelArticle>> cachedArticles = new ConcurrentHashMap<>();
    //private final TravelLocalDataHelper localDataHelper;
    //private int searchRadius = ARTICLE_SEARCH_RADIUS;
    //private int foundAmenitiesIndex;
    //private final List<Pair<File, Amenity>> foundAmenities = new ArrayList<>();
    
    private override init() {
//        this.app = app;
//        collator = OsmAndCollator.primaryCollator();
//        localDataHelper = new TravelLocalDataHelper(app);
    }
    
    func initializeDataToDisplay(resetData: Bool) {
//        if (resetData) {
//            foundAmenities.clear();
//            foundAmenitiesIndex = 0;
//            popularArticles.clear();
//            searchRadius = ARTICLE_SEARCH_RADIUS;
//        }
//        localDataHelper.refreshCachedData();
        
        loadPopularArticles()
    }
    
    
    func loadPopularArticles() -> PopularArticles {
        let lang = "en"

        searchAmenity()
        
        return PopularArticles()
    }
    
    func searchAmenity() {
        OATravelObfHelperBridge.foo(55.7512, lon: 37.6184)
    }
    
}
