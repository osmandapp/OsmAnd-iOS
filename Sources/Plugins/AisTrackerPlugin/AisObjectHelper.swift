//
//  AisObjectHelper.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import CoreLocation
import OsmAndShared

enum AisObjectHelper {
    static func lastUpdateDate(_ object: AisObject) -> Foundation.Date {
        Date(timeIntervalSince1970: TimeInterval(object.lastUpdate) / 1000.0)
    }

    static func location(_ object: AisObject) -> CLLocation? {
        guard let location = object.getAisLocation() else { return nil }
        return makeLocation(location, timestamp: lastUpdateDate(object), altitude: object.altitude)
    }

    static func currentLocation(_ object: AisObject) -> CLLocation? {
        guard let location = object.getExtrapolatedLocation(now: Int64(Date().timeIntervalSince1970 * 1000)) else { return nil }
        return makeLocation(location, timestamp: Date(), altitude: object.altitude)
    }

    static func messageTypesString(_ object: AisObject) -> String {
        let values = object.msgTypes.compactMap { ($0 as? KotlinInt).map { String($0.intValue) } }
        return values.sorted().joined(separator: ", ")
    }

    static func debugSummary(_ object: AisObject) -> String {
        let latitude = object.position?.latitude ?? AisObjectConstants.shared.INVALID_LAT
        let longitude = object.position?.longitude ?? AisObjectConstants.shared.INVALID_LON
        let positionText = object.position != nil ? String(format: "%.6f,%.6f", latitude, longitude) : "none"
        let age = Date().timeIntervalSince(lastUpdateDate(object))
        return String(format: "mmsi=%d msg=%d msgs=%@ class=%@ shipType=%d rest=%@ movable=%@ nav=%d sog=%.1f cog=%.1f heading=%d pos=%@ age=%.1fs",
                      object.mmsi,
                      object.msgType,
                      messageTypesString(object),
                      object.objectClass.name,
                      object.shipType,
                      object.isVesselAtRest() ? "yes" : "no",
                      object.isMovable() ? "yes" : "no",
                      object.navStatus,
                      object.sog,
                      object.cog,
                      object.heading,
                      positionText,
                      age)
    }

    static func debugLog(_ message: String) {
        AisLogger.shared.log(message)
    }

    private static func makeLocation(_ location: AisLocation, timestamp: Foundation.Date, altitude: Int32) -> CLLocation {
        CLLocation(coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                   altitude: altitude == AisObjectConstants.shared.INVALID_ALTITUDE ? 0 : CLLocationDistance(altitude),
                   horizontalAccuracy: 20,
                   verticalAccuracy: -1,
                   course: location.hasBearing ? CLLocationDirection(location.bearing) : -1,
                   speed: location.hasSpeed ? CLLocationSpeed(location.speed) : -1,
                   timestamp: timestamp)
    }
}
