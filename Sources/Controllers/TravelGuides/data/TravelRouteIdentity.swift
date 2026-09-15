import Foundation

struct TravelRouteIdentity {
    private enum Tag: String {
        case routeId = "route_id"
        case route
        case routeType = "route_type"
    }

    static func osmRouteId(from routeId: String?) -> Int64 {
        guard let routeId, routeId.hasPrefix("O") else { return 0 }
        let value = routeId.replacingOccurrences(of: "O", with: "")
        var digits = ""
        for (index, scalar) in value.unicodeScalars.enumerated() {
            if index == 0 && (scalar == "+" || scalar == "-") {
                digits.append(String(scalar))
            } else {
                guard scalar.value <= 0xFFFF,
                      scalar.properties.generalCategory == .decimalNumber,
                      let digit = Character(String(scalar)).wholeNumberValue else { return 0 }
                digits.append(String(digit))
            }
        }
        return Int64(digits) ?? 0
    }

    static func isTravelGpx(tags: [String: String]) -> Bool {
        tags[Tag.routeId.rawValue] != nil
            && (tags[Tag.route.rawValue] == "segment" || tags[Tag.routeType.rawValue] != nil)
    }

    static func routeType(from subTypes: String?) -> String? {
        subTypes?.components(separatedBy: ";")
            .first { $0.hasPrefix("routes_") }?
            .replacingOccurrences(of: "routes_", with: "")
    }
}
