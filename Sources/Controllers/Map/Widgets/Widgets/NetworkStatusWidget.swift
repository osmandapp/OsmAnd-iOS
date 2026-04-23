import Foundation
import Network

@objcMembers
final class NetworkStatusWidget: OASimpleWidget {

    // MARK: - Constants

    private enum Constants {
        static let requestTimeout: TimeInterval = 2
        static let resourceTimeout: TimeInterval = 3
        static let latencyRetryDelayNanoseconds: UInt64 = 500_000_000 // 0.5 seconds
        static let latencyBurstCount = 3

        // Latency thresholds (ms): below excellent = excellent, below fair = fair, at or above fair = poor
        static let excellentLatencyThreshold = 100
        static let fairLatencyThreshold = 300

        // Jitter (ms) above which quality is downgraded by one tier
        static let jitterDowngradeThreshold = 100

        // Packet loss ratio at or above which quality is downgraded by one tier
        static let packetLossDowngradeThreshold = 0.34
    }

    private struct BurstResult {
        let averageLatency: Int     // ms
        let jitter: Int             // ms, max - min of samples (0 if ≤1 sample)
        let packetLossRatio: Double // 0.0–1.0

        init(samples: [Int], totalAttempts: Int) {
            if samples.isEmpty {
                averageLatency = 0; jitter = 0; packetLossRatio = 1.0
            } else {
                averageLatency = samples.reduce(0, +) / samples.count
                jitter = samples.count > 1 ? (samples.max()! - samples.min()!) : 0
                packetLossRatio = Double(totalAttempts - samples.count) / Double(totalAttempts)
            }
        }
    }

    static let UPDATE_INTERVAL_PREF_ID = "network_status_update_interval"
    static let LATENCY_CHECK_URL_PREF_ID = "network_status_latency_check_url"

    static let defaultUpdateInterval = 5
    static let defaultLatencyCheckURL = "https://clients3.google.com/generate_204"

    // MARK: - Properties

    private var lastPingTimestamp: TimeInterval = 0
    private var isLatencyCheckInProgress = false
    private var isMonitoring = false
    private var currentPath: NWPath?

    private let monitor = NWPathMonitor()

    private var updateIntervalPref: OACommonLong
    private var latencyCheckURLPref: OACommonString
    private var customId: String?

