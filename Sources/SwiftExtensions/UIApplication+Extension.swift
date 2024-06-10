//
//  UIApplication+Extension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 28.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

extension UIApplication {
    fileprivate enum Constants {
        static let defaultConfiguration = "Default Configuration"
        static let carPlayConfiguration = "CarPlay Configuration"
    }
    
    @objc var mainWindow: UIWindow? {
        (mainScene as? UIWindowScene)?.keyWindow
    }
    
    @objc var mainScene: UIScene? {
        connectedScenes.first(where: { $0.session.configuration.name == Constants.defaultConfiguration })
    }
    
    @objc var carPlaySceneDelegate: CarPlaySceneDelegate? {
        guard let scene = connectedScenes.first(where: { $0.session.configuration.name == Constants.carPlayConfiguration && $0.activationState == .foregroundActive }) else {
            return nil
        }
        return scene.delegate as? CarPlaySceneDelegate
    }
}
