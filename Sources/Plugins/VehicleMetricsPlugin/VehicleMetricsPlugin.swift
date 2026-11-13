//
//  VehicleMetricsPlugin.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 09.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class VehicleMetricsPlugin: OAPlugin {
    
    let TRIP_RECORDING_VEHICLE_METRICS: OACommonStringList = OAAppSettings.sharedManager().registerStringListPreference("trip_recording_vehicle_metrics", defValue: nil).makeProfile().makeShared()
    var isOBDSimulatorConnected = false
    
    private let settings = OAAppSettings.sharedManager()
    
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

        DeviceHelper.shared.disconnectDevices(only: .OBD_VEHICLE_METRICS, reason: .pluginOff)
        DeviceHelper.shared.disconnectOBDSimulator()
    }
    
    override func update(_ location: CLLocation) {
        OBDDataComputer.shared.registerLocation(l: OBDDataComputer.OBDLocation(time: Int64(location.timestamp.timeIntervalSince1970), latLon: KLatLon(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)))
    }
    
    override func getWidgetIds() -> [String] {
        [WidgetType.OBDSpeed.id, WidgetType.OBDRpm.id, WidgetType.OBDEngineRuntime.id, WidgetType.OBDFuelPressure.id, WidgetType.OBDAirIntakeTemp.id, WidgetType.engineOilTemperature.id, WidgetType.OBDAmbientAirTemp.id, WidgetType.OBDBatteryVoltage.id, WidgetType.OBDEngineCoolantTemp.id, WidgetType.OBDRemainingFuel.id, WidgetType.OBDCalculatedEngineLoad.id, WidgetType.OBDThrottlePosition.id, WidgetType.OBDFuelConsumption.id, WidgetType.OBDAltBatteryVoltage.id]
    }

    override func createWidgets(_ delegate: any WidgetRegistrationDelegate, appMode: OAApplicationMode, widgetParams: [AnyHashable: Any]?) {
        let creator = WidgetInfoCreator(appMode: appMode,
                                        screenLayoutMode: delegate.screenLayoutMode,
                                        preferenceLayoutMode: delegate.preferenceLayoutMode)
        let widgetTypeArray: [WidgetType] = [.OBDSpeed, .OBDRpm, .OBDEngineRuntime, .OBDFuelPressure, .OBDAirIntakeTemp, .engineOilTemperature, .OBDAmbientAirTemp, .OBDBatteryVoltage, .OBDEngineCoolantTemp, .OBDRemainingFuel, .OBDCalculatedEngineLoad, .OBDThrottlePosition, .OBDFuelConsumption, .OBDAltBatteryVoltage]
        for widgetType in widgetTypeArray {
            let params = creator.widgetParams(for: widgetType, widgetParams: widgetParams as? [String: Any])
            guard let widget = createMapWidget(forParams: widgetType, customId: nil, appMode: appMode, widgetParams: params), let info = creator.createWidgetInfo(widget: widget) else { continue }
            delegate.addWidget(info)
        }
    }
    
    override func createMapWidget(forParams widgetType: WidgetType, customId: String?, appMode: OAApplicationMode, widgetParams: [AnyHashable: Any]?) -> OABaseWidgetView? {
        let params = widgetParams as? [String: Any]
        switch widgetType {
        case .OBDFuelConsumption:
            return OBDFuelConsumptionWidget(customId: customId, widgetType: widgetType, appMode: appMode, widgetParams: params)
        case .OBDRemainingFuel:
            return OBDRemainingFuelWidget(customId: customId, widgetType: widgetType, appMode: appMode, widgetParams: params)
        case .OBDSpeed, .OBDRpm, .OBDEngineRuntime, .OBDFuelPressure, .OBDAirIntakeTemp, .engineOilTemperature, .OBDAmbientAirTemp, .OBDBatteryVoltage, .OBDEngineCoolantTemp, .OBDCalculatedEngineLoad, .OBDThrottlePosition, .OBDAltBatteryVoltage:
            return OBDTextWidget(customId: customId, widgetType: widgetType, appMode: appMode, widgetParams: params)
        default:
            return nil
        }
    }
    
    override func getTrackPointsAnalyser() -> (any GpxTrackAnalysisTrackPointsAnalyser)? {
        VehicleTrackPointsAnalyser()
    }
    
    override func getAvailableGPXDataSetTypes(_ analysis: GpxTrackAnalysis, availableTypes: NSMutableArray) {
        VehicleMetricAttributesUtils.getAvailableGPXDataSetTypes(analysis: analysis, out: availableTypes)
    }
    
    override func getOrderedLineDataSet(chart: LineChartView, analysis: GpxTrackAnalysis, graphType: GPXDataSetType, axisType: GPXDataSetAxisType, calcWithoutGaps: Bool, useRightAxis: Bool) -> GpxUIHelper.OrderedLineDataSet? {
        guard graphType.getTypeGroup() == .vehicleMetrics else { return nil }
        return VehicleMetricAttributesUtils.createVehicleMetricsDataSet(plugin: self, chart: chart, analysis: analysis, graphType: graphType, axisType: axisType, useRightAxis: useRightAxis, drawFilled: true, calcWithoutGaps: calcWithoutGaps)
    }
    
    func getWidgetConvertedValue(type: OBDDataComputer.OBDTypeWidget, data: Any?) -> Any? {
        let mode = settings.applicationMode.get()
        switch type {
        case .speed:
            return getConvertedSpeed(data.asFloat, mode: mode)
        case .fuelLeftKm:
            return getConvertedDistance(data.asFloat, mode: mode)
        case .temperatureIntake, .engineOilTemperature, .temperatureAmbient, .temperatureCoolant:
            return getConvertedTemperature(data: data.asFloat, mode: mode)
        case .fuelLeftLiter:
            return getFormattedVolume(data.asFloat, mode: mode)
        case .fuelConsumptionRateLiterHour:
            return getFormatVolumePerHour(literPerHour: data.asFloat, mode: mode)
        case .fuelConsumptionRateLiterKm:
            return getFormatVolumePerDistance(litersPer100km: data.asFloat, mode: mode)
        case .engineRuntime:
            return getFormattedTime(time: data.asInt)
        case .fuelConsumptionRateSensor, .batteryVoltage, .adapterBatteryVoltage, .fuelType, .fuelConsumptionRatePercentHour, .fuelLeftPercent, .calculatedEngineLoad, .throttlePosition, .vin, .fuelPressure, .rpm:
            return data
        case .fuelConsumptionRateMPerLiter:
            return getFormatDistancePerVolume(metersPerLiter: data.asFloat, mode: mode)
        default:
            return data
        }
    }
    
    func getWidgetUnit(_ computerWidget: OBDDataComputer.OBDTypeWidget, appMode: OAApplicationMode? = nil) -> String? {
        let mode = appMode ?? settings.applicationMode.get()
        switch computerWidget {
        case .speed:
            return getSpeedUnit(mode)
        case .rpm:
            return localizedString("rpm_unit")
        case .fuelPressure:
            return localizedString("kpa_unit")
        case .fuelLeftKm:
            return getDistanceUnit(mode)
        case .calculatedEngineLoad,
                .throttlePosition,
                .fuelLeftPercent:
            return localizedString("percent_unit")
        case .fuelLeftLiter:
            return OAVolumeConstant.getUnitSymbol(settings.volumeUnits.get(mode))
        case .fuelConsumptionRatePercentHour:
            return localizedString("percent_hour")
        case .fuelConsumptionRateLiterHour:
            return getFormatVolumePerHourUnit(mode)
        case .fuelConsumptionRateSensor:
            return localizedString("liter_per_hour")
        case .temperatureCoolant,
                .temperatureIntake,
                .engineOilTemperature,
                .temperatureAmbient:
            return OATemperatureConstant.getUnitSymbol(getTemperatureUnit(mode))
        case .batteryVoltage, .adapterBatteryVoltage:
            return localizedString("unit_volt")
        case .fuelType, .engineRuntime, .vin:
            return nil
        case .fuelConsumptionRateLiterKm:
            return getFormatVolumePerDistanceUnit(mode)
        case .fuelConsumptionRateMPerLiter:
            return getFormatDistancePerVolumeUnit(mode)
        default:
            return nil
        }
    }
    
    func getWidgetValue(computerWidget: OBDDataComputer.OBDComputerWidget, appMode: OAApplicationMode? = nil) -> String {
        let mode = appMode ?? settings.applicationMode.get()
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
            convertedData = getConvertedSpeed(data.asFloat, mode: mode)
            // Float
        case .fuelLeftKm:
            // Float
            convertedData = getConvertedDistance(data.asFloat, mode: mode)
        case .temperatureIntake, .engineOilTemperature, .temperatureAmbient, .temperatureCoolant:
            // Float
            convertedData = getConvertedTemperature(data: data.asFloat, mode: mode)
        case .fuelLeftLiter:
            // Float
            convertedData = getFormattedVolume(data.asFloat, mode: mode)
        case .fuelConsumptionRateLiterHour:
            // Float
            convertedData = getFormatVolumePerHour(literPerHour: data.asFloat, mode: mode)
        case .fuelConsumptionRateLiterKm:
            // Float
            convertedData = getFormatVolumePerDistance(litersPer100km: data.asFloat, mode: mode)
        case .engineRuntime:
            // String
            convertedData = getFormattedTime(time: data.asInt)
        case .rpm, .fuelPressure:
            // Int
            convertedData = data.asInt

        case .fuelConsumptionRateSensor,
             .batteryVoltage,
             .adapterBatteryVoltage,
             .fuelConsumptionRatePercentHour,
             .fuelLeftPercent,
             .calculatedEngineLoad,
             .throttlePosition:
            // Float
            convertedData = data.asFloat
        case .fuelConsumptionRateMPerLiter:
            convertedData = getFormatDistancePerVolume(metersPerLiter: data.asFloat, mode: mode)
        default:
            break
        }
        
        return computerWidget.type.formatter.format(v: convertedData)
    }
    
    func reconnectOBDIfNeeded() {
        let deviceHelper = DeviceHelper.shared
        let connectedDevices = deviceHelper.connectedDevices(ofType: .OBD_VEHICLE_METRICS).filter({ !$0.isSimulator })
        
        guard connectedDevices.isEmpty else {
            return
        }
        
        guard let pairedDevices = deviceHelper.getSettingsForPairedDevices(matching: .OBD_VEHICLE_METRICS) else { return
        }
        
        let filteredPairedDevices = pairedDevices.filter { !$0.deviceId.lowercased().contains("simulator") }
        
        guard !filteredPairedDevices.isEmpty else {
            return
        }
        
        let disconnectedDevices = deviceHelper.getDisconnectedDevices(for: filteredPairedDevices).filter { $0.deviceType == .OBD_VEHICLE_METRICS }
        
        guard !disconnectedDevices.isEmpty else {
            return
        }
        
        deviceHelper.updateConnected(devices: disconnectedDevices)
    }
}

