//
//  values.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 23.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

extension OBDDataComputer.OBDTypeWidget {

    var image: UIImage? {
        switch self {
        case .speed:
            return .icCustomObdSpeed
        case .rpm:
            return .icCustomObdEngineSpeed
        case .engineRuntime:
            return nil
        case .fuelPressure:
            return .icCustomObdFuelPressure
        case .fuelLeftKm, .fuelLeftPercent, .fuelLeftLiter:
            return .icCustomObdFuelRemaining
        case .calculatedEngineLoad:
            return .icCustomCarInfo
        case .throttlePosition:
            return .icCustomObdThrottlePosition
        case .fuelConsumptionRatePercentHour, .fuelConsumptionRateLiterKm, .fuelConsumptionRateLiterHour, .fuelConsumptionRateSensor:
            return .icCustomObdFuelConsumption
        case .temperatureIntake:
            return .icCustomObdTemperatureIntake
        case .engineOilTemperature:
            return .icCustomObdTemperatureEngineOil
        case .temperatureAmbient:
            return .icCustomObdTemperatureOutside
        case .batteryVoltage:
            return .icCustomObdBatteryVoltage
        case .fuelType:
            return .icCustomObdFuelTank
        case .vin:
            return nil
        case .temperatureCoolant:
            return .icCustomObdTemperatureCoolant
        default:
            return nil
        }
    }
}
