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
    struct Snapshot {
        let entries: [StarMapCatalogEntry]

        static let empty = Snapshot(entries: [])
    }
    
    var topInsetHeight: CGFloat = 0

    private var snapshot: Snapshot
    private let onScroll: (UIScrollView) -> Void
    private let onCatalogSelected: (StarMapCatalogEntry) -> Void

    init(tableView: UITableView,
         snapshot: Snapshot,
         onScroll: @escaping (UIScrollView) -> Void,
         onCatalogSelected: @escaping (StarMapCatalogEntry) -> Void) {
        
        self.snapshot = snapshot
        self.onScroll = onScroll
        self.onCatalogSelected = onCatalogSelected
        super.init()
        self.registerCells(for: tableView)
    }

    func submitSnapshot(_ snapshot: Snapshot) {
        self.snapshot = snapshot
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let insetView = UIView()
        insetView.isUserInteractionEnabled = false
        return insetView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        topInsetHeight
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        topInsetHeight
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        snapshot.entries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: StarMapCatalogCell.reuseIdentifier) as? StarMapCatalogCell
            ?? StarMapCatalogCell(reuseIdentifier: StarMapCatalogCell.reuseIdentifier)
        bind(cell, entry: snapshot.entries[indexPath.row], isLastItem: indexPath.row == snapshot.entries.count - 1)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard snapshot.entries.indices.contains(indexPath.row) else {
            return
        }
        onCatalogSelected(snapshot.entries[indexPath.row])
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onScroll(scrollView)
    }
    
    private func registerCells(for tableView: UITableView) {
        tableView.register(StarMapCatalogCell.self, forCellReuseIdentifier: StarMapCatalogCell.reuseIdentifier)
    }

    private func bind(_ cell: StarMapCatalogCell, entry: StarMapCatalogEntry, isLastItem: Bool) {
        cell.configure(icon: .icCustomBookInfo,
                       title: entry.displayName,
                       subtitle: entry.description?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                            ? entry.description ?? ""
                            : formatCatalogObjectsCount(entry.objectCount))
    }

    private func formatCatalogObjectsCount(_ count: Int) -> String {
        String.localizedStringWithFormat((localizedString("astro_catalog_objects_count") as NSString) as String, count) as String
    }
}

private final class StarMapCatalogCell: UITableViewCell {
    private enum Layout {
        static let contentPadding: CGFloat = 16
        static let iconSize: CGFloat = 30
        static let iconTextSpacing: CGFloat = 16
        static var separatorLeadingInset: CGFloat {
            contentPadding + iconSize + iconTextSpacing
        }
    }

    private let rowIconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let textStack = UIStackView()
    private let rowStack = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setup()
    }

    init(reuseIdentifier: String) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func configure(icon: UIImage?, title: String, subtitle: String) {
        rowIconView.image = icon
        rowIconView.tintColor = .iconColorActive
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle.isEmpty
    }

    private func setup() {
        selectionStyle = .default
        accessoryType = .disclosureIndicator
        backgroundColor = .groupBg
        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 68).isActive = true

        rowIconView.contentMode = .scaleAspectFit
        rowIconView.tintColor = .iconColorActive
        rowIconView.isUserInteractionEnabled = false
        rowIconView.setContentHuggingPriority(.required, for: .horizontal)
        rowIconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        titleLabel.textColor = .textColorPrimary
        titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 1

        subtitleLabel.textColor = .textColorSecondary
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.numberOfLines = 2

        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.isUserInteractionEnabled = false
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = Layout.iconTextSpacing
        rowStack.isUserInteractionEnabled = false
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        rowStack.addArrangedSubview(rowIconView)
        rowStack.addArrangedSubview(textStack)

        contentView.addSubview(rowStack)

        NSLayoutConstraint.activate([
            rowStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.contentPadding),
            rowStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.contentPadding),
            rowStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rowStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 8),
            rowStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),

            rowIconView.widthAnchor.constraint(equalToConstant: Layout.iconSize),
            rowIconView.heightAnchor.constraint(equalToConstant: Layout.iconSize)
        ])
    }
}
