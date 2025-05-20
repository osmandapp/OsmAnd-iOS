//
//  commands.swift
//  SmartOBD2
//
//  Created by kemo konteh on 9/14/23.
//

import Foundation

public extension DecodeResult {
//    var stringResult: String? {
//        if case let .stringResult(res) = self { return res as String }
//        return nil
//    }

    var statusResult: Status? {
        if case let .statusResult(res) = self { return res as Status }
        return nil
    }

    var measurementResult: MeasurementResult? {
        if case let .measurementResult(res) = self { return res as MeasurementResult }
        return nil
    }

    var troubleCode: [TroubleCode]? {
        if case let .troubleCode(res) = self { return res as [TroubleCode] }
        return nil
    }

    var measurementMonitor: Monitor? {
        if case let .measurementMonitor(res) = self { return res as Monitor }
        return nil
    }
}

public struct CommandProperties: Encodable {
    public let command: String
    public let description: String
    let bytes: Int
    let decoder: Decoders
    public let live: Bool
    public let maxValue: Double
    public let minValue: Double

    public init(_ command: String,
                _ description: String,
                _ bytes: Int,
                _ decoder: Decoders,
                _ live: Bool = false,
                maxValue: Double = 100,
                minValue: Double = 0) {
        self.command = command
        self.description = description
        self.bytes = bytes
        self.decoder = decoder
        self.live = live
        self.maxValue = maxValue
        self.minValue = minValue
    }

//    public func decode(data: Data, unit: MeasurementUnit = .metric) -> Result<DecodeResult, DecodeError> {
//        return decoder.performDecode(data: data.dropFirst(), unit: unit)
//    }

    func decode(data: Data, unit: MeasurementUnit = .metric) -> Result<DecodeResult, DecodeError> {
        guard let decoderInstance = decoder.getDecoder() else {
            return .failure(.unsupportedDecoder)
        }
        return decoderInstance.decode(data: data.dropFirst(), unit: unit)
    }
}

public enum OBDCommand: Codable, Hashable, Comparable, Identifiable {
    case general(General)
    case mode1(Mode1)
    case mode3(Mode3)
    case mode6(Mode6)
    case mode9(Mode9)
    case protocols(Protocols)
	
	public var id: Self { return self }

    public var properties: CommandProperties {
        switch self {
        case let .general(command):
            return command.properties
        case let .mode1(command):
            return command.properties
        case let .mode9(command):
            return command.properties
        case let .mode6(command):
            return command.properties
        case let .mode3(command):
            return command.properties
        case let .protocols(command):
            return command.properties
        }
    }

    public enum General: CaseIterable, Codable, Comparable {
        case ATD
        case ATZ
        case ATRV
        case ATL0
        case ATE0
        case ATH1
        case ATH0
        case ATAT1
        case ATSTFF
        case ATDPN
    }

    public enum Protocols: CaseIterable, Codable, Comparable {
        case ATSP0
        case ATSP6
        public var properties: CommandProperties {
            switch self {
            case .ATSP0: return CommandProperties("ATSP0", "Auto protocol", 0, .none)
            case .ATSP6: return CommandProperties("ATSP6", "Auto protocol", 0, .none)

            }
        }
    }

    public enum Mode1: CaseIterable, Codable, Comparable {
        case pidsA
        case status
        case freezeDTC
        case fuelStatus
        case engineLoad
        case coolantTemp
        case shortFuelTrim1
        case longFuelTrim1
        case shortFuelTrim2
        case longFuelTrim2
        case fuelPressure
        case intakePressure
        case rpm
        case speed
        case timingAdvance
        case intakeTemp
        case maf
        case throttlePos
        case airStatus
        case O2Sensor
        case O2Bank1Sensor1
        case O2Bank1Sensor2
        case O2Bank1Sensor3
        case O2Bank1Sensor4
        case O2Bank2Sensor1
        case O2Bank2Sensor2
        case O2Bank2Sensor3
        case O2Bank2Sensor4
        case obdcompliance
        case O2SensorsALT
        case auxInputStatus
        case runTime
        case pidsB
        case distanceWMIL
        case fuelRailPressureVac
        case fuelRailPressureDirect
        case O2Sensor1WRVolatage
        case O2Sensor2WRVolatage
        case O2Sensor3WRVolatage
        case O2Sensor4WRVolatage
        case O2Sensor5WRVolatage
        case O2Sensor6WRVolatage
        case O2Sensor7WRVolatage
        case O2Sensor8WRVolatage
        case commandedEGR
        case EGRError
        case evaporativePurge
        case fuelLevel
        case warmUpsSinceDTCCleared
        case distanceSinceDTCCleared
        case evapVaporPressure
        case barometricPressure
        case O2Sensor1WRCurrent
        case O2Sensor2WRCurrent
        case O2Sensor3WRCurrent
        case O2Sensor4WRCurrent
        case O2Sensor5WRCurrent
        case O2Sensor6WRCurrent
        case O2Sensor7WRCurrent
        case O2Sensor8WRCurrent
        case catalystTempB1S1
        case catalystTempB2S1
        case catalystTempB1S2
        case catalystTempB2S2
        case pidsC
        case statusDriveCycle
        case controlModuleVoltage
        case absoluteLoad
        case commandedEquivRatio
        case relativeThrottlePos
        case ambientAirTemp
        case throttlePosB
        case throttlePosC
        case throttlePosD
        case throttlePosE
        case throttlePosF
        case throttleActuator
        case runTimeMIL
        case timeSinceDTCCleared
        case maxValues
        case maxMAF
        case fuelType
        case ethanoPercent
        case evapVaporPressureAbs
        case evapVaporPressureAlt
        case shortO2TrimB1
        case longO2TrimB1
        case shortO2TrimB2
        case longO2TrimB2
        case fuelRailPressureAbs
        case relativeAccelPos
        case hybridBatteryLife
        case engineOilTemp
        case fuelInjectionTiming
        case fuelRate
        case emissionsReq
    }

    public enum Mode3: CaseIterable, Codable, Comparable {
        case GET_DTC
        var properties: CommandProperties {
            switch self {
            case .GET_DTC: return CommandProperties("03", "Get DTCs", 0, .dtc)
            }
        }
    }

    public enum Mode4: CaseIterable, Codable, Comparable {
        case CLEAR_DTC
        var properties: CommandProperties {
            switch self {
            case .CLEAR_DTC: return CommandProperties("04", "Clear DTCs and freeze data", 0, .none)
            }
        }
    }

