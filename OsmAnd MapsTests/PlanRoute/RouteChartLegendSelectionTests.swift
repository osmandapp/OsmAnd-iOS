import DGCharts
import OsmAndShared
import UIKit
import XCTest
@testable import OsmAnd_Maps

@MainActor
final class RouteChartLegendSelectionTests: XCTestCase {
    func testLegendFollowsSelectionAcrossChartsAndRepeatedAttributes() {
        let synchronizer = RouteChartSynchronizer()
        let surface = makeChart(names: ["asphalt", "undefined", "asphalt"])
        let roadType = makeChart(names: ["primary", "secondary", "primary"])
        synchronizer.registerBarChart(surface)
        synchronizer.registerBarChart(roadType)
        let asphalt = makeLegend("Asphalt")
        let undefined = makeLegend("Undefined")
        let primary = makeLegend("Primary")
        synchronizer.registerLegendItem(asphalt, propertyName: "asphalt", chart: surface)
        synchronizer.registerLegendItem(undefined, propertyName: "undefined", chart: surface)
        synchronizer.registerLegendItem(primary, propertyName: "primary", chart: roadType)

        select(0.15, chart: surface, synchronizer: synchronizer)
        XCTAssertTrue(asphalt.isSelected)
        XCTAssertFalse(undefined.isSelected)
        XCTAssertTrue(primary.isSelected)
        select(0.5, chart: roadType, synchronizer: synchronizer)
        XCTAssertFalse(asphalt.isSelected)
        XCTAssertTrue(undefined.isSelected)
        XCTAssertFalse(primary.isSelected)
        select(0.85, chart: surface, synchronizer: synchronizer)
        XCTAssertTrue(asphalt.isSelected)
        XCTAssertFalse(undefined.isSelected)
    }

