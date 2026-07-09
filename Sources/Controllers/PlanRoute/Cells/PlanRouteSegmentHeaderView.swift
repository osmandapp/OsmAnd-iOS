//
//  PlanRouteSegmentHeaderView.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class PlanRouteSegmentHeaderView: UITableViewHeaderFooterView {
    static let reuseId = "PlanRouteSegmentHeaderView"

    private static let optionsButtonSize: CGFloat = 44

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

    func configure(title: String, subtitle: String?, menu: UIMenu?) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle?.isEmpty ?? true
        optionsButton.menu = menu
        optionsButton.isHidden = menu == nil
    }

    private func setupView() {
        titleLabel.font = .scaledSystemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .textColorPrimary
        titleLabel.numberOfLines = 1

        subtitleLabel.font = .scaledSystemFont(ofSize: 15)
        subtitleLabel.textColor = .textColorSecondary
        subtitleLabel.numberOfLines = 1

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        var configuration = UIButton.Configuration.plain()
        configuration.title = "⋯"
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var updated = attributes
            updated.font = .systemFont(ofSize: 17, weight: .bold)
            return updated
        }
        configuration.baseForegroundColor = .buttonAccentsBlue
        configuration.background.image = .blueCircleFill
        configuration.contentInsets = .zero
        optionsButton.configuration = configuration
        optionsButton.showsMenuAsPrimaryAction = true

        [textStack, optionsButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            optionsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            optionsButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            optionsButton.leadingAnchor.constraint(greaterThanOrEqualTo: textStack.trailingAnchor, constant: 12),
            optionsButton.widthAnchor.constraint(equalToConstant: Self.optionsButtonSize),
            optionsButton.heightAnchor.constraint(equalToConstant: Self.optionsButtonSize)
        ])
    }
}
