//
//  ElevationChart.swift
//  OsmAnd Maps
//
//  Created by Skalii on 23.08.2024.
//

import Foundation

final public class ElevationChart: LineChartView {

    private var showLastSet = true

    internal override func initialize() {
        super.initialize()

        xAxisRenderer = ElevationXAxisRenderer(self,
                                               viewPortHandler: viewPortHandler,
                                               xAxis: xAxis,
                                               trans: getTransformer(forAxis: .right))
        rightYAxisRenderer = ElevationYAxisRenderer(self,
                                                    viewPortHandler: viewPortHandler,
                                                    yAxis: rightAxis,
                                                    trans: _rightAxisTransformer)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        updateDimens(width: frame.width, height: frame.height)
    }

    public override func notifyDataSetChanged() {
        super.notifyDataSetChanged()

        updateDimens()
    }

    override func autoScale() {
        if let data {
            data.calcMinMaxY(fromX: lowestVisibleX, toX: highestVisibleX)
            xAxis.calculate(min: data.xMin, max: data.xMax)
            leftAxis.calculate(min: data.getYMin(axis: .left), max: data.getYMax(axis: .left))
            rightAxis.calculate(min: data.getYMin(axis: .right), max: data.getYMax(axis: .right))
        }
        calculateOffsets()
    }

    public override func draw(_ layer: CALayer, in ctx: CGContext) {
        guard data != nil else { return }

        if autoScaleMinMaxEnabled {
            prepareValuePxMatrix()
            autoScale()
        }

        if rightAxis.isEnabled {
            rightYAxisRenderer.computeAxis(min: rightAxis.axisMinimum,
                                           max: rightAxis.axisMaximum,
                                           inverted: rightAxis.isInverted)
        }

        leftYAxisRenderer.computeAxis(min: leftAxis.axisMinimum,
                                      max: leftAxis.axisMaximum,
                                      inverted: leftAxis.isInverted)
        if xAxis.isEnabled {
            xAxisRenderer.computeAxis(min: xAxis.axisMinimum, max: xAxis.axisMaximum, inverted: false)
        }

        ctx.saveGState()
        if clipDataToContentEnabled {
            ctx.clip(to: viewPortHandler.contentRect)
        }

        renderer?.drawData(context: ctx)
        if valuesToHighlight() {
            renderer?.drawHighlighted(context: ctx, indices: highlighted)
        }

        ctx.restoreGState()
        renderer?.drawExtras(context: ctx)
        if xAxis.isEnabled, !xAxis.isDrawLimitLinesBehindDataEnabled {
            xAxisRenderer.renderLimitLines(context: ctx)
        }

        xAxisRenderer.renderAxisLabels(context: ctx)
        rightYAxisRenderer.renderAxisLabels(context: ctx)
        if clipValuesToContentEnabled {
            ctx.saveGState()
            ctx.clip(to: viewPortHandler.contentRect)
            renderer?.drawValues(context: ctx)
            ctx.restoreGState()
        } else {
            renderer?.drawValues(context: ctx)
        }

        xAxisRenderer.renderGridLines(context: ctx)
        xAxisRenderer.renderAxisLine(context: ctx)
        rightYAxisRenderer.renderGridLines(context: ctx)
        legendRenderer.renderLegend(context: ctx)
        drawDescription(in: ctx)
        drawMarkers(context: ctx)
    }

    func shouldShowLastSet() -> Bool {
        showLastSet
    }

    func updateDimens() {
        updateDimens(width: frame.width, height: frame.height)
    }

    func updateDimens(width: CGFloat, height: CGFloat) {
        guard data != nil else { return }

        let measureText = getMeasuredMaxLabel()
        let adjustedWidth = width - CGFloat(measureText) - CGFloat(6.0 * UIScreen.main.scale)
        viewPortHandler.setChartDimens(width: adjustedWidth, height: height)

        for job in _viewportJobs {
            job.doJob()
        }
        clearAllViewportJobs()
    }

