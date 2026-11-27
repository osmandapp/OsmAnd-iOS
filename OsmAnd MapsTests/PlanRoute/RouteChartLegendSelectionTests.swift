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

    private final class CountingLegendLabel: UILabel {
        var fontUpdates = 0
        var traitUpdates = 0

        override var font: UIFont? {
            didSet { fontUpdates += 1 }
        }

        override var accessibilityTraits: UIAccessibilityTraits {
            didSet { traitUpdates += 1 }
        }
    }

    private final class SelectionTapGestureRecognizer: UITapGestureRecognizer {
        var tapLocation = CGPoint.zero
        var selectionAction: Selector?
        var isSendingTap = false
        weak var selectionTarget: NSObject?

        override var state: UIGestureRecognizer.State {
            get { isSendingTap ? .ended : super.state }
            set { super.state = newValue }
        }

        override func addTarget(_ target: Any, action: Selector) {
            super.addTarget(target, action: action)
            if let target = target as? RouteChartSynchronizer {
                selectionTarget = target
                selectionAction = action
            }
        }

        override func removeTarget(_ target: Any?, action: Selector?) {
            super.removeTarget(target, action: action)
            if target == nil || target as? NSObject === selectionTarget {
                selectionTarget = nil
                selectionAction = nil
            }
        }

        override func location(in view: UIView?) -> CGPoint {
            tapLocation
        }

        func sendTap() throws {
            let target = try XCTUnwrap(selectionTarget)
            let action = try XCTUnwrap(selectionAction)
            isSendingTap = true
            defer { isSendingTap = false }
            target.perform(action, with: self)
        }
    }

    private final class SelectionPanGestureRecognizer: UIPanGestureRecognizer {
        var panLocation = CGPoint.zero
        var selectionAction: Selector?
        var isSendingPan = false
        weak var selectionTarget: NSObject?

        override var state: UIGestureRecognizer.State {
            get { isSendingPan ? .changed : super.state }
            set { super.state = newValue }
        }

        override func addTarget(_ target: Any, action: Selector) {
            super.addTarget(target, action: action)
            if let target = target as? RouteChartSynchronizer {
                selectionTarget = target
                selectionAction = action
            }
        }

        override func removeTarget(_ target: Any?, action: Selector?) {
            super.removeTarget(target, action: action)
            if target == nil || target as? NSObject === selectionTarget {
                selectionTarget = nil
                selectionAction = nil
            }
        }

        override func location(in view: UIView?) -> CGPoint {
            panLocation
        }

        func sendPan() throws {
            let target = try XCTUnwrap(selectionTarget)
            let action = try XCTUnwrap(selectionAction)
            isSendingPan = true
            defer { isSendingPan = false }
            target.perform(action, with: self)
        }
    }

    private final class AnalyzeDataSource: PlanRouteAnalyzeDataSource {
        let routeInfo = PlanRouteInfo.empty
        let isCalculatingElevation = false
        let isCalculatingRoute = false
        let isTerrainElevationAvailable = false
        let analysisData: PlanRouteAnalysisData?

        init(statistics: OARouteStatistics) {
            analysisData = PlanRouteAnalysisData(uphill: 0,
                                                 downhill: 0,
                                                 altMin: nil,
                                                 altMax: nil,
                                                 avgSpeed: nil,
                                                 maxSpeed: nil,
                                                 timeInMotion: nil,
                                                 hasElevationData: false,
                                                 hasSpeedData: false,
                                                 gpxAnalysis: GpxTrackAnalysis(),
                                                 gpxFile: nil,
                                                 routeStatistics: [statistics])
        }

        func startElevationCalculation(useNearbyRoads: Bool) {}
        func cancelElevationCalculation() {}
        func hideChartHighlight() {}
        func showChartHighlightedLocation(_ points: TrackChartPoints) {}
        func showChartStatisticsLocation(_ points: TrackChartPoints) {}
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

    func testResetPreservesBindingsForSurvivingLegendViews() {
        let synchronizer = RouteChartSynchronizer()
        let chart = makeChart(names: ["asphalt", "sett"])
        let label = UILabel()
        let row = makeLegend("Sett")
        synchronizer.registerBarChart(chart)
        synchronizer.registerLegendLabel(label, propertyName: "asphalt", chart: chart)
        synchronizer.registerLegendItem(row, propertyName: "sett", chart: chart)
        select(0.25, chart: chart, synchronizer: synchronizer)
        XCTAssertTrue(label.accessibilityTraits.contains(.selected))
        synchronizer.reset()
        XCTAssertFalse(label.accessibilityTraits.contains(.selected))
        XCTAssertFalse(row.isSelected)
        synchronizer.registerBarChart(chart)
        select(0.75, chart: chart, synchronizer: synchronizer)
        XCTAssertTrue(row.isSelected)
        XCTAssertFalse(label.accessibilityTraits.contains(.selected))
        select(0.25, chart: chart, synchronizer: synchronizer)
        XCTAssertFalse(row.isSelected)
        XCTAssertTrue(label.accessibilityTraits.contains(.selected))
    }

    func testAnalyzeReloadKeepsVisibleChartInteractiveWithoutWillDisplay() throws {
        let names = ["Reload first", "Reload second"]
        let elements = try names.map { name in
            let segment = try XCTUnwrap(OARouteSegmentAttribute(propertyName: name, color: Int(UInt32(bitPattern: UIColor.iconColorActive.toARGBNumber())), slopeIndex: -1, boundariesClass: []))
            segment.distance = 150
            return segment
        }
        let statistics = try XCTUnwrap(OARouteStatistics(name: "routeInfo_surface", elements: elements, partition: Dictionary(uniqueKeysWithValues: zip(names, elements)), totalDistance: 300))
        let source = AnalyzeDataSource(statistics: statistics)
        let controller = PlanRouteAnalyzeViewController(dataSource: source)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = controller
        window.isHidden = false
        defer { window.isHidden = true }
        controller.view.layoutIfNeeded()
        let table = try XCTUnwrap(controller.view.subviews.first { $0 is UITableView } as? UITableView)
        table.layoutIfNeeded()
        let indexPath = IndexPath(row: 0, section: 1)
        let cell = try XCTUnwrap(table.cellForRow(at: indexPath) as? AnalyzeCardCell)
        let chart = try XCTUnwrap(cell.chartView as? HorizontalBarChartView)
        let labels = descendants(of: cell.cardView).compactMap { $0 as? UILabel }
        let first = try XCTUnwrap(labels.first { $0.text == names[0] })
        let second = try XCTUnwrap(labels.first { $0.text == names[1] })
        let tap = SelectionTapGestureRecognizer()
        let pan = SelectionPanGestureRecognizer()
        chart.addGestureRecognizer(tap)
        chart.addGestureRecognizer(pan)

        for _ in 0..<2 {
            controller.reloadData()
            XCTAssertTrue(table.cellForRow(at: indexPath) === cell)
            XCTAssertTrue(cell.chartView === chart)
            XCTAssertFalse(first.accessibilityTraits.contains(.selected))
            XCTAssertFalse(second.accessibilityTraits.contains(.selected))
            tap.tapLocation = chart.pixelForValues(x: chart.leftAxis.axisMaximum * 0.25, y: 0, axis: .left)
            try tap.sendTap()
            XCTAssertTrue(first.accessibilityTraits.contains(.selected))
            XCTAssertFalse(second.accessibilityTraits.contains(.selected))
            tap.tapLocation = chart.pixelForValues(x: chart.leftAxis.axisMaximum * 0.75, y: 0, axis: .left)
            try tap.sendTap()
            XCTAssertFalse(first.accessibilityTraits.contains(.selected))
            XCTAssertTrue(second.accessibilityTraits.contains(.selected))
            XCTAssertTrue(chart.isFullyZoomedOut)
            pan.panLocation = chart.pixelForValues(x: chart.leftAxis.axisMaximum * 0.25, y: 0, axis: .left)
            try pan.sendPan()
            XCTAssertTrue(first.accessibilityTraits.contains(.selected))
            XCTAssertFalse(second.accessibilityTraits.contains(.selected))
            pan.panLocation = chart.pixelForValues(x: chart.leftAxis.axisMaximum * 0.75, y: 0, axis: .left)
            try pan.sendPan()
            XCTAssertFalse(first.accessibilityTraits.contains(.selected))
            XCTAssertTrue(second.accessibilityTraits.contains(.selected))
        }
    }

    func testLongTrackGapBoundaryUsesSameDistanceInBothChartBuilders() throws {
        let settings = OAAppSettings.sharedManager()
        let previousMetricSystem = settings.metricSystem.get()
        settings.metricSystem.set(.KILOMETERS_AND_METERS)
        defer { settings.metricSystem.set(previousMetricSystem) }
        let analysis = GpxTrackAnalysis()
        analysis.setHasData(tag: GpxUtilities.shared.POINT_ELEVATION, hasData: true)
        XCTAssertTrue(analysis.hasElevationData())
        for _ in 0..<150_000 {
            let point = PointAttributes(distance: 3, timeDiff: 1, firstPoint: false, lastPoint: false)
            point.elevation = 10
            analysis.pointAttributes.add(point)
        }
        let gapEnd = PointAttributes(distance: 25, timeDiff: 1, firstPoint: true, lastPoint: false)
        gapEnd.elevation = 11
        analysis.pointAttributes.add(gapEnd)
        let lastPoint = PointAttributes(distance: 3, timeDiff: 1, firstPoint: false, lastPoint: true)
        lastPoint.elevation = 12
        analysis.pointAttributes.add(lastPoint)
        analysis.totalDistance = 450_028
        let names = ["asphalt", "sett"]
        let elements = try names.enumerated().map { index, name in
            let segment = try XCTUnwrap(OARouteSegmentAttribute(propertyName: name, color: Int(UInt32(bitPattern: UIColor.iconColorActive.toARGBNumber())), slopeIndex: -1, boundariesClass: []))
            segment.distance = index == 0 ? 450_000 : 3
            return segment
        }
        let statistics = try XCTUnwrap(OARouteStatistics(name: "routeInfo_surface", elements: elements, partition: Dictionary(uniqueKeysWithValues: zip(names, elements)), totalDistance: 450_003))
        let primary = ElevationChart(frame: CGRect(x: 0, y: 0, width: 360, height: 120))
        GpxUIHelper.refreshRouteLineChart(chartView: primary, analysis: analysis, firstType: .altitude, secondType: .none, axisType: .distance)
        let dataSet = try XCTUnwrap(primary.lineData?.dataSets.first as? GpxUIHelper.OrderedLineDataSet)
        let initialHeight = try XCTUnwrap(dataSet.entries.first?.y)
        let pointAfterGap = try XCTUnwrap(dataSet.entries.first { $0.y > initialHeight })
        let chart = HorizontalBarChartView(frame: CGRect(x: 0, y: 0, width: 360, height: 120))
        GpxUIHelper.refreshRouteBarChart(chartView: chart, statistics: statistics, analysis: analysis, nightMode: false)
        let entry = try XCTUnwrap(chart.barData?.dataSets.first?.entryForIndex(0) as? BarChartDataEntry)
        let gapRange = try XCTUnwrap(entry.ranges?[1])
        XCTAssertEqual(pointAfterGap.x, gapRange.to, accuracy: 1e-12)
        let synchronizer = RouteChartSynchronizer()
        synchronizer.registerBarChart(chart)
        let sett = makeLegend("Sett")
        synchronizer.registerLegendItem(sett, propertyName: "sett", chart: chart)
        synchronizer.setPrimaryChart(primary)
        synchronizer.syncHighlight(Highlight(x: pointAfterGap.x, y: pointAfterGap.y, dataSetIndex: 0), sourceChart: primary)
        XCTAssertTrue(sett.isSelected)
        let insideGap = (gapRange.from + gapRange.to) / 2
        synchronizer.unregisterPrimaryChart(primary)
        synchronizer.syncHighlight(Highlight(x: insideGap, y: 0, dataSetIndex: 0), sourceChart: chart)
        XCTAssertFalse(sett.isSelected)
    }

    func testCompactLabelUpdatesOnlyWhenSelectedAttributeChanges() {
        let synchronizer = RouteChartSynchronizer()
        let chart = makeChart(names: ["asphalt", "sett"])
        let label = CountingLegendLabel()
        synchronizer.registerBarChart(chart)
        synchronizer.registerLegendLabel(label, propertyName: "asphalt", chart: chart)
        select(0.15, chart: chart, synchronizer: synchronizer)
        let selectedFontUpdates = label.fontUpdates
        let selectedTraitUpdates = label.traitUpdates
        select(0.25, chart: chart, synchronizer: synchronizer)
        select(0.35, chart: chart, synchronizer: synchronizer)
        XCTAssertEqual(label.fontUpdates, selectedFontUpdates)
        XCTAssertEqual(label.traitUpdates, selectedTraitUpdates)
        select(0.75, chart: chart, synchronizer: synchronizer)
        XCTAssertEqual(label.fontUpdates, selectedFontUpdates + 1)
        XCTAssertEqual(label.traitUpdates, selectedTraitUpdates + 1)
        select(0.85, chart: chart, synchronizer: synchronizer)
        XCTAssertEqual(label.fontUpdates, selectedFontUpdates + 1)
        XCTAssertEqual(label.traitUpdates, selectedTraitUpdates + 1)
    }

    func testExpandedHeightAccommodatesSelectedTitlesOnNarrowScreens() throws {
        for count in 1...3 {
            let title = String(repeating: "Unpaved forest road ", count: count)
            let segment = try XCTUnwrap(OARouteSegmentAttribute(propertyName: title, color: Int(UInt32(bitPattern: UIColor.iconColorActive.toARGBNumber())), slopeIndex: -1, boundariesClass: []))
            segment.distance = 300
            let statistics = try XCTUnwrap(OARouteStatistics(name: "routeInfo_steepness", elements: [segment], partition: [title: segment], totalDistance: 300))
            let source = AnalyzeDataSource(statistics: statistics)
            let controller = PlanRouteAnalyzeViewController(dataSource: source)
            controller.loadViewIfNeeded()
            controller.view.frame = CGRect(x: 0, y: 0, width: 320, height: 1000)
            controller.view.layoutIfNeeded()
            let table = try XCTUnwrap(controller.view.subviews.first { $0 is UITableView } as? UITableView)
            let indexPath = IndexPath(row: 0, section: 1)
            controller.tableView(table, didSelectRowAt: indexPath)
            let cachedHeight = controller.tableView(table, heightForRowAt: indexPath)
            let cell = try XCTUnwrap(controller.tableView(table, cellForRowAt: indexPath) as? AnalyzeCardCell)
            cell.frame = CGRect(x: 0, y: 0, width: 320, height: cachedHeight)
            cell.layoutIfNeeded()
            let row = try XCTUnwrap(descendants(of: cell.cardView).first { $0 is OARouteInfoLegendItemView } as? OARouteInfoLegendItemView)
            row.isSelected = true
            let label = try XCTUnwrap(row.value(forKey: "titleView") as? UILabel)
            XCTAssertEqual(label.font.pointSize, UIFont.preferredFont(forTextStyle: .headline).pointSize)
            let requiredHeight = cell.cardView.systemLayoutSizeFitting(
                CGSize(width: 288, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            ).height
            XCTAssertGreaterThanOrEqual(cachedHeight + 0.5, requiredHeight, "\(count) title repetitions")
        }
    }

    private func descendants(of view: UIView) -> [UIView] {
        view.subviews.flatMap { [$0] + descendants(of: $0) }
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
