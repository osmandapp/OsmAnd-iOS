import DGCharts
import UIKit

private final class RouteStatisticsChartRenderer: HorizontalBarChartRenderer {
    private static let highlightLineWidth: CGFloat = 2

    var selectedTouchXProvider: (() -> CGFloat?)?

    override func drawHighlighted(context: CGContext, indices: [Highlight]) {
        guard !indices.isEmpty, let drawX = selectedTouchXProvider?() else { return }
        let highlightLineWidth = Self.highlightLineWidth
        guard viewPortHandler.isInBoundsX(drawX) else { return }

        context.saveGState()
        context.setStrokeColor(UIColor.chartSliderLine.cgColor)
        context.setLineWidth(highlightLineWidth)
        context.move(to: CGPoint(x: drawX, y: viewPortHandler.contentTop))
        context.addLine(to: CGPoint(x: drawX, y: viewPortHandler.contentBottom))
        context.strokePath()
        context.restoreGState()
    }
}

private final class RouteStatisticsYAxisRenderer: YAxisRendererHorizontalBarChart {
    private static let tickHalfLength: CGFloat = 3.5

    override func drawYLabels(context: CGContext,
                              fixedPosition: CGFloat,
                              positions: [CGPoint],
                              offset: CGFloat) {
        super.drawYLabels(context: context,
                          fixedPosition: fixedPosition,
                          positions: positions,
                          offset: offset)

        guard axis.drawAxisLineEnabled else { return }
        let tickHalfLength = Self.tickHalfLength
        context.saveGState()
        context.setStrokeColor(axis.axisLineColor.cgColor)
        context.setLineWidth(axis.axisLineWidth)
        context.beginPath()
        for position in positions where viewPortHandler.isInBoundsX(position.x) {
            context.move(to: CGPoint(x: position.x, y: viewPortHandler.contentBottom - tickHalfLength))
            context.addLine(to: CGPoint(x: position.x, y: viewPortHandler.contentBottom + tickHalfLength))
        }
        context.strokePath()
        context.restoreGState()
    }
}

@objcMembers
final class RouteChartSynchronizer: NSObject {
    private static let maxHighlightDistance: CGFloat = 10_000

    private let barCharts = NSHashTable<HorizontalBarChartView>.weakObjects()
    private weak var primaryChart: ElevationChart?
    private var primaryXAxisType: GPXDataSetAxisType?
    private var selectedProgress: Double?
    private var selectedXAxisValue: Double?
    private var visibleProgressRange: ClosedRange<Double>?
    private var visibleXAxisRange: ClosedRange<Double>?
    private var synchronizedCharts: [BarLineChartViewBase] {
        var charts = barCharts.allObjects.map { $0 as BarLineChartViewBase }
        if let primaryChart {
            charts.append(primaryChart)
        }
        return charts
    }

    private var usesDistanceXAxis: Bool {
        primaryXAxisType == .distance
    }

    func setPrimaryChart(_ chart: ElevationChart) {
        let xAxisType = (chart.lineData?.dataSets.first as? GpxUIHelper.OrderedLineDataSet)?.getDataSetAxisType()
        if primaryXAxisType != nil, primaryXAxisType != xAxisType {
            selectedXAxisValue = nil
            visibleXAxisRange = nil
        }
        primaryXAxisType = xAxisType
        primaryChart = chart
        chart.lineData?.dataSets
            .compactMap { $0 as? LineChartDataSetProtocol }
            .forEach { $0.highlightColor = .chartSliderLine }
        chart.notifyDataSetChanged()
        if primaryXAxisType != nil {
            barCharts.allObjects.forEach {
                updateHorizontalAxis(of: $0)
                $0.notifyDataSetChanged()
            }
        }
        applyStoredVisibleRange(to: chart)
        applySelectionToPrimaryChart(callDelegate: false)
        applySelectionToBarCharts()
    }

