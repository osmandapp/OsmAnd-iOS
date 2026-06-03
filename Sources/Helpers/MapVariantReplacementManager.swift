//
//  MapVariantReplacementManager.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 03.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class MapVariantReplacementManager: NSObject {

    static let shared = MapVariantReplacementManager()

    // MARK: - Properties

    /// Map variants grouped by resource identifier.
    /// Stored until installation completes successfully,
    /// after which obsolete variants are deleted.
    private var pendingDeletions: [String: [OAResourceSwiftItem]] = [:]

    private var downloadFailedObserver: OAAutoObserverProxy?

    // MARK: - Initialization

    private override init() {
        super.init()

        registerObservers()
    }

    // MARK: - Public API

    func storePendingDeletion(_ resources: [OAResourceSwiftItem], for resourceId: String) {
        pendingDeletions[resourceId] = resources
    }

    private func clearPendingDeletion(for resourceId: String) {
        guard !resourceId.isEmpty else { return }
        pendingDeletions.removeValue(forKey: resourceId)
    }

    private func pendingDeletion(for resourceId: String) -> [OAResourceSwiftItem]? {
        pendingDeletions[resourceId]
    }

    // MARK: - Private

    private func registerObservers() {
        downloadFailedObserver = OAAutoObserverProxy(self, withHandler: #selector(onDownloadTaskFinished(_:withKey:andValue:)),
                                                     andObserve: OsmAndApp.swiftInstance().downloadsManager.completedObservable)

        NotificationCenter.default.addObserver( forName: NSNotification.Name.OAResourceInstalled, object: nil, queue: .main ) { [weak self] notification in

            guard let self, let task = notification.object as? OADownloadTask else {
                return
            }

            guard task.key.hasPrefix("resource:") else {
                return
            }

            let resourceId = String(task.key.dropFirst("resource:".count))

            guard let resources = self.pendingDeletion(for: resourceId), !resources.isEmpty else {
                return
            }

            self.clearPendingDeletion(for: resourceId)

            OAResourcesUISwiftHelper.deleteResources(of: resources, progressHUD: nil, executeAfterSuccess: nil)
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name.OAResourceInstallationFailed, object: nil, queue: .main) { [weak self] notification in
            guard let resourceId = notification.object as? String, !resourceId.isEmpty else {
                return
            }

            self?.clearPendingDeletion(for: resourceId)
        }
    }

    @objc
    private func onDownloadTaskFinished(_ observer: OAObservableProtocol?, withKey key: Any?, andValue value: Any?) {
        guard let task = key as? OADownloadTask, task.key.hasPrefix("resource:"), task.error != nil else {
            return
        }

        let resourceId = String(task.key.dropFirst("resource:".count))

        clearPendingDeletion(for: resourceId)
    }
}
