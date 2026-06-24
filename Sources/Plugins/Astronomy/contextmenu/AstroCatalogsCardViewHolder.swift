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
        let card = AstroCardContainerView(title: localizedString("astro_designations"))
        let chips = WrappingChipsView()
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
        card.stack.addArrangedSubview(chips)
        return card
    }
}

final class WrappingChipsView: UIView {
    private var chips: [UIButton] = []

    func addChip(title: String, action: @escaping () -> Void) {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = AstroContextMenuTheme.actionBackground
        config.baseForegroundColor = AstroContextMenuTheme.activeText
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14)
            outgoing.foregroundColor = AstroContextMenuTheme.activeText
            return outgoing
        }
        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 19
        button.layer.masksToBounds = true
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        chips.append(button)
        addSubview(button)
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: layoutHeight(for: bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width - 64))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        _ = layoutHeight(for: bounds.width, apply: true)
    }

    private func layoutHeight(for width: CGFloat, apply: Bool = false) -> CGFloat {
        guard width > 0 else {
            return 0
        }
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        let spacing: CGFloat = 10
        for chip in chips {
            let size = chip.sizeThatFits(CGSize(width: width, height: 38))
            let chipSize = CGSize(width: min(width, ceil(size.width)), height: 38)
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
