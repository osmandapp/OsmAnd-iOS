//
//  UIStackView+Extension.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 15.01.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

extension UIStackView {
    
    func addSeparators(at positions: [Int],
                       color: UIColor = UIColor.widgetSeparator) {
        for position in positions {
            let separator = UIView()
            separator.backgroundColor = color
            separator.translatesAutoresizingMaskIntoConstraints = false
            insertArrangedSubview(separator, at: position)
            switch axis {
            case .horizontal:
                separator.widthAnchor.constraint(equalToConstant: 1).isActive = true
                separator.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 1).isActive = true
            case .vertical:
                separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
                separator.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1).isActive = true
            @unknown default:
                fatalError("Unknown UIStackView axis value.")
            }
        }
    }
    
    @objc @discardableResult func removeAllArrangedSubviews() -> [UIView] {
        let removedSubviews = arrangedSubviews.reduce([]) { (removedSubviews, subview) -> [UIView] in
            removeArrangedSubview(subview)
            NSLayoutConstraint.deactivate(subview.constraints)
            subview.removeFromSuperview()
            return removedSubviews + [subview]
        }
        return removedSubviews
    }
}
