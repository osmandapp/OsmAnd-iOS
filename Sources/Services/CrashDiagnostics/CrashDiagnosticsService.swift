//
//  CrashDiagnosticsService.swift
//  OsmAnd Maps
//

import Foundation
import MetricKit
import UIKit
import os

extension Notification.Name {
    static let crashDiagnosticsReportsDidChange = Notification.Name("OACrashDiagnosticsReportsDidChange")
}

@objcMembers
final class CrashDiagnosticsService: NSObject {
    static let shared = CrashDiagnosticsService()

    private let fileManager = FileManager.default
    private let stateQueue = DispatchQueue(label: "net.osmand.crash-diagnostics.session")
    private let processStartUptime = ProcessInfo.processInfo.systemUptime
    private let baseDirectory: URL
    private let sessionStateURL: URL
    private let store: CrashDiagnosticsStore
    private lazy var uploader = CrashDiagnosticsUploader(store: store) { [weak self] in
        self?.notifyReportsChanged()
    }
    private lazy var metricKitSubscriber = CrashDiagnosticsMetricKitSubscriber { [weak self] payloads in
        self?.processMetricKitPayloads(payloads)
    }
    private var currentSession = CrashSessionState(context: CrashContextSnapshot(), breadcrumbs: [])
    private var didStart = false
    private var didOfferPendingReport = false
    private var applicationContextReady = false
    private var contextRefreshTimer: Timer?

    override private init() {
        let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        baseDirectory = applicationSupport.appendingPathComponent("CrashDiagnostics", isDirectory: true)
        sessionStateURL = baseDirectory.appendingPathComponent("CurrentSession.json")
        store = CrashDiagnosticsStore(baseDirectory: baseDirectory)
        super.init()
    }

    @objc(startWithLaunchOptions:)
    func start(launchOptions: NSDictionary?) {
        guard Self.isCaptureEnabled else { return }
        let startup: (shouldStart: Bool, previousSession: CrashSessionState?) = stateQueue.sync {
            guard !didStart else { return (false, nil) }
            didStart = true
            configureBaseDirectory()
            return (true, loadSessionStateLocked())
        }
        guard startup.shouldStart else { return }

        installKSCrash()
        processPendingKSCrashReports(previousSession: startup.previousSession)

        stateQueue.sync {
            currentSession = CrashSessionState(context: CrashContextSnapshot(), breadcrumbs: [])
            currentSession.context.applicationState = "inactive"
            appendBreadcrumbLocked(event: .appLaunched, numericMetadata: [:])
            persistSessionStateLocked()
        }

        let metricManager = MXMetricManager.shared
        metricManager.add(metricKitSubscriber)
        processMetricKitPayloads(metricManager.pastDiagnosticPayloads)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        retryApprovedReports()
    }

    private static var isCaptureEnabled: Bool {
#if DEBUG
        true
#else
        Bundle.main.object(forInfoDictionaryKey: "OSMAND_CRASH_CAPTURE_ENABLED") as? Bool ?? false
#endif
    }

    private var isStarted: Bool {
        stateQueue.sync { didStart }
    }

    func recordBreadcrumb(_ event: CrashBreadcrumbEvent) {
        recordBreadcrumb(event, numericMetadata: [:])
    }

    func recordBreadcrumb(_ event: CrashBreadcrumbEvent, numericMetadata: [String: Int64]) {
        guard isStarted else { return }
        stateQueue.sync {
            appendBreadcrumbLocked(event: event, numericMetadata: numericMetadata)
            persistSessionStateLocked()
        }
    }

