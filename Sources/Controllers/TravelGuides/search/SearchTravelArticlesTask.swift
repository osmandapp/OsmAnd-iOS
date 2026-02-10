//
//  SearchTravelArticlesTask.swift
//  OsmAnd
//
//  Created by Max Kojin on 10/02/26.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

final class SearchTravelArticlesTask: OAAsyncTask {
    
    private let travelHelper = TravelObfHelper.shared
    private var routeIds: [String: CLLocation]
    private var callback: (([String: [String: TravelArticle]]) -> Void)
    
    init(routeIds: [String: CLLocation], callback: @escaping (([String: [String: TravelArticle]]) -> Void)) {
        self.routeIds = routeIds
        self.callback = callback
        super.init()
    }
    
    override func doInBackground() -> Any? {
        var result = [String: [String: TravelArticle]]()
        for entry in routeIds {
            let routeId = entry.key
            let latLon = entry.value
            
            let identifier = TravelArticleIdentifier(file: nil, lat: latLon.coordinate.latitude, lon: latLon.coordinate.longitude, title: nil, routeId: routeId, routeSource: nil)
            
            let map = travelHelper.getArticleByLangs(articleId: identifier)
            if !map.isEmpty {
                result[routeId] = map
            }
        }
        return result
    }
    
    override func onPostExecute(result: Any?) {
        if let articlesMap = result as? [String: [String: TravelArticle]] {
            callback(articlesMap)
        }
    }
}
