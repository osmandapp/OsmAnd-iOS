//
//  FFCircularProgressView+Extension.swift
//  OsmAnd Maps
//
//  Created by Skalii on 09.02.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

extension FFCircularProgressView {
    func createTickPath() {
        let radius: CGFloat = min(frame.size.width, frame.size.height) / 2
        let path = UIBezierPath()
        let tickWidth: CGFloat = radius * 0.3
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: tickWidth * 2))
        path.addLine(to: CGPoint(x: tickWidth * 3, y: tickWidth * 2))
        path.addLine(to: CGPoint(x: tickWidth * 3, y: tickWidth))
        path.addLine(to: CGPoint(x: tickWidth, y: tickWidth))
        path.addLine(to: CGPoint(x: tickWidth, y: 0))
        path.close()

        path.apply(CGAffineTransformMakeRotation(-(.pi / 4)))
        path.apply(CGAffineTransformMakeTranslation(radius * 0.46, 1.02 * radius))

        iconPath = path
    }
}
