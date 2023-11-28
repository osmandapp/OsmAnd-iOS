//
//  TravelSearchHistoryItem.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 11.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OATravelSearchHistoryItem)
@objcMembers
final class TravelSearchHistoryItem : NSObject {
    
    var articleFile: String? = ""
    var articleTitle: String = ""
    var lang: String = ""
    var imageTitle: String? = ""
    var isPartOf: String = ""
    var lastAccessed: TimeInterval = 0
    
    static func getKey(lang: String, title: String, file: String?) -> String {
        lang + ":" + title + ((file != nil) ? (":" + file!) : "")
    }
    
    func getKey() -> String {
        TravelSearchHistoryItem.getKey(lang: lang, title: articleTitle, file: articleFile)
    }
    
    func getTravelBook() -> String? {
        articleFile != nil ? TravelArticle.getTravelBook(file: articleFile!) : nil
    }
    
}