    public enum Mode6: CaseIterable, Codable, Comparable {
        case MIDS_A
        case MONITOR_O2_B1S1
        case MONITOR_O2_B1S2
        case MONITOR_O2_B1S3
        case MONITOR_O2_B1S4
        case MONITOR_O2_B2S1
        case MONITOR_O2_B2S2
        case MONITOR_O2_B2S3
        case MONITOR_O2_B2S4
        case MONITOR_O2_B3S1
        case MONITOR_O2_B3S2
        case MONITOR_O2_B3S3
        case MONITOR_O2_B3S4
        case MONITOR_O2_B4S1
        case MONITOR_O2_B4S2
        case MONITOR_O2_B4S3
        case MONITOR_O2_B4S4
        case MIDS_B
        case MONITOR_CATALYST_B1
        case MONITOR_CATALYST_B2
        case MONITOR_CATALYST_B3
        case MONITOR_CATALYST_B4
        case MONITOR_EGR_B1
        case MONITOR_EGR_B2
        case MONITOR_EGR_B3
        case MONITOR_EGR_B4
        case MONITOR_VVT_B1
        case MONITOR_VVT_B2
        case MONITOR_VVT_B3
        case MONITOR_VVT_B4
        case MONITOR_EVAP_150
        case MONITOR_EVAP_090
        case MONITOR_EVAP_040
        case MONITOR_EVAP_020
        case MONITOR_PURGE_FLOW
        case MIDS_C
        case MONITOR_O2_HEATER_B1S1
        case MONITOR_O2_HEATER_B1S2
        case MONITOR_O2_HEATER_B1S3
        case MONITOR_O2_HEATER_B1S4
        case MONITOR_O2_HEATER_B2S1
        case MONITOR_O2_HEATER_B2S2
        case MONITOR_O2_HEATER_B2S3
        case MONITOR_O2_HEATER_B2S4
        case MONITOR_O2_HEATER_B3S1
        case MONITOR_O2_HEATER_B3S2
        case MONITOR_O2_HEATER_B3S3
        case MONITOR_O2_HEATER_B3S4
        case MONITOR_O2_HEATER_B4S1
        case MONITOR_O2_HEATER_B4S2
        case MONITOR_O2_HEATER_B4S3
        case MONITOR_O2_HEATER_B4S4
        case MIDS_D
        case MONITOR_HEATED_CATALYST_B1
        case MONITOR_HEATED_CATALYST_B2
        case MONITOR_HEATED_CATALYST_B3
        case MONITOR_HEATED_CATALYST_B4
        case MONITOR_SECONDARY_AIR_1
        case MONITOR_SECONDARY_AIR_2
        case MONITOR_SECONDARY_AIR_3
        case MONITOR_SECONDARY_AIR_4
        case MIDS_E
        case MONITOR_FUEL_SYSTEM_B1
        case MONITOR_FUEL_SYSTEM_B2
        case MONITOR_FUEL_SYSTEM_B3
        case MONITOR_FUEL_SYSTEM_B4
        case MONITOR_BOOST_PRESSURE_B1
        case MONITOR_BOOST_PRESSURE_B2
        case MONITOR_NOX_ABSORBER_B1
        case MONITOR_NOX_ABSORBER_B2
        case MONITOR_NOX_CATALYST_B1
        case MONITOR_NOX_CATALYST_B2
        case MIDS_F
        case MONITOR_MISFIRE_GENERAL
        case MONITOR_MISFIRE_CYLINDER_1
        case MONITOR_MISFIRE_CYLINDER_2
        case MONITOR_MISFIRE_CYLINDER_3
        case MONITOR_MISFIRE_CYLINDER_4
        case MONITOR_MISFIRE_CYLINDER_5
        case MONITOR_MISFIRE_CYLINDER_6
        case MONITOR_MISFIRE_CYLINDER_7
        case MONITOR_MISFIRE_CYLINDER_8
        case MONITOR_MISFIRE_CYLINDER_9
        case MONITOR_MISFIRE_CYLINDER_10
        case MONITOR_MISFIRE_CYLINDER_11
        case MONITOR_MISFIRE_CYLINDER_12
        case MONITOR_PM_FILTER_B1
        case MONITOR_PM_FILTER_B2
    }

    public enum Mode9: CaseIterable, Codable, Comparable {
        case PIDS_9A
        case VIN_MESSAGE_COUNT
        case VIN
        case CALIBRATION_ID_MESSAGE_COUNT
        case CALIBRATION_ID
        case CVN_MESSAGE_COUNT
        case CVN
        var properties: CommandProperties {
            switch self {
            case .PIDS_9A: return CommandProperties("0900", "Supported PIDs [01-20]", 7, .pid)
            case .VIN_MESSAGE_COUNT: return CommandProperties("0901", "VIN Message Count", 3, .count)
            case .VIN: return CommandProperties("0902", "Vehicle Identification Number", 22, .encoded_string)
            case .CALIBRATION_ID_MESSAGE_COUNT: return CommandProperties("0903", "Calibration ID message count for PID 04", 3, .count)
            case .CALIBRATION_ID: return CommandProperties("0904", "Calibration ID", 18, .encoded_string)
            case .CVN_MESSAGE_COUNT: return CommandProperties("0905", "CVN Message Count for PID 06", 3, .count)
            case .CVN: return CommandProperties("0906", "Calibration Verification Numbers", 10, .cvn)
            }
        }
    }

    static var pidGetters: [OBDCommand] = {
        var getters: [OBDCommand] = []
        for command in OBDCommand.Mode1.allCases {
            if command.properties.decoder == .pid {
                getters.append(.mode1(command))
            }
        }

        for command in OBDCommand.Mode6.allCases {
            if command.properties.decoder == .pid {
                getters.append(.mode6(command))
            }
        }

        for command in OBDCommand.Mode9.allCases {
            if command.properties.decoder == .pid {
                getters.append(.mode9(command))
            }
        }
        return getters
    }()

    static public var allCommands: [OBDCommand] = {
        var commands: [OBDCommand] = []
        for command in OBDCommand.General.allCases {
            commands.append(.general(command))
        }

        for command in OBDCommand.Mode1.allCases {
            commands.append(.mode1(command))
        }

        for command in OBDCommand.Mode3.allCases {
            commands.append(.mode3(command))
        }

        for command in OBDCommand.Mode6.allCases {
            commands.append(.mode6(command))
        }

        for command in OBDCommand.Mode9.allCases {
            commands.append(.mode9(command))
        }
        for command in OBDCommand.Protocols.allCases {
            commands.append(.protocols(command))
        }
        return commands
    }()
}

extension OBDCommand.General {
    public var properties: CommandProperties {
        switch self {
        case .ATD: return CommandProperties("ATD", "Set to default", 5, .none)
        case .ATZ: return CommandProperties("ATZ", "Reset", 5, .none)
        case .ATRV: return CommandProperties("ATRV", "Voltage", 5, .none)
        case .ATL0: return CommandProperties("ATL0", "Linefeeds Off", 5, .none)
        case .ATE0: return CommandProperties("ATE0", "Echo Off", 5, .none)
        case .ATH1: return CommandProperties("ATH1", "Headers On", 5, .none)
        case .ATH0: return CommandProperties("ATH0", "Headers Off", 5, .none)
        case .ATAT1: return CommandProperties("ATAT1", "Adaptive Timing On", 5, .none)
        case .ATSTFF: return CommandProperties("ATSTFF", "Set Time to Fast", 5, .none)
        case .ATDPN: return CommandProperties("ATDPN", "Describe Protocol Number", 5, .none)
        }
    }
}

