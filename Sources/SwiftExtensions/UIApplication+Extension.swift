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
        // Get connected scenes
        return connectedScenes
        // Keep only active scenes, onscreen and visible to the user
            .filter { $0.activationState == .foregroundActive }
        // Keep only the first `UIWindowScene`
            .first(where: { $0 is UIWindowScene })
        // Get its associated windows
            .flatMap({ $0 as? UIWindowScene })?.windows
        // Finally, keep only the key window
            .first(where: \.isKeyWindow)
    }
}
