//
//  StarChartState.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import CoreLocation
import Foundation

final class StarChartState: NSObject {
    var date: Date
    var location: CLLocation?
    var heading: Double
    var selectedObject: SkyObject?
    var dataSnapshot: AstroDataSnapshot?

    override init() {
        date = Date()
        location = OsmAndApp.swiftInstance()?.locationServices?.lastKnownLocation
        heading = 0
        super.init()
    }
}
