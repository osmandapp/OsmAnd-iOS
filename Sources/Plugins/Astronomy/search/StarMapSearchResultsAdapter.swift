//
//  StarMapSearchResultsAdapter.swift
//  OsmAnd Maps
//
//  Created by Codex on 06.06.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import UIKit

final class StarMapSearchResultsAdapter: NSObject, UITableViewDataSource, UITableViewDelegate {
    struct Snapshot {
        let entries: [StarMapSearchEntry]
        let categoryPreset: StarMapSearchCategoryFilter?
        let useExploreRowLayout: Bool

        static let empty = Snapshot(entries: [],
                                    categoryPreset: nil,
                                    useExploreRowLayout: false)
    }
    
    var topInsetHeight: CGFloat = .leastNormalMagnitude

    private var snapshot: Snapshot
    private let nightMode: Bool
    private let widToDisplayName: () -> [String: String]
    private let starConstellationNameForObject: (SkyObject) -> String?
    private let eventTextProvider: (StarMapSearchEntry) -> NSAttributedString
    private let visibilityAttributedTextProvider: (StarMapSearchEntry) -> NSAttributedString
    private let onScroll: (UIScrollView) -> Void
    private let onEntrySelected: (StarMapSearchEntry) -> Void
    private lazy var resultFormatter = StarMapSearchResultFormatter(
        nightMode: nightMode,
        widToDisplayName: widToDisplayName,
        starConstellationNameForObject: starConstellationNameForObject,
        eventTextProvider: eventTextProvider,
        visibilityAttributedTextProvider: visibilityAttributedTextProvider
    )

    init(nightMode: Bool,
         snapshot: Snapshot,
         widToDisplayName: @escaping () -> [String: String],
         starConstellationNameForObject: @escaping (SkyObject) -> String?,
         eventTextProvider: @escaping (StarMapSearchEntry) -> NSAttributedString,
         visibilityAttributedTextProvider: @escaping (StarMapSearchEntry) -> NSAttributedString,
         onScroll: @escaping (UIScrollView) -> Void,
         onEntrySelected: @escaping (StarMapSearchEntry) -> Void) {
        self.nightMode = nightMode
        self.snapshot = snapshot
        self.widToDisplayName = widToDisplayName
        self.starConstellationNameForObject = starConstellationNameForObject
        self.eventTextProvider = eventTextProvider
        self.visibilityAttributedTextProvider = visibilityAttributedTextProvider
        self.onScroll = onScroll
        self.onEntrySelected = onEntrySelected
        super.init()
    }

    func submitSnapshot(_ snapshot: Snapshot) {
        self.snapshot = snapshot
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let v = UIView()
        v.isUserInteractionEnabled = false
        return v
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return topInsetHeight
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return topInsetHeight
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        snapshot.entries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let entry = getEntryForPosition(indexPath.row)
        let cell = tableView.dequeueReusableCell(withIdentifier: StarMapSearchObjectCell.reuseIdentifier) as? StarMapSearchObjectCell
            ?? StarMapSearchObjectCell(reuseIdentifier: StarMapSearchObjectCell.reuseIdentifier)
        bindResult(cell, entry: entry)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let entry = getEntryForSelection(indexPath.row) else {
            return
        }
        onEntrySelected(entry)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onScroll(scrollView)
    }

    private func getEntryForPosition(_ position: Int) -> StarMapSearchEntry {
        snapshot.entries[position]
    }

    private func getEntryForSelection(_ position: Int) -> StarMapSearchEntry? {
        guard snapshot.entries.indices.contains(position) else {
            return nil
        }
        return snapshot.entries[position]
    }

    private func bindResult(_ cell: StarMapSearchObjectCell, entry: StarMapSearchEntry) {
        let style: StarMapSearchObjectCellStyle = snapshot.useExploreRowLayout ? .myData : .explore
        cell.configure(style: style,
                       title: resultTitle(for: entry),
                       subtitle: resultFormatter.buildSubtitle(entry, categoryPreset: snapshot.categoryPreset))
        resultFormatter.bindIcon(cell.objectIconView, entry: entry, categoryPreset: snapshot.categoryPreset)
    }

