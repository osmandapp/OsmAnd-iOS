//
//  CollapsibleTextWithButtonCell.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 22.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class CollapsibleTextWithButtonCell: UITableViewCell {

    // MARK: - UI

    let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.isUserInteractionEnabled = true
        return label
    }()

    let actionButton: UIButton = {
        let button = UIButton(type: .custom)
        
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.baseForegroundColor = .buttonTextColorSecondary
            config.background.strokeColor = UIColor.buttonOutlineColorSecondary
            config.background.strokeWidth = 1
            config.cornerStyle = .fixed
            config.background.cornerRadius = 8
            
            config.imagePadding = Constants.buttonInset
            config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: Constants.buttonInset, bottom: 0, trailing: Constants.buttonInset)
            button.configuration = config
            
        } else {
            
            button.setTitleColor(.buttonTextColorSecondary, for: .normal)
            
            button.cornerRadius = 8
            button.borderWidth = 1
            button.borderColor = UIColor.buttonOutlineColorSecondary
            
            button.contentHorizontalAlignment = .left;
            button.contentEdgeInsets = .init(top: 0, left: Constants.buttonInset * 1.5,
                                             bottom: 0, right: Constants.buttonInset * 1.5)
            
            button.imageEdgeInsets = .init(top: 0, left: -Constants.buttonInset / 2, bottom: 0, right: Constants.buttonInset / 2)
            button.titleEdgeInsets = .init(top: 0, left: Constants.buttonInset / 2, bottom: 0, right: -Constants.buttonInset / 2)
        }
        
        return button
    }()

    // MARK: - State

    private var text: String = ""
    
    var isExpanded = false
    var maxCollapsedTextLength = 200
    
    private var onButtonAction: (() -> Void)?
    var onCollapseChange: ((_ height: CGFloat) -> Void)?

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        separatorInset = .zero
        contentView.addSubview(titleLabel)
        contentView.addSubview(actionButton)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.contentInset.top),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.contentInset.leading),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.contentInset.trailing),

            actionButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Constants.buttonTopInset),
            actionButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.contentInset.leading),
            actionButton.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -Constants.contentInset.trailing),
            actionButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constants.contentInset.bottom),
            actionButton.heightAnchor.constraint(equalToConstant: Constants.buttonHeight)
        ])
    }

    private func setupActions() {
        actionButton.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
        
        titleLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapText)))
    }
    
    //MARK: - Actions

    @objc private func didTapText() {
        isExpanded.toggle()
        titleLabel.attributedText = makeAttributedText(from: text)
        onCollapseChange?(calculateHeight(in: frame.width))
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
                string: "...",
                attributes: [
                    .font: UIFont.preferredFont(forTextStyle: .callout),
                    .foregroundColor: UIColor.textColorActive
                ]
            )
        )

        return result
    }
    
    func calculateHeight(in width: CGFloat) -> CGFloat {
        let targetSize = CGSizeMake(width, width);

        let size = contentView.systemLayoutSizeFitting(targetSize,
                                                            withHorizontalFittingPriority: .required,
                                                            verticalFittingPriority: .fittingSizeLevel)


        return ceil(size.height)
    }
}

extension CollapsibleTextWithButtonCell {
    private struct Constants {
        
        static let buttonInset: CGFloat = 16
        static let buttonHeight: CGFloat = 36
        static let buttonTopInset: CGFloat = 20
        
        static let contentInset: NSDirectionalEdgeInsets = .init(top: 20, leading: 20, bottom: 16, trailing: 20)
        
        static let iconSize: CGFloat = 20
    }
}