extension OBDCommand.Mode1 {
    var properties: CommandProperties {
        switch self {
        case .pidsA: return CommandProperties("0100", "Supported PIDs [01-20]", 5, .pid)
        case .status: return CommandProperties("0101", "Status since DTCs cleared", 5, .status)
        case .freezeDTC: return CommandProperties("0102", "DTC that triggered the freeze frame", 5, .singleDTC)
        case .fuelStatus: return CommandProperties("0103", "Fuel System Status", 5, .fuelStatus)
        case .engineLoad: return CommandProperties("0104", "Calculated Engine Load", 2, .percent, true)
        case .coolantTemp: return CommandProperties("0105", "Coolant temperature", 2, .temp, true, maxValue: 215, minValue: -40)
        case .shortFuelTrim1: return CommandProperties("0106", "Short Term Fuel Trim - Bank 1", 2, .percentCentered, true)
        case .longFuelTrim1: return CommandProperties("0107", "Long Term Fuel Trim - Bank 1", 2, .percentCentered, true)
        case .shortFuelTrim2: return CommandProperties("0108", "Short Term Fuel Trim - Bank 2", 2, .percentCentered, true)
        case .longFuelTrim2: return CommandProperties("0109", "Long Term Fuel Trim - Bank 2", 2, .percentCentered, true)
        case .fuelPressure: return CommandProperties("010A", "Fuel Pressure", 2, .fuelPressure, true, maxValue: 765)
        case .intakePressure: return CommandProperties("010B", "Intake Manifold Pressure", 3, .pressure, true, maxValue: 255)
        case .rpm: return CommandProperties("010C", "RPM", 3, .uas(0x07), true, maxValue: 8000)
        case .speed: return CommandProperties("010D", "Vehicle Speed", 2, .uas(0x09), true, maxValue: 280)
        case .timingAdvance: return CommandProperties("010E", "Timing Advance", 2, .timingAdvance, true, maxValue: 64, minValue: -64)
        case .intakeTemp: return CommandProperties("010F", "Intake Air Temp", 2, .temp, true)
        case .maf: return CommandProperties("0110", "Air Flow Rate (MAF)", 3, .uas(0x27), true)
        case .throttlePos: return CommandProperties("0111", "Throttle Position", 2, .percent, true)
        case .airStatus: return CommandProperties("0112", "Secondary Air Status", 2, .airStatus)
        case .O2Sensor: return CommandProperties("0113", "O2 Sensors Present", 2, .o2Sensors)
        case .O2Bank1Sensor1: return CommandProperties("0114", "O2: Bank 1 - Sensor 1 Voltage", 3, .sensorVoltage, true, maxValue: 1.275)
        case .O2Bank1Sensor2: return CommandProperties("0115", "O2: Bank 1 - Sensor 2 Voltage", 3, .sensorVoltage, true, maxValue: 1.275)
        case .O2Bank1Sensor3: return CommandProperties("0116", "O2: Bank 1 - Sensor 3 Voltage", 3, .sensorVoltage, true, maxValue: 1.275)
        case .O2Bank1Sensor4: return CommandProperties("0117", "O2: Bank 1 - Sensor 4 Voltage", 3, .sensorVoltage, true, maxValue: 1.275)
        case .O2Bank2Sensor1: return CommandProperties("0118", "O2: Bank 2 - Sensor 1 Voltage", 3, .sensorVoltage, true, maxValue: 1.275)
        case .O2Bank2Sensor2: return CommandProperties("0119", "O2: Bank 2 - Sensor 2 Voltage", 3, .sensorVoltage, true, maxValue: 1.275)
        case .O2Bank2Sensor3: return CommandProperties("011A", "O2: Bank 2 - Sensor 3 Voltage", 3, .sensorVoltage, true, maxValue: 1.275)
        case .O2Bank2Sensor4: return CommandProperties("011B", "O2: Bank 2 - Sensor 4 Voltage", 3, .sensorVoltage, true, maxValue: 1.275)
        case .obdcompliance: return CommandProperties("011C", "OBD Standards Compliance", 2, .obdCompliance)
        case .O2SensorsALT: return CommandProperties("011D", "O2 Sensors Present (alternate)", 2, .o2SensorsAlt)
        case .auxInputStatus: return CommandProperties("011E", "Auxiliary input status (power take off)", 2, .auxInputStatus)
        case .runTime: return CommandProperties("011F", "Engine Run Time", 3, .uas(0x12), true)
        case .pidsB: return CommandProperties("0120", "Supported PIDs [21-40]", 5, .pid)
        case .distanceWMIL: return CommandProperties("0121", "Distance Traveled with MIL on", 4, .uas(0x25), true)
        case .fuelRailPressureVac: return CommandProperties("0122", "Fuel Rail Pressure (relative to vacuum)", 4, .uas(0x19), true)
        case .fuelRailPressureDirect: return CommandProperties("0123", "Fuel Rail Pressure (direct inject)", 4, .uas(0x1B), true)
        case .O2Sensor1WRVolatage: return CommandProperties("0124", "02 Sensor 1 WR Lambda Voltage", 6, .sensorVoltageBig, true, maxValue: 8.192)
        case .O2Sensor2WRVolatage: return CommandProperties("0125", "02 Sensor 2 WR Lambda Voltage", 6, .sensorVoltageBig, true, maxValue: 8.192)
        case .O2Sensor3WRVolatage: return CommandProperties("0126", "02 Sensor 3 WR Lambda Voltage", 6, .sensorVoltageBig, true, maxValue: 8.192)
        case .O2Sensor4WRVolatage: return CommandProperties("0127", "02 Sensor 4 WR Lambda Voltage", 6, .sensorVoltageBig, true, maxValue: 8.192)
        case .O2Sensor5WRVolatage: return CommandProperties("0128", "02 Sensor 5 WR Lambda Voltage", 6, .sensorVoltageBig, true, maxValue: 8.192)
        case .O2Sensor6WRVolatage: return CommandProperties("0129", "02 Sensor 6 WR Lambda Voltage", 6, .sensorVoltageBig, true, maxValue: 8.192)
        case .O2Sensor7WRVolatage: return CommandProperties("012A", "02 Sensor 7 WR Lambda Voltage", 6, .sensorVoltageBig, true, maxValue: 8.192)
        case .O2Sensor8WRVolatage: return CommandProperties("012B", "02 Sensor 8 WR Lambda Voltage", 6, .sensorVoltageBig, true, maxValue: 8.192)
        case .commandedEGR: return CommandProperties("012C", "Commanded EGR", 4, .percent, true)
        case .EGRError: return CommandProperties("012D", "EGR Error", 4, .percentCentered, true)
        case .evaporativePurge: return CommandProperties("012E", "Commanded Evaporative Purge", 4, .percent, true)
        case .fuelLevel: return CommandProperties("012F", "Fuel Tank Level Input", 4, .percent, true)
        case .warmUpsSinceDTCCleared: return CommandProperties("0130", "Number of warm-ups since codes cleared", 4, .uas(0x01), true)
        case .distanceSinceDTCCleared: return CommandProperties("0131", "Distance traveled since codes cleared", 4, .uas(0x25), true, maxValue: 65535.0)
        case .evapVaporPressure: return CommandProperties("0132", "Evaporative system vapor pressure", 4, .evapPressure, true)
        case .barometricPressure: return CommandProperties("0133", "Barometric Pressure", 4, .pressure, true, maxValue: 255.0)
        case .O2Sensor1WRCurrent: return CommandProperties("0134", "02 Sensor 1 WR Lambda Current", 4, .currentCentered, true, maxValue: 128, minValue: -128)
        case .O2Sensor2WRCurrent: return CommandProperties("0135", "02 Sensor 2 WR Lambda Current", 4, .currentCentered, true, maxValue: 128, minValue: -128)
        case .O2Sensor3WRCurrent: return CommandProperties("0136", "02 Sensor 3 WR Lambda Current", 4, .currentCentered, true, maxValue: 128, minValue: -128)
        case .O2Sensor4WRCurrent: return CommandProperties("0137", "02 Sensor 4 WR Lambda Current", 4, .currentCentered, true, maxValue: 128, minValue: -128)
        case .O2Sensor5WRCurrent: return CommandProperties("0138", "02 Sensor 5 WR Lambda Current", 4, .currentCentered, true, maxValue: 128, minValue: -128)
        case .O2Sensor6WRCurrent: return CommandProperties("0139", "02 Sensor 6 WR Lambda Current", 4, .currentCentered, true, maxValue: 128, minValue: -128)
        case .O2Sensor7WRCurrent: return CommandProperties("013A", "02 Sensor 7 WR Lambda Current", 4, .currentCentered, true, maxValue: 128, minValue: -128)
        case .O2Sensor8WRCurrent: return CommandProperties("013B", "02 Sensor 8 WR Lambda Current", 4, .currentCentered, true, maxValue: 128, minValue: -128)
        case .catalystTempB1S1: return CommandProperties("013C", "Catalyst Temperature: Bank 1 - Sensor 1", 4, .uas(0x16), true)
        case .catalystTempB2S1: return CommandProperties("013D", "Catalyst Temperature: Bank 2 - Sensor 1", 4, .uas(0x16), true)
        case .catalystTempB1S2: return CommandProperties("013E", "Catalyst Temperature: Bank 1 - Sensor 2", 4, .uas(0x16), true)
        case .catalystTempB2S2: return CommandProperties("013F", "Catalyst Temperature: Bank 1 - Sensor 2", 4, .uas(0x16), true)
        case .pidsC: return CommandProperties("0140", "Supported PIDs [41-60]", 6, .pid)
        case .statusDriveCycle: return CommandProperties("0141", "Monitor status this drive cycle", 6, .status)
        case .controlModuleVoltage: return CommandProperties("0142", "Control module voltage", 4, .uas(0x0B), true)
        case .absoluteLoad: return CommandProperties("0143", "Absolute load value", 4, .percent, true)
        case .commandedEquivRatio: return CommandProperties("0144", "Commanded equivalence ratio", 4, .uas(0x1E), true)
        case .relativeThrottlePos: return CommandProperties("0145", "Relative throttle position", 4, .percent, true)
        case .ambientAirTemp: return CommandProperties("0146", "Ambient air temperature", 4, .temp, true)
        case .throttlePosB: return CommandProperties("0147", "Absolute throttle position B", 4, .percent, true)
        case .throttlePosC: return CommandProperties("0148", "Absolute throttle position C", 4, .percent, true)
        case .throttlePosD: return CommandProperties("0149", "Absolute throttle position D", 4, .percent, true)
        case .throttlePosE: return CommandProperties("014A", "Absolute throttle position E", 4, .percent, true)
        case .throttlePosF: return CommandProperties("014B", "Absolute throttle position F", 4, .percent, true)
        case .throttleActuator: return CommandProperties("014C", "Commanded throttle actuator", 4, .percent, true)
        case .runTimeMIL: return CommandProperties("014D", "Time run with MIL on", 4, .uas(0x34), true)
        case .timeSinceDTCCleared: return CommandProperties("014E", "Time since trouble codes cleared", 4, .uas(0x34), true)
        case .maxValues: return CommandProperties("014F", "Maximum value for various values", 6, .none)
        case .maxMAF: return CommandProperties("0150", "Maximum value for air flow rate from mass air flow sensor", 4, .maxMaf, true)
        case .fuelType: return CommandProperties("0151", "Fuel Type", 2, .fuelType)
        case .ethanoPercent: return CommandProperties("0152", "Ethanol fuel %", 2, .percent)
        case .evapVaporPressureAbs: return CommandProperties("0153", "Absolute Evap system vapor pressure", 4, .evapPressureAlt, true)
        case .evapVaporPressureAlt: return CommandProperties("0154", "Evap system vapor pressure", 4, .evapPressureAlt, true)
        case .shortO2TrimB1: return CommandProperties("0155", "Short term secondary O2 trim - Bank 1", 4, .percentCentered, true)
        case .longO2TrimB1: return CommandProperties("0156", "Long term secondary O2 trim - Bank 1", 4, .percentCentered, true)
        case .shortO2TrimB2: return CommandProperties("0157", "Short term secondary O2 trim - Bank 2", 4, .percentCentered, true)
        case .longO2TrimB2: return CommandProperties("0158", "Long term secondary O2 trim - Bank 2", 4, .percentCentered, true)
        case .fuelRailPressureAbs: return CommandProperties("0159", "Fuel rail pressure (absolute)", 4, .uas(0x1B), true)
        case .relativeAccelPos: return CommandProperties("015A", "Relative accelerator pedal position", 3, .percent, true)
        case .hybridBatteryLife: return CommandProperties("015B", "Hybrid battery pack remaining life", 3, .percent)
        case .engineOilTemp: return CommandProperties("015C", "Engine oil temperature", 3, .temp, true)
        case .fuelInjectionTiming: return CommandProperties("015D", "Fuel injection timing", 4, .injectTiming, true)
        case .fuelRate: return CommandProperties("015E", "Engine fuel rate", 4, .fuelRate, true)
        case .emissionsReq: return CommandProperties("015F", "Designed emission requirements", 3, .none)
        }
    }
}

