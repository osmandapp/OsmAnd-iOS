// Copyright © 2026 OsmAnd. All rights reserved.

import ActivityKit

/// Entry points can be called by the routing/recording queues on every supported iOS version.
@objcMembers
final class LiveActivityManager: NSObject {
    static let shared = LiveActivityManager()
    static let authorizationDidChangeNotification = Notification.Name("LiveActivityAuthorizationDidChange")

    var areActivitiesEnabled: Bool {
        guard #available(iOS 16.2, *) else { return false }
        return ActivityAuthorizationInfo().areActivitiesEnabled
    }

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

    private let authorizationInfo = ActivityAuthorizationInfo()
    private let allActivities: [BaseLiveActivity] = [NavigationLiveActivity(), GpxLiveActivity()]
    private var areActivitiesEnabled: Bool
    private var observers: [OAAutoObserverProxy] = []
    private var isRefreshScheduled = false

    override init() {
        areActivitiesEnabled = authorizationInfo.areActivitiesEnabled
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
        Task { [weak self, authorizationInfo] in
            for await isEnabled in authorizationInfo.activityEnablementUpdates {
                guard let self else { return }
                self.updateAuthorization(isEnabled)
                self.refresh()
            }
        }
    }

    func refresh() {
        // Coalesce transitions such as following -> planning -> paused before taking a snapshot.
        guard !isRefreshScheduled else { return }
        isRefreshScheduled = true
        DispatchQueue.main.async { [self] in
            isRefreshScheduled = false
            updateAuthorization(authorizationInfo.areActivitiesEnabled)
            for activity in allActivities {
                activity.refreshActivity()
            }
        }
    }

    private func updateAuthorization(_ isEnabled: Bool) {
        guard areActivitiesEnabled != isEnabled else { return }
        areActivitiesEnabled = isEnabled
        for activity in allActivities {
            activity.onAuthorizationChanged(isEnabled: isEnabled)
        }
        NotificationCenter.default.post(name: LiveActivityManager.authorizationDidChangeNotification, object: nil)
    }

    @objc private nonisolated func scheduleRefresh() {
        LiveActivityManager.shared.refresh()
    }
}