// MARK: - Formatters
extension VehicleMetricsPlugin {
    
    private func getSpeedUnit(_ mode: OAApplicationMode) -> String {
        OASpeedConstant.toShortString(settings.speedSystem.get(mode))
    }
    
    private func getDistanceUnit(_ mode: OAApplicationMode) -> String {
        switch settings.metricSystem.get(mode) {
        case .KILOMETERS_AND_METERS:
            return localizedString("km")
        case .NAUTICAL_MILES_AND_METERS, .NAUTICAL_MILES_AND_FEET:
            return localizedString("nm")
        default:
            return localizedString("mile")
        }
    }
    
    private func getTemperatureUnit(_ mode: OAApplicationMode) -> EOATemperatureConstant {
        settings.getTemperatureUnit(for: mode)
    }
    
    private func getFormatVolumePerHourUnit(_ mode: OAApplicationMode) -> String? {
        let volumeUnit = OAVolumeConstant.getUnitSymbol(settings.volumeUnits.get(mode))
        
        return String(format: localizedString("ltr_or_rtl_combine_via_slash"),
                      volumeUnit,
                      localizedString("int_hour"))
    }
    
    private func getFormatVolumePerDistanceUnit(_ mode: OAApplicationMode) -> String {
        let volumeUnit = OAVolumeConstant.getUnitSymbol(settings.volumeUnits.get(mode))
        return String(format: localizedString("ltr_or_rtl_combine_via_slash"), volumeUnit, "100\(getDistanceUnit(mode))")
    }
    