extension OBDCommand.Mode6 {
    var properties: CommandProperties {
        switch self {
        case .MIDS_A: return CommandProperties("0600", "Supported MIDs [01-20]", 0, .pid)
        case .MONITOR_O2_B1S1: return CommandProperties("0601", "O2 Sensor Monitor Bank 1 - Sensor 1", 0, .monitor)
        case .MONITOR_O2_B1S2: return CommandProperties("0602", "O2 Sensor Monitor Bank 1 - Sensor 2", 0, .monitor)
        case .MONITOR_O2_B1S3: return CommandProperties("0603", "O2 Sensor Monitor Bank 1 - Sensor 3", 0, .monitor)
        case .MONITOR_O2_B1S4: return CommandProperties("0604", "O2 Sensor Monitor Bank 1 - Sensor 4", 0, .monitor)
        case .MONITOR_O2_B2S1: return CommandProperties("0605", "O2 Sensor Monitor Bank 2 - Sensor 1", 0, .monitor)
        case .MONITOR_O2_B2S2: return CommandProperties("0606", "O2 Sensor Monitor Bank 2 - Sensor 2", 0, .monitor)
        case .MONITOR_O2_B2S3: return CommandProperties("0607", "O2 Sensor Monitor Bank 2 - Sensor 3", 0, .monitor)
        case .MONITOR_O2_B2S4: return CommandProperties("0608", "O2 Sensor Monitor Bank 2 - Sensor 4", 0, .monitor)
        case .MONITOR_O2_B3S1: return CommandProperties("0609", "O2 Sensor Monitor Bank 3 - Sensor 1", 0, .monitor)
        case .MONITOR_O2_B3S2: return CommandProperties("060A", "O2 Sensor Monitor Bank 3 - Sensor 2", 0, .monitor)
        case .MONITOR_O2_B3S3: return CommandProperties("060B", "O2 Sensor Monitor Bank 3 - Sensor 3", 0, .monitor)
        case .MONITOR_O2_B3S4: return CommandProperties("060C", "O2 Sensor Monitor Bank 3 - Sensor 4", 0, .monitor)
        case .MONITOR_O2_B4S1: return CommandProperties("060D", "O2 Sensor Monitor Bank 4 - Sensor 1", 0, .monitor)
        case .MONITOR_O2_B4S2: return CommandProperties("060E", "O2 Sensor Monitor Bank 4 - Sensor 2", 0, .monitor)
        case .MONITOR_O2_B4S3: return CommandProperties("060F", "O2 Sensor Monitor Bank 4 - Sensor 3", 0, .monitor)
        case .MONITOR_O2_B4S4: return CommandProperties("0610", "O2 Sensor Monitor Bank 4 - Sensor 4", 0, .monitor)
        case .MIDS_B: return CommandProperties("0620", "Supported MIDs [21-40]", 0, .pid)
        case .MONITOR_CATALYST_B1: return CommandProperties("0621", "Catalyst Monitor Bank 1", 0, .monitor)
        case .MONITOR_CATALYST_B2: return CommandProperties("0622", "Catalyst Monitor Bank 2", 0, .monitor)
        case .MONITOR_CATALYST_B3: return CommandProperties("0623", "Catalyst Monitor Bank 3", 0, .monitor)
        case .MONITOR_CATALYST_B4: return CommandProperties("0624", "Catalyst Monitor Bank 4", 0, .monitor)
        case .MONITOR_EGR_B1: return CommandProperties("0631", "EGR Monitor Bank 1", 0, .monitor)
        case .MONITOR_EGR_B2: return CommandProperties("0632", "EGR Monitor Bank 2", 0, .monitor)
        case .MONITOR_EGR_B3: return CommandProperties("0633", "EGR Monitor Bank 3", 0, .monitor)
        case .MONITOR_EGR_B4: return CommandProperties("0634", "EGR Monitor Bank 4", 0, .monitor)
        case .MONITOR_VVT_B1: return CommandProperties("0635", "VVT Monitor Bank 1", 0, .monitor)
        case .MONITOR_VVT_B2: return CommandProperties("0636", "VVT Monitor Bank 2", 0, .monitor)
        case .MONITOR_VVT_B3: return CommandProperties("0637", "VVT Monitor Bank 3", 0, .monitor)
        case .MONITOR_VVT_B4: return CommandProperties("0638", "VVT Monitor Bank 4", 0, .monitor)
        case .MONITOR_EVAP_150: return CommandProperties("0639", "EVAP Monitor (Cap Off / 0.150\")", 0, .monitor)
        case .MONITOR_EVAP_090: return CommandProperties("063A", "EVAP Monitor (0.090\")", 0, .monitor)
        case .MONITOR_EVAP_040: return CommandProperties("063B", "EVAP Monitor (0.040\")", 0, .monitor)
        case .MONITOR_EVAP_020: return CommandProperties("063C", "EVAP Monitor (0.020\")", 0, .monitor)
        case .MONITOR_PURGE_FLOW: return CommandProperties("063D", "Purge Flow Monitor", 0, .monitor)
        case .MIDS_C: return CommandProperties("0640", "Supported MIDs [41-60]", 0, .pid)
        case .MONITOR_O2_HEATER_B1S1: return CommandProperties("0641", "O2 Sensor Heater Monitor Bank 1 - Sensor 1", 0, .monitor)
        case .MONITOR_O2_HEATER_B1S2: return CommandProperties("0642", "O2 Sensor Heater Monitor Bank 1 - Sensor 2", 0, .monitor)
        case .MONITOR_O2_HEATER_B1S3: return CommandProperties("0643", "O2 Sensor Heater Monitor Bank 1 - Sensor 3", 0, .monitor)
        case .MONITOR_O2_HEATER_B1S4: return CommandProperties("0644", "O2 Sensor Heater Monitor Bank 1 - Sensor 4", 0, .monitor)
        case .MONITOR_O2_HEATER_B2S1: return CommandProperties("0645", "O2 Sensor Heater Monitor Bank 2 - Sensor 1", 0, .monitor)
        case .MONITOR_O2_HEATER_B2S2: return CommandProperties("0646", "O2 Sensor Heater Monitor Bank 2 - Sensor 2", 0, .monitor)
        case .MONITOR_O2_HEATER_B2S3: return CommandProperties("0647", "O2 Sensor Heater Monitor Bank 2 - Sensor 3", 0, .monitor)
        case .MONITOR_O2_HEATER_B2S4: return CommandProperties("0648", "O2 Sensor Heater Monitor Bank 2 - Sensor 4", 0, .monitor)
        case .MONITOR_O2_HEATER_B3S1: return CommandProperties("0649", "O2 Sensor Heater Monitor Bank 3 - Sensor 1", 0, .monitor)
        case .MONITOR_O2_HEATER_B3S2: return CommandProperties("064A", "O2 Sensor Heater Monitor Bank 3 - Sensor 2", 0, .monitor)
        case .MONITOR_O2_HEATER_B3S3: return CommandProperties("064B", "O2 Sensor Heater Monitor Bank 3 - Sensor 3", 0, .monitor)
        case .MONITOR_O2_HEATER_B3S4: return CommandProperties("064C", "O2 Sensor Heater Monitor Bank 3 - Sensor 4", 0, .monitor)
        case .MONITOR_O2_HEATER_B4S1: return CommandProperties("064D", "O2 Sensor Heater Monitor Bank 4 - Sensor 1", 0, .monitor)
        case .MONITOR_O2_HEATER_B4S2: return CommandProperties("064E", "O2 Sensor Heater Monitor Bank 4 - Sensor 2", 0, .monitor)
        case .MONITOR_O2_HEATER_B4S3: return CommandProperties("064F", "O2 Sensor Heater Monitor Bank 4 - Sensor 3", 0, .monitor)
        case .MONITOR_O2_HEATER_B4S4: return CommandProperties("0650", "O2 Sensor Heater Monitor Bank 4 - Sensor 4", 0, .monitor)
        case .MIDS_D: return CommandProperties("0660", "Supported MIDs [61-80]", 0, .pid)
        case .MONITOR_HEATED_CATALYST_B1: return CommandProperties("0661", "Heated Catalyst Monitor Bank 1", 0, .monitor)
        case .MONITOR_HEATED_CATALYST_B2: return CommandProperties("0662", "Heated Catalyst Monitor Bank 2", 0, .monitor)
        case .MONITOR_HEATED_CATALYST_B3: return CommandProperties("0663", "Heated Catalyst Monitor Bank 3", 0, .monitor)
        case .MONITOR_HEATED_CATALYST_B4: return CommandProperties("0664", "Heated Catalyst Monitor Bank 4", 0, .monitor)
        case .MONITOR_SECONDARY_AIR_1: return CommandProperties("0671", "Secondary Air Monitor 1", 0, .monitor)
        case .MONITOR_SECONDARY_AIR_2: return CommandProperties("0672", "Secondary Air Monitor 2", 0, .monitor)
        case .MONITOR_SECONDARY_AIR_3: return CommandProperties("0673", "Secondary Air Monitor 3", 0, .monitor)
        case .MONITOR_SECONDARY_AIR_4: return CommandProperties("0674", "Secondary Air Monitor 4", 0, .monitor)
        case .MIDS_E: return CommandProperties("0680", "Supported MIDs [81-A0]", 0, .pid)
        case .MONITOR_FUEL_SYSTEM_B1: return CommandProperties("0681", "Fuel System Monitor Bank 1", 0, .monitor)
        case .MONITOR_FUEL_SYSTEM_B2: return CommandProperties("0682", "Fuel System Monitor Bank 2", 0, .monitor)
        case .MONITOR_FUEL_SYSTEM_B3: return CommandProperties("0683", "Fuel System Monitor Bank 3", 0, .monitor)
        case .MONITOR_FUEL_SYSTEM_B4: return CommandProperties("0684", "Fuel System Monitor Bank 4", 0, .monitor)
        case .MONITOR_BOOST_PRESSURE_B1: return CommandProperties("0685", "Boost Pressure Control Monitor Bank 1", 0, .monitor)
        case .MONITOR_BOOST_PRESSURE_B2: return CommandProperties("0686", "Boost Pressure Control Monitor Bank 1", 0, .monitor)
        case .MONITOR_NOX_ABSORBER_B1: return CommandProperties("0690", "NOx Absorber Monitor Bank 1", 0, .monitor)
        case .MONITOR_NOX_ABSORBER_B2: return CommandProperties("0691", "NOx Absorber Monitor Bank 2", 0, .monitor)
        case .MONITOR_NOX_CATALYST_B1: return CommandProperties("0698", "NOx Catalyst Monitor Bank 1", 0, .monitor)
        case .MONITOR_NOX_CATALYST_B2: return CommandProperties("0699", "NOx Catalyst Monitor Bank 2", 0, .monitor)
        case .MIDS_F: return CommandProperties("06A0", "Supported MIDs [A1-C0]", 0, .pid)
        case .MONITOR_MISFIRE_GENERAL: return CommandProperties("06A1", "Misfire Monitor General Data", 0, .monitor)
        case .MONITOR_MISFIRE_CYLINDER_1: return CommandProperties("06A2", "Misfire Cylinder 1 Data", 0, .monitor)
        case .MONITOR_MISFIRE_CYLINDER_2: return CommandProperties("06A3", "Misfire Cylinder 2 Data", 0, .monitor)
        case .MONITOR_MISFIRE_CYLINDER_3: return CommandProperties("06A4", "Misfire Cylinder 3 Data", 0, .monitor)
        case .MONITOR_MISFIRE_CYLINDER_4: return CommandProperties("06A5", "Misfire Cylinder 4 Data", 0, .monitor)
        case .MONITOR_MISFIRE_CYLINDER_5: return CommandProperties("06A6", "Misfire Cylinder 5 Data", 0, .monitor)
        case .MONITOR_MISFIRE_CYLINDER_6: return CommandProperties("06A7", "Misfire Cylinder 6 Data", 0, .monitor)
        case .MONITOR_MISFIRE_CYLINDER_7: return CommandProperties("06A8", "Misfire Cylinder 7 Data", 0, .monitor)
        case .MONITOR_MISFIRE_CYLINDER_8: return CommandProperties("06A9", "Misfire Cylinder 8 Data", 0, .monitor)
        case .MONITOR_MISFIRE_CYLINDER_9: return CommandProperties("06AA", "Misfire Cylinder 9 Data", 0, .monitor)
        case .MONITOR_MISFIRE_CYLINDER_10: return CommandProperties("06AB", "Misfire Cylinder 10 Data", 0, .monitor)
        case .MONITOR_MISFIRE_CYLINDER_11: return CommandProperties("06AC", "Misfire Cylinder 11 Data", 0, .monitor)
        case .MONITOR_MISFIRE_CYLINDER_12: return CommandProperties("06AD", "Misfire Cylinder 12 Data", 0, .monitor)
        case .MONITOR_PM_FILTER_B1: return CommandProperties("06B0", "PM Filter Monitor Bank 1", 0, .monitor)
        case .MONITOR_PM_FILTER_B2: return CommandProperties("06B1", "PM Filter Monitor Bank 2", 0, .monitor)
        }
    }
}

