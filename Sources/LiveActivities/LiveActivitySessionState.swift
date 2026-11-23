// Copyright © 2026 OsmAnd. All rights reserved.

/// Remember observed dismissal until the session ends or system authorization is restored.
struct LiveActivitySessionState: Codable, Equatable {
    let sourceIdentifier: String?
    private(set) var isDismissed = false
    private(set) var areActivitiesEnabled = true

    init(sourceIdentifier: String? = nil) {
        self.sourceIdentifier = sourceIdentifier
    }

    mutating func updateAuthorization(isEnabled: Bool) {
        if isEnabled && !areActivitiesEnabled { resetDismissal() }
        areActivitiesEnabled = isEnabled
    }

    mutating func dismiss() { isDismissed = true }

    mutating func resetDismissal() { isDismissed = false }

    mutating func end() { isDismissed = false }

    func canRequestActivity(isSourceActive: Bool, isForeground: Bool, isAuthorized: Bool) -> Bool {
        isSourceActive && !isDismissed && isForeground && isAuthorized
    }
}