    private func resultTitle(for entry: StarMapSearchEntry) -> String {
        if snapshot.categoryPreset == .CONSTELLATIONS || entry.objectRef.type == .CONSTELLATION {
            let name = entry.objectRef.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                return name
            }
        }
        return entry.displayName
    }
}

enum StarMapSearchObjectCellStyle {
    case explore
    case myData
}

private final class StarMapSearchObjectCell: UITableViewCell {
    let objectIconView = UIImageView()
    private let nameLabel = UILabel()
    private let infoLabel = UILabel()
    private let textStack = UIStackView()
    private let rowStack = UIStackView()

    init(reuseIdentifier: String) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func configure(style: StarMapSearchObjectCellStyle, title: String, subtitle: NSAttributedString) {
        applyStyle(style)
        nameLabel.text = title
        infoLabel.attributedText = subtitle.withSearchSecondaryTextColor()
        infoLabel.isHidden = subtitle.string.isEmpty
    }

    private func applyStyle(_ style: StarMapSearchObjectCellStyle) {
        let orderedViews: [UIView]
        switch style {
        case .myData:
            orderedViews = [objectIconView, textStack]
        case .explore:
            orderedViews = [textStack, objectIconView]
        }
        for (index, view) in orderedViews.enumerated() {
            rowStack.insertArrangedSubview(view, at: index)
        }
    }
    
    private func setup() {
        selectionStyle = .default
        backgroundColor = .groupBg
        separatorInset = .init(top: 0, left: 16, bottom: 0, right: 16)
        contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 68).isActive = true

        nameLabel.textColor = .textColorPrimary
        nameLabel.font = UIFont.preferredFont(forTextStyle: .body)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.numberOfLines = 1

        infoLabel.textColor = .textColorSecondary
        infoLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        infoLabel.adjustsFontForContentSizeCategory = true
        infoLabel.numberOfLines = 2

        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.isUserInteractionEnabled = false
        textStack.addArrangedSubview(nameLabel)
        textStack.addArrangedSubview(infoLabel)

        objectIconView.contentMode = .scaleAspectFit
        objectIconView.isUserInteractionEnabled = false
        objectIconView.setContentHuggingPriority(.required, for: .horizontal)
        objectIconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        objectIconView.tintColor = .iconColorActive

        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = 16
        rowStack.isUserInteractionEnabled = false
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        rowStack.addArrangedSubview(textStack)
        rowStack.addArrangedSubview(objectIconView)

        contentView.addSubview(rowStack)

        NSLayoutConstraint.activate([
            rowStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            rowStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            rowStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rowStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 8),
            rowStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),

            objectIconView.widthAnchor.constraint(equalToConstant: 30),
            objectIconView.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
}

private extension NSAttributedString {
    func withSearchSecondaryTextColor() -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: self)
        
        result.addAttributes([
            .foregroundColor: UIColor.textColorSecondary,
            .font: UIFont.preferredFont(forTextStyle: .subheadline)
        ], range: NSRange(location: 0, length: result.length))

        return result
    }
}

private final class StarMapSearchResultFormatter {
    private let nightMode: Bool
    private let widToDisplayName: () -> [String: String]
    private let starConstellationNameForObject: (SkyObject) -> String?
    private let eventTextProvider: (StarMapSearchEntry) -> NSAttributedString
    private let visibilityAttributedTextProvider: (StarMapSearchEntry) -> NSAttributedString

    init(nightMode: Bool,
         widToDisplayName: @escaping () -> [String: String],
         starConstellationNameForObject: @escaping (SkyObject) -> String?,
         eventTextProvider: @escaping (StarMapSearchEntry) -> NSAttributedString,
         visibilityAttributedTextProvider: @escaping (StarMapSearchEntry) -> NSAttributedString) {
        self.nightMode = nightMode
        self.widToDisplayName = widToDisplayName
        self.starConstellationNameForObject = starConstellationNameForObject
        self.eventTextProvider = eventTextProvider
        self.visibilityAttributedTextProvider = visibilityAttributedTextProvider
    }

