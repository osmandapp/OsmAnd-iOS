//
//  StarMapSearchExploreAdapter.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 25.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

struct StarMapExploreRowConfig {
    let quickPresetType: StarMapSearchQuickPresetType
    let iconRes: String
    let titleRes: String
    let subtitleRes: String?
}

enum StarMapExploreSection: Int, CaseIterable {
    case watchNow
    case categories
    case myData
    case catalogs
}

enum StarMapExploreRow {
    case watchNow
    case category(StarMapExploreRowConfig)
    case myData(config: StarMapExploreRowConfig, count: Int)
    case catalog(StarMapCatalogEntry)
    case viewAllCatalogs(count: Int)
}

final class StarMapSearchExploreAdapter: NSObject, UITableViewDataSource, UITableViewDelegate {
    struct Snapshot {
        let sections: [(StarMapExploreSection, [StarMapExploreRow])]

        static let empty = Snapshot(sections: [])
    }

    private enum Layout {
        static let contentPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
    }

    private var snapshot: Snapshot
    private let onScroll: (UIScrollView) -> Void
    private let onWatchNow: () -> Void
    private let onCategory: (StarMapSearchQuickPresetType) -> Void
    private let onMyData: (StarMapSearchQuickPresetType) -> Void
    private let onCatalog: (StarMapCatalogEntry) -> Void
    private let onViewAllCatalogs: () -> Void

    init(snapshot: Snapshot,
         onScroll: @escaping (UIScrollView) -> Void,
         onWatchNow: @escaping () -> Void,
         onCategory: @escaping (StarMapSearchQuickPresetType) -> Void,
         onMyData: @escaping (StarMapSearchQuickPresetType) -> Void,
         onCatalog: @escaping (StarMapCatalogEntry) -> Void,
         onViewAllCatalogs: @escaping () -> Void) {
        self.snapshot = snapshot
        self.onScroll = onScroll
        self.onWatchNow = onWatchNow
        self.onCategory = onCategory
        self.onMyData = onMyData
        self.onCatalog = onCatalog
        self.onViewAllCatalogs = onViewAllCatalogs
        super.init()
    }

    func submitSnapshot(_ snapshot: Snapshot) {
        self.snapshot = snapshot
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        snapshot.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard snapshot.sections.indices.contains(section) else {
            return 0
        }
        return snapshot.sections[section].1.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard snapshot.sections.indices.contains(section) else {
            return nil
        }
        let sectionKind = snapshot.sections[section].0
        switch sectionKind {
        case .myData:
            return sectionHeaderView(localizedString("astro_explore_my_data"))
        case .catalogs:
            return sectionHeaderView(localizedString("astro_catalogs"))
        case .watchNow, .categories:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard snapshot.sections.indices.contains(section), section > 0 else {
            return 16
        }
        switch snapshot.sections[section].0 {
        case .myData, .catalogs:
            return UITableView.automaticDimension
        case .watchNow, .categories:
            return .leastNormalMagnitude
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        guard snapshot.sections.indices.contains(section), section > 0 else {
            return 16
        }
        switch snapshot.sections[section].0 {
        case .myData, .catalogs:
            return 44
        case .watchNow, .categories:
            return .leastNormalMagnitude
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        16
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        nil
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard snapshot.sections.indices.contains(indexPath.section),
              snapshot.sections[indexPath.section].1.indices.contains(indexPath.row) else {
            return UITableViewCell()
        }
        let row = snapshot.sections[indexPath.section].1[indexPath.row]

        switch row {
        case .watchNow:
            let cell = dequeueMenuCell(tableView)
            cell.configure(icon: AstroIcon.template("ic_custom_telescope"),
                           iconTintColor: .iconColorActive,
                           title: localizedString("astro_explore_watch_now"),
                           subtitle: localizedString("astro_explore_watch_now_subtitle"),
                           trailingText: nil,
                           titleColor: .textColorPrimary)
            return cell

        case .category(let config):
            let cell = dequeueMenuCell(tableView)
            cell.configure(icon: AstroIcon.template(config.iconRes),
                           iconTintColor: .iconColorActive,
                           title: localizedString(config.titleRes),
                           subtitle: config.subtitleRes.map(localizedString),
                           trailingText: nil,
                           titleColor: .textColorPrimary)
            return cell

        case .myData(let config, let count):
            let cell = dequeueMenuCell(tableView)
            cell.configure(icon: AstroIcon.template(config.iconRes),
                           iconTintColor: .iconColorActive,
                           title: localizedString(config.titleRes),
                           subtitle: nil,
                           trailingText: String(count),
                           titleColor: .textColorPrimary)
            return cell

        case .catalog(let entry):
            let cell = dequeueMenuCell(tableView)
            cell.configure(icon: AstroIcon.template("ic_custom_book_info"),
                           iconTintColor: .iconColorDefault,
                           title: entry.displayName,
                           subtitle: nil,
                           trailingText: nil,
                           titleColor: .textColorPrimary)
            return cell

        case .viewAllCatalogs(let count):
            let cell = dequeueMenuCell(tableView)
            cell.configure(icon: nil,
                           iconTintColor: .iconColorActive,
                           title: localizedString("shared_string_view_all"),
                           subtitle: nil,
                           trailingText: String(count),
                           titleColor: .textColorActive)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard snapshot.sections.indices.contains(indexPath.section),
              snapshot.sections[indexPath.section].1.indices.contains(indexPath.row) else {
            return
        }
        switch snapshot.sections[indexPath.section].1[indexPath.row] {
        case .watchNow:
            onWatchNow()
        case .category(let config):
            onCategory(config.quickPresetType)
        case .myData(let config, _):
            onMyData(config.quickPresetType)
        case .catalog(let entry):
            onCatalog(entry)
        case .viewAllCatalogs:
            onViewAllCatalogs()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onScroll(scrollView)
    }

    private func dequeueMenuCell(_ tableView: UITableView) -> StarMapExploreMenuCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.menuReuseIdentifier) as? StarMapExploreMenuCell
            ?? StarMapExploreMenuCell(reuseIdentifier: Self.menuReuseIdentifier)
        return cell
    }

    private func sectionHeaderView(_ text: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear

        let label = UILabel()
        label.text = text
        label.textColor = .textColorSecondary
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Layout.contentPadding),
            label.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -Layout.contentPadding),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: Layout.smallPadding),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -Layout.smallPadding)
        ])
        return container
    }

    private static let menuReuseIdentifier = "StarMapExploreMenuCell"
}

