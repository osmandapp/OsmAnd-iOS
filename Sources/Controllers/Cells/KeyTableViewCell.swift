//
//  KeyTableViewCell.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 17.09.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class KeyTableViewCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var warningLabel: UILabel!
    @IBOutlet private weak var titleContainerView: UIView!
    @IBOutlet private weak var keyContainerView: UIView!
    @IBOutlet private weak var warningContainerView: UIView!
    @IBOutlet private weak var alertImageView: UIImageView!
    
    private let horizontalSpace: CGFloat = 25
    private let verticalSpace: CGFloat = 23
    private let keyFontSize: CGFloat = 34
    private let defaultTextFontSize: CGFloat = 17
    
    private let keyView: KeyView = {
        let keyView: KeyView = .fromNib()
        keyView.translatesAutoresizingMaskIntoConstraints = false
        return keyView
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupKeyView()
    }
    
    func configure(actionName: String?, key: UIKeyboardHIDUsage?, existedKeyActionName: String?, showDisableIfNeeded: Bool, cornerRadius: CGFloat) {
        alertImageView.image = UIImage.templateImageNamed("ic_custom_alert")
        
        setupTitleContainer(with: actionName)
        
        keyView.configureWith(keySymbol: key.flatMap(KeySymbolMapper.keySymbol(for:)) ?? localizedString("shared_string_none"),
                              horizontalSpace: horizontalSpace,
                              verticalSpace: verticalSpace,
                              fontSize: keyFontSize,
                              cornerRadius: cornerRadius)
        
        if let existedKeyActionName, let key {
            setupWarning(existedKeyActionName, with: key)
        }
        warningContainerView.isHidden = existedKeyActionName == nil
        
        setupKeyViewColors(for: key, showDisableIfNeeded: showDisableIfNeeded)
    }
    
    private func setupKeyView() {
        keyContainerView.addSubview(keyView)
        NSLayoutConstraint.activate([
            keyView.topAnchor.constraint(equalTo: keyContainerView.topAnchor),
            keyView.bottomAnchor.constraint(equalTo: keyContainerView.bottomAnchor),
            keyView.centerXAnchor.constraint(equalTo: keyContainerView.centerXAnchor)
        ])
    }
    
    private func setupKeyViewColors(for key: UIKeyboardHIDUsage?, showDisableIfNeeded: Bool) {
        if key == nil {
            keyView.setKeyColor(borderColor: .keyBindStroke, backgroundColor: .keyBindBg, textColor: .textColorSecondary)
        } else if showDisableIfNeeded {
            keyView.setKeyColor(borderColor: .keyBindStrokeColorDisruptive, backgroundColor: .keyBindBgColorDisruptive, textColor: .textColorPrimary)
        } else {
            keyView.setKeyColor(borderColor: .keyBindStrokeActive, backgroundColor: .keyBindBgActive, textColor: .textColorActive)
        }
    }
    
    private func setupTitle(_ title: String) {
        let attributedText = NSMutableAttributedString(
            string: localizedString("press_button_to_link_with_action"),
            attributes: [.font: UIFont.systemFont(ofSize: defaultTextFontSize, weight: .regular)]
        )

        let actionNameText = NSAttributedString(
            string: title,
            attributes: [.font: UIFont.systemFont(ofSize: defaultTextFontSize, weight: .bold)]
        )
        attributedText.append(actionNameText)
        titleLabel.attributedText = attributedText
    }
    
    private func setupTitleContainer(with actionName: String?) {
        if let actionName {
            setupTitle(actionName)
        } else {
            titleContainerView.isHidden = true
        }
    }
    
    private func setupWarning(_ warning: String, with key: UIKeyboardHIDUsage) {
        let attributedText = NSMutableAttributedString(
            string: String(format: localizedString("key_is_already_assigned_error"), KeySymbolMapper.keySymbol(for: key)),
            attributes: [.font: UIFont.systemFont(ofSize: defaultTextFontSize, weight: .regular)]
        )

        let warningText = NSAttributedString(
            string: warning,
            attributes: [.font: UIFont.systemFont(ofSize: defaultTextFontSize, weight: .bold)]
        )
        attributedText.append(warningText)
        warningLabel.attributedText = attributedText
    }
}