    func updateContext(_ context: CrashContextSnapshot) {
        guard isStarted else { return }
        stateQueue.sync {
            let sanitized = CrashDiagnosticsSanitizer.sanitizeContext(context)
            let previous = currentSession.context
            guard sanitized != previous else { return }
            currentSession.context = sanitized
            if sanitized.screenIdentifier != previous.screenIdentifier {
                appendBreadcrumbLocked(event: .screenChanged, numericMetadata: [:])
            }
            if sanitized.navigationActive != previous.navigationActive {
                appendBreadcrumbLocked(
                    event: sanitized.navigationActive ? .navigationStarted : .navigationStopped,
                    numericMetadata: [:]
                )
            }
            if sanitized.routeCalculationState != previous.routeCalculationState {
                appendBreadcrumbLocked(
                    event: sanitized.routeCalculationState == "calculating"
                        ? .routeCalculationStarted
                        : .routeCalculationFinished,
                    numericMetadata: [:]
                )
            }
            if sanitized.profileFamily != previous.profileFamily {
                appendBreadcrumbLocked(event: .profileChanged, numericMetadata: [:])
            }
            if sanitized.builtInPluginIDs != previous.builtInPluginIDs
                || sanitized.customPluginCount != previous.customPluginCount {
                appendBreadcrumbLocked(event: .pluginChanged, numericMetadata: [:])
            }
            if sanitized.mapSourceCategory != previous.mapSourceCategory
                || sanitized.loadedMapCount != previous.loadedMapCount {
                appendBreadcrumbLocked(event: .mapSourceChanged, numericMetadata: [:])
            }
            persistSessionStateLocked()
        }
    }

    func recordNonFatal(_ event: CrashNonFatalEvent) {
        guard isStarted else { return }
        let session = stateQueue.sync { currentSession }
        let report = CrashDiagnosticsSanitizer.makeNonFatalEnvelope(event, session: session)
        do {
            if try store.save(report) {
                notifyReportsChanged()
            }
        } catch {
            NSLog("[CrashDiagnostics] Failed to save non-fatal report: %@", error.localizedDescription)
        }
    }

    func pendingReports() -> [CrashReportSummary] {
        store.summaries()
    }

    var pendingReportCount: Int {
        pendingReports().count
    }

    var canUpload: Bool {
        uploader.canUpload
    }

    func prettyPrintedReport(reportID: String) throws -> String {
        let data = try store.prettyPrintedReportData(reportID: reportID)
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    func approveAndSend(
        reportID: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard uploader.canUpload else {
            completion(.failure(CrashDiagnosticsUploadError.endpointUnavailable))
            return
        }
        do {
            _ = try store.approve(reportID: reportID)
            notifyReportsChanged()
            uploader.uploadApprovedReport(reportID: reportID) { [weak self] result in
                self?.notifyReportsChanged()
                completion(result)
            }
        } catch {
            completion(.failure(error))
        }
    }

    @objc(deleteReportWithID:)
    func delete(reportID: String) {
        store.delete(reportID: reportID)
        notifyReportsChanged()
    }

    func deleteAll() {
        store.deleteAll()
        notifyReportsChanged()
    }

    @objc(applicationStateDidChange:)
    func applicationStateDidChange(_ state: String) {
        guard isStarted else { return }
        switch state {
        case "active":
            recordBreadcrumb(.appBecameActive)
            retryApprovedReports()
            if stateQueue.sync(execute: { applicationContextReady }) {
                startContextRefreshTimerIfReady()
                presentPendingReportBannerIfNeeded()
            }
        case "background":
            recordBreadcrumb(.appEnteredBackground)
            stopContextRefreshTimer()
        case "inactive":
            stopContextRefreshTimer()
        default:
            break
        }
        updateApplicationContext(state: state)
    }

    func applicationStartupDidComplete() {
        guard isStarted else { return }
        stateQueue.sync {
            applicationContextReady = true
        }
        applicationStateDidChange(applicationStateName(UIApplication.shared.applicationState))
    }

    func didReceiveMemoryWarning() {
        guard isStarted else { return }
        recordBreadcrumb(.memoryWarning)
        updateApplicationContext(state: applicationStateName(UIApplication.shared.applicationState))
    }

    func presentPendingReportBannerIfNeeded() {
        guard isStarted else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            guard !self.didOfferPendingReport,
                  let report = self.pendingReports().first(where: {
                      $0.source != .nonFatal && $0.uploadState == .pending
                  }) else {
                return
            }
            self.didOfferPendingReport = true
            CrashDiagnosticsBannerPresenter.shared.present(reportID: report.reportID)
        }
    }

    private func installKSCrash() {
        guard OACrashDiagnosticsKSCrashBridge.install(atPath: baseDirectory.path) else { return }
        configureProtectionRecursively(at: baseDirectory.appendingPathComponent("RawReports", isDirectory: true))
    }

