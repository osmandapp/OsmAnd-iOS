//
//  CarPlayNavigationModeManager.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 13.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class CarPlayNavigationModeManager: NSObject {
    static let shared = CarPlayNavigationModeManager()
    
    // App mode (profile) that was active before switching to a CarPlay mode.
    private var originalAppMode: OAApplicationMode?
    
    private override init() {
        super.init()
    }
    
    func firstCarMode() -> OAApplicationMode {
        guard
            let modes = OAApplicationMode.values(),
            let carMode = modes.first(where: { $0.isDerivedRouting(from: .car()) })
        else {
            let fallback = OAAppSettings.sharedManager().applicationMode.get()
            NSLog("[CarPlayNavigationModeManager] -> No car-derived mode found. Fallback = %@", fallback.toHumanString())
            return fallback
        }
        
        return carMode
    }
    
    func configureForCarPlay() {
        guard let routing = OARoutingHelper.sharedInstance() else { return }
        let settings = OAAppSettings.sharedManager()
        captureOriginalModeIfNeeded()
        let current = settings.applicationMode.get()
        let firstCar = firstCarMode()
        let resolved = settings.isCarPlayModeDefault.get() ? (current.isDerivedRouting(from: .car()) ? current : firstCar) : settings.carPlayMode.get()
        guard resolved != current else { return }
        settings.setApplicationModePref(resolved)
        routing.setAppMode(resolved)
        if isRoutingActive() {
            routing.recalculateRouteDueToSettingsChange()
            OATargetPointsHelper.sharedInstance().updateRouteAndRefresh(true)
        }
    }
    
    func restoreOnDisconnect() {
        guard let originalAppMode else { return }
        guard !isRoutingActive() else { return }
        OAAppSettings.sharedManager().setApplicationModePref(originalAppMode)
        OARoutingHelper.sharedInstance()?.setAppMode(originalAppMode)
        self.originalAppMode = nil
    }
    
    private func isRoutingActive() -> Bool {
        OAAppSettings.sharedManager().followTheRoute.get() || OARoutingHelper.sharedInstance().isRouteCalculated() || OARoutingHelper.sharedInstance().isRouteBeingCalculated()
    }
    
    private func captureOriginalModeIfNeeded() {
        guard originalAppMode == nil else { return }
        originalAppMode = OAAppSettings.sharedManager().applicationMode.get()
    }
}
