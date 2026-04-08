//
//  AmenityExtensionsHelper.swift
//  OsmAnd
//
//  Created by Xcode Assistant on 07/04/2026.
//

@objcMembers
final class AmenityExtensionsHelper: NSObject {
    private static let wikidata = "wikidata"
    private static let wikipedia = "wikipedia"
    private static let wikimediaCommons = "wikimedia_commons"
    private static let mapillary = "mapillary"
    private static let image = "image"
    
    private static let osmImageKey = "osm_image"
    
    private static let tags = [
        image,
        mapillary,
        wikidata,
        wikipedia,
        wikimediaCommons
    ]
    
    static func imageParams(from extensions: [String: String]) -> [String: String] {
        tags.reduce(into: [:]) { result, tag in
            guard let value = extensions[tag], !value.isEmpty else { return }
            
            let key = tag == image ? osmImageKey : tag
            result[key] = value.removingPercentEncoding ?? value
        }
    }
}
