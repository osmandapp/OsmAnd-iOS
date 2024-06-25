//
//  WeatherLayerSettingsViewController.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 25.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

final class WeatherLayerSettingsViewController: OABaseNavbarViewController {
    
    override func getTitle() -> String! {
        localizedString("shared_string_layers")
    }
    
    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_close")
    }
}