    private func retryApprovedReports() {
        uploader.retryApprovedReports()
    }

    private func processPendingKSCrashReports(previousSession: CrashSessionState?) {
        let session = previousSession ?? CrashSessionState(context: CrashContextSnapshot(), breadcrumbs: [])
        for entry in OACrashDiagnosticsKSCrashBridge.pendingReports() {
            guard let reportID = (entry["report_id"] as? NSNumber)?.int64Value,
                  let rawReport = entry["report"] as? [String: Any] else {
                continue
            }
            guard let normalized = CrashDiagnosticsSanitizer.normalizeKSCrashReport(rawReport, session: session) else {
                OACrashDiagnosticsKSCrashBridge.deleteReport(withID: reportID)
                continue
            }
            do {
                let saved = try store.save(normalized)
                OACrashDiagnosticsKSCrashBridge.deleteReport(withID: reportID)
                if saved {
                    notifyReportsChanged()
                }
            } catch {
                NSLog("[CrashDiagnostics] Failed to normalize KSCrash report: %@", error.localizedDescription)
            }
        }
    }

    private func updateApplicationContext(state: String) {
        let shouldReadApplicationObjects = stateQueue.sync {
            currentSession.context.applicationState = allowedApplicationState(state)
            persistSessionStateLocked()
            return applicationContextReady
        }
        guard shouldReadApplicationObjects else { return }

        DispatchQueue.main.async {
            var context = self.stateQueue.sync { self.currentSession.context }

            let routingHelper = OARoutingHelper.sharedInstance()
            context.navigationActive = routingHelper.isFollowingMode()
            if routingHelper.isRouteBeingCalculated() {
                context.routeCalculationState = "calculating"
            } else if routingHelper.isRouteCalculated() {
                context.routeCalculationState = "calculated"
            } else {
                context.routeCalculationState = "idle"
            }

            let settings = OAAppSettings.sharedManager()
            let mode = settings.currentMode
            let baseMode = mode.parent ?? mode
            context.profileFamily = self.safeProfileFamily(baseMode.stringKey)

            let plugins = OAPluginsHelper.getEnabledPlugins()
            var builtInPluginIDs: [String] = []
            var customPluginCount = 0
            for plugin in plugins {
                let className = NSStringFromClass(type(of: plugin))
                if className.hasSuffix("OACustomPlugin") {
                    customPluginCount += 1
                } else if let pluginID = plugin.getId() {
                    builtInPluginIDs.append(pluginID)
                }
            }
            context.builtInPluginIDs = builtInPluginIDs
            context.customPluginCount = customPluginCount

            if let appData = OsmAndApp.swiftInstance().data {
                let activeMapSources = [
                    appData.lastMapSource,
                    appData.overlayMapSource,
                    appData.underlayMapSource,
                ].compactMap { $0 }
                context.loadedMapCount = activeMapSources.count
                context.mapSourceCategory = self.mapSourceCategory(appData.lastMapSource)
            } else {
                context.loadedMapCount = 0
                context.mapSourceCategory = "unknown"
            }

            if let appDelegate = UIApplication.shared.delegate as? OAAppDelegate,
               let root = appDelegate.rootViewController,
               root.mapPanel.mapViewController.mapViewLoaded {
                context.zoomBucket = Int(root.mapPanel.mapViewController.getMapZoom().rounded())
            }
            context.screenIdentifier = self.topViewControllerName()
            context.memoryAvailableBucketMB = self.resourceBucket(
                bytes: UInt64(os_proc_available_memory())
            )
            context.diskAvailableBucketMB = self.availableDiskBytes().map(self.resourceBucket)
            self.updateContext(context)
        }
    }

    private func appendBreadcrumbLocked(
        event: CrashBreadcrumbEvent,
        numericMetadata: [String: Int64]
    ) {
        let elapsed = max(ProcessInfo.processInfo.systemUptime - processStartUptime, 0)
        currentSession.breadcrumbs.append(
            CrashBreadcrumb(
                elapsedMilliseconds: Int64(elapsed * 1_000),
                event: event.wireName,
                numericMetadata: numericMetadata.isEmpty ? nil : numericMetadata,
                screenIdentifier: currentSession.context.screenIdentifier
            )
        )
        currentSession.breadcrumbs = Array(currentSession.breadcrumbs.suffix(100))
    }

