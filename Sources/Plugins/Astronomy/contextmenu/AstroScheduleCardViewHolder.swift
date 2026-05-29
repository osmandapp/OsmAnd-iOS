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
        let card = AstroCardContainerView(title: AstroContextMenuLocalizer.label("astronomy_schedule", fallback: "Schedule"),
                                          systemImageName: "calendar")

        let nav = UIStackView()
        nav.axis = .horizontal
        nav.alignment = .center
        nav.spacing = 8

        let prev = UIButton(type: .system)
        prev.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        prev.tintColor = AstroContextMenuTheme.activeIcon
        prev.addAction(UIAction { _ in onShiftPeriod(-AstroScheduleCardController.periodDays) }, for: .touchUpInside)
        let next = UIButton(type: .system)
        next.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        next.tintColor = AstroContextMenuTheme.activeIcon
        next.addAction(UIAction { _ in onShiftPeriod(AstroScheduleCardController.periodDays) }, for: .touchUpInside)
        let range = UILabel()
        range.text = item.rangeLabel
        range.textColor = AstroContextMenuTheme.primaryText
        range.font = .systemFont(ofSize: 20, weight: .semibold)
        range.textAlignment = .center
        nav.addArrangedSubview(prev)
        nav.addArrangedSubview(range)
        nav.addArrangedSubview(next)
        prev.widthAnchor.constraint(equalToConstant: 36).isActive = true
        next.widthAnchor.constraint(equalToConstant: 36).isActive = true
        card.stack.addArrangedSubview(nav)

        if item.showResetPeriodButton {
            let reset = UIButton(type: .system)
            reset.setTitle(AstroContextMenuLocalizer.label("astro_schedule_show_current_week", fallback: "Show current week"), for: .normal)
            reset.tintColor = AstroContextMenuTheme.activeIcon
            reset.setTitleColor(AstroContextMenuTheme.activeText, for: .normal)
            reset.addAction(UIAction { _ in onResetPeriod() }, for: .touchUpInside)
            card.stack.addArrangedSubview(reset)
        }

        if item.days.contains(where: { $0.setDayOffset > 0 }) {
            let note = UILabel()
            note.text = AstroContextMenuLocalizer.label("astro_schedule_next_day_note", fallback: "+1 means the set time is on the next day")
            note.textColor = AstroContextMenuTheme.secondaryText
            note.font = .systemFont(ofSize: 15)
            note.numberOfLines = 0
            card.stack.addArrangedSubview(note)
        }

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
        card.stack.addArrangedSubview(daysStack)
        return card
    }

    private static func dayRow(_ day: AstroScheduleDayItem, showDivider: Bool, onTap: @escaping () -> Void) -> UIView {
        let control = UIControl()
        control.addAction(UIAction { _ in onTap() }, for: .touchUpInside)

        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 8
        row.translatesAutoresizingMaskIntoConstraints = false
        control.addSubview(row)

        let dayLabel = UILabel()
        dayLabel.text = day.dayLabel
        dayLabel.textColor = AstroContextMenuTheme.primaryText
        dayLabel.font = .systemFont(ofSize: 17, weight: .regular)
        dayLabel.adjustsFontSizeToFitWidth = true
        dayLabel.minimumScaleFactor = 0.75
        dayLabel.widthAnchor.constraint(equalToConstant: 72).isActive = true
        row.addArrangedSubview(dayLabel)

        row.addArrangedSubview(timeBlock(time: day.riseTime, arrow: riseArrow))

        let graph = AstroScheduleGraphView()
        graph.submitModel(day.graph)
        graph.setContentHuggingPriority(.defaultLow, for: .horizontal)
        graph.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        graph.widthAnchor.constraint(greaterThanOrEqualToConstant: 72).isActive = true
        graph.heightAnchor.constraint(equalToConstant: 30).isActive = true
        row.addArrangedSubview(graph)
        row.addArrangedSubview(timeBlock(time: day.setTime, arrow: setArrow, suffix: nextDaySuffix(day.setDayOffset)))

        let divider = UIView()
        divider.backgroundColor = AstroContextMenuTheme.separator
        divider.isHidden = !showDivider
        divider.translatesAutoresizingMaskIntoConstraints = false
        control.addSubview(divider)

        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: control.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: control.trailingAnchor),
            row.topAnchor.constraint(equalTo: control.topAnchor, constant: 12),
            row.bottomAnchor.constraint(equalTo: control.bottomAnchor, constant: -12),
            divider.leadingAnchor.constraint(equalTo: control.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: control.trailingAnchor),
            divider.bottomAnchor.constraint(equalTo: control.bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1)
        ])
        return control
    }

    private static func placeholderRow(showDivider: Bool) -> UIView {
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: 54).isActive = true
        view.alpha = 0
        return view
    }

    private static func timeBlock(time: String?, arrow: String, suffix: String? = nil) -> UIView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 4
        stack.widthAnchor.constraint(equalToConstant: 76).isActive = true

        let arrowLabel = UILabel()
        arrowLabel.text = arrow
        arrowLabel.textColor = AstroContextMenuTheme.secondaryText
        arrowLabel.font = .systemFont(ofSize: 11, weight: .bold)
        let timeLabel = UILabel()
        timeLabel.attributedText = buildTimeText(time: time, suffix: suffix)
        timeLabel.textColor = AstroContextMenuTheme.primaryText
        timeLabel.font = .systemFont(ofSize: 17, weight: .regular)
        timeLabel.adjustsFontSizeToFitWidth = true
        timeLabel.minimumScaleFactor = 0.7
        stack.addArrangedSubview(arrowLabel)
        stack.addArrangedSubview(timeLabel)
        return stack
    }

    private static func buildTimeText(time: String?, suffix: String?) -> NSAttributedString {
        let parts = splitTimeParts(time)
        guard parts.main != emptyTime else {
            return NSAttributedString(string: emptyTime, attributes: [.foregroundColor: AstroContextMenuTheme.primaryText])
        }
        let result = NSMutableAttributedString(string: parts.main, attributes: [.foregroundColor: AstroContextMenuTheme.primaryText])
        if let meridiem = parts.meridiem, !meridiem.isEmpty {
            result.append(NSAttributedString(string: " "))
            result.append(NSAttributedString(string: meridiem, attributes: [
                .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                .foregroundColor: AstroContextMenuTheme.secondaryText
            ]))
        }
        if let suffix, !suffix.isEmpty {
            result.append(NSAttributedString(string: suffix, attributes: [
                .font: UIFont.systemFont(ofSize: 8, weight: .medium),
                .foregroundColor: AstroContextMenuTheme.primaryText,
                .baselineOffset: 5
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