    private func getFormatDistancePerVolumeUnit(_ mode: OAApplicationMode) -> String {
        let mc = settings.metricSystem.get(mode)
        let distanceUnit: String
        let isMileMetrics = [EOAMetricsConstant.MILES_AND_FEET, EOAMetricsConstant.MILES_AND_YARDS, EOAMetricsConstant.MILES_AND_METERS].contains(where: { mc == $0 })
        
        if isMileMetrics {
            distanceUnit = localizedString("mile")
        } else if [.NAUTICAL_MILES_AND_FEET, .NAUTICAL_MILES_AND_METERS].contains(where: { mc == $0 }) {
            distanceUnit = localizedString("nm")
        } else {
            distanceUnit = localizedString("km")
        }
        
        let volume = settings.volumeUnits.get(mode)
        let volumeUnit = OAVolumeConstant.getUnitSymbol(volume)
        
        if isMileMetrics && [EOAVolumeConstant.US_GALLONS, EOAVolumeConstant.IMPERIAL_GALLONS].contains(where: { volume == $0 }) {
            return localizedString("mpg")
        } else {
            return String(format: localizedString("ltr_or_rtl_combine_via_slash"), distanceUnit, volumeUnit)
        }
    }
    
    private func getFormatDistancePerVolume(metersPerLiter: Float, mode: OAApplicationMode) -> Float {
        let mc = settings.metricSystem.get(mode)
        let volumeUnit = settings.volumeUnits.get(mode)
        return getFormatDistancePerVolume(metersPerLiter: metersPerLiter, mc: mc, volumeUnit: volumeUnit)
    }
    
