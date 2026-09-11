//
//  OACrashReportRepository.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

enum OACrashReportRepositoryError: LocalizedError, Equatable {
    case emptyReport

    var errorDescription: String? {
        switch self {
        case .emptyReport:
            return "Crash diagnostic is empty."
        }
    }
}

/// File-backed storage for MetricKit crash diagnostics.
///
/// The caller is responsible for serializing access to an instance. Keeping the
/// repository independent of MetricKit makes all persistence behavior unit testable.
final class OACrashReportRepository {
    static let defaultRetentionLimit = 5

    private static let filePrefix = "osmand-crash-"
    private static let fileExtension = "json"

    let directoryURL: URL
    let retentionLimit: Int

    private let fileManager: FileManager
    private let filenameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmssSSS'Z'"
        formatter.isLenient = false
        return formatter
    }()

    init(
        directoryURL: URL,
        retentionLimit: Int = OACrashReportRepository.defaultRetentionLimit,
        fileManager: FileManager = .default
    ) {
        precondition(retentionLimit > 0, "Crash report retention limit must be positive.")
        self.directoryURL = directoryURL
        self.retentionLimit = retentionLimit
        self.fileManager = fileManager
    }

    @discardableResult
    func save(_ data: Data, receivedAt date: Date = Date()) throws -> URL {
        guard !data.isEmpty else {
            throw OACrashReportRepositoryError.emptyReport
        }

        // MetricKit promises JSON, but rejecting malformed input prevents a broken
        // report from occupying one of the five retained slots.
        _ = try JSONSerialization.jsonObject(with: data)

        try prepareDirectory()

        let timestamp = filenameDateFormatter.string(from: date)
        let filename = "\(Self.filePrefix)\(timestamp)-\(UUID().uuidString.lowercased()).\(Self.fileExtension)"
        let destinationURL = directoryURL.appendingPathComponent(filename, isDirectory: false)

        do {
            try data.write(to: destinationURL, options: .atomic)
            try fileManager.setAttributes(
                [
                    .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication,
                    .modificationDate: date
                ],
                ofItemAtPath: destinationURL.path
            )
        } catch {
            // Do not leave a partially configured report visible to the share UI.
            try? fileManager.removeItem(at: destinationURL)
            throw error
        }

        do {
            _ = try latestReportURLsPruningIfNeeded()
        } catch {
            // The report itself is already valid and fully protected. Preserve it
            // when maintenance fails so a transient directory error does not lose
            // the diagnostic that was just delivered.
            Self.logMaintenanceFailure("apply crash-report retention", error: error)
        }
        return destinationURL
    }

    /// Returns readable, non-empty JSON reports newest first and removes valid
    /// reports beyond the configured retention limit.
    func latestReportURLsPruningIfNeeded() throws -> [URL] {
        guard fileManager.fileExists(atPath: directoryURL.path) else {
            return []
        }

        let resourceKeys: Set<URLResourceKey> = [
            .contentModificationDateKey,
            .fileSizeKey,
            .isRegularFileKey
        ]
        let contents = try fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [.skipsHiddenFiles]
        )

        let reports = contents.compactMap { url -> StoredReport? in
            guard isCrashReportFilename(url.lastPathComponent),
                  fileManager.isReadableFile(atPath: url.path),
                  let values = try? url.resourceValues(forKeys: resourceKeys),
                  values.isRegularFile == true,
                  let fileSize = values.fileSize,
                  fileSize > 0,
                  let data = try? Data(contentsOf: url, options: .mappedIfSafe),
                  (try? JSONSerialization.jsonObject(with: data)) != nil else {
                return nil
            }

            return StoredReport(
                url: url,
                modificationDate: values.contentModificationDate ?? .distantPast
            )
        }
        .sorted {
            if $0.modificationDate != $1.modificationDate {
                return $0.modificationDate > $1.modificationDate
            }
            return $0.url.lastPathComponent > $1.url.lastPathComponent
        }

        if reports.count > retentionLimit {
            for report in reports.dropFirst(retentionLimit) {
                do {
                    try fileManager.removeItem(at: report.url)
                } catch {
                    // A single undeletable old file must not hide the valid reports
                    // that can still be shared. Retry it during the next refresh.
                    Self.logMaintenanceFailure(
                        "remove old crash report \(report.url.lastPathComponent)",
                        error: error
                    )
                }
            }
        }

        return reports.prefix(retentionLimit).map(\.url)
    }

    private func prepareDirectory() throws {
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

    private func isCrashReportFilename(_ filename: String) -> Bool {
        guard filename.hasPrefix(Self.filePrefix),
              URL(fileURLWithPath: filename).pathExtension.lowercased() == Self.fileExtension else {
            return false
        }

        let nameWithoutExtension = URL(fileURLWithPath: filename)
            .deletingPathExtension()
            .lastPathComponent
        let reportIdentifier = nameWithoutExtension.dropFirst(Self.filePrefix.count)
        let expectedTimestampLength = 19
        guard reportIdentifier.count == expectedTimestampLength + 1 + 36 else {
            return false
        }

        let separatorIndex = reportIdentifier.index(
            reportIdentifier.startIndex,
            offsetBy: expectedTimestampLength
        )
        guard reportIdentifier[separatorIndex] == "-" else { return false }

        let timestamp = String(reportIdentifier[..<separatorIndex])
        let uuidStartIndex = reportIdentifier.index(after: separatorIndex)
        let uuid = String(reportIdentifier[uuidStartIndex...])
        return filenameDateFormatter.date(from: timestamp) != nil
            && UUID(uuidString: uuid) != nil
    }

    private static func logMaintenanceFailure(_ operation: String, error: Error) {
        NSLog("[CrashDiagnostics] Failed to %@: %@", operation, error.localizedDescription)
    }
}

private extension OACrashReportRepository {
    struct StoredReport {
        let url: URL
        let modificationDate: Date
    }
}
