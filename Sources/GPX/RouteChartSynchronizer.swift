import DGCharts
import UIKit

private final class RouteStatisticsChartRenderer: HorizontalBarChartRenderer {
    private static let highlightLineWidth: CGFloat = 2

    override func drawHighlighted(context: CGContext, indices: [Highlight]) {
        let highlightLineWidth = Self.highlightLineWidth
        context.saveGState()
        context.setStrokeColor(UIColor.chartSliderLine.cgColor)
        context.setLineWidth(highlightLineWidth)

        for highlight in indices where viewPortHandler.isInBoundsX(highlight.drawX) {
            context.move(to: CGPoint(x: highlight.drawX, y: viewPortHandler.contentTop))
            context.addLine(to: CGPoint(x: highlight.drawX, y: viewPortHandler.contentBottom))
            context.strokePath()
        }

        context.restoreGState()
    }
}

@objcMembers
final class RouteChartSynchronizer: NSObject {
    private static let maxHighlightDistance: CGFloat = 10_000

    private let barCharts = NSHashTable<HorizontalBarChartView>.weakObjects()
    private weak var primaryChart: ElevationChart?
    private var selectedProgress: Double?
    private var synchronizedCharts: [BarLineChartViewBase] {
        var charts = barCharts.allObjects.map { $0 as BarLineChartViewBase }
        if let primaryChart {
            charts.append(primaryChart)
        }
        return charts
    }

    @objc(setPrimaryChart:) func setPrimaryChart(_ chart: ElevationChart) {
        primaryChart = chart
        barCharts.allObjects.forEach { barChart in
            updateAxisRange(barChart)
            barChart.notifyDataSetChanged()
        }
        applySelectionToPrimaryChart(callDelegate: false)
        applySelectionToBarCharts()
    }

    @objc(registerBarChart:) func registerBarChart(_ chart: HorizontalBarChartView) {
        let maxHighlightDistance = Self.maxHighlightDistance
        chart.maxHighlightDistance = maxHighlightDistance
        chart.highlightPerTapEnabled = false
        chart.highlightPerDragEnabled = false
        chart.renderer = RouteStatisticsChartRenderer(dataProvider: chart, animator: chart.chartAnimator, viewPortHandler: chart.viewPortHandler)
        updateAxisRange(chart)
        chart.notifyDataSetChanged()
        barCharts.add(chart)
        applySelection(to: chart)
    }

    @objc(selectPrimaryChartAtX:sourceChart:callDelegate:) func selectPrimaryChart(atX touchX: CGFloat,
                                                                                   sourceChart: BarLineChartViewBase,
                                                                                   callDelegate: Bool) {
        guard let progress = progress(atX: touchX, in: sourceChart) else { return }
        selectedProgress = progress
        applySelectionToBarCharts()
        applySelectionToPrimaryChart(callDelegate: callDelegate)
    }

    @objc(syncHighlight:sourceChart:) func syncHighlight(_ highlight: Highlight, sourceChart: BarLineChartViewBase) {
        guard let progress = progress(for: highlight, in: sourceChart) else { return }
        selectedProgress = progress
        applySelectionToBarCharts()
    }

    @objc(syncViewPortFromChart:) func syncViewPort(from sourceChart: BarLineChartViewBase) {
        guard let visibleRange = visibleRange(in: sourceChart) else { return }
        synchronizedCharts
            .filter { $0 !== sourceChart }
            .forEach { applyVisibleRange(visibleRange, to: $0) }
        applySelectionToBarCharts()
        applySelectionToPrimaryChart(callDelegate: true)
    }

    @objc(clearSynchronizedHighlights) func clearSynchronizedHighlights() {
        selectedProgress = nil
        barCharts.allObjects.forEach { $0.highlightValue(nil) }
    }

    @objc(reset) func reset() {
        selectedProgress = nil
        primaryChart?.highlightValue(nil)
        primaryChart = nil
        barCharts.allObjects.forEach { $0.highlightValue(nil) }
        barCharts.removeAllObjects()
    }

    private func updateAxisRange(_ chart: HorizontalBarChartView) {
        guard let primaryChart else { return }
        chart.leftAxis.axisMinimum = primaryChart.chartXMin
        chart.leftAxis.axisMaximum = primaryChart.chartXMax
        chart.rightAxis.axisMinimum = primaryChart.chartXMin
        chart.rightAxis.axisMaximum = primaryChart.chartXMax
    }

    private func visibleRange(in chart: BarLineChartViewBase) -> ClosedRange<Double>? {
        let handler = chart.viewPortHandler
        let left = chart.valueForTouchPoint(point: CGPoint(x: handler.contentLeft, y: 1), axis: .left).x
        let right = chart.valueForTouchPoint(point: CGPoint(x: handler.contentRight, y: 1), axis: .left).x
        let lowerBound = Double(min(left, right))
        let upperBound = Double(max(left, right))
        guard lowerBound.isFinite, upperBound.isFinite, upperBound > lowerBound else { return nil }
        return lowerBound...upperBound
    }

    private func applyVisibleRange(_ visibleRange: ClosedRange<Double>, to chart: BarLineChartViewBase) {
        guard let axisRange = horizontalRange(for: chart), chart.viewPortHandler.contentWidth > 0 else { return }
        let visibleWidth = visibleRange.upperBound - visibleRange.lowerBound
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

    private func applySelectionToPrimaryChart(callDelegate: Bool) {
        guard let primaryChart,
              let selectedProgress,
              let touchX = touchX(for: selectedProgress, in: primaryChart),
              let highlight = primaryChart.getHighlightByTouchPoint(CGPoint(x: touchX, y: 0)) else {
            return
        }
        primaryChart.lastHighlighted = highlight
        primaryChart.highlightValue(highlight, callDelegate: callDelegate)
    }

    private func applySelectionToBarCharts() {
        guard selectedProgress != nil else { return }
        barCharts.allObjects.forEach { applySelection(to: $0) }
    }

    private func applySelection(to chart: HorizontalBarChartView) {
        guard let selectedProgress,
              let touchX = touchX(for: selectedProgress, in: chart),
              let highlight = chart.highlighter?.getHighlight(x: 1, y: touchX) else {
            return
        }
        highlight.setDraw(x: touchX, y: 0)
        chart.lastHighlighted = highlight
        chart.highlightValue(highlight)
    }

    private func progress(for highlight: Highlight, in chart: BarLineChartViewBase) -> Double? {
        guard let range = horizontalRange(for: chart) else { return nil }
        return normalizedProgress(for: highlight.x, range: range)
    }

    private func progress(atX touchX: CGFloat, in chart: BarLineChartViewBase) -> Double? {
        guard let range = horizontalRange(for: chart) else { return nil }
        let point = chart.valueForTouchPoint(point: CGPoint(x: touchX, y: 0), axis: .left)
        return normalizedProgress(for: Double(point.x), range: range)
    }

    private func touchX(for progress: Double, in chart: BarLineChartViewBase) -> CGFloat? {
        guard let range = horizontalRange(for: chart) else { return nil }
        let value = range.lowerBound + progress * (range.upperBound - range.lowerBound)
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
}
