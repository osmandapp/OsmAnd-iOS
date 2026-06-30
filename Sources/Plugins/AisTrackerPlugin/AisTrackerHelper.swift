//
//  AisTrackerHelper.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 11.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import CoreLocation
import OsmAndShared

enum AisTrackerHelper {
    static func getCpa(_ ownLocation: CLLocation, _ otherLocation: CLLocation, result: AisCpa) {
        result.reset()
        AisTrackerMath.shared.getCpa(ownLocation: ownLocation.aisLocation,
                                                  otherLocation: otherLocation.aisLocation,
                                                  result: result)
    }
}

private extension CLLocation {
    var aisLocation: AisLocation {
        AisLocation(latitude: coordinate.latitude,
                                 longitude: coordinate.longitude,
                                 speed: speed >= 0 ? Float(speed) : .nan,
                                 bearing: course >= 0 ? Float(course) : .nan,
                                 hasSpeed: speed >= 0,
                                 hasBearing: course >= 0)
    }
}
