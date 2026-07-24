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
    enum CarPlaySceneType {
        case app
        case dashboard
    }
    
    static let shared = CarPlayService()
    
    private let navigationModeProvider = CarPlayNavigationModeProvider()
    
    private var sessionConfiguration: CPSessionConfiguration?
    private var lastContentStyle: CPContentStyle?
    /// Indicates whether Search Core resources have been prepared for CarPlay.
    private var isSearchUICorePrepared = false
    
    private override init() {
        super.init()
    }
        
    func configure() {
        reconnectOBDIfNeeded()
        navigationModeProvider.configureForCarPlay()
        initSessionConfiguration()
        applyCarPlayMapAppearance()
        OARoutingHelper.sharedInstance().resumeNavigationAfterCarPlayReconnect()
    }
    
    func disconnectScene(_ sceneType: CarPlaySceneType) {
        guard OsmAndApp.swiftInstance().initialized else {
            return
        }
        sessionConfiguration = nil
        lastContentStyle = nil
        OADayNightHelper.instance().resetCarPlayMode()
        OARoutingHelper.sharedInstance().onCarPlayConnectionStateChanged()
        navigationModeProvider.restoreOnDisconnect()
        if case .app = sceneType, isSearchUICorePrepared, UIApplication.shared.mainScene != nil {
            OAQuickSearchHelper.instance().setResourcesForSearchUICore()
            isSearchUICorePrepared = false
        }
    }
    
    /// Prepares Search Core resources for CarPlay if needed.
    /// - Important:
    /// CarPlay search results may differ from the main application search results due to
    /// different resource sets and constraints.
    func prepareSearchUICoreForIfNeeded() {
        guard !isSearchUICorePrepared else { return }
        
        OAQuickSearchHelper.instance().setResourcesForSearchUICore()
        isSearchUICorePrepared = true
    }

    // MARK: - Apply appearance mode

    func applyCarPlayMapAppearance() {
        let mode = DayNightMode(rawValue: OAAppSettings.sharedManager().carPlayMapAppearanceMode.get()) ?? .appTheme
        switch mode {
        case .day, .night, .auto:
            OADayNightHelper.instance().setCarPlayMode(Int(mode.rawValue))
        case .appTheme:
            if let lastContentStyle {
                applyVehicleAppearance(with: lastContentStyle)
            } else if let style = sessionConfiguration?.contentStyle {
                applyVehicleAppearance(with: style)
            }
        }
    }
    
    private func applyVehicleAppearance(with contentStyle: CPContentStyle) {
        lastContentStyle = contentStyle
        if contentStyle.contains(.dark) {
            NSLog("[CarPlayService] vehicle appearance → night (%lu)", UInt(contentStyle.rawValue))
            OADayNightHelper.instance().setCarPlayMode(Int(DayNightMode.night.rawValue))
        } else if contentStyle.contains(.light) {
            NSLog("[CarPlayService] vehicle appearance → day (%lu)", UInt(contentStyle.rawValue))
            OADayNightHelper.instance().setCarPlayMode(Int(DayNightMode.day.rawValue))
        } else {
            NSLog("[CarPlayService] vehicle appearance: unknown contentStyle, keep previous")
        }
    }
    
    private func initSessionConfiguration() {
        guard sessionConfiguration == nil else { return }
        sessionConfiguration = CPSessionConfiguration(delegate: self)
        if let style = sessionConfiguration?.contentStyle {
            lastContentStyle = style
        }
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
        lastContentStyle = contentStyle
        let mode = DayNightMode(rawValue: OAAppSettings.sharedManager().carPlayMapAppearanceMode.get()) ?? .appTheme
        guard mode == .appTheme else {
            NSLog("[CarPlayService] contentStyle changed, ignored (map mode=%d)", mode.rawValue)
            return
        }
        applyVehicleAppearance(with: contentStyle)
    }
}
