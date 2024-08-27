//
//  OARouteStatisticsViewController.swift
//  OsmAnd
//
//  Created by Paul on 9/3/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

import UIKit
import DGCharts

@objc enum GPXDataSetType: Int {
    case altitude, speed, slope, sensorSpeed, sensorHeartRate, sensorBikePower, sensorBikeCadence, sensorTemperature

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

    final class ValueFormatter: IAxisValueFormatter {

        private var formatX: String?
        private var unitsX: String

        init(formatX: String?, unitsX: String) {
            self.formatX = formatX
            self.unitsX = unitsX
        }

        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            if let formatX, formatX.length > 0 {
                return String(format: formatX, value) + " " + unitsX
            } else {
                return String(format: "%.0f", value) + " " + unitsX
            }
        }
    }

    private class HeightFormatter: IFillFormatter {
        func getFillLinePosition(dataSet: ILineChartDataSet, dataProvider: LineChartDataProvider) -> CGFloat {
            CGFloat(dataProvider.chartYMin)
        }
    }

    private class TimeFormatter: IAxisValueFormatter {

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

    private class TimeSpanFormatter : AxisValueFormatter {
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

    final class OrderedLineDataSet: LineChartDataSet {

        private let leftAxis: Bool

        var priority: Float
        var units: String
        var divX: Double = 1
        var divY: Double = 1
        var mulY: Double = 1
        var color: UIColor

        private var dataSetType: GPXDataSetType
        private var dataSetAxisType: GPXDataSetAxisType

        init(entries: [ChartDataEntry]?,
             label: String?,
             dataSetType: GPXDataSetType,
             dataSetAxisType: GPXDataSetAxisType,
             leftAxis: Bool) {
            self.dataSetType = dataSetType
            self.dataSetAxisType = dataSetAxisType
            self.priority = 0
            self.units = ""
            self.color = dataSetType.getTextColor()
            super.init(entries: entries, label: label)
            self.mode = LineChartDataSet.Mode.linear
            self.leftAxis = leftAxis
        }

        required init() {
            fatalError("init() has not been implemented")
        }

        override func getDivX() -> Double {
            divX
        }

        func getDataSetType() -> GPXDataSetType {
            dataSetType
        }

        func getDataSetAxisType() -> GPXDataSetAxisType {
            dataSetAxisType
        }

        func getPriority() -> Float {
            priority
        }

        func getDivY() -> Double {
            divY
        }

        func getMulY() -> Double {
            mulY
        }

        func getUnits() -> String {
            units
        }

        func isLeftAxis() -> Bool {
            leftAxis
        }
    }

    private class GPXChartMarker: MarkerView {

        private let widthOffset: CGFloat = 3.0
        private let heightOffset: CGFloat = 2.0

        private var text: NSAttributedString = NSAttributedString(string: "")

        override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
            super.refreshContent(entry: entry, highlight: highlight)

            let chartData = chartView?.data
            let res = NSMutableAttributedString(string: "")

            if chartData?.dataSetCount ?? 0 == 1 {
                let dataSet = chartData?.dataSets[0] as! OrderedLineDataSet
                res.append(NSAttributedString(string: "\(lround(entry.y)) " + dataSet.units,
                                              attributes: [NSAttributedString.Key.foregroundColor: dataSet.color]))
            } else if chartData?.dataSetCount ?? 0 == 2 {
                let dataSet1 = chartData?.dataSets[0] as! OrderedLineDataSet
                let dataSet2 = chartData?.dataSets[1] as! OrderedLineDataSet
                let useFirst = dataSet1.visible
                let useSecond = dataSet2.visible

                if useFirst {
                    let entry1 = dataSet1.entryForXValue(entry.x, closestToY: Double.nan, rounding: .up)
                    
                    res.append(NSAttributedString(string: "\(lround(entry1?.y ?? 0)) " + dataSet1.units,
                                                  attributes: [NSAttributedString.Key.foregroundColor: dataSet1.color]))
                }
                if useSecond {
                    let entry2 = dataSet2.entryForXValue(entry.x, closestToY: Double.nan, rounding: .up)
                    
                    if useFirst {
                        res.append(NSAttributedString(string: ", \(lround(entry2?.y ?? 0)) " + dataSet2.units,
                                                      attributes: [NSAttributedString.Key.foregroundColor: dataSet2.color]))
                    } else {
                        res.append(NSAttributedString(string: "\(lround(entry2?.y ?? 0)) " + dataSet2.units,
                                                      attributes: [NSAttributedString.Key.foregroundColor: dataSet2.color]))
                    }
                }
            }
            text = res
        }

        override func draw(context: CGContext, point: CGPoint) {
            super.draw(context: context, point: point)

            bounds.size = text.size()
            offset = CGPoint(x: 0.0, y: 0.0)

            let offset = offsetForDrawing(atPoint: CGPoint(x: point.x - text.size().width / 2 + widthOffset,
                                                           y: point.y))
            let labelRect = CGRect(origin: CGPoint(x: point.x - text.size().width / 2 + offset.x, y: heightOffset),
                                   size: bounds.size)
            let outline = CALayer()

            outline.borderColor = UIColor.chartSliderLabelStroke.cgColor
            outline.backgroundColor = UIColor.chartSliderLabelBg.cgColor
            outline.borderWidth = 1.0
            outline.cornerRadius = 2.0
            outline.bounds = CGRect(origin: CGPoint(x: labelRect.origin.x - widthOffset,
                                                    y: labelRect.origin.y),
                                    size: CGSize(width: labelRect.size.width + widthOffset * 2,
                                                 height: labelRect.size.height + heightOffset * 2))
            outline.render(in: context)

            drawText(text: text, rect: labelRect)
        }

        override func offsetForDrawing(atPoint point: CGPoint) -> CGPoint {
            guard let chart = chartView else { return offset }

            var offset = offset
            let width = bounds.size.width
            let height = bounds.size.height

            if point.x + offset.x < chart.extraLeftOffset {
                offset.x = -point.x + chart.extraLeftOffset + widthOffset * 2
            } else if point.x + width + offset.x > chart.bounds.size.width - chart.extraRightOffset {
                offset.x = chart.bounds.size.width - point.x - width - chart.extraRightOffset
            }

            if point.y + offset.y < 0 {
                offset.y = -point.y
            } else if point.y + height + offset.y > chart.bounds.size.height {
                offset.y = chart.bounds.size.height - point.y - height
            }

            return offset
        }

        private func drawText(text: NSAttributedString, rect: CGRect) {
            let size = text.size()
            let centeredRect = CGRect(x: rect.origin.x,
                                      y: rect.origin.y + (rect.size.height + heightOffset - size.height) / 2.0,
                                      width: size.width,
                                      height: size.height)
            text.draw(in: centeredRect)
        }
    }

    static let metersInKilometer = 1000.0
    static let metersInOneNauticalmile = 1852.0
    static let metersInOneMile = 1609.344
    static let feetInOneMeter = 3.2808
    static let yardsInOneMeter = 1.0936

    private static let maxChartDataItems = 10000.0

    static func getDivX(dataSet: IChartDataSet) -> Double {
        (dataSet as? OrderedLineDataSet)?.divX ?? 0
    }

    static func getDataSetAxisType(dataSet: IChartDataSet) -> GPXDataSetAxisType {
        (dataSet as? OrderedLineDataSet)?.getDataSetAxisType() ?? GPXDataSetAxisType.distance
    }

    static func refreshLineChart(chartView: LineChartView,
                                 analysis: OAGPXTrackAnalysis,
                                 useGesturesAndScale: Bool,
                                 firstType: GPXDataSetType,
                                 useRightAxis: Bool,
                                 calcWithoutGaps: Bool) {
        var dataSets = [LineChartDataSetProtocol]()
        let firstDataSet = getDataSet(chartView: chartView,
                                      analysis: analysis,
                                      type: firstType,
                                      calcWithoutGaps: calcWithoutGaps,
                                      useRightAxis: useRightAxis)
        if let firstDataSet {
            dataSets.append(firstDataSet)
        }
        if useRightAxis {
            chartView.leftAxis.enabled = false
            chartView.leftAxis.drawLabelsEnabled = false
            chartView.leftAxis.drawGridLinesEnabled = false
            chartView.rightAxis.enabled = true
        } else {
            chartView.rightAxis.enabled = false
            chartView.leftAxis.enabled = true
        }

        var highlightValues = [Highlight]()
        for i in 0..<chartView.highlighted.count {
            var h: Highlight = chartView.highlighted[i]
            h = Highlight(x: h.x,
                          y: h.y,
                          xPx: h.xPx,
                          yPx: h.yPx,
                          dataIndex: h.dataIndex,
                          dataSetIndex: dataSets.count - 1,
                          stackIndex: h.stackIndex,
                          axis: h.axis)
            highlightValues.append(h)
        }
        chartView.clear()
        chartView.data = LineChartData(dataSets: dataSets)
        chartView.highlightValues(highlightValues)
    }

    static func refreshLineChart(chartView: LineChartView,
                                 analysis: OAGPXTrackAnalysis,
                                 useGesturesAndScale: Bool,
                                 firstType: GPXDataSetType,
                                 secondType: GPXDataSetType,
                                 calcWithoutGaps: Bool) {
        var dataSets = [LineChartDataSetProtocol]()
        let firstDataSet: OrderedLineDataSet? = getDataSet(chartView: chartView,
                                                           analysis: analysis,
                                                           type: firstType,
                                                           calcWithoutGaps: calcWithoutGaps,
                                                           useRightAxis: false)
        let secondDataSet: OrderedLineDataSet? = getDataSet(chartView: chartView,
                                                            analysis: analysis,
                                                            type: secondType,
                                                            calcWithoutGaps: calcWithoutGaps,
                                                            useRightAxis: true)

        if let firstDataSet {
            dataSets.append(firstDataSet)
        }

        if let secondDataSet {
            dataSets.append(secondDataSet)
            chartView.leftAxis.drawLabelsEnabled = false
            chartView.leftAxis.drawGridLinesEnabled = false
        } else {
            chartView.rightAxis.enabled = false
            chartView.leftAxis.enabled = true
        }
        var highlightValues = [Highlight]()
        for i in 0..<chartView.highlighted.count {
            var h: Highlight = chartView.highlighted[i]
            h = Highlight(x: h.x,
                          y: h.y,
                          xPx: h.xPx,
                          yPx: h.yPx,
                          dataIndex: h.dataIndex,
                          dataSetIndex: dataSets.count - 1,
                          stackIndex: h.stackIndex,
                          axis: h.axis)
            highlightValues.append(h)
        }
        chartView.clear()
        chartView.data = LineChartData(dataSets: dataSets)
        chartView.highlightValues(highlightValues)
    }

    static func refreshBarChart(chartView: HorizontalBarChartView,
                                statistics: OARouteStatistics,
                                analysis: OAGPXTrackAnalysis,
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
        chart.renderer = CustomBarChartRenderer(dataProvider: chart,
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

    static func setupGPXChart(chartView: LineChartView,
                              yLabelsCount: Int,
                              topOffset: CGFloat,
                              bottomOffset: CGFloat,
                              useGesturesAndScale: Bool) {
        chartView.clear()
        chartView.fitScreen()
        chartView.layer.drawsAsynchronously = true

        chartView.isUserInteractionEnabled = useGesturesAndScale
        chartView.dragEnabled = useGesturesAndScale
        chartView.setScaleEnabled(useGesturesAndScale)
        chartView.pinchZoomEnabled = useGesturesAndScale
        chartView.scaleYEnabled = false
        chartView.autoScaleMinMaxEnabled = true
        chartView.drawBordersEnabled = false
        chartView.chartDescription.enabled = false
        chartView.maxVisibleCount = 10
        chartView.minOffset = 0.0
        chartView.rightYAxisRenderer = YAxisCombinedRenderer(viewPortHandler: chartView.viewPortHandler,
                                                             yAxis: chartView.rightAxis,
                                                             secondaryYAxis: chartView.leftAxis,
                                                             transformer: chartView.getTransformer(forAxis: .right),
                                                             secondaryTransformer: chartView.getTransformer(forAxis: .left))
        chartView.extraLeftOffset = 16
        chartView.extraRightOffset = 16
        chartView.dragDecelerationEnabled = false

        chartView.extraTopOffset = topOffset
        chartView.extraBottomOffset = bottomOffset

        let marker = GPXChartMarker()
        marker.chartView = chartView
        chartView.marker = marker
        chartView.drawMarkers = true

        let labelsColor = UIColor.chartTextColorAxisX
        let xAxis: XAxis = chartView.xAxis
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = false
        xAxis.gridLineWidth = 1.5
        xAxis.gridColor = UIColor.chartAxisGridLine
        xAxis.gridLineDashLengths = [10]
        xAxis.labelPosition = .bottom
        xAxis.labelTextColor = labelsColor
        xAxis.resetCustomAxisMin()
        let yColor = UIColor.chartAxisGridLine
        var yAxis: YAxis = chartView.leftAxis
        yAxis.gridLineDashLengths = [4.0, 4.0]
        yAxis.gridColor = yColor
        yAxis.drawAxisLineEnabled = false
        yAxis.drawGridLinesEnabled = true
        yAxis.labelPosition = .insideChart
        yAxis.xOffset = 16.0
        yAxis.yOffset = -6.0
        yAxis.labelCount = yLabelsCount
        yAxis.labelTextColor = UIColor.chartTextColorAxisX
        yAxis.labelFont = UIFont.systemFont(ofSize: 11)

        yAxis = chartView.rightAxis
        yAxis.gridLineDashLengths = [4.0, 4.0]
        yAxis.gridColor = yColor
        yAxis.drawAxisLineEnabled = false
        yAxis.drawGridLinesEnabled = true
        yAxis.labelPosition = .insideChart
        yAxis.xOffset = 16.0
        yAxis.yOffset = -6.0
        yAxis.labelCount = yLabelsCount
        xAxis.labelTextColor = labelsColor
        yAxis.enabled = false
        yAxis.labelFont = UIFont.systemFont(ofSize: 11)

        let legend = chartView.legend
        legend.enabled = false
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
        xAxis.axisLineDashLengths = [8.0, CGFLOAT_MAX]
        xAxis.axisLineDashPhase = 0.0
        xAxis.axisLineColor = xAxisGridColor
        xAxis.drawGridLinesEnabled = false
        xAxis.gridLineWidth = 1.0
        xAxis.gridColor = xAxisGridColor
        xAxis.gridLineDashLengths = [8.0, CGFLOAT_MAX]
        xAxis.gridLineDashPhase = 0.0
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
                        analysis: OAGPXTrackAnalysis,
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
            dataSet.color = UIColor.black
        } else {
            dataSet.drawCirclesEnabled = false
            dataSet.drawCircleHoleEnabled = false
            dataSet.color = color
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
            dataSet.highlightColor = UIColor.chartSliderLine
        }
        if useRightAxis {
            dataSet.axisDependency = YAxis.AxisDependency.right
        }
    }

    private static func getDataSet(chartView: LineChartView,
                                   analysis: OAGPXTrackAnalysis,
                                   type: GPXDataSetType,
                                   calcWithoutGaps: Bool,
                                   useRightAxis: Bool) -> OrderedLineDataSet? {
        switch type {
        case .altitude:
            return createGPXElevationDataSet(chartView: chartView,
                                             analysis: analysis,
                                             graphType: type,
                                             axisType: GPXDataSetAxisType.distance,
                                             useRightAxis: useRightAxis,
                                             drawFilled: true,
                                             calcWithoutGaps: calcWithoutGaps)
        case .slope:
            return createGPXSlopeDataSet(chartView: chartView,
                                         analysis: analysis,
                                         graphType: type,
                                         axisType: GPXDataSetAxisType.distance,
                                         eleValues: Array(),
                                         useRightAxis: useRightAxis,
                                         drawFilled: true,
                                         calcWithoutGaps: calcWithoutGaps)
        case .speed:
            return createGPXSpeedDataSet(chartView: chartView,
                                         analysis: analysis,
                                         graphType: type,
                                         axisType: GPXDataSetAxisType.distance,
                                         useRightAxis: useRightAxis,
                                         drawFilled: true,
                                         calcWithoutGaps: calcWithoutGaps)
        default:
            return OAPluginsHelper.getOrderedLineDataSet(chart: chartView,
                                                         analysis: analysis,
                                                         graphType: type,
                                                         axisType: GPXDataSetAxisType.distance,
                                                         calcWithoutGaps: calcWithoutGaps,
                                                         useRightAxis: useRightAxis)
        }
    }

    private static func buildStatisticChart(chartView: HorizontalBarChartView,
                                            routeStatistics: OARouteStatistics,
                                            analysis: OAGPXTrackAnalysis,
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
                                                  analysis: OAGPXTrackAnalysis,
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
        let yAxis: YAxis  = getYAxis(chart: chartView,
                                     textColor: UIColor.chartTextColorElevation,
                                     useRightAxis: useRightAxis)
        yAxis.granularity = 1
        yAxis.resetCustomAxisMax()
        yAxis.valueFormatter = ValueFormatter(formatX: nil, unitsX: mainUnitY)
        let values = calculateElevationArray(analysis: analysis,
                                             axisType: axisType,
                                             divX: divX,
                                             convEle: convEle,
                                             useGeneralTrackPoints: true,
                                             calcWithoutGaps: calcWithoutGaps)
        let dataSet = OrderedLineDataSet(entries: values,
                                         label: "",
                                         dataSetType: GPXDataSetType.altitude,
                                         dataSetAxisType: axisType,
                                         leftAxis: !useRightAxis)
        dataSet.priority = Float((analysis.avgElevation - analysis.minElevation) * convEle)
        dataSet.divX = divX
        dataSet.mulY = convEle
        dataSet.divY = Double.nan
        dataSet.units = mainUnitY

        let color: UIColor = graphType.getFillColor()
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
                                              analysis: OAGPXTrackAnalysis,
                                              graphType: GPXDataSetType,
                                              axisType: GPXDataSetAxisType,
                                              eleValues: [ChartDataEntry],
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
        let divX: Double = getDivX(lineChart: chartView, analysis: analysis, axisType: axisType, calcWithoutGaps: calcWithoutGaps)
        let mainUnitY: String = graphType.getMainUnitY()
        let yAxis: YAxis = getYAxis(chart: chartView, textColor: UIColor.chartTextColorSlope, useRightAxis: useRightAxis)
        yAxis.granularity = 1.0
        yAxis.resetCustomAxisMin()
        yAxis.valueFormatter = ValueFormatter(formatX: nil, unitsX: mainUnitY)

        var values = [ChartDataEntry]()
        if eleValues.count == 0 {
            values = calculateElevationArray(analysis: analysis,
                                             axisType: .distance,
                                             divX: 1.0,
                                             convEle: 1.0,
                                             useGeneralTrackPoints: false,
                                             calcWithoutGaps: calcWithoutGaps)
        } else {
            for e in eleValues {
                values.append(ChartDataEntry(x: e.x * divX, y: e.y / convEle))
            }
        }

        if values.count == 0 {
            if useRightAxis {
                yAxis.enabled = false
            }
            return nil
        }

        var lastIndex = values.count - 1
        var step: Double = 5
        var l: Int = 10

        while l > 0 && totalDistance / step > GpxUIHelper.maxChartDataItems {
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
        for i in 0..<calculatedSlopeDist.count {
            x = calculatedSlopeDist[i] / divX
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
                                         dataSetType: GPXDataSetType.slope,
                                         dataSetAxisType: axisType,
                                         leftAxis: !useRightAxis)
        dataSet.divX = divX
        dataSet.units = mainUnitY

        let color: UIColor = graphType.getFillColor()
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
        axisBase.valueFormatter = ValueFormatter(formatX: formatX, unitsX: mainUnitStr)

        return divX
    }

    private static func calculateElevationArray(analysis: OAGPXTrackAnalysis, 
                                                axisType: GPXDataSetAxisType,
                                                divX: Double,
                                                convEle: Double,
                                                useGeneralTrackPoints: Bool,
                                                calcWithoutGaps: Bool) -> [ChartDataEntry] {
        var values: [ChartDataEntry] = []
        if analysis.elevationData == nil {
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
                                              analysis: OAGPXTrackAnalysis,
                                              graphType: GPXDataSetType,
                                              axisType: GPXDataSetAxisType,
                                              useRightAxis: Bool,
                                              drawFilled: Bool,
                                              calcWithoutGaps: Bool) -> OrderedLineDataSet {
        let divX: Double = getDivX(lineChart: chartView,
                                   analysis: analysis,
                                   axisType: axisType,
                                   calcWithoutGaps: calcWithoutGaps)

        let pair: Pair<Double, Double>? = getScalingY(graphType)
        let mulSpeed: Double = pair?.first ?? Double.nan
        let divSpeed: Double = pair?.second ?? Double.nan
        let mainUnitY: String = graphType.getMainUnitY()
        let yAxis = getYAxis(chart: chartView,
                             textColor: UIColor.chartTextColorSpeed,
                             useRightAxis: useRightAxis)
        yAxis.axisMinimum = 0.0

        let values = getPointAttributeValues(key: graphType.getDatakey(),
                                             pointAttributes: analysis.pointAttributes as! [PointAttributes],
                                             axisType: axisType,
                                             divX: divX,
                                             mulY: mulSpeed,
                                             divY: divSpeed,
                                             calcWithoutGaps: calcWithoutGaps)

        let dataSet = OrderedLineDataSet(entries: values,
                                         label: "",
                                         dataSetType: GPXDataSetType.speed,
                                         dataSetAxisType: axisType, leftAxis:
                                            !useRightAxis)
        yAxis.valueFormatter = ValueFormatter(formatX: dataSet.yMax < 3 ? "%.0f" : nil, unitsX: mainUnitY)

        if divSpeed.isNaN {
            dataSet.priority = analysis.avgSpeed * Float(mulSpeed)
        } else {
            dataSet.priority = Float(divSpeed) / analysis.avgSpeed
        }
        dataSet.divX = divX
        if divSpeed.isNaN {
            dataSet.mulY = mulSpeed
            dataSet.divY = Double.nan
        } else {
            dataSet.divY = divSpeed
            dataSet.mulY = Double.nan
        }
        dataSet.units = mainUnitY

        let color: UIColor = graphType.getFillColor()
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
