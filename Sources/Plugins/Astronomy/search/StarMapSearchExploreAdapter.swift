//
//  StarMapSearchExploreAdapter.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 25.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

enum StarMapExploreSection: Int, CaseIterable {
    case recent
    case watchNow
    case categories
    case myData
    case catalogs
}

enum StarMapExploreRow {
    case recentChips
    case watchNow
    case category(StarMapExploreRowConfig)
    case myData(config: StarMapExploreRowConfig, count: Int)
    case catalog(StarMapCatalogEntry)
    case viewAllCatalogs(count: Int)
}

struct StarMapExploreRowConfig {
    let quickPresetType: StarMapSearchQuickPresetType
    let iconRes: String
    let titleRes: String
    let subtitleRes: String?
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

    var topInsetHeight: CGFloat = 10

    private let onScroll: (UIScrollView) -> Void
    private let onWatchNow: () -> Void
    private let onCategory: (StarMapSearchQuickPresetType) -> Void
    private let onMyData: (StarMapSearchQuickPresetType) -> Void
    private let onCatalog: (StarMapCatalogEntry) -> Void
    private let onViewAllCatalogs: () -> Void
    private let recentChipsScrollView: () -> UIScrollView
    
    private var snapshot: Snapshot
    
    init(tableView: UITableView,
         snapshot: Snapshot,
         onScroll: @escaping (UIScrollView) -> Void,
         onWatchNow: @escaping () -> Void,
         onCategory: @escaping (StarMapSearchQuickPresetType) -> Void,
         onMyData: @escaping (StarMapSearchQuickPresetType) -> Void,
         onCatalog: @escaping (StarMapCatalogEntry) -> Void,
         onViewAllCatalogs: @escaping () -> Void,
         recentChipsScrollView: @escaping () -> UIScrollView) {
        self.snapshot = snapshot
        self.onScroll = onScroll
        self.onWatchNow = onWatchNow
        self.onCategory = onCategory
        self.onMyData = onMyData
        self.onCatalog = onCatalog
        self.onViewAllCatalogs = onViewAllCatalogs
        self.recentChipsScrollView = recentChipsScrollView
        super.init()
        self.registerCells(for: tableView)
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

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard snapshot.sections.indices.contains(section) else {
            return .leastNormalMagnitude
        }
        if section == 0 {
            return topInsetHeight
        }
        switch snapshot.sections[section].0 {
        case .myData, .catalogs:
            return UITableView.automaticDimension
        case .recent, .watchNow, .categories:
            return .leastNormalMagnitude
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        guard snapshot.sections.indices.contains(section) else {
            return .leastNormalMagnitude
        }
        if section == 0 {
            return topInsetHeight
        }
        switch snapshot.sections[section].0 {
        case .myData, .catalogs:
            return 44
        case .recent, .watchNow, .categories:
            return .leastNormalMagnitude
        }
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard snapshot.sections.indices.contains(indexPath.section),
              snapshot.sections[indexPath.section].1.indices.contains(indexPath.row) else {
            return UITableView.automaticDimension
        }
        if case .recentChips = snapshot.sections[indexPath.section].1[indexPath.row] {
            return 52
        }
        return 68
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard snapshot.sections.indices.contains(section) else {
            return nil
        }
        if section == 0 {
            let spacer = UIView()
            spacer.isUserInteractionEnabled = false
            return spacer
        }
        let sectionKind = snapshot.sections[section].0
        switch sectionKind {
        case .myData:
            return sectionHeaderView(localizedString("astro_explore_my_data"))
        case .catalogs:
            return sectionHeaderView(localizedString("astro_catalogs"))
        case .recent, .watchNow, .categories:
            return nil
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
        case .recentChips:
            let cell = dequeueRecentChipsCell(tableView)
            cell.attach(scrollView: recentChipsScrollView())
            return cell

        case .watchNow:
            let cell = dequeueMenuCell(tableView)
            cell.configure(icon: AstroIcon.template("ic_custom_telescope"),
                           title: localizedString("astro_explore_watch_now"),
                           subtitle: localizedString("astro_explore_watch_now_subtitle"),
                           trailingText: nil,
                           config: .watchNow)
            return cell

        case .category(let config):
            let cell = dequeueMenuCell(tableView)
            cell.configure(icon: AstroIcon.template(config.iconRes),
                           title: localizedString(config.titleRes),
                           subtitle: config.subtitleRes.map(localizedString),
                           trailingText: nil,
                           config: .category)
            return cell

        case .myData(let config, let count):
            let cell = dequeueMenuCell(tableView)
            cell.configure(icon: AstroIcon.template(config.iconRes),
                           title: localizedString(config.titleRes),
                           subtitle: nil,
                           trailingText: String(count),
                           config: .category)
            return cell

        case .catalog(let entry):
            let cell = dequeueMenuCell(tableView)
            cell.configure(icon: AstroIcon.template("ic_custom_book_info"),
                           title: entry.displayName,
                           subtitle: nil,
                           trailingText: nil,
                           config: isBeforeViewAll(at: indexPath) ? .catalogLast : .catalog)
            return cell

        case .viewAllCatalogs(let count):
            let cell = dequeueMenuCell(tableView)
            cell.configure(icon: nil,
                           title: localizedString("shared_string_view_all"),
                           subtitle: nil,
                           trailingText: nil,
                           config: .button)
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
        case .recentChips:
            break
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

    private func dequeueRecentChipsCell(_ tableView: UITableView) -> StarMapExploreRecentChipsCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: StarMapExploreRecentChipsCell.reuseIdentifier) as? StarMapExploreRecentChipsCell else {
            return StarMapExploreRecentChipsCell(reuseIdentifier: StarMapExploreRecentChipsCell.reuseIdentifier)
        }
        return cell
    }

    private func dequeueMenuCell(_ tableView: UITableView) -> StarMapExploreMenuCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: StarMapExploreMenuCell.reuseIdentifier) as? StarMapExploreMenuCell else {
            return StarMapExploreMenuCell(reuseIdentifier: StarMapExploreMenuCell.reuseIdentifier)
        }
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
    
