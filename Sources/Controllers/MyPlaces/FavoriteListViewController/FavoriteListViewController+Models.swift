//
//  FavoriteListViewController+Models.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 04.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

enum ScreenMode {
    case root
    case folder(String, previousTitle: String)
}

enum FavoriteFolderSection: String, Hashable {
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

    var isFolder: Bool {
        if case .folderSection = self {
            return true
        }

        return false
    }
}

enum FavoriteListItem: Hashable {
    case sortHeader(FavoriteSortHeader)
    case backupBanner
    case header(FavoriteFolderSection)
    case folder(FavoriteFolderRow)
    case favorite(FavoritePointRow)
    case statsFooter(FavoriteFolderStats)
    case emptyState
    
    var selectionItem: FavoriteSelectionItem? {
        switch self {
        case .folder(let folder):
            return .folder(folder.fullPath)
        case .favorite(let favorite):
            return .favorite(favorite.bridgeItem.identifier)
        default:
            return nil
        }
    }

    var patchIdentifier: FavoriteListItemPatchIdentifier {
        switch self {
        case .sortHeader:
            return .sortHeader
        case .backupBanner:
            return .backupBanner
        case .header(let section):
            return .header(section)
        case .folder(let folder):
            return .folder(folder.fullPath)
        case .favorite(let favorite):
            return .favorite(favorite.bridgeItem.identifier)
        case .statsFooter:
            return .statsFooter
        case .emptyState:
            return .emptyState
        }
    }
}

enum FavoriteListItemPatchIdentifier: Hashable {
    case sortHeader
    case backupBanner
    case header(FavoriteFolderSection)
    case folder(String)
    case favorite(String)
    case statsFooter
    case emptyState
}

enum FavoriteSelectionItem: Hashable {
    case folder(String)
    case favorite(String)
}

struct FavoriteSortHeader: Hashable {
    let sortMode: FavoriteSortMode
    let includesDistanceSortModes: Bool
}

struct FavoriteFolderRow: Hashable, FavoriteSortableFolder {
    private static let subtitleDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dMMM")
        return formatter
    }()

    let fullPath: String
    let group: OAFavoriteFolderBridgeItem?
    let lastModified: Date?
    let subtreePointsCount: Int

    var title: String { group?.title ?? OAFavoritesHelperBridge.shared().displayName(forFavoriteGroup: FavoriteFolderPath.lastSegment(fullPath)) }
    var isVisible: Bool { group?.isVisible ?? true }
    var isPinned: Bool { group?.isPinned ?? false }
    var subtitle: String {
        let pointsText = "\(NumberFormatter.localizedCount(subtreePointsCount)) \(localizedString("shared_string_gpx_points").lowercased())"
        guard let lastModified else { return pointsText }
        return String(format: localizedString("ltr_or_rtl_combine_via_comma"), Self.subtitleDateFormatter.string(from: lastModified), pointsText)
    }

    var iconName: String {
        isVisible ? "ic_custom_folder" : "ic_custom_folder_hidden_outlined"
    }

    var iconColor: UIColor {
        isVisible ? (group?.color ?? .iconColorSelected) : .iconColorSecondary
    }

    var titleColor: UIColor {
        isVisible ? .textColorPrimary : .textColorSecondary
    }

    var titleFont: UIFont {
        guard !isVisible, let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).withSymbolicTraits(.traitItalic) else { return .preferredFont(forTextStyle: .body) }
        return UIFont(descriptor: descriptor, size: 0)
    }

    init(folder: FavoriteFolder) {
        fullPath = folder.getFullPath()
        let group = folder.getGroup()
        self.group = group
        if folder.isRoot() {
            lastModified = group?.lastModifiedDate
            subtreePointsCount = folder.getExactPointsCount()
        } else {
            let timestamp = folder.getSubtreeLastModified()
            lastModified = timestamp > 0 ? Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0) : nil
            subtreePointsCount = folder.getSubtreePointsCount()
        }
    }
}

struct FavoritePointRow: Hashable, FavoriteSortablePoint {
    let bridgeItem: OAFavoritePointBridgeItem

    var title: String { bridgeItem.title }

    var distance: CLLocationDistance? { bridgeItem.distance?.doubleValue }

    var lastModified: Date? { bridgeItem.timestampDate }

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
            parts.append("\(localizedString("shared_string_folders").lowercased()) \(NumberFormatter.localizedCount(foldersCount))")
        }

        parts.append("\(localizedString("shared_string_gpx_points").lowercased()) \(formattedPointsCount)")
        let firstLine = parts.joined(separator: ", ")
        let secondLine = "\(localizedString("shared_string_size").lowercased()) \(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))"
        return [firstLine, secondLine].map { (OAUtilities.capitalizeFirstLetter($0) ?? "") + "." }.joined(separator: "\n")
    }

    private var formattedPointsCount: String {
        NumberFormatter.localizedCount(pointsCount)
    }
}

final class FavoriteListCell: UICollectionViewListCell {
    private static let rowHeight: CGFloat = 68.0
    private var separatorConstraint: NSLayoutConstraint?
    private weak var primaryTextLayoutGuide: UILayoutGuide?

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        guard let textContentView = primaryTextLayoutGuide?.owningView, textContentView.bounds.width > 0 else {
            attributes.frame.size.height = ceil(max(Self.rowHeight, attributes.frame.height))
            return attributes
        }

        let targetSize = CGSize(width: textContentView.bounds.width, height: UIView.layoutFittingCompressedSize.height)
        let contentHeight = textContentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel).height
        attributes.frame.size.height = ceil(max(Self.rowHeight, max(attributes.frame.height, contentHeight)))
        return attributes
    }

    func setPrimaryTextLayoutGuide(_ layoutGuide: UILayoutGuide?) {
        guard primaryTextLayoutGuide !== layoutGuide else { return }
        separatorConstraint?.isActive = false
        separatorConstraint = nil
        primaryTextLayoutGuide = layoutGuide
        guard let layoutGuide else { return }
        separatorConstraint = separatorLayoutGuide.leadingAnchor.constraint(equalTo: layoutGuide.leadingAnchor)
        separatorConstraint?.isActive = true
    }
}
