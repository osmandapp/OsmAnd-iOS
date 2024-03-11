//
//  OutlineLabel.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 08.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objcMembers
final class OutlineLabel: UILabel {
    
    var outlineColor: UIColor? = .black
    var outlineWidth: CGFloat = 1.0
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func drawText(in rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        let inlineColor = textColor
        
        context.setLineWidth(outlineWidth)
        context.setLineJoin(.round)
        context.setTextDrawingMode(.stroke)
        textColor = outlineColor
        
        super.drawText(in: rect)
        
        context.setTextDrawingMode(.fill)
        textColor = inlineColor
        
        super.drawText(in: rect)
    }
}
