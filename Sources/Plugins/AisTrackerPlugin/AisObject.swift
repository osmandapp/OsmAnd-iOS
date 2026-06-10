import CoreLocation
import Foundation

@objc enum AisObjType: Int {
    case vessel
    case vesselSport
    case vesselFast
    case vesselPassenger
    case vesselFreight
    case vesselCommercial
    case vesselAuthorities
    case vesselSar
    case vesselOther
    case landStation
    case airplane
    case sart
    case aton
    case atonVirtual
    case invalid
}

enum AisObjectConstants {
    static let invalidHeading = 511
    static let invalidNavStatus = 15
    static let invalidManeuverIndicator = 0
    static let invalidShipType = 0
    static let invalidDimension = 0
    static let invalidEta = 0
    static let invalidEtaHour = 24
    static let invalidEtaMin = 60
    static let invalidAltitude = 4095
    static let unspecifiedAidType = 0
    static let invalidCog = 360.0
    static let invalidSog = 1023.0
    static let invalidLat = 91.0
    static let invalidLon = 181.0
    static let invalidRot = 128.0
    static let invalidDraught = 0.0
    static let invalidTcpa = -10000.0
    static let invalidCpa: Float = -1.0
    static let cpaUpdateTimeout: TimeInterval = 10
}

@objcMembers
final class AisObject: NSObject {
    let mmsi: Int
    private(set) var msgType: Int
    private(set) var msgTypes = Set<Int>()
    private(set) var timestamp = 0
    private(set) var imo = 0
    private(set) var heading = AisObjectConstants.invalidHeading
    private(set) var navStatus = AisObjectConstants.invalidNavStatus
    private(set) var maneuverIndicator = AisObjectConstants.invalidManeuverIndicator
    private(set) var shipType = AisObjectConstants.invalidShipType
    private(set) var dimensionToBow = AisObjectConstants.invalidDimension
    private(set) var dimensionToStern = AisObjectConstants.invalidDimension
    private(set) var dimensionToPort = AisObjectConstants.invalidDimension
    private(set) var dimensionToStarboard = AisObjectConstants.invalidDimension
    private(set) var etaMonth = AisObjectConstants.invalidEta
    private(set) var etaDay = AisObjectConstants.invalidEta
    private(set) var etaHour = AisObjectConstants.invalidEtaHour
    private(set) var etaMinute = AisObjectConstants.invalidEtaMin
    private(set) var altitude = AisObjectConstants.invalidAltitude
    private(set) var aidType = AisObjectConstants.unspecifiedAidType
    private(set) var draught = AisObjectConstants.invalidDraught
    private(set) var cog = AisObjectConstants.invalidCog
    private(set) var sog = AisObjectConstants.invalidSog
    private(set) var rot = AisObjectConstants.invalidRot
    private(set) var latitude = AisObjectConstants.invalidLat
    private(set) var longitude = AisObjectConstants.invalidLon
    private(set) var callSign: String?
    private(set) var shipName: String?
    private(set) var destination: String?
    private(set) var objectClass: AisObjType = .invalid
    private(set) var lastUpdate = Date()
    let cpa = AisCpa()

    init(mmsi: Int, msgType: Int) {
        self.mmsi = mmsi
        self.msgType = msgType
        super.init()
        msgTypes.insert(msgType)
        updateObjectClass()
    }

    var hasPosition: Bool {
        latitude != AisObjectConstants.invalidLat && longitude != AisObjectConstants.invalidLon
    }

    var title: String {
        if let shipName, !shipName.isEmpty { return shipName }
        if let callSign, !callSign.isEmpty { return callSign }
        return "MMSI \(mmsi)"
    }

    var messageTypesString: String {
        msgTypes.sorted().map(String.init).joined(separator: ", ")
    }

    func hasMessageType(_ type: Int) -> Bool {
        msgTypes.contains(type)
    }

    var hasImoMessage: Bool {
        hasMessageType(5)
    }

    var hasShipTypeMessage: Bool {
        hasMessageType(5) || hasMessageType(19) || hasMessageType(24)
    }

