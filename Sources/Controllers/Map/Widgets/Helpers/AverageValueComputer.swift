//
//  AverageValueComputer.swift
//  OsmAnd Maps
//
//  Created by Skalii on 04.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAAverageValueComputer)
@objcMembers
class AverageValueComputer: NSObject {
    
    static let addPointIntervalMillis = 1000
    static let defaultIntervalMillis = 30 * 60 * 1000
    static let measuredIntervals: [Int] = {
        var modifiableIntervals = [Int]()
        modifiableIntervals.append(contentsOf: [15 * 1000, 30 * 1000, 45 * 1000])
        for i in 1...60 {
            modifiableIntervals.append(i * 60 * 1000)
        }
        return modifiableIntervals
    }()
    static let biggestMeasuredInterval = measuredIntervals[measuredIntervals.count - 1]

    private var locations: [CLLocation] = []

    func getLocations() -> [CLLocation] {
        locations
    }

    func addLocation(_ location: CLLocation) {
        locations.append(location)
    }

    func updateLocation(_ location: CLLocation?) {
        guard let location, isEnabled() else { return }
        saveLocation(location, time: Date().timeIntervalSince1970)
    }

    func clearExpiredLocations(_ locations: inout [CLLocation], measuredInterval: Int) {
        let expirationTime = Int(Date().timeIntervalSince1970) * 1000 - measuredInterval
        locations.enumerated().forEach {
            if Int($1.timestamp.timeIntervalSince1970) * 1000 < expirationTime {
                locations.remove(at: $0)
            } else {
                return
            }
        }
    }

    func isEnabled() -> Bool {
        false
    }

    func saveLocation(_ location: CLLocation, time: TimeInterval) {
    }
}
