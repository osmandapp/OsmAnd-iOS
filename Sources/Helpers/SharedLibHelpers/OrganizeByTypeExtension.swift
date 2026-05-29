import OsmAndShared

extension OrganizeByType {
    var iosIconName: String {
        switch self {
        case .activity:          return "ic_custom_activity"
        case .duration:          return "ic_custom_time_span"
        case .timeInMotion:      return "ic_custom_time_in_motion"
        case .length:            return "ic_custom_length"
        case .yearOfCreation:    return "ic_custom_calendar_month"
        case .monthAndYear:      return "ic_custom_calendar_month"
        case .nearestCity:       return "ic_custom_city"
        case .maxSpeed:          return "ic_custom_speed_max"
        case .avgSpeed:          return "ic_custom_speed_average"
        case .maxAltitude:       return "ic_custom_altitude_max"
        case .avgAltitude:       return "ic_custom_altitude_average"
        case .uphill:            return "ic_custom_uphill"
        case .downhill:          return "ic_custom_downhill"
        case .sensorSpeedMax:    return "ic_custom_sensor_speed_outlined"
        case .sensorSpeedAvg:    return "ic_custom_sensor_speed_outlined"
        case .heartRateMax:      return "ic_custom_sensor_heart_rate_outlined"
        case .heartRateAvg:      return "ic_custom_sensor_heart_rate_outlined"
        case .cadenceMax:        return "ic_custom_sensor_cadence_outlined"
        case .cadenceAvg:        return "ic_custom_sensor_cadence_outlined"
        case .powerMax:          return "ic_custom_sensor_bicycle_power_outlined"
        case .powerAvg:          return "ic_custom_sensor_bicycle_power_outlined"
        case .tempMax:           return "ic_custom_sensor_thermometer"
        case .tempAvg:           return "ic_custom_sensor_thermometer"
        default:                 return "ic_custom_info_outlined"
        }
    }
}
