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
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = AstroContextMenuTheme.cardBackground
        card.layer.cornerRadius = 26
        card.layer.masksToBounds = true

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])

        let header = UIStackView()
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8
        header.isLayoutMarginsRelativeArrangement = true
        header.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 0, trailing: item.showResetButton ? 8 : 16)
        
        let title = UILabel()
        title.text = item.titleText
        title.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
        title.adjustsFontForContentSizeCategory = true
        title.textColor = AstroContextMenuTheme.secondaryText
        title.numberOfLines = 0
        header.addArrangedSubview(title)
        
        if item.showResetButton {
            let resetButton = UIButton(type: .system)
            resetButton.setImage(AstroIcon.template("ic_custom_date"), for: .normal)
            resetButton.tintColor = AstroContextMenuTheme.activeIcon
            resetButton.accessibilityLabel = localizedString("astro_visibility_show_today")
            resetButton.addAction(UIAction { _ in onResetToToday() }, for: .touchUpInside)
            resetButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
            resetButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
            header.addArrangedSubview(resetButton)
        }

        let graphView = AstroVisibilityGraphView()
        graphView.translatesAutoresizingMaskIntoConstraints = false
        graphView.heightAnchor.constraint(equalToConstant: 220).isActive = true
        graphView.submitGraph(item.graph, cursorReferenceTimeMillis: item.cursorReferenceTimeMillis)
        graphView.onCursorTimeChanged = onCursorTimeChanged
        stack.addArrangedSubview(graphView)

        let events = UIStackView()
        events.axis = .horizontal
        events.alignment = .fill
        events.distribution = .fill
        events.spacing = 0
        events.isLayoutMarginsRelativeArrangement = true
        events.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 16)
        let rise = makeEvent(time: item.riseTime,
                             symbol: "▲",
                             title: localizedString("astro_rise"),
                             symbolColor: AstroContextMenuTheme.activeIcon)
        let culmination = makeEvent(time: item.culminationTime,
                                    symbol: "●",
                                    title: localizedString("astro_culmination"),
                                    symbolColor: item.culminationColor)
        let set = makeEvent(time: item.setTime,
                            symbol: "▼",
                            title: localizedString("astro_set"),
                            symbolColor: AstroContextMenuTheme.activeIcon)
        let eventViews = [rise, culmination, set].compactMap { $0 }
        if !eventViews.isEmpty {
            if let rise {
                events.addArrangedSubview(rise)
            }
            if rise != nil && culmination != nil {
                events.addArrangedSubview(makeDivider())
            }
            if let culmination {
                events.addArrangedSubview(culmination)
            }
            if culmination != nil && set != nil {
                events.addArrangedSubview(makeDivider())
            }
            if let set {
                events.addArrangedSubview(set)
            }
            eventViews.dropFirst().forEach { $0.widthAnchor.constraint(equalTo: eventViews[0].widthAnchor).isActive = true }
            stack.addArrangedSubview(events)
        }
        
        let mainStack = UIStackView(arrangedSubviews: [header, card])
        mainStack.axis = .vertical
        mainStack.spacing = 10
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        if !item.locationText.isEmpty {
            let location = UILabel()
            location.text = item.locationText
            location.textColor = .textColorSecondary
            location.font = .preferredFont(forTextStyle: .footnote)
            location.numberOfLines = 0
            let iconView = UIImageView(image: .icCustomLocationMarker)
            iconView.tintColor = .textColorSecondary
            iconView.contentMode = .scaleAspectFit
            let row = UIStackView(arrangedSubviews: [iconView, location])
            row.axis = .horizontal
            row.alignment = .center
            row.spacing = 2
            row.isLayoutMarginsRelativeArrangement = true
            row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
            iconView.widthAnchor.constraint(equalToConstant: 20).isActive = true
            iconView.heightAnchor.constraint(equalToConstant: 20).isActive = true
            mainStack.addArrangedSubview(row)
            mainStack.setCustomSpacing(4, after: card)
        }

        return mainStack
    }

    private static func makeEvent(time: String?,
                                  symbol: String,
                                  title: String,
                                  symbolColor: UIColor) -> UIView? {
        guard let time, !time.isEmpty else {
            return nil
        }
        let block = UIStackView()
        block.axis = .vertical
        block.alignment = .leading
        block.spacing = 3
        let valueRow = UIStackView()
        valueRow.axis = .horizontal
        valueRow.alignment = .center
        valueRow.spacing = 6
        let timeLabel = UILabel()
        timeLabel.text = time
        timeLabel.textColor = AstroContextMenuTheme.activeText
        timeLabel.font = .preferredFont(forTextStyle: .subheadline)
        timeLabel.adjustsFontSizeToFitWidth = true
        timeLabel.minimumScaleFactor = 0.75
        let symbolLabel = UILabel()
        symbolLabel.text = symbol
        symbolLabel.textColor = symbolColor
        symbolLabel.font = .preferredFont(forTextStyle: .footnote)
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = .textColorSecondary
        titleLabel.font = .preferredFont(forTextStyle: .footnote)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        valueRow.addArrangedSubview(timeLabel)
        valueRow.addArrangedSubview(symbolLabel)
        block.addArrangedSubview(valueRow)
        block.addArrangedSubview(titleLabel)
        return block
    }

    private static func makeDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = AstroContextMenuTheme.separator
        divider.widthAnchor.constraint(equalToConstant: 1).isActive = true
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(divider)
        divider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wrapper.widthAnchor.constraint(equalToConstant: 17),
            divider.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor),
            divider.topAnchor.constraint(equalTo: wrapper.topAnchor),
            divider.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
        ])
        return wrapper
    }
}
