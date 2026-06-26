//
//  FavoriteSortModeHelper.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 05.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit
import CoreLocation

protocol FavoriteSortableFolder {
    var title: String { get }
    var isVisible: Bool { get }
    var isPinned: Bool { get }
    var lastModified: Date? { get }
}

protocol FavoriteSortablePoint {
    var title: String { get }
    var distance: CLLocationDistance? { get }
    var lastModified: Date? { get }
}

@objc enum FavoriteSortMode: Int, CaseIterable {
    case lastModified
    case nameAZ
    case nameZA
    case nearest
    case farthest
    case newestDateFirst
    case oldestDateFirst

    var title: String {
        switch self {
        case .lastModified: return localizedString("sort_last_modified")
        case .nameAZ: return localizedString("track_sort_az")
        case .nameZA: return localizedString("track_sort_za")
        case .nearest: return localizedString("distance_nearest")
        case .farthest: return localizedString("distance_farthest")
        case .newestDateFirst: return localizedString("newest_date_first")
        case .oldestDateFirst: return localizedString("oldest_date_first")
        }
    }

    var image: UIImage? {
        switch self {
        case .lastModified: return .icCustomLastModified
        case .nameAZ: return .icCustomSortNameAscending
        case .nameZA: return .icCustomSortNameDescending
        case .nearest: return .icCustomSortNear
        case .farthest: return .icCustomSortFar
        case .newestDateFirst: return .icCustomSortDateNewest
        case .oldestDateFirst: return .icCustomSortDateOldest
        }
    }
    
    var isDateOriented: Bool {
        self == .lastModified || self == .newestDateFirst || self == .oldestDateFirst
    }
    
    var isDistanceOriented: Bool {
        self == .nearest || self == .farthest
    }

    static func byTitle(_ title: String) -> FavoriteSortMode {
        allCases.first { $0.title == title } ?? .nameAZ
    }
}

@objc final class FavoriteSortModeHelper: NSObject {
    static func sortFoldersWithMode<Folder: FavoriteSortableFolder>(_ folders: [Folder], mode: FavoriteSortMode) -> [Folder] {
        folders.sorted { compareFolders($0, $1, mode: mode) == .orderedAscending }
    }

    static func sortFavoritePointsWithMode<Point: FavoriteSortablePoint>(_ points: [Point], mode: FavoriteSortMode) -> [Point] {
        points.sorted { compareFavoritePoints($0, $1, mode: mode) == .orderedAscending }
    }

    static func defaultSortMode() -> FavoriteSortMode {
        .nameAZ
    }

    @objc static func defaultSortModeTitle() -> String {
        defaultSortMode().title
    }

    private static func compareFolders<Folder: FavoriteSortableFolder>(_ lhs: Folder, _ rhs: Folder, mode: FavoriteSortMode) -> ComparisonResult {
        if lhs.isPinned != rhs.isPinned {
            return lhs.isPinned ? .orderedAscending : .orderedDescending
        }

        if lhs.isVisible != rhs.isVisible {
            return lhs.isVisible ? .orderedAscending : .orderedDescending
        }

        switch mode {
        case .lastModified, .newestDateFirst:
            return compareDates(lhs.lastModified, rhs.lastModified, newestFirst: true, lhsTitle: lhs.title, rhsTitle: rhs.title)
        case .oldestDateFirst:
            return compareDates(lhs.lastModified, rhs.lastModified, newestFirst: false, lhsTitle: lhs.title, rhsTitle: rhs.title)
        case .nameAZ:
            return compareTitles(lhs.title, rhs.title)
        case .nameZA:
            return compareTitles(rhs.title, lhs.title)
        case .nearest, .farthest:
            return .orderedSame
        }
    }

    private static func compareFavoritePoints<Point: FavoriteSortablePoint>(_ lhs: Point, _ rhs: Point, mode: FavoriteSortMode) -> ComparisonResult {
        switch mode {
        case .nameAZ:
            return compareTitles(lhs.title, rhs.title)
        case .nameZA:
            return compareTitles(rhs.title, lhs.title)
        case .nearest:
            return compareDistances(lhs.distance, rhs.distance, nearestFirst: true, lhsTitle: lhs.title, rhsTitle: rhs.title)
        case .farthest:
            return compareDistances(lhs.distance, rhs.distance, nearestFirst: false, lhsTitle: lhs.title, rhsTitle: rhs.title)
        case .lastModified, .newestDateFirst:
            return compareDates(lhs.lastModified, rhs.lastModified, newestFirst: true, lhsTitle: lhs.title, rhsTitle: rhs.title)
        case .oldestDateFirst:
            return compareDates(lhs.lastModified, rhs.lastModified, newestFirst: false, lhsTitle: lhs.title, rhsTitle: rhs.title)
        }
    }

    private static func compareDates(_ lhs: Date?, _ rhs: Date?, newestFirst: Bool, lhsTitle: String, rhsTitle: String) -> ComparisonResult {
        if let lhs, let rhs, lhs != rhs {
            return newestFirst ? rhs.compare(lhs) : lhs.compare(rhs)
        } else if lhs != nil {
            return .orderedAscending
        } else if rhs != nil {
            return .orderedDescending
        }

        return compareTitles(lhsTitle, rhsTitle)
    }

    private static func compareDistances(_ lhs: CLLocationDistance?, _ rhs: CLLocationDistance?, nearestFirst: Bool, lhsTitle: String, rhsTitle: String) -> ComparisonResult {
        if let lhs, let rhs, lhs != rhs {
            if nearestFirst {
                return lhs < rhs ? .orderedAscending : .orderedDescending
            }
            return lhs > rhs ? .orderedAscending : .orderedDescending
        } else if lhs != nil {
            return .orderedAscending
        } else if rhs != nil {
            return .orderedDescending
        }

        return compareTitles(lhsTitle, rhsTitle)
    }

    private static func compareTitles(_ lhs: String, _ rhs: String) -> ComparisonResult {
        lhs.localizedCaseInsensitiveCompare(rhs)
    }
}
