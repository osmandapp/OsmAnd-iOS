//
//  UIApplication+Extension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 28.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

extension UIApplication {
    @objc var mainWindow: UIWindow? {
        (mainScene as? UIWindowScene)?.keyWindow
    }
    
    @objc var mainScene: UIScene? {
        connectedScenes.first(where: { $0.session.configuration.name == "Default Configuration" })
    }
}