    private static var availableIntervals: [Int: String] = getAvailableIntervals()

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Constants.requestTimeout
        config.timeoutIntervalForResource = Constants.resourceTimeout
        return URLSession(configuration: config)
    }()

    // MARK: - Initializers

    convenience init(customId: String?, appMode: OAApplicationMode, widgetParams: ([String: Any])? = nil) {
        self.init(frame: .zero)

        widgetType = .networkStatus
        self.customId = customId
        configurePrefs(withId: customId, appMode: appMode, widgetParams: widgetParams)
        updateIntervalPref = Self.registerUpdateIntervalPref(customId, appMode: appMode, widgetParams: widgetParams)
        latencyCheckURLPref = Self.registerLatencyCheckURLPref(customId, appMode: appMode, widgetParams: widgetParams)
        startNetworkMonitoring()
    }

    override init(frame: CGRect) {
        updateIntervalPref = Self.registerUpdateIntervalPref(nil)
        latencyCheckURLPref = Self.registerLatencyCheckURLPref(nil)
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Public Methods

    override func updateInfo() -> Bool {
        let currentTime = Date().timeIntervalSince1970
        let interval = TimeInterval(updateIntervalPref.get())
        guard isUpdateNeeded() || currentTime - lastPingTimestamp >= interval else { return false }

        lastPingTimestamp = currentTime
        Task {
            await checkLatency()
        }
        return false
    }

    // MARK: - Settings

    override func getSettingsData(_ appMode: OAApplicationMode,
                                  widgetConfigurationParams: [String: Any]?,
                                  isCreate: Bool) -> OATableDataModel? {
        let data = OATableDataModel()
        let section = data.createNewSection()
        section.headerText = localizedString("shared_string_settings")

        // Interval row
        let intervalRow = section.createNewRow()
        intervalRow.cellType = OAValueTableViewCell.getIdentifier()
        intervalRow.key = "value_pref"
        intervalRow.title = localizedString("shared_string_interval")
        intervalRow.setObj(updateIntervalPref, forKey: "pref")

        var currentValue = Self.defaultUpdateInterval
        if let widgetConfigurationParams,
           let key = widgetConfigurationParams.keys.first(where: { $0.hasPrefix(Self.UPDATE_INTERVAL_PREF_ID) }),
           let value = widgetConfigurationParams[key] as? String,
           let widgetValue = Int(value) {
            currentValue = widgetValue
        } else if !isCreate {
            currentValue = updateIntervalPref.get(appMode)
        }
        intervalRow.setObj(Self.getIntervalTitle(currentValue), forKey: "value")
        intervalRow.setObj(getPossibleValues(), forKey: "possible_values")
        intervalRow.setObj(localizedString("network_status_update_interval_desc"), forKey: "footer")

        // URL row
        let urlRow = section.createNewRow()
        urlRow.cellType = OAInputTableViewCell.getIdentifier()
        urlRow.key = "url_input"
        urlRow.title = localizedString("network_status_url")

        var currentURL = Self.defaultLatencyCheckURL
        if let widgetConfigurationParams,
           let key = widgetConfigurationParams.keys.first(where: { $0.hasPrefix(Self.LATENCY_CHECK_URL_PREF_ID) }),
           let value = widgetConfigurationParams[key] as? String,
           !value.isEmpty {
            currentURL = value
        } else if !isCreate {
            let stored = latencyCheckURLPref.get(appMode)
            if !stored.isEmpty {
                currentURL = stored
            }
        }
        urlRow.setObj(currentURL, forKey: "value")
        urlRow.setObj(Self.defaultLatencyCheckURL, forKey: "default_value")
        urlRow.setObj(latencyCheckURLPref, forKey: "pref")
        urlRow.descr = localizedString("network_status_url_desc")

        return data
    }

    override func copySettings(_ appMode: OAApplicationMode, customId: String?) {
        Self.registerUpdateIntervalPref(customId).set(updateIntervalPref.get(appMode), mode: appMode)
        Self.registerLatencyCheckURLPref(customId).set(latencyCheckURLPref.get(appMode), mode: appMode)
    }

    // MARK: - Preference Registration

    @discardableResult
    static func registerUpdateIntervalPref(_ customId: String?,
                                           appMode: OAApplicationMode? = nil,
                                           widgetParams: ([String: Any])? = nil) -> OACommonLong {
        let settings = OAAppSettings.sharedManager()
        let prefId = customId == nil || customId!.isEmpty
            ? Self.UPDATE_INTERVAL_PREF_ID
            : Self.UPDATE_INTERVAL_PREF_ID + customId!

        let preference = settings.registerLongPreference(prefId, defValue: defaultUpdateInterval)
        if let appMode, let string = widgetParams?[Self.UPDATE_INTERVAL_PREF_ID] as? String, let widgetValue = Int(string) {
            preference.set(widgetValue, mode: appMode)
        }
        return preference
    }

    @discardableResult
    static func registerLatencyCheckURLPref(_ customId: String?,
                                            appMode: OAApplicationMode? = nil,
                                            widgetParams: ([String: Any])? = nil) -> OACommonString {
        let settings = OAAppSettings.sharedManager()
        let prefId = customId == nil || customId!.isEmpty
            ? Self.LATENCY_CHECK_URL_PREF_ID
            : Self.LATENCY_CHECK_URL_PREF_ID + customId!

        let preference = settings.registerStringPreference(prefId, defValue: defaultLatencyCheckURL)
        if let appMode, let value = widgetParams?[Self.LATENCY_CHECK_URL_PREF_ID] as? String, !value.isEmpty {
            preference.set(value, mode: appMode)
        }
        return preference
    }

    // MARK: - Interval Helpers

    static func getAvailableIntervals() -> [Int: String] {
        let intervals = [3, 5, 10, 15, 30, 60, 120, 180, 300]
        var result = [Int: String]()
        for seconds in intervals {
            let timeInterval: String
            let timeUnit: String
            if seconds < 60 {
                timeInterval = String(seconds)
                timeUnit = localizedString("shared_string_sec")
            } else {
                timeInterval = String(seconds / 60)
                timeUnit = localizedString("int_min")
            }
            let formatted = String(format: localizedString("ltr_or_rtl_combine_via_space"), arguments: [timeInterval, timeUnit])
            result[seconds] = formatted
        }
        return result
    }

    static func getIntervalTitle(_ intervalValue: Int) -> String {
        availableIntervals[intervalValue] ?? "-"
    }

    private func getPossibleValues() -> [OATableRowData] {
        var rows = [OATableRowData]()
        let valuesRow = OATableRowData()
        valuesRow.key = "values"
        valuesRow.cellType = OASegmentSliderTableViewCell.getIdentifier()
        valuesRow.title = localizedString("shared_string_interval")
        valuesRow.setObj(Self.availableIntervals, forKey: "values")
        rows.append(valuesRow)
        return rows
    }

    // MARK: - Monitoring

    private func startNetworkMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            self.currentPath = path
            DispatchQueue.main.async {
                if path.status != .satisfied {
                    self.updateStatus(.offline)
                } else {
                    Task {
                        await self.checkLatency()
                    }
                }
            }
        }

        monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }

    private func isNetworkAvailable() -> Bool {
        return currentPath?.status == .satisfied
    }

    // MARK: - Latency Check

    private func latencyCheckURL() -> URL? {
        let stored = latencyCheckURLPref.get()
        if !stored.isEmpty {
            return URL(string: stored)
        }
        return URL(string: Self.defaultLatencyCheckURL)
    }

    private func determineNetworkQuality(from result: BurstResult) -> NetworkQuality {
        // Base quality from average latency
        let baseQuality: NetworkQuality
        if result.averageLatency < Constants.excellentLatencyThreshold {
            baseQuality = .excellent
        } else if result.averageLatency < Constants.fairLatencyThreshold {
            baseQuality = .fair
        } else {
            baseQuality = .poor
        }

        // Count downgrade factors
        var downgrades = 0
        if result.jitter > Constants.jitterDowngradeThreshold { downgrades += 1 }
        if result.packetLossRatio >= Constants.packetLossDowngradeThreshold { downgrades += 1 }

        return applyDowngrades(to: baseQuality, count: downgrades)
    }

    private func applyDowngrades(to quality: NetworkQuality, count: Int) -> NetworkQuality {
        guard count > 0 else { return quality }
        switch quality {
        case .excellent: return count >= 2 ? .poor : .fair
        case .fair:      return .poor
        case .poor, .offline: return quality
        }
    }

    @MainActor
    private func updateStatus(_ quality: NetworkQuality) {
        setIcon(quality.iconName)
        setText(quality.label, subtext: nil)
    }

    private func checkLatency() async {
        guard !isLatencyCheckInProgress, isNetworkAvailable(), let url = latencyCheckURL() else {
            await MainActor.run { updateStatus(.offline) }
            return
        }

        isLatencyCheckInProgress = true
        defer { isLatencyCheckInProgress = false }

        var samples = [Int]()
        for _ in 0..<Constants.latencyBurstCount {
            if let latency = await measureSingleLatency(url: url) {
                samples.append(latency)
            }
        }

        if samples.isEmpty {
            // All burst requests failed — retry once with a single request
            try? await Task.sleep(nanoseconds: Constants.latencyRetryDelayNanoseconds)
            if let latency = await measureSingleLatency(url: url) {
                samples.append(latency)
            }
        }

        if samples.isEmpty {
            await MainActor.run { updateStatus(.offline) }
        } else {
            let burstResult = BurstResult(samples: samples, totalAttempts: Constants.latencyBurstCount)
            let quality = determineNetworkQuality(from: burstResult)
            await MainActor.run { updateStatus(quality) }
        }
    }

    private func measureSingleLatency(url: URL) async -> Int? {
        let delegate = LatencyMetricsDelegate()
        let startTime = Date()
        do {
            let (_, response) = try await session.data(for: URLRequest(url: url), delegate: delegate)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
            // Prefer metrics-based timing (HTTP request/response only)
            if let transaction = delegate.metrics?.transactionMetrics.last,
               let requestStart = transaction.requestStartDate,
               let responseEnd = transaction.responseEndDate {
                return Int(responseEnd.timeIntervalSince(requestStart) * 1000)
            }
            // Fallback to wall-clock timing
            return Int(Date().timeIntervalSince(startTime) * 1000)
        } catch {
            return nil
        }
    }
}

// MARK: - Latency Metrics Delegate

private final class LatencyMetricsDelegate: NSObject, URLSessionTaskDelegate {
    var metrics: URLSessionTaskMetrics?

    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        self.metrics = metrics
    }
}

// MARK: - Network Quality Enum

fileprivate enum NetworkQuality {
    case excellent
    case fair
    case poor
    case offline

    var label: String {
        switch self {
        case .excellent: return localizedString("network_status_widget_excellent")
        case .fair: return localizedString("network_status_widget_fair")
        case .poor: return localizedString("network_status_widget_poor")
        case .offline: return localizedString("network_status_widget_offline")
        }
    }

    var iconName: String {
        switch self {
        case .offline: return "widget_network_status_offline"
        default: return "widget_network_status_online"
        }
    }
}
