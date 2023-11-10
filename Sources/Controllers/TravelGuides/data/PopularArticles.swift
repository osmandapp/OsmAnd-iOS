//
//  PopularArticles.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 08.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

final class PopularArticles : NSObject {
    
    static let ARTICLES_PER_PAGE = 30
    var articles = [TravelArticle]()
    
    override init() {
        articles = [TravelArticle]()
    }
    
    init(artcles: PopularArticles) {
        self.articles = artcles.articles
    }
    
    func clear() {
        articles = [TravelArticle]()
    }
    
    func getArticles() -> [TravelArticle] {
        Array(articles)
    }
    
    func add(article: TravelArticle) -> Bool {
        articles.append(article)
        return articles.count % PopularArticles.ARTICLES_PER_PAGE != 0
    }
    
    func contains(article: TravelArticle) -> Bool {
        if articles.firstIndex(of: article) != nil {
            return true
        }
        return false
    }
    
    func containsByRouteId(routeId: String) -> Bool {
        for article in articles {
            if article.routeId == routeId {
                return true
            }
        }
        return false
    }
}
