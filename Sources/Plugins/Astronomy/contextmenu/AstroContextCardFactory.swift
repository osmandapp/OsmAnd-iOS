//
//  AstroContextCardFactory.swift
//  OsmAnd Maps
//
//  Ported from Android AstroContextCardFactory.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation

final class AstroContextCardFactory {
    func buildCards(skyObject: SkyObject?,
                    article: AstroArticle?,
                    uiState: AstroContextUiState,
                    knowledgeItem: AstroKnowledgeCardItem?,
                    visibilityItem: AstroVisibilityCardItem?,
                    scheduleItem: AstroScheduleCardItem?) -> [AstroContextMenuItem] {
        guard let skyObject else {
            return []
        }

        var items: [AstroContextMenuItem] = []
        let descriptionItem = buildDescriptionCardItem(obj: skyObject, astroArticle: article)
        if let descriptionItem {
            items.append(descriptionItem)
        }
        if !skyObject.catalogs.isEmpty {
            items.append(AstroCatalogsCardItem(catalogs: skyObject.catalogs, expanded: uiState.catalogsExpanded))
        }
        items.append(AstroGalleryCardItem(wid: skyObject.wid,
                                          showAllTitle: skyObject.niceName(),
                                          state: uiState.galleryState))
        if let knowledgeItem, (knowledgeItem.state == .download || descriptionItem == nil) {
            items.append(knowledgeItem)
        }
        if let visibilityItem {
            items.append(visibilityItem)
        }
        if let scheduleItem {
            items.append(scheduleItem)
        }
        return items
    }

    private func buildDescriptionCardItem(obj: SkyObject, astroArticle: AstroArticle?) -> AstroDescriptionCardItem? {
        let description = astroArticle?.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let hasOfflineArticle = astroArticle?.hasOfflineContent() == true
        let wikipediaUri = astroArticle?.getOnlineArticleUrl().flatMap(URL.init(string:))
        let hasWikipediaArticle = hasOfflineArticle || wikipediaUri != nil
        let wikidataUri = obj.wid.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !shouldOpenWikidata(obj: obj, hasWikipediaArticle: hasWikipediaArticle)
            ? nil
            : buildWikidataUri(wikidataId: obj.wid)
        let readMoreUri = wikipediaUri ?? wikidataUri
        let linkType: AstroDescriptionLinkType?
        if hasWikipediaArticle {
            linkType = .wikipedia
        } else if wikidataUri != nil {
            linkType = .wikidata
        } else {
            linkType = nil
        }

        if description.isEmpty && readMoreUri == nil && !hasOfflineArticle {
            return nil
        }
        return AstroDescriptionCardItem(description: description,
                                        readMoreUri: readMoreUri,
                                        linkType: linkType,
                                        hasOfflineArticle: hasOfflineArticle)
    }

    private func buildWikidataUri(wikidataId: String) -> URL? {
        let encoded = wikidataId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? wikidataId
        return URL(string: "https://www.wikidata.org/wiki/\(encoded)")
    }

    private func shouldOpenWikidata(obj: SkyObject, hasWikipediaArticle: Bool) -> Bool {
        if hasWikipediaArticle {
            return false
        }
        return obj.hasMissingPrimaryName()
    }
}
