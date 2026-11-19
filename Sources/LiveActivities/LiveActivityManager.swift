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
