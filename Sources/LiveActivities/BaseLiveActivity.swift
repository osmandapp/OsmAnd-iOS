// Copyright © 2026 OsmAnd. All rights reserved.

import ActivityKit
import CoreLocation

/// Each activity owns a serial update loop: an awaited update/end can never overtake a newer session.
@available(iOS 16.2, *)
@MainActor
class BaseLiveActivity {
    private enum Constants {
        static let minimumUpdateInterval: TimeInterval = 1
        static let locationFreshnessInterval: TimeInterval = 15
    }

    var hasActiveSession: Bool { session.isActive }

    private let kind: LiveActivityKind
    private let relevanceScore: Double
    private var activity: Activity<LiveActivityAttributes>?
    private var latestContent: ActivityKit.ActivityContent<LiveActivityContent>?
    private var lastSentContent: ActivityKit.ActivityContent<LiveActivityContent>?
    private var lastSentAt = Date.distantPast
    private var session = LiveActivitySessionState()
    private var hasPendingChanges = false
    private var isProcessingChanges = false
    private var needsContentRefresh = false
    private var isPreparingContent = false
    private var isContentSnapshotValid = false
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
            lastSentContent = activity.content
            session.activate(canStart: true)
        }
    }

    func isActive() -> Bool { false }

    func isEnabled() -> Bool { false }

    func isRunning() -> Bool { false }

    // Subclasses await a snapshot from their data source.
    // swiftlint:disable:next async_without_await
    func buildContent() async -> LiveActivityContent? { nil }

    func refreshActivity() {
        isContentSnapshotValid = false
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
        prepareContent()
    }

    func onAuthorizationChanged(isEnabled: Bool) {
        if isEnabled { session.resetDismissal() }
        removeActivity(endSession: false)
    }

    func removeActivity(endSession: Bool = true) {
        cancelScheduledRefresh()
        needsContentRefresh = false
        isContentSnapshotValid = false
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

    private func prepareContent() {
        needsContentRefresh = true
        guard !isPreparingContent else { return }
        isPreparingContent = true
        Task { [self] in
            defer { isPreparingContent = false }
            while needsContentRefresh {
                needsContentRefresh = false
                isContentSnapshotValid = true
                let content = await buildContent()
                // A source/profile/session change while awaiting the snapshot needs a new read.
                guard isContentSnapshotValid else { continue }
                guard session.isActive, isActive(), isEnabled(), ActivityAuthorizationInfo().areActivitiesEnabled else { return }
                queueContentUpdate(content)
            }
        }
    }

    private func queueContentUpdate(_ content: LiveActivityContent?) {
        guard let content else {
            removeActivity()
            return
        }
        let activityContent = makeActivityContent(content)
        latestContent = activityContent
        if let staleDate = activityContent.staleDate, staleDate != .distantPast {
            // Clear the speed even if no more location or recording events arrive.
            scheduleRefresh(at: staleDate)
        }
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
            // A new fix must extend freshness even when the formatted values have not changed.
            guard content.state != lastSentContent?.state || content.staleDate != lastSentContent?.staleDate else { return }
            if let previous = lastSentContent, !content.state.needsImmediateUpdate(comparedTo: previous.state),
               (content.staleDate == .distantPast) == (previous.staleDate == .distantPast),
               Date().timeIntervalSince(lastSentAt) < Constants.minimumUpdateInterval {
                var nextRefreshAt = lastSentAt.addingTimeInterval(Constants.minimumUpdateInterval)
                if let staleDate = content.staleDate, staleDate != .distantPast {
                    nextRefreshAt = min(nextRefreshAt, staleDate)
                }
                scheduleRefresh(at: nextRefreshAt)
                return
            }
            lastSentContent = content
            lastSentAt = Date()
            await activity.update(content)
        } else if session.canRequestActivity(isForeground: UIApplication.shared.applicationState == .active,
                                             isAuthorized: ActivityAuthorizationInfo().areActivitiesEnabled),
                  Date() >= nextRequestAllowedAt {
            do {
                let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                    ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
                    ?? ""
                let attributes = LiveActivityAttributes(kind: kind, appName: appName)
                activity = try Activity.request(attributes: attributes, content: content, pushType: nil)
                lastSentContent = content
                lastSentAt = Date()
            } catch {
                nextRequestAllowedAt = Date().addingTimeInterval(15)
                scheduleRefresh(at: nextRequestAllowedAt)
            }
        }
    }

    private func makeActivityContent(_ content: LiveActivityContent) -> ActivityKit.ActivityContent<LiveActivityContent> {
        var content = content
        content.speedText = ""
        content.isLocationUnavailable = false
        // Paused activities show historical totals, which do not depend on live location updates.
        guard content.phase != .paused else {
            return ActivityKit.ActivityContent(state: content, staleDate: nil, relevanceScore: relevanceScore)
        }
        guard let locationServices = OsmAndApp.swiftInstance().locationServices else {
            content.isLocationUnavailable = true
            return ActivityKit.ActivityContent(state: content, staleDate: .distantPast, relevanceScore: relevanceScore)
        }
        let hasLocationSource = locationServices.externalProviderActive || locationServices.isRouteAnimating()
            || locationServices.isInLocationSimulation() || (locationServices.status == .active && locationServices.allowed)
        guard hasLocationSource, let location = locationServices.lastKnownLocation,
              location.horizontalAccuracy.isFinite, location.horizontalAccuracy >= 0,
              CLLocationCoordinate2DIsValid(location.coordinate) else {
            content.isLocationUnavailable = true
            return ActivityKit.ActivityContent(state: content, staleDate: .distantPast, relevanceScore: relevanceScore)
        }
        // Positions rejected by the router must not make navigation data fresh.
        guard kind != .navigation || OALocationServices.isPointAccurate(forRouting: location) else {
            return ActivityKit.ActivityContent(state: content, staleDate: .distantPast, relevanceScore: relevanceScore)
        }
        // Background distance filtering can leave a valid position unchanged for longer than 15 seconds.
        guard abs(location.timestamp.timeIntervalSinceNow) < Constants.locationFreshnessInterval else {
            return ActivityKit.ActivityContent(state: content, staleDate: .distantPast, relevanceScore: relevanceScore)
        }
        if location.speed.isFinite, location.speed >= 0 {
            content.speedText = OAOsmAndFormatter.getFormattedSpeed(Float(location.speed)) ?? ""
        }
        return ActivityKit.ActivityContent(state: content,
                                           staleDate: location.timestamp.addingTimeInterval(Constants.locationFreshnessInterval),
                                           relevanceScore: relevanceScore)
    }
}
