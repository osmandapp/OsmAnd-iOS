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
        mainScene
        // Get its associated windows
            .flatMap({ $0 as? UIWindowScene })?.windows
        // Finally, keep only the key window
            .first(where: \.isKeyWindow)
    }
    
    @objc var mainScene: UIScene? {
        connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first(where: { $0 is UIWindowScene })
    }
}
