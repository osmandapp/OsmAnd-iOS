// Copyright © 2026 OsmAnd. All rights reserved.

import OsmAndShared

struct LiveActivityContent: Codable, Hashable, Sendable {
    var turnTypeValue: Int32 = TurnType.companion.C
    var turnAngle: Float = 0

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
    var isLocationUnavailable = false

    // Recreate the maneuver for drawing; only scalar values are stored and serialized.
    var turnType: TurnType {
        let turnType = TurnType.companion.valueOf(value: turnTypeValue, leftSide: false)
        turnType.exitOut = Int32(clamping: exitNumber)
        turnType.turnAngle = turnAngle
        return turnType
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        turnTypeValue = try container.decode(Int32.self, forKey: .turnTypeValue)
        turnAngle = try container.decode(Float.self, forKey: .turnAngle)
        phase = try container.decode(LiveActivityPhase.self, forKey: .phase)
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        turnID = try container.decode(Int.self, forKey: .turnID)
        exitNumber = try container.decode(Int.self, forKey: .exitNumber)
        turnDistanceText = try container.decode(String.self, forKey: .turnDistanceText)
        distanceText = try container.decode(String.self, forKey: .distanceText)
        durationText = try container.decode(String.self, forKey: .durationText)
        arrivalTime = try container.decodeIfPresent(Date.self, forKey: .arrivalTime)
        speedText = try container.decode(String.self, forKey: .speedText)
        progress = try container.decodeIfPresent(Double.self, forKey: .progress)
        // Older activity payloads do not contain this flag.
        isLocationUnavailable = try container.decodeIfPresent(Bool.self, forKey: .isLocationUnavailable) ?? false
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
        if isLocationUnavailable {
            instruction = localizedString("shared_string_location_unknown")
        } else if kind == .navigation, phase == .active, turnType.isRoundAbout() {
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
            || isLocationUnavailable != previous.isLocationUnavailable
    }
}
