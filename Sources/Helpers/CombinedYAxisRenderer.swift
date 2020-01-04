//
//  CombinedYAxisRenderer.swift
//  OsmAnd
//
//  Created by Paul on 03.01.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

import UIKit
import Charts

@objc class CombinedYAxisRenderer: YAxisRenderer {
    let secondaryYAxis: YAxis?
    let secondaryTransformer: Transformer?
    
    @objc public init(viewPortHandler: ViewPortHandler, yAxis: YAxis?, secondaryYAxis: YAxis?, transformer: Transformer?, secondaryTransformer: Transformer?)
    {
        self.secondaryYAxis = secondaryYAxis
        self.secondaryTransformer = secondaryTransformer
        super.init(viewPortHandler: viewPortHandler, yAxis: yAxis, transformer: transformer)
    }
    
    /// draws the y-axis labels to the screen
    open override func renderAxisLabels(context: CGContext)
    {
        guard let yAxis = self.axis as? YAxis else { return }
        
        if !yAxis.isEnabled || !yAxis.isDrawLabelsEnabled
        {
            return
        }
        
        let xoffset = yAxis.xOffset
        let yoffset = yAxis.labelFont.lineHeight / 2.5 + yAxis.yOffset
        
        let dependency = yAxis.axisDependency
        let labelPosition = yAxis.labelPosition
        
        var xPos = CGFloat(0.0)
        
        var textAlign: NSTextAlignment
        
        if dependency == .left
        {
            if labelPosition == .outsideChart
            {
                textAlign = .right
                xPos = viewPortHandler.offsetLeft - xoffset
            }
            else
            {
                textAlign = .left
                xPos = viewPortHandler.offsetLeft + xoffset
            }
            
        }
        else
        {
            if labelPosition == .outsideChart
            {
                textAlign = .left
                xPos = viewPortHandler.contentRight + xoffset
            }
            else
            {
                textAlign = .right
                xPos = viewPortHandler.contentRight - xoffset
            }
        }
        
        drawYLabels(
            context: context,
            fixedPosition: xPos,
            positions: transformedPositions(),
            offset: yoffset - yAxis.labelFont.lineHeight,
            textAlign: textAlign)
    }
    
    internal func drawYLabels(
        context: CGContext,
        fixedPosition: CGFloat,
        positions: [CGPoint],
        offset: CGFloat,
        textAlign: NSTextAlignment)
    {
        guard
            let yAxis = self.axis as? YAxis
            else { return }
        
        let labelFont = yAxis.labelFont
        let labelTextColor = yAxis.labelTextColor
        let labelBackgroundColor = yAxis.labelBackgroundColor
        
        let from = yAxis.isDrawBottomYLabelEntryEnabled ? 0 : 1
        let to = yAxis.isDrawTopYLabelEntryEnabled ? yAxis.entryCount : (yAxis.entryCount - 1)
        
        for i in stride(from: from, to: to, by: 1)
        {
            let text = yAxis.getFormattedLabel(i)
            
            print(secondaryTransformer?.valueForTouchPoint(CGPoint(x: fixedPosition, y: positions[i].y + offset)).y)
            
            ChartUtils.drawText(
                context: context,
                text: text,
                point: CGPoint(x: fixedPosition, y: positions[i].y + offset),
                align: textAlign,
                attributes: [.font: labelFont, .foregroundColor: labelTextColor, .backgroundColor: labelBackgroundColor]
            )
        }
    }
}
