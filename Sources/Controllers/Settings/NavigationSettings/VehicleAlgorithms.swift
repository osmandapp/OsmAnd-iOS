//
//  VehicleAlgorithms.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 19.11.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class VehicleAlgorithms: NSObject {
    static func convertWeightFromTons(_ weight: Float, usePounds: Bool, appMode: OAApplicationMode) -> Float {
        usePounds ? weight * (OsmAndFormatter.shared.POUNDS_IN_ONE_KILOGRAM * Float(OsmAndFormatter.shared.KILOGRAMS_IN_ONE_TON)) : weight
    }
    
    static func convertWeightToTons(_ weight: Float, usePounds: Bool, appMode: OAApplicationMode) -> Float {
        usePounds ? weight / (OsmAndFormatter.shared.POUNDS_IN_ONE_KILOGRAM * Float(OsmAndFormatter.shared.KILOGRAMS_IN_ONE_TON)) : weight
    }
    
    static func convertLengthFromMeters(_ length: Float, appMode: OAApplicationMode) -> Float {
        let metric = OAAppSettings.sharedManager().metricSystem.get(appMode)
        return metric == EOAMetricsConstant.MILES_AND_FEET || metric == EOAMetricsConstant.NAUTICAL_MILES_AND_FEET || metric == EOAMetricsConstant.MILES_AND_YARDS ? length * OsmAndFormatter.shared.INCHES_IN_ONE_METER : length
    }
    
    static func convertLengthToMeters(_ length: Float, appMode: OAApplicationMode) -> Float {
        let metric = OAAppSettings.sharedManager().metricSystem.get(appMode)
        return metric == EOAMetricsConstant.MILES_AND_FEET || metric == EOAMetricsConstant.NAUTICAL_MILES_AND_FEET || metric == EOAMetricsConstant.MILES_AND_YARDS ? length / OsmAndFormatter.shared.INCHES_IN_ONE_METER : length
    }
    
    static func convertFromMetric(_ value: Float, isWeight: Bool, appMode: OAApplicationMode) -> Float {
        isWeight ? convertWeightFromTons(value, usePounds: usePounds(with: appMode), appMode: appMode) : convertLengthFromMeters(value, appMode: appMode)
    }
    
    static func convertToMetric(_ value: Float, isWeight: Bool, appMode: OAApplicationMode) -> Float {
        isWeight ? convertWeightToTons(value, usePounds: usePounds(with: appMode), appMode: appMode) : convertLengthToMeters(value, appMode: appMode)
    }
    
    static func formattedSelectedValue(_ value: Double, maximumFractionDigits: Int) -> String {
        let factor = pow(10.0, Double(maximumFractionDigits))
        let rounded = round(value * factor) / factor
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumIntegerDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.decimalSeparator = "."
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: rounded)) ?? "0"
    }
    
    static func roundToSecondSignificantDigit(_ value: Double) -> Double {
        guard value != 0 else { return 0 }
        let absValue = abs(value)
        let power = floor(log10(absValue)) - 1
        let factor = pow(10.0, power)
        var rounded = absValue / factor
        rounded = round(rounded)
        rounded *= factor
        let sign = value > 0 ? 1.0 : (value < 0 ? -1.0 : 0.0)

        return sign * rounded
    }
    
    static func usePoundsOrInches(with appMode: OAApplicationMode, isWeight: Bool) -> Bool {
        isWeight ? usePounds(with: appMode) : useInches(with: appMode)
    }
    
    static func usePounds(with appMode: OAApplicationMode) -> Bool {
        OAAppSettings.sharedManager().drivingRegion.get(appMode) == EOADrivingRegion.DR_US
    }
    
    static func useInches(with appMode: OAApplicationMode) -> Bool {
        let metric = OAAppSettings.sharedManager().metricSystem.get(appMode)
        return metric == EOAMetricsConstant.MILES_AND_FEET || metric == EOAMetricsConstant.NAUTICAL_MILES_AND_FEET || metric == EOAMetricsConstant.MILES_AND_YARDS
    }
    
    static func weightOrSizeUnit(with appMode: OAApplicationMode, isWeight: Bool) -> String {
        localizedString(isWeight ? weightUnit(with: appMode) : sizeUnit(with: appMode))
    }
    
    private static func weightUnit(with appMode: OAApplicationMode) -> String {
        usePounds(with: appMode) ? "metric_lbs" : "metric_ton"
    }
    
    private static func sizeUnit(with appMode: OAApplicationMode) -> String {
        useInches(with: appMode) ? "inch" : "m"
    }
}
