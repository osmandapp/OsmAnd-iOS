// Copyright © 2026 OsmAnd. All rights reserved.

/// Remember dismissal until the session ends or system authorization is restored.
struct LiveActivitySessionState {
    private(set) var isActive = false
    private(set) var isDismissed = false

    mutating func activate(canStart: Bool) {
        if canStart { isActive = true }
    }

    mutating func dismiss() { isDismissed = true }

    mutating func resetDismissal() { isDismissed = false }

    mutating func end() {
        isActive = false
        isDismissed = false
    }

    func canRequestActivity(isForeground: Bool, isAuthorized: Bool) -> Bool {
        isActive && !isDismissed && isForeground && isAuthorized
    }
}
