//
//  WikipediaContextMenuView.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 23.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class WikipediaContextMenuView: UIView {
    
    // MARK: - Properties

    var isExpanded = false
    var maxCollapsedTextLength = 200
    
    var onExpandStateChange: ((Bool) -> Void)?
    
    private var text: String = ""
    private var onButtonAction: (() -> Void)?

    // MARK: - UI
    
    private let labelContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.clipsToBounds = true
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.isUserInteractionEnabled = true
        return label
    }()

    private let actionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = .buttonTextColorSecondary
        config.background.strokeColor = UIColor.buttonOutlineColorSecondary
        config.background.strokeWidth = 1
        config.cornerStyle = .fixed
        config.background.cornerRadius = 8
        
        config.imagePadding = Constants.buttonContentInset.leading
        config.contentInsets = Constants.buttonContentInset
        button.configuration = config

        return button
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(labelContainer)
        addSubview(actionButton)
        labelContainer.addSubview(titleLabel)
        
        let heightContainerConstraint = labelContainer.heightAnchor.constraint(equalTo: titleLabel.heightAnchor)
        heightContainerConstraint.priority = .defaultLow

        NSLayoutConstraint.activate([
            labelContainer.topAnchor.constraint(equalTo: topAnchor, constant: Constants.contentInset.top),
            labelContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.contentInset.leading),
            labelContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.contentInset.trailing),
            heightContainerConstraint,
            
            titleLabel.topAnchor.constraint(equalTo: labelContainer.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: labelContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: labelContainer.trailingAnchor),

            actionButton.topAnchor.constraint(greaterThanOrEqualTo: labelContainer.bottomAnchor, constant: Constants.buttonTopOffset),
            actionButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.contentInset.leading),
            actionButton.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -Constants.contentInset.trailing),
            actionButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.contentInset.bottom),
            actionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.buttonHeight)
        ])
    }

    private func setupActions() {
        actionButton.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
        titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapText)))
    }
    
    // MARK: - Actions

    @objc private func didTapText() {
        isExpanded.toggle()
        titleLabel.attributedText = makeAttributedText(from: text)
        onExpandStateChange?(isExpanded)
    }
    
    @objc private func didTapActionButton() {
        onButtonAction?()
    }

    // MARK: - Configure
    
    func configure(text: String,
                   buttonText: String,
                   icon: UIImage?,
                   onButtonAction: @escaping () -> Void) {
        self.onButtonAction = onButtonAction
        
        self.text = text
        titleLabel.attributedText = makeAttributedText(from: text)
        actionButton.setTitle(buttonText, for: .normal)
        
        if let icon {
            let resizedIcon = OAUtilities.resize(icon, newSize: .init(width: Constants.iconSize, height: Constants.iconSize))
            actionButton.setImage(resizedIcon, for: .normal)
        }
    }
    
    private func makeAttributedText(from text: String) -> NSAttributedString {
        if isExpanded || text.count <= maxCollapsedTextLength {
            return NSAttributedString(
                string: text,
                attributes: [
                    .font: UIFont.preferredFont(forTextStyle: .callout),
                    .foregroundColor: UIColor.textColorPrimary
                ]
            )
        }

        let truncatedText = String(text.prefix(maxCollapsedTextLength))

        let result = NSMutableAttributedString(
            string: truncatedText,
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .callout),
                .foregroundColor: UIColor.textColorPrimary
            ]
        )

        result.append(
            NSAttributedString(
                string: localizedString("shared_string_ellipsis"),
                attributes: [
                    .font: UIFont.preferredFont(forTextStyle: .callout),
                    .foregroundColor: UIColor.textColorActive
                ]
            )
        )

        return result
    }
}

extension WikipediaContextMenuView {
    private struct Constants {
        static let buttonHeight: CGFloat = 36
        static let buttonTopOffset: CGFloat = 14
        static let buttonContentInset: NSDirectionalEdgeInsets = .init(top: 6, leading: 12, bottom: 6, trailing: 16)
        
        static let contentInset: NSDirectionalEdgeInsets = .init(top: 14, leading: 20, bottom: 14, trailing: 20)
        
        static let iconSize: CGFloat = 16
    }
}
