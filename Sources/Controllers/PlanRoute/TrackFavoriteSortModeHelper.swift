//
//  TrackFavoriteSortModeHelper.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 01.07.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

@objc enum TrackFavoriteSortMode: Int, CaseIterable {
    case lastModified
    case nameAZ
    case nameZA
    case newestDateFirst
    case oldestDateFirst
    
    var title: String {
        switch self {
        case .lastModified: return localizedString("sort_last_modified")
        case .nameAZ: return localizedString("track_sort_az")
        case .nameZA: return localizedString("track_sort_za")
        case .newestDateFirst: return localizedString("newest_date_first")
        case .oldestDateFirst: return localizedString("oldest_date_first")
        }
    }
    
    var image: UIImage? {
        switch self {
        case .lastModified: return .icCustomLastModified
        case .nameAZ: return .icCustomSortNameAscending
        case .nameZA: return .icCustomSortNameDescending
        case .newestDateFirst: return .icCustomSortDateNewest
        case .oldestDateFirst: return .icCustomSortDateOldest
        }
    }
}

@objc final class TrackFavoriteSortModeHelper: NSObject {
    static func defaultSortMode() -> TrackFavoriteSortMode {
        .nameAZ
    }
    
    static func sortTrackPointsWithMode(_ points: [PlanRoutePoiPoint], mode: TrackFavoriteSortMode) -> [PlanRoutePoiPoint] {
        points.sorted { comparePoints($0, $1, mode: mode) == .orderedAscending }
    }
    
    private static func comparePoints(_ lhs: PlanRoutePoiPoint, _ rhs: PlanRoutePoiPoint, mode: TrackFavoriteSortMode) -> ComparisonResult {
        switch mode {
        case .lastModified, .newestDateFirst:
            return compareTimes(pointTime(lhs), pointTime(rhs), newestFirst: true, lhsName: lhs.name, rhsName: rhs.name)
        case .oldestDateFirst:
            return compareTimes(pointTime(lhs), pointTime(rhs), newestFirst: false, lhsName: lhs.name, rhsName: rhs.name)
        case .nameAZ:
            return compareNames(lhs.name, rhs.name)
        case .nameZA:
            return compareNames(rhs.name, lhs.name)
        }
    }
    
    private static func compareTimes(_ lhs: Int?, _ rhs: Int?, newestFirst: Bool, lhsName: String, rhsName: String) -> ComparisonResult {
        if let lhs, let rhs, lhs != rhs {
            if newestFirst {
                return lhs > rhs ? .orderedAscending : .orderedDescending
            }
            return lhs < rhs ? .orderedAscending : .orderedDescending
        } else if lhs != nil {
            return .orderedAscending
        } else if rhs != nil {
            return .orderedDescending
        }
        
        return compareNames(lhsName, rhsName)
    }
    
    private static func compareNames(_ lhs: String, _ rhs: String) -> ComparisonResult {
        lhs.localizedCaseInsensitiveCompare(rhs)
    }
    
    private static func pointTime(_ point: PlanRoutePoiPoint) -> Int? {
        guard let wpt = point.item.point else { return nil }
        let time = Int(wpt.time)
        return time > 0 ? time : nil
    }
}
