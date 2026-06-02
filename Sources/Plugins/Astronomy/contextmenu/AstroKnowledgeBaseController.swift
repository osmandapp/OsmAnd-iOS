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
    static let knowledgeBaseFileName = "stars-articles.stardb"
    static let resourceId = "stars-articles.stardb"
    static let resourceTaskKey = "resource:\(resourceId)"

    private static let travelRegionId = "travel"
    private static let resourceTypeName = "starmap"

    private(set) var requestedIndexesReload = false
    private var cachedDownloadItem: OAResourceSwiftItem?

    func buildCardItem(progressOverride: Float? = nil) -> AstroKnowledgeCardItem? {
        if isDownloaded() {
            return nil
        }
        guard let state = currentState() else {
            return nil
        }
        let resourceItem = state == .download ? findDownloadItem() : nil
        let downloadTask = state == .download ? findActiveDownload(resourceItem: resourceItem) : nil
        let progress = progressOverride ?? downloadTask?.progressCompleted
        return AstroKnowledgeCardItem(state: state,
                                      resourceId: resourceItem?.resourceId() ?? (state == .download ? Self.resourceId : nil),
                                      resourceItem: resourceItem,
                                      downloadTask: downloadTask,
                                      progress: progress,
                                      buttonTitle: buttonTitle(state: state,
                                                               resourceItem: resourceItem,
                                                               downloadTask: downloadTask,
                                                               progressOverride: progressOverride),
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
        isDownloaded() || findActiveDownload(resourceItem: findDownloadItem()) != nil || actionWasDisabled
    }

    func findDownloadItem() -> OAResourceSwiftItem? {
        if let cachedDownloadItem {
            cachedDownloadItem.refreshDownloadTask()
            return cachedDownloadItem
        }
        guard let resources = OAResourcesUISwiftHelper.getResourcesInRepositoryIds(byRegionId: Self.travelRegionId,
                                                                                   resourceTypeNames: [Self.resourceTypeName]) else {
            return nil
        }
        guard let item = resources.first(where: { $0.resourceId() == Self.resourceId }) else {
            return nil
        }
        item.refreshDownloadTask()
        cachedDownloadItem = item
        return item
    }

    func findActiveDownload(resourceItem: OAResourceSwiftItem? = nil) -> OADownloadTask? {
        resourceItem?.refreshDownloadTask()
        if let task = resourceItem?.downloadTask() {
            return task
        }
        guard let app = OsmAndApp.swiftInstance() else {
            return nil
        }
        return app.downloadsManager.downloadTasks(withKey: Self.resourceTaskKey).first as? OADownloadTask
    }

    private func knowledgeBaseFileUrl() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(RESOURCES_DIR, isDirectory: true)
            .appendingPathComponent("astro", isDirectory: true)
            .appendingPathComponent(Self.knowledgeBaseFileName, isDirectory: false)
    }

    private func buttonTitle(state: AstroKnowledgeCardState,
                             resourceItem: OAResourceSwiftItem?,
                             downloadTask: OADownloadTask?,
                             progressOverride: Float?) -> String {
        switch state {
        case .upsell:
            return localizedString("shared_string_get")
        case .download:
            if let downloadTask {
                let downloading = localizedString("downloading")
                let progress = progressOverride ?? downloadTask.progressCompleted
                if let progressText = downloadProgressText(resourceItem: resourceItem, progress: progress) {
                    return combine(downloading, progressText)
                }
                if let size = resourceSizeText(resourceItem) {
                    return combine(downloading, size)
                }
                return downloading
            }
            let download = localizedString("shared_string_download")
            if let size = resourceSizeText(resourceItem) {
                return combine(download, size)
            }
            return download
        }
    }

    private func downloadProgressText(resourceItem: OAResourceSwiftItem?, progress: Float) -> String? {
        guard let resourceItem,
              let text = OAResourcesUISwiftHelper.formatedDownloadingProgressString(resourceItem.sizePkg(), progress: progress),
              !text.isEmpty else {
            return nil
        }
        return text
    }

    private func resourceSizeText(_ resourceItem: OAResourceSwiftItem?) -> String? {
        guard let text = resourceItem?.formatedSizePkg(),
              !text.isEmpty else {
            return nil
        }
        return text
    }

    private func combine(_ first: String, _ second: String) -> String {
        String(format: localizedString("ltr_or_rtl_combine_via_space"), first, second)
    }
}
