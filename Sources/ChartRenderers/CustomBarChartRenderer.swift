//
//  CustomBarChartRenderer.swift
//  DGCharts
//
//  Created by Oleksandr Panchenko on 23.08.2024.
//

import UIKit

open class CustomBarChartRenderer: HorizontalBarChartRenderer {
    
    public override init(dataProvider: BarChartDataProvider, animator: Animator, viewPortHandler: ViewPortHandler) {
        super.init(dataProvider: dataProvider, animator: animator, viewPortHandler: viewPortHandler)
    }

    open override func drawHighlighted(context: CGContext, indices: [Highlight]) {
        guard
            let dataProvider = dataProvider,
            let barData = dataProvider.barData
            else { return }

        context.saveGState()

        var barRect = CGRect()

        for high in indices {
            guard
                let set = barData[high.dataSetIndex] as? BarChartDataSetProtocol,
                set.isHighlightEnabled
                else { continue }

            if let e = set.entryForXValue(high.x, closestToY: high.y) as? BarChartDataEntry {
                if !isInBoundsX(entry: e, dataSet: set) {
                    continue
                }

                let trans = dataProvider.getTransformer(forAxis: set.axisDependency)

                context.setFillColor(set.highlightColor.cgColor)
                context.setAlpha(set.highlightAlpha)

                let isStack = high.stackIndex >= 0 && e.isStacked

                let y1: Double
                let y2: Double

                if isStack {
                    if dataProvider.isHighlightFullBarEnabled {
                        y1 = e.positiveSum
                        y2 = -e.negativeSum
                    } else {
                        let range = e.ranges?[high.stackIndex]

                        y1 = range?.from ?? 0.0
                        y2 = range?.to ?? 0.0
                    }
                } else {
                    y1 = e.y
                    y2 = 0.0
                }

                prepareBarHighlight(x: e.x, y1: y1, y2: y2, barWidthHalf: barData.barWidth / 2.0, trans: trans, rect: &barRect)

                barRect.origin.x = high.drawX - 1.0
                barRect.size.width = 1.0

                context.fill(barRect)
            }
        }

        context.restoreGState()
    }
}
