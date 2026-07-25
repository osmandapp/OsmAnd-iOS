//
//  CrashDiagnosticsSanitizer.swift
//  OsmAnd Maps
//

import CryptoKit
import Foundation
import UIKit

enum CrashDiagnosticsSanitizer {
    private static let maximumThreads = 64
    private static let maximumFramesPerThread = 128
    private static let maximumTotalKSCrashFrames = 1_024
    private static let maximumBinaryImages = 512
    private static let maximumMetricKitFrames = 512
    private static let allowedNumericMetadataKeys: Set<String> = [
        "attempt_count",
        "bytes",
        "duration_ms",
        "item_count",
        "retry_count",
        "status_code",
    ]
    private static let allowedBreadcrumbEvents: Set<String> = [
        "app_launched",
        "app_became_active",
        "app_entered_background",
        "screen_changed",
        "navigation_started",
        "navigation_stopped",
        "route_calculation_started",
        "route_calculation_finished",
        "profile_changed",
        "plugin_changed",
        "map_source_changed",
        "memory_warning",
    ]

    static func normalizeKSCrashReport(
        _ rawReport: [String: Any],
        session: CrashSessionState
    ) -> CrashReportEnvelope? {
        let report = dictionary(rawReport["report"])
        let system = dictionary(rawReport["system"])
        let crash = dictionary(rawReport["crash"])
        let error = dictionary(crash["error"])

        let kind = kscrashKind(error["type"] as? String)
        let occurredAt = sanitizedTimestamp(report["timestamp"] as? String)
        let app = CrashAppInfo(
            version: safeIdentifier(system["CFBundleShortVersionString"] as? String, fallback: currentAppVersion()),
            build: safeIdentifier(system["CFBundleVersion"] as? String, fallback: currentAppBuild())
        )
        let device = CrashDeviceInfo(
            model: safeHardwareModel(system["machine"] as? String) ?? currentDeviceModel(),
            osVersion: safeIdentifier(system["system_version"] as? String, fallback: ProcessInfo.processInfo.operatingSystemVersionString)
        )

        let mach = dictionary(error["mach"])
        let signal = dictionary(error["signal"])
        let nsException = dictionary(error["nsexception"])
        let cppException = dictionary(error["cpp_exception"])
        let threads = normalizeKSCrashThreads(array(crash["threads"]))
        let crashedThread = threads.first(where: { $0.crashed })?.index
        let images = normalizeKSCrashImages(array(rawReport["binary_images"]))
        let exceptionName = safeCodeIdentifier(
            (nsException["name"] as? String)
                ?? (cppException["name"] as? String)
                ?? (mach["exception_name"] as? String)
        )

        let diagnostic = CrashDiagnostic(
            kind: kind,
            exceptionName: exceptionName,
            exceptionType: uint64(mach["exception"]),
            exceptionCode: uint64(mach["code"]),
            signal: integer(signal["signal"]),
            signalName: safeCodeIdentifier(signal["name"] as? String),
            terminationReason: nil,
            crashedThread: crashedThread,
            hangDurationMilliseconds: nil,
            cpuTimeMilliseconds: nil,
            sampledTimeMilliseconds: nil,
            diskWritesBytes: nil,
            component: nil,
            errorCode: nil,
            severity: nil,
            numericMetadata: nil,
            threads: threads,
            binaryImages: images
        )

        return makeEnvelope(
            source: .kscrash,
            occurredAt: occurredAt,
            app: app,
            device: device,
            diagnostic: diagnostic,
            context: sanitizeContext(session.context),
            breadcrumbs: sanitizeBreadcrumbs(session.breadcrumbs)
        )
    }

