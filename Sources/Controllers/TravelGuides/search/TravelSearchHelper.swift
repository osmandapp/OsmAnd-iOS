//
//  TravelSearchHelper.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 19.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

final class TravelSearchHelper {
    
    let TIMEOUT_BETWEEN_CHARS: TimeInterval = 700.0
    let SLEEP_TIME: UInt64 = 50
    
    var requestNumber = 0
    var uiCanceled = false
    
    func search(query: String, onComplete: @escaping ([TravelSearchResult])->() ) {
        DispatchQueue.global(qos: .default).async {
            
            self.requestNumber += 1
            let req = self.requestNumber
            
            DispatchQueue.global(qos: .default).asyncAfter(deadline: .now() + self.TIMEOUT_BETWEEN_CHARS / 1000) {
                if self.isCanceled(req) {
                    return
                }
                
                if !self.isCanceled(req) {
                    let results = TravelObfHelper.shared.search(searchQuery: query)
                    if !self.isCanceled(req) {
                        
                        onComplete(results)
                    }
                }
            }
        }
    }
    
    func isCanceled(_ req: Int) -> Bool {
        requestNumber != req || uiCanceled
    }
}
