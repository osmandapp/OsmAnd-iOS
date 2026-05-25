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
    enum StarChartType: String, CaseIterable {
        case STAR_VISIBLITY
        case STAR_ALTITUDE

        func next() -> StarChartType {
            let entries = Self.allCases
            let nextItemIndex = (entries.firstIndex(of: self) ?? 0) + 1
            return entries[nextItemIndex % entries.count]
        }
    }

    private static let typePreferenceKey = "star_chart_type"

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

    func changeToNextState() {
        let nextType = getStarChartType().next()
        UserDefaults.standard.set(nextType.rawValue, forKey: Self.typePreferenceKey)
    }

    func getStarChartType() -> StarChartType {
        guard let value = UserDefaults.standard.string(forKey: Self.typePreferenceKey),
              let type = StarChartType(rawValue: value) else {
            return .STAR_VISIBLITY
        }
        return type
    }
}
