//
//  StarMapSearchResultsAdapter.swift
//  OsmAnd Maps
//
//  Created by Codex on 06.06.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

final class StarMapSearchResultsAdapter: NSObject, UITableViewDataSource, UITableViewDelegate {
    var visibleEntries: [StarMapSearchEntry]
    private let nightMode: Bool
    private let widToDisplayName: () -> [String: String]
    private let shouldShowInfoHeader: () -> Bool
    private let useExploreRowLayout: () -> Bool
    private let categoryPresetProvider: () -> StarMapSearchCategoryFilter?
    private let eventTextProvider: (StarMapSearchEntry) -> NSAttributedString
    private let onScroll: (UIScrollView) -> Void
    private let onEntrySelected: (StarMapSearchEntry) -> Void
    private lazy var resultFormatter = StarMapSearchResultFormatter(nightMode: nightMode,
                                                                    widToDisplayName: widToDisplayName,
                                                                    categoryPresetProvider: categoryPresetProvider,
                                                                    eventTextProvider: eventTextProvider)

    init(nightMode: Bool,
         visibleEntries: [StarMapSearchEntry],
         widToDisplayName: @escaping () -> [String: String],
         shouldShowInfoHeader: @escaping () -> Bool,
         useExploreRowLayout: @escaping () -> Bool,
         categoryPresetProvider: @escaping () -> StarMapSearchCategoryFilter?,
         eventTextProvider: @escaping (StarMapSearchEntry) -> NSAttributedString,
         onScroll: @escaping (UIScrollView) -> Void,
         onEntrySelected: @escaping (StarMapSearchEntry) -> Void) {
        self.nightMode = nightMode
        self.visibleEntries = visibleEntries
        self.widToDisplayName = widToDisplayName
        self.shouldShowInfoHeader = shouldShowInfoHeader
        self.useExploreRowLayout = useExploreRowLayout
        self.categoryPresetProvider = categoryPresetProvider
        self.eventTextProvider = eventTextProvider
        self.onScroll = onScroll
        self.onEntrySelected = onEntrySelected
        super.init()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        visibleEntries.count + (shouldShowInfoHeader() ? 1 : 0)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if shouldShowInfoHeader() && indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: Self.infoReuseIdentifier) as? StarMapSearchInfoCell
                ?? StarMapSearchInfoCell(reuseIdentifier: Self.infoReuseIdentifier)
            bindInfo(cell)
            return cell
        }
        if useExploreRowLayout() {
            let cell = tableView.dequeueReusableCell(withIdentifier: Self.exploreReuseIdentifier) as? StarMapSearchExploreCell
                ?? StarMapSearchExploreCell(reuseIdentifier: Self.exploreReuseIdentifier)
            bindExploreResult(cell, entry: getEntryForPosition(indexPath.row))
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.itemReuseIdentifier) as? StarMapSearchObjectCell
            ?? StarMapSearchObjectCell(reuseIdentifier: Self.itemReuseIdentifier)
        bindResult(cell, entry: getEntryForPosition(indexPath.row))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if shouldShowInfoHeader() && indexPath.row == 0 {
            return
        }
        onEntrySelected(getEntryForPosition(indexPath.row))
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onScroll(scrollView)
    }

    private func getEntryForPosition(_ position: Int) -> StarMapSearchEntry {
        let entryIndex = shouldShowInfoHeader() ? position - 1 : position
        return visibleEntries[entryIndex]
    }

    private func bindInfo(_ cell: StarMapSearchInfoCell) {
        guard let presetCategory = categoryPresetProvider() else {
            return
        }
        cell.configure(icon: AstroIcon.template(getCategoryIconRes(presetCategory)),
                       iconTintColor: StarMapControlTheme.activeForeground(nightMode: nightMode),
                       text: localizedString(getCategoryInfoTextRes(presetCategory)))
    }

    private func bindResult(_ cell: StarMapSearchObjectCell, entry: StarMapSearchEntry) {
        cell.configure(title: entry.displayName, subtitle: resultFormatter.buildSubtitle(entry))
        resultFormatter.bindIcon(cell.objectIconView, entry: entry)
    }

    private func bindExploreResult(_ cell: StarMapSearchExploreCell, entry: StarMapSearchEntry) {
        cell.configure(title: entry.displayName, subtitle: resultFormatter.buildSubtitle(entry))
        resultFormatter.bindIcon(cell.rowIconView, entry: entry)
    }

    private static let infoReuseIdentifier = "StarMapSearchInfoCell"
    private static let itemReuseIdentifier = "StarMapSearchItemCell"
    private static let exploreReuseIdentifier = "StarMapSearchExploreCell"
}

