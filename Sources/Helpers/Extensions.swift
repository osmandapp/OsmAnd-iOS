//
//  Extensions.swift
//  OsmAnd Maps
//
//  Created by Paul on 06.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import UIKit

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
}

extension UIImage {

    func rotate(radians: CGFloat) -> UIImage {
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
            .integral.size
        UIGraphicsBeginImageContext(rotatedSize)
        if let context = UIGraphicsGetCurrentContext() {
            let origin = CGPoint(x: rotatedSize.width / 2.0,
                                 y: rotatedSize.height / 2.0)
            context.translateBy(x: origin.x, y: origin.y)
            context.rotate(by: radians)
            draw(in: CGRect(x: -origin.y, y: -origin.x,
                            width: size.width, height: size.height))
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return rotatedImage ?? self
        }
        return self
    }

}

extension NSMutableAttributedString {

    func attachImage(image: UIImage, at position: Int = 0) {
        let attachmentImage = NSTextAttachment()
        attachmentImage.image = image.withRenderingMode(.alwaysOriginal)
        if let font = attributes(at: position, effectiveRange: nil)[.font] as? UIFont {
            let fontHeight = font.lineHeight
            let attachmentHeight = attachmentImage.image!.size.height
            let yOffset = (fontHeight - attachmentHeight) / 2.0
            attachmentImage.bounds = CGRect(x: 0, y: yOffset, width: attachmentImage.image!.size.width, height: attachmentHeight)
            attachmentImage.bounds.origin.y += font.descender
        }
        let attachmentString = NSAttributedString(attachment: attachmentImage)
        self.insert(attachmentString, at: position)
    }

}

@objc extension NSIndexPath {

    @objc static func getRowsCount(_ section: UInt, at indexPaths: [NSIndexPath]) -> Int {
        return indexPaths.filter { $0.section == section }.count
    }

}
