//
//  DateTimeSelectionView.swift
//  OsmAnd Maps
//
//  Created by Codex on 20.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

final class DateTimeSelectionView: UIView {
    private enum Field: Hashable {
        case year
        case month
        case day
        case hour
        case minute
    }

    private var currentDate = Date()
    private var onDateTimeChangeListener: ((Date) -> Void)?
    private let calendar = Calendar.current
    private var labels: [Field: UILabel] = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initViews()
    }

    private func initViews() {
        backgroundColor = UIColor.black.withAlphaComponent(0.67)
        layer.cornerRadius = 0
        layer.shadowOpacity = 0

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 4
        stack.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        addColumn(.year, to: stack)
        addColumn(.month, to: stack)
        addColumn(.day, to: stack)
        stack.setCustomSpacing(8, after: stack.arrangedSubviews[2])
        addColumn(.hour, to: stack)
        addColumn(.minute, to: stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        updateDisplay()
    }

    private func addColumn(_ field: Field, to parent: UIStackView) {
        let column = UIStackView()
        column.axis = .vertical
        column.alignment = .center
        column.spacing = 2

        let up = makeStepButton(iconName: "ic_action_arrow_up")
        up.addAction(UIAction { [weak self] _ in self?.step(field, amount: field == .minute ? 5 : 1) }, for: .touchUpInside)
        column.addArrangedSubview(up)

        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center
        label.widthAnchor.constraint(greaterThanOrEqualToConstant: field == .year ? 52 : 32).isActive = true
        labels[field] = label
        column.addArrangedSubview(label)

        let down = makeStepButton(iconName: "ic_action_arrow_down")
        down.addAction(UIAction { [weak self] _ in self?.step(field, amount: field == .minute ? -5 : -1) }, for: .touchUpInside)
        column.addArrangedSubview(down)

        parent.addArrangedSubview(column)
    }

    private func makeStepButton(iconName: String) -> UIButton {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.setImage(AstroIcon.template(iconName), for: .normal)
        button.widthAnchor.constraint(equalToConstant: 40).isActive = true
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return button
    }

    private func step(_ field: Field, amount: Int) {
        let component: Calendar.Component
        switch field {
        case .year:
            component = .year
        case .month:
            component = .month
        case .day:
            component = .day
        case .hour:
            component = .hour
        case .minute:
            component = .minute
        }
        if let date = calendar.date(byAdding: component, value: amount, to: currentDate) {
            currentDate = date
            updateDisplay()
            onDateTimeChangeListener?(currentDate)
        }
    }

    private func updateDisplay() {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: currentDate)
        labels[.year]?.text = String(format: "%04d", components.year ?? 0)
        labels[.month]?.text = String(format: "%02d", components.month ?? 0)
        labels[.day]?.text = String(format: "%02d", components.day ?? 0)
        labels[.hour]?.text = String(format: "%02d", components.hour ?? 0)
        labels[.minute]?.text = String(format: "%02d", components.minute ?? 0)
    }

    func setOnDateTimeChangeListener(_ listener: @escaping (Date) -> Void) {
        onDateTimeChangeListener = listener
    }

    func setDateTime(_ date: Date) {
        currentDate = date
        updateDisplay()
    }

    func getDateTime() -> Date {
        currentDate
    }
}
