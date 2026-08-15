//
//  OACrashDiagnosticsManager.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation
import MetricKit

@objcMembers
final class OACrashDiagnosticsManager: NSObject {
    static let shared = OACrashDiagnosticsManager()
    static let reportsDidChangeNotification = Notification.Name("OACrashDiagnosticsReportsDidChangeNotification")
    private static let shareSnapshotMaximumAge: TimeInterval = 24 * 60 * 60
    private static let shareSnapshotPrefix = "snapshot-"

    private let repository: OACrashReportRepository?
    private let shareSnapshotsDirectoryURL: URL?
    private let fileManager: FileManager
    private lazy var metricSubscriber = OACrashMetricManagerSubscriber(manager: self)
    private let storageQueue = DispatchQueue(label: "net.osmand.crash-diagnostics.storage", qos: .utility)
    private let startLock = NSLock()
    private let reportsLock = NSLock()
    private var isStarted = false
    private var cachedReportURLs: [URL] = []

    private override init() {
        let fileManager = FileManager.default
        self.fileManager = fileManager
        var repositoryInitializationError: Error?
        do {
            let applicationSupportURL = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            repository = OACrashReportRepository(
                directoryURL: applicationSupportURL.appendingPathComponent("CrashDiagnostics", isDirectory: true)
            )
            shareSnapshotsDirectoryURL = applicationSupportURL.appendingPathComponent(
                "CrashDiagnosticsShareSnapshots",
                isDirectory: true
            )
        } catch {
            repository = nil
            shareSnapshotsDirectoryURL = nil
            repositoryInitializationError = error
        }

        super.init()

        if let repositoryInitializationError {
            Self.logStorageFailure(
                "locate the Application Support directory",
                error: repositoryInitializationError
            )
        }
    }

    /// Registers the singleton as a MetricKit subscriber exactly once per process.
    func start() {
        startLock.lock()
        let shouldStart = !isStarted
        isStarted = true
        startLock.unlock()

        guard shouldStart else { return }
        MXMetricManager.shared.add(metricSubscriber)

        guard let repository else { return }
        storageQueue.async { [weak self] in
            guard let self else { return }
            self.removeStaleShareSnapshots()
            do {
                let urls = try repository.latestReportURLsPruningIfNeeded()
                let didChange = self.replaceCachedReportURLs(with: urls)
                if didChange {
                    self.postReportsDidChangeNotification()
                }
            } catch {
                Self.logStorageFailure("load stored crash diagnostics", error: error)
            }
        }
    }

    var hasCrashReports: Bool {
        reportsLock.lock()
        defer { reportsLock.unlock() }
        return !cachedReportURLs.isEmpty
    }

    var latestCrashReportURLs: [URL] {
        reportsLock.lock()
        defer { reportsLock.unlock() }
        return cachedReportURLs
    }

    /// Creates immutable copies for one share-sheet session. Retention may safely
    /// continue deleting original reports while these URLs are in use.
    @objc(prepareCrashReportsForSharing:)
    func prepareCrashReportsForSharing(_ completion: @escaping ([URL]) -> Void) {
        guard let repository, shareSnapshotsDirectoryURL != nil else {
            DispatchQueue.main.async {
                completion([])
            }
            return
        }

        storageQueue.async { [weak self] in
            guard let self else { return }
            let sourceURLs: [URL]
            do {
                sourceURLs = try repository.latestReportURLsPruningIfNeeded()
                let didChange = self.replaceCachedReportURLs(with: sourceURLs)
                if didChange {
                    self.postReportsDidChangeNotification()
                }
            } catch {
                Self.logStorageFailure("refresh crash reports before sharing", error: error)
                sourceURLs = self.readableCachedReportURLs()
                if self.replaceCachedReportURLs(with: sourceURLs) {
                    self.postReportsDidChangeNotification()
                }
            }

            guard !sourceURLs.isEmpty else {
                self.completeSharePreparation(with: [], completion: completion)
                return
            }

            do {
                let snapshotURLs = try self.createShareSnapshot(from: sourceURLs)
                self.completeSharePreparation(with: snapshotURLs, completion: completion)
            } catch {
                Self.logStorageFailure("prepare crash reports for sharing", error: error)
                self.completeSharePreparation(with: [], completion: completion)
            }
        }
    }

    /// Deletes only a snapshot directory previously created by this manager.
    @objc(cleanUpCrashReportsShareSnapshot:)
    func cleanUpCrashReportsShareSnapshot(_ urls: [URL]) {
        guard let shareSnapshotsDirectoryURL,
              let snapshotDirectoryURL = urls.first?.deletingLastPathComponent().standardizedFileURL,
              urls.allSatisfy({ $0.deletingLastPathComponent().standardizedFileURL == snapshotDirectoryURL }),
              isManagedShareSnapshotDirectory(snapshotDirectoryURL),
              snapshotDirectoryURL.deletingLastPathComponent().standardizedFileURL
                == shareSnapshotsDirectoryURL.standardizedFileURL else {
            return
        }

        storageQueue.async { [weak self] in
            guard let self else { return }
            do {
                if self.fileManager.fileExists(atPath: snapshotDirectoryURL.path) {
                    try self.fileManager.removeItem(at: snapshotDirectoryURL)
                }
            } catch {
                Self.logStorageFailure("remove a crash-report share snapshot", error: error)
            }
        }
    }

    @discardableResult
    private func replaceCachedReportURLs(with urls: [URL]) -> Bool {
        reportsLock.lock()
        defer { reportsLock.unlock() }
        let didChange = cachedReportURLs != urls
        cachedReportURLs = urls
        return didChange
    }

