//
//  AstroVisibilityCardViewHolder.swift
//  OsmAnd Maps
//
//  Ported from Android AstroVisibilityCardViewHolder.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

enum AstroVisibilityCardViewHolder {
    static func makeView(item: AstroVisibilityCardItem,
                         onResetToToday: @escaping () -> Void,
                         onCursorTimeChanged: @escaping (Int64) -> Void) -> UIView {
        let card = AstroCardContainerView()

        let header = UIStackView()
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8
        let title = UILabel()
        title.text = item.titleText
        title.textColor = AstroContextMenuTheme.primaryText
        title.font = .systemFont(ofSize: 20, weight: .bold)
        title.numberOfLines = 0
        header.addArrangedSubview(title)
        if item.showResetButton {
            let resetButton = UIButton(type: .system)
            resetButton.setImage(UIImage(systemName: "calendar.badge.clock"), for: .normal)
            resetButton.tintColor = AstroContextMenuTheme.activeIcon
            resetButton.accessibilityLabel = localizedString("astro_visibility_show_today")
            resetButton.addAction(UIAction { _ in onResetToToday() }, for: .touchUpInside)
            resetButton.widthAnchor.constraint(equalToConstant: 36).isActive = true
            resetButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
            header.addArrangedSubview(resetButton)
        }
        card.stack.addArrangedSubview(header)

        let graphView = AstroVisibilityGraphView()
        graphView.translatesAutoresizingMaskIntoConstraints = false
        graphView.heightAnchor.constraint(equalToConstant: 270).isActive = true
        graphView.submitGraph(item.graph, cursorReferenceTimeMillis: item.cursorReferenceTimeMillis)
        graphView.onCursorTimeChanged = onCursorTimeChanged
        card.stack.addArrangedSubview(graphView)

        let events = UIStackView()
        events.axis = .horizontal
        events.alignment = .fill
        events.distribution = .fillEqually
        events.spacing = 6
        addEvent(to: events,
                 time: item.riseTime,
                 symbol: "▲",
                 title: localizedString("astro_rise"),
                 symbolColor: AstroContextMenuTheme.activeIcon)
        addEvent(to: events,
                 time: item.culminationTime,
                 symbol: "●",
                 title: localizedString("astro_culmination"),
                 symbolColor: item.culminationColor)
        addEvent(to: events,
                 time: item.setTime,
                 symbol: "▼",
                 title: localizedString("astro_set"),
                 symbolColor: AstroContextMenuTheme.activeIcon)
        if !events.arrangedSubviews.isEmpty {
            card.stack.addArrangedSubview(events)
        }

        if !item.locationText.isEmpty {
            let location = UILabel()
            location.text = item.locationText
            location.textColor = AstroContextMenuTheme.secondaryText
            location.font = .systemFont(ofSize: 17)
            location.numberOfLines = 0
            let row = UIStackView(arrangedSubviews: [UIImageView(image: UIImage(systemName: "location")), location])
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 7
            (row.arrangedSubviews.first as? UIImageView)?.tintColor = AstroContextMenuTheme.secondaryIcon
            row.arrangedSubviews.first?.widthAnchor.constraint(equalToConstant: 16).isActive = true
            card.stack.addArrangedSubview(row)
        }
        return card
    }

    private static func addEvent(to stack: UIStackView,
                                 time: String?,
                                 symbol: String,
                                 title: String,
                                 symbolColor: UIColor) {
        guard let time, !time.isEmpty else {
            return
        }
        let block = UIStackView()
        block.axis = .vertical
        block.alignment = .center
        block.spacing = 3
        let symbolLabel = UILabel()
        symbolLabel.text = symbol
        symbolLabel.textColor = symbolColor
        symbolLabel.font = .systemFont(ofSize: 14, weight: .bold)
        let timeLabel = UILabel()
        timeLabel.text = time
        timeLabel.textColor = AstroContextMenuTheme.activeText
        timeLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        timeLabel.adjustsFontSizeToFitWidth = true
        timeLabel.minimumScaleFactor = 0.75
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = AstroContextMenuTheme.secondaryText
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        block.addArrangedSubview(symbolLabel)
        block.addArrangedSubview(timeLabel)
        block.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(block)
    }
}
