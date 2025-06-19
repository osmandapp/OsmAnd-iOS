//
//  VehicleMetricsPlugin.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 09.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class VehicleMetricsPlugin: OAPlugin {
    
    // FIXME: delimiter ";"
    let TRIP_RECORDING_VEHICLE_METRICS: OACommonStringList = OAAppSettings.sharedManager().registerStringListPreference("trip_recording_vehicle_metrics", defValue: nil).makeProfile().makeShared()
    
    override func getId() -> String? {
        kInAppId_Addon_Vehicle_Metrics
    }
    
    override func getName() -> String {
        localizedString("vehicle_metrics_obd_ii")
    }
    
    override func getDescription() -> String {
        localizedString("obd_plugin_description")
    }
    
    override func disable() {
        super.disable()
        DeviceHelper.shared.disconnectAllOBDDevices(reason: .pluginOff)
    }
    
    override func update(_ location: CLLocation) {
        OBDDataComputer.shared.registerLocation(l: OBDDataComputer.OBDLocation(time: Int64(location.timestamp.timeIntervalSince1970), latLon: KLatLon(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)))
    }
    
    func getWidgetUnit(_ computerWidget: OBDDataComputer.OBDTypeWidget) -> String? {
        switch computerWidget {
        case .speed:
            return getSpeedUnit()
        case .rpm:
            return localizedString("rpm_unit")
        case .fuelPressure:
            return localizedString("kpa_unit")
        case .fuelLeftKm:
            return getDistanceUnit()
        case .calculatedEngineLoad,
                .throttlePosition,
                .fuelLeftPercent:
            return localizedString("percent_unit")
        case .fuelLeftLiter:
            return OAVolumeConstant.getUnitSymbol(OAAppSettings.sharedManager().volumeUnits.get())
        case .fuelConsumptionRatePercentHour:
            return localizedString("percent_hour")
        case .fuelConsumptionRateLiterHour:
            return getFormatVolumePerHourUnit()
        case .fuelConsumptionRateSensor:
            return localizedString("liter_per_hour")
        case .temperatureCoolant,
                .temperatureIntake,
                .engineOilTemperature,
                .temperatureAmbient:
            return getTemperatureUnit()
        case .batteryVoltage:
            return localizedString("unit_volt")
        case .fuelType, .engineRuntime, .vin:
            return nil
        default:
            return nil
        }
    }
    
    func getWidgetValue(computerWidget: OBDDataComputer.OBDComputerWidget) -> String {
        let data = computerWidget.computeValue()

        if let dataStr = data as? String, dataStr == "N/A" {
            return "N/A"
        } else if data == nil {
            return "-"
        }

        if computerWidget.type.requiredCommand == OBDCommand.obdFuelLevelCommand {
            if let floatVal = data as? Float, floatVal.isNaN {
                return "-"
            } else if let doubleVal = data as? Double, doubleVal.isNaN {
                return "-"
            }
        }

        var convertedData: Any = data ?? "-"

        switch computerWidget.type {
        case .speed:
            // Float
            convertedData = getConvertedSpeed(data.asFloat)
            // Float
        case .fuelLeftKm:
            // Float
            convertedData = getConvertedDistance(data.asFloat)
        case .temperatureIntake, .engineOilTemperature, .temperatureAmbient, .temperatureCoolant:
            // Float
            convertedData = getConvertedTemperature(data: data.asFloat)
        case .fuelLeftLiter:
            // Float
            convertedData = getFormattedVolume(data.asFloat)
        case .fuelConsumptionRateLiterHour:
            // Float
            convertedData = getFormatVolumePerHour(literPerHour: data.asFloat)
        case .fuelConsumptionRateLiterKm:
            // Float
            convertedData = getFormatVolumePerDistance(litersPer100km: data.asFloat)
        case .engineRuntime:
            // String
            convertedData = getFormattedTime(time: data.asInt)
        case .rpm, .fuelPressure:
            // Int
            convertedData = data.asInt

        case .fuelConsumptionRateSensor,
             .batteryVoltage,
             .fuelConsumptionRatePercentHour,
             .fuelLeftPercent,
             .calculatedEngineLoad,
             .throttlePosition:
            // Float
            convertedData = data.asFloat
        default:
            break
        }
        
        return computerWidget.type.formatter.format(v: convertedData)
    }
}

// MARK: - Formatters
extension VehicleMetricsPlugin {
    
    private func getSpeedUnit() -> String {
        OASpeedConstant.toShortString(OAAppSettings.sharedManager().speedSystem.get())
    }
    
    private func getDistanceUnit() -> String {
        switch OAAppSettings.sharedManager().metricSystem.get() {
        case .KILOMETERS_AND_METERS:
            return localizedString("km")
        case .NAUTICAL_MILES_AND_METERS, .NAUTICAL_MILES_AND_FEET:
            return localizedString("nm")
        default:
            return localizedString("mile")
        }
    }
    
    private func getTemperatureUnit() -> String {
        let formatter = MeasurementFormatter()
        formatter.locale = .autoupdatingCurrent
        return formatter.string(from: UnitTemperature.current())
    }
    
    private func getFormatVolumePerHourUnit() -> String? {
        guard let volumeUnit = OAVolumeConstant.getUnitSymbol(OAAppSettings.sharedManager().volumeUnits.get()) else {
            return nil
        }
        
        return String(format: localizedString("ltr_or_rtl_combine_via_slash"),
                      volumeUnit,
                      localizedString("int_hour"))
    }
    
