//
//  KeyView.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 29.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class KeyView: UIView {
    @IBOutlet private weak var keyLabel: UILabel!
    @IBOutlet private weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet private weak var rightConstraint: NSLayoutConstraint!
    
    func configureWith(input: String, horizontalSpace: CGFloat, fontSize: CGFloat) {
        keyLabel.text = input.uppercased()
        keyLabel.font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        leftConstraint.constant = horizontalSpace
        rightConstraint.constant = horizontalSpace
    }
}
