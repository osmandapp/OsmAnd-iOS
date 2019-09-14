//
//  OARouteStatisticsViewController.swift
//  OsmAnd
//
//  Created by Paul on 9/3/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

import UIKit
import Charts

public enum GPXDataSetType: String {
    case ALTITUDE = "map_widget_altitude"
    case SPEED = "gpx_speed"
    case SLOPE = "gpx_slope"
    
    public func getName() -> String {
        return NSLocalizedString(self.rawValue, comment: "");
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

@objc class OARouteStatisticsViewController: UIViewController {
    
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
    
    private class OrderedLineDataSet: LineChartDataSet {
        
        private var dataSetType: GPXDataSetType;
        private var dataSetAxisType: GPXDataSetAxisType;
        
        var priority: Float;
        var units: String;
        var divX: Double = 1;
        var divY: Double = 1;
        var mulY: Double = 1;
        
        init(entries: [ChartDataEntry]?, label: String?, dataSetType: GPXDataSetType, dataSetAxisType: GPXDataSetAxisType) {
            self.dataSetType = dataSetType
            self.dataSetAxisType = dataSetAxisType
            self.priority = 0
            self.units = ""
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
        
        public func getDivX() -> Double {
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
    }
    
    private var slopeDataSet: OrderedLineDataSet?
    private var elevationDataSet: OrderedLineDataSet?

    @IBOutlet weak var chartView: LineChartView!
    // For testing
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGPXChart(yLabelsCount: 4, topOffset: 0, bottomOffset: 0, useGesturesAndScale: true)
    }
    
    @objc public func refreshLineChart(analysis: OAGPXTrackAnalysis) {
        if (analysis.hasElevationData) {
            setupGPXChart(yLabelsCount: 4, topOffset: 0, bottomOffset: 0, useGesturesAndScale: true)
            var dataSets = [ILineChartDataSet]()
            var slopeDataSet: OrderedLineDataSet? = nil
            let elevationDataSet = createGPXElevationDataSet(analysis: analysis, axisType: GPXDataSetAxisType.DISTANCE, useRightAxis: false, drawFilled: true)
            dataSets.append(elevationDataSet);
            slopeDataSet = createGPXSlopeDataSet(analysis: analysis, axisType: GPXDataSetAxisType.DISTANCE, eleValues: elevationDataSet.entries, useRightAxis: true, drawFilled: true)
            
            if (slopeDataSet != nil) {
                dataSets.append(slopeDataSet!)
            }
            self.elevationDataSet = elevationDataSet
            self.slopeDataSet = slopeDataSet
            
            let data = LineChartData(dataSets: dataSets)
            chartView.data = data;
        }
    }
    
    public func setupGPXChart(yLabelsCount: Int, topOffset: CGFloat, bottomOffset: CGFloat, useGesturesAndScale: Bool) {
        chartView.dragEnabled = useGesturesAndScale
        chartView.setScaleEnabled(useGesturesAndScale)
        chartView.pinchZoomEnabled = useGesturesAndScale
        chartView.scaleYEnabled = false
        chartView.autoScaleMinMaxEnabled = true
        chartView.drawBordersEnabled = false
        chartView.chartDescription?.enabled = false
        chartView.maxVisibleCount = 10
        chartView.minOffset = 0.0
//        setDragDecelerationEnabled(false);
        
        chartView.extraTopOffset = topOffset
        chartView.extraBottomOffset = bottomOffset
        // TODO
        // create a custom MarkerView (extend MarkerView) and specify the layout
        // to use for it
//        GPXMarkerView mv = new GPXMarkerView(chartView.getContext());
//        mv.setChartView(chartView); // For bounds control
//        chartView.setMarker(mv); // Set the marker to the chart
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
        
        let yColor = UIColor(rgbValue: color_tint_gray)
        var yAxis: YAxis = chartView.leftAxis;
        yAxis.gridLineDashLengths = [10.0, 5.0]
        yAxis.gridColor = yColor
        yAxis.drawAxisLineEnabled = false
        yAxis.drawGridLinesEnabled = true
        yAxis.labelPosition = .insideChart
        yAxis.xOffset = 16.0
        yAxis.yOffset = -6.0
        yAxis.labelCount = yLabelsCount
        xAxis.labelTextColor = labelsColor
        
        yAxis = chartView.rightAxis;
        yAxis.gridLineDashLengths = [10.0, 5.0]
        yAxis.gridColor = yColor
        yAxis.drawAxisLineEnabled = false
        yAxis.drawGridLinesEnabled = true
        yAxis.labelPosition = .insideChart
        yAxis.xOffset = 16.0
        yAxis.yOffset = -6.0
        yAxis.labelCount = yLabelsCount
        xAxis.labelTextColor = labelsColor
        yAxis.enabled = false
        
        let legend = chartView.legend
        legend.enabled = false
    }
    
    private func createGPXElevationDataSet(analysis: OAGPXTrackAnalysis, axisType: GPXDataSetAxisType, useRightAxis: Bool, drawFilled: Bool) -> OrderedLineDataSet {
        let mc: EOAMetricsConstant = OAAppSettings.sharedManager().metricSystem
        let useFeet: Bool = (mc == EOAMetricsConstant.MILES_AND_FEET) || (mc == EOAMetricsConstant.MILES_AND_YARDS)
        let convEle: Double = useFeet ? 3.28084 : 1.0
        
        var divX: Double
        let xAxis: XAxis = chartView.xAxis
        
        divX = setupAxisDistance(axisBase: xAxis, meters: Double(analysis.totalDistance))
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
        // TODO set colors
        //        dataSet.setHighLightColor(light ? mChart.getResources().getColor(R.color.text_color_secondary_light) : mChart.getResources().getColor(R.color.text_color_secondary_dark));
        dataSet.highlightColor = UIColor(rgbValue: color_tint_gray)
        dataSet.mode = LineChartDataSet.Mode.horizontalBezier
        dataSet.fillFormatter = HeightFormatter()
        if useRightAxis {
           dataSet.axisDependency = YAxis.AxisDependency.right
        }
        return dataSet
    }
    
    private func createGPXSlopeDataSet(analysis: OAGPXTrackAnalysis,
                                      axisType: GPXDataSetAxisType,
                                      eleValues: Array<ChartDataEntry>,
                                      useRightAxis: Bool,
                                      drawFilled: Bool) -> OrderedLineDataSet? {
        if (axisType == GPXDataSetAxisType.TIME || axisType == GPXDataSetAxisType.TIMEOFDAY) {
            return nil;
        }
        let mc: EOAMetricsConstant = OAAppSettings.sharedManager().metricSystem
        let useFeet: Bool = (mc == EOAMetricsConstant.MILES_AND_FEET) || (mc == EOAMetricsConstant.MILES_AND_YARDS)
        let convEle: Double = useFeet ? 3.28084 : 1.0
        let totalDistance: Float = analysis.totalDistance;
        
        let xAxis: XAxis = chartView.xAxis
        let divX: Double = setupAxisDistance(axisBase: xAxis, meters: Double(analysis.totalDistance))
        
        let mainUnitY: String = "%"
        
        var yAxis: YAxis
        if (useRightAxis) {
            yAxis = chartView.rightAxis
            yAxis.enabled = true
        } else {
            yAxis = chartView.leftAxis
        }
        yAxis.labelTextColor = UIColor(rgbValue: color_slope_chart)
        yAxis.gridColor = UIColor(rgbValue: color_slope_chart)
//        setGridColor(ActivityCompat.getColor(mChart.getContext(), R.color.gpx_chart_green_grid));
        yAxis.granularity = 1.0
        yAxis.resetCustomAxisMax()
        yAxis.valueFormatter = ValueFormatter(formatX: nil, unitsX: mainUnitY)
        
        var values: Array<ChartDataEntry> = Array()
//        if (eleValues == nil) {
//            values = calculateElevationArray(analysis, GPXDataSetAxisType.DISTANCE, 1f, 1f, false);
//        } else {
        for e in eleValues {
            values.append(ChartDataEntry(x: e.x * divX, y: e.y / convEle))
        }
//        }
        
        if (values.count == 0) {
            if (useRightAxis) {
                yAxis.enabled = false
            }
            return nil
        }
        
        var lastIndex = values.count - 1
        
        var step: Double = 5
        var l: Int = 10
        while (l > 0 && Double(totalDistance) / step > OARouteStatisticsViewController.MAX_CHART_DATA_ITEMS) {
            step = max(step, Double(totalDistance) / Double(values.count * l));
            l = l - 1
        }
        
        var calculatedDist: Array<Double> = Array(repeating: 0, count: Int((Double(totalDistance) / step) + 1))
        var calculatedH: Array<Double> = Array(repeating: 0, count: Int((Double(totalDistance) / step) + 1))
        var nextW: Int = 0
        for k in 0...calculatedDist.count - 1 {
            if (k > 0) {
                calculatedDist.insert(calculatedDist[k - 1] + step, at: k)
            }
            while (nextW < lastIndex && calculatedDist[k] > values[nextW].x) {
                nextW += 1
            }
            let pd: Double = nextW == 0 ? 0 : values[nextW - 1].x
            let ph: Double = nextW == 0 ? values[0].y : values[nextW - 1].y
            calculatedH.insert(ph + (values[nextW].y - ph) / (values[nextW].x - pd) * (calculatedDist[k] - pd), at:k)
        }
        
        let slopeProximity: Double = max(100, step * 2)
        
        if (Double(totalDistance) - slopeProximity < 0) {
            if (useRightAxis) {
                yAxis.enabled = false
            }
            return nil;
        }
        
        var calculatedSlopeDist: Array<Double> = Array(repeating: 0, count: Int(((Double(totalDistance) - slopeProximity) / step) + 1))
        var calculatedSlope: Array<Double> = Array(repeating: 0, count: Int(((Double(totalDistance) - slopeProximity) / step) + 1))
        let index: Int = Int((slopeProximity / step) / 2)
        for k in 0...calculatedSlopeDist.count - 1 {
            calculatedSlopeDist.insert(calculatedDist[index + k], at: k)
            calculatedSlope.insert((calculatedH[ 2 * index + k] - calculatedH[k]) * 100 / slopeProximity, at: k)
            if (calculatedSlope[k].isNaN) {
                calculatedSlope.insert(0, at: k)
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
        for i in 0...lastIndex {
            x = calculatedSlopeDist[i] / divX
            slope = calculatedSlope[i]
            if (prevSlope != -80000) {
                if (prevSlope == slope && i < lastIndex) {
                    hasSameY = true;
                    lastXSameY = x;
                    continue;
                }
                if (hasSameY) {
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
        dataSet.highlightColor = UIColor(rgbValue: color_tint_gray)
        
        //dataSet.setMode(LineDataSet.Mode.HORIZONTAL_BEZIER);
        
        /*
         dataSet.setFillFormatter(new IFillFormatter() {
         @Override
         public float getFillLinePosition(ILineDataSet dataSet, LineDataProvider dataProvider) {
         return dataProvider.getYChartMin();
         }
         });
         */
        if useRightAxis {
            dataSet.axisDependency = YAxis.AxisDependency.right
        }
        return dataSet;
    }
    
    private func setupAxisDistance(axisBase: AxisBase, meters: Double) -> Double {
        let settings: OAAppSettings = OAAppSettings.sharedManager()
        let mc: EOAMetricsConstant = settings.metricSystem
        var divX: Double
        
        let format1 = "%.0f"
        let format2 = "%.1f"
        var fmt: String? = nil
        var granularity: Double = 1
        var mainUnitStr: String
        var mainUnitInMeters: Double
        if mc == EOAMetricsConstant.KILOMETERS_AND_METERS {
            mainUnitStr = NSLocalizedString("units_km", comment: "")
            mainUnitInMeters = OARouteStatisticsViewController.METERS_IN_KILOMETER
        } else if mc == EOAMetricsConstant.NAUTICAL_MILES {
            mainUnitStr = NSLocalizedString("nm", comment: "")
            mainUnitInMeters = OARouteStatisticsViewController.METERS_IN_ONE_NAUTICALMILE
        } else {
            mainUnitStr = NSLocalizedString("units_mi", comment: "")
            mainUnitInMeters = OARouteStatisticsViewController.METERS_IN_ONE_MILE
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
                divX = Double(1.0 / OARouteStatisticsViewController.FEET_IN_ONE_METER)
                mainUnitStr = NSLocalizedString("units_ft", comment: "")
            } else if (mc == EOAMetricsConstant.MILES_AND_YARDS) {
                divX = Double(1.0 / OARouteStatisticsViewController.YARDS_IN_ONE_METER)
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
    
    private func calculateElevationArray(analysis: OAGPXTrackAnalysis, axisType: GPXDataSetAxisType, divX: Double, convEle: Double, useGeneralTrackPoints: Bool) -> Array<ChartDataEntry> {
        var values: Array<ChartDataEntry> = []
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
                        if (hasSameY) {
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
    
}
