//
//  VehicleMetricsTripRecordingCommandsViewController+Model.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 18.06.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

enum VehicleMetricsItem: CaseIterable {
    case engineOilTemp
    case engineCoolantTemp
    case airTemp
    case airIntakeTemp
    case fuelLevel
    case fuelPressure
    case fuelConsumption
    case engineLoad
    case engineRuntime
    case engineRPM
    case batteryVoltage
    case throttlePosition
    case speed
    
    var command: String {
        switch self {
        case .engineOilTemp: "OBD_ENGINE_OIL_TEMPERATURE_COMMAND"
        case .engineCoolantTemp: "OBD_ENGINE_COOLANT_TEMP_COMMAND"
        case .airTemp: "OBD_AMBIENT_AIR_TEMPERATURE_COMMAND"
        case .airIntakeTemp: "OBD_AIR_INTAKE_TEMP_COMMAND"
        case .fuelLevel: "OBD_FUEL_LEVEL_COMMAND"
        case .fuelPressure: "OBD_FUEL_PRESSURE_COMMAND"
        case .fuelConsumption: "OBD_FUEL_CONSUMPTION_RATE_COMMAND"
        case .engineLoad: "OBD_CALCULATED_ENGINE_LOAD_COMMAND"
        case .engineRuntime: "OBD_ENGINE_RUNTIME_COMMAND"
        case .engineRPM: "OBD_RPM_COMMAND"
        case .batteryVoltage: "OBD_BATTERY_VOLTAGE_COMMAND"
        case .throttlePosition: "OBD_THROTTLE_POSITION_COMMAND"
        case .speed: "OBD_SPEED_COMMAND"
        }
    }
    
    var name: String {
        switch self {
        case .engineOilTemp: localizedString("obd_engine_oil_temperature")
        case .engineCoolantTemp: localizedString("obd_engine_coolant_temp")
        case .airTemp: localizedString("obd_ambient_air_temp")
        case .airIntakeTemp: localizedString("obd_air_intake_temp")
        case .fuelLevel: localizedString("remaining_fuel")
        case .fuelPressure: localizedString("obd_fuel_pressure")
        case .fuelConsumption: localizedString("obd_fuel_consumption")
        case .engineLoad: localizedString("obd_calculated_engine_load")
        case .engineRuntime: localizedString("obd_engine_runtime")
        case .engineRPM: localizedString("obd_widget_engine_speed")
        case .batteryVoltage: localizedString("obd_battery_voltage")
        case .throttlePosition: localizedString("obd_throttle_position")
        case .speed: localizedString("obd_widget_vehicle_speed")
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .engineOilTemp: return .icCustomObdTemperatureEngineOil
        case .engineCoolantTemp: return .icCustomObdTemperatureCoolant
        case .airTemp: return .icCustomObdTemperatureOutside
        case .airIntakeTemp: return .icCustomObdTemperatureIntake
        case .fuelLevel: return .icCustomObdFuelRemaining
        case .fuelPressure: return .icCustomObdFuelPressure
        case .fuelConsumption: return .icCustomObdFuelConsumption
        case .engineLoad: return .icCustomCarInfo
        case .engineRuntime: return .icCustomCarRunningTime
        case .engineRPM: return .icCustomObdEngineSpeed
        case .batteryVoltage: return .icCustomObdBatteryVoltage
        case .throttlePosition: return .icCustomObdThrottlePosition
        case .speed: return .icCustomObdSpeed
        }
    }
    
    static var allCommands: [String] {
        Self.allCases.map { $0.command }
    }
    
    //        var category: RecordingCategory {
    //            switch self {
    //            case .engineOilTemp, .engineCoolantTemp, .airTemp, .airIntakeTemp:
    //                return .temperature
    //            case .fuelLevel, .fuelPressure, .fuelConsumption:
    //                return .fuel
    //            case .engineLoad, .engineRuntime, .engineRPM:
    //                return .engine
    //            case .batteryVoltage, .throttlePosition, .speed:
    //                return .other
    //            }
    //        }

    //        static func items(for category: RecordingCategory) -> [VehicleMetricsItem] {
    //            Self.allCases.filter { $0.category == category }
    //        }
}

enum RecordingCategory: Int, CaseIterable {
    case temperature
    case fuel
    case engine
    case other
    
    var title: String {
        switch self {
        case .temperature: localizedString("shared_string_temperature")
        case .fuel: localizedString("poi_filter_fuel")
        case .engine: localizedString("shared_string_engine")
        case .other: localizedString("shared_string_other")
        }
    }
    
    var items: [VehicleMetricsItem] {
        switch self {
        case .temperature: [.airTemp, .engineCoolantTemp, .engineOilTemp, .airIntakeTemp]
        case .fuel: [.fuelConsumption, .fuelPressure, .fuelLevel]
        case .engine: [.engineLoad, .engineRuntime, .engineRPM]
        case .other: [.batteryVoltage, .throttlePosition, .speed]
        }
    }
}
