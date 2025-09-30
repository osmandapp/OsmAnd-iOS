//
//  KeyView.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 29.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class KeyView: UIView {
    struct Params {
        let keySymbol: String
        let horizontalSpace: CGFloat
        let verticalSpace: CGFloat
        let fontSize: CGFloat
        let cornerRadius: CGFloat
    }
    
    @IBOutlet private weak var keyLabel: UILabel!
    @IBOutlet private weak var keyContainerView: UIView!
    @IBOutlet private weak var leftConstraint: NSLayoutConstraint!
    @IBOutlet private weak var rightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var topConstraint: NSLayoutConstraint!
    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!
    
    func configureWith(keyCode: UIKeyboardHIDUsage, horizontalSpace: CGFloat, fontSize: CGFloat) {
        keyLabel.text = OAUtilities.capitalizeFirstLetter(KeySymbolMapper.keySymbol(for: keyCode))
        keyLabel.font = .systemFont(ofSize: fontSize, weight: .semibold)
        leftConstraint.constant = horizontalSpace
        rightConstraint.constant = horizontalSpace
    }
    
    func configureWith(params: Params) {
        keyLabel.text = OAUtilities.capitalizeFirstLetter(params.keySymbol)
        keyLabel.font = .systemFont(ofSize: params.fontSize, weight: .semibold)
        leftConstraint.constant = params.horizontalSpace
        rightConstraint.constant = params.horizontalSpace
        topConstraint.constant = params.verticalSpace
        bottomConstraint.constant = params.verticalSpace
        keyContainerView.cornerRadius = params.cornerRadius
    }
    
    func setKeyColor(borderColor: UIColor, backgroundColor: UIColor, textColor: UIColor) {
        keyLabel.textColor = textColor
        keyContainerView.backgroundColor = backgroundColor
        keyContainerView.borderColor = borderColor
    }
}
