//
//  GpxUIHelper.swift
//  OsmAnd
//
//  Created by Paul on 9/3/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

import UIKit
import DGCharts
import OsmAndShared

@objc enum GPXDataSetType: Int {
    case none, altitude, speed, slope, sensorSpeed, sensorHeartRate, sensorBikePower, sensorBikeCadence, sensorTemperatureA, sensorTemperatureW

    func getTitle() -> String {
        OAGPXDataSetType.getTitle(rawValue)
    }

    func getIconName() -> String {
        OAGPXDataSetType.getIconName(rawValue)
    }

    func getDatakey() -> String {
        OAGPXDataSetType.getDataKey(rawValue)
    }

    func getTextColor() -> UIColor {
        OAGPXDataSetType.getTextColor(rawValue)
    }

    func getFillColor() -> UIColor {
        OAGPXDataSetType.getFillColor(rawValue)
    }

    func getMainUnitY() -> String {
        OAGPXDataSetType.getMainUnitY(rawValue)
    }
}

@objc enum GPXDataSetAxisType: Int {
    case distance, time, timeOfDay

    func getName() -> String {
        switch self {
        case .distance:
            return OAUtilities.getLocalizedString("shared_string_distance")
        case .time:
            return OAUtilities.getLocalizedString("shared_string_time")
        case .timeOfDay:
            return OAUtilities.getLocalizedString("time_of_day")
        }
    }

    func getImageName() -> String {
        switch self {
        case .distance:
            return ""
        case .time:
            return ""
        case .timeOfDay:
            return ""
        }
    }
}

@objcMembers
class GpxUIHelper: NSObject {

    final class ValueFormatterLocal: AxisValueFormatter {

        private var formatX: String?
        private var unitsX: String

