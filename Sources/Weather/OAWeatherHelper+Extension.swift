//
//  OAWeatherHelper+Extension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 25.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

extension OAWeatherHelper {
    
    @objc var allLayersAreDisabled: Bool {
        bands.map({ $0.isBandVisible()}).allSatisfy({!$0})
    }
}
