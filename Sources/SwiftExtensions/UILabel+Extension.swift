//
//  UILabel+Extension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 11.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

extension UILabel {
   @objc var actualScaleFactor: CGFloat {
        guard let attributedText else { return font.pointSize }
        let text = NSMutableAttributedString(attributedString: attributedText)
        text.setAttributes([.font: font as Any], range: NSRange(location: 0, length: text.length))
        let context = NSStringDrawingContext()
        context.minimumScaleFactor = minimumScaleFactor
        text.boundingRect(with: frame.size, options: .usesLineFragmentOrigin, context: context)
        return context.actualScaleFactor
    }
}
