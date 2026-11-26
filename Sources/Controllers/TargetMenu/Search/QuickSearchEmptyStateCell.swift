//
//  QuickSearchEmptyStateCell.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class QuickSearchEmptyStateListItem: OAQuickSearchEmptyResultListItem {
    let query: String
    let radius: String?
    let onIncreaseRadius: (() -> Void)?
    let onClearFilters: (() -> Void)?

    init(query: String, radius: String?, onIncreaseRadius: (() -> Void)?, onClearFilters: (() -> Void)?) {
        self.query = query
        self.radius = radius
        self.onIncreaseRadius = onIncreaseRadius
        self.onClearFilters = onClearFilters
        super.init()
    }
}

final class QuickSearchEmptyStateCell: UITableViewCell {
    private static let horizontalInset: CGFloat = 16
    private static let topInset: CGFloat = 30
    private static let bottomInset: CGFloat = 30
    private static let buttonsBottomInset: CGFloat = 16
    private static let iconSize: CGFloat = 60
    private static let iconSpacing: CGFloat = 30
    private static let titleSpacing: CGFloat = 6
    private static let textSpacing: CGFloat = 20
    private static let buttonSpacing: CGFloat = 16
    private static let buttonHeight: CGFloat = 44
    private static let buttonCornerRadius: CGFloat = 10
    private static let titleFontSize: CGFloat = 17
    private static let descriptionFontSize: CGFloat = 15
    private static let descriptionLineSpacing: CGFloat = 2

    private let stackView = UIStackView()
    private let iconView = UIImageView(image: .icCustomSearch)
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let increaseRadiusButton = UIButton(type: .system)
    private let clearFiltersButton = UIButton(type: .system)
    private var bottomConstraint: NSLayoutConstraint?
    private var onIncreaseRadius: (() -> Void)?
    private var onClearFilters: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    func configure(with item: QuickSearchEmptyStateListItem) {
        titleLabel.attributedText = Self.titleText(for: item.query)
        let description = item.radius.map { String(format: localizedString("search_nothing_found_within_radius"), $0) }
        descriptionLabel.attributedText = description.map(Self.descriptionText)
        descriptionLabel.isHidden = description == nil
        onIncreaseRadius = item.onIncreaseRadius
        onClearFilters = item.onClearFilters
        increaseRadiusButton.isHidden = item.onIncreaseRadius == nil
        clearFiltersButton.isHidden = item.onClearFilters == nil
        stackView.setCustomSpacing(description == nil ? Self.textSpacing : Self.titleSpacing, after: titleLabel)
        let hasButtons = item.onIncreaseRadius != nil || item.onClearFilters != nil
        bottomConstraint?.constant = -(hasButtons ? Self.buttonsBottomInset : Self.bottomInset)
    }

    private func setupView() {
        selectionStyle = .none
        backgroundConfiguration = PointContentConfiguration.backgroundConfiguration()

        iconView.tintColor = .iconColorSecondary
        iconView.contentMode = .scaleAspectFit

        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0

        configureButton(increaseRadiusButton, title: localizedString("increase_radius"), filled: true)
        increaseRadiusButton.addAction(UIAction { [weak self] _ in
            self?.onIncreaseRadius?()
        }, for: .touchUpInside)
        configureButton(clearFiltersButton, title: localizedString("shared_string_clear_filters"), filled: false)
        clearFiltersButton.addAction(UIAction { [weak self] _ in
            self?.onClearFilters?()
        }, for: .touchUpInside)

        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        [iconView, titleLabel, descriptionLabel, increaseRadiusButton, clearFiltersButton].forEach(stackView.addArrangedSubview)
        stackView.setCustomSpacing(Self.iconSpacing, after: iconView)
        stackView.setCustomSpacing(Self.textSpacing, after: descriptionLabel)
        stackView.setCustomSpacing(Self.buttonSpacing, after: increaseRadiusButton)
        contentView.addSubview(stackView)

        let bottomConstraint = stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Self.buttonsBottomInset)
        self.bottomConstraint = bottomConstraint
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Self.topInset),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.horizontalInset),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Self.horizontalInset),
            bottomConstraint,
            iconView.heightAnchor.constraint(equalToConstant: Self.iconSize),
            increaseRadiusButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.buttonHeight),
            clearFiltersButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.buttonHeight)
        ])
    }

    private func configureButton(_ button: UIButton, title: String, filled: Bool) {
        var configuration: UIButton.Configuration = filled ? .filled() : .plain()
        configuration.title = title
        configuration.baseForegroundColor = .buttonTextColorSecondary
        if filled {
            configuration.baseBackgroundColor = .buttonBgColorTertiary
        }
        configuration.cornerStyle = .fixed
        configuration.background.cornerRadius = Self.buttonCornerRadius
        configuration.titleLineBreakMode = .byTruncatingTail
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = UIFont.scaledSystemFont(ofSize: Self.titleFontSize)
            return attributes
        }
        button.configuration = configuration
    }

    private static func titleText(for query: String) -> NSAttributedString {
        let text = String(format: localizedString("search_no_results_for"), query)
        let attributedText = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.scaledSystemFont(ofSize: titleFontSize),
            .foregroundColor: UIColor.textColorPrimary
        ])
        let queryRange = (text as NSString).range(of: query, options: .backwards)
        if queryRange.location != NSNotFound, !query.isEmpty {
            attributedText.addAttribute(.font, value: UIFont.scaledSystemFont(ofSize: titleFontSize, weight: .semibold), range: queryRange)
        }
        return attributedText
    }

    private static func descriptionText(_ text: String) -> NSAttributedString {
        let font = UIFont.scaledSystemFont(ofSize: descriptionFontSize)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.minimumLineHeight = font.lineHeight + descriptionLineSpacing
        paragraphStyle.maximumLineHeight = font.lineHeight + descriptionLineSpacing
        return NSAttributedString(string: text, attributes: [
            .font: font,
            .foregroundColor: UIColor.textColorSecondary,
            .paragraphStyle: paragraphStyle
        ])
    }
}
