// Copyright © 2026 OsmAnd. All rights reserved.

import OsmAndShared

/// A snapshot of route data that can cross the Objective-C++/Swift boundary.
@objcMembers
final class LiveActivityRouteInfo: NSObject {
    let turnType: TurnType
    let turnID: Int
    let turnDistance: Double
    let instruction: String
    let streetName: String
    let totalDistance: Double

    init(turnType: TurnType, turnID: Int, turnDistance: Double,
         instruction: String, streetName: String, totalDistance: Double) {
        // Copy the maneuver values used by Live Activities so route updates cannot mutate this snapshot.
        self.turnType = TurnType.companion.valueOf(value: turnType.value, leftSide: false)
        self.turnType.turnAngle = turnType.turnAngle
        self.turnType.exitOut = turnType.exitOut
        self.turnID = turnID
        self.turnDistance = turnDistance
        self.instruction = instruction
        self.streetName = streetName
        self.totalDistance = totalDistance
        super.init()
    }
}