extension OBDCommand {
    static public func from(command: String) -> OBDCommand? {
        return OBDCommand.allCommands.first(where: { $0.properties.command == command })
    }
}

extension OBDCommand {
	public var detailedDescription: String? {
		switch self {
			case .mode1(let mode1):
				switch mode1 {
					case .status: return "Monitor Status of the vehicle's systems"
					case .freezeDTC: return """
						The Freeze DTC (Diagnostic Trouble Codes) PID is used to retrieve trouble codes that were stored in the vehicle's ECU (Engine Control Unit) when a fault condition was detected. Specifically, Freeze DTC will provide the trouble codes for faults that triggered the Malfunction Indicator Light (MIL), also known as the Check Engine Light (CEL).

						These codes represent issues or malfunctions in the vehicle's systems, such as the engine, transmission, emissions controls, and more. The codes are stored in the vehicle's computer memory to help identify what needs to be repaired.
						"""
					case .fuelStatus: return """
						The Fuel Status PID provides information about the fuel system's operating status. Specifically, it indicates whether the engine is running in closed-loop or open-loop operation, and whether the fuel system is in a condition that is optimizing fuel efficiency.

						This data is important because it helps determine how efficiently the engine is operating and if it's using the correct air-fuel ratio based on the engine's operating conditions.
						"""
					case .engineLoad: return """
						The Fuel Status PID provides information about the fuel system's operating status. Specifically, it indicates whether the engine is running in closed-loop or open-loop operation, and whether the fuel system is in a condition that is optimizing fuel efficiency.

						This data is important because it helps determine how efficiently the engine is operating and if it's using the correct air-fuel ratio based on the engine's operating conditions.
						"""
					case .coolantTemp: return """
						The Coolant Temperature PID provides the current temperature of the engine's coolant. This is an important parameter because the engine's cooling system regulates the engine temperature to prevent overheating and to optimize fuel efficiency. The coolant temperature can affect engine performance, fuel efficiency, and emissions.
						"""
					case .shortFuelTrim1: return """
						The Short Term Fuel Trim 1 (STFT1) PID provides the short-term adjustment the engine control unit (ECU) makes to the fuel injector pulse width in response to real-time feedback from the oxygen sensor. This adjustment is used to correct the air-fuel mixture (the ratio of air to fuel) for optimal combustion.

						STFT1 refers to Bank 1, Sensor 1 — the upstream oxygen sensor, which is located before the catalytic converter.
						"""
					case .longFuelTrim1: return """
						The Long Term Fuel Trim 1 (LTFT1) PID provides the long-term adjustment made by the engine control unit (ECU) to the fuel injection system based on sustained trends over time. Unlike Short Term Fuel Trim (STFT), which adjusts in real-time, LTFT1 reflects cumulative changes made to the fuel mixture to address consistent deviations from the ideal air-fuel ratio.

						LTFT1 refers to Bank 1, Sensor 1 — the upstream oxygen sensor for Bank 1 (the side of the engine that typically includes cylinder 1).
						"""
					case .shortFuelTrim2: return """
						The Short Term Fuel Trim 2 (STFT2) PID provides the short-term adjustment to the fuel system for Bank 2 (the opposite side of the engine from Bank 1) based on feedback from the upstream oxygen sensor (O2 sensor). This adjustment helps the engine maintain an optimal air-fuel ratio for combustion in real-time.

						STFT2 is similar to STFT1, but it pertains to Bank 2, and it represents the engine’s short-term response to changes in air-fuel ratio based on sensor feedback.
						"""
					case .longFuelTrim2: return """
						The Long Term Fuel Trim 2 (LTFT2) PID provides the long-term adjustment the engine control unit (ECU) makes to the fuel injector pulse width in response to persistent trends in the air-fuel mixture over time. Unlike the Short Term Fuel Trim (STFT), which adjusts in real-time, LTFT represents a cumulative, long-term correction to fuel delivery, reflecting ongoing conditions.

						LTFT2 refers to Bank 2, Sensor 1 — the upstream oxygen sensor for Bank 2 (the side of the engine opposite to Bank 1, which is typically determined by cylinder numbering in the engine).
						"""
					case .fuelPressure: return """
						Shows the fuel rail pressure. 
						
						Normal Range: Typically between 300–450 kPa depending on the vehicle and operating conditions. 
						Low or high fuel pressure can indicate issues with the fuel pump, fuel filter, or fuel injectors.
						"""
					case .intakePressure: return """
						Indicates intake manifold pressure.
						
						Normal Range: Typically around 20–100 kPa at idle, depending on altitude and engine load.
						Low values usually mean a vacuum is being created in the manifold (idle or light load).
						High values indicate high intake pressures, which happen when the throttle is wide open or under heavy load.
						"""
					case .rpm: return "The Engine RPM PID provides the current revolutions per minute (RPM) of the engine, indicating how fast the engine's crankshaft is rotating. This is a key parameter for monitoring engine performance and efficiency."
					case .speed: return "The Vehicle Speed PID provides the current speed of the vehicle, typically in kilometers per hour (km/h) or miles per hour (mph), depending on the vehicle's configuration."
					case .timingAdvance: return """
						Shows ignition timing advance.
						
						Positive values (e.g., +5°) = advanced timing, which improves performance and efficiency.
						Negative values = retarded timing, typically to prevent knocking or because of high load conditions.
						Normal values typically range from +10° to -10° (depending on load, engine speed, and conditions).
						"""
					case .intakeTemp: return """
						Shows intake air temperature.
						
						Cold air is denser, improving combustion efficiency and power, so lower intake temperatures (e.g., under 20°C) are generally better for performance.
						High intake temperatures (e.g., over 40°C) can reduce engine performance and efficiency, especially under heavy load.
						"""
					case .maf: return """
						Shows the mass air flow (in g/s).
						
						MAF measures the amount of air entering the engine, which the ECU uses to determine the right amount of fuel to inject.
						Low MAF readings could indicate issues with the air intake system (e.g., clogged air filter).
						High MAF readings are common under heavy acceleration or high load.
						"""
					case .throttlePos: return """
						Shows the throttle position as a percentage.
						
						0% = Throttle is closed (idle or off)
						100% = Throttle is fully open (wide open throttle or WOT)
						Normal driving conditions will vary, but you'll often see values between 10-50% during normal driving.
						"""
					case .airStatus: return """
						This is related to the status of the air intake system, which helps in monitoring air quality and air flow for optimal combustion.
						"""
					case .O2Sensor: return """
						Oxygen sensors (also called O2 sensors) measure the amount of oxygen in the exhaust gases, which helps the engine control unit (ECU) adjust the air-fuel mixture for optimal combustion.
						
						Wideband O2 sensors: Voltage range typically from 0 to 5V. Higher voltage indicates a richer mixture, while lower voltage indicates a leaner mixture.
						Narrowband O2 sensors: Typically fluctuate between 0.1V (lean) and 0.9V (rich).
						Normal Range (for narrowband O2 sensor):
						0.1V - 0.9V: Normal sensor behavior (lean to rich conditions)
						"""
					case .O2Bank1Sensor1: return "The Oxygen Sensor Bank 1, Sensor 1 PID provides the data from the first oxygen sensor located before the catalytic converter (also called the pre-catalytic converter O2 sensor) on Bank 1 of the engine. Bank 1 refers to the side of the engine where cylinder #1 is located, and this sensor is critical for monitoring the air-fuel mixture and ensuring proper emissions control."
					case .O2Bank1Sensor2: return "The Oxygen Sensor Bank 1, Sensor 2 PID provides the data from the second oxygen sensor located after the catalytic converter on Bank 1 of the engine. This sensor is often referred to as the post-catalytic converter O2 sensor or downstream O2 sensor. It plays a crucial role in monitoring the performance of the catalytic converter and ensuring it is properly filtering the exhaust gases."
					case .O2Bank1Sensor3: return "The Oxygen Sensor Bank 1, Sensor 3 PID is not part of the standard OBD-II PIDs and generally does not exist for typical gasoline vehicles. The OBD-II standard generally only defines PIDs for upstream (pre-catalytic converter) and downstream (post-catalytic converter) oxygen sensors for each bank."
					case .O2Bank1Sensor4: return "Similar to Oxygen Sensor Bank 1, Sensor 3, the Oxygen Sensor Bank 1, Sensor 4 PID does not exist as part of the standard OBD-II PIDs. The OBD-II standard typically provides only two oxygen sensors per bank: one before (upstream) and one after (downstream) the catalytic converter."
					case .O2Bank2Sensor1: return """
						The Oxygen Sensor Bank 2, Sensor 1 PID provides data from the first oxygen sensor located before the catalytic converter (pre-catalytic converter O2 sensor) on Bank 2 of the engine. Bank 2 refers to the side of the engine opposite to Bank 1 (the side where cylinder #1 is located).

						This upstream O2 sensor plays a critical role in monitoring the air-fuel mixture and sending feedback to the ECU (Engine Control Unit) to adjust fuel delivery for optimal combustion.
						"""
					case .O2Bank2Sensor2: return """
						The Oxygen Sensor Bank 2, Sensor 2 PID provides data from the second oxygen sensor located after the catalytic converter (post-catalytic converter O2 sensor) on Bank 2 of the engine. This sensor is also referred to as the downstream O2 sensor and is crucial for monitoring the efficiency of the catalytic converter.

						It measures the oxygen content in the exhaust gases after the gases have passed through the catalytic converter, which allows the ECU to determine if the catalytic converter is performing correctly in reducing emissions.
						"""
					case .O2Bank2Sensor3: return """
						Similar to Bank 1, Sensor 3, the Oxygen Sensor Bank 2, Sensor 3 PID is not part of the standard OBD-II PIDs. The standard OBD-II system typically provides support for two oxygen sensors per bank:
						Upstream sensor (Sensor 1): Before the catalytic converter (pre-catalytic converter).
						Downstream sensor (Sensor 2): After the catalytic converter (post-catalytic converter).
						"""
					case .O2Bank2Sensor4: return """
						Similar to Oxygen Sensor Bank 2, Sensor 3, the Oxygen Sensor Bank 2, Sensor 4 PID is not part of the standard OBD-II PIDs. The OBD-II standard typically provides support for two oxygen sensors per bank — one upstream (before the catalytic converter) and one downstream (after the catalytic converter).
						"""
					case .obdcompliance: return "OBD Compliance typically refers to a vehicle’s readiness to pass emissions testing."
					case .auxInputStatus: return """
						"Auxiliary Input Status isn't typically a standard OBD-II PID but might relate to manufacturer-specific diagnostics or custom sensor readings.
						You would need the manufacturer-specific PID to access data related to these systems.
						"""
					case .runTime: return """
						Shows engine run time since the last reset or ignition cycle.
						
						Engine Run Time is useful for tracking how long the engine has been operating, especially for maintenance schedules, troubleshooting idle issues, or verifying engine performance.
						It also resets to zero each time the ignition is turned off and back on.
						"""
					case .distanceWMIL: return """
						Distance Since MIL (Malfunction Indicator Light) Was Last Cleared — a useful diagnostic parameter that tracks how many miles (or kilometers) the vehicle has driven since the MIL (check engine light) was last reset or turned off. 
						
						This can help you understand how long the vehicle has been operating with potential engine issues since the MIL was last cleared.
						The MIL (check engine light) is typically triggered when there is a malfunction in the engine or emissions system.
						Distance since MIL tells you how much distance has been driven since the problem was last cleared/reset.
						This is useful for tracking how much time or distance has passed since the vehicle last encountered a fault that triggered the check engine light.
						"""
					case .EGRError: return """
						The term EGR Error refers to a malfunction or issue with the Exhaust Gas Recirculation (EGR) system.
						
						The EGR system helps reduce nitrogen oxide (NOx) emissions by recirculating a portion of the exhaust gases back into the intake air to lower combustion temperatures. When the EGR system isn't functioning properly, it can trigger a fault code and cause the Check Engine Light (MIL) to illuminate.
						"""
					case .evaporativePurge: return """
						The Evaporative Purge refers to the evaporative emission control system (EVAP), which is responsible for managing and purging fuel vapors from the fuel tank. The system captures fuel vapors from the tank and sends them to the engine to be burned, rather than allowing them to escape into the atmosphere.

						The Evaporative Purge process involves the purge valve, which is controlled by the engine control unit (ECU) to allow the fuel vapors to flow into the engine when needed.
						"""
					case .fuelLevel: return """
						The Fuel Level parameter provides the current amount of fuel in the vehicle’s tank, typically expressed as a percentage of the tank’s full capacity. This reading helps the engine control unit (ECU) and the driver monitor the available fuel.
						"""
					case .warmUpsSinceDTCCleared: return """
						The Warm-ups Since DTC Cleared parameter refers to the number of engine warm-up cycles that have occurred since the Diagnostic Trouble Codes (DTCs) were last cleared. A warm-up cycle is typically counted when the engine goes from a cold start to reaching its normal operating temperature.

						This count is important because many vehicle systems, especially those related to emissions control, may perform self-diagnostics during the warm-up phase. These systems might not show faults (DTCs) until the engine has had a chance to warm up and reach certain operational conditions.
						"""
					case .distanceSinceDTCCleared: return """
						The Distance Since DTC Cleared parameter refers to the number of miles (or kilometers) the vehicle has traveled since the Diagnostic Trouble Codes (DTCs) were last cleared. This value can be helpful for determining how much driving has occurred since a fault was last reset in the vehicle's engine control unit (ECU), providing context for how long a problem has persisted.
						"""
					case .evapVaporPressure: return """
						The Evap Vapor Pressure refers to the pressure within the evaporative emission control system (EVAP). This system captures and stores fuel vapors from the fuel tank to prevent them from escaping into the atmosphere. The Evaporative Vapor Pressure is a critical parameter that the vehicle’s ECU monitors to ensure the EVAP system is functioning correctly. It helps to check for potential issues, such as leaks or improper pressure in the fuel system, which could lead to emissions problems.

						This pressure is measured by a vapor pressure sensor in the EVAP system. If the pressure is too high or too low, it can indicate a malfunction, like a blocked vent valve, a faulty pressure sensor, or an EVAP system leak.
						"""
					case .barometricPressure: return """
						The Barometric Pressure refers to the atmospheric pressure at a given location, measured in kilopascals (kPa) or inches of mercury (inHg). In OBD-II systems, this pressure reading is used by the engine control unit (ECU) for various calculations, including air-fuel ratio adjustments and altitude compensation.

						Barometric pressure plays a role in how the ECU calculates other parameters, such as air intake, fuel mixture, and engine load. Since atmospheric pressure decreases with altitude, the ECU uses the barometric pressure reading to adjust for changes in altitude during operation.
						"""
					case .catalystTempB1S1: return """
						The Catalyst Temperature (B1S1) refers to the temperature of the catalytic converter in Bank 1, Sensor 1. The catalytic converter helps reduce harmful emissions by converting toxic gases such as carbon monoxide (CO), hydrocarbons (HC), and nitrogen oxides (NOx) into less harmful substances. The temperature of the catalyst is crucial for its efficiency and effectiveness in this process.
						"""
					case .catalystTempB2S1: return """
						The Catalyst Temperature (B2S1) refers to the temperature of the catalytic converter in Bank 2, Sensor 1. The catalytic converter helps reduce harmful emissions by converting toxic gases such as carbon monoxide (CO), hydrocarbons (HC), and nitrogen oxides (NOx) into less harmful substances. The temperature of the catalyst is crucial for its efficiency and effectiveness in this process.
						"""
					case .catalystTempB1S2: return """
						The Catalyst Temperature (B1S2) refers to the temperature of the catalytic converter in Bank 1, Sensor 2. The catalytic converter helps reduce harmful emissions by converting toxic gases such as carbon monoxide (CO), hydrocarbons (HC), and nitrogen oxides (NOx) into less harmful substances. The temperature of the catalyst is crucial for its efficiency and effectiveness in this process.
						"""
					case .catalystTempB2S2: return """
						The Catalyst Temperature (B1S2) refers to the temperature of the catalytic converter in Bank 2, Sensor 2. The catalytic converter helps reduce harmful emissions by converting toxic gases such as carbon monoxide (CO), hydrocarbons (HC), and nitrogen oxides (NOx) into less harmful substances. The temperature of the catalyst is crucial for its efficiency and effectiveness in this process.
						"""
					case .statusDriveCycle: return """
						The Status of the Drive Cycle is a diagnostic parameter that indicates the current state of the vehicle’s drive cycle. A drive cycle refers to a specific sequence of driving conditions required to allow the vehicle's onboard diagnostic (OBD) system to perform self-tests and verify that various components and systems, such as the catalytic converter, oxygen sensors, and evaporative emissions system, are functioning properly.

						During a drive cycle, the OBD system checks if certain conditions have been met to test components like the catalytic converter, oxygen sensors, and other critical emissions components. The status of the drive cycle helps inform if all tests have been completed successfully or if certain tests are still pending.
						"""
					case .controlModuleVoltage: return """
						The Control Module Voltage refers to the voltage supplied to the engine control module (ECM) or powertrain control module (PCM). These control modules are responsible for managing various engine functions, such as fuel injection, ignition timing, and emissions control. The control module requires a stable voltage supply to ensure proper operation.

						If the voltage to the control module is too low or too high, it can lead to issues with engine performance, poor fuel efficiency, or even cause malfunctioning of sensors and other systems controlled by the module. Monitoring this voltage is essential to ensure the vehicle’s systems are operating within the proper electrical parameters.
						"""
					case .absoluteLoad: return """
						The Absolute Load is a measure of the engine's load in relation to the maximum load it is capable of handling. It reflects the engine’s power demand based on factors such as throttle position, engine speed (RPM), and air intake. The absolute load is useful for understanding the strain on the engine at any given moment, helping diagnose performance issues, fuel efficiency, and emissions.

						Absolute Load is typically given as a percentage of the maximum possible engine load (i.e., the maximum load the engine could handle at full throttle under ideal conditions).
						"""
					case .commandedEquivRatio: return """
						The Commanded Equivalence Ratio is a measure used by the engine control unit (ECU) to adjust the air-fuel mixture in the engine. It represents the target air-fuel ratio the ECU is trying to achieve, which is typically used to optimize engine performance and reduce emissions.

						In an internal combustion engine, the air-fuel ratio is crucial for combustion efficiency. The equivalence ratio is the ratio of the actual air-fuel ratio to the stoichiometric air-fuel ratio, which is the ideal ratio for complete combustion. The stoichiometric ratio for gasoline is typically 14.7:1 (14.7 parts air to 1 part fuel), meaning that when the air-fuel ratio is at this point, the engine is burning all the fuel with all the available oxygen.

						Commanded Equivalence Ratio < 1: Indicates a lean mixture, where there is more air than needed for the fuel.
						Commanded Equivalence Ratio > 1: Indicates a rich mixture, where there is more fuel than needed for the available air.

						The commanded equivalence ratio is used by the ECU to fine-tune fuel delivery based on sensor readings, such as oxygen sensors or mass air flow (MAF) sensors, in order to optimize engine performance and emissions.
						"""
					case .relativeThrottlePos: return """
						The Relative Throttle Position is a parameter that indicates the current position of the throttle valve in the intake system relative to the maximum throttle position. This value is crucial for understanding how much the throttle is being opened, which directly affects the amount of air entering the engine and, in turn, the engine's power output.

						A 0% throttle means the throttle valve is fully closed (idle or minimal acceleration).
						A 100% throttle means the throttle valve is fully open (wide-open throttle or full acceleration).

						This value is often used by the engine control unit (ECU) to adjust fuel delivery and ignition timing for optimal performance, emissions control, and fuel efficiency.
						"""
					case .ambientAirTemp: return """
						The Ambient Air Temperature refers to the temperature of the air surrounding the vehicle, which is typically measured by a temperature sensor located outside the vehicle, often near the front bumper or in the vehicle’s air intake system. This value can influence several aspects of engine performance, including fuel delivery and air intake calculations.

						In an OBD-II context, the ambient air temperature is used by the engine control unit (ECU) to adjust engine parameters based on the outside air conditions. For example, if the ambient temperature is cold, the ECU may adjust fuel injection and ignition timing to compensate for denser air, while in hot weather, adjustments might be made for thinner air.
						"""
					case .throttleActuator: return """
						The Throttle Actuator is a component in a vehicle's throttle system that controls the throttle valve's position based on input from the engine control unit (ECU). This actuator is typically an electric motor that adjusts the throttle valve's position, controlling the amount of air entering the engine and thus the engine’s power output. The throttle actuator is particularly common in drive-by-wire systems, where there is no physical connection between the accelerator pedal and the throttle body, as opposed to traditional cable-operated throttles.

						In modern vehicles, the throttle actuator works in conjunction with various sensors (like the throttle position sensor) to maintain smooth acceleration, fuel efficiency, and emissions control.
						"""
					case .runTimeMIL: return """
						The Run Time MIL (Malfunction Indicator Lamp) refers to the amount of time that the Malfunction Indicator Light (MIL), commonly known as the Check Engine Light (CEL), has been illuminated during a particular driving session since the vehicle was last started. This is important for diagnosing and troubleshooting issues in the vehicle's emissions system or engine performance.

						When the MIL light comes on, it indicates that the engine control unit (ECU) has detected an issue with one of the vehicle’s systems (e.g., fuel, exhaust, ignition). The Run Time MIL provides information on how long the light has been on, which can help a technician understand the severity or persistence of the problem.
						"""
					case .timeSinceDTCCleared: return """
						The Time Since DTC Cleared refers to the amount of time that has passed since the Diagnostic Trouble Codes (DTCs) were last cleared or reset in a vehicle's OBD-II system. This can be useful for understanding when the last diagnostic reset occurred and is often helpful in tracking how long the vehicle has been operating since any issues were cleared from the system.

						DTCs are generated by the engine control unit (ECU) when it detects an issue with the vehicle's performance or systems. These codes remain in the system until they are manually cleared (such as by using a diagnostic scanner or after certain repairs are made). The time since DTC cleared can be important when determining how long a vehicle has been running since any errors or faults were last addressed.
						"""
					case .maxValues: return "Max Values refer to the maximum values recorded by the vehicle’s ECU (Engine Control Unit) for certain parameters since the last DTC reset. This gives insight into how hard the engine has been worked or if it has experienced abnormal conditions."
					case .maxMAF: return "The Max MAF value represents the maximum air intake measured by the Mass Air Flow (MAF) sensor since the last time the Diagnostic Trouble Codes (DTCs) were cleared. It tells you how much air the engine has ever pulled in under peak load or speed conditions."
					case .fuelType: return "The Fuel Type PID tells you what type of fuel the vehicle is designed to run on, as reported by the Engine Control Unit (ECU). It’s a standardized identifier useful for diagnostics, emissions testing, and understanding how to interpret certain sensor values (since they can vary depending on the fuel type)."
					case .ethanoPercent: return "The Ethanol Percentage PID tells you what percentage of the fuel in the tank is ethanol. This is especially relevant for flex-fuel vehicles (FFVs) that can operate on varying blends of gasoline and ethanol (like E10, E15, or E85). Knowing this helps the ECU adjust fuel delivery and timing for optimal performance."
					case .evapVaporPressureAbs: return """
						The Evaporative Vapor Pressure (Absolute) PID provides the absolute pressure inside the EVAP (evaporative emissions) system. This value helps monitor the fuel system for leaks, vapor containment, and emissions compliance.

						It’s similar to other vapor pressure PIDs but reports absolute pressure, meaning it’s measured relative to a perfect vacuum (0 kPa), not atmospheric pressure.
						"""
					case .evapVaporPressureAlt: return """
						The Evap Vapor Pressure (Alternate) PID reports the evaporative system vapor pressure, but depending on the vehicle manufacturer, it may use a different scale, unit, or sensor range than the standard PID 53. This PID is typically used in vehicles where pressure is reported as a signed 16-bit value, and the units vary by manufacturer — most commonly reported in Pascals (Pa) or inches of H₂O.
						"""
					case .fuelRailPressureAbs: return "The Fuel Rail Pressure (Absolute) PID reports the actual pressure in the fuel rail relative to a perfect vacuum (0 kPa). This is useful for diagnosing fuel delivery issues, checking for fuel pump performance, and ensuring proper fuel injector function."
					case .relativeAccelPos: return "The Relative Accelerator Pedal Position PID shows how far the accelerator pedal is pressed relative to its minimum and maximum calibrated values, not just raw voltage or angle. This PID provides a normalized percentage (0–100%), making it easier to compare across vehicles."
					case .engineOilTemp: return "The Engine Oil Temperature PID provides the current temperature of the engine's lubricating oil, which is critical for monitoring engine health, thermal load, and lubrication performance. This sensor is not mandatory on all vehicles, so availability may vary."
					case .fuelInjectionTiming: return "The Fuel Injection Timing PID provides the timing of fuel injection relative to the crankshaft position, typically expressed in degrees before or after top dead center (BTDC/ATDC). This is essential for understanding combustion efficiency, engine performance, and diagnosing timing-related issues."
					case .fuelRate: return "The Fuel Flow Rate PID reports the rate at which fuel is being consumed by the engine. It is typically expressed in liters per hour (L/h) or gallons per hour (GPH), and is useful for monitoring fuel efficiency, consumption trends, and overall engine performance."
					case .emissionsReq: return "The Emissions Requirements PID provides information about the status of emissions system readiness and compliance with the vehicle’s emission control systems. This PID is often used to check if the vehicle is ready for an emissions inspection or if any emission-related issues are affecting the vehicle’s systems."
					default: return nil
				}
			default: return nil
		}
	}
}
