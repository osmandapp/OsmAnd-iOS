//
//  TravelLocalDataHelper.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 11.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

class TravelLocalDataHelper {
    
    private static let HISTORY_ITEMS_LIMIT = 300
    private let dbHelper: WikivoyageLocalDataDbHelper
    private var historyMap: [String : WikivoyageSearchHistoryItem] = [:]
    private var savedArticles: [TravelArticle] = []
    
//    private final Set<Listener> listeners = new HashSet<>();
//    public void addListener(Listener listener) { listeners.add(listener); }
//    public void removeListener(Listener listener) { listeners.remove(listener); }

    
    init() {
        dbHelper = WikivoyageLocalDataDbHelper()
    }
    
    func refreshCachedData() {
        //TODO: implement
//        historyMap = dbHelper.getAllHistoryMap();
//        savedArticles = dbHelper.readSavedArticles();
    }
    
    
    
    private class WikivoyageLocalDataDbHelper {
        
        //TODO: continue here
        
    }
}
