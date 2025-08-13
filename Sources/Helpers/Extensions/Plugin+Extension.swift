//
//  Plugin+Extension.swift
//  OsmAnd Maps
//
//  Created by Skalii on 20.12.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import DGCharts

extension OAPlugin {

    @objc func getOrderedLineDataSet(chart: LineChartView,
                                     analysis: GpxTrackAnalysis,
                                     graphType: GPXDataSetType,
                                     axisType: GPXDataSetAxisType,
                                     calcWithoutGaps: Bool,
                                     useRightAxis: Bool) -> GpxUIHelper.OrderedLineDataSet? {
        return nil
    }
}
