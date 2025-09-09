//
//  KeyAssignmentTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 27.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class KeyAssignmentTableViewCell: OASimpleTableViewCell {
    @IBOutlet private weak var keysStackView: UIStackView!
    
    func configure(keyCodes: [UIKeyboardHIDUsage],
                   horizontalSpace: CGFloat = 12,
                   fontSize: CGFloat = 12,
                   additionalVerticalSpace: CGFloat = 5,
                   keySpacing: CGFloat = 6,
                   isAlignedToLeading: Bool = false) {
        keysStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        keysStackView.isHidden = keyCodes.isEmpty
        keysStackView.spacing = keySpacing
        setAdditionalVerticalSpace(additionalVerticalSpace)
        for keyCode in keyCodes {
            let keyView: KeyView = .fromNib()
            keyView.configureWith(keyCode: keyCode, horizontalSpace: horizontalSpace, fontSize: fontSize)
            keysStackView.addArrangedSubview(keyView)
        }
        
        if isAlignedToLeading {
            let spacer = UIView()
            spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
            spacer.setContentCompressionResistancePriority(.required, for: .horizontal)
            keysStackView.addArrangedSubview(spacer)
        }
    }
}
