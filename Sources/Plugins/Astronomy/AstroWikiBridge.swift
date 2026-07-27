//
//  AstroWikiBridge.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 16.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class AstroWikiBridge: NSObject {

    private static var dataProvider: AstroDataProvider? {
        (OAPluginsHelper.getPlugin(AstronomyPlugin.self) as? AstronomyPlugin)?.dataProvider
    }

    static func availableLanguages(wikidataId: String) -> [String] {
        dataProvider?.getAstroArticleLanguages(wikidataId: wikidataId).map { $0 == "en" ? "" : $0 } ?? []
    }

    static func loadArticle(wikidataId: String, lang: String) -> NSDictionary? {
        let dbLang = lang.isEmpty ? "en" : lang
        guard let article = dataProvider?.getAstroArticle(wikidataId: wikidataId, lang: dbLang),
              let html = article.getMobileHtmlString() else {
            return nil
        }
        return [
            "html": extractBody(from: html),
            "title": article.title,
            "locale": article.lang == "en" ? "" : article.lang,
            "onlineURL": article.getOnlineArticleUrl() ?? ""
        ]
    }

    private static func extractBody(from html: String) -> String {
        let bodyContentRegex = try? NSRegularExpression(
            pattern: "<body[^>]*>([\\s\\S]*?)</body>",
            options: [.caseInsensitive]
        )
        guard let regex = bodyContentRegex else { return html }
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: range),
              match.numberOfRanges > 1,
              let bodyRange = Range(match.range(at: 1), in: html) else {
            return html
        }
        return String(html[bodyRange])
    }
}