    private func isBeforeViewAll(at indexPath: IndexPath) -> Bool {
        let nextIndex = indexPath.row + 1
        
        guard let section = snapshot.sections[safe: indexPath.section]?.1 else { return false }
        guard let nextRow = section[safe: nextIndex] else { return false }
        
        if case .viewAllCatalogs = nextRow {
            return true
        } else {
            return false
        }
    }
    
    private func registerCells(for tableView: UITableView) {
        tableView.register(StarMapExploreRecentChipsCell.self, forCellReuseIdentifier: StarMapExploreRecentChipsCell.reuseIdentifier)
        tableView.register(StarMapExploreMenuCell.self, forCellReuseIdentifier: StarMapExploreMenuCell.reuseIdentifier)
    }
}

private final class StarMapExploreRecentChipsCell: UITableViewCell {

    private enum Layout {
        static let minHeight: CGFloat = 44
    }

    private weak var attachedScrollView: UIScrollView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
    }
    
    init(reuseIdentifier: String) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        selectionStyle = .none
    }

    func attach(scrollView: UIScrollView) {
        if attachedScrollView === scrollView, scrollView.superview === contentView {
            return
        }
        attachedScrollView?.removeFromSuperview()
        attachedScrollView = scrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            scrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: Layout.minHeight)
        ])
    }
}

private final class StarMapExploreMenuCell: UITableViewCell {
    private enum Layout {
        static let contentPadding: CGFloat = 16
        static let smallPadding: CGFloat = 11
        static let bigPadding: CGFloat = 24
        static let iconSize: CGFloat = 30
    }
    
    struct Config {
        let iconColor: UIColor
        let titleColor: UIColor
        let hasRightArrow: Bool
        let separatorInset: UIEdgeInsets
        
