//
//  TracksIndexingTracker.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 20.10.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import OsmAndShared

final class TracksIndexingTracker {
    private struct IndexingRun {
        private(set) var pendingFiles: [String: KFile]
        private(set) var progress: CGFloat = 0
        private var seenCount: Int

        init(pendingFiles: [String: KFile]) {
            self.pendingFiles = pendingFiles
            seenCount = pendingFiles.count
        }

        mutating func update(pendingFiles: [String: KFile]) {
            seenCount += pendingFiles.keys.filter { self.pendingFiles[$0] == nil }.count
            self.pendingFiles = pendingFiles
            progress = max(progress, CGFloat(seenCount - pendingFiles.count) / CGFloat(seenCount))
        }
    }

    private static var run: IndexingRun?

    private(set) var isInProgress = false

    var progress: CGFloat {
        Self.run?.progress ?? 0
    }

    func refresh(rootFolder: TrackFolder?) {
        let helper = GpxDbHelper.shared
        guard helper.isInitialized() else { return }
        var pendingFiles = Self.run?.pendingFiles.filter { isPending($0.value, helper: helper) } ?? [:]
        if pendingFiles.isEmpty {
            Self.run = nil
        }
        if let rootFolder {
            collectPendingFiles(in: rootFolder, helper: helper, into: &pendingFiles)
        }
        if !pendingFiles.isEmpty {
            if Self.run == nil {
                Self.run = IndexingRun(pendingFiles: pendingFiles)
            } else {
                Self.run?.update(pendingFiles: pendingFiles)
            }
        }
        isInProgress = Self.run != nil
    }

    private func collectPendingFiles(in folder: TrackFolder, helper: GpxDbHelper, into pendingFiles: inout [String: KFile]) {
        for item in folder.getTrackItems() where item.dataItem == nil {
            let path = item.path
            if pendingFiles[path] == nil, let file = item.getFile(), isPending(file, helper: helper) {
                pendingFiles[path] = file
            }
        }
        for subfolder in folder.getSubFolders() {
            collectPendingFiles(in: subfolder, helper: helper, into: &pendingFiles)
        }
    }

    private func isPending(_ file: KFile, helper: GpxDbHelper) -> Bool {
        !helper.hasGpxDataItem(file: file) && helper.isReading(file: file)
    }
}
