//
//  AstroKnowledgeBaseController.swift
//  OsmAnd Maps
//
//  Ported from Android AstroKnowledgeBaseController.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation
import UIKit

final class AstroKnowledgeBaseController {
    private static let knowledgeBaseFileName = "stars-articles.stardb"

    private(set) var requestedIndexesReload = false

    func buildCardItem() -> AstroKnowledgeCardItem? {
        if isDownloaded() {
            return nil
        }
        guard let state = currentState() else {
            return nil
        }
        return AstroKnowledgeCardItem(state: state,
                                      buttonTitle: state == .download
                                        ? localizedString("shared_string_download")
                                        : localizedString("shared_string_get"),
                                      actionEnabled: true)
    }

    func currentState() -> AstroKnowledgeCardState? {
        if isDownloaded() {
            return nil
        }
        return hasAccess() ? .download : .upsell
    }

    func hasAccess() -> Bool {
        OAIAPHelper.isOsmAndProAvailable()
    }

    func isDownloaded() -> Bool {
        knowledgeBaseFileUrl().map { FileManager.default.fileExists(atPath: $0.path) } ?? false
    }

    func ensureIndexesLoaded() {
        requestedIndexesReload = true
    }

    func resetIndexesReloadFlag() {
        requestedIndexesReload = false
    }

    func shouldRefreshAfterDownload(_ actionWasDisabled: Bool) -> Bool {
        isDownloaded() || actionWasDisabled
    }

    private func knowledgeBaseFileUrl() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(RESOURCES_DIR, isDirectory: true)
            .appendingPathComponent("astro", isDirectory: true)
            .appendingPathComponent(Self.knowledgeBaseFileName, isDirectory: false)
    }
}
