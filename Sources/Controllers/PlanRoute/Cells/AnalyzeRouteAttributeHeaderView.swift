//
//  AnalyzeRouteAttributeHeaderView.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class AnalyzeRouteAttributeHeaderView: UITableViewHeaderFooterView {

    private let titleLabel = UILabel()
    private let chevronImageView = UIImageView()

    private var onTap: (() -> Void)?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onTap = nil
    }

    func configure(title: String, isExpanded: Bool, onTap: @escaping () -> Void) {
        titleLabel.text = title
        accessibilityLabel = title
        setExpanded(isExpanded)
        self.onTap = onTap
    }

    func setExpanded(_ isExpanded: Bool) {
        chevronImageView.image = UIImage(
            systemName: isExpanded ? "chevron.down" : "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        )
    }

    private func setupView() {
        contentView.backgroundColor = .clear
        backgroundView = UIView()
        backgroundView?.backgroundColor = .clear

        titleLabel.font = .scaledSystemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .textColorPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.tintColor = .iconColorActive
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.isAccessibilityElement = false
        isAccessibilityElement = true
        accessibilityTraits = [.header, .button]

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        contentView.addGestureRecognizer(tap)

        [titleLabel, chevronImageView].forEach { contentView.addSubview($0) }

        let constraints = [
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            chevronImageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -32),
            chevronImageView.widthAnchor.constraint(equalToConstant: 18),
            chevronImageView.heightAnchor.constraint(equalToConstant: 18)
        ]
        constraints.forEach { $0.priority = UILayoutPriority(999) }
        NSLayoutConstraint.activate(constraints)
    }

    @objc private func handleTap() {
        onTap?()
    }
}
