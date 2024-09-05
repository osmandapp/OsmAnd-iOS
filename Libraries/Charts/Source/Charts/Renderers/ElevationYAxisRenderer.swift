//
//  ElevationYAxisRenderer.swift
//  DGCharts
//
//  Created by Skalii on 28.08.2024.
//

import Foundation

final class ElevationYAxisRenderer: YAxisRenderer {

    private let chartView: ElevationChart

    override var gridClippingRect: CGRect {
        var rect = CGRect(x: chartView.extraLeftOffset,
                          y: chartView.extraTopOffset,
                          width: chartView.extraRightOffset,
                          height: chartView.extraBottomOffset)
        let dy = axis.gridLineWidth
        rect.origin.y -= dy / 2.0
        rect.size.height += dy
        return rect
    }

    init(_ chartView: ElevationChart, viewPortHandler: ViewPortHandler, yAxis: YAxis, trans: Transformer) {
        self.chartView = chartView
        super.init(viewPortHandler: viewPortHandler, axis: yAxis, transformer: trans)
    }

    override func renderAxisLabels(context: CGContext) {
        guard axis.isEnabled, axis.isDrawLabelsEnabled else { return }

        let yoffset = axis.labelFont.lineHeight / 2.5 + axis.yOffset
        let xPos: CGFloat
        let textAlign: TextAlignment

        if axis.axisDependency == .left {
            if axis.labelPosition == .outsideChart {
                textAlign = .right
                xPos = viewPortHandler.offsetLeft - axis.xOffset
            } else {
                textAlign = .left
                xPos = viewPortHandler.offsetLeft + axis.xOffset
            }
        } else {
            if axis.labelPosition == .outsideChart {
                textAlign = .left
                xPos = viewPortHandler.contentRight + axis.xOffset
            } else {
                textAlign = .right
                xPos = chartView.frame.width - chartView.extraRightOffset - axis.xOffset
            }
        }

        drawYLabels(context: context,
                    fixedPosition: xPos,
                    positions: transformedPositions(),
                    offset: yoffset - axis.labelFont.lineHeight,
                    textAlign: textAlign)
    }

    override func drawYLabels(context: CGContext,
                              fixedPosition: CGFloat,
                              positions: [CGPoint],
                              offset: CGFloat,
                              textAlign: TextAlignment) {
        let labelFont = axis.labelFont
        let labelTextColor = axis.labelTextColor

        let from = axis.isDrawBottomYLabelEntryEnabled ? 0 : 1
        let to = axis.isDrawTopYLabelEntryEnabled ? axis.entryCount : (axis.entryCount - 1)
        let xOffset = axis.labelXOffset

        guard let chartData = chartView.lineData else { return }
        var dataSetCount = chartData.dataSetCount
        let lastDataSet = dataSetCount > 0 ? chartData.dataSet(at: dataSetCount - 1) : nil
        if lastDataSet != nil, !chartView.shouldShowLastSet() {
            dataSetCount -= 1
        }

        for i in from..<to {
            var leftText = ""
            if dataSetCount == 1 {
                leftText = chartView.leftAxis.getFormattedLabel(i)
                if let dataSetLast = lastDataSet as? IOrderedLineDataSet {
                    leftText = dataSetLast.isLeftAxis()
                    ? leftText
                    : chartView.rightAxis.getFormattedLabel(i)
                }

                if let lineChartData = chartData.dataSet(at: 0) as? LineChartDataSet {
                    let color = lineChartData.color(atIndex: 0)
                    context.drawText(leftText,
                                     at: CGPoint(x: fixedPosition + xOffset, y: positions[i].y + offset),
                                     align: textAlign,
                                     attributes: [.font: labelFont, .foregroundColor: color])
                }
            } else {
                leftText = chartView.leftAxis.getFormattedLabel(i) + ", "
                let rightText = chartView.rightAxis.getFormattedLabel(i)
                let startDataSet = getDataSet(chartData, firstSet: true)
                let endDataSet = getDataSet(chartData, firstSet: false)
                let rightTextWidth = rightText.size(withAttributes: [.font: labelFont]).width
                if let startDataSet, let endDataSet {
                    var leftTextColor = startDataSet.color(atIndex: 0)
                    var rightTextColor = endDataSet.color(atIndex: 0)
                    if let dataSetStart = startDataSet as? IOrderedLineDataSet {
                        if dataSetStart.isLeftAxis() {
                            leftTextColor = startDataSet.color(atIndex: 0)
                            rightTextColor = endDataSet.color(atIndex: 0)
                        } else {
                            leftTextColor = endDataSet.color(atIndex: 0)
                            rightTextColor = startDataSet.color(atIndex: 0)
                        }
                    }

                    context.drawText(rightText,
                                     at: CGPoint(x: fixedPosition + xOffset, y: positions[i].y + offset),
                                     align: textAlign,
                                     attributes: [.font: labelFont, .foregroundColor: rightTextColor])

                    context.drawText(leftText,
                                     at: CGPoint(x: fixedPosition + xOffset - rightTextWidth, y: positions[i].y + offset),
                                     align: textAlign,
                                     attributes: [.font: labelFont, .foregroundColor: leftTextColor])
                } else {
                    context.drawText(rightText,
                                     at: CGPoint(x: fixedPosition + xOffset, y: positions[i].y + offset),
                                     align: textAlign,
                                     attributes: [.font: labelFont, .foregroundColor: labelTextColor])

                    context.drawText(leftText,
                                     at: CGPoint(x: fixedPosition + xOffset - rightTextWidth, y: positions[i].y + offset),
                                     align: textAlign,
                                     attributes: [.font: labelFont, .foregroundColor: labelTextColor])
                }
            }
        }
    }

    private func getDataSet(_ lineData: LineChartData, firstSet: Bool) -> LineChartDataSet? {
        if lineData.dataSets.count == 1 {
            return lineData.dataSet(at: 0) as? LineChartDataSet
        } else {
            return (lineData.dataSets.count > 1 ? lineData.dataSet(at: firstSet ? 0 : 1) : nil) as? LineChartDataSet
        }
    }

    override func renderGridLines(context: CGContext) {
        guard axis.isEnabled else { return }

        if axis.drawGridLinesEnabled {
            let positions = transformedPositions()

            context.setShouldAntialias(axis.gridAntialiasEnabled)
            context.setStrokeColor(axis.gridColor.cgColor)
            context.setLineWidth(axis.gridLineWidth)
            context.setLineCap(axis.gridLineCap)

            if axis.gridLineDashLengths != nil {
                context.setLineDash(phase: axis.gridLineDashPhase, lengths: axis.gridLineDashLengths)
            } else {
                context.setLineDash(phase: 0.0, lengths: [])
            }

            // draw the grid
            positions.forEach { drawGridLine(context: context, position: $0) }
        }

        if axis.drawZeroLineEnabled {
            // draw zero line
            drawZeroLine(context: context)
        }
    }
    
    override func drawGridLine(context: CGContext, position: CGPoint) {
        context.beginPath()
        context.move(to: CGPoint(x: chartView.extraLeftOffset, y: position.y))
        context.addLine(to: CGPoint(x: chartView.frame.width - chartView.extraRightOffset, y: position.y))
        context.strokePath()
    }
}
