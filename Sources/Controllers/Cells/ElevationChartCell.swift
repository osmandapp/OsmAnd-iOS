//
//  ElevationChartCell.swift
//  OsmAnd Maps
//
//  Created by Skalii on 29.08.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation
import DGCharts

final class ElevationChartCell: UITableViewCell {
    
    @IBOutlet weak var chartView: ElevationChart!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    
}