    private func configureBaseDirectory() {
        try? fileManager.createDirectory(
            at: baseDirectory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication]
        )
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var directory = baseDirectory
        try? directory.setResourceValues(resourceValues)
        configureProtectionRecursively(at: baseDirectory)
    }

    private func startContextRefreshTimerIfReady() {
        let isReady = stateQueue.sync { applicationContextReady }
        guard isReady else { return }
        DispatchQueue.main.async {
            self.contextRefreshTimer?.invalidate()
            self.contextRefreshTimer = Timer.scheduledTimer(
                withTimeInterval: 10,
                repeats: true
            ) { [weak self] _ in
                guard let self else { return }
                self.updateApplicationContext(
                    state: self.applicationStateName(UIApplication.shared.applicationState)
                )
            }
        }
    }

    private func stopContextRefreshTimer() {
        DispatchQueue.main.async {
            self.contextRefreshTimer?.invalidate()
            self.contextRefreshTimer = nil
        }
    }

    private func configureProtectionRecursively(at url: URL) {
        try? fileManager.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: url.path
        )
    }

    private func loadSessionStateLocked() -> CrashSessionState? {
        guard let data = try? Data(contentsOf: sessionStateURL) else { return nil }
        return try? CrashDiagnosticsJSON.decoder().decode(CrashSessionState.self, from: data)
    }

    private func persistSessionStateLocked() {
        guard let data = try? CrashDiagnosticsJSON.encoder().encode(currentSession) else { return }
        try? data.write(
            to: sessionStateURL,
            options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
        )
    }

    private func notifyReportsChanged() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .crashDiagnosticsReportsDidChange, object: self)
        }
    }

    private func safeProfileFamily(_ rawValue: String) -> String {
        let allowed: Set<String> = [
            "default", "car", "bicycle", "pedestrian", "aircraft", "truck",
            "motorcycle", "moped", "boat", "public_transport", "train", "ski", "horse",
        ]
        return allowed.contains(rawValue) ? rawValue : "custom"
    }

    private func mapSourceCategory(_ mapSource: OAMapSource?) -> String {
        guard let mapSource else { return "unknown" }
        if mapSource.type?.caseInsensitiveCompare("sqlitedb") == .orderedSame {
            return "offline_raster"
        }
        if mapSource.resourceId?.caseInsensitiveCompare("online_tiles") == .orderedSame {
            return "online_raster"
        }
        return "offline_vector"
    }

    private func topViewControllerName() -> String? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        var current = window?.rootViewController
        while true {
            if let navigation = current as? UINavigationController {
                current = navigation.visibleViewController
            } else if let tab = current as? UITabBarController {
                current = tab.selectedViewController
            } else if let presented = current?.presentedViewController {
                current = presented
            } else {
                break
            }
        }
        guard let current else { return nil }
        return NSStringFromClass(type(of: current)).components(separatedBy: ".").last
    }

    private func allowedApplicationState(_ state: String) -> String {
        ["active", "inactive", "background"].contains(state) ? state : "unknown"
    }

    private func applicationStateName(_ state: UIApplication.State) -> String {
        switch state {
        case .active: return "active"
        case .inactive: return "inactive"
        case .background: return "background"
        @unknown default: return "unknown"
        }
    }

    private func availableDiskBytes() -> UInt64? {
        let values = try? baseDirectory.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        guard let bytes = values?.volumeAvailableCapacityForImportantUsage, bytes >= 0 else {
            return nil
        }
        return UInt64(bytes)
    }

    private func resourceBucket(bytes: UInt64) -> Int {
        let megabytes = Int(min(bytes / 1_024 / 1_024, UInt64(Int.max)))
        let buckets = [0, 64, 128, 256, 512, 1_024, 2_048, 4_096, 8_192, 16_384, 32_768, 65_536, 131_072]
        return buckets.last(where: { $0 <= megabytes }) ?? 0
    }
}

