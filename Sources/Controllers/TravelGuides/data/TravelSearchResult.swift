//
//  TravelSearchResult.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 11.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OATravelSearchResult)
@objcMembers
class TravelSearchResult : NSObject {
    
    static let SHOW_LANGS = 3
    
    var articleId: TravelArticleIdentifier
    var imageTitle: String?
    var isPartOf: String?
    var langs: [String]?
    
    init(arcticle: TravelArticle, langs: [String]?) {
        self.articleId = arcticle.generateIdentifier()
        self.imageTitle = arcticle.imageTitle
        self.isPartOf = arcticle.isPartOf
        if langs != nil {
            self.langs = langs
        }
    }
    
    init(routeId: String, articleTitle: String, isPartOf: String?, imageTitle: String?, langs: [String]?) {
        let arcticle = TravelArticle()
        arcticle.routeId = routeId
        arcticle.title = articleTitle
        self.articleId = arcticle.generateIdentifier()
        self.imageTitle = imageTitle
        self.isPartOf = isPartOf
        if langs != nil {
            self.langs = langs
        }
    }
    
    func getArticleTitle() -> String? {
        return articleId.title
    }
    
    func getArticleRouteId() -> String? {
        return articleId.routeId
    }
    
    func getFirstLangsString() -> String {
        guard langs != nil else {return ""}
        
        var res = ""
        let limit = min(TravelSearchResult.SHOW_LANGS, langs!.count)
        for i in 0..<limit {
            res += OAUtilities.capitalizeFirstLetter(langs![i])
            if i != limit - 1 {
                res += ", "
            }
        }
        return res
    }
    
    
    static func == (lhs: TravelSearchResult, rhs: TravelSearchResult) -> Bool {
        return lhs.articleId == rhs.articleId
    }
    
}
