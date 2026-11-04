// Copyright © 2026 OsmAnd. All rights reserved.


/// Immutable values copied under the router lock; no mutable route or maneuver objects leave it.
@objcMembers
final class LiveActivityRouteInfo: NSObject, @unchecked Sendable {
    let turnTypeValue: Int32
    let turnAngle: Float
    let exitNumber: Int
    let turnID: Int
    let turnDistance: Double
    let instruction: String
    let streetName: String
    let totalDistance: Double
    let remainingDistance: Double
    let remainingDuration: TimeInterval
    let isRouteCalculated: Bool
    let isDeviatedFromRoute: Bool
    let routeDeviation: Double
    let calculationError: String

    init(turnTypeValue: Int32,
         turnAngle: Float,
         exitNumber: Int,
         turnID: Int,
         turnDistance: Double,
         instruction: String,
         streetName: String,
         totalDistance: Double,
         remainingDistance: Double,
         remainingDuration: TimeInterval,
         isRouteCalculated: Bool,
         isDeviatedFromRoute: Bool,
         routeDeviation: Double,
         calculationError: String) {
        self.turnTypeValue = turnTypeValue
        self.turnAngle = turnAngle.isFinite ? turnAngle : 0
        self.exitNumber = exitNumber
        self.turnID = turnID
        self.turnDistance = turnDistance
        self.instruction = instruction
        self.streetName = streetName
        self.totalDistance = totalDistance
        self.remainingDistance = remainingDistance
        self.remainingDuration = remainingDuration
        self.isRouteCalculated = isRouteCalculated
        self.isDeviatedFromRoute = isDeviatedFromRoute
        self.routeDeviation = routeDeviation
        self.calculationError = calculationError
        super.init()
    }
}
