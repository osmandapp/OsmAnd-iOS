//
//  ElevationXAxisRenderer.swift
//  OsmAnd Maps
//
//  Created by Skalii on 25.08.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation
import Charts

final class ElevationXAxisRenderer: XAxisRenderer {

    private let chartView: LineChartView

    init(_ chartView: LineChartView, viewPortHandler: ViewPortHandler, xAxis: XAxis, trans: Transformer) {
        super.init(viewPortHandler: viewPortHandler, xAxis: xAxis, transformer: trans)
        self.chartView = chartView
    }

    override var gridClippingRect: CGRect {
        var rect = CGRect(x: viewPortHandler.contentLeft, y: viewPortHandler.contentTop, width: viewPortHandler.contentWidth, height: viewPortHandler.contentHeight)
        let dx = axis?.gridLineWidth ?? 0.0
        rect.origin.x -= dx / 2.0
        rect.size.width += dx
        return rect
    }

    override func renderAxisLine(context: CGContext) {
        guard let xAxis = axis as? XAxis, xAxis.isEnabled, xAxis.drawAxisLineEnabled else { return }

        context.saveGState()

        context.setStrokeColor(xAxis.axisLineColor.cgColor)
        context.setLineWidth(xAxis.axisLineWidth)
        if let axisLineDashLengths = xAxis.axisLineDashLengths {
            context.setLineDash(phase: xAxis.axisLineDashPhase, lengths: axisLineDashLengths)
        } else {
            context.setLineDash(phase: 0.0, lengths: [])
        }

        context.beginPath()
        context.move(to: CGPoint(x: chartView.extraLeftOffset, y: viewPortHandler.contentBottom))
        context.addLine(to: CGPoint(x: CGFloat(context.width) - chartView.extraRightOffset, y: viewPortHandler.contentBottom))
        context.strokePath()

        context.restoreGState()
    }
}
