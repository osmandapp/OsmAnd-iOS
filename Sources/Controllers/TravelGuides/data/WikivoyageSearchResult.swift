//
//  WikivoyageSearchResult.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 11.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation


class WikivoyageSearchResult : Hashable {
    
    var foo: String = ""
    
    
    
    static func == (lhs: WikivoyageSearchResult, rhs: WikivoyageSearchResult) -> Bool {
        //TODO: implement
        return false
    }
    
    func hash(into hasher: inout Hasher) {
        //TODO: implement
        hasher.combine(foo)
    }
    
}
