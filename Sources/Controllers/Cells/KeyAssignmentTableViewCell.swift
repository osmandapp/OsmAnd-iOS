//
//  KeyAssignmentTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 27.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class KeyAssignmentTableViewCell: UITableViewCell {
    private static let defaultHorizontalSpace: CGFloat = 12
    private static let defaultFontSize: CGFloat = 12
    private static let defaultCellHeight: CGFloat = 48
    private static let defaultKeySpacing: CGFloat = 6
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var leftIconView: UIImageView!
    @IBOutlet private weak var keysStackView: UIStackView!
    @IBOutlet private weak var heightConstraint: NSLayoutConstraint!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let viewFrame = titleLabel.convert(titleLabel.bounds, to: self)
        separatorInset = UIEdgeInsets(top: 0, left: isDirectionRTL() ? getTableView().frame.size.width - (viewFrame.origin.x + viewFrame.size.width) : viewFrame.origin.x, bottom: 0, right: 0)
    }
    
    func configure(keyCodes: [UIKeyboardHIDUsage],
                   horizontalSpace: CGFloat = KeyAssignmentTableViewCell.defaultHorizontalSpace,
                   fontSize: CGFloat = KeyAssignmentTableViewCell.defaultFontSize,
                   cellHeight: CGFloat = KeyAssignmentTableViewCell.defaultCellHeight,
                   keySpacing: CGFloat = KeyAssignmentTableViewCell.defaultKeySpacing,
                   isAlignedToLeading: Bool = false) {
        keysStackView.arrangedSubviews.forEach {
            keysStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        keysStackView.isHidden = keyCodes.isEmpty
        keysStackView.spacing = keySpacing
        heightConstraint.constant = cellHeight
        
        if !isAlignedToLeading {
            addSpacer()
        }
        
        for keyCode in keyCodes {
            let keyView: KeyView = .fromNib()
            keyView.configureWith(keyCode: keyCode, horizontalSpace: horizontalSpace, fontSize: fontSize)
            keysStackView.addArrangedSubview(keyView)
        }
        
        if isAlignedToLeading {
            addSpacer()
        }
    }
    
    func titleVisibility(_ show: Bool) {
        titleLabel.isHidden = !show
    }
    
    func setTitle(_ title: String?) {
        titleLabel.text = title
        titleLabel.accessibilityLabel = title
    }
    
    func leftIconVisibility(_ show: Bool) {
        leftIconView.isHidden = !show
    }
    
    func setLeftIcon(_ iconName: String?, tintColor color: UIColor? = nil) {
        leftIconView.image = UIImage.templateImageNamed(iconName)
        if let color {
            leftIconView.tintColor = color
        }
    }
    
    private func addSpacer() {
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        keysStackView.addArrangedSubview(spacer)
    }
}
