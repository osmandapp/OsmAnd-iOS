//
//  TravelContentJsonStructs.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 25.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

final class TravelJsonParser {
    
    static let HEADERS = "headers"
    static let SUBHEADERS = "subheaders"
    static let LINK = "link"
    
    static func parseJsonContents(jsonText: String) -> TravelContentItem {
        
        let topContentItem = TravelContentItem(name: HEADERS, link: nil)
        
        let data = Data(jsonText.utf8)
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                
                if let headers = json[HEADERS] as? [String : Any] {
                    for headerName in headers.keys {
                        
                        if let headerContent = headers[headerName] as? [String : Any] {
                            let link = headerContent[LINK] as? String
                            let headerItem = TravelContentItem(name: headerName, link: link, parent: topContentItem)
                            topContentItem.subItems.append(headerItem)
                            
                            if let subheaders = headerContent[SUBHEADERS] as? [String : Any] {
                                for subheaderName in subheaders.keys {
                                    
                                    if let subheaderContent = subheaders[subheaderName] as? [String : Any] {
                                        let subheaderLink = subheaderContent[LINK] as? String
                                        let subheaderItem = TravelContentItem(name: subheaderName, link: subheaderLink, parent: headerItem)
                                        headerItem.subItems.append(subheaderItem)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
        } catch let error as NSError {
            print("Travel Article Contents JSON parsing error: \(error.localizedDescription)")
        }
        
        return sortContentItem(topContentItem: topContentItem, jsonText: jsonText)
    }
    
    static func sortContentItem(topContentItem: TravelContentItem, jsonText: String) -> TravelContentItem {
        let sortedTopContentItem = topContentItem
        sortedTopContentItem.subItems.sort { a, b in
            guard let rangeA = jsonText.range(of: a.name) else {return false}
            guard let rangeB = jsonText.range(of: b.name) else {return false}
            let indexA = rangeA.lowerBound
            let indexB = rangeB.lowerBound
            return indexA < indexB
        }
        
        for subitem in sortedTopContentItem.subItems {
            subitem.subItems.sort { a, b in
                guard let rangeA = jsonText.range(of: a.name) else {return false}
                guard let rangeB = jsonText.range(of: b.name) else {return false}
                let indexA = rangeA.lowerBound
                let indexB = rangeB.lowerBound
                return indexA < indexB
            }
        }
        
        return sortedTopContentItem
    }
    
}


final class TravelContentItem {
    var name: String
    var link: String?
    var subItems: [TravelContentItem]
    var parent: TravelContentItem?
    
    init(name: String, link: String?) {
        self.link = link
        self.name = name
        self.parent = nil
        self.subItems = []
    }
    
    init(name: String, link: String?, parent: TravelContentItem?) {
        self.link = link
        self.name = name
        self.parent = parent
        self.subItems = []
    }
}
