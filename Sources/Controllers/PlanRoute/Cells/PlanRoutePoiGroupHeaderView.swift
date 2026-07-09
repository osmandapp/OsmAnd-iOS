//
//  PlanRoutePoiGroupHeaderView.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRoutePoiGroupHeaderView: UITableViewHeaderFooterView {
    static let reuseId = "PlanRoutePoiGroupHeaderView"
    private static let buttonSize: CGFloat = 44

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let optionsButton = UIButton(type: .system)

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func makeButtonConfiguration() -> UIButton.Configuration {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "ellipsis")
        configuration.baseForegroundColor = .buttonAccentsBlue
        configuration.background.image = .blueCircleFill
        configuration.contentInsets = .zero
        return configuration
    }

    func configure(title: String, subtitle: String, menu: UIMenu) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        optionsButton.menu = menu
    }

    private func setupView() {
        titleLabel.font = .scaledSystemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .textColorPrimary
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
        subtitleLabel.textColor = .textColorSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.adjustsFontForContentSizeCategory = true
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        optionsButton.configuration = Self.makeButtonConfiguration()
        optionsButton.accessibilityLabel = localizedString("shared_string_options")
        optionsButton.showsMenuAsPrimaryAction = true
        optionsButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        [textStack, optionsButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            optionsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            optionsButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            optionsButton.leadingAnchor.constraint(greaterThanOrEqualTo: textStack.trailingAnchor, constant: 12),
            optionsButton.widthAnchor.constraint(equalToConstant: Self.buttonSize),
            optionsButton.heightAnchor.constraint(equalToConstant: Self.buttonSize)
        ])
    }
}
