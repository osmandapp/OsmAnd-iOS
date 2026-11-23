import DGCharts
import OsmAndShared
import UIKit
import XCTest
@testable import OsmAnd_Maps

@MainActor
final class RouteChartLegendSelectionTests: XCTestCase {
    private final class FailingBarHighlighter: HorizontalBarHighlighter {
        var failsLookup = false

        override func getHighlight(x: CGFloat, y: CGFloat) -> Highlight? {
            failsLookup ? nil : super.getHighlight(x: x, y: y)
        }
    }

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

    func testSyntheticSteepnessUsesLegendGroupsWhenRenderingPropertiesMatch() throws {
        let titles = ["0%–3%", "4%–6%", "0%–3%"]
        let elements = try titles.map { title in
            let segment = try XCTUnwrap(OARouteSegmentAttribute(propertyName: "undefined", color: Int(UInt32(bitPattern: UIColor.iconColorActive.toARGBNumber())), slopeIndex: -1, boundariesClass: []))
            segment.userPropertyName = title
            segment.distance = 100
            return segment
        }
        let statistics = try XCTUnwrap(OARouteStatistics(name: "routeInfo_steepness", elements: elements, partition: [titles[0]: elements[0], titles[1]: elements[1]], totalDistance: 300))
        let chart = HorizontalBarChartView(frame: CGRect(x: 0, y: 0, width: 360, height: 120))
        GpxUIHelper.refreshRouteBarChart(chartView: chart, statistics: statistics, analysis: GpxTrackAnalysis(), nightMode: false)
        let entry = try XCTUnwrap(chart.barData?.dataSets.first?.entryForIndex(0) as? BarChartDataEntry)
        XCTAssertEqual(entry.data as? [String?], titles.map { Optional($0) })
        let synchronizer = RouteChartSynchronizer()
        synchronizer.registerBarChart(chart)
        let flat = makeLegend(titles[0])
        let uphill = makeLegend(titles[1])
        synchronizer.registerLegendItem(flat, propertyName: titles[0], chart: chart)
        synchronizer.registerLegendItem(uphill, propertyName: titles[1], chart: chart)
        select(0.15, chart: chart, synchronizer: synchronizer)
        XCTAssertTrue(flat.isSelected)
        XCTAssertFalse(uphill.isSelected)
        select(0.5, chart: chart, synchronizer: synchronizer)
        XCTAssertFalse(flat.isSelected)
        XCTAssertTrue(uphill.isSelected)
        select(0.85, chart: chart, synchronizer: synchronizer)
        XCTAssertTrue(flat.isSelected)
        XCTAssertFalse(uphill.isSelected)
    }

    func testAltitudeSelectionAtFirstPointAfterGapSelectsFollowingAttribute() {
        let synchronizer = RouteChartSynchronizer()
        let chart = makeChart(names: ["asphalt", nil, "sett"])
        synchronizer.registerBarChart(chart)
        let asphalt = makeLegend("Asphalt")
        let sett = makeLegend("Sett")
        synchronizer.registerLegendItem(asphalt, propertyName: "asphalt", chart: chart)
        synchronizer.registerLegendItem(sett, propertyName: "sett", chart: chart)
        let primary = ElevationChart(frame: CGRect(x: 0, y: 0, width: 360, height: 120))
        let entries = [0.0, 100, 150, 200, 300].map { ChartDataEntry(x: $0, y: 10) }
        let dataSet = GpxUIHelper.OrderedLineDataSet(entries: entries,
                                                     label: "",
                                                     dataSetType: .altitude,
                                                     dataSetAxisType: .distance,
                                                     leftAxis: true)
        primary.data = LineChartData(dataSet: dataSet)
        primary.layoutIfNeeded()
        primary.notifyDataSetChanged()
        synchronizer.setPrimaryChart(primary)
        synchronizer.syncHighlight(Highlight(x: 150, y: 10, dataSetIndex: 0), sourceChart: primary)
        XCTAssertFalse(asphalt.isSelected)
        XCTAssertFalse(sett.isSelected)
        synchronizer.syncHighlight(Highlight(x: 200, y: 10, dataSetIndex: 0), sourceChart: primary)
        XCTAssertFalse(asphalt.isSelected)
        XCTAssertTrue(sett.isSelected)
        let restored = makeLegend("Sett")
        synchronizer.registerLegendItem(restored, propertyName: "sett", chart: chart)
        XCTAssertTrue(restored.isSelected)
    }

    func testFailedLookupClearsHighlightBeforeLegendRegistration() {
        let synchronizer = RouteChartSynchronizer()
        let chart = makeChart(names: ["asphalt", "sett"])
        let highlighter = FailingBarHighlighter(chart: chart)
        chart.highlighter = highlighter
        synchronizer.registerBarChart(chart)
        let source = makeChart(names: ["primary", "secondary"])
        synchronizer.registerBarChart(source)
        let asphalt = makeLegend("Asphalt")
        synchronizer.registerLegendItem(asphalt, propertyName: "asphalt", chart: chart)
        select(0.25, chart: chart, synchronizer: synchronizer)
        XCTAssertTrue(asphalt.isSelected)
        highlighter.failsLookup = true
        select(0.75, chart: source, synchronizer: synchronizer)
        XCTAssertFalse(asphalt.isSelected)
        XCTAssertNil(chart.lastHighlighted)
        XCTAssertTrue(chart.highlighted.isEmpty)
        let expanded = makeLegend("Asphalt")
        synchronizer.registerLegendItem(expanded, propertyName: "asphalt", chart: chart)
        XCTAssertFalse(expanded.isSelected)
        XCTAssertFalse(asphalt.isSelected)
    }

    func testAccessibilitySelectionMovesBetweenCompactAndExpandedEntries() {
        let synchronizer = RouteChartSynchronizer()
        let chart = makeChart(names: ["asphalt", "sett"])
        synchronizer.registerBarChart(chart)
        let labels = [UILabel(), UILabel()]
        let rows = [makeLegend("Asphalt"), makeLegend("Sett")]
        for (index, name) in ["asphalt", "sett"].enumerated() {
            labels[index].text = name
            synchronizer.registerLegendLabel(labels[index], propertyName: name, chart: chart)
            synchronizer.registerLegendItem(rows[index], propertyName: name, chart: chart)
        }
        for progress in [0.25, 0.75] {
            select(progress, chart: chart, synchronizer: synchronizer)
            for index in labels.indices {
                let expected = index == (progress < 0.5 ? 0 : 1)
                XCTAssertEqual(labels[index].accessibilityTraits.contains(.selected), expected)
                XCTAssertEqual(rows[index].accessibilityTraits.contains(.selected), expected)
                XCTAssertTrue(labels[index].isAccessibilityElement)
                XCTAssertTrue(rows[index].isAccessibilityElement)
            }
        }
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
