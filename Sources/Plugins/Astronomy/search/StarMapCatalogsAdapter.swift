//
//  StarMapCatalogsAdapter.swift
//  OsmAnd Maps
//
//  Created by Codex on 06.06.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

struct StarMapCatalogEntry {
    let catalog: Catalog
    let displayName: String
    let description: String?
    let objectCount: Int
}

final class StarMapCatalogsAdapter: NSObject, UITableViewDataSource, UITableViewDelegate {
    var visibleEntries: [StarMapCatalogEntry]
    private let nightMode: Bool
    private let onScroll: (UIScrollView) -> Void
    private let onCatalogSelected: (StarMapCatalogEntry) -> Void

    init(nightMode: Bool,
         visibleEntries: [StarMapCatalogEntry],
         onScroll: @escaping (UIScrollView) -> Void,
         onCatalogSelected: @escaping (StarMapCatalogEntry) -> Void) {
        self.nightMode = nightMode
        self.visibleEntries = visibleEntries
        self.onScroll = onScroll
        self.onCatalogSelected = onCatalogSelected
        super.init()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        visibleEntries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.reuseIdentifier) as? StarMapCatalogCell
            ?? StarMapCatalogCell(reuseIdentifier: Self.reuseIdentifier)
        bind(cell, entry: visibleEntries[indexPath.row], isLastItem: indexPath.row == visibleEntries.count - 1)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onCatalogSelected(visibleEntries[indexPath.row])
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onScroll(scrollView)
    }

    private func bind(_ cell: StarMapCatalogCell, entry: StarMapCatalogEntry, isLastItem: Bool) {
        cell.configure(icon: AstroIcon.template("ic_action_book_info"),
                       iconTintColor: StarMapSearchLightPalette.defaultIcon,
                       title: entry.displayName,
                       subtitle: entry.description?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                            ? entry.description ?? ""
                            : formatCatalogObjectsCount(entry.objectCount),
                       showDivider: !isLastItem)
    }

    private func formatCatalogObjectsCount(_ count: Int) -> String {
        String.localizedStringWithFormat((localizedString("astro_catalog_objects_count") as NSString) as String, count) as String
    }

    private static let reuseIdentifier = "StarMapCatalogCell"
}

private final class StarMapCatalogCell: UITableViewCell {
    private let rowIconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let dividerView = UIView()

    init(reuseIdentifier: String) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        selectionStyle = .default
        backgroundColor = StarMapSearchLightPalette.listBackground
        contentView.backgroundColor = StarMapSearchLightPalette.listBackground
        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true

        rowIconView.contentMode = .scaleAspectFit
        rowIconView.translatesAutoresizingMaskIntoConstraints = false
        rowIconView.isUserInteractionEnabled = false

        titleLabel.textColor = StarMapSearchLightPalette.primaryText
        titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
        titleLabel.numberOfLines = 1

        subtitleLabel.textColor = StarMapSearchLightPalette.secondaryText
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        subtitleLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.isUserInteractionEnabled = false

        dividerView.backgroundColor = StarMapSearchLightPalette.separator
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.isUserInteractionEnabled = false

        contentView.addSubview(rowIconView)
        contentView.addSubview(textStack)
        contentView.addSubview(dividerView)

        NSLayoutConstraint.activate([
            rowIconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            rowIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rowIconView.widthAnchor.constraint(equalToConstant: 24),
            rowIconView.heightAnchor.constraint(equalToConstant: 24),

            textStack.leadingAnchor.constraint(equalTo: rowIconView.trailingAnchor, constant: 32),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 8),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),

            dividerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 72),
            dividerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            dividerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale)
        ])
    }

    func configure(icon: UIImage?, iconTintColor: UIColor, title: String, subtitle: String, showDivider: Bool) {
        rowIconView.image = icon
        rowIconView.tintColor = iconTintColor
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle.isEmpty
        dividerView.isHidden = !showDivider
    }
}
