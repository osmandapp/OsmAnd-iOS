//
//  CrashDiagnosticsStore.swift
//  OsmAnd Maps
//

import Foundation

enum CrashDiagnosticsStoreError: Error {
    case reportNotFound
    case consentIntegrityFailure
}

final class CrashDiagnosticsStore {
    static let maximumReportCount = 3
    static let maximumTotalBytes = 5 * 1_024 * 1_024
    static let maximumAge: TimeInterval = 7 * 24 * 60 * 60

    private let fileManager: FileManager
    private let reportsDirectory: URL
    private let queue = DispatchQueue(label: "net.osmand.crash-diagnostics.store")

    init(baseDirectory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let baseDirectory {
            reportsDirectory = baseDirectory.appendingPathComponent("Reports", isDirectory: true)
        } else {
            let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            reportsDirectory = applicationSupport
                .appendingPathComponent("CrashDiagnostics", isDirectory: true)
                .appendingPathComponent("Reports", isDirectory: true)
        }
        queue.sync {
            configureDirectoryLocked()
            pruneLocked(now: Date())
        }
    }

    @discardableResult
    func save(_ report: CrashReportEnvelope, now: Date = Date()) throws -> Bool {
        try queue.sync {
            configureDirectoryLocked()
            let existing = loadAllLocked()
            guard !existing.contains(where: { isLikelyDuplicate($0.report, report) }) else {
                return false
            }
            let stored = StoredCrashReport(
                report: report,
                uploadState: .pending,
                consent: nil,
                createdAt: now,
                uploadAttempts: 0,
                nextRetryAt: nil
            )
            try writeLocked(stored)
            pruneLocked(now: now)
            return fileManager.fileExists(atPath: reportURL(reportID: report.reportID).path)
        }
    }

    func summaries() -> [CrashReportSummary] {
        queue.sync {
            pruneLocked(now: Date())
            return loadAllLocked()
                .sorted { $0.createdAt > $1.createdAt }
                .map {
                    CrashReportSummary(
                        reportID: $0.report.reportID,
                        source: $0.report.source,
                        kind: $0.report.diagnostic.kind,
                        occurredAt: $0.report.occurredAt,
                        uploadState: $0.uploadState
                    )
                }
        }
    }

    func storedReport(reportID: String) -> StoredCrashReport? {
        queue.sync {
            loadLocked(reportID: reportID)
        }
    }

    func prettyPrintedReportData(reportID: String) throws -> Data {
        try queue.sync {
            pruneLocked(now: Date())
            guard let stored = loadLocked(reportID: reportID) else {
                throw CrashDiagnosticsStoreError.reportNotFound
            }
            return try CrashDiagnosticsSanitizer.prettyPrintedData(for: stored.report)
        }
    }

    func approve(reportID: String, now: Date = Date()) throws -> CrashUploadRequest {
        try queue.sync {
            pruneLocked(now: now)
            guard var stored = loadLocked(reportID: reportID) else {
                throw CrashDiagnosticsStoreError.reportNotFound
            }
            let canonicalData = try CrashDiagnosticsSanitizer.canonicalData(for: stored.report)
            let consent = CrashReportConsent(
                mode: "per_report",
                approvedAt: CrashDiagnosticsSanitizer.iso8601Minute(now),
                reviewedPayloadSHA256: CrashDiagnosticsSanitizer.sha256Hex(canonicalData)
            )
            stored.uploadState = .approved
            stored.consent = consent
            stored.uploadAttempts = 0
            stored.nextRetryAt = now
            try writeLocked(stored)
            return CrashUploadRequest(report: stored.report, consent: consent)
        }
    }

    func verifiedUploadRequest(reportID: String) throws -> CrashUploadRequest {
        try queue.sync {
            pruneLocked(now: Date())
            guard let stored = loadLocked(reportID: reportID),
                  let consent = stored.consent,
                  stored.uploadState == .approved else {
                throw CrashDiagnosticsStoreError.reportNotFound
            }
            let canonicalData = try CrashDiagnosticsSanitizer.canonicalData(for: stored.report)
            guard CrashDiagnosticsSanitizer.sha256Hex(canonicalData) == consent.reviewedPayloadSHA256 else {
                throw CrashDiagnosticsStoreError.consentIntegrityFailure
            }
            return CrashUploadRequest(report: stored.report, consent: consent)
        }
    }

    func approvedReportsDue(now: Date = Date()) -> [String] {
        queue.sync {
            pruneLocked(now: now)
            return loadAllLocked().compactMap { stored in
                guard stored.uploadState == .approved,
                      (stored.nextRetryAt ?? .distantPast) <= now else {
                    return nil
                }
                return stored.report.reportID
            }
        }
    }

    func markUploadFailure(reportID: String, now: Date = Date()) -> Date? {
        queue.sync {
            guard var stored = loadLocked(reportID: reportID) else { return nil }
            stored.uploadAttempts += 1
            let delays: [TimeInterval] = [
                60,
                15 * 60,
                60 * 60,
                6 * 60 * 60,
                24 * 60 * 60,
            ]
            let delay = delays[min(max(stored.uploadAttempts - 1, 0), delays.count - 1)]
            stored.nextRetryAt = now.addingTimeInterval(delay)
            try? writeLocked(stored)
            return stored.nextRetryAt
        }
    }

