//
//  TravelArticle.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 08.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OATravelArticle)
@objcMembers
class TravelArticle: NSObject {
    
    static let IMAGE_ROOT_URL = "https://upload.wikimedia.org/wikipedia/commons/"
    static let THUMB_PREFIX = "320px-"
    static let REGULAR_PREFIX = "1280px-" //1280, 1024, 800
    
    var file: String?
    var title: String?
    var content: String?
    var isPartOf: String?
    var isParentOf: String? = ""
    var lat: Double = Double.nan
    var lon: Double = Double.nan
    var imageTitle: String?
    var gpxFile: OAGPXDocumentAdapter?;
    var routeId: String?
    var routeRadius = -1
    var ref: String?
    var routeSource: String?
    var originalId: UInt64 = 0 //long
    var lang: String?
    var contentsJson: String?
    var aggregatedPartOf: String?
    var descr: String?
    
    var lastModified: TimeInterval = 0 //long
    var gpxFileReading: Bool = false
    var gpxFileRead: Bool = false
    
    func generateIdentifier() -> TravelArticleIdentifier {
        TravelArticleIdentifier(article: self)
    }
    
    static func getTravelBook(file: String) -> String {
        file.replacingOccurrences(of: OsmAndApp.swiftInstance().dataPath, with: "")
    }
    
    func getTravelBook() -> String? {
        file != nil ? TravelArticle.getTravelBook(file: file!) : nil
    }
    
    func getLastModified() -> TimeInterval {
        if lastModified > 0 {
            return lastModified
        }
        
        if let file {
            if let date = fileModificationDate(path: file) {
                return date.timeIntervalSince1970;
            }
        }
        return 0
    }
    
    func getGeoDescription() -> String? {
        if aggregatedPartOf == nil || aggregatedPartOf?.length == 0 {
            return nil
        }
        
        if let parts = aggregatedPartOf?.components(separatedBy: ",") {
            if !parts.isEmpty {
                var res = ""
                res.append(parts[parts.count - 1])
                
                if parts.count > 1 {
                    res.append(" \u{2022} ")
                    res.append(parts[0])
                }
                return res
            }
        }
        return nil
    }
    
    static func getImageUrl(imageTitle: String, thumbnail: Bool) -> String {
        if let title = decodeUrl(url: imageTitle.replacingOccurrences(of: " ", with: "_")) {
            if let hash = getHash(s: title) {
                if let title = encodeUrl(url: title) {
                    let prefix = thumbnail ? THUMB_PREFIX : REGULAR_PREFIX
                    let suffix = title.hasSuffix(".svg") ? ".png" : ""
                    return IMAGE_ROOT_URL + "thumb/" + hash[0] + "/" + hash[1] + "/" + title + "/" + prefix + title + suffix
                }
            }
        }
        return ""
    }
    
    func getPointFilterString() -> String {
        "route_article_point"
    }
    
    func getAnalysis() -> OAGPXTrackAnalysis? {
        nil
    }
    
    static func getHash(s: String) -> [String]? {
        if let md5 = OAUtilities.toMD5(s) {
            let index1 = md5.index(md5.startIndex, offsetBy: 1)
            let index2 = md5.index(md5.startIndex, offsetBy: 2)
            let substring1 = md5[..<index1]
            let substring2 = md5[..<index2]
            return [String(substring1), String(substring2)]
        }
        return nil
    }
    
    func equals(obj: TravelArticle?) -> Bool {
        if let obj {
            return OAMapUtils.areLatLonEqual(self.lat, lon1: self.lon, lat2: obj.lat, lon2: obj.lon) &&
                self.file == obj.file &&
                self.routeId == obj.routeId &&
                self.routeSource == obj.routeSource
        } else {
            return false
        }
    }
    
    static func == (lhs: TravelArticle, rhs: TravelArticle) -> Bool {
        lhs.equals(obj: rhs)
    }
    
    func fileModificationDate(path: String) -> Date? {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: path)
            return attr[FileAttributeKey.modificationDate] as? Date
        } catch {
            return nil
        }
    }
    
    static func encodeUrl(url: String) -> String?
    {
        url.addingPercentEncoding( withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
    }
    
    static func decodeUrl(url: String) -> String?
    {
        url.removingPercentEncoding
    }    
}

@objc(OATravelArticleIdentifier)
@objcMembers
final class TravelArticleIdentifier : NSObject {
   
    var file: String?
    var lat: Double = Double.nan
    var lon: Double = Double.nan
    var title: String?
    var routeId: String?
    var routeSource: String?
    
    init(article: TravelArticle) {
        file = article.file;
        lat = article.lat
        lon = article.lon
        title = article.title
        routeId = article.routeId
        routeSource = article.routeSource
    }

    static func == (lhs: TravelArticleIdentifier, rhs: TravelArticleIdentifier) -> Bool {
        return OAMapUtils.areLatLonEqual(lhs.lat, lon1: lhs.lon, lat2: rhs.lat, lon2: rhs.lon) &&
        lhs.file == rhs.file &&
        lhs.routeId == rhs.routeId &&
        lhs.routeSource == rhs.routeSource
    }
    
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(getFirstIntSymbols(lat, digitsCount: 10))
        hasher.combine(getFirstIntSymbols(lon, digitsCount: 10))
        hasher.combine(file ?? "")
        hasher.combine(routeId ?? "")
        hasher.combine(routeSource ?? "")
        return hasher.finalize()
    }
    
    private func getFirstIntSymbols(_ doubleValue: Double, digitsCount: Int) -> Int {
        // hasher.combine() sometimes makes differs cache for double values like latLon.
        // but it works fine if it will be rouder to Int. Like this:
        // 41.31233892746772 -> 4131233892
        return Int(doubleValue * pow(Double(10), Double(digitsCount)))
    }
}