    private func postReportsDidChangeNotification() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            NotificationCenter.default.post(
                name: Self.reportsDidChangeNotification,
                object: self
            )
        }
    }

    private func readableCachedReportURLs() -> [URL] {
        latestCrashReportURLs.filter {
            fileManager.isReadableFile(atPath: $0.path)
        }
    }

    private func createShareSnapshot(from sourceURLs: [URL]) throws -> [URL] {
        guard let shareSnapshotsDirectoryURL else { return [] }

        try prepareProtectedDirectory(shareSnapshotsDirectoryURL)
        let snapshotDirectoryURL = shareSnapshotsDirectoryURL.appendingPathComponent(
            "\(Self.shareSnapshotPrefix)\(UUID().uuidString.lowercased())",
            isDirectory: true
        )
        try prepareProtectedDirectory(snapshotDirectoryURL)

        do {
            var snapshotURLs: [URL] = []
            snapshotURLs.reserveCapacity(sourceURLs.count)
            for sourceURL in sourceURLs {
                let destinationURL = snapshotDirectoryURL.appendingPathComponent(
                    sourceURL.lastPathComponent,
                    isDirectory: false
                )
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
                try fileManager.setAttributes(
                    [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                    ofItemAtPath: destinationURL.path
                )
                snapshotURLs.append(destinationURL)
            }
            return snapshotURLs
        } catch {
            try? fileManager.removeItem(at: snapshotDirectoryURL)
            throw error
        }
    }

    private func prepareProtectedDirectory(_ directoryURL: URL) throws {
        try fileManager.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true,
            attributes: [
                .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
            ]
        )
        try fileManager.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: directoryURL.path
        )

        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutableDirectoryURL = directoryURL
        try mutableDirectoryURL.setResourceValues(resourceValues)
    }

    private func removeStaleShareSnapshots() {
        guard let shareSnapshotsDirectoryURL,
              fileManager.fileExists(atPath: shareSnapshotsDirectoryURL.path) else {
            return
        }
        do {
            let resourceKeys: Set<URLResourceKey> = [
                .contentModificationDateKey,
                .creationDateKey,
                .isDirectoryKey
            ]
            let cutoffDate = Date().addingTimeInterval(-Self.shareSnapshotMaximumAge)
            let contents = try fileManager.contentsOfDirectory(
                at: shareSnapshotsDirectoryURL,
                includingPropertiesForKeys: Array(resourceKeys),
                options: [.skipsHiddenFiles]
            )
            for url in contents where isManagedShareSnapshotDirectory(url) {
                guard let values = try? url.resourceValues(forKeys: resourceKeys),
                      values.isDirectory == true,
                      let date = values.contentModificationDate ?? values.creationDate,
                      date < cutoffDate else {
                    continue
                }
                do {
                    try fileManager.removeItem(at: url)
                } catch {
                    Self.logStorageFailure(
                        "remove stale crash-report share snapshot \(url.lastPathComponent)",
                        error: error
                    )
                }
            }
        } catch {
            Self.logStorageFailure("inspect stale crash-report share snapshots", error: error)
        }
    }

    private func isManagedShareSnapshotDirectory(_ url: URL) -> Bool {
        let name = url.lastPathComponent
        guard name.hasPrefix(Self.shareSnapshotPrefix) else { return false }
        let identifier = String(name.dropFirst(Self.shareSnapshotPrefix.count))
        return UUID(uuidString: identifier) != nil
    }

    private func completeSharePreparation(
        with urls: [URL],
        completion: @escaping ([URL]) -> Void
    ) {
        DispatchQueue.main.async {
            completion(urls)
        }
    }

    @nonobjc
    fileprivate func storeCrashDiagnostics(from payloads: [MXDiagnosticPayload]) {
        guard let repository else { return }

        storageQueue.async { [weak self] in
            guard let self else { return }
            var didReceiveCrashDiagnostic = false
            var newlyStoredURLs: [URL] = []

            for payload in payloads {
                for crashDiagnostic in payload.crashDiagnostics ?? [] {
                    didReceiveCrashDiagnostic = true
                    do {
                        let url = try repository.save(crashDiagnostic.jsonRepresentation())
                        newlyStoredURLs.append(url)
                    } catch {
                        Self.logStorageFailure("store a MetricKit crash diagnostic", error: error)
                    }
                }
            }

            guard didReceiveCrashDiagnostic else { return }
            var didChangeStoredReports = false
            do {
                let urls = try repository.latestReportURLsPruningIfNeeded()
                didChangeStoredReports = self.replaceCachedReportURLs(with: urls)
            } catch {
                Self.logStorageFailure("refresh stored crash diagnostics", error: error)
                let cachedURLs = self.latestCrashReportURLs
                var seenURLs = Set<URL>()
                let fallbackURLs = (Array(newlyStoredURLs.reversed()) + cachedURLs)
                    .filter {
                        self.fileManager.isReadableFile(atPath: $0.path)
                            && seenURLs.insert($0).inserted
                    }
                    .prefix(OACrashReportRepository.defaultRetentionLimit)
                didChangeStoredReports = self.replaceCachedReportURLs(with: Array(fallbackURLs))
            }
            if !newlyStoredURLs.isEmpty || didChangeStoredReports {
                self.postReportsDidChangeNotification()
            }
        }
    }

    private static func logStorageFailure(_ operation: String, error: Error) {
        NSLog("[CrashDiagnostics] Failed to %@: %@", operation, error.localizedDescription)
    }
}

private final class OACrashMetricManagerSubscriber: NSObject, MXMetricManagerSubscriber {
    private weak var manager: OACrashDiagnosticsManager?

    init(manager: OACrashDiagnosticsManager) {
        self.manager = manager
        super.init()
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        manager?.storeCrashDiagnostics(from: payloads)
    }
}