private final class StarMapSearchInfoCell: UITableViewCell {
    private let cardView = UIView()
    private let infoIconView = UIImageView()
    private let infoLabel = UILabel()

    init(reuseIdentifier: String) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = StarMapSearchLightPalette.listBackground
        contentView.backgroundColor = StarMapSearchLightPalette.listBackground

        cardView.backgroundColor = StarMapSearchLightPalette.appBarBackground
        cardView.layer.cornerRadius = 10
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.isUserInteractionEnabled = false

        infoIconView.contentMode = .scaleAspectFit
        infoIconView.translatesAutoresizingMaskIntoConstraints = false

        infoLabel.textColor = StarMapSearchLightPalette.primaryText
        infoLabel.font = UIFont.preferredFont(forTextStyle: .body)
        infoLabel.numberOfLines = 0
        infoLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(cardView)
        cardView.addSubview(infoIconView)
        cardView.addSubview(infoLabel)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            infoIconView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            infoIconView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 18),
            infoIconView.widthAnchor.constraint(equalToConstant: 24),
            infoIconView.heightAnchor.constraint(equalToConstant: 24),

            infoLabel.leadingAnchor.constraint(equalTo: infoIconView.trailingAnchor, constant: 24),
            infoLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            infoLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            infoLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12)
        ])
    }

    func configure(icon: UIImage?, iconTintColor: UIColor, text: String) {
        infoIconView.image = icon
        infoIconView.tintColor = iconTintColor
        infoLabel.text = text
    }
}

private final class StarMapSearchObjectCell: UITableViewCell {
    let objectIconView = UIImageView()
    private let nameLabel = UILabel()
    private let infoLabel = UILabel()
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
        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 72).isActive = true

        nameLabel.textColor = StarMapSearchLightPalette.primaryText
        nameLabel.font = UIFont.preferredFont(forTextStyle: .title3)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.numberOfLines = 1

        infoLabel.textColor = StarMapSearchLightPalette.secondaryText
        infoLabel.font = UIFont.preferredFont(forTextStyle: .body)
        infoLabel.adjustsFontForContentSizeCategory = true
        infoLabel.numberOfLines = 2

        let textStack = UIStackView(arrangedSubviews: [nameLabel, infoLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.isUserInteractionEnabled = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        objectIconView.contentMode = .scaleAspectFit
        objectIconView.translatesAutoresizingMaskIntoConstraints = false
        objectIconView.isUserInteractionEnabled = false

        dividerView.backgroundColor = StarMapSearchLightPalette.separator
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        dividerView.isUserInteractionEnabled = false

        contentView.addSubview(textStack)
        contentView.addSubview(objectIconView)
        contentView.addSubview(dividerView)

        NSLayoutConstraint.activate([
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textStack.trailingAnchor.constraint(equalTo: objectIconView.leadingAnchor, constant: -16),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 8),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),

            objectIconView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -36),
            objectIconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            objectIconView.widthAnchor.constraint(equalToConstant: 24),
            objectIconView.heightAnchor.constraint(equalToConstant: 24),

            dividerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dividerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            dividerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale)
        ])
    }

    func configure(title: String, subtitle: NSAttributedString) {
        nameLabel.text = title
        infoLabel.attributedText = subtitle.withSearchSecondaryTextColor()
        infoLabel.isHidden = subtitle.string.isEmpty
    }
}

private final class StarMapSearchExploreCell: UITableViewCell {
    let rowIconView = UIImageView()
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
        textStack.isUserInteractionEnabled = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

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

    func configure(title: String, subtitle: NSAttributedString) {
        titleLabel.text = title
        subtitleLabel.attributedText = subtitle.withSearchSecondaryTextColor()
        subtitleLabel.isHidden = subtitle.string.isEmpty
    }
}

private extension NSAttributedString {
    func withSearchSecondaryTextColor() -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: self)
        result.addAttribute(.foregroundColor,
                            value: StarMapSearchLightPalette.secondaryText,
                            range: NSRange(location: 0, length: result.length))
        return result
    }
}

private final class StarMapSearchResultFormatter {
    private let nightMode: Bool
    private let widToDisplayName: () -> [String: String]
    private let categoryPresetProvider: () -> StarMapSearchCategoryFilter?
    private let eventTextProvider: (StarMapSearchEntry) -> NSAttributedString