    func bindIcon(_ iconView: UIImageView?, entry: StarMapSearchEntry, categoryPreset: StarMapSearchCategoryFilter?) {
        let iconCategory = categoryPreset ?? entry.category
        iconView?.image = AstroIcon.template(getCategoryIconRes(iconCategory))
        iconView?.tintColor = .iconColorActive
    }

    func buildSubtitle(_ entry: StarMapSearchEntry, categoryPreset: StarMapSearchCategoryFilter?) -> NSAttributedString {
        if isStarSubtitle(entry, categoryPreset: categoryPreset) {
            let magnitudeText = String(format: localizedString("astro_search_magnitude_short"), entry.magnitude)
            let result = NSMutableAttributedString()
            if let constellationName = resolveParentName(entry.objectRef) {
                result.append(NSAttributedString(string: constellationName))
                result.append(NSAttributedString(string: " • \(magnitudeText) • "))
            } else {
                result.append(NSAttributedString(string: "\(magnitudeText) • "))
            }
            result.append(eventTextProvider(entry))
            return result
        }
        
        if categoryPreset == .CONSTELLATIONS || entry.objectRef.type == .CONSTELLATION {
            let meaning = constellationLocalizedMeaning(entry.objectRef)
            let result = NSMutableAttributedString(string: "\(meaning) • ")
            result.append(visibilityAttributedTextProvider(entry))
            return result
        }
        
        let descriptorText = buildDescriptor(entry, categoryPreset: categoryPreset)
        let result = NSMutableAttributedString(string: descriptorText)
        let magnitudeText = String(format: localizedString("astro_search_magnitude_short"), entry.magnitude)
        result.append(NSAttributedString(string: " • \(magnitudeText) • "))
        result.append(eventTextProvider(entry))
        return result
    }

    private func isStarSubtitle(_ entry: StarMapSearchEntry, categoryPreset: StarMapSearchCategoryFilter?) -> Bool {
        categoryPreset == .STARS || entry.category == .STARS || entry.objectRef.type == .STAR
    }

    private func constellationLocalizedMeaning(_ obj: SkyObject) -> String {
        let localized = obj.localizedName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let name = obj.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !localized.isEmpty, !name.isEmpty, localized.caseInsensitiveCompare(name) != .orderedSame {
            return localized
        }
        return name.isEmpty ? localizedString("astro_type_constellation") : name
    }

    private func buildDescriptor(_ entry: StarMapSearchEntry, categoryPreset: StarMapSearchCategoryFilter?) -> String {
        let obj = entry.objectRef
        let parentName = resolveParentName(obj)
        switch categoryPreset {
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
        if !centerWid.isEmpty {
            let mappedName = widToDisplayName()[centerWid]
            if mappedName?.isEmpty == false {
                return mappedName
            }
            let fallback = centerWid.replacingOccurrences(of: "_", with: " ")
            if !fallback.isEmpty {
                return fallback
            }
        }
        if obj.type == .STAR {
            return starConstellationNameForObject(obj)
        }
        return nil
    }
}

func getCategoryIconRes(_ category: StarMapSearchCategoryFilter) -> String {
    switch category {
    case .SOLAR_SYSTEM:
        return "ic_custom_planet_outlined"
    case .CONSTELLATIONS:
        return "ic_custom_constellations"
    case .STARS:
        return "ic_custom_star_shine"
    case .NEBULAS:
        return "ic_custom_nebulas"
    case .STAR_CLUSTERS:
        return "ic_custom_star_clusters"
    case .DEEP_SKY:
        return "ic_custom_galaxy"
    case .ALL:
        return "ic_custom_list"
    }
}