    func registerBarChart(_ chart: HorizontalBarChartView) {
        if !barCharts.contains(chart) {
            let maxHighlightDistance = Self.maxHighlightDistance
            chart.maxHighlightDistance = maxHighlightDistance
            chart.highlightPerTapEnabled = false
            chart.highlightPerDragEnabled = true
            chart.rightYAxisRenderer = RouteStatisticsYAxisRenderer(viewPortHandler: chart.viewPortHandler,
                                                                    axis: chart.rightAxis,
                                                                    transformer: chart.getTransformer(forAxis: .right))
            let renderer = RouteStatisticsChartRenderer(dataProvider: chart,
                                                        animator: chart.chartAnimator,
                                                        viewPortHandler: chart.viewPortHandler)
            renderer.selectedTouchXProvider = { [weak self, weak chart] in
                guard let self, let chart else { return nil }
                return touchX(in: chart)
            }
            chart.renderer = renderer
            barCharts.add(chart)
            installSelectionGestureTargets(in: chart)
        }
        updateHorizontalAxis(of: chart)
        chart.notifyDataSetChanged()
        applyStoredVisibleRange(to: chart)
        applySelection(to: chart)
    }

    func unregisterBarChart(_ chart: HorizontalBarChartView) {
        removeSelectionGestureTargets(from: chart)
        barCharts.remove(chart)
    }

    func syncHighlight(_ highlight: Highlight, sourceChart: BarLineChartViewBase) {
        guard updateSelection(atValue: highlight.x, in: sourceChart) else { return }
        applySelectionToBarCharts()
    }

    @objc(syncViewPortFromChart:) func syncViewPort(from sourceChart: BarLineChartViewBase) {
        let targetCharts = synchronizedCharts.filter { $0 !== sourceChart }
        if usesDistanceXAxis {
            guard let visibleRange = visibleRange(in: sourceChart) else { return }
            visibleXAxisRange = visibleRange
            visibleProgressRange = normalizedVisibleRange(in: sourceChart)
            targetCharts.forEach { applyVisibleRange(visibleRange, to: $0) }
        } else {
            guard let visibleRange = normalizedVisibleRange(in: sourceChart) else { return }
            visibleXAxisRange = nil
            visibleProgressRange = visibleRange
            targetCharts.forEach { applyNormalizedVisibleRange(visibleRange, to: $0) }
        }
        applySelectionToPrimaryChart(callDelegate: true)
        applySelectionToBarCharts()
    }

    func clearSynchronizedHighlights() {
        selectedProgress = nil
        selectedXAxisValue = nil
        if let primaryChart {
            clearHighlight(in: primaryChart)
        }
        barCharts.allObjects.forEach { clearHighlight(in: $0) }
    }

    func reset() {
        selectedProgress = nil
        selectedXAxisValue = nil
        visibleProgressRange = nil
        visibleXAxisRange = nil
        if let primaryChart {
            clearHighlight(in: primaryChart)
        }
        primaryChart = nil
        primaryXAxisType = nil
        barCharts.allObjects.forEach { chart in
            clearHighlight(in: chart)
            removeSelectionGestureTargets(from: chart)
        }
        barCharts.removeAllObjects()
    }

    private func selectPrimaryChart(atX touchX: CGFloat, sourceChart: BarLineChartViewBase) {
        guard updateSelection(atX: touchX, in: sourceChart) else { return }
        applySelectionToPrimaryChart(callDelegate: true)
    }

    private func clearHighlight(in chart: ChartViewBase) {
        chart.lastHighlighted = nil
        chart.highlightValue(nil)
    }