    var location: CLLocation? {
        guard hasPosition else { return nil }
        return CLLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                          altitude: altitude == AisObjectConstants.invalidAltitude ? 0 : CLLocationDistance(altitude),
                          horizontalAccuracy: 20,
                          verticalAccuracy: -1,
                          course: cog == AisObjectConstants.invalidCog ? -1 : cog,
                          speed: sog == AisObjectConstants.invalidSog ? -1 : sog * 1852.0 / 3600.0,
                          timestamp: lastUpdate)
    }

    @objc var debugSummary: String {
        let position = hasPosition
            ? String(format: "%.6f,%.6f", latitude, longitude)
            : "none"
        let age = Date().timeIntervalSince(lastUpdate)
        return String(format: "mmsi=%d msg=%d msgs=%@ class=%@ shipType=%d rest=%@ movable=%@ nav=%d sog=%.1f cog=%.1f heading=%d pos=%@ age=%.1fs",
                      mmsi,
                      msgType,
                      messageTypesString,
                      objectClassDebugName,
                      shipType,
                      isVesselAtRest ? "yes" : "no",
                      isMovable ? "yes" : "no",
                      navStatus,
                      sog,
                      cog,
                      heading,
                      position,
                      age)
    }

    var currentLocation: CLLocation? {
        guard let location else { return nil }
        let ageHours = Date().timeIntervalSince(lastUpdate) / 3600.0
        return AisTrackerHelper.newPosition(from: location, ageHours: ageHours)
    }

    func merge(_ other: AisObject) {
        msgType = other.msgType
        msgTypes.insert(other.msgType)
        if other.timestamp != 0 { timestamp = other.timestamp }
        if other.imo != 0 { imo = other.imo }
        if other.shipType != AisObjectConstants.invalidShipType { shipType = other.shipType }
        if other.dimensionToBow != AisObjectConstants.invalidDimension { dimensionToBow = other.dimensionToBow }
        if other.dimensionToStern != AisObjectConstants.invalidDimension { dimensionToStern = other.dimensionToStern }
        if other.dimensionToPort != AisObjectConstants.invalidDimension { dimensionToPort = other.dimensionToPort }
        if other.dimensionToStarboard != AisObjectConstants.invalidDimension { dimensionToStarboard = other.dimensionToStarboard }
        if other.etaMonth != AisObjectConstants.invalidEta { etaMonth = other.etaMonth }
        if other.etaDay != AisObjectConstants.invalidEta { etaDay = other.etaDay }
        if other.etaHour != AisObjectConstants.invalidEtaHour { etaHour = other.etaHour }
        if other.etaMinute != AisObjectConstants.invalidEtaMin { etaMinute = other.etaMinute }
        if other.altitude != AisObjectConstants.invalidAltitude { altitude = other.altitude }
        if other.aidType != AisObjectConstants.unspecifiedAidType { aidType = other.aidType }
        if other.draught != AisObjectConstants.invalidDraught { draught = other.draught }
        if other.hasPosition {
            latitude = other.latitude
            longitude = other.longitude
        }
        if let value = other.callSign { callSign = value }
        if let value = other.shipName { shipName = value }
        if let value = other.destination { destination = value }

        if [1, 2, 3, 18, 19, 27].contains(other.msgType) {
            heading = other.heading
        }
        if [1, 2, 3, 27].contains(other.msgType) {
            navStatus = other.navStatus
            maneuverIndicator = other.maneuverIndicator
            rot = other.rot
        }
        if [1, 2, 3, 9, 18, 19, 27].contains(other.msgType) {
            cog = other.cog
            sog = other.sog
        }
        lastUpdate = Date()
        updateObjectClass()
    }

    func isLost(maxAgeMinutes: Int) -> Bool {
        Date().timeIntervalSince(lastUpdate) / 60.0 > Double(maxAgeMinutes)
    }

    func signalLost(maxAgeMinutes: Int) -> Bool {
        isLost(maxAgeMinutes: maxAgeMinutes) && isMovable && !isVesselAtRest
    }

    var isMovable: Bool {
        switch objectClass {
        case .vessel, .vesselSport, .vesselFast, .vesselPassenger, .vesselFreight, .vesselCommercial, .vesselAuthorities, .vesselSar, .vesselOther, .airplane:
            return true
        case .invalid:
            return sog != AisObjectConstants.invalidSog && sog > 0
        default:
            return false
        }
    }

    var isVesselAtRest: Bool {
        switch objectClass {
        case .vessel, .vesselSport, .vesselFast, .vesselPassenger, .vesselFreight, .vesselCommercial, .vesselAuthorities, .vesselSar, .vesselOther:
            if navStatus == 5 {
                return cog == AisObjectConstants.invalidCog || sog < 0.2
            }
            return (msgTypes.contains(18) || msgTypes.contains(24) || msgTypes.contains(1) || msgTypes.contains(3))
                && cog == AisObjectConstants.invalidCog && sog < 0.2
        default:
            return false
        }
    }

    var vesselRotation: Double {
        if cog != AisObjectConstants.invalidCog { return cog }
        if heading != AisObjectConstants.invalidHeading { return Double(heading) }
        return 0
    }

    var shipTypeString: String {
        switch shipType {
        case AisObjectConstants.invalidShipType: return localizedString("ais_unknown")
        case 20: return localizedString("ais_ship_type_wig")
        case 21: return localizedString("ais_ship_type_wig_hazard_a")
        case 22: return localizedString("ais_ship_type_wig_hazard_b")
        case 23: return localizedString("ais_ship_type_wig_hazard_c")
        case 24: return localizedString("ais_ship_type_wig_hazard_d")
        case 30: return localizedString("ais_ship_type_fishing")
        case 31, 32: return localizedString("ais_ship_type_towing")
        case 33: return localizedString("ais_ship_type_dredging")
        case 34: return localizedString("ais_ship_type_diving_ops")
        case 35: return localizedString("ais_ship_type_military_ops")
        case 36: return localizedString("ais_ship_type_sailing")
        case 37: return localizedString("ais_ship_type_pleasure_craft")
        case 40: return localizedString("ais_ship_type_hsc")
        case 41: return localizedString("ais_ship_type_hsc_hazard_a")
        case 42: return localizedString("ais_ship_type_hsc_hazard_b")
        case 43: return localizedString("ais_ship_type_hsc_hazard_c")
        case 44: return localizedString("ais_ship_type_hsc_hazard_d")
        case 49: return localizedString("ais_ship_type_hsc")
        case 50: return localizedString("ais_ship_type_pilot_vessel")
        case 51: return localizedString("ais_ship_type_search_and_rescue")
        case 52: return localizedString("ais_ship_type_tug")
        case 53: return localizedString("ais_ship_type_port_tender")
        case 54: return localizedString("ais_ship_type_antipollution")
        case 55: return localizedString("ais_ship_type_law_enforcement")
        case 56, 57: return localizedString("ais_ship_type_spare_local_vessel")
        case 58: return localizedString("ais_ship_type_medical_transport")
        case 59: return localizedString("ais_ship_type_noncombatant")
        case 60: return localizedString("ais_ship_type_passenger")
        case 61: return localizedString("ais_ship_type_passenger_hazard_a")
        case 62: return localizedString("ais_ship_type_passenger_hazard_b")
        case 63: return localizedString("ais_ship_type_passenger_hazard_c")
        case 64: return localizedString("ais_ship_type_passenger_hazard_d")
        case 69: return localizedString("ais_ship_type_passenger_cruise_ferry")
        case 70: return localizedString("ais_ship_type_cargo")
        case 71: return localizedString("ais_ship_type_cargo_hazard_a")
        case 72: return localizedString("ais_ship_type_cargo_hazard_b")
        case 73: return localizedString("ais_ship_type_cargo_hazard_c")
        case 74: return localizedString("ais_ship_type_cargo_hazard_d")
        case 79: return localizedString("ais_ship_type_cargo")
        case 80: return localizedString("ais_ship_type_tanker")
        case 81: return localizedString("ais_ship_type_tanker_hazard_a")
        case 82: return localizedString("ais_ship_type_tanker_hazard_b")
        case 83: return localizedString("ais_ship_type_tanker_hazard_c")
        case 84: return localizedString("ais_ship_type_tanker_hazard_d")
        case 89: return localizedString("ais_ship_type_tanker")
        case 90: return localizedString("ais_ship_type_other")
        case 91: return localizedString("ais_ship_type_other_hazard_a")
        case 92: return localizedString("ais_ship_type_other_hazard_b")
        case 93: return localizedString("ais_ship_type_other_hazard_c")
        case 94: return localizedString("ais_ship_type_other_hazard_d")
        case 99: return localizedString("ais_ship_type_other")
        default: return "\(shipType)"
        }
    }

    var navStatusString: String {
        switch navStatus {
        case 0: return localizedString("ais_nav_status_under_way_engine")
        case 1: return localizedString("ais_nav_status_at_anchor")
        case 2: return localizedString("ais_nav_status_not_under_command")
        case 3: return localizedString("ais_nav_status_restricted_maneuverability")
        case 4: return localizedString("ais_nav_status_constrained_draught")
        case 5: return localizedString("ais_nav_status_moored")
        case 6: return localizedString("ais_nav_status_aground")
        case 7: return localizedString("ais_nav_status_engaged_fishing")
        case 8: return localizedString("ais_nav_status_under_way_sailing")
        case 11: return localizedString("ais_nav_status_towing_astern")
        case 12: return localizedString("ais_nav_status_pushing_or_towing")
        case 14: return localizedString("ais_nav_status_sart_active")
        case AisObjectConstants.invalidNavStatus: return localizedString("ais_unknown")
        default: return "\(navStatus)"
        }
    }

    var maneuverIndicatorString: String {
        switch maneuverIndicator {
        case 0: return localizedString("shared_string_not_available")
        case 1: return localizedString("ais_maneuver_no_special")
        case 2: return localizedString("ais_maneuver_special")
        default: return "\(maneuverIndicator)"
        }
    }

    var aidTypeString: String {
        switch aidType {
        case 0: return localizedString("ais_not_specified")
        case 1: return localizedString("ais_aid_reference_point")
        case 2: return localizedString("ais_aid_racon")
        case 3: return localizedString("ais_aid_fixed_structure_off_shore")
        case 5: return localizedString("ais_aid_light_without_sectors")
        case 6: return localizedString("ais_aid_light_with_sectors")
        case 7: return localizedString("ais_aid_leading_light_front")
        case 8: return localizedString("ais_aid_leading_light_rear")
        case 9: return localizedString("ais_aid_beacon_cardinal_n")
        case 10: return localizedString("ais_aid_beacon_cardinal_e")
        case 11: return localizedString("ais_aid_beacon_cardinal_s")
        case 12: return localizedString("ais_aid_beacon_cardinal_w")
        case 13: return localizedString("ais_aid_beacon_port_hand")
        case 14: return localizedString("ais_aid_beacon_starboard_hand")
        case 17: return localizedString("ais_aid_beacon_isolated_danger")
        case 18: return localizedString("ais_aid_beacon_safe_water")
        case 19: return localizedString("ais_aid_beacon_special_mark")
        case 20: return localizedString("ais_aid_cardinal_mark_n")
        case 21: return localizedString("ais_aid_cardinal_mark_e")
        case 22: return localizedString("ais_aid_cardinal_mark_s")
        case 23: return localizedString("ais_aid_cardinal_mark_w")
        case 24: return localizedString("ais_aid_port_hand_mark")
        case 25: return localizedString("ais_aid_starboard_hand_mark")
        case 28: return localizedString("ais_aid_isolated_danger")
        case 29: return localizedString("ais_aid_safe_water")
        case 30: return localizedString("ais_aid_special_mark")
        case 31: return localizedString("ais_aid_light_vessel_lanby_rigs")
        default: return "\(aidType)"
        }
    }

    func applyPosition(timestamp: Int, navStatus: Int, maneuverIndicator: Int, heading: Int, cog: Double, sog: Double, lat: Double, lon: Double, rot: Double) {
        self.timestamp = timestamp
        self.navStatus = navStatus
        self.maneuverIndicator = maneuverIndicator
        self.heading = heading
        self.cog = cog
        self.sog = sog
        self.latitude = lat
        self.longitude = lon
        self.rot = rot
        updateObjectClass()
    }

    func applyBaseStation(lat: Double, lon: Double) {
        latitude = lat
        longitude = lon
        updateObjectClass()
    }

    func applyStatic(imo: Int, callSign: String?, shipName: String?, shipType: Int, bow: Int, stern: Int, port: Int, starboard: Int, draught: Double, destination: String?, etaMonth: Int, etaDay: Int, etaHour: Int, etaMinute: Int) {
        self.imo = imo
        self.callSign = callSign
        self.shipName = shipName
        self.shipType = shipType
        dimensionToBow = bow
        dimensionToStern = stern
        dimensionToPort = port
        dimensionToStarboard = starboard
        self.draught = draught
        if let destination, !destination.allSatisfy({ $0 == "@" }) {
            self.destination = destination
        }
        self.etaMonth = etaMonth
        self.etaDay = etaDay
        self.etaHour = etaHour
        self.etaMinute = etaMinute
        updateObjectClass()
    }

    func applyAircraft(timestamp: Int, altitude: Int, cog: Double, sog: Double, lat: Double, lon: Double) {
        self.timestamp = timestamp
        self.altitude = altitude
        self.cog = cog
        self.sog = sog
        latitude = lat
        longitude = lon
        updateObjectClass()
    }

    func applyAton(lat: Double, lon: Double, aidType: Int, bow: Int, stern: Int, port: Int, starboard: Int) {
        latitude = lat
        longitude = lon
        self.aidType = aidType
        dimensionToBow = bow
        dimensionToStern = stern
        dimensionToPort = port
        dimensionToStarboard = starboard
        updateObjectClass()
    }

    private func updateObjectClass() {
        switch shipType {
        case 20...24, 40...44, 49:
            objectClass = .vesselFast
        case 30...34, 50, 52...54, 56, 57, 59:
            objectClass = .vesselCommercial
        case 35, 55:
            objectClass = .vesselAuthorities
        case 51, 58:
            objectClass = .vesselSar
        case 36, 37:
            objectClass = .vesselSport
        case 60...64, 69:
            objectClass = .vesselPassenger
        case 70...74, 79, 80...84, 89:
            objectClass = .vesselFreight
        case 90...94, 99:
            objectClass = .vesselOther
        default:
            if msgTypes.contains(9) {
                objectClass = .airplane
            } else if msgTypes.contains(4) {
                objectClass = .landStation
            } else if msgTypes.contains(21) {
                objectClass = (aidType == 29 || aidType == 30) ? .atonVirtual : .aton
            } else if msgTypes.contains(18) {
                objectClass = .vessel
            } else {
                switch navStatus {
                case 0...6, 8, 11, 12:
                    objectClass = .vessel
                case 7:
                    objectClass = .vesselCommercial
                case 14:
                    objectClass = .sart
                default:
                    objectClass = .invalid
                }
            }
        }
    }

    private var objectClassDebugName: String {
        switch objectClass {
        case .vessel: return "vessel"
        case .vesselSport: return "vesselSport"
        case .vesselFast: return "vesselFast"
        case .vesselPassenger: return "vesselPassenger"
        case .vesselFreight: return "vesselFreight"
        case .vesselCommercial: return "vesselCommercial"
        case .vesselAuthorities: return "vesselAuthorities"
        case .vesselSar: return "vesselSar"
        case .vesselOther: return "vesselOther"
        case .landStation: return "landStation"
        case .airplane: return "airplane"
        case .sart: return "sart"
        case .aton: return "aton"
        case .atonVirtual: return "atonVirtual"
        case .invalid: return "invalid"
        }
    }
}

func aisDebugLog(_ message: @autoclosure () -> String) {
#if DEBUG
    NSLog("[AIS] %@", message())
#endif
}
