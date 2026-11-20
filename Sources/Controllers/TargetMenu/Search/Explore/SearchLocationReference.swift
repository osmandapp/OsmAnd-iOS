//
//  SearchLocationReference.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

struct SearchLocationReference {
    let searchNearMapCenter: Bool
    let searchLocation: CLLocationCoordinate2D

    var location: CLLocation? {
        if isMapCenter {
            return CLLocation(latitude: searchLocation.latitude, longitude: searchLocation.longitude)
        }
        return OsmAndApp.swiftInstance()?.locationServices?.lastKnownLocation
    }

    private var isMapCenter: Bool {
        searchNearMapCenter && CLLocationCoordinate2DIsValid(searchLocation)
    }

    func secondaryContent(latitude: Double, longitude: Double, address: String? = nil, trailingText: String? = nil) -> PointSecondaryContent {
        let metrics = distanceAndDirection(latitude: latitude, longitude: longitude)
        return PointSecondaryContent(formattedDistance: metrics.distance,
                                     direction: metrics.direction,
                                     directionColor: metrics.color,
                                     address: address,
                                     date: nil,
                                     trailingText: trailingText)
    }

    private func distanceAndDirection(latitude: Double, longitude: Double) -> (distance: String?, direction: CGFloat, color: UIColor) {
        if isMapCenter {
            let center = CLLocation(latitude: searchLocation.latitude, longitude: searchLocation.longitude)
            let meters = OADistanceAndDirectionsUpdater.distance(from: center, toDestinationLatitude: latitude, destinationLongitude: longitude)
            let azimuth = OARootViewController.instance()?.mapPanel?.mapViewController.azimuth() ?? 0
            let direction = OADistanceAndDirectionsUpdater.directionAngle(from: center,
                                                                          sourceDirection: CLLocationDirection(azimuth),
                                                                          toDestinationLatitude: latitude,
                                                                          destinationLongitude: longitude)
            return (OAOsmAndFormatter.getFormattedDistance(Float(meters)), direction, .iconColorDirectionMapCenter)
        }

        guard let location = OsmAndApp.swiftInstance()?.locationServices?.lastKnownLocation else { return (nil, 0, .iconColorDirectionActive) }
        let meters = OADistanceAndDirectionsUpdater.distance(from: location, toDestinationLatitude: latitude, destinationLongitude: longitude)
        let direction = OADistanceAndDirectionsUpdater.directionAngle(from: location, toDestinationLatitude: latitude, destinationLongitude: longitude)
        return (OAOsmAndFormatter.getFormattedDistance(Float(meters)), direction, .iconColorDirectionActive)
    }
}