    private func installSelectionGestureTargets(in chart: HorizontalBarChartView) {
        chart.gestureRecognizers?.forEach { recognizer in
            if let tapRecognizer = recognizer as? UITapGestureRecognizer,
               tapRecognizer.numberOfTapsRequired == 1 {
                tapRecognizer.removeTarget(self, action: #selector(onBarChartTap(_:)))
                tapRecognizer.addTarget(self, action: #selector(onBarChartTap(_:)))
            } else if let panRecognizer = recognizer as? UIPanGestureRecognizer {
                panRecognizer.removeTarget(self, action: #selector(onBarChartPan(_:)))
                panRecognizer.addTarget(self, action: #selector(onBarChartPan(_:)))
            }
        }
    }

    private func removeSelectionGestureTargets(from chart: HorizontalBarChartView) {
        chart.gestureRecognizers?.forEach { recognizer in
            recognizer.removeTarget(self, action: #selector(onBarChartTap(_:)))
            recognizer.removeTarget(self, action: #selector(onBarChartPan(_:)))
        }
    }

    private func updateHorizontalAxis(of chart: HorizontalBarChartView) {
        guard primaryXAxisType != nil else { return }
        if usesDistanceXAxis,
           let primaryChart,
           let primaryRange = horizontalRange(for: primaryChart) {
            setHorizontalAxisRange(primaryRange, of: chart)
        } else if let dataRange = horizontalDataRange(for: chart) {
            setHorizontalAxisRange(dataRange, of: chart)
        } else {
            chart.leftAxis.resetCustomAxisMin()
            chart.leftAxis.resetCustomAxisMax()
            chart.rightAxis.resetCustomAxisMin()
            chart.rightAxis.resetCustomAxisMax()
        }
    }

    private func setHorizontalAxisRange(_ range: ClosedRange<Double>, of chart: HorizontalBarChartView) {
        chart.leftAxis.axisMinimum = range.lowerBound
        chart.leftAxis.axisMaximum = range.upperBound
        chart.rightAxis.axisMinimum = range.lowerBound
        chart.rightAxis.axisMaximum = range.upperBound
    }

    private func horizontalDataRange(for chart: HorizontalBarChartView) -> ClosedRange<Double>? {
        guard let dataSet = chart.barData?.dataSets.first,
              let entry = dataSet.entryForIndex(0) as? BarChartDataEntry else { return nil }
        let upperBound = entry.positiveSum
        guard upperBound.isFinite, upperBound > 0 else { return nil }
        return 0...upperBound
    }

    private func normalizedVisibleRange(in chart: BarLineChartViewBase) -> ClosedRange<Double>? {
        guard let axisRange = horizontalRange(for: chart) else { return nil }
        guard let visibleRange = visibleRange(in: chart) else { return nil }
        let lowerBound = normalizedProgress(for: visibleRange.lowerBound, range: axisRange)
        let upperBound = normalizedProgress(for: visibleRange.upperBound, range: axisRange)
        guard lowerBound.isFinite, upperBound.isFinite, upperBound > lowerBound else { return nil }
        return lowerBound...upperBound
    }

    private func applyNormalizedVisibleRange(_ visibleRange: ClosedRange<Double>, to chart: BarLineChartViewBase) {
        guard let axisRange = horizontalRange(for: chart) else { return }
        let axisWidth = axisRange.upperBound - axisRange.lowerBound
        let lowerValue = axisRange.lowerBound + visibleRange.lowerBound * axisWidth
        let upperValue = axisRange.lowerBound + visibleRange.upperBound * axisWidth
        applyVisibleRange(lowerValue...upperValue, to: chart)
    }

    private func applyVisibleRange(_ visibleRange: ClosedRange<Double>, to chart: BarLineChartViewBase) {
        guard let axisRange = horizontalRange(for: chart), chart.viewPortHandler.contentWidth > 0 else { return }
        let visibleWidth = visibleRange.upperBound - visibleRange.lowerBound
        guard visibleWidth > 0 else { return }
        let scale = max((axisRange.upperBound - axisRange.lowerBound) / visibleWidth, 1)
        guard scale.isFinite else { return }

        let handler = chart.viewPortHandler
        handler.refresh(newMatrix: handler.fitScreen(), chart: chart, invalidate: false)
        handler.refresh(newMatrix: handler.zoom(scaleX: scale, scaleY: 1), chart: chart, invalidate: false)
        let startPoint = chart.pixelForValues(x: visibleRange.lowerBound, y: 0, axis: .left)
        let translation = handler.contentLeft - startPoint.x
        let matrix = handler.touchMatrix.concatenating(CGAffineTransform(translationX: translation, y: 0))
        handler.refresh(newMatrix: matrix, chart: chart, invalidate: true)
    }

    private func applyStoredVisibleRange(to chart: BarLineChartViewBase) {
        if usesDistanceXAxis, let visibleXAxisRange {
            applyVisibleRange(visibleXAxisRange, to: chart)
        } else if let visibleProgressRange {
            applyNormalizedVisibleRange(visibleProgressRange, to: chart)
        }
    }

    private func applySelectionToPrimaryChart(callDelegate: Bool) {
        guard let primaryChart,
              let touchX = touchX(in: primaryChart),
              let highlight = primaryChart.getHighlightByTouchPoint(CGPoint(x: touchX, y: 0)) else {
            return
        }
        guard updateSelection(atValue: highlight.x, in: primaryChart) else { return }
        primaryChart.lastHighlighted = highlight
        primaryChart.highlightValue(highlight, callDelegate: callDelegate)
    }

    private func applySelectionToBarCharts() {
        guard selectedProgress != nil else { return }
        barCharts.allObjects.forEach { applySelection(to: $0) }
    }

    private func applySelection(to chart: HorizontalBarChartView) {
        guard let touchX = touchX(in: chart),
              let highlight = chart.highlighter?.getHighlight(x: 1, y: touchX) else {
            return
        }
        highlight.setDraw(x: touchX, y: 0)
        chart.lastHighlighted = highlight
        chart.highlightValue(highlight)
    }

    private func updateSelection(atX touchX: CGFloat, in chart: BarLineChartViewBase) -> Bool {
        let value = Double(chart.valueForTouchPoint(point: CGPoint(x: touchX, y: 0), axis: .left).x)
        return updateSelection(atValue: value, in: chart)
    }

    private func updateSelection(atValue value: Double, in chart: BarLineChartViewBase) -> Bool {
        guard value.isFinite,
              let axisRange = horizontalRange(for: chart) else { return false }
        selectedProgress = normalizedProgress(for: value, range: axisRange)
        selectedXAxisValue = usesDistanceXAxis ? value : nil
        return true
    }

    private func visibleRange(in chart: BarLineChartViewBase) -> ClosedRange<Double>? {
        let lowerBound: Double
        let upperBound: Double
        if chart is HorizontalBarChartView {
            let handler = chart.viewPortHandler
            let leftValue = chart.valueForTouchPoint(point: CGPoint(x: handler.contentLeft, y: 0), axis: .left).x
            let rightValue = chart.valueForTouchPoint(point: CGPoint(x: handler.contentRight, y: 0), axis: .left).x
            lowerBound = Double(min(leftValue, rightValue))
            upperBound = Double(max(leftValue, rightValue))
        } else {
            lowerBound = chart.lowestVisibleX
            upperBound = chart.highestVisibleX
        }
        guard lowerBound.isFinite, upperBound.isFinite, upperBound > lowerBound else { return nil }
        return lowerBound...upperBound
    }

    private func touchX(in chart: BarLineChartViewBase) -> CGFloat? {
        if usesDistanceXAxis, let selectedXAxisValue {
            let touchX = chart.pixelForValues(x: selectedXAxisValue, y: 0, axis: .left).x
            return touchX.isFinite ? touchX : nil
        }
        guard let selectedProgress,
              let axisRange = horizontalRange(for: chart) else { return nil }
        let value = axisRange.lowerBound + selectedProgress * (axisRange.upperBound - axisRange.lowerBound)
        let touchX = chart.pixelForValues(x: value, y: 0, axis: .left).x
        return touchX.isFinite ? touchX : nil
    }

    private func horizontalRange(for chart: BarLineChartViewBase) -> ClosedRange<Double>? {
        let lowerBound: Double
        let upperBound: Double
        if let barChart = chart as? HorizontalBarChartView {
            lowerBound = barChart.leftAxis.axisMinimum
            upperBound = barChart.leftAxis.axisMaximum
        } else {
            lowerBound = chart.chartXMin
            upperBound = chart.chartXMax
        }
        guard lowerBound.isFinite, upperBound.isFinite, upperBound > lowerBound else { return nil }
        return lowerBound...upperBound
    }

    private func normalizedProgress(for value: Double, range: ClosedRange<Double>) -> Double {
        let progress = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return min(max(progress, 0), 1)
    }

    @objc private func onBarChartTap(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended,
              let chart = recognizer.view as? HorizontalBarChartView else { return }
        selectPrimaryChart(atX: recognizer.location(in: chart).x, sourceChart: chart)
    }

    @objc private func onBarChartPan(_ recognizer: UIPanGestureRecognizer) {
        guard recognizer.state == .changed,
              let chart = recognizer.view as? HorizontalBarChartView,
              chart.isFullyZoomedOut else { return }
        selectPrimaryChart(atX: recognizer.location(in: chart).x, sourceChart: chart)
    }
}
