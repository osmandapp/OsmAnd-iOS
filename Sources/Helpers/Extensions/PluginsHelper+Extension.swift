//
//  PluginsHelper+Extension.swift
//  OsmAnd Maps
//
//  Created by Alexey K on 31.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation
import DGCharts

extension OAPluginsHelper {

    static func getOrderedLineDataSet(chart: LineChartView,
                                      analysis: GpxTrackAnalysis,
                                      graphType: GPXDataSetType,
                                      axisType: GPXDataSetAxisType,
                                      calcWithoutGaps: Bool,
                                      useRightAxis: Bool) -> GpxUIHelper.OrderedLineDataSet? {
        for plugin in Self.getAvailablePlugins() {
            if let dataSet = plugin.getOrderedLineDataSet(chart: chart,
                                                          analysis: analysis,
                                                          graphType: graphType,
                                                          axisType: axisType,
                                                          calcWithoutGaps: calcWithoutGaps,
                                                          useRightAxis: useRightAxis) {
                return dataSet
            }
        }
        return nil
    }
}
