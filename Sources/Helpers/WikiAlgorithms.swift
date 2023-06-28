//
//  WikiAlgorithms.swift
//  OsmAnd Maps
//
//  Created by Skalii on 26.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAWikiAlgorithms)
@objcMembers
class WikiAlgorithms : NSObject {
    static let wikipedia = "wikipedia"
    static let wikipediaDomain = ".wikipedia.org/"
    static let wikiLink = wikipediaDomain + "wiki/"

    static func getWikiUrl(text: String) -> String {
        return getWikiParams(key: "", value: text).1
    }

    static func getWikiParams(key: String, value: String) -> (String, String) {
        var title: String?
        var langCode: String = "en"
        // Full OpenStreetMap Wikipedia tag pattern looks like "operator:wikipedia:lang_code",
        // "operator" and "lang_code" is optional parameters and may be skipped.
        if key.contains(":") {
            let tagParts: [Substring] = key.split(separator: ":")
            if tagParts.count == 3 {
                // In this case tag contains all 3 parameters: "operator", "wikipedia" and "lang_code".
                langCode = String(tagParts[2])
            } else if tagParts.count == 2 {
                // In this case one of the optional parameters was skipped.
                // Parameters never change their order and parameter "wikipedia" is always present.
                if wikipedia == String(tagParts[0]) {
                    // So if "wikipedia" is the first parameter, then parameter "operator" was skipped.
                    // And the second parameter is "lang_code".
                    langCode = String(tagParts[1])
                }
            }
        }
        // Value of an Wikipedia item can be an URL, but it is not recommended.
        // OSM users should use the following pattern "lang_code:article_title" instead.
        // Where "lang_code" is optional parameter for multilingual wikipedia tags.
        var url: String
        if isUrl(value) {
            // In this case a value is already represented as an URL.
            url = value
        } else {
            if value.contains(":") {
                // If value contains a sign ":" it means that "lang_code" is also present in value.
                let valueParts: [Substring] = value.split(separator: ":")
                langCode = String(valueParts[0])
                title = String(valueParts[1])
            } else {
                title = value
            }
            // Full article URL has a pattern: "http://lang_code.wikipedia.org/wiki/article_name"
            let formattedTitle: String = title?.replacingOccurrences(of: " ", with: "_") ?? ""
            url = "http://" + langCode + wikiLink + formattedTitle
        }

        let text: String = title != nil ? title! : value
        return (text, url)
    }

    static func isUrl(_ value: String) -> Bool {
        return value.lowercased().hasPrefix("http://") || value.lowercased().hasPrefix("https://")
    }
}
