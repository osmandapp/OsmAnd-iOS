//
//  TravelGuidesUtils.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 01.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

final class TravelGuidesUtils {
    
    static let GEO_PARAMS = "?lat="
    static let ARTICLE_TITLE = "article_title"
    static let ARTICLE_LANG = "article_lang"
    static let EN_LANG_PREFIX = "en:"
    
    static func processWikivoyageDomain(url: String, delegate: TravelArticleDialogProtocol) {
        guard let lang = OAWikiArticleHelper.getLang(url), 
                let articleName = OAWikiArticleHelper.getArticleName(fromUrl: url, lang: lang) else { return }
        
        if let articleId = TravelObfHelper.shared.getArticleId(title: articleName, lang: lang) {
            delegate.openArticleById(newArticleId: articleId, newSelectedLang: lang)
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
        if let coordinates {
            OAWikiArticleHelper.showWikiArticle([coordinates], url: articleUrl, onStart: nil, sourceView: delegate.getWebView()) {
                delegate.getWebView().removeSpinner()
            }
        }
    }
    
    static func parseCoordinates(url: String) -> CLLocation? {
        if url.contains(GEO_PARAMS) {
            let geoPart = url.substring(from: Int(url.index(of: GEO_PARAMS)))
            let fristValueStart = Int(geoPart.index(of: "="))
            let firstValueEnd = Int(geoPart.index(of: "&"))
            
            let secondGeoPart = geoPart.substring(from: firstValueEnd)
            let secondValueStart = Int(secondGeoPart.index(of: "="))
            
            if fristValueStart != -1 && firstValueEnd != -1 && secondValueStart != -1 && firstValueEnd > fristValueStart {
                let lat = geoPart.substring(from: fristValueStart + 1, to: firstValueEnd)
                let lon = secondGeoPart.substring(from: fristValueStart)
                if let doubleLat = Double(lat), let doubleLon = Double(lon) {
                    return CLLocation(latitude: doubleLat, longitude: doubleLon)
                }
            }
        }
        return nil
    }
    
    static func getTitleWithoutPrefix(title: String) -> String {
        title.hasPrefix(EN_LANG_PREFIX) ? String(title.dropFirst(EN_LANG_PREFIX.count)) : title
    }
}
