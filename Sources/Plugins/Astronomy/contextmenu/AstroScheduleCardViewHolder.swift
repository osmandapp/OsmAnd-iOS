//
//  AstroScheduleCardViewHolder.swift
//  OsmAnd Maps
//
//  Ported from Android AstroScheduleCardViewHolder.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

enum AstroScheduleCardViewHolder {
    private static let riseArrow = "▲"
    private static let setArrow = "▼"
    private static let emptyTime = "—"

    static func makeView(item: AstroScheduleCardItem,
                         onResetPeriod: @escaping () -> Void,
                         onShiftPeriod: @escaping (Int) -> Void,
                         onSelectDate: @escaping (Date) -> Void) -> UIView {
        let headerLabel = UILabel()
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = localizedString("astronomy_schedule")
        headerLabel.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold))
        headerLabel.adjustsFontForContentSizeCategory = true
        headerLabel.textColor = AstroContextMenuTheme.secondaryText
        
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
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = AstroContextMenuTheme.cardBackground
        card.layer.cornerRadius = 26
        card.layer.masksToBounds = true

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(contentStack)
        
        let divider = UIView()
        divider.backgroundColor = AstroContextMenuTheme.separator
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true

        let headerCardView = header(item: item,
                                    onResetPeriod: onResetPeriod,
                                    onShiftPeriod: onShiftPeriod)
        contentStack.addArrangedSubview(headerCardView)

        let daysStack = UIStackView()
        daysStack.axis = .vertical
        daysStack.spacing = 0
        for index in 0..<AstroScheduleCardController.periodDays {
            if let day = item.days[safe: index] {
                daysStack.addArrangedSubview(dayRow(day, showDivider: index != AstroScheduleCardController.periodDays - 1) {
                    onSelectDate(day.date)
                })
            } else {
                daysStack.addArrangedSubview(placeholderRow(showDivider: index != AstroScheduleCardController.periodDays - 1))
            }
        }
        contentStack.setCustomSpacing(12, after: headerCardView)
        contentStack.addArrangedSubview(divider)
        contentStack.addArrangedSubview(daysStack)
        
        let mainStack = UIStackView(arrangedSubviews: [headerView, card])
        mainStack.axis = .vertical
        mainStack.spacing = 10
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        if item.days.contains(where: { $0.setDayOffset > 0 }) {
            let noteContainer = UIView()
            let note = UILabel()
            note.translatesAutoresizingMaskIntoConstraints = false
            note.text = localizedString("astro_schedule_next_day_note")
            note.textColor = AstroContextMenuTheme.secondaryText
            note.font = .systemFont(ofSize: 14)
            note.numberOfLines = 0
            noteContainer.addSubview(note)
            NSLayoutConstraint.activate([
                note.leadingAnchor.constraint(equalTo: noteContainer.leadingAnchor, constant: 16),
                note.trailingAnchor.constraint(equalTo: noteContainer.trailingAnchor, constant: -16),
                note.topAnchor.constraint(equalTo: noteContainer.topAnchor),
                note.bottomAnchor.constraint(equalTo: noteContainer.bottomAnchor)
            ])
            mainStack.setCustomSpacing(4, after: card)
            mainStack.addArrangedSubview(noteContainer)
        }

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        return mainStack
    }

    private static func header(item: AstroScheduleCardItem,
                               onResetPeriod: @escaping () -> Void,
                               onShiftPeriod: @escaping (Int) -> Void) -> UIView {
        let header = UIStackView()
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8
        header.isLayoutMarginsRelativeArrangement = true
        header.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        let range = UILabel()
        range.text = item.rangeLabel
        range.textColor = AstroContextMenuTheme.primaryText
        range.font = .preferredFont(forTextStyle: .headline)
        range.adjustsFontForContentSizeCategory = true

        let buttons = UIStackView()
        buttons.axis = .horizontal
        buttons.alignment = .center
        buttons.spacing = 6
        buttons.setContentHuggingPriority(.required, for: .horizontal)
        buttons.setContentCompressionResistancePriority(.required, for: .horizontal)

        let resetIconName: String
        if #available(iOS 26.0, *) {
            let day = Calendar.current.component(.day, from: Date())
            resetIconName = "\(day).calendar"
        } else {
            resetIconName = "calendar"
        }
        
        let reset = iconButton(name: resetIconName,
                               accessibilityLabel: localizedString("astro_schedule_show_current_week")) {
            onResetPeriod()
        }
        reset.isHidden = !item.showResetPeriodButton
        let prev = iconButton(name: "arrow.left",
                              accessibilityLabel: localizedString("shared_string_previous")) {
            onShiftPeriod(-AstroScheduleCardController.periodDays)
        }
        let next = iconButton(name: "arrow.right",
                              accessibilityLabel: localizedString("shared_string_next")) {
            onShiftPeriod(AstroScheduleCardController.periodDays)
        }
        buttons.addArrangedSubview(reset)
        buttons.addArrangedSubview(prev)
        buttons.addArrangedSubview(next)
        buttons.setCustomSpacing(16, after: reset)

        header.addArrangedSubview(range)
        header.addArrangedSubview(buttons)
        return header
    }
    
    private static func iconButton(name: String,
                                   accessibilityLabel: String,
                                   action: @escaping () -> Void) -> UIButton {
        
        let iconConfig = UIImage.SymbolConfiguration(
            font: .preferredFont(forTextStyle: .headline)
        )
        
        let image = UIImage(
            systemName: name,
            withConfiguration: iconConfig
        )?.imageFlippedForRightToLeftLayoutDirection()
        
        var config = UIButton.Configuration.plain()
        config.image = image
        config.contentInsets = .zero
        config.cornerStyle = .capsule
        
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = accessibilityLabel
        
        button.configurationUpdateHandler = { button in
            var config = button.configuration
            
            switch button.state {
            case .disabled:
                config?.baseForegroundColor = .cellButtonIconDisabled
                config?.background.backgroundColor = .cellButtonBg
                
            case .highlighted:
                config?.baseForegroundColor = .cellButtonIcon
                config?.background.backgroundColor = .cellButtonBgPressed
                
            default:
                config?.baseForegroundColor = .cellButtonIcon
                config?.background.backgroundColor = .cellButtonBg
            }
            
            button.configuration = config
        }
        
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 46),
            button.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        return button
    }

    private static func dayRow(_ day: AstroScheduleDayItem, showDivider: Bool, onTap: @escaping () -> Void) -> UIView {
        let control = UIControl()
        control.addAction(UIAction { _ in onTap() }, for: .touchUpInside)

        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        control.addSubview(row)

        let dayLabel = UILabel()
        dayLabel.text = day.dayLabel
        dayLabel.textColor = AstroContextMenuTheme.primaryText
        dayLabel.font = .systemFont(ofSize: 16)
        dayLabel.numberOfLines = 1
        dayLabel.lineBreakMode = .byTruncatingTail
        dayLabel.adjustsFontSizeToFitWidth = true
        dayLabel.minimumScaleFactor = 0.75
        dayLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(dayLabel)

        let riseBlock = timeBlock(time: day.riseTime, arrow: riseArrow, alignment: .trailing)
        row.addSubview(riseBlock)

        let graph = AstroScheduleGraphView()
        graph.translatesAutoresizingMaskIntoConstraints = false
        graph.submitModel(day.graph)
        row.addSubview(graph)

        let setBlock = timeBlock(time: day.setTime,
                                 arrow: setArrow,
                                 suffix: nextDaySuffix(day.setDayOffset),
                                 alignment: .leading)
        row.addSubview(setBlock)

        let divider = UIView()
        divider.backgroundColor = AstroContextMenuTheme.separator
        divider.isHidden = !showDivider
        divider.translatesAutoresizingMaskIntoConstraints = false
        control.addSubview(divider)
        let dividerHeight = divider.heightAnchor.constraint(equalToConstant: showDivider ? 1 : 0)

        NSLayoutConstraint.activate([
            control.heightAnchor.constraint(greaterThanOrEqualToConstant: 56),

            row.leadingAnchor.constraint(equalTo: control.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: control.trailingAnchor, constant: -4),
            row.topAnchor.constraint(equalTo: control.topAnchor),
            row.bottomAnchor.constraint(equalTo: divider.topAnchor),
            row.heightAnchor.constraint(greaterThanOrEqualToConstant: 55),

            dayLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            dayLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            riseBlock.leadingAnchor.constraint(equalTo: dayLabel.trailingAnchor, constant: 6),
            riseBlock.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            riseBlock.widthAnchor.constraint(equalTo: dayLabel.widthAnchor, multiplier: 1.15),

            graph.leadingAnchor.constraint(equalTo: riseBlock.trailingAnchor, constant: 10),
            graph.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            graph.widthAnchor.constraint(equalTo: dayLabel.widthAnchor, multiplier: 1.6),
            graph.heightAnchor.constraint(equalToConstant: 22),

            setBlock.leadingAnchor.constraint(equalTo: graph.trailingAnchor, constant: 10),
            setBlock.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            setBlock.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            setBlock.widthAnchor.constraint(equalTo: dayLabel.widthAnchor, multiplier: 1.35),

            divider.leadingAnchor.constraint(equalTo: control.leadingAnchor, constant: 16),
            divider.trailingAnchor.constraint(equalTo: control.trailingAnchor, constant: -16),
            divider.bottomAnchor.constraint(equalTo: control.bottomAnchor),
            dividerHeight
        ])
        return control
    }

    private static func placeholderRow(showDivider _: Bool) -> UIView {
        let view = UIView()
        view.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true
        view.alpha = 0
        return view
    }

    private enum TimeBlockAlignment {
        case leading
        case trailing
    }

    private static func timeBlock(time: String?,
                                  arrow: String,
                                  suffix: String? = nil,
                                  alignment: TimeBlockAlignment) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        let arrowLabel = UILabel()
        arrowLabel.text = arrow
        arrowLabel.textColor = AstroContextMenuTheme.secondaryText
        arrowLabel.font = .systemFont(ofSize: 12)
        let timeLabel = UILabel()
        timeLabel.attributedText = buildTimeText(time: time, suffix: suffix)
        timeLabel.textColor = AstroContextMenuTheme.secondaryText
        timeLabel.numberOfLines = 1
        timeLabel.adjustsFontSizeToFitWidth = true
        timeLabel.minimumScaleFactor = 0.7
        timeLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        stack.addArrangedSubview(arrowLabel)
        stack.addArrangedSubview(timeLabel)

        let horizontalAnchor: NSLayoutConstraint
        switch alignment {
        case .leading:
            horizontalAnchor = stack.leadingAnchor.constraint(equalTo: container.leadingAnchor)
        case .trailing:
            horizontalAnchor = stack.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        }
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),
            stack.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            horizontalAnchor
        ])
        return container
    }

    private static func buildTimeText(time: String?, suffix: String?) -> NSAttributedString {
        let parts = splitTimeParts(time)
        guard parts.main != emptyTime else {
            return NSAttributedString(string: emptyTime, attributes: [.foregroundColor: AstroContextMenuTheme.secondaryText])
        }
        let result = NSMutableAttributedString(string: parts.main, attributes: [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: AstroContextMenuTheme.secondaryText
        ])
        if let meridiem = parts.meridiem, !meridiem.isEmpty {
            result.append(NSAttributedString(string: " "))
            result.append(NSAttributedString(string: meridiem, attributes: [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: AstroContextMenuTheme.secondaryText
            ]))
        }
        if let suffix, !suffix.isEmpty {
            result.append(NSAttributedString(string: suffix, attributes: [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: AstroContextMenuTheme.secondaryText,
                .baselineOffset: 6
            ]))
        }
        return result
    }

    private static func splitTimeParts(_ time: String?) -> (main: String, meridiem: String?) {
        guard let time,
              !time.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return (emptyTime, nil)
        }
        let tokens = time.split(whereSeparator: { $0.isWhitespace }).map(String.init)
        guard tokens.count > 1 else {
            return (tokens.first ?? emptyTime, nil)
        }
        return (tokens.dropLast().joined(separator: " "), tokens.last)
    }

    private static func nextDaySuffix(_ dayOffset: Int) -> String? {
        dayOffset > 0 ? "+\(dayOffset)" : nil
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
