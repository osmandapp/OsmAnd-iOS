// Copyright © 2026 OsmAnd. All rights reserved.

import ActivityKit
import Foundation

/// Entry points can be called by the routing/recording queues on every supported iOS version.
@objcMembers
final class LiveActivityManager: NSObject {
    private enum Constants {
        static let terminationCleanupTimeout: TimeInterval = 1
    }

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

    /// Best-effort cleanup when iOS gives the app time to terminate.
    func endNavigationActivityOnTermination() {
        guard #available(iOS 16.2, *) else { return }
        let navigationActivities = Activity<LiveActivityAttributes>.activities.filter { $0.attributes.kind == .navigation }
        guard !navigationActivities.isEmpty else { return }

        let completion = DispatchSemaphore(value: 0)
        // Termination occupies the main thread, so ActivityKit cleanup must run independently.
        Task.detached(priority: .high) {
            for activity in navigationActivities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            completion.signal()
        }
        // applicationWillTerminate is synchronous, so the process may exit before Activity.end finishes.
        // Wait for completion, with a timeout to leave time for the remaining shutdown work.
        _ = completion.wait(timeout: .now() + Constants.terminationCleanupTimeout)
    }
}
