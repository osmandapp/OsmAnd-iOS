//
//  AstroArticle.swift
//  OsmAnd Maps
//
//  Created by Codex on 20.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation

final class AstroArticle: Equatable, Hashable {
    let wikidata: String
    let lang: String
    let title: String
    let description: String
    let thumbnailUrl: String?
    let summaryJson: String?
    private let mobileHtml: Data?

    var wikidataId: String { wikidata }
    var language: String { lang }
    var extract: String { description }

    init(wikidata: String,
         lang: String,
         title: String,
         description: String,
         thumbnailUrl: String?,
         summaryJson: String?,
         mobileHtml: Data?) {
        self.wikidata = wikidata
        self.lang = lang
        self.title = title
        self.description = description
        self.thumbnailUrl = thumbnailUrl
        self.summaryJson = summaryJson
        self.mobileHtml = mobileHtml
    }

    convenience init(wikidataId: String,
                     language: String,
                     title: String?,
                     extract: String?,
                     thumbnailUrl: String?,
                     summaryJson: String?,
                     mobileHtml: Data?) {
        self.init(wikidata: wikidataId,
                  lang: language,
                  title: title ?? "",
                  description: extract ?? "",
                  thumbnailUrl: thumbnailUrl,
                  summaryJson: summaryJson,
                  mobileHtml: mobileHtml)
    }

    func hasOfflineContent() -> Bool {
        mobileHtml?.isEmpty == false
    }

    func getMobileHtmlString() -> String? {
        guard let mobileHtml, !mobileHtml.isEmpty else {
            return nil
        }
        return String(data: mobileHtml, encoding: .utf8)
    }

    func getOnlineArticleUrl() -> String? {
        getSummaryArticleUrl() ?? buildFallbackArticleUrl()
    }

    private func getSummaryArticleUrl() -> String? {
        guard let summaryJson,
              let data = summaryJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content_urls"] as? [String: Any] else {
            return nil
        }

        if let mobile = content["mobile"] as? [String: Any],
           let page = mobile["page"] as? String,
           !page.isEmpty {
            return page
        }
        if let desktop = content["desktop"] as? [String: Any],
           let page = desktop["page"] as? String,
           !page.isEmpty {
            return page
        }
        return nil
    }

    private func buildFallbackArticleUrl() -> String? {
        guard !lang.isEmpty, !title.isEmpty else {
            return nil
        }
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "_")
        guard let encodedTitle = normalizedTitle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return nil
        }
        return "https://\(lang.lowercased()).wikipedia.org/wiki/\(encodedTitle)"
    }

    static func == (lhs: AstroArticle, rhs: AstroArticle) -> Bool {
        lhs.wikidata == rhs.wikidata &&
            lhs.lang == rhs.lang &&
            lhs.title == rhs.title &&
            lhs.description == rhs.description &&
            lhs.thumbnailUrl == rhs.thumbnailUrl &&
            lhs.summaryJson == rhs.summaryJson &&
            lhs.mobileHtml == rhs.mobileHtml
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(wikidata)
        hasher.combine(lang)
        hasher.combine(title)
        hasher.combine(description)
        hasher.combine(thumbnailUrl)
        hasher.combine(summaryJson)
        hasher.combine(mobileHtml)
    }

    func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AstroArticle else {
            return false
        }
        return wikidata == other.wikidata &&
            lang == other.lang &&
            title == other.title &&
            description == other.description &&
            thumbnailUrl == other.thumbnailUrl &&
            summaryJson == other.summaryJson &&
            mobileHtml == other.mobileHtml
    }
}
