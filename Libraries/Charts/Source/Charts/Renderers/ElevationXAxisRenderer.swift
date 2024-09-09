//
//  ElevationXAxisRenderer.swift
//  OsmAnd Maps
//
//  Created by Skalii on 25.08.2024.
//

import Foundation

final class ElevationXAxisRenderer: XAxisRenderer {

    private let chartView: LineChartView

    override var gridClippingRect: CGRect {
        CGRect(x: viewPortHandler.contentLeft,
               y: viewPortHandler.contentTop,
               width: viewPortHandler.contentWidth,
               height: viewPortHandler.contentHeight - viewPortHandler.contentBottom - 4.0)
    }

    init(_ chartView: LineChartView, viewPortHandler: ViewPortHandler, xAxis: XAxis, trans: Transformer) {
        self.chartView = chartView
        super.init(viewPortHandler: viewPortHandler, axis: xAxis, transformer: trans)
    }

    override func renderAxisLine(context: CGContext) {
        guard axis.isEnabled && axis.drawAxisLineEnabled else { return }

        context.saveGState()
        defer { context.restoreGState() }

        context.setStrokeColor(axis.axisLineColor.cgColor)
        context.setLineWidth(axis.axisLineWidth)
        if let axisLineDashLengths = axis.axisLineDashLengths {
            context.setLineDash(phase: axis.axisLineDashPhase, lengths: axisLineDashLengths)
        } else {
            context.setLineDash(phase: 0.0, lengths: [])
        }

        axisLineSegmentsBuffer[0].x = chartView.extraLeftOffset
        axisLineSegmentsBuffer[0].y = viewPortHandler.contentBottom
        axisLineSegmentsBuffer[1].x = chartView.frame.width - chartView.extraRightOffset
        axisLineSegmentsBuffer[1].y = viewPortHandler.contentBottom
        context.strokeLineSegments(between: axisLineSegmentsBuffer)
    }
    
    override func drawGridLine(context: CGContext, x: CGFloat, y: CGFloat) {
        guard x >= viewPortHandler.offsetLeft && x <= viewPortHandler.chartWidth else { return }

        context.beginPath()
        context.move(to: CGPoint(x: x, y: viewPortHandler.contentTop + 4.0))
        context.addLine(to: CGPoint(x: x, y: viewPortHandler.contentBottom))
        context.strokePath()
    }

    override func drawLabels(context: CGContext, pos: CGFloat, anchor: CGPoint) {
        guard let transformer else { return }

        let paraStyle = ParagraphStyle.default.mutableCopy() as! MutableParagraphStyle
        paraStyle.alignment = .center

        let labelAttrs: [NSAttributedString.Key: Any] = [.font: axis.labelFont,
                                                         .foregroundColor: axis.labelTextColor,
                                                         .paragraphStyle: paraStyle]

        let labelRotationAngleRadians = axis.labelRotationAngle.DEG2RAD
        let isCenteringEnabled = axis.isCenterAxisLabelsEnabled
        let valueToPixelMatrix = transformer.valueToPixelMatrix

        var position = CGPoint.zero
        var labelMaxSize = CGSize.zero

        if axis.isWordWrapEnabled {
            labelMaxSize.width = axis.wordWrapWidthPercent * valueToPixelMatrix.a
        }

        let entries = axis.entries
        for i in entries.indices {
            let px = isCenteringEnabled ? CGFloat(axis.centeredEntries[i]) : CGFloat(entries[i])
            position = CGPoint(x: px, y: 0)
                .applying(valueToPixelMatrix)

            guard viewPortHandler.isInBoundsX(position.x) else { continue }

            let label = axis.valueFormatter?.stringForValue(axis.entries[i], axis: axis) ?? ""
            let labelns = label as NSString

            if axis.isAvoidFirstLastClippingEnabled {
                // avoid clipping of the last
                if i == axis.entryCount - 1 && axis.entryCount > 1 {
                    let width = labelns.boundingRect(with: labelMaxSize,
                                                     options: .usesLineFragmentOrigin,
                                                     attributes: labelAttrs,
                                                     context: nil).size.width
                    
                    if !viewPortHandler.isInBoundsX(position.x + width / 2.0) {
                        position.x = viewPortHandler.contentRight - width / 2.0
                    }
                } else if i == 0 { // avoid clipping of the first
                    let width = labelns.boundingRect(with: labelMaxSize,
                                                     options: .usesLineFragmentOrigin,
                                                     attributes: labelAttrs,
                                                     context: nil).size.width
                    if !viewPortHandler.isInBoundsX(position.x - width / 2.0) {
                        position.x = viewPortHandler.contentLeft + width / 2.0
                    }
                }
            }

            drawLabel(context: context,
                      formattedLabel: label,
                      x: position.x,
                      y: pos,
                      attributes: labelAttrs,
                      constrainedTo: labelMaxSize,
                      anchor: anchor,
                      angleRadians: labelRotationAngleRadians)
        }
    }

