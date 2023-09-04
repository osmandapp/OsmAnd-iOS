//
//  TravelGuidesUtils.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 01.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

class TravelGuidesUtils {
    
    static let GEO_PARAMS = "?lat="
    static let ARTICLE_TITLE = "article_title"
    static let ARTICLE_LANG = "article_lang"
    
    static func processWikivoyageDomain(url: String, delegate: TravelArticleDialogProtocol) {
        let lang = OAWikiArticleHelper.getLang(url)
        let articleName = OAWikiArticleHelper.getArticleName(fromUrl: url, lang: lang)
        let articleId = TravelObfHelper.shared.getArticleId(title: articleName!, lang: lang!)
        if articleId != nil {
            delegate.openArticleById(articleId: articleId!, selectedLang: lang!)
        } else {
            OAWikiArticleHelper.warnAboutExternalLoad(url, sourceView: delegate.getWebView())
        }
    }
    
    static func processWikipediaDomain(defaultLocation: CLLocation, url: String, delegate: TravelArticleDialogProtocol) {
        var articleUrl = url
        let articleCoordinates = parseCoordinates(url: url)
        if articleUrl.contains(GEO_PARAMS) {
            articleUrl = articleUrl.substring(to: Int(articleUrl.index(of: GEO_PARAMS)))
        }
        let coordinates = articleCoordinates != nil ? articleCoordinates : defaultLocation
        OAWikiArticleHelper.showWikiArticle([coordinates!], url: articleUrl, onStart: nil, sourceView: delegate.getWebView()) {
            delegate.getWebView().removeSpinner()
        }
    }
    
    static func parseCoordinates(url: String) -> CLLocation? {
        if url.contains(GEO_PARAMS) {
            let geoPart = url.substring(from: Int(url.index(of: GEO_PARAMS)))
            let fristValueStart = Int(geoPart.index(of: "="))
            let firstValueEnd = Int(geoPart.index(of: "&"))
            
            let secondGeoPart = geoPart.substring(from: firstValueEnd)
            let secondValueStart = Int(secondGeoPart.index(of: "="))
            
            if fristValueStart != -1 && firstValueEnd != -1 && secondValueStart != -1  && firstValueEnd > fristValueStart {
                let lat = geoPart.substring(from: fristValueStart + 1, to: firstValueEnd)
                let lon = secondGeoPart.substring(from: fristValueStart)
                if Double(lat) != nil && Double(lon) != nil {
                    return CLLocation(latitude: Double(lat)!, longitude: Double(lon)!)
                }
            }
        }
        return nil
    }
    
}
