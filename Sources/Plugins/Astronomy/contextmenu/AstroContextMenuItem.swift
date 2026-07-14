//
//  AstroContextMenuItem.swift
//  OsmAnd Maps
//
//  Ported from Android AstroContextMenuItem.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation
import UIKit

enum AstroContextCardKey: Int64, CaseIterable {
    case knowledge = 1
    case description = 2
    case catalogs = 3
    case gallery = 4
    case visibility = 5
    case schedule = 6

    var stableId: Int64 {
        rawValue
    }
}

protocol AstroContextMenuItem {
    var key: AstroContextCardKey { get }
}

enum AstroKnowledgeCardState {
    case upsell
    case download
}

enum AstroDescriptionLinkType {
    case wikipedia
    case wikidata
}

enum AstroGalleryState {
    case collapsed
    case loading
    case ready([AbstractCard])
}

struct AstroKnowledgeCardItem: AstroContextMenuItem {
    let state: AstroKnowledgeCardState
    let resourceId: String?
    let resourceItem: OAResourceSwiftItem?
    let downloadTask: OADownloadTask?
    let progress: Float?
    let buttonTitle: String
    let actionEnabled: Bool
    let key: AstroContextCardKey = .knowledge

    var isDownloading: Bool {
        downloadTask != nil
    }

    func getTitle() -> String {
        switch state {
        case .upsell:
            return localizedString("astro_expand_your_universe_title")
        case .download:
            return localizedString("astro_offline_knowledge_base_title")
        }
    }

    func getDescription() -> String {
        switch state {
        case .upsell:
            return localizedString("astro_expand_your_universe_description")
        case .download:
            return localizedString("astro_offline_knowledge_base_description")
        }
    }

    func getIconName() -> String {
        switch state {
        case .upsell:
            return "ic_custom_telescope_colored"
        case .download:
            return "ic_custom_sky_map_download"
        }
    }
}

struct AstroDescriptionCardItem: AstroContextMenuItem {
    let description: String
    let readMoreUri: URL?
    let linkType: AstroDescriptionLinkType?
    let hasOfflineArticle: Bool
    let key: AstroContextCardKey = .description
}

struct AstroCatalogsCardItem: AstroContextMenuItem {
    let catalogs: [Catalog]
    let expanded: Bool
    let key: AstroContextCardKey = .catalogs
}

struct AstroGalleryCardItem: AstroContextMenuItem {
    let wid: String
    let showAllTitle: String?
    let state: AstroGalleryState
    let key: AstroContextCardKey = .gallery
}

struct AstroVisibilityGraphSnapshot {
    let startMillis: Int64
    let endMillis: Int64
    let timeZone: TimeZone
    let objectAltitudes: [Double]
    let objectAzimuths: [Double]
    let sunAltitudes: [Double]

    var size: Int {
        objectAltitudes.count
    }
}

struct AstroVisibilityCardItem: AstroContextMenuItem {
    let graph: AstroVisibilityGraphSnapshot?
    let cursorReferenceTimeMillis: Int64
    let riseTime: String?
    let culminationTime: String?
    let setTime: String?
    let locationText: String
    let culminationColor: UIColor
    let titleText: String
    let showResetButton: Bool
    let key: AstroContextCardKey = .visibility
}

struct AstroScheduleDayGraphSnapshot {
    let sunAltitudes: [Double]
    let objectAltitudes: [Double]
}

struct AstroScheduleDayItem {
    let date: Date
    let riseTime: String?
    let setTime: String?
    let setDayOffset: Int
    let graph: AstroScheduleDayGraphSnapshot
}

struct AstroScheduleCardItem: AstroContextMenuItem {
    let periodStart: Date
    let rangeLabel: String
    let days: [AstroScheduleDayItem]
    let showResetPeriodButton: Bool
    let key: AstroContextCardKey = .schedule
}
