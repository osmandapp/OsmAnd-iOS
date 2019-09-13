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
    
    private class ValueFormatter: IAxisValueFormatter
    {
        private var formatX: String?
        private var unitsX: String
        
        init(formatX: String?, unitsX: String) {
            self.formatX = formatX
            self.unitsX = unitsX
        }
        
        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
//            if (formatX != nil && formatX?.length ?? 0 > 0) {
//                return String(format: "\%%s", )
//            } else {
            return String(value) + " " + self.unitsX
//            }
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
        let dollars1 = [20.0, 4.0, 6.0, 3.0, 12.0, 16.0, 4.0, 18.0, 2.0, 4.0, 5.0, 4.0]
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        // 1 - creating an array of data entries
        var yValues : [ChartDataEntry] = [ChartDataEntry]()
        for i in 0 ..< months.count {
            yValues.append(ChartDataEntry(x: Double(i + 1), y: dollars1[i]))
        }
        
        let data = LineChartData()
        let ds = LineChartDataSet(entries: yValues, label: "Months")
        
        data.addDataSet(ds)
        chartView.data = data
    }
    
    @objc public func refreshLineChart(analysis: OAGPXTrackAnalysis) {
        if (analysis.hasElevationData) {
            var dataSets = [ILineChartDataSet]();
//            OrderedLineDataSet slopeDataSet = null;
//            OAOrderedLineDataSet elevationDataSet = createGPXElevationDataSet(app, mChart, analysis,
//                                                                                        GPXDataSetAxisType.DISTANCE, false, true);
            let elevationDataSet = createGPXElevationDataSet(analysis: analysis)
            dataSets.append(elevationDataSet);
//                slopeDataSet = GpxUiHelper.createGPXSlopeDataSet(app, mChart, analysis,
//                                                                 GPXDataSetAxisType.DISTANCE, elevationDataSet.getValues(), true, true);
        
//            if (slopeDataSet != null) {
//                dataSets.add(slopeDataSet);
//            }
            self.elevationDataSet = elevationDataSet
//            self.slopeDataSet = slopeDataSet;
            
            let data = LineChartData(dataSets: dataSets)
            chartView.data = data;
        }
    }
    
    private func createGPXElevationDataSet(analysis: OAGPXTrackAnalysis) -> OrderedLineDataSet {
        // TODO Draw filled! & other params
        let drawFilled: Bool = true
        let useRightAxis: Bool = false
        let mc: EOAMetricsConstant = OAAppSettings.sharedManager().metricSystem
        let useFeet: Bool = (mc == EOAMetricsConstant.MILES_AND_FEET) || (mc == EOAMetricsConstant.MILES_AND_YARDS)
        let convEle: Double = useFeet ? 3.28084 : 1.0
        
        var divX: Double
        let xAxis: XAxis = chartView.xAxis
        
        divX = setupAxisDistance(axisBase: xAxis, meters: Double(analysis.totalDistance))

        
        let mainUnitY: String = useFeet ? NSLocalizedString("units_ft", comment: "") : NSLocalizedString("units_m", comment: "")
        
        var yAxis: YAxis
//        if (useRightAxis) {
//            yAxis = mChart.getAxisRight();
//            yAxis.setEnabled(true);
//        } else {
            yAxis = chartView.leftAxis
//        }
//        yAxis.setTextColor(ActivityCompat.getColor(mChart.getContext(), R.color.gpx_chart_blue_label));
//        yAxis.setGridColor(ActivityCompat.getColor(mChart.getContext(), R.color.gpx_chart_blue_grid));
        yAxis.granularity = 1
        yAxis.resetCustomAxisMax()
        yAxis.valueFormatter = ValueFormatter(formatX: nil, unitsX: mainUnitY)
        let values: Array<ChartDataEntry> = calculateElevationArray(analysis: analysis, divX: divX, convEle: convEle, useGeneralTrackPoints: true)
        // TODO: axisType!
        let dataSet: OrderedLineDataSet = OrderedLineDataSet(entries: values, label: "", dataSetType: GPXDataSetType.ALTITUDE, dataSetAxisType: GPXDataSetAxisType.DISTANCE)
        dataSet.priority = Float((analysis.avgElevation - analysis.minElevation) * convEle)
        dataSet.divX = divX
        dataSet.mulY = convEle
        dataSet.divY = Double.nan
        dataSet.units = mainUnitY

        dataSet.setColor(NSUIColor(red: 35, green: 123, blue: 255, alpha: 1))
        dataSet.lineWidth = 1
        if drawFilled {
            dataSet.fillAlpha = 0.1
            dataSet.fillColor = NSUIColor(red: 35, green: 123, blue: 255, alpha: 1)
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
        dataSet.highlightColor = NSUIColor(red: 114, green: 114, blue: 114, alpha: 1)
        dataSet.mode = LineChartDataSet.Mode.horizontalBezier
        dataSet.fillFormatter = HeightFormatter()
        if useRightAxis {
           dataSet.axisDependency = YAxis.AxisDependency.right
        }
        return dataSet
    }
    
    private func setupAxisDistance(axisBase: AxisBase, meters: Double) -> Double {
        let settings: OAAppSettings = OAAppSettings.sharedManager()
        let mc: EOAMetricsConstant = settings.metricSystem
        var divX: Double
        
        var format1 = "{0,number,0.#} "
        var format2 = "{0,number,0.##} "
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
    
    private func calculateElevationArray(analysis: OAGPXTrackAnalysis, divX: Double, convEle: Double, useGeneralTrackPoints: Bool) -> Array<ChartDataEntry> {
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
        var x: CLLocationDistance
        for e in elevationData {
            i += 1;
//            if (axisType == GPXDataSetAxisType.TIME || axisType == GPXDataSetAxisType.TIMEOFDAY) {
//                x = e.time;
//            } else {
                x = e.distance;
//            }
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