    static func makeMetricKitEnvelope(
        kind: CrashDiagnosticKind,
        occurredAt: Date,
        appVersion: String,
        appBuild: String,
        deviceModel: String,
        osVersion: String,
        exceptionType: NSNumber? = nil,
        exceptionCode: NSNumber? = nil,
        signal: NSNumber? = nil,
        terminationReason: String? = nil,
        hangDurationMilliseconds: Int64? = nil,
        cpuTimeMilliseconds: Int64? = nil,
        sampledTimeMilliseconds: Int64? = nil,
        diskWritesBytes: Int64? = nil,
        callStackTreeData: Data?
    ) -> CrashReportEnvelope {
        let frames = normalizeMetricKitFrames(callStackTreeData)
        let diagnostic = CrashDiagnostic(
            kind: kind,
            exceptionName: nil,
            exceptionType: exceptionType?.uint64Value,
            exceptionCode: exceptionCode?.uint64Value,
            signal: signal?.intValue,
            signalName: nil,
            terminationReason: safeTerminationReason(terminationReason),
            crashedThread: frames.isEmpty ? nil : 0,
            hangDurationMilliseconds: boundedNonNegative(hangDurationMilliseconds),
            cpuTimeMilliseconds: boundedNonNegative(cpuTimeMilliseconds),
            sampledTimeMilliseconds: boundedNonNegative(sampledTimeMilliseconds),
            diskWritesBytes: boundedNonNegative(diskWritesBytes),
            component: nil,
            errorCode: nil,
            severity: nil,
            numericMetadata: nil,
            threads: frames.isEmpty ? [] : [CrashThread(index: 0, crashed: kind == .crash, frames: frames)],
            binaryImages: metricKitImages(from: frames)
        )

        return makeEnvelope(
            source: .metricKit,
            occurredAt: iso8601Minute(occurredAt),
            app: CrashAppInfo(
                version: safeIdentifier(appVersion, fallback: currentAppVersion()),
                build: safeIdentifier(appBuild, fallback: currentAppBuild())
            ),
            device: CrashDeviceInfo(
                model: safeHardwareModel(deviceModel) ?? currentDeviceModel(),
                osVersion: safeIdentifier(osVersion, fallback: ProcessInfo.processInfo.operatingSystemVersionString)
            ),
            diagnostic: diagnostic,
            context: CrashContextSnapshot(),
            breadcrumbs: []
        )
    }

    static func makeNonFatalEnvelope(
        _ event: CrashNonFatalEvent,
        session: CrashSessionState
    ) -> CrashReportEnvelope {
        let numericMetadata = sanitizeNumericMetadata(event.numericMetadata)
        let diagnostic = CrashDiagnostic(
            kind: .nonFatal,
            exceptionName: nil,
            exceptionType: nil,
            exceptionCode: nil,
            signal: nil,
            signalName: nil,
            terminationReason: nil,
            crashedThread: nil,
            hangDurationMilliseconds: nil,
            cpuTimeMilliseconds: nil,
            sampledTimeMilliseconds: nil,
            diskWritesBytes: nil,
            component: event.component.rawValue,
            errorCode: min(max(event.code, -1_000_000), 1_000_000),
            severity: event.severity.rawValue,
            numericMetadata: numericMetadata.isEmpty ? nil : numericMetadata,
            threads: [],
            binaryImages: []
        )

        return makeEnvelope(
            source: .nonFatal,
            occurredAt: iso8601Minute(Date()),
            app: CrashAppInfo(version: currentAppVersion(), build: currentAppBuild()),
            device: CrashDeviceInfo(model: currentDeviceModel(), osVersion: currentOSVersion()),
            diagnostic: diagnostic,
            context: sanitizeContext(session.context),
            breadcrumbs: sanitizeBreadcrumbs(session.breadcrumbs)
        )
    }

    static func sanitizeContext(_ context: CrashContextSnapshot) -> CrashContextSnapshot {
        var result = context
        result.screenIdentifier = safeScreenIdentifier(context.screenIdentifier)
        result.routeCalculationState = allowedValue(
            context.routeCalculationState,
            allowed: ["idle", "calculating", "calculated", "failed"]
        )
        result.profileFamily = allowedValue(
            context.profileFamily,
            allowed: ["default", "car", "bicycle", "pedestrian", "aircraft", "truck", "motorcycle", "moped", "boat", "public_transport", "train", "ski", "horse", "custom", "unknown"]
        )
        result.zoomBucket = context.zoomBucket.map { min(max($0, 0), 24) }
        result.mapSourceCategory = allowedValue(
            context.mapSourceCategory,
            allowed: ["offline_vector", "offline_raster", "online_raster", "unknown"]
        )
        result.loadedMapCount = min(max(context.loadedMapCount, 0), 1_000)
        result.builtInPluginIDs = Array(
            Set(context.builtInPluginIDs.compactMap(safeIdentifier))
        ).sorted().prefix(32).map { $0 }
        result.customPluginCount = min(max(context.customPluginCount, 0), 100)
        result.applicationState = allowedValue(
            context.applicationState,
            allowed: ["active", "inactive", "background", "unknown"]
        )
        result.memoryAvailableBucketMB = sanitizeResourceBucket(context.memoryAvailableBucketMB)
        result.diskAvailableBucketMB = sanitizeResourceBucket(context.diskAvailableBucketMB)
        return result
    }

