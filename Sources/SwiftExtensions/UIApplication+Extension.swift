//
//  UIApplication+Extension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 28.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

extension UIApplication {
    fileprivate enum Constants {
        static let defaultConfiguration = "Default Configuration"
        static let carPlayConfiguration = "CarPlay Configuration"
        static let carPlayDashboardConfiguration = "CarPlay-Dashboard Configuration"
    }
    
    @objc var mainWindow: UIWindow? {
        (mainScene as? UIWindowScene)?.keyWindow
    }
    
    @objc var mainScene: UIScene? {
        connectedScenes.first(where: { $0.session.configuration.name == Constants.defaultConfiguration })
    }
}

// MARK: - CarPlay
extension UIApplication {
    
    @objc var carPlayWindow: CPWindow? {
        return connectedScenes
            .compactMap { $0 as? CPTemplateApplicationScene }
            .first?
            .carWindow
    }
    
    /// Returns `true` if the app currently has any CarPlay-related scene connected.
    /// This includes both the main CarPlay app scene and the CarPlay Dashboard scene.
    ///
    /// Does **not** require the scene to be active on screen — only connected.
    @objc var isCarPlayConnected: Bool {
        safelyCheckConnectedScenes {
            connectedScenes.contains { scene in
                let name = scene.session.configuration.name
                return name == Constants.carPlayConfiguration || name == Constants.carPlayDashboardConfiguration
            }
        }
    }
    
    /// Returns `true` if the main CarPlay application scene is currently active (`foregroundActive`).
    ///
    /// This means the app is visible and interactable on the CarPlay display.
    @objc var isCarPlayAppActive: Bool {
        connectedScenes.contains {
            $0.session.configuration.name == Constants.carPlayConfiguration &&
            $0.activationState == .foregroundActive
        }
    }
    
    /// Returns `true` if the CarPlay Dashboard scene is currently active (`foregroundActive`).
    ///
    /// This indicates that the Dashboard UI is being shown on the CarPlay display.
    @objc var isCarPlayDashboardActive: Bool {
        connectedScenes.contains {
            $0.session.configuration.name == Constants.carPlayDashboardConfiguration &&
            $0.activationState == .foregroundActive
        }
    }
    
    /// Returns `true` if **any** CarPlay scene (App or Dashboard) is currently active.
    ///
    /// This combines `isCarPlayAppActive` and `isCarPlayDashboardActive`
    /// and can be used to check whether the app is currently displayed on CarPlay
    /// in any form.
    @objc var isAnyCarPlaySceneActive: Bool {
        isCarPlayAppActive || isCarPlayDashboardActive
    }
    
    @objc var carPlaySceneDelegate: CarPlaySceneDelegate? {
        guard let scene = connectedScenes.first(where: { $0.session.configuration.name == Constants.carPlayConfiguration && $0.activationState == .foregroundActive }) else {
            return nil
        }
        return scene.delegate as? CarPlaySceneDelegate
    }
    
    private func safelyCheckConnectedScenes(_ block: () -> Bool) -> Bool {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.sync { block() }
        }
    }
}

// MARK: - Scheme URL
extension UIApplication {
    @discardableResult
    @objc func openWunderLINQ() -> Bool {
        guard let url = URL(string: "wunderlinq://datagrid"), UIApplication.shared.canOpenURL(url) else {
            return false
        }
        UIApplication.shared.open(url)
        return true
    }
}
