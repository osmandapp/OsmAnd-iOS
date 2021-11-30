//
//  OARouteStatisticsViewController.swift
//  OsmAnd
//
//  Created by Paul on 9/3/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

import UIKit
import Charts
import Charts.Swift

@objc public enum GPXDataSetType: Int {
    case ALTITUDE = 0
    case SPEED = 1
    case SLOPE = 2
    
    public func getName() -> String {
        switch self {
            case .ALTITUDE:
                return NSLocalizedString("map_widget_altitude", comment: "");
            case .SPEED:
                return NSLocalizedString("gpx_speed", comment: "");
            case .SLOPE:
                return NSLocalizedString("gpx_slope", comment: "");
        }
    }
    
    public func getImageName() -> String {
        switch self {
        case .ALTITUDE:
            return ""
        case .SPEED:
            return ""
        case .SLOPE:
            return ""
        }
    }
}

public enum GPXDataSetAxisType: String {
    case DISTANCE = "shared_string_distance"
    case TIME = "shared_string_time"
    case TIMEOFDAY = "shared_string_time_of_day"
    
    var icon: String {
        switch self {
        case .DISTANCE:
            return ""
        case .TIME:
            return ""
        case .TIMEOFDAY:
            return ""
        }
    }
    
    func getLocalizedName() -> String {
        return NSLocalizedString(self.rawValue, comment: "")
    }
}

@objc class GpxUIHelper: NSObject {
    
    static let METERS_IN_KILOMETER: Double = 1000
    static let METERS_IN_ONE_NAUTICALMILE: Double = 1852
    static let METERS_IN_ONE_MILE: Double = 1609.344
    static let FEET_IN_ONE_METER: Double = 3.2808
    static let YARDS_IN_ONE_METER: Double = 1.0936
    
    private static let MAX_CHART_DATA_ITEMS: Double = 10000
    
    private class ValueFormatter: IAxisValueFormatter
    {
        private var formatX: String?
        private var unitsX: String
        
