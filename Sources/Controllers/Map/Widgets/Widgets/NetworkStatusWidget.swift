import Foundation
import Network

@objcMembers
final class NetworkStatusWidget: OASimpleWidget {

    // MARK: - Constants
    
    private enum Constants {
        static let requestTimeout: TimeInterval = 2
        static let resourceTimeout: TimeInterval = 3
        static let updateInterval: TimeInterval = 5
        static let latencyRetryDelayNanoseconds: UInt64 = 500_000_000 // 0.5 seconds
    }

    // MARK: - Properties
    
    private var lastPingTimestamp: TimeInterval = 0
    private var isLatencyCheckInProgress = false
    private var isMonitoring = false
    private var currentPath: NWPath?

    private let monitor = NWPathMonitor()

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Constants.requestTimeout
        config.timeoutIntervalForResource = Constants.resourceTimeout
        return URLSession(configuration: config)
    }()

    // MARK: - Initializers

    init(customId: String?, appMode: OAApplicationMode, widgetParams: ([String: Any])? = nil) {
        super.init(type: .networkStatus)
        configurePrefs(withId: customId, appMode: appMode, widgetParams: widgetParams)
        startNetworkMonitoring()
    }

    override init(frame: CGRect) {
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
        guard currentTime - lastPingTimestamp >= Constants.updateInterval else { return false }

        lastPingTimestamp = currentTime
        Task {
            await checkLatency()
        }
        return false
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
        return URL(string: "https://clients3.google.com/generate_204")
    }

    private func determineNetworkQuality(for latency: Int) -> NetworkQuality {
        switch latency {
        case ..<80:
            return .excellent
        case ..<250:
            return .fair
        default:
            return .poor
        }
    }

    @MainActor
    private func updateStatus(_ quality: NetworkQuality) {
        setIcon(quality.iconName)
        setText(quality.label, subtext: nil)
    }

    private func checkLatency(retries: Int = 1) async {
        guard !isLatencyCheckInProgress, isNetworkAvailable(), let url = latencyCheckURL() else {
            await MainActor.run { updateStatus(.offline) }
            return
        }

        isLatencyCheckInProgress = true
        defer { isLatencyCheckInProgress = false }

        let startTime = Date()

        do {
            let (_, response) = try await session.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 else {
                throw URLError(.badServerResponse)
            }

            let latency = Int(Date().timeIntervalSince(startTime) * 1000)
            let quality = determineNetworkQuality(for: latency)
            await MainActor.run { updateStatus(quality) }

        } catch {
            if retries > 0 {
                try? await Task.sleep(nanoseconds: Constants.latencyRetryDelayNanoseconds)
                await checkLatency(retries: retries - 1)
            } else {
                await MainActor.run { updateStatus(.offline) }
            }
        }
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

