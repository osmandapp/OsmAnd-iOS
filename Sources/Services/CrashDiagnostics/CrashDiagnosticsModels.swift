//
//  CrashDiagnosticsModels.swift
//  OsmAnd Maps
//
//  Privacy-preserving crash diagnostics wire and storage models.
//

import Foundation

enum CrashReportSource: String, Codable {
    case kscrash
    case metricKit = "metrickit"
    case nonFatal = "non_fatal"
}

enum CrashDiagnosticKind: String, Codable {
    case machException = "mach_exception"
    case signal
    case cppException = "cpp_exception"
    case objectiveCException = "objective_c_exception"
    case memoryTermination = "memory_termination"
    case crash
    case hang
    case cpuException = "cpu_exception"
    case diskWriteException = "disk_write_exception"
    case nonFatal = "non_fatal"
    case unknown
}

struct CrashAppInfo: Codable, Equatable {
    let version: String
    let build: String
}

struct CrashDeviceInfo: Codable, Equatable {
    let model: String
    let osVersion: String

    enum CodingKeys: String, CodingKey {
        case model
        case osVersion = "os_version"
    }
}

struct CrashStackFrame: Codable, Equatable {
    let instructionAddress: UInt64?
    let binaryAddress: UInt64?
    let binaryOffset: UInt64?
    let binaryName: String?
    let binaryUUID: String?
    let symbolAddress: UInt64?
    let symbolName: String?

    enum CodingKeys: String, CodingKey {
        case instructionAddress = "instruction_address"
        case binaryAddress = "binary_address"
        case binaryOffset = "binary_offset"
        case binaryName = "binary_name"
        case binaryUUID = "binary_uuid"
        case symbolAddress = "symbol_address"
        case symbolName = "symbol_name"
    }
}

struct CrashThread: Codable, Equatable {
    let index: Int
    let crashed: Bool
    let frames: [CrashStackFrame]
}

struct CrashBinaryImage: Codable, Equatable {
    let name: String
    let uuid: String?
    let imageAddress: UInt64?

    enum CodingKeys: String, CodingKey {
        case name
        case uuid
        case imageAddress = "image_address"
    }
}

struct CrashDiagnostic: Codable, Equatable {
    let kind: CrashDiagnosticKind
    let exceptionName: String?
    let exceptionType: UInt64?
    let exceptionCode: UInt64?
    let signal: Int?
    let signalName: String?
    let terminationReason: String?
    let crashedThread: Int?
    let hangDurationMilliseconds: Int64?
    let cpuTimeMilliseconds: Int64?
    let sampledTimeMilliseconds: Int64?
    let diskWritesBytes: Int64?
    let component: String?
    let errorCode: Int?
    let severity: String?
    let numericMetadata: [String: Int64]?
    let threads: [CrashThread]
    let binaryImages: [CrashBinaryImage]

    enum CodingKeys: String, CodingKey {
        case kind
        case exceptionName = "exception_name"
        case exceptionType = "exception_type"
        case exceptionCode = "exception_code"
        case signal
        case signalName = "signal_name"
        case terminationReason = "termination_reason"
        case crashedThread = "crashed_thread"
        case hangDurationMilliseconds = "hang_duration_ms"
        case cpuTimeMilliseconds = "cpu_time_ms"
        case sampledTimeMilliseconds = "sampled_time_ms"
        case diskWritesBytes = "disk_writes_bytes"
        case component
        case errorCode = "error_code"
        case severity
        case numericMetadata = "numeric_metadata"
        case threads
        case binaryImages = "binary_images"
    }
}

struct CrashContextSnapshot: Codable, Equatable {
    var screenIdentifier: String?
    var navigationActive = false
    var routeCalculationState = "idle"
    var profileFamily = "unknown"
    var zoomBucket: Int?
    var mapSourceCategory = "unknown"
    var loadedMapCount = 0
    var builtInPluginIDs: [String] = []
    var customPluginCount = 0
    var applicationState = "unknown"
    var memoryAvailableBucketMB: Int?
    var diskAvailableBucketMB: Int?

    enum CodingKeys: String, CodingKey {
        case screenIdentifier = "screen_identifier"
        case navigationActive = "navigation_active"
        case routeCalculationState = "route_calculation_state"
        case profileFamily = "profile_family"
        case zoomBucket = "zoom_bucket"
        case mapSourceCategory = "map_source_category"
        case loadedMapCount = "loaded_map_count"
        case builtInPluginIDs = "built_in_plugin_ids"
        case customPluginCount = "custom_plugin_count"
        case applicationState = "application_state"
        case memoryAvailableBucketMB = "memory_available_bucket_mb"
        case diskAvailableBucketMB = "disk_available_bucket_mb"
    }
}

