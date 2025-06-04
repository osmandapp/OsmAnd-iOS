//
//  VehicleMetricsPlugin.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 09.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class VehicleMetricsPlugin: OAPlugin {
    
    override func getId() -> String? {
        kInAppId_Addon_Vehicle_Metrics
    }
    
    override func getName() -> String {
        localizedString("vehicle_metrics_obd_ii")
    }
    
    override func getDescription() -> String {
        localizedString("obd_plugin_description")
    }
    
    override func setEnabled(_ enabled: Bool) {
        super.setEnabled(enabled)
        // TODO:
    }
    
    override func disable() {
        super.disable()
        DeviceHelper.shared.disconnectAllOBDDevices(reason: .pluginOff)

    }
    
    override func isEnabled() -> Bool {
        super.isEnabled() && OAIAPHelper.isVehicleMetricsPurchased()
    }
//
//    - (void)setEnabled:(BOOL)enabled
//    {
//        [super setEnabled:enabled];
//        if (OsmAndApp.instance.initialized)
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [[OARootViewController instance] updateLeftPanelMenu];
//            });
//    }
//
    
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
            convertedData = getConvertedSpeed((data as? NSNumber) ?? 0)
        case .fuelLeftKm:
            convertedData = getConvertedDistance(data as! Double)
        case .temperatureIntake, .engineOilTemperature, .temperatureAmbient, .temperatureCoolant:
            convertedData = getConvertedTemperature(data: data as! NSNumber)
        case .fuelLeftLiter:
            convertedData = getFormattedVolume(data as! NSNumber)
        case .fuelConsumptionRateLiterHour:
            convertedData = getFormatVolumePerHour(literPerHour: data as! NSNumber)
        case .fuelConsumptionRateLiterKm:
            convertedData = getFormatVolumePerDistance(litersPer100km: data as! NSNumber)
        case .engineRuntime:
            convertedData = getFormattedTime(time: data as! Int)
//        case .fuelConsumptionRateSensor,
//            .batteryVoltage,
//             .fuelType,
//             .fuelConsumptionRatePercentHour,
//             .fuelLeftPercent,
//             .calculatedEngineLoad,
//             .throttlePosition,
//             .vin,
//             .fuelPressure,
//             .rpm:
//            convertedData = convertedData
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
    
    private func getFormatVolumePerDistance(litersPer100km: NSNumber) -> Float {
        let volumeUnit = OAAppSettings.sharedManager().volumeUnits.get()
        let volumeResult = OAOsmAndFormatter.convertLiterToVolumeUnit(withVolumeUnit: volumeUnit, value: litersPer100km.floatValue)
        
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

    private func getFormatVolumePerHour(literPerHour: NSNumber) -> Float {
        let volumeUnit = OAAppSettings.sharedManager().volumeUnits.get()
        
        return OAOsmAndFormatter.convertLiterToVolumeUnit(withVolumeUnit: volumeUnit, value: literPerHour.floatValue)
    }
    
    private func getConvertedTemperature(data: NSNumber) -> Float {
        let temperature = data.floatValue
        if UnitTemperature.current() == .celsius {
            return temperature
        } else {
            return temperature * 1.8 + 32
        }
    }
    
    private func getFormattedVolume(_ data: NSNumber) -> Float {
        let volumeUnit = OAAppSettings.sharedManager().volumeUnits.get()
        return OAOsmAndFormatter.convertLiterToVolumeUnit(withVolumeUnit: volumeUnit, value: data.floatValue)
    }
    
    
    private func getConvertedSpeed(_ speed: NSNumber) -> Float {
        let speedInMetersPerSecond: Float = speed.floatValue * 1000 / 3600
        let formattedAverageSpeed = OAOsmAndFormatter.getFormattedSpeed(speedInMetersPerSecond).components(separatedBy: " ")
        guard let value = formattedAverageSpeed.first, let floatValue = Float(value) else {
            return 0
        }
        return floatValue
    }

    private func getConvertedDistance(_ distance: Double) -> Float {
        let formattedValue = OAOsmAndFormatter.getFormattedDistance(Float(distance)).components(separatedBy: " ")
        
        guard let value = formattedValue.first, let floatValue = Float(value) else {
            return 0
        }
        return floatValue
    }
    
}