    static func sanitizeBreadcrumbs(_ breadcrumbs: [CrashBreadcrumb]) -> [CrashBreadcrumb] {
        Array(breadcrumbs.suffix(100)).compactMap { breadcrumb in
            guard allowedBreadcrumbEvents.contains(breadcrumb.event) else { return nil }
            let metadata = sanitizeNumericMetadata(breadcrumb.numericMetadata ?? [:])
            return CrashBreadcrumb(
                elapsedMilliseconds: min(max(breadcrumb.elapsedMilliseconds, 0), 7 * 24 * 60 * 60 * 1_000),
                event: breadcrumb.event,
                numericMetadata: metadata.isEmpty ? nil : metadata,
                screenIdentifier: safeScreenIdentifier(breadcrumb.screenIdentifier)
            )
        }
    }

    static func canonicalData(for report: CrashReportEnvelope) throws -> Data {
        try CrashDiagnosticsJSON.encoder().encode(report)
    }

    static func prettyPrintedData(for report: CrashReportEnvelope) throws -> Data {
        try CrashDiagnosticsJSON.encoder(prettyPrinted: true).encode(report)
    }

    static func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func makeEnvelope(
        source: CrashReportSource,
        occurredAt: String,
        app: CrashAppInfo,
        device: CrashDeviceInfo,
        diagnostic: CrashDiagnostic,
        context: CrashContextSnapshot,
        breadcrumbs: [CrashBreadcrumb]
    ) -> CrashReportEnvelope {
        let reportID = UUID().uuidString.lowercased()
        return CrashReportEnvelope(
            schemaVersion: CrashReportEnvelope.currentSchemaVersion,
            reportID: reportID,
            source: source,
            occurredAt: occurredAt,
            app: app,
            device: device,
            diagnostic: diagnostic,
            context: context,
            breadcrumbs: breadcrumbs
        )
    }

    private static func normalizeKSCrashThreads(_ rawThreads: [Any]) -> [CrashThread] {
        var remainingFrames = maximumTotalKSCrashFrames
        var threads: [CrashThread] = []
        for (offset, rawThread) in rawThreads.prefix(maximumThreads).enumerated() {
            let thread = dictionary(rawThread)
            guard !thread.isEmpty else { continue }
            let backtrace = dictionary(thread["backtrace"])
            let frameLimit = min(maximumFramesPerThread, remainingFrames)
            let frames = array(backtrace["contents"])
                .prefix(frameLimit)
                .compactMap(normalizeKSCrashFrame)
            threads.append(
                CrashThread(
                    index: integer(thread["index"]) ?? offset,
                    crashed: boolean(thread["crashed"]),
                    frames: frames
                )
            )
            remainingFrames -= frames.count
            if remainingFrames == 0 {
                break
            }
        }
        return threads
    }

    private static func normalizeKSCrashFrame(_ rawFrame: Any) -> CrashStackFrame? {
        let frame = dictionary(rawFrame)
        guard !frame.isEmpty else { return nil }
        let instructionAddress = uint64(frame["instruction_addr"])
        let binaryAddress = uint64(frame["object_addr"])
        let binaryOffset: UInt64?
        if let instructionAddress, let binaryAddress, instructionAddress >= binaryAddress {
            binaryOffset = instructionAddress - binaryAddress
        } else {
            binaryOffset = nil
        }
        let binaryName = safeBasename(frame["object_name"] as? String)
        let symbolAddress = uint64(frame["symbol_addr"])
        let symbolName = safeSymbol(frame["symbol_name"] as? String)
        guard instructionAddress != nil
                || binaryAddress != nil
                || binaryName != nil
                || symbolAddress != nil
                || symbolName != nil else {
            return nil
        }
        return CrashStackFrame(
            instructionAddress: instructionAddress,
            binaryAddress: binaryAddress,
            binaryOffset: binaryOffset,
            binaryName: binaryName,
            binaryUUID: nil,
            symbolAddress: symbolAddress,
            symbolName: symbolName
        )
    }

