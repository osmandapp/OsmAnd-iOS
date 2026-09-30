// Copyright © 2026 OsmAnd. All rights reserved.

/// Entry points can be called by the routing/recording queues on every supported iOS version.
@objcMembers
final class LiveActivityManager: NSObject {
    static let shared = LiveActivityManager()

    private override init() {
        super.init()
    }

    func refresh() {
        guard #available(iOS 16.2, *) else { return }
        DispatchQueue.main.async {
            LiveActivityCoordinator.shared.refresh()
        }
    }
}

@available(iOS 16.2, *)
@MainActor
private final class LiveActivityCoordinator: NSObject {
    static let shared = LiveActivityCoordinator()

    private let allActivities: [BaseLiveActivity] = [NavigationLiveActivity(), GpxLiveActivity()]
    private var observers: [OAAutoObserverProxy] = []
    private var isRefreshScheduled = false

    override init() {
        super.init()
        let app: OsmAndAppProtocol = OsmAndApp.swiftInstance()
        let refreshSelector = #selector(scheduleRefresh)
        observers = [
            OAAutoObserverProxy(self, withHandler: refreshSelector, andObserve: app.locationServices.updateLocationObserver),
            OAAutoObserverProxy(self, withHandler: refreshSelector, andObserve: app.trackRecordingObservable),
            OAAutoObserverProxy(self, withHandler: refreshSelector, andObserve: app.trackStartStopRecObservable),
            OAAutoObserverProxy(self, withHandler: refreshSelector, andObserve: app.applicationModeChangedObservable)
        ].compactMap { $0 }
        NotificationCenter.default.addObserver(self, selector: refreshSelector, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: refreshSelector, name: NSNotification.Name(kNotificationSetProfileSetting), object: nil)
    }

    func refresh() {
        // Coalesce transitions such as following -> planning -> paused before taking a snapshot.
        guard !isRefreshScheduled else { return }
        isRefreshScheduled = true
        DispatchQueue.main.async { [self] in
            isRefreshScheduled = false
            for activity in allActivities {
                activity.refreshActivity()
            }
        }
    }

    @objc private nonisolated func scheduleRefresh() {
        LiveActivityManager.shared.refresh()
    }
}
