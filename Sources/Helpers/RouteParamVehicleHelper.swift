//
//  RouteParamVehicleHelper.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 27.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class RouteParamVehicleHelper: NSObject {
    static let height = "height"
    static let weight = "weight"
    static let width = "width"
    static let length = "length"
    static let motorType = "motor_type"
    static let maxAxleLoad = "maxaxleload"
    static let weightRating = "weightrating"
    static let fuelTankCapacity = "fuel_tank_capacity"
    
    static func isWeightParameter(_ parameter: String) -> Bool {
        [weight, weightRating, maxAxleLoad].contains(where: { $0 == parameter })
    }
}
