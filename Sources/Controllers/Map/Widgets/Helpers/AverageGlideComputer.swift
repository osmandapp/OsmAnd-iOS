//
//  AverageGlideComputer.swift
//  OsmAnd Maps
//
//  Created by Skalii on 04.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAAverageGlideComputer)
@objcMembers
final class AverageGlideComputer: AverageValueComputer {

    static let shared = AverageGlideComputer()

    private override init() {}

    override func isEnabled() -> Bool {
        if let appMode = OAAppSettings.sharedManager().applicationMode?.get(),
           let registry = OAMapWidgetRegistry.sharedInstance() {
            for widgetInfo in registry.getAllWidgets() where widgetInfo.widget is GlideAverageWidget
                    && widgetInfo.isEnabledForAppMode(appMode)
                    && WidgetsAvailabilityHelper.isWidgetAvailable(widgetId: widgetInfo.key, appMode: appMode) {
                return true
            }
        }
        return false
    }

    override func saveLocation(_ location: CLLocation, time: TimeInterval) {
        if !location.altitude.isNaN, !location.altitude.isZero {
            addLocation(CLLocation(coordinate: location.coordinate,
                                   altitude: location.altitude,
                                   horizontalAccuracy: location.horizontalAccuracy,
                                   verticalAccuracy: location.verticalAccuracy,
                                   course: location.course,
                                   courseAccuracy: location.courseAccuracy,
                                   speed: location.speed,
                                   speedAccuracy: location.speedAccuracy,
                                   timestamp: Date(timeIntervalSince1970: time),
                                   sourceInfo: location.sourceInformation ?? CLLocationSourceInformation()))
            clearExpiredLocations(AverageValueComputer.biggestMeasuredInterval)
        }
    }

    func getFormattedAverage(verticalSpeed: Bool, measuredInterval: Int) -> String? {
        clearExpiredLocations(measuredInterval)

        let locationsToUse: [CLLocation] = getLocations()
        if !locationsToUse.isEmpty {
            if !verticalSpeed {
                let distance = calculateTotalDistance(locationsToUse)
                let difference = calculateAltitudeDifference(locationsToUse)
                return GlideUtils.calculateFormattedRatio(distance, altDif: difference)
            } else {
                let altitudeDifference = calculateAltitudeDifference(locationsToUse)
                if measuredInterval > 0 {
                    let verticalSpeedValue = abs(altitudeDifference) / (Double(measuredInterval) / 1000.0)
                    let roundedVerticalSpeedValue = round(verticalSpeedValue)
                    let speedSystem: EOASpeedConstant = OASpeedConstant.imperial(OAAppSettings.sharedManager().speedSystem.get())
                        ? .FEET_PER_SECOND : .METERS_PER_SECOND
                    return OAOsmAndFormatter.getFormattedSpeed(Float(roundedVerticalSpeedValue), speedSystem: speedSystem)
                }
            }
        }
        return nil
    }

    private func calculateTotalDistance(_ locations: [CLLocation]) -> Double {
        var totalDistance = 0.0
        for i in 0..<locations.count - 1 {
            let l1 = locations[i]
            let l2 = locations[i + 1]
            totalDistance += OAMapUtils.getDistance(l1.coordinate.latitude,
                                                    lon1: l1.coordinate.longitude,
                                                    lat2: l2.coordinate.latitude,
                                                    lon2: l2.coordinate.longitude)
        }
        return totalDistance
    }

    private func calculateAltitudeDifference(_ locations: [CLLocation]) -> Double {
        guard locations.count > 1 else { return 0.0 }
        let start = locations[0]
        let end = locations[locations.count - 1]
        return start.altitude - end.altitude
    }
}
