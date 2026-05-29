//
//  MetricsAdapter.swift
//  OsmAnd Maps
//
//  Ported from Android MetricsAdapter.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

final class MetricsAdapter {
    struct MetricUi {
        let value: String
        let label: String
    }

    private(set) var currentList: [MetricUi] = []

    func submit(_ list: [MetricUi]) {
        currentList = list
    }

    func makeMetricsView() -> UIView {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])

        for (index, item) in currentList.enumerated() {
            let view = MetricView()
            view.bind(item, showDivider: index != currentList.indices.last)
            stack.addArrangedSubview(view)
        }
        return scrollView
    }
}

private final class MetricView: UIView {
    private let valueLabel = UILabel()
    private let titleLabel = UILabel()
    private let divider = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(_ item: MetricsAdapter.MetricUi, showDivider: Bool) {
        valueLabel.text = item.value
        titleLabel.text = item.label
        divider.isHidden = !showDivider
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(greaterThanOrEqualToConstant: 112).isActive = true

        let stack = UIStackView(arrangedSubviews: [valueLabel, titleLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false

        valueLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        valueLabel.textColor = AstroContextMenuTheme.activeText
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.8

        titleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        titleLabel.textColor = AstroContextMenuTheme.secondaryText

        divider.backgroundColor = AstroContextMenuTheme.separator
        divider.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        addSubview(divider)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 7),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -7),

            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.centerYAnchor.constraint(equalTo: centerYAnchor),
            divider.widthAnchor.constraint(equalToConstant: 1),
            divider.heightAnchor.constraint(equalToConstant: 34)
        ])
    }
}
