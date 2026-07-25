//
//  CrashDiagnosticsTests.swift
//  OsmAnd MapsTests
//

import XCTest

final class CrashDiagnosticsTests: XCTestCase {
    func testKSCrashNormalizationDropsSensitiveRawFields() throws {
        let rawReport: [String: Any] = [
            "report": [
                "timestamp": "2026-07-24T12:00:12Z",
                "process_name": "OsmAnd Maps",
            ],
            "system": [
                "CFBundleShortVersionString": "5.2.0",
                "CFBundleVersion": "5200",
                "machine": "iPhone16,2",
                "system_version": "18.5",
                "device_app_hash": "persistent-installation-secret",
                "process_path": "/private/var/containers/OsmAnd Maps",
            ],
            "crash": [
                "error": [
                    "type": "signal",
                    "reason": "Search query: private cafe",
                    "signal": ["signal": 6, "name": "SIGABRT"],
                ],
                "threads": [
                    [
                        "index": 0,
                        "crashed": true,
                        "registers": ["basic": ["x0": 123]],
                        "stack": ["contents": "private stack memory"],
                        "backtrace": [
                            "contents": [
                                [
                                    "instruction_addr": 4_096,
                                    "object_addr": 2_048,
                                    "object_name": "/private/var/containers/Bundle/Application/OsmAnd",
                                    "symbol_name": "OAAppDelegate.applicationDidBecomeActive()",
                                ],
                            ],
                        ],
                    ],
                ],
            ],
            "binary_images": [
                [
                    "name": "/private/var/containers/Bundle/Application/OsmAnd",
                    "uuid": "00112233445566778899AABBCCDDEEFF",
                    "image_addr": 2_048,
                    "image_size": 8_192,
                ],
            ],
            "console_log": "favorite Home; latitude 51.5; https://private.example",
            "user": [
                "notification_contents": "private message",
                "custom_plugin_name": "Home automation",
                "map_region_id": "london",
                "route": "Home to Work",
                "file_path": "/private/var/mobile/Documents/private.gpx",
                "account_email": "person@example.com",
            ],
        ]
        let session = CrashSessionState(
            context: CrashContextSnapshot(),
            breadcrumbs: [
                CrashBreadcrumb(
                    elapsedMilliseconds: 1_000,
                    event: "app_became_active",
                    numericMetadata: ["latitude": 51_500_000, "item_count": 2]
                ),
            ]
        )

        let report = try XCTUnwrap(
            CrashDiagnosticsSanitizer.normalizeKSCrashReport(rawReport, session: session)
        )
        let data = try CrashDiagnosticsSanitizer.prettyPrintedData(for: report)
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertTrue(json.contains("\"binary_name\" : \"OsmAnd\""))
        XCTAssertTrue(json.contains("\"item_count\" : 2"))
        for prohibited in [
            "private cafe",
            "private stack memory",
            "persistent-installation-secret",
            "notification_contents",
            "custom_plugin_name",
            "map_region_id",
            "Home to Work",
            "person@example.com",
            "latitude",
            "https://",
            "/private/",
            "console_log",
            "registers",
        ] {
            XCTAssertFalse(json.localizedCaseInsensitiveContains(prohibited), prohibited)
        }
    }

    func testNonFatalOnlyAllowsEnumeratedNumericMetadata() throws {
        let event = CrashNonFatalEvent(
            component: .networking,
            code: 42,
            severity: .warning,
            numericMetadata: [
                "status_code": 503,
                "latitude": 51_500_000,
                "search_query_hash": 123,
            ]
        )
        let report = CrashDiagnosticsSanitizer.makeNonFatalEnvelope(
            event,
            session: CrashSessionState(context: CrashContextSnapshot(), breadcrumbs: [])
        )

        XCTAssertEqual(report.diagnostic.numericMetadata, ["status_code": 503])
    }

