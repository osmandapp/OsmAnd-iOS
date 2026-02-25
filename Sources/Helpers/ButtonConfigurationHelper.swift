//
//  ButtonConfigurationHelper.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 24.02.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class ButtonConfigurationHelper: NSObject {
    
    static func purchasePlanButtonConfiguration(title: String) -> UIButton.Configuration {
        UIButton.Configuration.purchasePlanButtonConfiguration(title: title)
    }
}
