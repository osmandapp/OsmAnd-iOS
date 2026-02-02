//
//  CarPlayService.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 04.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import CarPlay.CPSessionConfiguration

@objcMembers
final class CarPlayService: NSObject {
    static let shared = CarPlayService()
    
    private let navigationModeProvider = CarPlayNavigationModeProvider()
    
    private var sessionConfiguration: CPSessionConfiguration?
    /// MapAppearanceMode that was active before switching to a CarPlay mode.
    private var appMapAppearanceMode: DayNightMode?
    private var carPlayMapAppearanceMode: DayNightMode?
    
    private override init() {
        super.init()
    }
    
    func configure() {
        reconnectOBDIfNeeded()
        navigationModeProvider.configureForCarPlay()
        saveAppMapAppearanceModeIfNeeded()
        saveCarPlayMapAppearanceIfNeeded()
        initSessionConfiguration()
        OARoutingHelper.sharedInstance().onCarNavigationStart()
    }
    
    func disconnectScene() {
        sessionConfiguration = nil
        restoreOriginalMapAppearanceModeIfNeeded()
        appMapAppearanceMode = nil
        carPlayMapAppearanceMode = nil
        OARoutingHelper.sharedInstance().onCarNavigationSessionChanged()
        navigationModeProvider.restoreOnDisconnect()
    }

    // MARK: - Save / Restore appearance mode
    
    private func saveAppMapAppearanceModeIfNeeded() {
        guard appMapAppearanceMode == nil else { return }
        
        if let originalAppMode = navigationModeProvider.originalAppMode {
            appMapAppearanceMode = DayNightMode(rawValue: OAAppSettings.sharedManager().appearanceMode.get(originalAppMode))
        }
    }
    
    private func saveCarPlayMapAppearanceIfNeeded() {
        guard carPlayMapAppearanceMode == nil else { return }
        // appearanceMode already stores the appearance for CarPlay
        carPlayMapAppearanceMode = DayNightMode(rawValue: OAAppSettings.sharedManager().appearanceMode.get())
    }
    
    private func restoreOriginalMapAppearanceModeIfNeeded() {
        guard let appMapAppearanceMode else { return }
        guard let originalAppMode = navigationModeProvider.originalAppMode else { return }

        OAAppSettings.sharedManager().appearanceMode.set(appMapAppearanceMode.rawValue, mode: originalAppMode)
        let currentMode = OAAppSettings.sharedManager().currentMode
        if originalAppMode != currentMode {
            guard let carPlayMapAppearanceMode else { return }
            OAAppSettings.sharedManager().appearanceMode.set(carPlayMapAppearanceMode.rawValue, mode: currentMode)
        }
    }
    
    private func initSessionConfiguration() {
        guard sessionConfiguration == nil else { return }
        sessionConfiguration = CPSessionConfiguration(delegate: self)
    }
}

// MARK: - CarPlayNavigationModeProvider
extension CarPlayService {
    func firstCarMode() -> OAApplicationMode {
        navigationModeProvider.firstCarMode()
    }
}

// MARK: - OBD
extension CarPlayService {
    private func reconnectOBDIfNeeded() {
        guard let plugin = OAPluginsHelper.getEnabledPlugin(VehicleMetricsPlugin.self) as? VehicleMetricsPlugin else { return }
        plugin.reconnectOBDIfNeeded()
    }
}

// MARK: - CPSessionConfigurationDelegate
extension CarPlayService: CPSessionConfigurationDelegate {
    /// Handle CarPlay content-style updates triggered by the “Always Show Dark Maps” setting.
    func sessionConfiguration(_ sessionConfiguration: CPSessionConfiguration,
                              contentStyleChanged contentStyle: CPContentStyle) {
        updateMapStyle(with: contentStyle)
    }
    
    private func updateMapStyle(with contentStyle: CPContentStyle) {
        switch contentStyle {
        case _ where contentStyle.contains(.dark):
            NSLog("[CarPlayService] -> onUpdateMapStyle: %lu (dark)", UInt(contentStyle.rawValue))
            OAAppSettings.sharedManager().appearanceMode.set(DayNightMode.night.rawValue)
        case _ where contentStyle.contains(.light):
            NSLog("[CarPlayService] -> onUpdateMapStyle: %lu (light)", UInt(contentStyle.rawValue))
            OAAppSettings.sharedManager().appearanceMode.set(DayNightMode.day.rawValue)
        default:
            NSLog("[CarPlayService] -> onUpdateMapStyle: unknown style, keeping previous appearanceMode")
        }
    }
}