    func testApprovalHashesExactlyTheReviewedEnvelope() throws {
        let baseDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: baseDirectory) }
        let store = CrashDiagnosticsStore(baseDirectory: baseDirectory)
        let report = sampleEnvelope()

        XCTAssertTrue(try store.save(report))
        let reviewedData = try store.prettyPrintedReportData(reportID: report.reportID)
        XCTAssertFalse(reviewedData.isEmpty)
        let request = try store.approve(reportID: report.reportID)
        let verified = try store.verifiedUploadRequest(reportID: report.reportID)
        let canonicalData = try CrashDiagnosticsSanitizer.canonicalData(for: report)

        XCTAssertEqual(request, verified)
        XCTAssertEqual(
            request.consent.reviewedPayloadSHA256,
            CrashDiagnosticsSanitizer.sha256Hex(canonicalData)
        )
        XCTAssertEqual(request.consent.mode, "per_report")
    }

    func testMetricKitFixtureUsesTheSamePrivacyAllowlistAndDeduplicatesFatalReport() throws {
        let fixtureURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/metrickit_call_stack.json")
        let fixtureData = try Data(contentsOf: fixtureURL)
        let metricKitReport = CrashDiagnosticsSanitizer.makeMetricKitEnvelope(
            kind: .crash,
            occurredAt: try XCTUnwrap(
                ISO8601DateFormatter().date(from: "2026-07-24T12:00:00Z")
            ),
            appVersion: "5.2.0",
            appBuild: "5200",
            deviceModel: "iPhone16,2",
            osVersion: "18.5",
            signal: 6,
            callStackTreeData: fixtureData
        )
        let serialized = try CrashDiagnosticsSanitizer.prettyPrintedData(for: metricKitReport)
        let json = try XCTUnwrap(String(data: serialized, encoding: .utf8))

        XCTAssertTrue(json.contains("\"binary_name\" : \"OsmAnd\""))
        XCTAssertFalse(json.contains("private.example"))
        XCTAssertFalse(json.contains("private cafe"))
        XCTAssertFalse(json.contains("/private/"))

        let baseDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: baseDirectory) }
        let store = CrashDiagnosticsStore(baseDirectory: baseDirectory)
        XCTAssertTrue(try store.save(sampleEnvelope()))
        XCTAssertFalse(try store.save(metricKitReport))
    }

    func testFatalReportsTakeRetentionPriorityOverNonFatalReports() throws {
        let baseDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: baseDirectory) }
        let store = CrashDiagnosticsStore(baseDirectory: baseDirectory)
        let fatalA = sampleEnvelope()
        let fatalB = copy(
            fatalA,
            reportID: UUID().uuidString.lowercased(),
            occurredAt: "2026-07-24T12:10:00Z"
        )
        let nonFatalA = nonFatalEnvelope(errorCode: 7)
        let nonFatalB = nonFatalEnvelope(errorCode: 8)
        let now = Date()

        XCTAssertTrue(try store.save(fatalA, now: now))
        XCTAssertTrue(try store.save(fatalB, now: now.addingTimeInterval(1)))
        XCTAssertTrue(try store.save(nonFatalA, now: now.addingTimeInterval(2)))
        XCTAssertTrue(try store.save(nonFatalB, now: now.addingTimeInterval(3)))

        let summaries = store.summaries()
        XCTAssertEqual(summaries.count, CrashDiagnosticsStore.maximumReportCount)
        XCTAssertEqual(summaries.filter { $0.source == .kscrash }.count, 2)
    }

    func testReportsExpireAfterSevenDays() throws {
        let baseDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: baseDirectory) }
        let store = CrashDiagnosticsStore(baseDirectory: baseDirectory)
        let expired = Date().addingTimeInterval(-CrashDiagnosticsStore.maximumAge - 1)

        XCTAssertTrue(try store.save(sampleEnvelope(), now: expired))
        XCTAssertTrue(store.summaries().isEmpty)
    }

    func testApprovedReportRetriesOnlyAfterBackoffWithoutChangingPayload() throws {
        let baseDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: baseDirectory) }
        let store = CrashDiagnosticsStore(baseDirectory: baseDirectory)
        let report = sampleEnvelope()
        let now = Date()
        XCTAssertTrue(try store.save(report, now: now))
        let approved = try store.approve(reportID: report.reportID, now: now)

        let retryAt = try XCTUnwrap(
            store.markUploadFailure(reportID: report.reportID, now: now)
        )
        XCTAssertTrue(store.approvedReportsDue(now: now).isEmpty)
        XCTAssertEqual(
            store.approvedReportsDue(now: retryAt.addingTimeInterval(1)),
            [report.reportID]
        )
        XCTAssertEqual(try store.verifiedUploadRequest(reportID: report.reportID), approved)
    }

    private func sampleEnvelope() -> CrashReportEnvelope {
        CrashReportEnvelope(
            schemaVersion: 1,
            reportID: UUID().uuidString.lowercased(),
            source: .kscrash,
            occurredAt: "2026-07-24T12:00:00Z",
            app: CrashAppInfo(version: "5.2.0", build: "5200"),
            device: CrashDeviceInfo(model: "iPhone16.2", osVersion: "18.5"),
            diagnostic: CrashDiagnostic(
                kind: .signal,
                exceptionName: nil,
                exceptionType: nil,
                exceptionCode: nil,
                signal: 6,
                signalName: "SIGABRT",
                terminationReason: nil,
                crashedThread: 0,
                hangDurationMilliseconds: nil,
                cpuTimeMilliseconds: nil,
                sampledTimeMilliseconds: nil,
                diskWritesBytes: nil,
                component: nil,
                errorCode: nil,
                severity: nil,
                numericMetadata: nil,
                threads: [
                    CrashThread(
                        index: 0,
                        crashed: true,
                        frames: [
                            CrashStackFrame(
                                instructionAddress: 4_096,
                                binaryAddress: 2_048,
                                binaryOffset: 2_048,
                                binaryName: "OsmAnd",
                                binaryUUID: "00112233445566778899AABBCCDDEEFF",
                                symbolAddress: nil,
                                symbolName: nil
                            ),
                        ]
                    ),
                ],
                binaryImages: [
                    CrashBinaryImage(
                        name: "OsmAnd",
                        uuid: "00112233445566778899AABBCCDDEEFF",
                        imageAddress: 2_048
                    ),
                ]
            ),
            context: CrashContextSnapshot(),
            breadcrumbs: []
        )
    }

    private func nonFatalEnvelope(errorCode: Int) -> CrashReportEnvelope {
        let event = CrashNonFatalEvent(
            component: .resources,
            code: errorCode,
            severity: .warning,
            numericMetadata: [:]
        )
        let report = CrashDiagnosticsSanitizer.makeNonFatalEnvelope(
            event,
            session: CrashSessionState(context: CrashContextSnapshot(), breadcrumbs: [])
        )
        return copy(
            report,
            reportID: UUID().uuidString.lowercased(),
            occurredAt: report.occurredAt
        )
    }

    private func copy(
        _ report: CrashReportEnvelope,
        reportID: String,
        occurredAt: String
    ) -> CrashReportEnvelope {
        CrashReportEnvelope(
            schemaVersion: report.schemaVersion,
            reportID: reportID,
            source: report.source,
            occurredAt: occurredAt,
            app: report.app,
            device: report.device,
            diagnostic: report.diagnostic,
            context: report.context,
            breadcrumbs: report.breadcrumbs
        )
    }
}
