//
//  VehicleMetricAttributesUtils.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 05.03.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation
import DGCharts

@objcMembers
final class VehicleMetricAttributesUtils: NSObject {
    
    static func getAvailableGPXDataSetTypes(analysis: GpxTrackAnalysis, out: NSMutableArray) {
        for type in GPXDataSetType.allCases {
            guard type.getTypeGroup() == .vehicleMetrics else { continue }
            if analysis.hasData(tag: type.getDatakey()) {
                out.add([NSNumber(value: type.rawValue)])
            }
        }
    }
    
    static func createVehicleMetricsDataSet(plugin: VehicleMetricsPlugin, chart: LineChartView, analysis: GpxTrackAnalysis, graphType: GPXDataSetType, axisType: GPXDataSetAxisType, useRightAxis: Bool, drawFilled: Bool, calcWithoutGaps: Bool) -> GpxUIHelper.OrderedLineDataSet {
        let widgetType: OBDDataComputer.OBDTypeWidget? = OBDDataComputer.OBDTypeWidget.entries.first { widget in
            widget.requiredCommand.gpxTag == graphType.getDatakey()
        }
        
        let divX: Double = GpxUIHelper.getDivX(lineChart: chart, analysis: analysis, axisType: axisType, calcWithoutGaps: calcWithoutGaps)
        let pair: Pair<Double, Double>? = GpxUIHelper.getScalingY(graphType)
        let mulY: Double = pair?.first ?? 1
        let divY: Double = pair?.second ?? Double.nan
        let textColor: UIColor = graphType.getTextColor()
        let yAxis = GpxUIHelper.getYAxis(chart: chart, textColor: textColor, useRightAxis: useRightAxis)
        yAxis.axisMinimum = 0
        let values = getPointAttributeValues(plugin: plugin, key: graphType.getDatakey(), widgetType: widgetType, pointAttributes: analysis.pointAttributes as! [PointAttributes], axisType: axisType, divX: Float(divX), mulY: Float(mulY), divY: Float(divY), calcWithoutGaps: calcWithoutGaps)
        let dataSet = GpxUIHelper.OrderedLineDataSet(entries: values, label: "", dataSetType: graphType, dataSetAxisType: axisType, leftAxis: !useRightAxis)
        var format: String?
        if dataSet.yMax < 3 {
            format = "%.1f"
        }
        
        let formatY = format
        let mainUnitY = widgetType.flatMap { plugin.getWidgetUnit($0) } ?? ""
        yAxis.valueFormatter = GpxUIHelper.ValueFormatterLocal(formatX: formatY, unitsX: mainUnitY)
        dataSet.divX = divX
        dataSet.units = mainUnitY
        let color: UIColor = graphType.getFillColor()
        GpxUIHelper.setupDataSet(dataSet: dataSet, color: color, fillColor: color, drawFilled: drawFilled, drawCircles: false, useRightAxis: useRightAxis)
        return dataSet
    }
    
    private static func getPointAttributeValues(plugin: VehicleMetricsPlugin, key: String, widgetType: OBDDataComputer.OBDTypeWidget?, pointAttributes: [PointAttributes], axisType: GPXDataSetAxisType, divX: Float, mulY: Float, divY: Float, calcWithoutGaps: Bool) -> [ChartDataEntry] {
        var values: [ChartDataEntry] = []
        var currentX: Float = 0
        for (i, attribute) in pointAttributes.enumerated() {
            let stepX: Float = axisType == .time || axisType == .timeOfDay ? attribute.timeDiff : attribute.distance
            if i == 0 || stepX > 0 {
                if !(calcWithoutGaps && attribute.firstPoint) {
                    currentX += stepX / divX
                }
                
                if attribute.hasValidValue(tag: key) {
                    var value: Float = attribute.getAttributeValue(tag: key)
                    let formattedValue = widgetType.flatMap {
                        plugin.getWidgetConvertedValue(type: $0, data: value)
                    }
                    
                    if let number = formattedValue as? NSNumber {
                        value = number.floatValue
                    }
                    
                    var currentY: Float = divY.isNaN ? value * mulY : divY / value
                    if currentY < 0 || currentY.isInfinite {
                        currentY = 0
                    }
                    
                    if attribute.firstPoint && currentY != 0 {
                        values.append(ChartDataEntry(x: Double(currentX), y: 0))
                    }
                    
                    values.append(ChartDataEntry(x: Double(currentX), y: Double(currentY)))
                    if attribute.lastPoint && currentY != 0 {
                        values.append(ChartDataEntry(x: Double(currentX), y: 0))
                    }
                }
            }
        }
        
        return values
    }
}
