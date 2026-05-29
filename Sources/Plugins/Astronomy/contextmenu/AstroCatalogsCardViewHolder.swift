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
        let card = AstroCardContainerView(title: AstroContextMenuLocalizer.label("shared_string_catalogs", fallback: "Catalogs"),
                                          systemImageName: "tag")
        let chips = WrappingChipsView()
        let needShowMore = item.catalogs.count > maxVisible
        let visible = !item.expanded && needShowMore ? Array(item.catalogs.prefix(maxVisible)) : item.catalogs
        visible.forEach { catalog in
            chips.addChip(title: catalog.catalogId.isEmpty ? catalog.name : catalog.catalogId) {
                onCatalogClick(catalog)
            }
        }
        if needShowMore {
            chips.addChip(title: item.expanded
                          ? AstroContextMenuLocalizer.label("shared_string_show_less", fallback: "Show less")
                          : AstroContextMenuLocalizer.label("shared_string_ellipsis", fallback: "...")) {
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
        config.baseBackgroundColor = UIColor(white: 1, alpha: 0.10)
        config.baseForegroundColor = .systemBlue
        config.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 11, bottom: 7, trailing: 11)
        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 14
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        chips.append(button)
        addSubview(button)
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: layoutHeight(for: bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width - 56))
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
        let spacing: CGFloat = 8
        for chip in chips {
            let size = chip.sizeThatFits(CGSize(width: width, height: 32))
            let chipSize = CGSize(width: min(width, max(44, size.width)), height: max(30, size.height))
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

