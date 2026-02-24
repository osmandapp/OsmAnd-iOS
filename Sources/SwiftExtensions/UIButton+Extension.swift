//
//  UIButtonExtension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 28.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

extension UIButton {
    @objc(addRightImage:offset:withRTL:)
    func addRight(with image: UIImage, offset: CGFloat, withRTL: Bool) {
        setImage(image, for: .normal)
        if let imageView {
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0.0).isActive = true
            if withRTL {
                imageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -offset).isActive = true
            } else {
                imageView.rightAnchor.constraint(equalTo: rightAnchor, constant: -offset).isActive = true
            }
        }
    }
}
