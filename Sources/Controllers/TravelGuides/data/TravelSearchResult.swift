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
    
    var foo: String = ""
    
    func getArticleTitle() -> String {
        //TODO: implement
        return ""
    }
    
    static func == (lhs: TravelSearchResult, rhs: TravelSearchResult) -> Bool {
        //TODO: implement
        return false
    }
    
}
