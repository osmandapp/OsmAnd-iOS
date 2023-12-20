//
//  Plugin+Ext.swift
//  OsmAnd Maps
//
//  Created by Skalii on 20.12.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import Charts

extension OAPlugin {

    @objc func getOrderedLineDataSet(chart: LineChartView,
                                     analysis: OAGPXTrackAnalysis,
                                     graphType: GPXDataSetType,
                                     axisType: GPXDataSetAxisType,
                                     calcWithoutGaps: Bool,
                                     useRightAxis: Bool) -> GpxUIHelper.OrderedLineDataSet? {
        return nil
    }

    static func getOrderedLineDataSet(chart: LineChartView,
                                      analysis: OAGPXTrackAnalysis,
                                      graphType: GPXDataSetType,
                                      axisType: GPXDataSetAxisType,
                                      calcWithoutGaps: Bool,
                                      useRightAxis: Bool) -> GpxUIHelper.OrderedLineDataSet? {
        for plugin in Self.getAvailablePlugins() {
            let dataSet: GpxUIHelper.OrderedLineDataSet? = plugin.getOrderedLineDataSet(chart: chart, analysis: analysis, graphType: graphType, axisType: axisType, calcWithoutGaps: calcWithoutGaps, useRightAxis: useRightAxis)
            if let dataSet {
                return dataSet
            }
        }
        return nil
    }
}
