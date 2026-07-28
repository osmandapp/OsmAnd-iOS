//
//  RouteDeepLinkBuilder.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 24.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class RouteDeepLinkBuilder: NSObject {
    static func generateRouteUrl() -> String {
        func formatLatLon(_ location: CLLocation) -> String {
            String(format: "%.6f,%.6f", location.coordinate.latitude, location.coordinate.longitude)
        }
        
        func percentEncodedQueryValue(_ value: String) -> String {
            var allowed = CharacterSet.urlQueryAllowed
            allowed.remove(charactersIn: ",;")
            return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
        }
        
        let targets = OATargetPointsHelper.sharedInstance()
        let mapVC = OARootViewController.instance().mapPanel.mapViewController
        let mapLocation = mapVC.getMapLocation()
        let zoom = Int(mapVC.getMapZoom())

        var components = URLComponents()
        components.scheme = kHttpsScheme
        components.host = kOsmAndHost
        components.path = kOsmAndMapPathPrefix

        var items: [URLQueryItem] = []

        if let start = targets?.getPointToStart() {
            items.append(URLQueryItem(name: "start", value: formatLatLon(start.point)))
        }

        let intermediates = targets?.getIntermediatePoints() ?? []
        if !intermediates.isEmpty {
            let via = intermediates.map { formatLatLon($0.point) }.joined(separator: ";")
            items.append(URLQueryItem(name: "via", value: via))
        }

        if let end = targets?.getPointToNavigate() {
            items.append(URLQueryItem(name: "end", value: formatLatLon(end.point)))
        }

        items.append(URLQueryItem(
            name: "profile",
            value: OARoutingHelper.sharedInstance().getAppMode().stringKey
        ))
        components.percentEncodedQueryItems = items.map {
            URLQueryItem(name: $0.name, value: $0.value.map(percentEncodedQueryValue))
        }

        let lat = mapLocation.coordinate.latitude
        let lon = mapLocation.coordinate.longitude
        components.fragment = String(format: "%d/%.6f/%.6f", zoom, lat, lon)

        return components.url?.absoluteString ?? ""
    }
}
