//
//  DistanceByTapViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 01.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import Foundation

final class DistanceByTapViewController: OABaseNavbarViewController {
    weak var delegate: WidgetStateDelegate?
    
    override func getTitle() -> String {
        localizedString("map_widget_distance_by_tap")
    }
}
