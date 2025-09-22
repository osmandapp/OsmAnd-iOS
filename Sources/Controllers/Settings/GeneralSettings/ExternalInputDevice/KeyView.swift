//
//  KeyView.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 29.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class KeyView: UIView {
    @IBOutlet private weak var keyLabel: UILabel!
    @IBOutlet private weak var keyContainerView: UIView!
    @IBOutlet private weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet private weak var rightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var topConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!
    
    func configureWith(keyCode: UIKeyboardHIDUsage, horizontalSpace: CGFloat, fontSize: CGFloat) {
        keyLabel.text = KeySymbolMapper.keySymbol(for: keyCode).firstLetterUppercase()
        keyLabel.font = .systemFont(ofSize: fontSize, weight: .semibold)
        leftConstraint.constant = horizontalSpace
        rightConstraint.constant = horizontalSpace
    }
    
    func configureWith(keySymbol: String, horizontalSpace: CGFloat, verticalSpace: CGFloat, fontSize: CGFloat, cornerRadius: CGFloat) {
        keyLabel.text = keySymbol.firstLetterUppercase()
        keyLabel.font = .systemFont(ofSize: fontSize, weight: .semibold)
        leftConstraint.constant = horizontalSpace
        rightConstraint.constant = horizontalSpace
        topConstraint.constant = verticalSpace
        bottomConstraint.constant = verticalSpace
        keyContainerView.cornerRadius = cornerRadius
    }
    
    func setKeyColor(borderColor: UIColor, backgroundColor: UIColor, textColor: UIColor) {
        keyLabel.textColor = textColor
        keyContainerView.backgroundColor = backgroundColor
        keyContainerView.borderColor = borderColor
    }
}