private extension CrashDiagnosticsService {
    func processMetricKitPayloads(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            let occurredAt = payload.timeStampEnd
            for diagnostic in payload.crashDiagnostics ?? [] {
                saveMetricKitReport(
                    kind: .crash,
                    diagnostic: diagnostic,
                    occurredAt: occurredAt,
                    exceptionType: diagnostic.exceptionType,
                    exceptionCode: diagnostic.exceptionCode,
                    signal: diagnostic.signal,
                    terminationReason: diagnostic.terminationReason,
                    callStackTreeData: diagnostic.callStackTree.jsonRepresentation()
                )
            }
            for diagnostic in payload.hangDiagnostics ?? [] {
                saveMetricKitReport(
                    kind: .hang,
                    diagnostic: diagnostic,
                    occurredAt: occurredAt,
                    hangDurationMilliseconds: Int64(
                        diagnostic.hangDuration.converted(to: .milliseconds).value.rounded()
                    ),
                    callStackTreeData: diagnostic.callStackTree.jsonRepresentation()
                )
            }
            for diagnostic in payload.cpuExceptionDiagnostics ?? [] {
                saveMetricKitReport(
                    kind: .cpuException,
                    diagnostic: diagnostic,
                    occurredAt: occurredAt,
                    cpuTimeMilliseconds: Int64(
                        diagnostic.totalCPUTime.converted(to: .milliseconds).value.rounded()
                    ),
                    sampledTimeMilliseconds: Int64(
                        diagnostic.totalSampledTime.converted(to: .milliseconds).value.rounded()
                    ),
                    callStackTreeData: diagnostic.callStackTree.jsonRepresentation()
                )
            }
            for diagnostic in payload.diskWriteExceptionDiagnostics ?? [] {
                saveMetricKitReport(
                    kind: .diskWriteException,
                    diagnostic: diagnostic,
                    occurredAt: occurredAt,
                    diskWritesBytes: Int64(
                        diagnostic.totalWritesCaused.converted(to: .bytes).value.rounded()
                    ),
                    callStackTreeData: diagnostic.callStackTree.jsonRepresentation()
                )
            }
        }
        presentPendingReportBannerIfNeeded()
    }

    private func saveMetricKitReport(
        kind: CrashDiagnosticKind,
        diagnostic: MXDiagnostic,
        occurredAt: Date,
        exceptionType: NSNumber? = nil,
        exceptionCode: NSNumber? = nil,
        signal: NSNumber? = nil,
        terminationReason: String? = nil,
        hangDurationMilliseconds: Int64? = nil,
        cpuTimeMilliseconds: Int64? = nil,
        sampledTimeMilliseconds: Int64? = nil,
        diskWritesBytes: Int64? = nil,
        callStackTreeData: Data?
    ) {
        let metaData = diagnostic.metaData
        let report = CrashDiagnosticsSanitizer.makeMetricKitEnvelope(
            kind: kind,
            occurredAt: occurredAt,
            appVersion: diagnostic.applicationVersion,
            appBuild: metaData.applicationBuildVersion,
            deviceModel: metaData.deviceType,
            osVersion: metaData.osVersion,
            exceptionType: exceptionType,
            exceptionCode: exceptionCode,
            signal: signal,
            terminationReason: terminationReason,
            hangDurationMilliseconds: hangDurationMilliseconds,
            cpuTimeMilliseconds: cpuTimeMilliseconds,
            sampledTimeMilliseconds: sampledTimeMilliseconds,
            diskWritesBytes: diskWritesBytes,
            callStackTreeData: callStackTreeData
        )
        do {
            if try store.save(report) {
                notifyReportsChanged()
            }
        } catch {
            NSLog("[CrashDiagnostics] Failed to save MetricKit report: %@", error.localizedDescription)
        }
    }
}

private final class CrashDiagnosticsMetricKitSubscriber: NSObject, MXMetricManagerSubscriber {
    private let payloadHandler: ([MXDiagnosticPayload]) -> Void

    init(payloadHandler: @escaping ([MXDiagnosticPayload]) -> Void) {
        self.payloadHandler = payloadHandler
        super.init()
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        payloadHandler(payloads)
    }
}