    func testCompactLegendAndNewlyRegisteredLegendRestoreAndClearSelection() throws {
        let synchronizer = RouteChartSynchronizer()
        let chart = makeChart(names: ["asphalt", "undefined", "asphalt"])
        synchronizer.registerBarChart(chart)
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .footnote)
        let regularFont = label.font
        synchronizer.registerLegendLabel(label, propertyName: "asphalt", chart: chart)
        select(0.15, chart: chart, synchronizer: synchronizer)
        XCTAssertTrue(label.font.fontDescriptor.symbolicTraits.contains(.traitBold))
        let expanded = makeLegend("Asphalt")
        synchronizer.registerLegendItem(expanded, propertyName: "asphalt", chart: chart)
        XCTAssertTrue(expanded.isSelected)
        let title = try XCTUnwrap(expanded.value(forKey: "titleView") as? UILabel)
        let distance = try XCTUnwrap(expanded.value(forKey: "distanceView") as? UILabel)
        XCTAssertTrue(title.font.fontDescriptor.symbolicTraits.contains(.traitBold))
        XCTAssertTrue(distance.font.fontDescriptor.symbolicTraits.contains(.traitBold))
        synchronizer.unregisterBarChart(chart)
        synchronizer.registerBarChart(chart)
        XCTAssertTrue(expanded.isSelected)
        synchronizer.clearSynchronizedHighlights()
        XCTAssertFalse(expanded.isSelected)
        XCTAssertFalse(title.font.fontDescriptor.symbolicTraits.contains(.traitBold))
        XCTAssertTrue(distance.font.fontDescriptor.symbolicTraits.contains(.traitBold))
        XCTAssertEqual(label.font, regularFont)
        XCTAssertFalse(label.accessibilityTraits.contains(.selected))
    }

    func testGapClearsLegendAndFollowingStackUsesItsOwnAttribute() {
        let synchronizer = RouteChartSynchronizer()
        let chart = makeChart(names: ["asphalt", nil, "undefined"])
        synchronizer.registerBarChart(chart)
        let asphalt = makeLegend("Asphalt")
        let undefined = makeLegend("Undefined")
        synchronizer.registerLegendItem(asphalt, propertyName: "asphalt", chart: chart)
        synchronizer.registerLegendItem(undefined, propertyName: "undefined", chart: chart)
        select(0.15, chart: chart, synchronizer: synchronizer)
        XCTAssertTrue(asphalt.isSelected)
        select(0.5, chart: chart, synchronizer: synchronizer)
        XCTAssertFalse(asphalt.isSelected)
        XCTAssertFalse(undefined.isSelected)
        select(0.85, chart: chart, synchronizer: synchronizer)
        XCTAssertTrue(undefined.isSelected)
        synchronizer.reset()
        XCTAssertFalse(undefined.isSelected)
    }

    func testSingleAttributeLegendIsSelectedForUnstackedHighlight() {
        let synchronizer = RouteChartSynchronizer()
        let chart = makeChart(names: ["asphalt"])
        synchronizer.registerBarChart(chart)
        let legend = makeLegend("Asphalt")
        synchronizer.registerLegendItem(legend, propertyName: "asphalt", chart: chart)
        select(0.5, chart: chart, synchronizer: synchronizer)
        XCTAssertTrue(legend.isSelected)
    }

    func testAltitudeSelectionUpdatesAttributeLegend() {
        let synchronizer = RouteChartSynchronizer()
        let surface = makeChart(names: ["asphalt", "undefined", "asphalt"])
        synchronizer.registerBarChart(surface)
        let legend = makeLegend("Undefined")
        synchronizer.registerLegendItem(legend, propertyName: "undefined", chart: surface)
        let primary = ElevationChart(frame: CGRect(x: 0, y: 0, width: 360, height: 120))
        let entries = [ChartDataEntry(x: 0, y: 10), ChartDataEntry(x: 150, y: 15), ChartDataEntry(x: 300, y: 10)]
        let dataSet = GpxUIHelper.OrderedLineDataSet(entries: entries,
                                                     label: "",
                                                     dataSetType: .altitude,
                                                     dataSetAxisType: .distance,
                                                     leftAxis: true)
        primary.data = LineChartData(dataSet: dataSet)
        primary.layoutIfNeeded()
        primary.notifyDataSetChanged()
        synchronizer.setPrimaryChart(primary)
        synchronizer.syncHighlight(Highlight(x: 150, y: 15, dataSetIndex: 0), sourceChart: primary)
        XCTAssertTrue(legend.isSelected)
        synchronizer.syncHighlight(Highlight(x: 0, y: 10, dataSetIndex: 0), sourceChart: primary)
        XCTAssertFalse(legend.isSelected)
    }

    func testChartBuilderPreservesNamesWhenGapSplitsAnAttribute() throws {
        let segment = try XCTUnwrap(OARouteSegmentAttribute(propertyName: "asphalt", color: Int(UInt32(bitPattern: UIColor.iconColorActive.toARGBNumber())), slopeIndex: -1, boundariesClass: []))
        segment.distance = 200
        let statistics = try XCTUnwrap(OARouteStatistics(name: "routeInfo_surface", elements: [segment], partition: ["asphalt": segment], totalDistance: 200))
        let analysis = GpxTrackAnalysis()
        analysis.pointAttributes.add(PointAttributes(distance: 100, timeDiff: 1, firstPoint: false, lastPoint: false))
        analysis.pointAttributes.add(PointAttributes(distance: 20, timeDiff: 1, firstPoint: true, lastPoint: false))
        analysis.pointAttributes.add(PointAttributes(distance: 100, timeDiff: 1, firstPoint: false, lastPoint: false))
        let chart = HorizontalBarChartView(frame: CGRect(x: 0, y: 0, width: 360, height: 120))
        GpxUIHelper.refreshRouteBarChart(chartView: chart, statistics: statistics, analysis: analysis, nightMode: false)
        let entry = try XCTUnwrap(chart.barData?.dataSets.first?.entryForIndex(0) as? BarChartDataEntry)
        XCTAssertEqual(entry.data as? [String?], ["asphalt", nil, "asphalt"])
        XCTAssertEqual(entry.yValues?.count, 3)
    }

    private func makeChart(names: [String?]) -> HorizontalBarChartView {
        let chart = HorizontalBarChartView(frame: CGRect(x: 0, y: 0, width: 360, height: 120))
        let entry = BarChartDataEntry(x: 0, yValues: names.map { _ in 100 }, data: names)
        let dataSet = BarChartDataSet(entries: [entry], label: "")
        chart.data = BarChartData(dataSet: dataSet)
        chart.leftAxis.axisMinimum = 0
        chart.leftAxis.axisMaximum = Double(names.count) * 100
        chart.rightAxis.axisMinimum = 0
        chart.rightAxis.axisMaximum = Double(names.count) * 100
        chart.layoutIfNeeded()
        chart.notifyDataSetChanged()
        return chart
    }

    private func makeLegend(_ title: String) -> OARouteInfoLegendItemView {
        OARouteInfoLegendItemView(title: title, color: .iconColorActive, distance: "100 m")
    }

    private func select(_ progress: Double, chart: HorizontalBarChartView, synchronizer: RouteChartSynchronizer) {
        let highlight = Highlight(x: chart.leftAxis.axisMaximum * progress, y: 0, dataSetIndex: 0)
        synchronizer.syncHighlight(highlight, sourceChart: chart)
    }
}
