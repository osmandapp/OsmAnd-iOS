import DGCharts
import UIKit

private final class RouteStatisticsChartRenderer: HorizontalBarChartRenderer {
    private static let highlightLineWidth: CGFloat = 2

    var selectedPositionProvider: (() -> CGFloat?)?

    override func drawHighlighted(context: CGContext, indices: [Highlight]) {
        guard !indices.isEmpty, let selectedPosition = selectedPositionProvider?() else { return }
        let highlightLineWidth = Self.highlightLineWidth
        let drawX = viewPortHandler.contentLeft + selectedPosition * viewPortHandler.contentWidth
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

@objcMembers
final class RouteChartSynchronizer: NSObject {
    private static let maxHighlightDistance: CGFloat = 10_000

    private let barCharts = NSHashTable<HorizontalBarChartView>.weakObjects()
    private weak var primaryChart: ElevationChart?
    private var selectedPosition: CGFloat?
    private var visibleProgressRange: ClosedRange<Double>?
    private var synchronizedCharts: [BarLineChartViewBase] {
        var charts = barCharts.allObjects.map { $0 as BarLineChartViewBase }
        if let primaryChart {
            charts.append(primaryChart)
        }
        return charts
    }

    @objc(setPrimaryChart:) func setPrimaryChart(_ chart: ElevationChart) {
        primaryChart = chart
        applyVisibleProgressRange(to: chart)
        applySelectionToPrimaryChart(callDelegate: false)
        applySelectionToBarCharts()
    }

    @objc(registerBarChart:) func registerBarChart(_ chart: HorizontalBarChartView) {
        if !barCharts.contains(chart) {
            let maxHighlightDistance = Self.maxHighlightDistance
            chart.maxHighlightDistance = maxHighlightDistance
            chart.highlightPerTapEnabled = false
            chart.highlightPerDragEnabled = true
            let renderer = RouteStatisticsChartRenderer(dataProvider: chart,
                                                        animator: chart.chartAnimator,
                                                        viewPortHandler: chart.viewPortHandler)
            renderer.selectedPositionProvider = { [weak self] in
                self?.selectedPosition
            }
            chart.renderer = renderer
            chart.notifyDataSetChanged()
            barCharts.add(chart)
            installSelectionGestureTargets(in: chart)
        }
        applyVisibleProgressRange(to: chart)
        applySelection(to: chart)
    }

    @objc(syncHighlight:sourceChart:) func syncHighlight(_ highlight: Highlight, sourceChart: BarLineChartViewBase) {
        guard let position = relativePosition(atX: highlight.xPx, in: sourceChart) else { return }
        selectedPosition = position
        applySelectionToBarCharts()
    }

    @objc(syncViewPortFromChart:) func syncViewPort(from sourceChart: BarLineChartViewBase) {
        guard let visibleRange = normalizedVisibleRange(in: sourceChart) else { return }
        visibleProgressRange = visibleRange
        synchronizedCharts
            .filter { $0 !== sourceChart }
            .forEach { applyNormalizedVisibleRange(visibleRange, to: $0) }
        applySelectionToBarCharts()
        applySelectionToPrimaryChart(callDelegate: true)
    }

    @objc(clearSynchronizedHighlights) func clearSynchronizedHighlights() {
        selectedPosition = nil
        barCharts.allObjects.forEach { $0.highlightValue(nil) }
    }

    @objc(reset) func reset() {
        selectedPosition = nil
        visibleProgressRange = nil
        primaryChart?.highlightValue(nil)
        primaryChart = nil
        barCharts.allObjects.forEach { chart in
            chart.highlightValue(nil)
            removeSelectionGestureTargets(from: chart)
        }
        barCharts.removeAllObjects()
    }

    private func selectPrimaryChart(atX touchX: CGFloat, sourceChart: BarLineChartViewBase) {
        guard let position = relativePosition(atX: touchX, in: sourceChart) else { return }
        selectedPosition = position
        applySelectionToBarCharts()
        applySelectionToPrimaryChart(callDelegate: true)
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

    private func normalizedVisibleRange(in chart: BarLineChartViewBase) -> ClosedRange<Double>? {
        guard let axisRange = horizontalRange(for: chart) else { return nil }
        let handler = chart.viewPortHandler
        let leftValue = chart.valueForTouchPoint(point: CGPoint(x: handler.contentLeft, y: 0), axis: .left).x
        let rightValue = chart.valueForTouchPoint(point: CGPoint(x: handler.contentRight, y: 0), axis: .left).x
        let lowerBound = normalizedProgress(for: Double(min(leftValue, rightValue)), range: axisRange)
        let upperBound = normalizedProgress(for: Double(max(leftValue, rightValue)), range: axisRange)
        guard lowerBound.isFinite, upperBound.isFinite, upperBound > lowerBound else { return nil }
        return lowerBound...upperBound
    }

    private func applyNormalizedVisibleRange(_ visibleRange: ClosedRange<Double>, to chart: BarLineChartViewBase) {
        guard let axisRange = horizontalRange(for: chart), chart.viewPortHandler.contentWidth > 0 else { return }
        let axisWidth = axisRange.upperBound - axisRange.lowerBound
        let lowerValue = axisRange.lowerBound + visibleRange.lowerBound * axisWidth
        let upperValue = axisRange.lowerBound + visibleRange.upperBound * axisWidth
        let visibleWidth = upperValue - lowerValue
        let scale = max(axisWidth / visibleWidth, 1)
        guard scale.isFinite else { return }

        let handler = chart.viewPortHandler
        handler.refresh(newMatrix: handler.fitScreen(), chart: chart, invalidate: false)
        handler.refresh(newMatrix: handler.zoom(scaleX: scale, scaleY: 1), chart: chart, invalidate: false)
        let startPoint = chart.pixelForValues(x: lowerValue, y: 0, axis: .left)
        let translation = handler.contentLeft - startPoint.x
        let matrix = handler.touchMatrix.concatenating(CGAffineTransform(translationX: translation, y: 0))
        handler.refresh(newMatrix: matrix, chart: chart, invalidate: true)
    }

    private func applyVisibleProgressRange(to chart: BarLineChartViewBase) {
        guard let visibleProgressRange else { return }
        applyNormalizedVisibleRange(visibleProgressRange, to: chart)
    }

    private func applySelectionToPrimaryChart(callDelegate: Bool) {
        guard let primaryChart,
              let touchX = touchX(in: primaryChart),
              let highlight = primaryChart.getHighlightByTouchPoint(CGPoint(x: touchX, y: 0)) else {
            return
        }
        primaryChart.lastHighlighted = highlight
        primaryChart.highlightValue(highlight, callDelegate: callDelegate)
    }

    private func applySelectionToBarCharts() {
        guard selectedPosition != nil else { return }
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

    private func relativePosition(atX touchX: CGFloat, in chart: BarLineChartViewBase) -> CGFloat? {
        let handler = chart.viewPortHandler
        guard touchX.isFinite, handler.contentWidth > 0 else { return nil }
        let position = (touchX - handler.contentLeft) / handler.contentWidth
        return min(max(position, 0), 1)
    }

    private func touchX(in chart: BarLineChartViewBase) -> CGFloat? {
        guard let selectedPosition else { return nil }
        let handler = chart.viewPortHandler
        guard handler.contentWidth > 0 else { return nil }
        return handler.contentLeft + selectedPosition * handler.contentWidth
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
