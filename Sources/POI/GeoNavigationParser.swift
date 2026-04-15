//
//  GeoNavigationParser.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 15.04.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

enum GeoNavigationAction {
    case buildRoute(source: CLLocation?, destination: CLLocation?, waypoints: [CLLocation])
    case search(query: String)
    case showOnMap(coordinate: CLLocation, title: String?)
}

struct GeoNavigationParser {

    static func parse(_ url: URL) -> GeoNavigationAction? {
        guard url.scheme == "geo-navigation",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return nil }

        let path = components.path.lowercased()
        let queryItems = components.queryItems ?? []
        let params = Dictionary(uniqueKeysWithValues: queryItems
            .filter { $0.name.lowercased() != "waypoint" }
            .map { ($0.name.lowercased(), $0.value ?? "") })

        let waypoints = queryItems
            .filter { $0.name.lowercased() == "waypoint" }
            .compactMap { $0.value.flatMap { parseCoord($0) } }

        if path.contains("directions") {
            let destCoord = params["destination"].flatMap { parseCoord($0) }
            let srcCoord = params["source"].flatMap { parseCoord($0) }
            return .buildRoute(source: srcCoord, destination: destCoord, waypoints: destCoord != nil ? waypoints : [])
        }

        if path.contains("place") {
            let address = params["address"]

            if let coordValue = params["coordinate"], let coord = parseCoord(coordValue) {
                return .showOnMap(coordinate: coord, title: address)
            } else if let address, !address.isEmpty {
                return .search(query: address)
            }
        }

        return nil
    }

    private static func parseCoord(_ string: String) -> CLLocation? {
        let parts = string.split(separator: ",")

        guard parts.count == 2,
              let lat = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              let lon = Double(parts[1].trimmingCharacters(in: .whitespaces)) else {
            return nil
        }

        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)

        guard CLLocationCoordinate2DIsValid(coord) else {
            return nil
        }

        return CLLocation(latitude: coord.latitude, longitude: coord.longitude)
    }
}
