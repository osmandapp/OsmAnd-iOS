// Copyright © 2026 OsmAnd. All rights reserved.

import OsmAndShared

struct LiveActivityContent: Codable, Hashable {
    private var turnTypeValue = TurnType.companion.C
    private var turnAngle: Float = 0

    var phase: LiveActivityPhase = .active
    var title = ""
    var subtitle = ""
    var turnID = -1
    var exitNumber = 0
    var turnDistanceText = ""
    var distanceText = ""
    var durationText = ""
    var arrivalTime: Date?
    var speedText = ""
    var progress: Double?

    // Store values so encoding, equality and copies are independent of Kotlin object identity and mutation.
    var turnType: TurnType {
        get {
            let turnType = TurnType.companion.valueOf(value: turnTypeValue, leftSide: false)
            turnType.exitOut = Int32(clamping: exitNumber)
            turnType.turnAngle = turnAngle
            return turnType
        }
        set {
            turnTypeValue = newValue.value
            turnAngle = newValue.turnAngle.isFinite ? newValue.turnAngle : 0
            exitNumber = Int(newValue.exitOut)
        }
    }

    static func routeProgress(remainingDistance: Double, totalDistance: Double) -> Double? {
        guard remainingDistance.isFinite, totalDistance.isFinite, totalDistance > 0 else { return nil }
        return min(1, max(0, 1 - remainingDistance / totalDistance))
    }

    // Payloads also contain LiveActivityAttributes. Truncate external route names so that
    // exceptionally long OSM names cannot exceed ActivityKit's 4 KB limit.
    static func truncateToUTF8ByteLimit(_ value: String, maxBytes: Int = 256) -> String {
        var result = ""
        var totalByteCount = 0
        for character in value {
            let characterByteCount = String(character).utf8.count
            guard totalByteCount + characterByteCount <= maxBytes else { break }
            result.append(character)
            totalByteCount += characterByteCount
        }
        return result
    }

    func accessibilityTitle(for kind: LiveActivityKind) -> String {
        let activityName = localizedString(kind == .navigation ? "shared_string_navigation" : "record_plugin_name")
        let instruction: String
        if kind == .navigation, phase == .active, turnType.isRoundAbout() {
            instruction = String(format: localizedString("route_roundabout"), exitNumber)
        } else {
            instruction = title
        }
        return [activityName, instruction == activityName ? "" : instruction]
            .filter { !$0.isEmpty }.joined(separator: ", ")
    }

    func needsImmediateUpdate(comparedTo previous: Self) -> Bool {
        phase != previous.phase || turnID != previous.turnID || turnTypeValue != previous.turnTypeValue
            || turnAngle != previous.turnAngle || exitNumber != previous.exitNumber || title != previous.title
    }
}