        init(formatX: String?, unitsX: String) {
            self.formatX = formatX
            self.unitsX = unitsX
        }
        
        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            if (formatX != nil && formatX?.length ?? 0 > 0) {
                return String(format: formatX!, value) + " " + self.unitsX
            } else {
                return String(format: "%.0f", value) + " " + self.unitsX
            }
        }
    }
    
    private class HeightFormatter: IFillFormatter
    {
        func getFillLinePosition(dataSet: ILineChartDataSet, dataProvider: LineChartDataProvider) -> CGFloat {
            return CGFloat(dataProvider.chartYMin)
        }
    }
    
    private class TimeFormatter: IAxisValueFormatter
    {
        private var useHours: Bool
        
        init(useHours: Bool) {
            self.useHours = useHours
        }
        
        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            let seconds = Int(value)
            if (useHours) {
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
    
    private class TimeSpanFormatter : IAxisValueFormatter
    {
        private var startTime: Int64
        
        init(startTime: Int64) {
            self.startTime = startTime
        }
        
        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            let seconds = Double(startTime/1000) + value
            let date = Date(timeIntervalSince1970: seconds)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss"
            dateFormatter.timeZone = .current
            return dateFormatter.string(from: date)
        }
    }
    
    private class OrderedLineDataSet: LineChartDataSet {
        
        private var dataSetType: GPXDataSetType;
        private var dataSetAxisType: GPXDataSetAxisType;
        
        var priority: Float;
        var units: String;
        var divX: Double = 1;
        var divY: Double = 1;
        var mulY: Double = 1;
        var color: UIColor;
        
        init(entries: [ChartDataEntry]?, label: String?, dataSetType: GPXDataSetType, dataSetAxisType: GPXDataSetAxisType) {
            self.dataSetType = dataSetType
            self.dataSetAxisType = dataSetAxisType
            self.priority = 0
            self.units = ""
            self.color = OrderedLineDataSet.getColorForType(type: dataSetType)
            super.init(entries: entries, label: label)
        }
        
        required init() {
            fatalError("init() has not been implemented")
        }
        
        public func getDataSetType() -> GPXDataSetType {
            return dataSetType;
        }
        
        public func getDataSetAxisType() -> GPXDataSetAxisType {
            return dataSetAxisType;
        }
        
        public func getPriority() -> Float {
            return priority;
        }
        
        public override func getDivX() -> Double {
            return divX;
        }
        
        public func getDivY() -> Double {
            return divY;
        }
        
        public func getMulY() -> Double {
            return mulY;
        }
        
        public func getUnits() -> String {
            return units;
        }
        
        private static func getColorForType(type: GPXDataSetType) -> UIColor {
            switch type {
            case .ALTITUDE:
                return UIColor(rgbValue: color_elevation_chart)
            case .SLOPE:
                return UIColor(rgbValue: color_slope_chart)
            case .SPEED:
                return UIColor(rgbValue: color_chart_orange)
            }
        }
    }

    @objc static public func getDivX(dataSet: IChartDataSet) -> Double
    {
        let orderedDataSet: OrderedLineDataSet? = dataSet as? OrderedLineDataSet
        return orderedDataSet?.divX ?? 0
    }

    private class GPXChartMarker: MarkerView {
        
        private var text: NSAttributedString = NSAttributedString(string: "")
        
        private let widthOffset: CGFloat = 3.0
        private let heightOffset: CGFloat = 2.0

        override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
            super.refreshContent(entry: entry, highlight: highlight)
            
            let chartData = self.chartView?.data
            
            let res = NSMutableAttributedString(string: "")
            
            
            if (chartData?.dataSetCount ?? 0 == 1)
            {
                let dataSet = chartData?.dataSets[0] as! OrderedLineDataSet
                res.append(NSAttributedString(string: "\(lround(entry.y)) " + dataSet.units, attributes:[NSAttributedString.Key.foregroundColor: dataSet.color]))
            }
            else if (chartData?.dataSetCount ?? 0 == 2) {
                let dataSet1 = chartData?.dataSets[0] as! OrderedLineDataSet
                let dataSet2 = chartData?.dataSets[1] as! OrderedLineDataSet

                let useFirst = dataSet1.visible
                let useSecond = dataSet2.visible

                if (useFirst) {
                    let entry1 = dataSet1.entryForXValue(entry.x, closestToY: Double.nan, rounding: .up)
                    
                    res.append(NSAttributedString(string: "\(lround(entry1?.y ?? 0)) " + dataSet1.units, attributes:[NSAttributedString.Key.foregroundColor: dataSet1.color]))
                }
                if (useSecond) {
                    let entry2 = dataSet2.entryForXValue(entry.x, closestToY: Double.nan, rounding: .up)
                    
                    if (useFirst) {
                        res.append(NSAttributedString(string: ", \(lround(entry2?.y ?? 0)) " + dataSet2.units, attributes:[NSAttributedString.Key.foregroundColor: dataSet2.color]))
                    } else {
                        res.append(NSAttributedString(string: "\(lround(entry2?.y ?? 0)) " + dataSet2.units, attributes:[NSAttributedString.Key.foregroundColor: dataSet2.color]))
                    }
                }
            }
            text = res
        }

        override func draw(context: CGContext, point: CGPoint) {
            super.draw(context: context, point: point)
            
            self.bounds.size = text.size()
            self.offset = CGPoint(x: 0.0, y: 0.0)

            let offset = self.offsetForDrawing(atPoint: CGPoint(x: point.x - text.size().width / 2 + widthOffset, y: point.y))
            
            let labelRect = CGRect(origin: CGPoint(x: point.x - text.size().width / 2 + offset.x, y: heightOffset), size: self.bounds.size)
            
            let outline = CALayer()
            
            outline.borderColor = UIColor(rgbValue: color_primary_purple).cgColor
            outline.backgroundColor = UIColor.white.cgColor
            outline.borderWidth = 1.0
            outline.cornerRadius = 2.0
            outline.bounds = CGRect(origin: CGPoint(x: labelRect.origin.x - widthOffset, y: labelRect.origin.y), size: CGSize(width: labelRect.size.width + widthOffset * 2, height: labelRect.size.height + heightOffset * 2))
            
            outline.render(in: context)
            
            drawText(text: text, rect: labelRect)
        }

        private func drawText(text: NSAttributedString, rect: CGRect) {
            let size = text.size()
            let centeredRect = CGRect(x: rect.origin.x, y: rect.origin.y + (rect.size.height + heightOffset - size.height) / 2.0, width: size.width, height: size.height)
            text.draw(in: centeredRect)
        }
        
        open override func offsetForDrawing(atPoint point: CGPoint) -> CGPoint
        {
            guard let chart = chartView else { return self.offset }
            
            var offset = self.offset
            
            let width = self.bounds.size.width
            let height = self.bounds.size.height
            
            if point.x + offset.x < chart.extraLeftOffset
            {
                offset.x = -point.x + chart.extraLeftOffset + widthOffset * 2
            }
            else if point.x + width + offset.x > chart.bounds.size.width - chart.extraRightOffset
            {
                offset.x = chart.bounds.size.width - point.x - width - chart.extraRightOffset
            }
            
            if point.y + offset.y < 0
            {
                offset.y = -point.y
            }
            else if point.y + height + offset.y > chart.bounds.size.height
            {
                offset.y = chart.bounds.size.height - point.y - height
            }
            
            return offset
        }
    }

    private static func getDataSet(chartView: LineChartView,
                                   analysis: OAGPXTrackAnalysis,
                                   type: GPXDataSetType) -> OrderedLineDataSet? {
        switch type {
            case .ALTITUDE:
                return createGPXElevationDataSet(chartView: chartView, analysis: analysis, axisType: GPXDataSetAxisType.DISTANCE, useRightAxis: false, drawFilled: true)
            case .SLOPE:
                return createGPXSlopeDataSet(chartView: chartView, analysis: analysis, axisType: GPXDataSetAxisType.DISTANCE, eleValues: Array(), useRightAxis: true, drawFilled: true)
            case .SPEED:
                return createGPXSpeedDataSet(chartView: chartView, analysis: analysis, axisType: GPXDataSetAxisType.DISTANCE, useRightAxis: true, drawFilled: true)
            default:
                return nil;
        }
    }

    @objc static public func refreshLineChart(chartView: LineChartView,
                                              analysis: OAGPXTrackAnalysis,
                                              useGesturesAndScale: Bool,
                                              firstType: GPXDataSetType,
                                              useRightAxis: Bool)
    {
        var dataSets = [ILineChartDataSet]()
        let firstDataSet: OrderedLineDataSet? = getDataSet(chartView: chartView, analysis: analysis, type: firstType)
        if (firstDataSet != nil) {
            dataSets.append(firstDataSet!);
        }
        if (useRightAxis) {
            chartView.leftAxis.enabled = false
            chartView.leftAxis.drawLabelsEnabled = false
            chartView.leftAxis.drawGridLinesEnabled = false
            chartView.rightAxis.enabled = true
        }
        else {
            chartView.rightAxis.enabled = false
            chartView.leftAxis.enabled = true
        }
        chartView.data = LineChartData(dataSets: dataSets)
    }

    @objc static public func refreshLineChart(chartView: LineChartView,
                                              analysis: OAGPXTrackAnalysis,
                                              useGesturesAndScale: Bool,
                                              firstType: GPXDataSetType,
                                              secondType: GPXDataSetType)
    {
        var dataSets = [ILineChartDataSet]()
        let firstDataSet: OrderedLineDataSet? = getDataSet(chartView: chartView, analysis: analysis, type: firstType)
        let secondDataSet: OrderedLineDataSet? = getDataSet(chartView: chartView, analysis: analysis, type: secondType)

        if (firstDataSet != nil) {
            dataSets.append(firstDataSet!);
        }

        if (secondDataSet != nil)
        {
            dataSets.append(secondDataSet!)
            chartView.leftAxis.drawLabelsEnabled = false
            chartView.leftAxis.drawGridLinesEnabled = false
        } else {
            chartView.rightAxis.enabled = false
            chartView.leftAxis.enabled = true
        }
        chartView.data = LineChartData(dataSets: dataSets)
    }
    
    @objc static public func refreshBarChart(chartView: HorizontalBarChartView, statistics: OARouteStatistics, analysis: OAGPXTrackAnalysis, nightMode: Bool)
    {
        setupHorizontalGPXChart(chart: chartView, yLabelsCount: 4, topOffset: 20, bottomOffset: 4, useGesturesAndScale: true, nightMode: nightMode)
        chartView.extraLeftOffset = 16
        chartView.extraRightOffset = 16
        
        let barData = buildStatisticChart(chartView: chartView, routeStatistics: statistics, analysis: analysis, useRightAxis: true, nightMode: nightMode)
        
        chartView.data = barData
    }
    
    public static func setupHorizontalGPXChart(chart: HorizontalBarChartView, yLabelsCount : Int,
                                               topOffset: CGFloat, bottomOffset: CGFloat, useGesturesAndScale: Bool, nightMode: Bool) {
        chart.isUserInteractionEnabled = useGesturesAndScale
        chart.dragEnabled = useGesturesAndScale
        chart.scaleYEnabled = false
        chart.autoScaleMinMaxEnabled = true
        chart.drawBordersEnabled = true
        chart.chartDescription?.enabled = false
        chart.dragDecelerationEnabled = false
        chart.highlightPerTapEnabled = false
        chart.highlightPerDragEnabled = true
        
        chart.renderer = CustomBarChartRenderer(dataProvider: chart, animator: chart.chartAnimator, viewPortHandler: chart.viewPortHandler)

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
        yl.axisMinimum = 0.0;

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

    @objc static public func setupGPXChart(chartView: LineChartView, yLabelsCount: Int, topOffset: CGFloat, bottomOffset: CGFloat, useGesturesAndScale: Bool)
    {
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
        chartView.chartDescription?.enabled = false
        chartView.maxVisibleCount = 10
        chartView.minOffset = 0.0
        chartView.rightYAxisRenderer = YAxisCombinedRenderer(viewPortHandler: chartView.viewPortHandler, yAxis: chartView.rightAxis, secondaryYAxis: chartView.leftAxis, transformer: chartView.getTransformer(forAxis: .right), secondaryTransformer:chartView.getTransformer(forAxis: .left))
        chartView.extraLeftOffset = 16
        chartView.extraRightOffset = 16
        chartView.dragDecelerationEnabled = false
        
        chartView.extraTopOffset = topOffset
        chartView.extraBottomOffset = bottomOffset

        let marker = GPXChartMarker()
        marker.chartView = chartView
        chartView.marker = marker
        chartView.drawMarkers = true
        
        let labelsColor = UIColor(rgbValue: color_text_footer)
        let xAxis: XAxis = chartView.xAxis;
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = false
        xAxis.gridLineWidth = 1.5
        xAxis.gridColor = .black
        xAxis.gridLineDashLengths = [10]
        xAxis.labelPosition = .bottom
        xAxis.labelTextColor = labelsColor
        xAxis.resetCustomAxisMin()
        let yColor = UIColor(rgbValue: color_tint_gray)
        var yAxis: YAxis = chartView.leftAxis;
        yAxis.gridLineDashLengths = [4.0, 4.0]
        yAxis.gridColor = yColor
        yAxis.drawAxisLineEnabled = false
        yAxis.drawGridLinesEnabled = true
        yAxis.labelPosition = .insideChart
        yAxis.xOffset = 16.0
        yAxis.yOffset = -6.0
        yAxis.labelCount = yLabelsCount
        yAxis.labelTextColor = UIColor(rgbValue: color_elevation_chart)
        yAxis.labelFont = UIFont.systemFont(ofSize: 11)
        
        yAxis = chartView.rightAxis;
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
    
    private static func buildStatisticChart(chartView: HorizontalBarChartView,
                                           routeStatistics: OARouteStatistics,
                                           analysis: OAGPXTrackAnalysis,
                                           useRightAxis: Bool,
                                           nightMode: Bool) -> BarChartData {

        let xAxis = chartView.xAxis
        xAxis.enabled = false

        var yAxis: YAxis
        if (useRightAxis) {
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
        
        for i in 0..<stacks.count {
            let segment: OARouteSegmentAttribute = segments![i]
            
            stacks[i] = Double(segment.distance) / divX
            colors[i] = NSUIColor(cgColor: UIColor(argbValue: UInt32(segment.color)).cgColor)
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
    
    private static func createGPXElevationDataSet(chartView: LineChartView, analysis: OAGPXTrackAnalysis, axisType: GPXDataSetAxisType, useRightAxis: Bool, drawFilled: Bool) -> OrderedLineDataSet {
        let mc: EOAMetricsConstant = OAAppSettings.sharedManager().metricSystem.get()
        let useFeet: Bool = (mc == EOAMetricsConstant.MILES_AND_FEET) || (mc == EOAMetricsConstant.MILES_AND_YARDS)
        let convEle: Double = useFeet ? 3.28084 : 1.0
        var divX: Double
        let xAxis: XAxis = chartView.xAxis
        if (axisType == GPXDataSetAxisType.TIME && analysis.isTimeSpecified()) {
            divX = setupXAxisTime(xAxis: xAxis, timeSpan: Int64(analysis.timeSpan))
        } else if (axisType == GPXDataSetAxisType.TIMEOFDAY && analysis.isTimeSpecified()) {
            divX = setupXAxisTimeOfDay(xAxis: xAxis, startTime: Int64(analysis.startTime));
        } else {
            divX = setupAxisDistance(axisBase: xAxis, meters: Double(analysis.totalDistance))
        }
        let mainUnitY: String = useFeet ? NSLocalizedString("units_ft", comment: "") : NSLocalizedString("units_m", comment: "")
        
        var yAxis: YAxis
        if (useRightAxis) {
            yAxis = chartView.rightAxis;
            yAxis.enabled = true;
        } else {
            yAxis = chartView.leftAxis
        }
//        yAxis.setTextColor(ActivityCompat.getColor(mChart.getContext(), R.color.gpx_chart_blue_label));
//        yAxis.setGridColor(ActivityCompat.getColor(mChart.getContext(), R.color.gpx_chart_blue_grid));
        yAxis.granularity = 1
        yAxis.resetCustomAxisMax()
        yAxis.valueFormatter = ValueFormatter(formatX: nil, unitsX: mainUnitY)
        yAxis.labelBackgroundColor = UIColor.white.withAlphaComponent(0.6)
        let values: Array<ChartDataEntry> = calculateElevationArray(analysis: analysis,axisType: axisType, divX: divX, convEle: convEle, useGeneralTrackPoints: true)
        let dataSet: OrderedLineDataSet = OrderedLineDataSet(entries: values, label: "", dataSetType: GPXDataSetType.ALTITUDE, dataSetAxisType: axisType)
        dataSet.priority = Float((analysis.avgElevation - analysis.minElevation) * convEle)
        dataSet.divX = divX
        dataSet.mulY = convEle
        dataSet.divY = Double.nan
        dataSet.units = mainUnitY

        let chartColor = UIColor(rgbValue: color_elevation_chart)
        dataSet.setColor(chartColor)
        dataSet.lineWidth = 1
        if drawFilled {
            dataSet.fillAlpha = 0.1
            dataSet.fillColor = chartColor
            dataSet.drawFilledEnabled = true
        } else {
            dataSet.drawFilledEnabled = false
        }
        dataSet.drawValuesEnabled = false
        dataSet.valueFont = NSUIFont.systemFont(ofSize: 15)
        dataSet.formLineWidth = 1
        dataSet.formSize = 15
        dataSet.drawCirclesEnabled = false
        dataSet.drawCircleHoleEnabled = false
        dataSet.highlightEnabled = true
        dataSet.drawVerticalHighlightIndicatorEnabled = true
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.highlightColor = UIColor(rgbValue: color_primary_purple)
        dataSet.mode = LineChartDataSet.Mode.linear
        dataSet.fillFormatter = HeightFormatter()
        if useRightAxis {
           dataSet.axisDependency = YAxis.AxisDependency.right
        }
        return dataSet
    }
    
    private static func createGPXSlopeDataSet(chartView: LineChartView, analysis: OAGPXTrackAnalysis,
                                      axisType: GPXDataSetAxisType,
                                      eleValues: Array<ChartDataEntry>,
                                      useRightAxis: Bool,
                                      drawFilled: Bool) -> OrderedLineDataSet? {
        if (axisType == GPXDataSetAxisType.TIME || axisType == GPXDataSetAxisType.TIMEOFDAY) {
            return nil;
        }
        let mc: EOAMetricsConstant = OAAppSettings.sharedManager().metricSystem.get()
        let useFeet: Bool = (mc == EOAMetricsConstant.MILES_AND_FEET) || (mc == EOAMetricsConstant.MILES_AND_YARDS)
        let convEle: Double = useFeet ? 3.28084 : 1.0
        let totalDistance: Double = Double(analysis.totalDistance)
        
        let xAxis: XAxis = chartView.xAxis
        let divX: Double = setupAxisDistance(axisBase: xAxis, meters: totalDistance)
        
        let mainUnitY: String = "%"
        
        var yAxis: YAxis
        if (useRightAxis) {
            yAxis = chartView.rightAxis
            yAxis.enabled = true
        } else {
            yAxis = chartView.leftAxis
        }
        yAxis.labelTextColor = UIColor(rgbValue: color_slope_chart)
        yAxis.labelBackgroundColor = UIColor.white.withAlphaComponent(0.6)
//        yAxis.gridColor = UIColor(rgbValue: color_slope_chart)
//        setGridColor(ActivityCompat.getColor(mChart.getContext(), R.color.gpx_chart_green_grid));
        yAxis.granularity = 1.0
        yAxis.resetCustomAxisMin()
        yAxis.valueFormatter = ValueFormatter(formatX: nil, unitsX: mainUnitY)
        
        var values: Array<ChartDataEntry> = Array()
        if (eleValues.count == 0) {
            values = calculateElevationArray(analysis: analysis, axisType: .DISTANCE, divX: 1.0, convEle: 1.0, useGeneralTrackPoints: false)
        } else {
            for e in eleValues {
                values.append(ChartDataEntry(x: e.x * divX, y: e.y / convEle))
            }
        }
        
        if (values.count == 0) {
            if (useRightAxis) {
                yAxis.enabled = false
            }
            return nil
        }
        
        var lastIndex = values.count - 1
        
        var step: Double = 5
        var l: Int = 10
        while (l > 0 && totalDistance / step > GpxUIHelper.MAX_CHART_DATA_ITEMS) {
            step = max(step, totalDistance / Double(values.count * l))
            l -= 1
        }
        
        var calculatedDist: Array<Double> = Array(repeating: 0, count: Int(totalDistance / step) + 1)
        var calculatedH: Array<Double> = Array(repeating: 0, count: Int(totalDistance / step) + 1)
        var nextW: Int = 0
        for k in 0..<calculatedDist.count {
            if (k > 0) {
                calculatedDist[k] = calculatedDist[k - 1] + step
            }
            while (nextW < lastIndex && calculatedDist[k] > values[nextW].x) {
                nextW += 1
            }
            let pd: Double = nextW == 0 ? 0 : values[nextW - 1].x
            let ph: Double = nextW == 0 ? values[0].y : values[nextW - 1].y
            calculatedH[k] = ph + (values[nextW].y - ph) / (values[nextW].x - pd) * (calculatedDist[k] - pd)
        }
        
        let slopeProximity: Double = max(100, step * 2)
        
        if (totalDistance - slopeProximity < 0) {
            if (useRightAxis) {
                yAxis.enabled = false
            }
            return nil;
        }
        
        var calculatedSlopeDist: Array<Double> = Array(repeating: 0, count: Int(((totalDistance - slopeProximity) / step)) + 1)
        var calculatedSlope: Array<Double> = Array(repeating: 0, count: Int(((totalDistance - slopeProximity) / step)) + 1)
        let index: Int = Int((slopeProximity / step) / 2.0)
        for k in 0..<calculatedSlopeDist.count {
            calculatedSlopeDist[k] = calculatedDist[index + k]
            // Sometimes calculatedH.count - calculatedSlope.count < 2 which causes a rare crash
            calculatedSlope[k] = (2 * index + k) < calculatedH.count ? (calculatedH[2 * index + k] - calculatedH[k]) * 100 / slopeProximity : 0
            if (calculatedSlope[k].isNaN) {
                calculatedSlope[k] = 0
            }
        }
        
        var slopeValues = [ChartDataEntry]()
        var prevSlope: Double = -80000
        var slope: Double
        var x: Double
        var lastXSameY: Double = 0
        var hasSameY = false
        var lastEntry: ChartDataEntry? = nil
        lastIndex = calculatedSlopeDist.count - 1
        for i in 0..<calculatedSlopeDist.count {
            x = calculatedSlopeDist[i] / divX
            slope = calculatedSlope[i]
            if (prevSlope != -80000) {
                if (prevSlope == slope && i < lastIndex) {
                    hasSameY = true;
                    lastXSameY = x;
                    continue;
                }
                if (hasSameY && lastEntry != nil) {
                    slopeValues.append(ChartDataEntry(x: lastXSameY, y: lastEntry!.y))
                }
                hasSameY = false
            }
            prevSlope = slope;
            lastEntry = ChartDataEntry(x: x, y: slope)
            slopeValues.append(lastEntry!)
        }
        
        let dataSet: OrderedLineDataSet = OrderedLineDataSet(entries: slopeValues, label: "", dataSetType: GPXDataSetType.SLOPE, dataSetAxisType: axisType)
        dataSet.divX = divX
        dataSet.units = mainUnitY
        
        dataSet.setColor(UIColor(rgbValue: color_slope_chart))
        dataSet.lineWidth = 1
        if (drawFilled) {
            dataSet.fillAlpha = 0.1
            dataSet.fillColor = UIColor(rgbValue: color_slope_chart)
            dataSet.drawFilledEnabled = true
        } else {
            dataSet.drawFilledEnabled = false
        }
        
        dataSet.drawValuesEnabled = false
        dataSet.valueFont = UIFont.systemFont(ofSize: 9)
        dataSet.formLineWidth = 1
        dataSet.formSize = 15
        
        dataSet.drawCirclesEnabled = false
        dataSet.drawCircleHoleEnabled = false
        
        dataSet.highlightEnabled = true
        dataSet.drawVerticalHighlightIndicatorEnabled = true
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.highlightColor = UIColor(rgbValue: color_primary_purple)
        dataSet.mode = LineChartDataSet.Mode.linear
        
        if useRightAxis {
            dataSet.axisDependency = YAxis.AxisDependency.right
        }
        return dataSet;
    }
    
    private static func setupAxisDistance(axisBase: AxisBase, meters: Double) -> Double {
        let settings: OAAppSettings = OAAppSettings.sharedManager()
        let mc: EOAMetricsConstant = settings.metricSystem.get()
        var divX: Double = 0
        
        let format1 = "%.0f"
        let format2 = "%.1f"
        var fmt: String? = nil
        var granularity: Double = 1
        var mainUnitStr: String
        var mainUnitInMeters: Double
        if mc == EOAMetricsConstant.KILOMETERS_AND_METERS {
            mainUnitStr = NSLocalizedString("units_km", comment: "")
            mainUnitInMeters = GpxUIHelper.METERS_IN_KILOMETER
        } else if mc == EOAMetricsConstant.NAUTICAL_MILES {
            mainUnitStr = NSLocalizedString("nm", comment: "")
            mainUnitInMeters = GpxUIHelper.METERS_IN_ONE_NAUTICALMILE
        } else {
            mainUnitStr = NSLocalizedString("units_mi", comment: "")
            mainUnitInMeters = GpxUIHelper.METERS_IN_ONE_MILE
        }
        if (meters > 9.99 * mainUnitInMeters) {
            fmt = format1;
            granularity = 0.1;
        }
        if (meters >= 100 * mainUnitInMeters ||
            meters > 9.99 * mainUnitInMeters ||
                meters > 0.999 * mainUnitInMeters ||
            mc == EOAMetricsConstant.MILES_AND_FEET && meters > 0.249 * mainUnitInMeters ||
            mc == EOAMetricsConstant.MILES_AND_METERS && meters > 0.249 * mainUnitInMeters ||
            mc == EOAMetricsConstant.MILES_AND_YARDS && meters > 0.249 * mainUnitInMeters ||
            mc == EOAMetricsConstant.NAUTICAL_MILES && meters > 0.99 * mainUnitInMeters) {
            
            divX = mainUnitInMeters;
            if (fmt == nil) {
                fmt = format2;
                granularity = 0.01;
            }
        } else {
            fmt = nil;
            granularity = 1;
            if (mc == EOAMetricsConstant.KILOMETERS_AND_METERS || mc == EOAMetricsConstant.MILES_AND_METERS) {
                divX = 1;
                mainUnitStr = NSLocalizedString("units_m", comment: "")
            } else if (mc == EOAMetricsConstant.MILES_AND_FEET) {
                divX = Double(1.0 / GpxUIHelper.FEET_IN_ONE_METER)
                mainUnitStr = NSLocalizedString("units_ft", comment: "")
            } else if (mc == EOAMetricsConstant.MILES_AND_YARDS) {
                divX = Double(1.0 / GpxUIHelper.YARDS_IN_ONE_METER)
                mainUnitStr = NSLocalizedString("units_yd", comment: "")
            } else {
                divX = 1.0;
                mainUnitStr = NSLocalizedString("units_m", comment: "")
            }
        }
        
        let formatX: String? = fmt
        axisBase.granularity = granularity
        axisBase.valueFormatter = ValueFormatter(formatX: formatX, unitsX: mainUnitStr)
        
        return divX;
    }
    
    private static func calculateElevationArray(analysis: OAGPXTrackAnalysis, axisType: GPXDataSetAxisType, divX: Double, convEle: Double, useGeneralTrackPoints: Bool) -> Array<ChartDataEntry> {
        var values: Array<ChartDataEntry> = []
        if (analysis.elevationData == nil) {
            return values
        }
        let elevationData: Array<OAElevation> = analysis.elevationData
        var nextX: Double = 0
        var nextY: Double
        var elev: Double
        var prevElevOrig: Double = -80000
        var prevElev: Double = 0
        var i: Int = -1
        let lastIndex: Int = elevationData.count - 1
        var lastEntry: ChartDataEntry? = nil
        var lastXSameY: Double = -1
        var hasSameY: Bool = false
        var x: Double
        for e in elevationData {
            i += 1;
            if (axisType == .TIME || axisType == .TIMEOFDAY) {
                x = Double(e.time);
            } else {
                x = e.distance;
            }
            if (x > 0)
            {
                nextX += x / divX
                if (!e.elevation.isNaN) {
                    elev = e.elevation;
                    if (prevElevOrig != -80000) {
                        if (elev > prevElevOrig) {
                            elev -= 1;
                        } else if (prevElevOrig == elev && i < lastIndex) {
                            hasSameY = true;
                            lastXSameY = nextX;
                            continue;
                        }
                        if (prevElev == elev && i < lastIndex) {
                            hasSameY = true;
                            lastXSameY = nextX;
                            continue;
                        }
                        if (hasSameY && lastEntry != nil) {
                            values.append(ChartDataEntry(x: lastXSameY, y: lastEntry!.y))
                        }
                        hasSameY = false;
                    }
                    if (useGeneralTrackPoints && e.firstPoint && lastEntry != nil) {
                        values.append(ChartDataEntry(x: nextX, y:lastEntry!.y));
                    }
                    prevElevOrig = e.elevation;
                    prevElev = elev;
                    nextY = elev * convEle;
                    lastEntry = ChartDataEntry(x: nextX, y: nextY);
                    values.append(lastEntry!);
                }
            }
        }
        return values;
    }

    private static func createGPXSpeedDataSet(chartView: LineChartView, analysis: OAGPXTrackAnalysis,
                                              axisType: GPXDataSetAxisType,
                                              useRightAxis: Bool,
                                              drawFilled: Bool) -> OrderedLineDataSet {
        let settings: OAAppSettings = OAAppSettings.sharedManager()
        //    boolean light = settings.isLightContent();
        
        var divX: Double
        let xAxis: XAxis = chartView.xAxis
        if (axisType == GPXDataSetAxisType.TIME && analysis.isTimeSpecified()) {
            divX = setupXAxisTime(xAxis: xAxis, timeSpan: Int64(analysis.timeSpan))
        } else if (axisType == GPXDataSetAxisType.TIMEOFDAY && analysis.isTimeSpecified()) {
            divX = setupXAxisTimeOfDay(xAxis: xAxis, startTime: Int64(analysis.startTime))
        } else {
            divX = setupAxisDistance(axisBase: xAxis, meters: Double(analysis.totalDistance))
        }
        
        let sps: OACommonSpeedConstant = settings.speedSystem
        var mulSpeed = Double.nan
        var divSpeed = Double.nan
        let mainUnitY = OASpeedConstant.toShortString(sps.get())
        if (sps.get() == EOASpeedConstant.KILOMETERS_PER_HOUR) {
            mulSpeed = 3.6;
        } else if (sps.get() == EOASpeedConstant.MILES_PER_HOUR) {
            mulSpeed = 3.6 * GpxUIHelper.METERS_IN_KILOMETER / GpxUIHelper.METERS_IN_ONE_MILE
        } else if (sps.get() == EOASpeedConstant.NAUTICALMILES_PER_HOUR) {
            mulSpeed = 3.6 * GpxUIHelper.METERS_IN_KILOMETER / GpxUIHelper.METERS_IN_ONE_NAUTICALMILE
        } else if (sps.get() == EOASpeedConstant.MINUTES_PER_KILOMETER) {
            divSpeed = GpxUIHelper.METERS_IN_KILOMETER / 60
        } else if (sps.get() == EOASpeedConstant.MINUTES_PER_MILE) {
            divSpeed = GpxUIHelper.METERS_IN_ONE_MILE / 60
        } else {
            mulSpeed = 1
        }
        
        var yAxis: YAxis
        if (useRightAxis) {
            yAxis = chartView.rightAxis
            yAxis.enabled = true
        } else {
            yAxis = chartView.leftAxis
        }
        if (analysis.hasSpeedInTrack) {
            yAxis.labelTextColor = UIColor(rgbValue: color_chart_orange_label)
            yAxis.gridColor = UIColor(argbValue: color_chart_orange_grid)
        } else {
            yAxis.labelTextColor = UIColor(rgbValue: color_chart_red_label)
            yAxis.gridColor = UIColor(argbValue: color_chart_red_grid)
        }

        yAxis.axisMinimum = 0.0
        
        var values: Array<ChartDataEntry> = [ChartDataEntry]()
        let speedData: Array<OASpeed> = analysis.speedData
        var nextX: Double = 0
        var nextY: Double
        var x: Double
        for s: OASpeed in speedData {
            switch(axisType) {
            case GPXDataSetAxisType.TIMEOFDAY, GPXDataSetAxisType.TIME:
                x = Double(s.time)
                break;
            default:
                x = s.distance;
                break;
            }
            
            if (x > 0) {
                if (axisType == GPXDataSetAxisType.TIME && x > 60 ||
                    axisType == GPXDataSetAxisType.TIMEOFDAY && x > 60) {
                    values.append(ChartDataEntry(x: nextX + 1, y: 0))
                    values.append(ChartDataEntry(x: nextX + x - 1, y: 0))
                }
                nextX += x / divX
                if (divSpeed.isNaN) {
                    nextY = s.speed * mulSpeed
                } else {
                    nextY = divSpeed / s.speed
                }
                if (nextY < 0 || nextY.isInfinite) {
                    nextY = 0
                }
                if (s.firstPoint) {
                    values.append(ChartDataEntry(x: nextX, y: 0))
                }
                values.append(ChartDataEntry(x: nextX, y: nextY))
                if (s.lastPoint) {
                    values.append(ChartDataEntry(x: nextX, y: 0))
                }
            }
        }
        
        let dataSet: OrderedLineDataSet = OrderedLineDataSet(entries: values, label: "", dataSetType: GPXDataSetType.SPEED, dataSetAxisType: axisType)
        yAxis.valueFormatter = ValueFormatter(formatX: dataSet.yMax < 3 ? "%.0f" : nil, unitsX: mainUnitY ?? "")
        
        if (divSpeed.isNaN) {
            dataSet.priority = analysis.avgSpeed * Float(mulSpeed)
        } else {
            dataSet.priority = Float(divSpeed) / analysis.avgSpeed
        }
        dataSet.divX = divX
        if (divSpeed.isNaN) {
            dataSet.mulY = mulSpeed
            dataSet.divY = Double.nan
        } else {
            dataSet.divY = divSpeed
            dataSet.mulY = Double.nan
        }
        dataSet.units = mainUnitY ?? ""
        
        if (analysis.hasSpeedInTrack) {
            dataSet.setColor(UIColor(rgbValue: color_chart_orange))
        } else {
            dataSet.setColor(UIColor(rgbValue: color_chart_red))
        }
        dataSet.lineWidth = 1
        if (drawFilled) {
            dataSet.fillAlpha = 0.1
            if (analysis.hasSpeedInTrack) {
                dataSet.fillColor = UIColor(rgbValue: color_chart_orange)
            } else {
                dataSet.fillColor = UIColor(rgbValue: color_chart_red)
            }
            dataSet.drawFilledEnabled = true
        } else {
            dataSet.drawFilledEnabled = false
        }
        dataSet.drawValuesEnabled = false
        dataSet.valueFont = UIFont.systemFont(ofSize: 9.0)
        dataSet.formLineWidth = 1
        dataSet.formSize = 15.0
        
        dataSet.drawCirclesEnabled = false
        dataSet.drawCircleHoleEnabled = false
        
        dataSet.highlightEnabled = true
        dataSet.drawVerticalHighlightIndicatorEnabled = true
        dataSet.drawHorizontalHighlightIndicatorEnabled = false
        dataSet.highlightColor = UIColor(rgbValue: color_primary_purple)
        
        if (useRightAxis) {
            dataSet.axisDependency = .right
        }
        return dataSet;
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
