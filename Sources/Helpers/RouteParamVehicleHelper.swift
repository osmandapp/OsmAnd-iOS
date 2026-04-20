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
    
    static func enrichParameterInfo(_ paramInfo: NSMutableDictionary, parameterId: String, storedValue: String?, routerProfileKey: String?, derivedProfile: String?, appMode: OAApplicationMode) {
        guard let vehicleSpecs = getVehicleSpecs(routerProfileKey, derivedProfile: derivedProfile), let specificationType = SpecificationType.companion.getByKey(key: parameterId) else { return }
        let isMetric = shouldUseMetricSystem(specificationType, appMode: appMode)
        let measurementUnit = vehicleSpecs.getMeasurementUnits(type: specificationType, isMetric: isMetric)
        let displayValue = VehicleValueConverter.shared.readSavedValue(valueStr: storedValue ?? "0", displayUnit: measurementUnit)
        let formattedValue: (Double) -> String = { value in
            String(format: localizedString("ltr_or_rtl_combine_via_space"), SharedNumberFormatter.shared.formatDecimal(value: value, maxDigits: 1), measurementUnit.getSymbol())
        }
        
        var possibleValues: [NSNumber] = [0]
        var possibleValueDescriptions: [String] = ["-"]
        var selectedIndex = displayValue == 0.0 ? 0 : -1
        for (index, predefinedValue) in vehicleSpecs.getPredefinedValues(type: specificationType, isMetric: isMetric).enumerated() {
            let value = predefinedValue.doubleValue
            possibleValues.append(NSNumber(value: value))
            possibleValueDescriptions.append(formattedValue(value))
            if abs(value - displayValue) < 0.0001 {
                selectedIndex = index + 1
            }
        }
        
        paramInfo["value"] = displayValue == 0.0 ? localizedString("shared_string_none") : formattedValue(displayValue)
        paramInfo["selectedItem"] = NSNumber(value: selectedIndex)
        paramInfo["possibleValues"] = possibleValues
        paramInfo["possibleValuesDescr"] = possibleValueDescriptions
        paramInfo["sharedMeasurementUnit"] = measurementUnit as AnyObject
    }
    
    private static func getVehicleSpecs(_ routerProfileKey: String?, derivedProfile: String?) -> VehicleSpecs? {
        guard let routerProfile = getSharedRouterProfile(routerProfileKey) else { return nil }
        return VehicleSpecsFactory.shared.createSpecifications(profile: routerProfile, derivedProfile: derivedProfile)
    }
    
    private static func getSharedRouterProfile(_ routerProfileKey: String?) -> GeneralRouterProfile? {
        switch routerProfileKey?.lowercased() {
        case "bicycle":
            return .bicycle
        case "boat":
            return .boat
        case "car":
            return .car
        default:
            return nil
        }
    }
    
    private static func shouldUseMetricSystem(_ specificationType: SpecificationType, appMode: OAApplicationMode) -> Bool {
        let settings = OAAppSettings.sharedManager()
        if specificationType.isWeightRelated() {
            return settings.drivingRegion.get(appMode) != .DR_US
        }
        
        let metricSystem = settings.metricSystem.get(appMode)
        return metricSystem != .MILES_AND_FEET && metricSystem != .NAUTICAL_MILES_AND_FEET && metricSystem != .MILES_AND_YARDS
    }
}