struct CrashBreadcrumb: Codable, Equatable {
    let elapsedMilliseconds: Int64
    let event: String
    let numericMetadata: [String: Int64]?
    let screenIdentifier: String?

    init(
        elapsedMilliseconds: Int64,
        event: String,
        numericMetadata: [String: Int64]?,
        screenIdentifier: String? = nil
    ) {
        self.elapsedMilliseconds = elapsedMilliseconds
        self.event = event
        self.numericMetadata = numericMetadata
        self.screenIdentifier = screenIdentifier
    }

    enum CodingKeys: String, CodingKey {
        case elapsedMilliseconds = "elapsed_ms"
        case event
        case numericMetadata = "numeric_metadata"
        case screenIdentifier = "screen_identifier"
    }
}

struct CrashReportEnvelope: Codable, Equatable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let reportID: String
    let source: CrashReportSource
    let occurredAt: String
    let app: CrashAppInfo
    let device: CrashDeviceInfo
    let diagnostic: CrashDiagnostic
    let context: CrashContextSnapshot
    let breadcrumbs: [CrashBreadcrumb]

    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case reportID = "report_id"
        case source
        case occurredAt = "occurred_at"
        case app
        case device
        case diagnostic
        case context
        case breadcrumbs
    }
}

struct CrashReportConsent: Codable, Equatable {
    let mode: String
    let approvedAt: String
    let reviewedPayloadSHA256: String

    enum CodingKeys: String, CodingKey {
        case mode
        case approvedAt = "approved_at"
        case reviewedPayloadSHA256 = "reviewed_payload_sha256"
    }
}

struct CrashUploadRequest: Codable, Equatable {
    let report: CrashReportEnvelope
    let consent: CrashReportConsent
}

enum CrashUploadState: String, Codable {
    case pending
    case approved
    case rejected
}

struct StoredCrashReport: Codable, Equatable {
    var report: CrashReportEnvelope
    var uploadState: CrashUploadState
    var consent: CrashReportConsent?
    var createdAt: Date
    var uploadAttempts: Int
    var nextRetryAt: Date?

    enum CodingKeys: String, CodingKey {
        case report
        case uploadState = "upload_state"
        case consent
        case createdAt = "created_at"
        case uploadAttempts = "upload_attempts"
        case nextRetryAt = "next_retry_at"
    }
}

struct CrashReportSummary: Equatable {
    let reportID: String
    let source: CrashReportSource
    let kind: CrashDiagnosticKind
    let occurredAt: String
    let uploadState: CrashUploadState
}

struct CrashSessionState: Codable, Equatable {
    var context: CrashContextSnapshot
    var breadcrumbs: [CrashBreadcrumb]
}

enum CrashNonFatalComponent: String {
    case appStartup = "app_startup"
    case mapRendering = "map_rendering"
    case navigation
    case resources
    case networking
    case storage
    case unknown
}

enum CrashNonFatalSeverity: String {
    case warning
    case error
}

struct CrashNonFatalEvent {
    let component: CrashNonFatalComponent
    let code: Int
    let severity: CrashNonFatalSeverity
    let numericMetadata: [String: Int64]
}

@objc enum CrashBreadcrumbEvent: Int {
    case appLaunched
    case appBecameActive
    case appEnteredBackground
    case screenChanged
    case navigationStarted
    case navigationStopped
    case routeCalculationStarted
    case routeCalculationFinished
    case profileChanged
    case pluginChanged
    case mapSourceChanged
    case memoryWarning

    var wireName: String {
        switch self {
        case .appLaunched: return "app_launched"
        case .appBecameActive: return "app_became_active"
        case .appEnteredBackground: return "app_entered_background"
        case .screenChanged: return "screen_changed"
        case .navigationStarted: return "navigation_started"
        case .navigationStopped: return "navigation_stopped"
        case .routeCalculationStarted: return "route_calculation_started"
        case .routeCalculationFinished: return "route_calculation_finished"
        case .profileChanged: return "profile_changed"
        case .pluginChanged: return "plugin_changed"
        case .mapSourceChanged: return "map_source_changed"
        case .memoryWarning: return "memory_warning"
        }
    }
}

enum CrashDiagnosticsJSON {
    static func encoder(prettyPrinted: Bool = false) -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = prettyPrinted ? [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes] : [.sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
