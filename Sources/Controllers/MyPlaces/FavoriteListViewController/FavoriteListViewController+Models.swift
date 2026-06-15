//
//  FavoriteListViewController+Models.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 04.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import CoreLocation
import UniformTypeIdentifiers

enum ScreenMode {
    case root
    case folder(FavoriteFolderRow, previousTitle: String)
}

enum FavoriteFolderSection: Hashable {
    case pinned
    case visible
    case hidden

    var title: String {
        switch self {
        case .pinned: localizedString("shared_string_pinned")
        case .visible: localizedString("shared_string_visible")
        case .hidden: localizedString("shared_string_hidden")
        }
    }
}

enum FavoriteListSection: Hashable {
    case sortHeader
    case backupBanner
    case folderSection(FavoriteFolderSection)
    case content
    case statsFooter
    case emptyState
}

enum FavoriteListItem: Hashable {
    case sortHeader(FavoriteSortHeader)
    case backupBanner
    case header(FavoriteFolderSection)
    case folder(FavoriteFolderRow)
    case favorite(FavoritePointRow)
    case statsFooter(FavoriteFolderStats)
    case emptyState
}

struct FavoriteSortHeader: Hashable {
    let sortMode: FavoriteSortMode
    let includesDistanceSortModes: Bool
}

struct FavoriteFolderRow: Hashable, FavoriteSortableFolder {
    static let subtitleDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    let bridgeItem: OAFavoriteFolderBridgeItem

    var title: String { bridgeItem.title }

    var isVisible: Bool { bridgeItem.isVisible }

    var isPinned: Bool { bridgeItem.isPinned }

    var lastModified: Date? { bridgeItem.lastModifiedDate }

    var subtitle: String {
        let pointsText = "\(bridgeItem.subtreePointsCount) \(localizedString("shared_string_gpx_points").lowercased())"
        guard let lastModified else { return pointsText + "." }
        return String(format: localizedString("ltr_or_rtl_combine_via_comma"), Self.subtitleDateFormatter.string(from: lastModified), pointsText) + "."
    }

    var iconName: String {
        isVisible ? "ic_custom_folder" : "ic_custom_folder_hidden_outlined"
    }

    var iconColor: UIColor {
        isVisible ? (bridgeItem.color ?? .iconColorSelected) : .iconColorSecondary
    }

    var titleColor: UIColor {
        isVisible ? .textColorPrimary : .textColorSecondary
    }

    var titleFont: UIFont {
        guard !isVisible, let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withSymbolicTraits(.traitItalic) else { return .preferredFont(forTextStyle: .body) }
        return UIFont(descriptor: descriptor, size: 0)
    }

    init(item: OAFavoriteFolderBridgeItem) {
        bridgeItem = item
    }
}

struct FavoritePointRow: Hashable, FavoriteSortablePoint {
    let bridgeItem: OAFavoritePointBridgeItem

    var title: String { bridgeItem.title }

    var distance: CLLocationDistance? { bridgeItem.distance?.doubleValue }

    var lastModified: Date? { bridgeItem.timestampDate }

    var titleColor: UIColor {
        bridgeItem.isVisible ? .textColorPrimary : .textColorSecondary
    }

    var titleFont: UIFont {
        guard !bridgeItem.isVisible, let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withSymbolicTraits(.traitItalic) else { return .preferredFont(forTextStyle: .body) }
        return UIFont(descriptor: descriptor, size: 0)
    }

    init(item: OAFavoritePointBridgeItem) {
        bridgeItem = item
    }
}

struct FavoriteFolderStats: Hashable {
    let foldersCount: Int
    let pointsCount: Int
    let fileSize: Int64

    var text: String {
        var parts: [String] = []
        if foldersCount > 0 {
            parts.append("\(localizedString("shared_string_folders").lowercased()) \(foldersCount)")
        }

        parts.append("\(localizedString("shared_string_gpx_points").lowercased()) \(pointsCount)")
        parts.append("\(localizedString("shared_string_size").lowercased()) \(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))")
        let text = parts.joined(separator: ", ") + "."
        return text.prefix(1).uppercased() + String(text.dropFirst())
    }
}

final class FavoriteListCell: UICollectionViewListCell {
    private static let rowHeight: CGFloat = 68.0

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        attributes.frame.size.height = max(Self.rowHeight, attributes.frame.height)
        return attributes
    }
}
