//
//  GradientXAxisRenderer.swift
//  DGCharts
//
//  Created by Skalii on 18.10.2024.
//

import Foundation

final class GradientXAxisRenderer: ElevationXAxisRenderer {
    
    private let chartView: GradientChart
    
    init(_ chartView: GradientChart,
         viewPortHandler: ViewPortHandler,
         xAxis: XAxis,
         trans: Transformer) {
        self.chartView = chartView
        super.init(chartView,
                   viewPortHandler: viewPortHandler,
                   xAxis: xAxis,
                   trans: trans)
    }
    
    override func drawLabels(context: CGContext, pos: CGFloat, anchor: CGPoint) {
        guard let transformer else { return }

        let paraStyle = ParagraphStyle.default.mutableCopy() as! MutableParagraphStyle
        paraStyle.alignment = .center
        let labelAttrs: [NSAttributedString.Key: Any] = [.font: axis.labelFont,
                                                         .foregroundColor: axis.labelTextColor,
                                                         .paragraphStyle: paraStyle]

        let labelRotationAngleRadians = axis.labelRotationAngle.DEG2RAD
        let splitInterval = (axis.axisMaximum - axis.axisMinimum) / Double(axis.entryCount - 1)
        let valueToPixelMatrix = transformer.valueToPixelMatrix
        var labelMaxSize = CGSize.zero

        if axis.isWordWrapEnabled {
            labelMaxSize.width = axis.wordWrapWidthPercent * valueToPixelMatrix.a
        }

        var positions = [CGPoint](repeating: CGPoint(x: 0, y: 0), count: axis.entryCount * 2)
        for i in stride(from: 0, to: positions.count, by: 2) {
            positions[i] = CGPoint(x: axis.axisMinimum + Double(i / 2) * splitInterval, y: 0)
        }
        transformer.pointValuesToPixel(&positions)

        for i in stride(from: 0, to: positions.count, by: 2) {
            var x = positions[i].x
            guard viewPortHandler.isInBoundsX(x) else { continue }

            let label = NSString(string: axis.valueFormatter?.stringForValue(axis.entries[i / 2], axis: axis) ?? "")
            if axis.isAvoidFirstLastClippingEnabled {
                if i / 2 == axis.entryCount - 1 && axis.entryCount > 1 {
                    let width = label.boundingRect(with: labelMaxSize,
                                                   options: .usesLineFragmentOrigin,
                                                   attributes: labelAttrs,
                                                   context: nil).size.width
                    x -= width / 2.0
                } else if i == 0 {
                    let width = label.boundingRect(with: labelMaxSize,
                                                   options: .usesLineFragmentOrigin,
                                                   attributes: labelAttrs,
                                                   context: nil).size.width
                    x += width / 2.0
                }
            }

            drawLabel(context: context,
                      formattedLabel: label as String,
                      x: x,
                      y: pos,
                      attributes: labelAttrs,
                      constrainedTo: labelMaxSize,
                      anchor: anchor,
                      angleRadians: labelRotationAngleRadians)

            context.saveGState()
            context.setStrokeColor(axis.axisLineColor.cgColor)
            drawTick(context: context, x: positions[i].x)
            context.restoreGState()
        }
    }

    override func computeAxisValues(min: Double, max: Double) {
        let yMin = min
        let yMax = max
        if let lineData = chartView.lineData,
           let dataSet = lineData.dataSet(at: 0) {
            let labelCount = dataSet.entryCount
            let range = abs(yMax - yMin)
            if labelCount == 0 || range <= 0.0 || range.isInfinite {
                axis.entries = []
                axis.centeredEntries = []
                return
            }

            axis.entries = [Double](repeating: 0, count: labelCount)
            axis.centeredEntries = [Double](repeating: 0, count: labelCount)
            
            for i in 0..<labelCount {
                if let entry = dataSet.entryForIndex(i) {
                    axis.entries[i] = entry.x
                    axis.centeredEntries[i] = entry.x
                }
            }

            computeSize()
        }
    }

    override func renderGridLines(context: CGContext) {
        guard axis.isEnabled, axis.isDrawGridLinesEnabled else {
            return
        }

        context.saveGState()
        defer { context.restoreGState() }

        context.clip(to: gridClippingRect)
        let splitInterval = (axis.axisMaximum - axis.axisMinimum) / Double(axis.entryCount - 1)
        var positions = [CGPoint](repeating: CGPoint(x: 0, y: 0), count: axis.entryCount * 2)
        for i in stride(from: 0, to: positions.count, by: 2) {
            positions[i] = CGPoint(x: axis.axisMinimum + Double(i / 2) * splitInterval, y: 0)
        }
        transformer?.pointValuesToPixel(&positions)

        context.setShouldAntialias(axis.gridAntialiasEnabled)
        context.setStrokeColor(axis.gridColor.cgColor)
        context.setLineWidth(axis.gridLineWidth)
        context.setLineCap(axis.gridLineCap)

        if let lengths = axis.gridLineDashLengths {
            context.setLineDash(phase: axis.gridLineDashPhase, lengths: lengths)
        } else {
            context.setLineDash(phase: 0.0, lengths: [])
        }

        for i in stride(from: 0, to: positions.count, by: 2) {
            var x = positions[i].x
            if i / 2 == axis.entryCount - 1 && axis.entryCount > 1 {
                x -= axis.gridLineWidth / 2.0
            } else if i == 0 {
                x += axis.gridLineWidth / 2.0
            }
            drawGridLine(context: context, x: x, y: positions[i + 1].y)
        }
    }
}