    private func getFormatDistancePerVolume(metersPerLiter: Float,
                                            mc: EOAMetricsConstant,
                                            volumeUnit: EOAVolumeConstant) -> Float {
        let litersInVolume = OAOsmAndFormatter.convertLiterToVolumeUnit(withVolumeUnit: volumeUnit, value: 1)
        let distanceInMeters: Float
        switch mc {
        case .MILES_AND_YARDS, .MILES_AND_FEET, .MILES_AND_METERS:
            distanceInMeters = Float(METERS_IN_ONE_MILE)
            case .NAUTICAL_MILES_AND_FEET, .NAUTICAL_MILES_AND_METERS:
            distanceInMeters = Float(METERS_IN_ONE_NAUTICALMILE)
        default:
            distanceInMeters = Float(METERS_IN_KILOMETER)
        }
        return metersPerLiter / litersInVolume / distanceInMeters
    }
    
    private func getFormatVolumePerDistance(litersPer100km: Float, mode: OAApplicationMode) -> Float {
        let volumeUnit = settings.volumeUnits.get(mode)
        let volumeResult = OAOsmAndFormatter.convertLiterToVolumeUnit(withVolumeUnit: volumeUnit, value: litersPer100km)
        
        let metricConstant = settings.metricSystem.get(mode)
        
        switch metricConstant {
        case EOAMetricsConstant.MILES_AND_YARDS,
             EOAMetricsConstant.MILES_AND_FEET,
             EOAMetricsConstant.MILES_AND_METERS:
            return volumeResult * Float(METERS_IN_ONE_MILE) / 1000
            
        case EOAMetricsConstant.NAUTICAL_MILES_AND_FEET,
             EOAMetricsConstant.NAUTICAL_MILES_AND_METERS:
            return volumeResult * Float(METERS_IN_ONE_NAUTICALMILE) / 1000
            
        default:
            return volumeResult
        }
    }
    
    private func getFormattedTime(time: Int) -> String {
        OAOsmAndFormatter.getFormattedTimeRuntime(time)
    }

    private func getFormatVolumePerHour(literPerHour: Float, mode: OAApplicationMode) -> Float {
        let volumeUnit = settings.volumeUnits.get(mode)
        
        return OAOsmAndFormatter.convertLiterToVolumeUnit(withVolumeUnit: volumeUnit, value: literPerHour)
    }
    
    private func getConvertedTemperature(data: Float, mode: OAApplicationMode) -> Float {
        let temperature = data
        switch getTemperatureUnit(mode) {
        case .CELSIUS, .SYSTEM_DEFAULT:
            return temperature
        case .FAHRENHEIT:
            return temperature * 1.8 + 32
        default:
            return temperature
        }
    }
    
    private func getFormattedVolume(_ data: Float, mode: OAApplicationMode) -> Float {
        let volumeUnit = settings.volumeUnits.get(mode)
        return OAOsmAndFormatter.convertLiterToVolumeUnit(withVolumeUnit: volumeUnit, value: data)
    }
    
    private func getConvertedSpeed(_ speed: Float, mode: OAApplicationMode) -> Float {
        let speedInMetersPerSecond: Float = speed * 1000 / 3600
        let formattedAverageSpeed = OAOsmAndFormatter.getFormattedSpeed(speedInMetersPerSecond, mode: mode).components(separatedBy: " ")
        guard let value = formattedAverageSpeed.first, let floatValue = Float(value) else {
            return 0
        }
        return floatValue
    }

    private func getConvertedDistance(_ distance: Float, mode: OAApplicationMode) -> Float {
        let formattedValue = OAOsmAndFormatter.getFormattedDistance(distance, mode: mode).components(separatedBy: " ")
        
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
        
        guard OAIAPHelper.isVehicleMetricsAvailable() else { return }
        
        let mode = settings.applicationMode.get()
        let commandNames = TRIP_RECORDING_VEHICLE_METRICS.get(mode) ?? []
        let selectedCommands = Set(commandNames.compactMap { OBDCommand.companion.getCommand(name: $0) })

        guard !selectedCommands.isEmpty,
              let rawData = OBDService.shared.obdDispatcher?.getRawData() as? [OBDCommand: Any] else {
            return
        }
        
        var jsonDict: [String: String] = [:]
        let prefix = GpxUtilities().OSMAND_EXTENSIONS_PREFIX

        rawData.forEach { command, dataField in
            guard selectedCommands.contains(command),
                  let tag = command.gpxTag,
                  let value = (dataField as? OBDDataField<AnyObject>)?.value as? NSNumber else {
                return
            }

            jsonDict[prefix + tag] = value.stringValue
        }
        
        guard !jsonDict.isEmpty else { return }

        do {
            let jsonData = try JSONEncoder().encode(jsonDict)
            json.append(jsonData)
        } catch {
            NSLog("VehicleMetricsPlugin -> failed to encode sensor data: \(error.localizedDescription)")
        }
    }
}