    private static func normalizeKSCrashImages(_ rawImages: [Any]) -> [CrashBinaryImage] {
        rawImages.prefix(maximumBinaryImages).compactMap { rawImage in
            let image = dictionary(rawImage)
            guard let name = safeBasename(image["name"] as? String) else { return nil }
            return CrashBinaryImage(
                name: name,
                uuid: safeUUID(image["uuid"] as? String),
                imageAddress: uint64(image["image_addr"])
            )
        }
    }

    private static func normalizeMetricKitFrames(_ data: Data?) -> [CrashStackFrame] {
        guard let data,
              let root = try? JSONSerialization.jsonObject(with: data) else {
            return []
        }
        var frames: [CrashStackFrame] = []
        collectMetricKitFrames(root, into: &frames)
        return Array(frames.prefix(maximumMetricKitFrames))
    }

    private static func collectMetricKitFrames(_ value: Any, into frames: inout [CrashStackFrame]) {
        guard frames.count < maximumMetricKitFrames else { return }
        if let dictionary = value as? [String: Any] {
            let binaryName = (dictionary["binaryName"] as? String)
                ?? (dictionary["binary_name"] as? String)
            let binaryUUID = (dictionary["binaryUUID"] as? String)
                ?? (dictionary["binary_uuid"] as? String)
            let address = uint64(dictionary["address"])
            let offset = uint64(
                dictionary["offsetIntoBinaryTextSegment"]
                    ?? dictionary["offset_into_binary_text_segment"]
            )
            if binaryName != nil || binaryUUID != nil || address != nil || offset != nil {
                frames.append(
                    CrashStackFrame(
                        instructionAddress: address,
                        binaryAddress: nil,
                        binaryOffset: offset,
                        binaryName: safeBasename(binaryName),
                        binaryUUID: safeUUID(binaryUUID),
                        symbolAddress: nil,
                        symbolName: nil
                    )
                )
            }
            for key in dictionary.keys.sorted() {
                collectMetricKitFrames(dictionary[key] as Any, into: &frames)
            }
        } else if let array = value as? [Any] {
            for item in array {
                collectMetricKitFrames(item, into: &frames)
            }
        }
    }

    private static func metricKitImages(from frames: [CrashStackFrame]) -> [CrashBinaryImage] {
        var seen = Set<String>()
        return frames.compactMap { frame in
            guard let name = frame.binaryName else { return nil }
            let key = "\(name)|\(frame.binaryUUID ?? "")"
            guard seen.insert(key).inserted else { return nil }
            return CrashBinaryImage(name: name, uuid: frame.binaryUUID, imageAddress: nil)
        }
    }

    private static func kscrashKind(_ rawType: String?) -> CrashDiagnosticKind {
        switch rawType {
        case "mach": return .machException
        case "signal": return .signal
        case "cpp_exception": return .cppException
        case "nsexception": return .objectiveCException
        case "memory_termination": return .memoryTermination
        default: return .unknown
        }
    }

    private static func safeIdentifier(_ value: String?, fallback: String) -> String {
        safeIdentifier(value) ?? safeIdentifier(fallback) ?? "unknown"
    }

    private static func safeIdentifier(_ value: String?) -> String? {
        guard let value else { return nil }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._-")
        let scalars = value.unicodeScalars.filter { allowed.contains($0) }
        let sanitized = String(String.UnicodeScalarView(scalars)).prefix(128)
        return sanitized.isEmpty ? nil : String(sanitized)
    }

    private static func safeScreenIdentifier(_ value: String?) -> String? {
        guard let identifier = safeIdentifier(value),
              identifier.contains("ViewController")
                || identifier.hasSuffix("Controller")
                || identifier.hasSuffix("Screen")
                || identifier.hasSuffix("Sheet")
                || identifier.hasSuffix("Fragment") else {
            return nil
        }
        return identifier
    }

