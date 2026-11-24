//
//  CollapsibleSectionHeaderView.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

final class CollapsibleSectionHeaderView: UITableViewHeaderFooterView {
    private static let verticalInset: CGFloat = 8
    private static let chevronSize: CGFloat = 18
    private static let titleToChevronSpacing: CGFloat = 12

    var fixedHorizontalInsets: NSDirectionalEdgeInsets? {
        didSet {
            guard fixedHorizontalInsets != oldValue else { return }
            updateHorizontalConstraints()
        }
    }

    private let titleLabel = UILabel()
    private let chevronImageView = UIImageView()

    private lazy var marginConstraints = [
        titleLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
        chevronImageView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
    ]
    private lazy var titleLeadingToEdgeConstraint = titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor)
    private lazy var chevronTrailingToEdgeConstraint = chevronImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)

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
            systemName: isExpanded ? "chevron.down" : "chevron.forward",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        )
        if #available(iOS 18.0, *) {
            accessibilityExpandedStatus = isExpanded ? .expanded : .collapsed
        }
    }

    private func setupView() {
        contentView.backgroundColor = .clear
        contentView.preservesSuperviewLayoutMargins = true
        backgroundView = UIView()
        backgroundView?.backgroundColor = .clear

        titleLabel.font = .scaledSystemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .textColorPrimary
        titleLabel.numberOfLines = 0
        titleLabel.adjustsFontForContentSizeCategory = true
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
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Self.verticalInset),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Self.verticalInset),

            chevronImageView.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: Self.titleToChevronSpacing),
            chevronImageView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: Self.chevronSize),
            chevronImageView.heightAnchor.constraint(equalToConstant: Self.chevronSize)
        ]
        (constraints + marginConstraints + [titleLeadingToEdgeConstraint, chevronTrailingToEdgeConstraint]).forEach { $0.priority = UILayoutPriority(999) }
        NSLayoutConstraint.activate(constraints)
        updateHorizontalConstraints()
    }

    private func updateHorizontalConstraints() {
        let edgeConstraints = [titleLeadingToEdgeConstraint, chevronTrailingToEdgeConstraint]
        guard let fixedHorizontalInsets else {
            NSLayoutConstraint.deactivate(edgeConstraints)
            NSLayoutConstraint.activate(marginConstraints)
            return
        }

        titleLeadingToEdgeConstraint.constant = fixedHorizontalInsets.leading
        chevronTrailingToEdgeConstraint.constant = -fixedHorizontalInsets.trailing
        NSLayoutConstraint.deactivate(marginConstraints)
        NSLayoutConstraint.activate(edgeConstraints)
    }

    @objc private func handleTap() {
        onTap?()
    }
}