    internal func getMeasuredMaxLabel() -> Float {
        let from = rightAxis.drawBottomYLabelEntryEnabled ? 0 : 1
        let to = rightAxis.drawTopYLabelEntryEnabled ? rightAxis.entryCount : rightAxis.entryCount - 1
        let chartData = lineData
        var dataSetCount = chartData?.dataSetCount ?? 0
        let lastDataSet = dataSetCount > 0 ? chartData?.dataSet(at: dataSetCount - 1) : nil
        if lastDataSet != nil, !shouldShowLastSet() {
            dataSetCount -= 1
        }

        let font = rightYAxisRenderer.axis.labelFont
        var maxMeasuredWidth: Float = 0.0

        for i in from..<to {
            var measuredLabelWidth: Float = 0.0
            var leftText: String
            if dataSetCount == 1 {
                leftText = leftAxis.getFormattedLabel(i)
                if let dSet = lastDataSet as? IOrderedLineDataSet {
                    leftText = dSet.isLeftAxis() ? leftText : rightAxis.getFormattedLabel(i)
                }
                measuredLabelWidth = Float(leftText.size(withAttributes: [.font: font]).width)
            } else {
                leftText = leftAxis.getFormattedLabel(i) + ", "
                let rightText = rightAxis.getFormattedLabel(i)
                let leftTextWidth = leftText.size(withAttributes: [.font: font]).width
                let rightTextWidth = rightText.size(withAttributes: [.font: font]).width
                measuredLabelWidth = Float(leftTextWidth + rightTextWidth)
            }

            if measuredLabelWidth > maxMeasuredWidth {
                maxMeasuredWidth = measuredLabelWidth
            }
        }

        return maxMeasuredWidth
    }

    public func setupGPXChart(markerView: MarkerView,
                              topOffset: CGFloat,
                              bottomOffset: CGFloat,
                              xAxisGridColor: UIColor,
                              labelsColor: UIColor,
                              yAxisGridColor: UIColor,
                              useGesturesAndScale: Bool) {
        clear()
        fitScreen()
        layer.drawsAsynchronously = true
        isUserInteractionEnabled = useGesturesAndScale

        extraRightOffset = 16.0
        extraLeftOffset = 16.0
        extraTopOffset = topOffset
        extraBottomOffset = bottomOffset
        dragEnabled = useGesturesAndScale
        setScaleEnabled(useGesturesAndScale)
        pinchZoomEnabled = useGesturesAndScale
        scaleYEnabled = false
        autoScaleMinMaxEnabled = true
        drawBordersEnabled = false
        chartDescription.enabled = false
        maxVisibleCount = 10
        minOffset = 0.0
        dragDecelerationEnabled = false
        markerView.chartView = self
        marker = markerView
        drawMarkers = true

        xAxis.yOffset = 5.0
        xAxis.drawAxisLineEnabled = true
        xAxis.axisLineWidth = 1.0
        xAxis.axisLineColor = xAxisGridColor
        xAxis.drawGridLinesEnabled = true
        xAxis.gridLineWidth = 1.0
        xAxis.gridColor = xAxisGridColor
        xAxis.gridLineDashLengths = [8.0]
        xAxis.gridLineDashPhase = 0.0
        xAxis.labelPosition = .bottom
        xAxis.labelTextColor = labelsColor
        xAxis.avoidFirstLastClippingEnabled = true

        leftAxis.setLabelCount(3, force: true)
        leftAxis.enabled = false
        leftAxis.drawLabelsEnabled = false
        leftAxis.drawGridLinesEnabled = false

        rightAxis.gridLineDashLengths = [4.0, 4.0]
        rightAxis.gridLineDashPhase = 0.0
        rightAxis.gridColor = yAxisGridColor
        rightAxis.gridLineWidth = 1.0
        rightAxis.drawBottomYLabelEntryEnabled = false
        rightAxis.drawAxisLineEnabled = false
        rightAxis.labelPosition = .insideChart
        rightAxis.xOffset = -1.0
        rightAxis.yOffset = 10.25
        rightAxis.labelFont = UIFont.systemFont(ofSize: 11)
        rightAxis.setLabelCount(3, force: true)

        legend.enabled = false
    }
}
