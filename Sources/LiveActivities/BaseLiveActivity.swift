// Copyright © 2026 OsmAnd. All rights reserved.

import ActivityKit

/// Each activity owns a serial update loop: an awaited update/end can never overtake a newer session.
@available(iOS 16.2, *)
@MainActor
class BaseLiveActivity {
    private enum Constants {
        static let minimumUpdateInterval: TimeInterval = 1
    }

    var hasActiveSession: Bool { session.isActive }

    private let kind: LiveActivityKind
    private let relevanceScore: Double
    private var activity: Activity<LiveActivityAttributes>?
    private var latestContent: LiveActivityContent?
    private var lastSentContent: LiveActivityContent?
    private var lastSentAt = Date.distantPast
    private var session = LiveActivitySessionState()
    private var hasPendingChanges = false
    private var isProcessingChanges = false
    private var nextRequestAllowedAt = Date.distantPast
    private var scheduledRefreshTask: Task<Void, Never>?
    private var activitiesToEnd: [Activity<LiveActivityAttributes>] = []

    init(kind: LiveActivityKind, relevanceScore: Double) {
        self.kind = kind
        self.relevanceScore = relevanceScore
        let existingActivities = Activity<LiveActivityAttributes>.activities.filter { $0.attributes.kind == kind }
        activity = existingActivities.first { $0.activityState == .active || $0.activityState == .stale }
        activitiesToEnd = existingActivities.filter { $0.id != activity?.id }
        if let activity {
            lastSentContent = activity.content.state
            session.activate(canStart: true)
        }
    }

    func isActive() -> Bool { false }

    func isEnabled() -> Bool { false }

    func isRunning() -> Bool { false }

    func buildContent() -> LiveActivityContent? { nil }

    func refreshActivity() {
        cancelScheduledRefresh()
        guard isActive() else {
            removeActivity()
            return
        }
        session.activate(canStart: isRunning())
        let isAuthorized = ActivityAuthorizationInfo().areActivitiesEnabled
        guard isEnabled(), isAuthorized else {
            // A profile or system setting can hide the card without ending the ongoing session.
            removeActivity(endSession: false)
            return
        }
        syncActivityState()
        let canRequestActivity = session.canRequestActivity(isForeground: UIApplication.shared.applicationState == .active,
                                                            isAuthorized: isAuthorized)
        guard !session.isDismissed,
              activity != nil || (canRequestActivity && Date() >= nextRequestAllowedAt) else {
            latestContent = nil
            if canRequestActivity, Date() < nextRequestAllowedAt {
                scheduleRefresh(at: nextRequestAllowedAt)
            }
            hasPendingChanges = true
            processPendingActivityChanges()
            return
        }
        queueContentUpdate(buildContent())
    }

    func onAuthorizationChanged(isEnabled: Bool) {
        if isEnabled { session.resetDismissal() }
        removeActivity(endSession: false)
    }

    func removeActivity(endSession: Bool = true) {
        cancelScheduledRefresh()
        if let activity { activitiesToEnd.append(activity) }
        activity = nil
        latestContent = nil
        lastSentContent = nil
        lastSentAt = .distantPast
        if endSession { session.end() }
        nextRequestAllowedAt = .distantPast
        hasPendingChanges = true
        processPendingActivityChanges()
    }

    func formattedCurrentSpeed(isPaused: Bool) -> String {
        guard !isPaused, let location = OsmAndApp.swiftInstance().locationServices.lastKnownLocation,
              location.speed >= 0, abs(location.timestamp.timeIntervalSinceNow) < 15 else { return "" }
        return OAOsmAndFormatter.getFormattedSpeed(Float(location.speed)) ?? ""
    }

    private func queueContentUpdate(_ content: LiveActivityContent?) {
        guard let content else {
            removeActivity()
            return
        }
        latestContent = content
        hasPendingChanges = true
        processPendingActivityChanges()
    }

    private func processPendingActivityChanges() {
        guard !isProcessingChanges else { return }
        isProcessingChanges = true
        Task { [self] in
            defer { isProcessingChanges = false }
            while hasPendingChanges {
                hasPendingChanges = false
                let oldActivities = activitiesToEnd
                activitiesToEnd.removeAll()
                for oldActivity in oldActivities {
                    await oldActivity.end(nil, dismissalPolicy: .immediate)
                }
                await createOrUpdateActivity()
            }
        }
    }

    private func syncActivityState() {
        guard let activity else { return }
        switch activity.activityState {
        case .dismissed:
            session.dismiss()
        case .ended:
            // A system-ended activity may be replaced when the ongoing task returns to the foreground.
            activitiesToEnd.append(activity)
            nextRequestAllowedAt = .distantPast
        default:
            return
        }
        self.activity = nil
        lastSentContent = nil
        lastSentAt = .distantPast
        hasPendingChanges = true
    }

    private func scheduleRefresh(at date: Date) {
        cancelScheduledRefresh()
        let delay = max(0, date.timeIntervalSinceNow)
        scheduledRefreshTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            self?.scheduledRefreshTask = nil
            self?.refreshActivity()
        }
    }

    private func cancelScheduledRefresh() {
        scheduledRefreshTask?.cancel()
        scheduledRefreshTask = nil
    }

    private func createOrUpdateActivity() async {
        guard isEnabled(), ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        syncActivityState()
        guard activitiesToEnd.isEmpty, session.isActive, !session.isDismissed,
              let content = latestContent else { return }
        if let activity {
            guard content != lastSentContent else { return }
            if let previous = lastSentContent, !content.needsImmediateUpdate(comparedTo: previous),
               Date().timeIntervalSince(lastSentAt) < Constants.minimumUpdateInterval {
                scheduleRefresh(at: lastSentAt.addingTimeInterval(Constants.minimumUpdateInterval))
                return
            }
            lastSentContent = content
            lastSentAt = Date()
            await activity.update(makeActivityContent(content))
        } else if session.canRequestActivity(isForeground: UIApplication.shared.applicationState == .active,
                                             isAuthorized: ActivityAuthorizationInfo().areActivitiesEnabled),
                  Date() >= nextRequestAllowedAt {
            do {
                let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                    ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
                    ?? ""
                let attributes = LiveActivityAttributes(kind: kind, appName: appName)
                activity = try Activity.request(attributes: attributes, content: makeActivityContent(content), pushType: nil)
                lastSentContent = content
                lastSentAt = Date()
            } catch {
                nextRequestAllowedAt = Date().addingTimeInterval(15)
                scheduleRefresh(at: nextRequestAllowedAt)
            }
        }
    }

    private func makeActivityContent(_ content: LiveActivityContent) -> ActivityKit.ActivityContent<LiveActivityContent> {
        ActivityKit.ActivityContent(state: content,
                                    staleDate: nil,
                                    relevanceScore: relevanceScore)
    }
}
