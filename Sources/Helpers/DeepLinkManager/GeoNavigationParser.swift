//
//  GeoNavigationParser.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 15.04.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

enum GeoNavigationAction {
    case buildRoute(source: LocationPoint?, destination: LocationPoint?, waypoints: [LocationPoint])
    case showOnMap(point: LocationPoint?)
}

enum LocationPoint {
    case coordinate(CLLocation)
    case address(String)
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
        
        func parseLocation(_ value: String?) -> LocationPoint? {
            guard let value, !value.isEmpty else { return nil }
            if let coord = parseCoord(value) {
                return .coordinate(coord)
            }
            return .address(value)
        }
        
        let waypoints = queryItems
            .filter { $0.name.lowercased() == "waypoint" }
            .compactMap { parseLocation($0.value) }
        
        if path.contains("directions") {
            let dest = parseLocation(params["destination"])
            let src = parseLocation(params["source"])
            return .buildRoute(source: src, destination: dest, waypoints: waypoints)
        }
        
        if path.contains("place") {
            let location = parseLocation(params["coordinate"] ?? params["address"])
            return .showOnMap(point: location)
        }
        
        return nil
    }
    
    private static func parseCoord(_ string: String) -> CLLocation? {
        let parts = string.split(separator: ",")
        guard parts.count == 2,
              let lat = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              let lon = Double(parts[1].trimmingCharacters(in: .whitespaces)) else { return nil }
        
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        guard CLLocationCoordinate2DIsValid(coord) else { return nil }
        
        return CLLocation(latitude: coord.latitude, longitude: coord.longitude)
    }
}