    init(nightMode: Bool,
         widToDisplayName: @escaping () -> [String: String],
         categoryPresetProvider: @escaping () -> StarMapSearchCategoryFilter?,
         eventTextProvider: @escaping (StarMapSearchEntry) -> NSAttributedString) {
        self.nightMode = nightMode
        self.widToDisplayName = widToDisplayName
        self.categoryPresetProvider = categoryPresetProvider
        self.eventTextProvider = eventTextProvider
    }

    func bindIcon(_ iconView: UIImageView?, entry: StarMapSearchEntry) {
        let iconCategory = categoryPresetProvider() ?? entry.category
        iconView?.image = AstroIcon.template(getCategoryIconRes(iconCategory))
        iconView?.tintColor = StarMapSearchLightPalette.defaultIcon
    }

    func buildSubtitle(_ entry: StarMapSearchEntry) -> NSAttributedString {
        let descriptorText = buildDescriptor(entry)
        let result = NSMutableAttributedString(string: descriptorText)
        if entry.objectRef.type == .CONSTELLATION {
            result.append(NSAttributedString(string: " • "))
            result.append(eventTextProvider(entry))
            return result
        }
        let magnitudeText = String(format: localizedString("astro_search_magnitude_short"), entry.magnitude)
        result.append(NSAttributedString(string: " • \(magnitudeText) • "))
        result.append(eventTextProvider(entry))
        return result
    }

    private func buildDescriptor(_ entry: StarMapSearchEntry) -> String {
        let obj = entry.objectRef
        let parentName = resolveParentName(obj)
        switch categoryPresetProvider() {
        case .CONSTELLATIONS:
            return localizedString("astro_type_constellation")
        case .STARS:
            if parentName?.isEmpty != false {
                return localizedString("astro_type_star")
            }
            return String(format: localizedString("astro_search_in_location"), parentName ?? "")
        case .NEBULAS, .STAR_CLUSTERS, .DEEP_SKY:
            let typeLabel = getSingularTypeLabel(obj.type)
            if parentName?.isEmpty != false {
                return typeLabel
            }
            return String(format: localizedString("astro_search_type_in_location"), typeLabel, parentName ?? "")
        default:
            return getSingularTypeLabel(obj.type)
        }
    }

    private func getSingularTypeLabel(_ type: SkyObjectType) -> String {
        switch type {
        case .SUN:
            return localizedString("astro_name_sun")
        case .MOON:
            return localizedString("astro_name_moon")
        case .PLANET:
            return localizedString("astro_type_planet")
        case .STAR:
            return localizedString("astro_type_star")
        case .GALAXY:
            return localizedString("astro_type_galaxy")
        case .NEBULA:
            return localizedString("astro_type_nebula")
        case .BLACK_HOLE:
            return localizedString("astro_type_black_hole")
        case .OPEN_CLUSTER:
            return localizedString("astro_type_open_cluster")
        case .GLOBULAR_CLUSTER:
            return localizedString("astro_type_globular_cluster")
        case .GALAXY_CLUSTER:
            return localizedString("astro_type_galaxy_cluster")
        case .CONSTELLATION:
            return localizedString("astro_type_constellation")
        }
    }

    private func resolveParentName(_ obj: SkyObject) -> String? {
        let centerWid = obj.centerWId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if centerWid.isEmpty {
            return nil
        }
        let mappedName = widToDisplayName()[centerWid]
        if mappedName?.isEmpty == false {
            return mappedName
        }
        let fallback = centerWid.replacingOccurrences(of: "_", with: " ")
        return fallback.isEmpty ? nil : fallback
    }
}

func getCategoryIconRes(_ category: StarMapSearchCategoryFilter) -> String {
    switch category {
    case .SOLAR_SYSTEM:
        return "ic_action_planet_outlined"
    case .CONSTELLATIONS:
        return "ic_action_constellations"
    case .STARS:
        return "ic_action_stars"
    case .NEBULAS:
        return "ic_action_nebulas"
    case .STAR_CLUSTERS:
        return "ic_action_star_clusters"
    case .DEEP_SKY:
        return "ic_action_galaxy"
    case .ALL:
        return "ic_action_search_dark"
    }
}

func getCategoryInfoTextRes(_ category: StarMapSearchCategoryFilter) -> String {
    switch category {
    case .SOLAR_SYSTEM:
        return "astro_search_info_solar_system"
    case .CONSTELLATIONS:
        return "astro_search_info_constellations"
    case .STARS:
        return "astro_search_info_stars"
    case .NEBULAS:
        return "astro_search_info_nebulas"
    case .STAR_CLUSTERS:
        return "astro_search_info_star_clusters"
    case .DEEP_SKY:
        return "astro_search_info_deep_sky"
    case .ALL:
        return "astro_search_info_solar_system"
    }
}