    override func calculateInterval(range: Double, labelCount: Int) -> Double {
        let labelCountForFullInterval = labelCount - 1
        var interval = range / Double(labelCountForFullInterval)
        
        if axis.granularityEnabled {
            interval = Swift.max(interval, axis.granularity)
        }
        
        let intervalMagnitude = pow(10.0, Double(Int(log10(interval)))).roundedToNextSignificant()
        let intervalSigDigit = Int(interval / intervalMagnitude)
        if intervalSigDigit > 5 {
            interval = floor(10.0 * Double(intervalMagnitude))
        }
        return interval
    }

    override func calculateNoForcedLabelCount(interval: Double,
                                              n: inout Int,
                                              yMin: Double,
                                              yMax: Double) -> (Double, Int) {
        var first = interval == 0.0 ? 0.0 : ceil(yMin / interval) * interval
        if axis.centerAxisLabelsEnabled {
            first -= interval
        }

        let last = interval == 0.0 ? 0.0 : yMax
        if interval != 0.0, last != first {
            stride(from: first, through: last, by: interval).forEach { _ in n += 1 }
        }

        // Ensure stops contains at least n elements.
        axis.entries.removeAll(keepingCapacity: true)
        axis.entries.reserveCapacity(n)

        let start = first, end = first + Double(n) * interval

        // Fix for IEEE negative zero case (Where value == -0.0, and 0.0 == -0.0)
        let values = stride(from: start, to: end, by: interval).map { $0 == 0.0 ? 0.0 : $0 }
        axis.entries.append(contentsOf: values)
        return (interval, n)
    }

    override func renderGridLines(context: CGContext) {
        guard let transformer, axis.isEnabled, axis.isDrawGridLinesEnabled else {
            return
        }

        context.saveGState()
        defer { context.restoreGState() }

        context.clip(to: gridClippingRect)

        context.setShouldAntialias(axis.gridAntialiasEnabled)
        context.setStrokeColor(axis.gridColor.cgColor)
        context.setLineWidth(axis.gridLineWidth)
        context.setLineCap(axis.gridLineCap)

        if let lengths = axis.gridLineDashLengths {
            context.setLineDash(phase: axis.gridLineDashPhase, lengths: lengths)
        } else {
            context.setLineDash(phase: 0.0, lengths: [])
        }

        let valueToPixelMatrix = transformer.valueToPixelMatrix
        var position = CGPoint.zero
        let entries = axis.entries

        for i in 0..<entries.count {
            
            var entry = entries[i]
            if i == axis.entryCount - 1 && axis.entryCount > 1 {
                entry -= axis.gridLineWidth / 2.0
            } else if i == 0 {
                entry += axis.gridLineWidth / 2.0
            }
            
            position.x = CGFloat(entry)
            position.y = CGFloat(entries[i])
            position = position.applying(valueToPixelMatrix)
            
            drawGridLine(context: context, x: position.x, y: position.y)
        }
    }
}