    private func getFormatVolumePerDistance(litersPer100km: Float) -> Float {
        let volumeUnit = OAAppSettings.sharedManager().volumeUnits.get()
        let volumeResult = OAOsmAndFormatter.convertLiterToVolumeUnit(withVolumeUnit: volumeUnit, value: litersPer100km)
        
        let metricConstant = OAAppSettings.sharedManager().metricSystem.get()
        
        switch metricConstant {
        case EOAMetricsConstant.MILES_AND_YARDS,
             EOAMetricsConstant.MILES_AND_FEET,
             EOAMetricsConstant.MILES_AND_METERS:
            return volumeResult * Float(METERS_IN_ONE_MILE)
            
        case EOAMetricsConstant.NAUTICAL_MILES_AND_FEET,
             EOAMetricsConstant.NAUTICAL_MILES_AND_METERS:
            return volumeResult * Float(METERS_IN_ONE_NAUTICALMILE)
            
        default:
            return volumeResult
        }
    }
    
    private func getFormattedTime(time: Int) -> String {
        OAOsmAndFormatter.getFormattedTimeRuntime(time)
    }

    private func getFormatVolumePerHour(literPerHour: Float) -> Float {
        let volumeUnit = OAAppSettings.sharedManager().volumeUnits.get()
        
        return OAOsmAndFormatter.convertLiterToVolumeUnit(withVolumeUnit: volumeUnit, value: literPerHour)
    }
    
    private func getConvertedTemperature(data: Float) -> Float {
        let temperature = data
        if UnitTemperature.current() == .celsius {
            return temperature
        } else {
            return temperature * 1.8 + 32
        }
    }
    
    private func getFormattedVolume(_ data: Float) -> Float {
        let volumeUnit = OAAppSettings.sharedManager().volumeUnits.get()
        return OAOsmAndFormatter.convertLiterToVolumeUnit(withVolumeUnit: volumeUnit, value: data)
    }
    
    private func getConvertedSpeed(_ speed: Float) -> Float {
        let speedInMetersPerSecond: Float = speed * 1000 / 3600
        let formattedAverageSpeed = OAOsmAndFormatter.getFormattedSpeed(speedInMetersPerSecond).components(separatedBy: " ")
        guard let value = formattedAverageSpeed.first, let floatValue = Float(value) else {
            return 0
        }
        return floatValue
    }

    private func getConvertedDistance(_ distance: Float) -> Float {
        let formattedValue = OAOsmAndFormatter.getFormattedDistance(distance).components(separatedBy: " ")
        
        guard let value = formattedValue.first, let floatValue = Float(value) else {
            return 0
        }
        return floatValue
    }
}

// MARK: - Trip recording

extension VehicleMetricsPlugin {
    override func attachAdditionalInfo(toRecordedTrack location: CLLocation, json: NSMutableData) {
        super.attachAdditionalInfo(toRecordedTrack: location, json: json)
        guard OAIAPHelper.isVehicleMetricsAvailable() else {
            return
        }
        
        let mode = OAAppSettings.sharedManager().applicationMode.get()
        let commandNames: [String]? = TRIP_RECORDING_VEHICLE_METRICS.get(mode)
        let selectedCommands: [OBDCommand] = commandNames?.compactMap { OBDCommand.companion.getCommand(name: $0) } ?? []
        
        guard !selectedCommands.isEmpty,
              let rawData = OBDService.shared.obdDispatcher?.getRawData() as? [OBDCommand: Any] else {
            return
        }

        for (command, dataField) in rawData {
            guard selectedCommands.contains(command),
                  let tag = command.gpxTag,
                  // FIXME:
                  let value = dataField as? OBDDataField<AnyObject> else {
                continue
            }
            
            let key = GpxUtilities().OSMAND_EXTENSIONS_PREFIX + tag
            if let jsonObject = try? JSONSerialization.jsonObject(with: json as Data) as? NSMutableDictionary {
                jsonObject[key] = value.value
                if let updatedData = try? JSONSerialization.data(withJSONObject: jsonObject, options: []) {
                    json.setData(updatedData)
                }
            }
        }
    }
}

//
//override func attachAdditionalInfoToRecordedTrack(location: Location, json: JSONObject) {
//    super.attachAdditionalInfoToRecordedTrack(location, json)
//
//    let mode = appInstance.settings.applicationMode
//    let commandNames: [String]? = TRIP_RECORDING_VEHICLE_METRICS.getStringsListForProfile(mode)
//
//    // Используем compactMap для фильтрации nil и ?? для предоставления пустого массива
//    let selectedCommands: [OBDCommand] = commandNames?.compactMap {
//        OBDCommand.getCommand($0)
//    } ?? []
//
//    // Проверяем, что selectedCommands не пуст и метрики доступны
//    if !selectedCommands.isEmpty && InAppPurchaseUtils.isVehicleMetricsAvailable(appInstance) {
//        let rawData = obdDispatcherInstance.getRawData()
//
//        // Используем 'if let' для безопасной распаковки rawData
//        if let data = rawData {
//            // Перебираем ключи (команды) в rawData
//            for command in data.keys {
//                // Пропускаем команды, которые не выбраны
//                guard selectedCommands.contains(command) else {
//                    continue
//                }
//
//                let dataField = data[command] // dataField будет иметь тип DataField?
//
//                // Проверяем, существует ли gpxTag у команды
//                if let gpxTag = command.gpxTag {
//                    let combinedTag = GpxUtilities.OSMAND_EXTENSIONS_PREFIX + gpxTag
//                    json.put(combinedTag, dataField?.value) // Добавляем в JSON
//                }
//            }
//        }
//    }
//}
