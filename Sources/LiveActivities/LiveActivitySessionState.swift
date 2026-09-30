// Copyright © 2026 OsmAnd. All rights reserved.

/// A dismissed activity stays dismissed until its navigation/recording session ends.
struct LiveActivitySessionState {
    private(set) var isActive = false
    private(set) var isDismissed = false

    mutating func activate(canStart: Bool) {
        if canStart { isActive = true }
    }

    mutating func dismiss() { isDismissed = true }

    mutating func end() {
        isActive = false
        isDismissed = false
    }

    func canRequestActivity(isForeground: Bool, isAuthorized: Bool, isRunning: Bool) -> Bool {
        isActive && !isDismissed && isForeground && isAuthorized && isRunning
    }
}