        init(formatX: String?, unitsX: String) {
            self.formatX = formatX
            self.unitsX = unitsX
        }

        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            let hasUnits = value == axis?.entries.first || axis is YAxis
            if let formatX, formatX.length > 0 {
                return String(format: formatX, value) + (hasUnits ? (" " + unitsX) : "")
            } else {
                return String(format: "%.0f", value) + (hasUnits ? (" " + unitsX) : "")
            }
        }
    }

    private class HeightFormatter: FillFormatter {
        func getFillLinePosition(dataSet: LineChartDataSetProtocol,
                                 dataProvider: LineChartDataProvider) -> CGFloat {
            CGFloat(dataProvider.chartYMin)
        }
    }

    private class TimeFormatter: AxisValueFormatter {

        private var useHours: Bool

        init(useHours: Bool) {
            self.useHours = useHours
        }

        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            let seconds = Int(value)
            if useHours {
                let hours = seconds / (60 * 60)
                let minutes = (seconds / 60) % 60
                let sec = seconds % 60
                let strHours = String(hours)
                let strMinutes = String(minutes)
                let strSeconds = String(sec)
                return strHours + ":" + (minutes < 10 ? "0" + strMinutes : strMinutes) + ":" + (sec < 10 ? "0" + strSeconds : strSeconds)
            } else {
                let minutes = (seconds / 60) % 60
                let sec = seconds % 60
                let strMinutes = String(minutes)
                let strSeconds = String(sec)
                return (minutes < 10 ? "0" + strMinutes : strMinutes) + ":" + (sec < 10 ? "0" + strSeconds : strSeconds)
            }
        }
    }

    private class TimeSpanFormatter: AxisValueFormatter {
        private var startTime: Int64

        init(startTime: Int64) {
            self.startTime = startTime
        }

        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            let seconds = Double(startTime / 1000) + value
            let date = Date(timeIntervalSince1970: seconds)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss"
            dateFormatter.timeZone = .current
            return dateFormatter.string(from: date)
        }
    }

    final class OrderedLineDataSet: LineChartDataSet, IOrderedLineDataSet {

        private let leftAxis: Bool

        var units: String
        var priority: Float
        var divX: Double = 1

        private var dataSetType: GPXDataSetType
        private var dataSetAxisType: GPXDataSetAxisType

        init(entries: [ChartDataEntry],
             label: String,
             dataSetType: GPXDataSetType,
             dataSetAxisType: GPXDataSetAxisType,
             leftAxis: Bool) {
            self.dataSetType = dataSetType
            self.dataSetAxisType = dataSetAxisType
            self.priority = 0
            self.units = ""
            self.leftAxis = leftAxis
            super.init(entries: entries, label: label)
            self.mode = LineChartDataSet.Mode.linear
        }

        required init() {
            fatalError("init() has not been implemented")
        }

        func getDataSetType() -> GPXDataSetType {
            dataSetType
        }

        func getDataSetAxisType() -> GPXDataSetAxisType {
            dataSetAxisType
        }

        func isLeftAxis() -> Bool {
            leftAxis
        }
    }

    public class GPXChartMarker: MarkerView {
        
        private let widthOffset: CGFloat = 3.0
        private let heightOffset: CGFloat = 2.0
        private let textLayer = CATextLayer()
        private let outlineLayer = CALayer()

        private var text: NSAttributedString = NSAttributedString(string: "")

        override init(frame: CGRect) {
            super.init(frame: frame)

            setupLayers()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)

            setupLayers()
        }

        private func setupLayers() {
            outlineLayer.borderColor = UIColor.chartSliderLabelStroke.cgColor
            outlineLayer.backgroundColor = UIColor.chartSliderLabelBg.cgColor
            outlineLayer.borderWidth = 1.0
            outlineLayer.cornerRadius = 2.0

            textLayer.alignmentMode = .center
            textLayer.contentsScale = UIScreen.main.scale

            outlineLayer.addSublayer(textLayer)
        }

        override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
            super.refreshContent(entry: entry, highlight: highlight)

            let chartData = chartView?.data
            let res = NSMutableAttributedString(string: "")

            if chartData?.dataSetCount ?? 0 == 1 {
                let dataSet = chartData?.dataSets[0] as! OrderedLineDataSet
                res.append(NSAttributedString(string: "\(lround(entry.y)) " + dataSet.units,
                                              attributes: [.foregroundColor: dataSet.color(atIndex: 0)]))
            } else if chartData?.dataSetCount ?? 0 == 2 {
                let dataSet1 = chartData?.dataSets[0] as! OrderedLineDataSet
                let dataSet2 = chartData?.dataSets[1] as! OrderedLineDataSet
                let useFirst = dataSet1.visible
                let useSecond = dataSet2.visible

                if useFirst {
                    let entry1 = dataSet1.entryForXValue(entry.x, closestToY: Double.nan, rounding: .up)
                    res.append(NSAttributedString(string: "\(lround(entry1?.y ?? 0)) " + dataSet1.units,
                                                  attributes: [.foregroundColor: dataSet1.color(atIndex: 0)]))
                }
                if useSecond {
                    let entry2 = dataSet2.entryForXValue(entry.x, closestToY: Double.nan, rounding: .up)
                    if useFirst {
                        res.append(NSAttributedString(string: ", \(lround(entry2?.y ?? 0)) " + dataSet2.units,
                                                      attributes: [.foregroundColor: dataSet2.color(atIndex: 0)]))
                    } else {
                        res.append(NSAttributedString(string: "\(lround(entry2?.y ?? 0)) " + dataSet2.units,
                                                      attributes: [.foregroundColor: dataSet2.color(atIndex: 0)]))
                    }
                }
            }
            text = res
            textLayer.string = res
        }

        override func draw(context: CGContext, point: CGPoint) {
            super.draw(context: context, point: point)

            context.saveGState()
            context.setLineDash(phase: 0, lengths: [])

            bounds.size = text.size()
            offset = CGPoint(x: 0.0, y: 0.0)

            let offset = offsetForDrawing(atPoint: CGPoint(x: point.x - text.size().width / 2 + widthOffset,
                                                           y: point.y))
            let labelRect = CGRect(origin: CGPoint(x: point.x - text.size().width / 2 + offset.x, y: heightOffset),
                                   size: bounds.size)

            outlineLayer.bounds = CGRect(origin: CGPoint(x: labelRect.origin.x - widthOffset,
                                                         y: labelRect.origin.y),
                                    size: CGSize(width: labelRect.size.width + widthOffset * 2,
                                                 height: labelRect.size.height + heightOffset * 2))
            textLayer.frame = labelRect
            outlineLayer.render(in: context)
            context.restoreGState()
        }

        override func offsetForDrawing(atPoint point: CGPoint) -> CGPoint {
            guard let chartView else { return offset }

            var offset = offset
            let width = bounds.size.width
            let height = bounds.size.height

            if point.x + offset.x < chartView.extraLeftOffset {
                offset.x = -point.x + chartView.extraLeftOffset + widthOffset * 2
            } else if point.x + width + offset.x > chartView.bounds.size.width - chartView.extraRightOffset {
                offset.x = chartView.bounds.size.width - point.x - width - chartView.extraRightOffset
            }

            if point.y + offset.y < 0 {
                offset.y = -point.y
            } else if point.y + height + offset.y > chartView.bounds.size.height {
                offset.y = chartView.bounds.size.height - point.y - height
            }

            return offset
        }
    }

    static let metersInKilometer = 1000.0
    static let metersInOneNauticalmile = 1852.0
    static let metersInOneMile = 1609.344
    static let feetInOneMeter = 3.2808
    static let yardsInOneMeter = 1.0936

    private static let maxChartDataItems = 10000.0

    static func getDivX(dataSet: ChartDataSetProtocol) -> Double {
        (dataSet as? OrderedLineDataSet)?.divX ?? 0
    }

    static func getDataSetAxisType(dataSet: ChartDataSetProtocol) -> GPXDataSetAxisType {
        (dataSet as? OrderedLineDataSet)?.getDataSetAxisType() ?? GPXDataSetAxisType.distance
    }

    static func refreshLineChart(chartView: ElevationChart,
                                 analysis: GpxTrackAnalysis,
                                 firstType: GPXDataSetType,
                                 secondType: GPXDataSetType,
                                 axisType: GPXDataSetAxisType,
                                 calcWithoutGaps: Bool) {
        chartView.clear()
        chartView.data = LineChartData(dataSets:
                                        Self.getDataSets(chartView: chartView,
                                                         analysis: analysis,
                                                         firstType: firstType,
                                                         secondType: secondType,
                                                         gpxDataSetAxisType: axisType,
                                                         calcWithoutGaps: calcWithoutGaps))
    }

    static func refreshBarChart(chartView: HorizontalBarChartView,
                                statistics: OARouteStatistics,
                                analysis: GpxTrackAnalysis,
                                nightMode: Bool) {
        setupHorizontalGPXChart(chart: chartView,
                                yLabelsCount: 4,
                                topOffset: 20,
                                bottomOffset: 4,
                                useGesturesAndScale: true,
                                nightMode: nightMode)
        chartView.extraLeftOffset = 16
        chartView.extraRightOffset = 16
        let barData = buildStatisticChart(chartView: chartView,
                                          routeStatistics: statistics,
                                          analysis: analysis,
                                          useRightAxis: true,
                                          nightMode: nightMode)
        chartView.data = barData
    }

    static func setupHorizontalGPXChart(chart: HorizontalBarChartView,
                                        yLabelsCount: Int,
                                        topOffset: CGFloat,
                                        bottomOffset: CGFloat,
                                        useGesturesAndScale: Bool,
                                        nightMode: Bool) {
        chart.isUserInteractionEnabled = useGesturesAndScale
        chart.dragEnabled = useGesturesAndScale
        chart.scaleYEnabled = false
        chart.autoScaleMinMaxEnabled = true
        chart.drawBordersEnabled = true
        chart.chartDescription.enabled = false
        chart.dragDecelerationEnabled = false
        chart.highlightPerTapEnabled = false
        chart.highlightPerDragEnabled = true
        chart.renderer = HorizontalBarChartRenderer(dataProvider: chart,
                                                    animator: chart.chartAnimator,
                                                    viewPortHandler: chart.viewPortHandler)
        chart.extraTopOffset = topOffset
        chart.extraBottomOffset = bottomOffset

        let xl = chart.xAxis
        xl.drawLabelsEnabled = false
        xl.enabled = false
        xl.drawAxisLineEnabled = false
        xl.drawGridLinesEnabled = false

        let yl = chart.leftAxis
        yl.labelCount = yLabelsCount
        yl.drawLabelsEnabled = false
        yl.enabled = false
        yl.drawAxisLineEnabled = false
        yl.drawGridLinesEnabled = false
        yl.axisMinimum = 0.0

        let yr = chart.rightAxis
        yr.labelCount = yLabelsCount
        yr.drawAxisLineEnabled = false
        yr.drawGridLinesEnabled = false
        yr.axisMinimum = 0.0

        chart.minOffset = 16

        let mainFontColor = nightMode ? UIColor(rgbValue: color_icon_color_light) : .black
        yl.labelTextColor = mainFontColor
        yr.labelTextColor = mainFontColor

        chart.fitBars = true
        chart.highlightFullBarEnabled = false
        chart.borderColor = nightMode ? UIColor(rgbValue: color_icon_color_light) : .black
        chart.legend.enabled = false
    }

    static func setupElevationChart(chartView: ElevationChart) {
        let marker = GPXChartMarker(frame: CGRect(x: 0, y: 0, width: 80, height: 40))
        setupElevationChart(chartView: chartView,
                            markerView: marker,
                            topOffset: 24,
                            bottomOffset: 16,
                            useGesturesAndScale: true)
    }

    static func setupElevationChart(chartView: ElevationChart,
                                    topOffset: CGFloat,
                                    bottomOffset: CGFloat,
                                    useGesturesAndScale: Bool) {
        let marker = GPXChartMarker(frame: CGRect(x: 0, y: 0, width: 80, height: 40))
        setupElevationChart(chartView: chartView,
                            markerView: marker,
                            topOffset: topOffset,
                            bottomOffset: bottomOffset,
                            useGesturesAndScale: useGesturesAndScale)
    }

    static func setupElevationChart(chartView: ElevationChart,
                                    markerView: GPXChartMarker,
                                    topOffset: CGFloat,
                                    bottomOffset: CGFloat,
                                    useGesturesAndScale: Bool) {
        let axisGridColor = UIColor.chartAxisGridLine
        chartView.setupGPXChart(markerView: markerView,
                                topOffset: topOffset,
                                bottomOffset: bottomOffset,
                                xAxisGridColor: axisGridColor,
                                labelsColor: UIColor.textColorSecondary,
                                yAxisGridColor: axisGridColor,
                                useGesturesAndScale: useGesturesAndScale)
    }
    
    static func setupGradientChart(chart: LineChartView,
                                   useGesturesAndScale: Bool,
                                   xAxisGridColor: UIColor,
                                   labelsColor: UIColor) {
        chart.extraRightOffset = 20.0
        chart.extraLeftOffset = 20.0

        chart.isUserInteractionEnabled = useGesturesAndScale
        chart.dragEnabled = useGesturesAndScale
        chart.setScaleEnabled(useGesturesAndScale)
        chart.pinchZoomEnabled = useGesturesAndScale
        chart.scaleYEnabled = false
        chart.autoScaleMinMaxEnabled = true
        chart.drawBordersEnabled = false
        chart.chartDescription.enabled = false
        chart.maxVisibleCount = 10
        chart.minOffset = 0.0
        chart.dragDecelerationEnabled = false
        chart.drawGridBackgroundEnabled = false

        let xAxis = chart.xAxis
        xAxis.drawAxisLineEnabled = true
        xAxis.axisLineWidth = 1.0
        xAxis.axisLineDashPhase = 0.0
        xAxis.axisLineColor = xAxisGridColor
        xAxis.drawGridLinesEnabled = false
        xAxis.labelPosition = .bottom
        xAxis.labelTextColor = labelsColor
        xAxis.avoidFirstLastClippingEnabled = true
        xAxis.enabled = true

        let leftYAxis = chart.leftAxis
        leftYAxis.enabled = false

        let rightYAxis = chart.rightAxis
        rightYAxis.enabled = false

        let legend = chart.legend
        legend.enabled = false
    }

    static func buildGradientChart(chart: LineChartView,
                                   colorPalette: ColorPalette,
                                   valueFormatter: AxisValueFormatter) -> LineChartData {
        chart.xAxis.valueFormatter = valueFormatter

        let colorValues = colorPalette.colorValues
        var cgColors = [CGColor]()
        var entries = [ChartDataEntry]()

        for i in 0..<colorValues.count {
            let clr = colorValues[i].clr
            cgColors.append(UIColor(argb: clr).cgColor)
            entries.append(ChartDataEntry(x: colorValues[i].val, y: 0))
        }

        let barDataSet = LineChartDataSet(entries: entries, label: "")
        barDataSet.highlightColor = .textColorSecondary
        // [START] Disable circles and lines
        barDataSet.drawCirclesEnabled = false
        barDataSet.drawCircleHoleEnabled = false
        barDataSet.setColor(.clear)
        // [END] Disable circles and lines

        let step = 1.0 / CGFloat(colorValues.count - 1)
        var colorLocations = [CGFloat]()
        for i in 0...colorValues.count - 1 {
            colorLocations.append(CGFloat(i) * step)
        }
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: cgColors as CFArray,
                                     locations: colorLocations) {
            barDataSet.fill = LinearGradientFill(gradient: gradient)
            barDataSet.fillAlpha = 1.0
            barDataSet.drawFilledEnabled = true
        }

        let dataSet = LineChartData(dataSet: barDataSet)
        dataSet.setDrawValues(false)
        return dataSet
    }

    static func getScalingY(_ graphType: GPXDataSetType) -> Pair<Double, Double>? {
        if graphType == GPXDataSetType.speed || graphType == GPXDataSetType.sensorSpeed {
            var mulSpeed: Double = Double.nan
            var divSpeed: Double = Double.nan
            let speedConstants: EOASpeedConstant = OAAppSettings.sharedManager().speedSystem.get()
            if speedConstants == EOASpeedConstant.KILOMETERS_PER_HOUR {
                mulSpeed = 3.6
            } else if speedConstants == EOASpeedConstant.MILES_PER_HOUR {
                mulSpeed = 3.6 * GpxUIHelper.metersInKilometer / GpxUIHelper.metersInOneMile
            } else if speedConstants == EOASpeedConstant.NAUTICALMILES_PER_HOUR {
                mulSpeed = 3.6 * GpxUIHelper.metersInKilometer / GpxUIHelper.metersInOneNauticalmile
            } else if speedConstants == EOASpeedConstant.MINUTES_PER_KILOMETER {
                divSpeed = GpxUIHelper.metersInKilometer / 60.0
            } else if speedConstants == EOASpeedConstant.MINUTES_PER_MILE {
                divSpeed = GpxUIHelper.metersInOneMile / 60.0
            } else {
                mulSpeed = 1
            }
            return Pair(mulSpeed, divSpeed)
        }
        return nil
    }

    static func getDivX(lineChart: LineChartView,
                        analysis: GpxTrackAnalysis,
                        axisType: GPXDataSetAxisType,
                        calcWithoutGaps: Bool) -> Double {
        let xAxis: XAxis = lineChart.xAxis
        if axisType == .time && analysis.isTimeSpecified() {
            return setupXAxisTime(xAxis: xAxis,
                                  timeSpan: Int64(calcWithoutGaps ? analysis.timeSpanWithoutGaps : analysis.timeSpan))
        } else if axisType == .timeOfDay && analysis.isTimeSpecified() {
            return setupXAxisTimeOfDay(xAxis: xAxis,
                                       startTime: Int64(analysis.startTime))
        } else {
            return setupAxisDistance(axisBase: xAxis,
                                     meters: Double(calcWithoutGaps ? analysis.totalDistanceWithoutGaps : analysis.totalDistance))
        }
    }

    static func getYAxis(chart: LineChartView, textColor: UIColor, useRightAxis: Bool) -> YAxis {
        let yAxis: YAxis = useRightAxis ? chart.rightAxis : chart.leftAxis
        yAxis.enabled = true
        yAxis.labelTextColor = textColor
        yAxis.labelBackgroundColor = UIColor.chartAxisValueBg
        return yAxis
    }

    static func getPointAttributeValues(key: String,
                                        pointAttributes: [PointAttributes],
                                        axisType: GPXDataSetAxisType,
                                        divX: Double,
                                        mulY: Double,
                                        divY: Double,
                                        calcWithoutGaps: Bool) -> [ChartDataEntry] {
        var values: [ChartDataEntry] = []
        var currentX: Double = 0

        for i in 0..<pointAttributes.count {
            let attribute: PointAttributes = pointAttributes[i]
            let stepX: Double = Double(axisType == .time || axisType == .timeOfDay ? attribute.timeDiff : attribute.distance)
            if i == 0 || stepX > 0 {
                if !(calcWithoutGaps && attribute.firstPoint) {
                    currentX += stepX / divX
                }
                if attribute.hasValidValue(for: key) {
                    let value: Float = attribute.getAttributeValue(for: key) ?? 1
                    var currentY: Float = divY.isNaN ? value * Float(mulY) : Float(divY) / value
                    if currentY < 0 || currentY.isInfinite {
                        currentY = 0
                    }
                    if attribute.firstPoint && currentY != 0 {
                        values.append(ChartDataEntry(x: currentX, y: 0))
                    }
                    values.append(ChartDataEntry(x: currentX, y: Double(currentY)))
                    if attribute.lastPoint && currentY != 0 {
                        values.append(ChartDataEntry(x: currentX, y: 0))
                    }
                }
            }
        }
        return values
    }

    static func setupDataSet(dataSet: OrderedLineDataSet,
                             color: UIColor,
                             fillColor: UIColor,
                             drawFilled: Bool,
                             drawCircles: Bool,
                             useRightAxis: Bool) {
        if drawCircles {
            dataSet.setCircleColor(color)
            dataSet.circleRadius = 3
            dataSet.circleHoleColor = UIColor.black
            dataSet.circleHoleRadius = 2
            dataSet.drawCircleHoleEnabled = false
            dataSet.drawCirclesEnabled = true
            dataSet.setColor(UIColor.black)
        } else {
            dataSet.drawCirclesEnabled = false
            dataSet.drawCircleHoleEnabled = false
            dataSet.setColor(color)
        }
        dataSet.lineWidth = 1
        if drawFilled && !drawCircles {
            dataSet.fillAlpha = 0.1
            dataSet.fillColor = fillColor
        }
        dataSet.drawFilledEnabled = drawFilled && !drawCircles
        dataSet.drawValuesEnabled = false
        if drawCircles {
            dataSet.highlightEnabled = false
            dataSet.drawVerticalHighlightIndicatorEnabled = false
            dataSet.drawHorizontalHighlightIndicatorEnabled = false
        } else {
            dataSet.valueFont = UIFont.systemFont(ofSize: 9)
            dataSet.formLineWidth = 1
            dataSet.formSize = 15
            dataSet.highlightEnabled = true
            dataSet.drawVerticalHighlightIndicatorEnabled = true
            dataSet.drawHorizontalHighlightIndicatorEnabled = false
            dataSet.highlightColor = .chartSliderLine
        }
        if useRightAxis {
            dataSet.axisDependency = YAxis.AxisDependency.right
        }
    }

    static func getDataSets(chartView: LineChartView?,
                            analysis: GpxTrackAnalysis?,
                            firstType: GPXDataSetType,
                            secondType: GPXDataSetType,
                            gpxDataSetAxisType: GPXDataSetAxisType,
                            calcWithoutGaps: Bool) -> [LineChartDataSet] {
        guard let chartView, let analysis else {
            return [LineChartDataSet]()
        }
        var result = [LineChartDataSet]()
        if secondType == .none {
            if let dataSet = getDataSet(chartView: chartView,
                                        analysis: analysis,
                                        type: firstType,
                                        otherType: nil,
                                        gpxDataSetAxisType: gpxDataSetAxisType,
                                        calcWithoutGaps: calcWithoutGaps,
                                        useRightAxis: false) {
                result.append(dataSet)
            }
        } else {
            let dataSet1 = getDataSet(chartView: chartView,
                                      analysis: analysis,
                                      type: firstType,
                                      otherType: secondType,
                                      gpxDataSetAxisType: gpxDataSetAxisType,
                                      calcWithoutGaps: calcWithoutGaps,
                                      useRightAxis: false)
            let dataSet2 = getDataSet(chartView: chartView,
                                      analysis: analysis,
                                      type: secondType,
                                      otherType: firstType,
                                      gpxDataSetAxisType: gpxDataSetAxisType,
                                      calcWithoutGaps: calcWithoutGaps,
                                      useRightAxis: true)
            guard let dataSet1 else {
                if let dataSet2 {
                    result.append(dataSet2)
                }
                return result
            }
            guard let dataSet2 else {
                result.append(dataSet1)
                return result
            }

            if dataSet1.priority < dataSet2.priority {
                result.append(dataSet2)
                result.append(dataSet1)
            } else {
                result.append(dataSet1)
                result.append(dataSet2)
            }
        }
        /* Do not show extremums because of too heavy approximation
         if ((firstType == GPXDataSetType.ALTITUDE || secondType == GPXDataSetType.ALTITUDE)
         && PluginsHelper.isActive(OsmandDevelopmentPlugin.class)) {
         OrderedLineDataSet dataSet = getDataSet(app, chart, analysis, GPXDataSetType.ALTITUDE_EXTRM, calcWithoutGaps, false);
         if (dataSet != null) {
         result.add(dataSet);
         }
         }
         */
        return result
    }
    
    private static func getDataSet(chartView: LineChartView,
                                   analysis: GpxTrackAnalysis,
                                   type: GPXDataSetType,
                                   otherType: GPXDataSetType?,
                                   gpxDataSetAxisType: GPXDataSetAxisType,
                                   calcWithoutGaps: Bool,
                                   useRightAxis: Bool) -> OrderedLineDataSet? {
        switch type {
        case .altitude:
            return createGPXElevationDataSet(chartView: chartView,
                                             analysis: analysis,
                                             graphType: type,
                                             axisType: gpxDataSetAxisType,
                                             useRightAxis: useRightAxis,
                                             drawFilled: true,
                                             calcWithoutGaps: calcWithoutGaps)
        case .slope:
            return createGPXSlopeDataSet(chartView: chartView,
                                         analysis: analysis,
                                         graphType: type,
                                         axisType: gpxDataSetAxisType,
                                         eleValues: nil,
                                         useRightAxis: useRightAxis,
                                         drawFilled: true,
                                         calcWithoutGaps: calcWithoutGaps)
        case .speed:
            return createGPXSpeedDataSet(chartView: chartView,
                                         analysis: analysis,
                                         graphType: type,
                                         axisType: gpxDataSetAxisType,
                                         useRightAxis: useRightAxis,
                                         setYAxisMinimum: true,
                                         drawFilled: true,
                                         calcWithoutGaps: calcWithoutGaps)
        default:
            return OAPluginsHelper.getOrderedLineDataSet(chart: chartView,
                                                         analysis: analysis,
                                                         graphType: type,
                                                         axisType: gpxDataSetAxisType,
                                                         calcWithoutGaps: calcWithoutGaps,
                                                         useRightAxis: useRightAxis)
        }
    }

    private static func buildStatisticChart(chartView: HorizontalBarChartView,
                                            routeStatistics: OARouteStatistics,
                                            analysis: GpxTrackAnalysis,
                                            useRightAxis: Bool,
                                            nightMode: Bool) -> BarChartData {
        let xAxis = chartView.xAxis
        xAxis.enabled = false

        var yAxis: YAxis
        if useRightAxis {
            yAxis = chartView.rightAxis
            yAxis.enabled = true
        } else {
            yAxis = chartView.leftAxis
        }
        let divX = setupAxisDistance(axisBase: yAxis, meters: Double(analysis.totalDistance))
        let segments = routeStatistics.elements
        var entries = [BarChartDataEntry]()
        var stacks = Array(repeating: 0 as Double, count: segments?.count ?? 0)
        var colors = Array(repeating: NSUIColor(cgColor: UIColor.white.cgColor), count: segments?.count ?? 0)

        if let segments {
            for i in 0..<stacks.count {
                let segment = segments[i]
                stacks[i] = Double(segment.distance) / divX
                colors[i] = NSUIColor(cgColor: UIColor(argbValue: UInt32(segment.color)).cgColor)
            }
        }

        entries.append(BarChartDataEntry(x: 0, yValues: stacks))

        let barDataSet = BarChartDataSet(entries: entries, label: "")
        barDataSet.colors = colors
        barDataSet.highlightColor = UIColor(rgbValue: color_primary_purple)

        let dataSet = BarChartData(dataSet: barDataSet)
        dataSet.setDrawValues(false)
        dataSet.barWidth = 1

        chartView.rightAxis.axisMaximum = dataSet.yMax
        chartView.leftAxis.axisMaximum = dataSet.yMax
        return dataSet
    }

    private static func createGPXElevationDataSet(chartView: LineChartView,
                                                  analysis: GpxTrackAnalysis,
                                                  graphType: GPXDataSetType,
                                                  axisType: GPXDataSetAxisType,
                                                  useRightAxis: Bool,
                                                  drawFilled: Bool,
                                                  calcWithoutGaps: Bool) -> OrderedLineDataSet {
        let useFeet: Bool = OAMetricsConstant.shouldUseFeet(OAAppSettings.sharedManager().metricSystem.get())
        let convEle: Double = useFeet ? 3.28084 : 1.0
        let divX: Double = getDivX(lineChart: chartView,
                                   analysis: analysis,
                                   axisType: axisType,
                                   calcWithoutGaps: calcWithoutGaps)
        let mainUnitY: String = graphType.getMainUnitY()
        let yAxis = getYAxis(chart: chartView,
                             textColor: .chartTextColorElevation,
                             useRightAxis: useRightAxis)
        yAxis.granularity = 1
        yAxis.resetCustomAxisMin()
        yAxis.valueFormatter = ValueFormatterLocal(formatX: nil, unitsX: mainUnitY)
        let values = calculateElevationArray(analysis: analysis,
                                             axisType: axisType,
                                             divX: divX,
                                             convEle: convEle,
                                             useGeneralTrackPoints: true,
                                             calcWithoutGaps: calcWithoutGaps)
        let dataSet = OrderedLineDataSet(entries: values,
                                         label: "",
                                         dataSetType: graphType,
                                         dataSetAxisType: axisType,
                                         leftAxis: !useRightAxis)
        dataSet.priority = Float((analysis.avgElevation - analysis.minElevation) * convEle)
        dataSet.divX = divX
        dataSet.units = mainUnitY

        let color = graphType.getFillColor()
        setupDataSet(dataSet: dataSet,
                     color: color,
                     fillColor: color,
                     drawFilled: drawFilled,
                     drawCircles: false,
                     useRightAxis: useRightAxis)
        dataSet.fillFormatter = HeightFormatter()
        return dataSet
    }

    private static func createGPXSlopeDataSet(chartView: LineChartView,
                                              analysis: GpxTrackAnalysis,
                                              graphType: GPXDataSetType,
                                              axisType: GPXDataSetAxisType,
                                              eleValues: [ChartDataEntry]?,
                                              useRightAxis: Bool,
                                              drawFilled: Bool,
                                              calcWithoutGaps: Bool) -> OrderedLineDataSet? {
        if axisType == GPXDataSetAxisType.time || axisType == GPXDataSetAxisType.timeOfDay {
            return nil
        }
        let mc: EOAMetricsConstant = OAAppSettings.sharedManager().metricSystem.get()
        let useFeet: Bool = (mc == EOAMetricsConstant.MILES_AND_FEET) || (mc == EOAMetricsConstant.MILES_AND_YARDS) || (mc == EOAMetricsConstant.NAUTICAL_MILES_AND_FEET)
        let convEle: Double = useFeet ? 3.28084 : 1.0
        let totalDistance: Double = calcWithoutGaps
        	? Double(analysis.totalDistanceWithoutGaps)
        	: Double(analysis.totalDistance)
        let divX: Double = getDivX(lineChart: chartView,
                                   analysis: analysis,
                                   axisType: axisType,
                                   calcWithoutGaps: calcWithoutGaps)
        let mainUnitY: String = graphType.getMainUnitY()
        let yAxis: YAxis = getYAxis(chart: chartView,
                                    textColor: UIColor.chartTextColorSlope,
                                    useRightAxis: useRightAxis)
        yAxis.granularity = 1.0
        yAxis.resetCustomAxisMin()
        yAxis.valueFormatter = ValueFormatterLocal(formatX: nil, unitsX: mainUnitY)

        var values = [ChartDataEntry]()
        if let eleValues {
            for e in eleValues {
                values.append(ChartDataEntry(x: e.x * divX, y: e.y / convEle))
            }
        } else {
            values = calculateElevationArray(analysis: analysis,
                                             axisType: .distance,
                                             divX: 1.0,
                                             convEle: 1.0,
                                             useGeneralTrackPoints: false,
                                             calcWithoutGaps: calcWithoutGaps)
        }

        if values.isEmpty {
            if useRightAxis {
                yAxis.enabled = false
            }
            return nil
        }

        var lastIndex = values.count - 1
        var step: Double = 5
        var l: Int = 10

        while l > 0 && totalDistance / step > Self.maxChartDataItems {
            step = max(step, totalDistance / Double(values.count * l))
            l -= 1
        }

        let interpolator = GPXInterpolator(pointsCount: values.count, totalLength: totalDistance, step: step,
                                           getX: { index in return values[index].x },
                                           getY: { index in return values[index].y })
        interpolator.interpolate()

        let calculatedDist = interpolator.getCalculatedX()
        let calculatedH = interpolator.getCalculatedY()
        if calculatedDist.isEmpty || calculatedH.isEmpty {
            return nil
        }

        let slopeProximity: Double = max(20, step * 2)
        if totalDistance - slopeProximity < 0 {
            if useRightAxis {
                yAxis.enabled = false
            }
            return nil
        }

        var calculatedSlopeDist: [Double] = Array(repeating: 0, count: Int((totalDistance / step)) + 1)
        var calculatedSlope: [Double] = Array(repeating: 0, count: Int((totalDistance / step)) + 1)
        let threshold = max(2, Int((slopeProximity / step) / 2))

        if calculatedSlopeDist.count <= 4 {
            return nil
        }
        for k in 0..<calculatedSlopeDist.count {
            calculatedSlopeDist[k] = calculatedDist[k]

            if k < threshold {
                calculatedSlope[k] = (-1.5 * calculatedH[k] + 2.0 * calculatedH[k + 1] - 0.5 * calculatedH[k + 2]) * 100 / step
            } else if k >= calculatedSlopeDist.count - threshold {
                calculatedSlope[k] = (0.5 * calculatedH[k - 2] - 2.0 * calculatedH[k - 1] + 1.5 * calculatedH[k]) * 100 / step
            } else {
                calculatedSlope[k] = (calculatedH[threshold + k] - calculatedH[k - threshold]) * 100 / slopeProximity
            }
            if calculatedSlope[k].isNaN { // }|| abs(calculatedSlope[k]) > 1000 {
                calculatedSlope[k] = 0
            }
        }

        var slopeValues = [ChartDataEntry]()
        var prevSlope: Double = -80000
        var slope: Double
        var x: Double
        var lastXSameY: Double = 0
        var hasSameY = false
        var lastEntry: ChartDataEntry?
        lastIndex = calculatedSlopeDist.count - 1
        let timeSpanInSeconds = Double(analysis.timeSpan) / 1000.0
        for i in 0..<calculatedSlopeDist.count {
            if (axisType == .timeOfDay || axisType == .time), analysis.isTimeSpecified() {
                x = (timeSpanInSeconds * Double(i)) / Double(calculatedSlopeDist.count)
            } else {
                x = calculatedSlopeDist[i] / divX
            }
            slope = calculatedSlope[i]
            if prevSlope != -80000 {
                if prevSlope == slope && i < lastIndex {
                    hasSameY = true
                    lastXSameY = x
                    continue
                }
                if hasSameY, let lastEntry {
                    slopeValues.append(ChartDataEntry(x: lastXSameY, y: lastEntry.y))
                }
                hasSameY = false
            }
            prevSlope = slope
            lastEntry = ChartDataEntry(x: x, y: slope)
            if let lastEntry {
                slopeValues.append(lastEntry)
            }
        }

        let dataSet = OrderedLineDataSet(entries: slopeValues,
                                         label: "",
                                         dataSetType: .slope,
                                         dataSetAxisType: axisType,
                                         leftAxis: !useRightAxis)
        dataSet.divX = divX
        dataSet.units = mainUnitY

        let color = graphType.getFillColor()
        GpxUIHelper.setupDataSet(dataSet: dataSet,
                                 color: color,
                                 fillColor: color,
                                 drawFilled: drawFilled,
                                 drawCircles: false,
                                 useRightAxis: useRightAxis)
        return dataSet
    }

    private static func setupAxisDistance(axisBase: AxisBase, meters: Double) -> Double {
        let settings: OAAppSettings = OAAppSettings.sharedManager()
        let mc: EOAMetricsConstant = settings.metricSystem.get()
        var divX: Double = 0

        let format1 = "%.0f"
        let format2 = "%.1f"
        var fmt: String?
        var granularity: Double = 1
        var mainUnitStr: String
        var mainUnitInMeters: Double
        if mc == EOAMetricsConstant.KILOMETERS_AND_METERS {
            mainUnitStr = OAUtilities.getLocalizedString("km")
            mainUnitInMeters = GpxUIHelper.metersInKilometer
        } else if mc == EOAMetricsConstant.NAUTICAL_MILES_AND_METERS || mc == EOAMetricsConstant.NAUTICAL_MILES_AND_FEET {
            mainUnitStr = OAUtilities.getLocalizedString("nm")
            mainUnitInMeters = GpxUIHelper.metersInOneNauticalmile
        } else {
            mainUnitStr = OAUtilities.getLocalizedString("mile")
            mainUnitInMeters = GpxUIHelper.metersInOneMile
        }
        if meters > 9.99 * mainUnitInMeters {
            fmt = format1
            granularity = 0.1
        }
        if meters >= 100 * mainUnitInMeters ||
            meters > 9.99 * mainUnitInMeters ||
                meters > 0.999 * mainUnitInMeters ||
            mc == EOAMetricsConstant.MILES_AND_FEET && meters > 0.249 * mainUnitInMeters ||
            mc == EOAMetricsConstant.MILES_AND_METERS && meters > 0.249 * mainUnitInMeters ||
            mc == EOAMetricsConstant.MILES_AND_YARDS && meters > 0.249 * mainUnitInMeters ||
            mc == EOAMetricsConstant.NAUTICAL_MILES_AND_METERS && meters > 0.99 * mainUnitInMeters ||
            mc == EOAMetricsConstant.NAUTICAL_MILES_AND_FEET && meters > 0.99 * mainUnitInMeters {

            divX = mainUnitInMeters
            if fmt == nil {
                fmt = format2
                granularity = 0.01
            }
        } else {
            fmt = nil
            granularity = 1
            if mc == EOAMetricsConstant.KILOMETERS_AND_METERS || mc == EOAMetricsConstant.MILES_AND_METERS {
                divX = 1
                mainUnitStr = OAUtilities.getLocalizedString("m")
            } else if mc == EOAMetricsConstant.MILES_AND_FEET || mc == EOAMetricsConstant.NAUTICAL_MILES_AND_FEET {
                divX = Double(1.0 / GpxUIHelper.feetInOneMeter)
                mainUnitStr = OAUtilities.getLocalizedString("foot")
            } else if mc == EOAMetricsConstant.MILES_AND_YARDS {
                divX = Double(1.0 / GpxUIHelper.yardsInOneMeter)
                mainUnitStr = OAUtilities.getLocalizedString("yard")
            } else {
                divX = 1.0
                mainUnitStr = OAUtilities.getLocalizedString("m")
            }
        }

        let formatX: String? = fmt
        axisBase.granularity = granularity
        axisBase.valueFormatter = ValueFormatterLocal(formatX: formatX, unitsX: mainUnitStr)

        return divX
    }

    private static func calculateElevationArray(analysis: GpxTrackAnalysis, 
                                                axisType: GPXDataSetAxisType,
                                                divX: Double,
                                                convEle: Double,
                                                useGeneralTrackPoints: Bool,
                                                calcWithoutGaps: Bool) -> [ChartDataEntry] {
        var values: [ChartDataEntry] = []
        if !analysis.hasElevationData() {
            return values
        }
        let elevationData: [OAElevation] = analysis.elevationData
        var nextX: Double = 0
        var nextY: Double
        var elev: Double
        var prevElevOrig: Double = -80000
        var prevElev: Double = 0
        var i: Int = -1
        let lastIndex: Int = elevationData.count - 1
        var lastEntry: ChartDataEntry?
        var lastXSameY: Double = -1
        var hasSameY = false
        var x: Double
        for e in elevationData {
            i += 1
            if axisType == .time || axisType == .timeOfDay {
                x = Double(e.time)
            } else {
                x = e.distance
            }
            if x >= 0 {
                if !(calcWithoutGaps && e.firstPoint && lastEntry != nil) {
                    nextX += x / divX
                }
                if !e.elevation.isNaN {
                    elev = e.elevation
                    if prevElevOrig != -80000 {
                        if elev > prevElevOrig {
                            // elev -= 1
                        } else if prevElevOrig == elev && i < lastIndex {
                            hasSameY = true
                            lastXSameY = nextX
                            continue
                        }
                        if prevElev == elev && i < lastIndex {
                            hasSameY = true
                            lastXSameY = nextX
                            continue
                        }
                        if hasSameY, let lastEntry {
                            values.append(ChartDataEntry(x: lastXSameY, y: lastEntry.y))
                        }
                        hasSameY = false
                    }
                    if useGeneralTrackPoints, e.firstPoint, let lastEntry {
                        values.append(ChartDataEntry(x: nextX, y: lastEntry.y))
                    }
                    prevElevOrig = e.elevation
                    prevElev = elev
                    nextY = elev * convEle
                    lastEntry = ChartDataEntry(x: nextX, y: nextY)
                    if let lastEntry {
                        values.append(lastEntry)
                    }
                }
            }
        }
        return values
    }

    private static func createGPXSpeedDataSet(chartView: LineChartView,
                                              analysis: GpxTrackAnalysis,
                                              graphType: GPXDataSetType,
                                              axisType: GPXDataSetAxisType,
                                              useRightAxis: Bool,
                                              setYAxisMinimum: Bool,
                                              drawFilled: Bool,
                                              calcWithoutGaps: Bool) -> OrderedLineDataSet {
        let divX: Double = getDivX(lineChart: chartView,
                                   analysis: analysis,
                                   axisType: axisType,
                                   calcWithoutGaps: calcWithoutGaps)

        let pair: Pair<Double, Double>? = getScalingY(graphType)
        let mulSpeed: Double = pair?.first ?? Double.nan
        let divSpeed: Double = pair?.second ?? Double.nan
        let yAxis = getYAxis(chart: chartView,
                             textColor: .chartTextColorSpeed,
                             useRightAxis: useRightAxis)

        if setYAxisMinimum {
            yAxis.axisMinimum = 0.0
        } else {
            yAxis.resetCustomAxisMin()
        }

        let values = getPointAttributeValues(key: graphType.getDatakey(),
                                             pointAttributes: analysis.pointAttributes as! [PointAttributes],
                                             axisType: axisType,
                                             divX: divX,
                                             mulY: mulSpeed,
                                             divY: divSpeed,
                                             calcWithoutGaps: calcWithoutGaps)

        let dataSet = OrderedLineDataSet(entries: values,
                                         label: "",
                                         dataSetType: graphType,
                                         dataSetAxisType: axisType,
                                         leftAxis: !useRightAxis)
        let mainUnitY: String = graphType.getMainUnitY()

        yAxis.valueFormatter = ValueFormatterLocal(formatX: dataSet.yMax < 3 ? "%.0f" : nil, unitsX: mainUnitY)

        if divSpeed.isNaN {
            dataSet.priority = analysis.avgSpeed * Float(mulSpeed)
        } else {
            dataSet.priority = Float(divSpeed) / analysis.avgSpeed
        }
        dataSet.divX = divX
        dataSet.units = mainUnitY

        let color = graphType.getFillColor()
        GpxUIHelper.setupDataSet(dataSet: dataSet,
                                 color: color,
                                 fillColor: color,
                                 drawFilled: drawFilled,
                                 drawCircles: false,
                                 useRightAxis: useRightAxis)
        return dataSet
    }

    private static func setupXAxisTime(xAxis: XAxis, timeSpan: Int64) -> Double {
        let useHours: Bool = timeSpan / 3600000 > 0
        xAxis.granularity = 1
        xAxis.valueFormatter = TimeFormatter(useHours: useHours)
        return 1
    }

    private static func setupXAxisTimeOfDay(xAxis: XAxis, startTime: Int64) -> Double {
        xAxis.granularity = 1
        xAxis.valueFormatter = TimeSpanFormatter(startTime: startTime)
        return 1
    }
}
