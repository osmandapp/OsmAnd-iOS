//
//  CarPlayNavigationModeManager.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 13.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class CarPlayNavigationModeManager {
    
    @discardableResult static func configureCarPlayNavigationMode(defaultAppMode: OAApplicationMode?) -> OAApplicationMode? {
        guard let routing = OARoutingHelper.sharedInstance() else { return nil }
        let settings = OAAppSettings.sharedManager()
        let baseMode = defaultAppMode ?? settings.applicationMode.get()
        let firstCar = OAApplicationMode.values()?.first { $0.isDerivedRouting(from: .car()) } ?? baseMode
        let resolvedMode: OAApplicationMode = settings.isCarPlayModeDefault.get()
        ? (baseMode.isDerivedRouting(from: .car()) ? baseMode : firstCar)
        : settings.carPlayMode.get()
        let current = settings.applicationMode.get()
        guard resolvedMode != current else { return baseMode }
        settings.setApplicationModePref(resolvedMode)
        routing.setAppMode(resolvedMode)
        if isRoutingActive() {
            routing.recalculateRouteDueToSettingsChange()
            OATargetPointsHelper.sharedInstance().updateRouteAndRefresh(true)
        }
        
        return baseMode
    }
    
    static func isRoutingActive() -> Bool {
        OAAppSettings.sharedManager().followTheRoute.get() || OARoutingHelper.sharedInstance().isRouteCalculated() || OARoutingHelper.sharedInstance().isRouteBeingCalculated()
    }
}
