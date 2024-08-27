//
//  YAxisCombinedRenderer.swift
//  DGCharts
//
//  Created by Oleksandr Panchenko on 23.08.2024.
//

import UIKit

@objc(ChartYAxisCombinedRenderer)
open class YAxisCombinedRenderer: YAxisRenderer {

    @objc(YAxisCombinedRenderingMode)
    public enum RenderingMode: Int {
        case primaryValueOnly
        case secondaryValueOnly
        case bothValues
    }

    @objc open var renderingMode: RenderingMode

    @objc public let secondaryYAxis: YAxis?
    @objc public let secondaryTransformer: Transformer?

    @objc public init(viewPortHandler: ViewPortHandler, yAxis: YAxis, secondaryYAxis: YAxis?, transformer: Transformer?, secondaryTransformer: Transformer?) {
        self.secondaryYAxis = secondaryYAxis
        self.secondaryTransformer = secondaryTransformer
        self.renderingMode = .bothValues
        super.init(viewPortHandler: viewPortHandler, axis: yAxis, transformer: transformer)
    }

    open override func drawYLabels(
        context: CGContext,
        fixedPosition: CGFloat,
        positions: [CGPoint],
        offset: CGFloat,
        textAlign: NSTextAlignment) {
        let primaryAttributes: [NSAttributedString.Key: Any] = [.font: axis.labelFont,
                                                                .foregroundColor: axis.labelTextColor,
                                                                .backgroundColor: axis.labelBackgroundColor]
        let secondaryAttributes: [NSAttributedString.Key: Any] = [.font: secondaryYAxis?.labelFont ?? UIFont.systemFont(ofSize: 15),
                                                                  .foregroundColor: secondaryYAxis?.labelTextColor ?? .white,
                                                                  .backgroundColor: secondaryYAxis?.labelBackgroundColor ?? .white]

        let from = axis.isDrawBottomYLabelEntryEnabled ? 0 : 1
        let to = axis.isDrawTopYLabelEntryEnabled ? axis.entryCount : (axis.entryCount - 1)

        for i in stride(from: from, to: to, by: 1) {
            let height: CGPoint? = secondaryTransformer?.valueForTouchPoint(CGPoint(x: fixedPosition, y: positions[i].y + offset))
            let secondaryText: String = secondaryYAxis?.valueFormatter?.stringForValue(Double(height?.y ?? 0), axis: secondaryYAxis) ?? ""
            let text = axis.getFormattedLabel(i)

            let needsSeparator = self.renderingMode == .bothValues
            let separator = needsSeparator ? ", " : ""
            let secondaryWidth = (separator + secondaryText).size(withAttributes: secondaryAttributes).width
            let correctedPosition = fixedPosition - secondaryWidth

            switch self.renderingMode {
            case .bothValues:
                context.drawText(text,
                                 at: CGPoint(x: correctedPosition, y: positions[i].y + offset),
                                 align: textAlign,
                                 attributes: primaryAttributes)

                if !secondaryText.isEmpty {
                    context.drawText(separator + secondaryText,
                                     at: CGPoint(x: fixedPosition, y: positions[i].y + offset),
                                     align: textAlign,
                                     attributes: secondaryAttributes)
                }
            case .primaryValueOnly:
                context.drawText(text,
                                 at: CGPoint(x: fixedPosition, y: positions[i].y + offset),
                                 align: textAlign,
                                 attributes: primaryAttributes)
            case .secondaryValueOnly:
                if !secondaryText.isEmpty {
                    context.drawText(separator + secondaryText,
                                     at: CGPoint(x: fixedPosition, y: positions[i].y + offset),
                                     align: textAlign,
                                     attributes: secondaryAttributes)
                }
            default:
                break
            }
        }
    }
}
