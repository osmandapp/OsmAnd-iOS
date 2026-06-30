//
//  StarMapSearchEmptyView.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 27.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

enum StarMapSearchEmptyConfig {
    case searchNoResults
    case myDataFavorites
    case myDataDailyPath
    case myDataDirections

    var iconName: String {
        switch self {
        case .searchNoResults:
            return "ic_custom_search"
        case .myDataFavorites:
            return "ic_custom_bookmark_outlined"
        case .myDataDirections:
            return "ic_custom_target_direction_off"
        case .myDataDailyPath:
            return "ic_custom_target_path_off"
        }
    }

    var title: String {
        switch self {
        case .searchNoResults:
            return localizedString("nothing_found")
        case .myDataFavorites:
            return localizedString("astro_my_data_no_favorites_title")
        case .myDataDailyPath:
            return localizedString("astro_my_data_no_daily_paths_title")
        case .myDataDirections:
            return localizedString("astro_my_data_no_directions_title")
        }
    }

    var description: String {
        switch self {
        case .searchNoResults:
            return localizedString("astro_search_empty_description")
        case .myDataFavorites:
            return localizedString("astro_my_data_no_favorites_description")
        case .myDataDailyPath:
            return localizedString("astro_my_data_no_daily_paths_description")
        case .myDataDirections:
            return localizedString("astro_my_data_no_directions_description")
        }
    }

    var actionTitle: String {
        switch self {
        case .searchNoResults:
            return localizedString("shared_string_reset")
        case .myDataFavorites, .myDataDailyPath, .myDataDirections:
            return localizedString("astro_go_to_map")
        }
    }
}

final class StarMapSearchEmptyView: UIView {

    private enum Layout {
        static let contentPadding: CGFloat = 30
        static let textSpacing: CGFloat = 8
        static let iconSize: CGFloat = 60
        static let buttonHeight: CGFloat = 44
        static let buttonPadding: CGFloat = 20
        static let buttonCornerRadius: CGFloat = 9
        static let cornerRadius: CGFloat = 26
    }

    var onAction: (() -> Void)?

    private let containerStack = UIStackView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with config: StarMapSearchEmptyConfig) {
        iconView.image = AstroIcon.template(config.iconName)
        titleLabel.text = config.title
        descriptionLabel.text = config.description
        actionButton.setTitle(config.actionTitle, for: .normal)
    }

    private func setupView() {
        backgroundColor = .groupBg
        cornerRadius = Layout.cornerRadius
        
        containerStack.axis = .vertical
        containerStack.alignment = .center
        containerStack.spacing = Layout.textSpacing
        containerStack.backgroundColor = .clear
        containerStack.layoutMargins = UIEdgeInsets(
            top: Layout.contentPadding,
            left: Layout.contentPadding,
            bottom: Layout.buttonPadding,
            right: Layout.contentPadding
        )
        containerStack.isLayoutMarginsRelativeArrangement = true
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStack)

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = .iconColorDefault

        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .textColorPrimary

        descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
        descriptionLabel.adjustsFontForContentSizeCategory = true
        descriptionLabel.textColor = .textColorSecondary
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center

        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.addTarget(self, action: #selector(actionPressed), for: .touchUpInside)

        var configuration = UIButton.Configuration.filled()
        configuration.cornerStyle = .small
        configuration.baseBackgroundColor = .buttonBgColorTertiary
        configuration.baseForegroundColor = .buttonTextColorSecondary
        configuration.background.cornerRadius = Layout.buttonCornerRadius
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .subheadline)
            return outgoing
        }
        actionButton.configuration = configuration

        containerStack.addArrangedSubview(iconView)
        containerStack.addArrangedSubview(titleLabel)
        containerStack.addArrangedSubview(descriptionLabel)
        containerStack.addArrangedSubview(actionButton)
        
        containerStack.setCustomSpacing(Layout.contentPadding, after: iconView)
        containerStack.setCustomSpacing(Layout.buttonPadding, after: descriptionLabel)

        NSLayoutConstraint.activate([
            containerStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStack.topAnchor.constraint(equalTo: topAnchor),
            containerStack.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconView.heightAnchor.constraint(equalToConstant: Layout.iconSize),
            iconView.widthAnchor.constraint(equalToConstant: Layout.iconSize),

            actionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.buttonHeight),
            actionButton.widthAnchor.constraint(
                equalTo: containerStack.widthAnchor,
                constant: -2 * Layout.contentPadding
            )
        ])
    }

    @objc private func actionPressed() {
        onAction?()
    }
}
