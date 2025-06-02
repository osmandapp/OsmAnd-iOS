//
//  VehicleMetricsPlugin.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 09.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class VehicleMetricsPlugin: OAPlugin {
    
//    static let shared = VehicleMetricsPlugin()
//    
//    private override init() {
//    }
    
    override func getId() -> String? {
        "net.osmand.maps.inapp.addon.vehicle_metrics"
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
        // TODO:
    }
    
    override func update(_ location: CLLocation) {
        OBDDataComputer.shared.registerLocation(l: OBDDataComputer.OBDLocation(time: Int64(location.timestamp.timeIntervalSince1970), latLon: KLatLon.init(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)))
    }
    
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
        // FIXME: "°C" or "°F" - Convert  UnitTemperature.current() ?
        return formatter.string(from: UnitTemperature.celsius)
    }
    
    private func getFormatVolumePerHourUnit() -> String? {
        guard let volumeUnit = OAVolumeConstant.getUnitSymbol(OAAppSettings.sharedManager().volumeUnits.get()) else {
            return nil
        }
        
        return String(format: localizedString("ltr_or_rtl_combine_via_slash"),
                      volumeUnit,
                      localizedString("int_hour"))
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
}