        static let watchNow = Config(iconColor: .iconColorActive, titleColor: .textColorPrimary, hasRightArrow: false, separatorInset: .init(top: 0, left: 0, bottom: 0, right: 0))
        static let category = Config(iconColor: .iconColorActive, titleColor: .textColorPrimary, hasRightArrow: true, separatorInset: .init(top: 0, left: 62, bottom: 0, right: 16))
        static let catalog = Config(iconColor: .iconColorDefault, titleColor: .textColorPrimary, hasRightArrow: false, separatorInset: .init(top: 0, left: 62, bottom: 0, right: 16))
        static let catalogLast = Config(iconColor: .iconColorDefault, titleColor: .textColorPrimary, hasRightArrow: false, separatorInset: .init(top: 0, left: 16, bottom: 0, right: 16))
        static let button = Config(iconColor: .iconColorDefault, titleColor: .textColorActive, hasRightArrow: false, separatorInset: .init(top: 0, left: 0, bottom: 0, right: 0))
    }
    
    private let rowIconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let trailingLabel = UILabel()
    private let textStack = UIStackView()
    private var textStackLeadingToIcon: NSLayoutConstraint?
    private var textStackLeadingToContent: NSLayoutConstraint?
    
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

    func configure(icon: UIImage?,
                   title: String,
                   subtitle: String?,
                   trailingText: String?,
                   config: Config) {
        if let icon {
            rowIconView.image = icon
            rowIconView.tintColor = config.iconColor
            rowIconView.isHidden = false
            textStackLeadingToContent?.isActive = false
            textStackLeadingToIcon?.isActive = true
        } else {
            rowIconView.image = nil
            rowIconView.isHidden = true
            textStackLeadingToIcon?.isActive = false
            textStackLeadingToContent?.isActive = true
        }
        titleLabel.text = title
        titleLabel.textColor = config.titleColor
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle?.isEmpty != false
        trailingLabel.text = trailingText
        trailingLabel.isHidden = trailingText == nil
        
        if config.hasRightArrow {
            accessoryType = .disclosureIndicator
        } else {
            accessoryType = .none
        }
        separatorInset = config.separatorInset
    }
    
    private func setup() {
        selectionStyle = .default
        accessoryType = .disclosureIndicator
        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true

        rowIconView.contentMode = .scaleAspectFit
        rowIconView.translatesAutoresizingMaskIntoConstraints = false
        rowIconView.isUserInteractionEnabled = false

        titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 1

        subtitleLabel.textColor = .textColorSecondary
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.numberOfLines = 2

        textStack.axis = .vertical
        textStack.spacing = 6
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.isUserInteractionEnabled = false
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        trailingLabel.textColor = .textColorSecondary
        trailingLabel.font = UIFont.preferredFont(forTextStyle: .body)
        trailingLabel.adjustsFontForContentSizeCategory = true
        trailingLabel.setContentHuggingPriority(.required, for: .horizontal)
        trailingLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        trailingLabel.translatesAutoresizingMaskIntoConstraints = false
        trailingLabel.isUserInteractionEnabled = false

        contentView.addSubview(rowIconView)
        contentView.addSubview(textStack)
        contentView.addSubview(trailingLabel)

        textStackLeadingToIcon = textStack.leadingAnchor.constraint(equalTo: rowIconView.trailingAnchor, constant: Layout.contentPadding)
        textStackLeadingToIcon?.isActive = true
        textStackLeadingToContent = textStack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor)

        NSLayoutConstraint.activate([
            rowIconView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            rowIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rowIconView.widthAnchor.constraint(equalToConstant: Layout.iconSize),
            rowIconView.heightAnchor.constraint(equalToConstant: Layout.iconSize),

            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: Layout.smallPadding),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -Layout.smallPadding),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingLabel.leadingAnchor, constant: -Layout.smallPadding),

            trailingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.bigPadding),
            trailingLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
}
