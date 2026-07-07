//
//  AstroCatalogsCardViewHolder.swift
//  OsmAnd Maps
//
//  Ported from Android AstroCatalogsCardViewHolder.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

enum AstroCatalogsCardViewHolder {
    private static let maxVisible = 5

    static func makeView(item: AstroCatalogsCardItem,
                         onToggleExpanded: @escaping () -> Void,
                         onCatalogClick: @escaping (Catalog) -> Void) -> UIView {

        let headerLabel = UILabel()
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = localizedString("astro_designations")
        headerLabel.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
        headerLabel.adjustsFontForContentSizeCategory = true
        headerLabel.textColor = .textColorSecondary
        
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(headerLabel)
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10),
            headerLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16)
        ])

        let card = UIView()
        card.layer.cornerRadius = 26
        card.clipsToBounds = true
        card.backgroundColor = .groupBg
        card.translatesAutoresizingMaskIntoConstraints = false

        let chips = WrappingChipsView()
        chips.translatesAutoresizingMaskIntoConstraints = false

        let needShowMore = item.catalogs.count > maxVisible
        let visible = !item.expanded && needShowMore ? Array(item.catalogs.prefix(maxVisible)) : item.catalogs
        visible.forEach { catalog in
            chips.addChip(title: catalog.catalogId) {
                onCatalogClick(catalog)
            }
        }
        if needShowMore {
            chips.addChip(title: item.expanded
                          ? localizedString("shared_string_show_less")
                          : localizedString("shared_string_ellipsis")) {
                onToggleExpanded()
            }
        }

        card.addSubview(chips)
        NSLayoutConstraint.activate([
            chips.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            chips.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            chips.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            chips.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])
        
        let stack = UIStackView(arrangedSubviews: [headerView, card])
        stack.axis = .vertical
        stack.spacing = 10
        
        return stack
    }
}

final class WrappingChipsView: UIView {
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: layoutHeight(for: bounds.width))
    }
    
    private var chips: [UIButton] = []

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0 else { return }
        let height = layoutHeight(for: bounds.width, apply: true)
        if abs(bounds.height - height) > 0.5 {
            invalidateIntrinsicContentSize()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    func addChip(title: String, action: @escaping () -> Void) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = .buttonBgColorSecondary
        config.baseForegroundColor = .buttonTextColorSecondary
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        config.background.cornerRadius = 10
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .subheadline)
            outgoing.foregroundColor = .buttonTextColorSecondary
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.layer.masksToBounds = true
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        chips.append(button)
        addSubview(button)
        invalidateIntrinsicContentSize()
    }

    private func layoutHeight(for width: CGFloat, apply: Bool = false) -> CGFloat {
        guard width > 0 else {
            return 0
        }
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        let spacing: CGFloat = 12
        for chip in chips {
            let size = chip.sizeThatFits(CGSize(width: width, height: 36))
            let chipSize = CGSize(width: min(width, ceil(size.width)), height: 36)
            if x > 0 && x + chipSize.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            if apply {
                chip.frame = CGRect(origin: CGPoint(x: x, y: y), size: chipSize)
            }
            x += chipSize.width + spacing
            rowHeight = max(rowHeight, chipSize.height)
        }
        return y + rowHeight
    }
}