    private static func safeHardwareModel(_ value: String?) -> String? {
        guard let value else { return nil }
        let allowed = CharacterSet(
            charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789,._-"
        )
        guard value.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return nil }
        return String(value.prefix(64))
    }

    private static func safeSymbol(_ value: String?) -> String? {
        guard let value else { return nil }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.$:+-<>[]() ")
        let scalars = value.unicodeScalars.filter { allowed.contains($0) }
        let sanitized = String(String.UnicodeScalarView(scalars)).prefix(256)
        return sanitized.isEmpty ? nil : String(sanitized)
    }

    private static func safeCodeIdentifier(_ value: String?) -> String? {
        guard let value, !value.isEmpty, value.count <= 128 else { return nil }
        let allowed = CharacterSet(
            charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.$:+-<>[]()"
        )
        guard value.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return nil }
        return value
    }

    private static func safeBasename(_ value: String?) -> String? {
        guard let value else { return nil }
        return safeIdentifier((value as NSString).lastPathComponent)
    }

    private static func safeUUID(_ value: String?) -> String? {
        guard let value else { return nil }
        let compact = value.replacingOccurrences(of: "-", with: "")
        let allowed = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        guard (compact.count == 32 || compact.count == 40),
              compact.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            return nil
        }
        return value.uppercased()
    }

    private static func safeTerminationReason(_ value: String?) -> String? {
        guard let value else { return nil }
        let normalized = value.lowercased()
        if normalized.contains("watchdog") || normalized.contains("8badf00d") {
            return "watchdog"
        }
        if normalized.contains("jetsam") {
            return "jetsam"
        }
        if normalized.contains("memory") {
            return "memory_pressure"
        }
        if normalized.contains("resource") || normalized.contains("cpu") || normalized.contains("disk") {
            return "resource_limit"
        }
        if normalized.contains("signal") {
            return "namespace_signal"
        }
        return "unknown"
    }

    private static func sanitizeNumericMetadata(_ metadata: [String: Int64]) -> [String: Int64] {
        var sanitized: [String: Int64] = [:]
        for key in metadata.keys.sorted().prefix(16) {
            guard allowedNumericMetadataKeys.contains(key),
                  let safeKey = safeIdentifier(key),
                  let value = metadata[key] else {
                continue
            }
            sanitized[safeKey] = min(max(value, -1_000_000_000), 1_000_000_000)
        }
        return sanitized
    }

    private static func sanitizeResourceBucket(_ value: Int?) -> Int? {
        value.map { min(max($0, 0), 1_048_576) }
    }

    private static func allowedValue(_ value: String, allowed: Set<String>) -> String {
        allowed.contains(value) ? value : "unknown"
    }

    private static func boundedNonNegative(_ value: Int64?) -> Int64? {
        value.map { min(max($0, 0), Int64.max / 2) }
    }

    private static func sanitizedTimestamp(_ value: String?) -> String {
        guard let value, let date = ISO8601DateFormatter().date(from: value) else {
            return iso8601Minute(Date())
        }
        return iso8601Minute(date)
    }

    static func iso8601Minute(_ date: Date) -> String {
        let interval = floor(date.timeIntervalSince1970 / 60) * 60
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: Date(timeIntervalSince1970: interval))
    }

    private static func currentAppVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }

    private static func currentAppBuild() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
    }

    private static func currentOSVersion() -> String {
        UIDevice.current.systemVersion
    }

    private static func currentDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let identifier = Mirror(reflecting: systemInfo.machine).children.reduce(into: "") { result, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            result.append(String(UnicodeScalar(UInt8(value))))
        }
        return identifier.isEmpty ? "unknown" : identifier
    }

    private static func dictionary(_ value: Any?) -> [String: Any] {
        value as? [String: Any] ?? [:]
    }

    private static func array(_ value: Any?) -> [Any] {
        value as? [Any] ?? []
    }

    private static func boolean(_ value: Any?) -> Bool {
        (value as? Bool) ?? (value as? NSNumber)?.boolValue ?? false
    }

    private static func integer(_ value: Any?) -> Int? {
        if let number = value as? NSNumber {
            return number.intValue
        }
        if let string = value as? String {
            return Int(string)
        }
        return nil
    }

    private static func uint64(_ value: Any?) -> UInt64? {
        if let number = value as? NSNumber {
            return number.uint64Value
        }
        if let string = value as? String {
            if string.hasPrefix("0x") {
                return UInt64(string.dropFirst(2), radix: 16)
            }
            return UInt64(string)
        }
        return nil
    }
}
