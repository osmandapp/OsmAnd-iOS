import UIKit
import OsmAndShared

extension OrganizeByType {
    var image: UIImage? {
        switch self {
        case .activity:          return .templateImageNamed("ic_custom_activity")
        case .duration:          return .templateImageNamed("ic_custom_time_span")
        case .timeInMotion:      return .templateImageNamed("ic_custom_time_in_motion")
        case .length:            return .templateImageNamed("ic_custom_length")
        case .yearOfCreation:    return .templateImageNamed("ic_custom_calendar_month")
        case .monthAndYear:      return .templateImageNamed("ic_custom_calendar_month")
        case .nearestCity:       return .templateImageNamed("ic_custom_city")
        case .country:           return .templateImageNamed("ic_custom_globe")
        case .maxSpeed:          return .templateImageNamed("ic_custom_speed_max")
        case .avgSpeed:          return .templateImageNamed("ic_custom_speed_average")
        case .maxAltitude:       return .templateImageNamed("ic_custom_altitude_max")
        case .avgAltitude:       return .templateImageNamed("ic_custom_altitude_average")
        case .uphill:            return .templateImageNamed("ic_custom_uphill")
        case .downhill:          return .templateImageNamed("ic_custom_downhill")
        case .sensorSpeedMax:    return .templateImageNamed("ic_custom_sensor_speed_outlined")
        case .sensorSpeedAvg:    return .templateImageNamed("ic_custom_sensor_speed_outlined")
        case .heartRateMax:      return .templateImageNamed("ic_custom_sensor_heart_rate_outlined")
        case .heartRateAvg:      return .templateImageNamed("ic_custom_sensor_heart_rate_outlined")
        case .cadenceMax:        return .templateImageNamed("ic_custom_sensor_cadence_outlined")
        case .cadenceAvg:        return .templateImageNamed("ic_custom_sensor_cadence_outlined")
        case .powerMax:          return .templateImageNamed("ic_custom_sensor_bicycle_power_outlined")
        case .powerAvg:          return .templateImageNamed("ic_custom_sensor_bicycle_power_outlined")
        case .tempMax:           return .templateImageNamed("ic_custom_sensor_thermometer")
        case .tempAvg:           return .templateImageNamed("ic_custom_sensor_thermometer")
        default:                 return .templateImageNamed("ic_custom_info_outlined")
        }
    }
}
