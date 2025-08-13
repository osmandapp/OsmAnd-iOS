//
//  ExternalSensorsPlugin+Extension.swift
//  OsmAnd Maps
//
//  Created by Skalii on 20.12.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import DGCharts
import OsmAndShared

extension OAExternalSensorsPlugin {
    @objc override func getOrderedLineDataSet(chart: LineChartView,
                                              analysis: GpxTrackAnalysis,
                                              graphType: GPXDataSetType,
                                              axisType: GPXDataSetAxisType,
                                              calcWithoutGaps: Bool,
                                              useRightAxis: Bool) -> GpxUIHelper.OrderedLineDataSet? {
        SensorAttributesUtils.getOrderedLineDataSet(chart: chart, analysis: analysis, graphType: graphType, axisType: axisType, calcWithoutGaps: calcWithoutGaps, useRightAxis: useRightAxis)
    }
}
