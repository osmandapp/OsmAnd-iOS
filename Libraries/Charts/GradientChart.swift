//
//  GradientChart.swift
//  DGCharts
//
//  Created by Skalii on 18.10.2024.
//

import Foundation

final public class GradientChart: LineChartView {

    internal override func initialize() {
        super.initialize()

        xAxisRenderer = GradientXAxisRenderer(self,
                                              viewPortHandler: viewPortHandler,
                                              xAxis: xAxis,
                                              trans: getTransformer(forAxis: .right))
    }

    public override func notifyDataSetChanged() {
        super.notifyDataSetChanged()

        guard let data, let dataColors = data.dataSet(at: 0)?.colors else { return }

        let step = 1.0 / CGFloat(dataColors.count - 1)
        var colorLocations = [CGFloat]()
        for i in 0..<dataColors.count {
            colorLocations.append(CGFloat(i) * step)
        }

        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                        colors: dataColors.map({ $0.cgColor }) as CFArray,
                                        locations: colorLocations) else {
            return
        }

        if let lineDataSet = data.dataSet(at: 0) as? LineChartDataSet {
            lineDataSet.fill = LinearGradientFill(gradient: gradient)
        }
    }

    override func calculateOffsets() {
        if !_customViewPortEnabled {
            var offsetLeft = CGFloat(0.0)
            var offsetRight = CGFloat(0.0)
            var offsetTop = CGFloat(0.0)
            var offsetBottom = CGFloat(0.0)

            calculateLegendOffsets(offsetLeft: &offsetLeft,
                                   offsetTop: &offsetTop,
                                   offsetRight: &offsetRight,
                                   offsetBottom: &offsetBottom)

            offsetTop += self.extraTopOffset
            offsetRight += self.extraRightOffset
            offsetBottom += self.extraBottomOffset
            offsetLeft += self.extraLeftOffset

            viewPortHandler.restrainViewPort(
                offsetLeft: max(self.minOffset, offsetLeft),
                offsetTop: max(self.minOffset, offsetTop),
                offsetRight: max(self.minOffset, offsetRight),
                offsetBottom: max(self.minOffset, offsetBottom))
        }
        
        prepareOffsetMatrix()
        prepareValuePxMatrix()
    }

    public override func draw(_ layer: CALayer, in ctx: CGContext) {
        guard let data else { return }

        if autoScaleMinMaxEnabled {
            autoScale()
        }

        xAxis.enabled = true
        if xAxis.isEnabled {
            xAxisRenderer.computeAxis(min: xAxis.axisMinimum,
                                      max: xAxis.axisMaximum,
                                      inverted: false)
        }

        ctx.saveGState()
        if clipDataToContentEnabled {
            ctx.clip(to: viewPortHandler.contentRect)
        }

        if let lineDataSet = data.dataSet(at: 0) as? LineChartDataSet,
           let fill = lineDataSet.fill as? LinearGradientFill {
            ctx.drawLinearGradient(fill.gradient,
                                   start: CGPoint(x: viewPortHandler.contentRect.minX, y: viewPortHandler.contentRect.minY),
                                   end: CGPoint(x: viewPortHandler.contentRect.maxX, y: viewPortHandler.contentRect.minY),
                                   options: [])
        }

        ctx.restoreGState()
        xAxisRenderer.renderAxisLabels(context: ctx)
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
    }
}