private final class StarMapExploreMenuCell: UITableViewCell {
    private let rowIconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let trailingLabel = UILabel()
    private let textStack = UIStackView()
    private var textStackLeadingToIcon: NSLayoutConstraint!
    private var textStackLeadingToContent: NSLayoutConstraint!

    private enum Metrics {
        static let contentPadding: CGFloat = 16
        static let iconSize: CGFloat = 30
    }

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
        accessoryType = .disclosureIndicator
        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true

        rowIconView.contentMode = .scaleAspectFit
        rowIconView.translatesAutoresizingMaskIntoConstraints = false
        rowIconView.isUserInteractionEnabled = false

        titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
        titleLabel.numberOfLines = 1

        subtitleLabel.textColor = .textColorSecondary
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        subtitleLabel.numberOfLines = 2

        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.isUserInteractionEnabled = false
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        trailingLabel.textColor = StarMapSearchLightPalette.secondaryText
        trailingLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        trailingLabel.setContentHuggingPriority(.required, for: .horizontal)
        trailingLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        trailingLabel.translatesAutoresizingMaskIntoConstraints = false
        trailingLabel.isUserInteractionEnabled = false

        contentView.addSubview(rowIconView)
        contentView.addSubview(textStack)
        contentView.addSubview(trailingLabel)

        textStackLeadingToIcon = textStack.leadingAnchor.constraint(equalTo: rowIconView.trailingAnchor, constant: Metrics.contentPadding)
        textStackLeadingToContent = textStack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor)

        NSLayoutConstraint.activate([
            rowIconView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            rowIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rowIconView.widthAnchor.constraint(equalToConstant: Metrics.iconSize),
            rowIconView.heightAnchor.constraint(equalToConstant: Metrics.iconSize),

            textStackLeadingToIcon,
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 8),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingLabel.leadingAnchor, constant: -8),

            trailingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Metrics.contentPadding),
            trailingLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        accessoryView?.tintColor = .tertiaryLabel
    }

    func configure(icon: UIImage?,
                   iconTintColor: UIColor,
                   title: String,
                   subtitle: String?,
                   trailingText: String?,
                   titleColor: UIColor) {
        accessoryType = .disclosureIndicator
        if let icon {
            rowIconView.image = icon
            rowIconView.tintColor = iconTintColor
            rowIconView.isHidden = false
            textStackLeadingToContent.isActive = false
            textStackLeadingToIcon.isActive = true
        } else {
            rowIconView.image = nil
            rowIconView.isHidden = true
            textStackLeadingToIcon.isActive = false
            textStackLeadingToContent.isActive = true
        }
        titleLabel.text = title
        titleLabel.textColor = titleColor
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle?.isEmpty != false
        trailingLabel.text = trailingText
        trailingLabel.isHidden = trailingText == nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        accessoryType = .disclosureIndicator
    }
}