    func markUploadRejected(reportID: String) {
        queue.sync {
            guard var stored = loadLocked(reportID: reportID) else { return }
            stored.uploadState = .rejected
            stored.nextRetryAt = nil
            try? writeLocked(stored)
        }
    }

    func delete(reportID: String) {
        queue.sync {
            try? fileManager.removeItem(at: reportURL(reportID: reportID))
        }
    }

    func deleteAll() {
        queue.sync {
            for url in reportFileURLsLocked() {
                try? fileManager.removeItem(at: url)
            }
        }
    }

    private func configureDirectoryLocked() {
        try? fileManager.createDirectory(
            at: reportsDirectory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
        )
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var directory = reportsDirectory
        try? directory.setResourceValues(resourceValues)
        try? fileManager.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: reportsDirectory.path
        )
    }

    private func writeLocked(_ report: StoredCrashReport) throws {
        let data = try CrashDiagnosticsJSON.encoder().encode(report)
        let target = reportURL(reportID: report.report.reportID)
        try data.write(to: target, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    private func loadLocked(reportID: String) -> StoredCrashReport? {
        let url = reportURL(reportID: reportID)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? CrashDiagnosticsJSON.decoder().decode(StoredCrashReport.self, from: data)
    }

    private func loadAllLocked() -> [StoredCrashReport] {
        reportFileURLsLocked().compactMap { url in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? CrashDiagnosticsJSON.decoder().decode(StoredCrashReport.self, from: data)
        }
    }

    private func reportFileURLsLocked() -> [URL] {
        (try? fileManager.contentsOfDirectory(
            at: reportsDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ))?.filter { $0.pathExtension == "json" } ?? []
    }

    private func pruneLocked(now: Date) {
        var reports = loadAllLocked()
        for report in reports where now.timeIntervalSince(report.createdAt) > Self.maximumAge {
            try? fileManager.removeItem(at: reportURL(reportID: report.report.reportID))
        }

        reports = loadAllLocked().sorted(by: retentionPriority)
        if reports.count > Self.maximumReportCount {
            for report in reports.dropFirst(Self.maximumReportCount) {
                try? fileManager.removeItem(at: reportURL(reportID: report.report.reportID))
            }
        }

        reports = loadAllLocked().sorted(by: retentionPriority)
        var retainedBytes = 0
        for report in reports {
            let url = reportURL(reportID: report.report.reportID)
            let bytes = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            if retainedBytes + bytes > Self.maximumTotalBytes {
                try? fileManager.removeItem(at: url)
            } else {
                retainedBytes += bytes
            }
        }
    }

    private func reportURL(reportID: String) -> URL {
        reportsDirectory.appendingPathComponent(reportID).appendingPathExtension("json")
    }

    private func isLikelyDuplicate(
        _ first: CrashReportEnvelope,
        _ second: CrashReportEnvelope
    ) -> Bool {
        guard first.app.build == second.app.build,
              diagnosticFamily(first.diagnostic.kind) == diagnosticFamily(second.diagnostic.kind),
              first.diagnostic.component == second.diagnostic.component,
              first.diagnostic.errorCode == second.diagnostic.errorCode,
              topFrameSignature(first.diagnostic.threads) == topFrameSignature(second.diagnostic.threads) else {
            return false
        }
        let formatter = ISO8601DateFormatter()
        guard let firstDate = formatter.date(from: first.occurredAt),
              let secondDate = formatter.date(from: second.occurredAt) else {
            return first.occurredAt == second.occurredAt
        }
        let isCrossSourceFatal = first.source != second.source
            && diagnosticFamily(first.diagnostic.kind) == "fatal"
        let tolerance: TimeInterval = isCrossSourceFatal ? 24 * 60 * 60 : 5 * 60
        return abs(firstDate.timeIntervalSince(secondDate)) <= tolerance
    }

    private func diagnosticFamily(_ kind: CrashDiagnosticKind) -> String {
        switch kind {
        case .machException, .signal, .cppException, .objectiveCException,
             .memoryTermination, .crash, .unknown:
            return "fatal"
        default:
            return kind.rawValue
        }
    }

    private func topFrameSignature(_ threads: [CrashThread]) -> [String] {
        let frames = threads.first(where: { $0.crashed })?.frames
            ?? threads.first?.frames
            ?? []
        return frames.prefix(8).map {
            "\($0.binaryName ?? "unknown")@\($0.binaryOffset ?? $0.instructionAddress ?? 0)"
        }
    }

    private func retentionPriority(_ lhs: StoredCrashReport, _ rhs: StoredCrashReport) -> Bool {
        let lhsFatal = lhs.report.source != .nonFatal
        let rhsFatal = rhs.report.source != .nonFatal
        if lhsFatal != rhsFatal {
            return lhsFatal
        }
        return lhs.createdAt > rhs.createdAt
    }
}
