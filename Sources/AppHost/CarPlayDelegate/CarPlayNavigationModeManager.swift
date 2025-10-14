//
//  CarPlayNavigationModeManager.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 13.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class CarPlayNavigationModeManager: NSObject {
    private static var originalAppMode: OAApplicationMode?
    
    private static func isRoutingActive() -> Bool {
        OAAppSettings.sharedManager().followTheRoute.get() || OARoutingHelper.sharedInstance().isRouteCalculated() || OARoutingHelper.sharedInstance().isRouteBeingCalculated()
    }
    
    private static func captureOriginalModeIfNeeded() {
        guard Self.originalAppMode == nil else { return }
        Self.originalAppMode = OAAppSettings.sharedManager().applicationMode.get()
    }
    
    static func firstCarMode() -> OAApplicationMode {
        (OAApplicationMode.values() ?? []).first { $0.isDerivedRouting(from: .car()) } ?? OAAppSettings.sharedManager().applicationMode.get()
    }
    
    static func configureForCarPlay() {
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
    
    static func restoreOnDisconnect() {
        guard let original = Self.originalAppMode else { return }
        guard !isRoutingActive() else { return }
        OAAppSettings.sharedManager().setApplicationModePref(original)
        OARoutingHelper.sharedInstance()?.setAppMode(original)
        Self.originalAppMode = nil
    }
}
