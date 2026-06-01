//
//  MyPlacesSortModeHelper.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 22.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@objc enum MyPlacesSortMode: Int, CaseIterable {
    case lastModified
    case nameAZ
    case nameZA
    
    var title: String {
        switch self {
        case .lastModified: return localizedString("sort_last_modified")
        case .nameAZ: return localizedString("track_sort_az")
        case .nameZA: return localizedString("track_sort_za")
        }
    }
    
    var image: UIImage? {
        switch self {
        case .lastModified: return .icCustomLastModified
        case .nameAZ: return .icCustomSortNameAscending
        case .nameZA: return .icCustomSortNameDescending
        }
    }
    
    static func byTitle(_ title: String) -> MyPlacesSortMode {
        MyPlacesSortMode.allCases.first(where: { $0.title == title }) ?? .lastModified
    }
}

@objcMembers
final class MyPlacesSortModeHelper: NSObject {
    @objc static func defaultSortMode() -> MyPlacesSortMode {
        .lastModified
    }
    
    @objc static func defaultSortModeTitle() -> String {
        title(for: defaultSortMode())
    }
    
    @objc static private func title(for mode: MyPlacesSortMode) -> String {
        mode.title
    }
    
    static func sortTravelGuidesWithMode(_ travelGuides: [TravelArticle], mode: MyPlacesSortMode) -> [TravelArticle] {
        switch mode {
        case .lastModified: travelGuides.sorted { $0.lastModified > $1.lastModified }
        case .nameAZ: travelGuides.sorted { ($0.title ?? "").localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending }
        case .nameZA: travelGuides.sorted { ($0.title ?? "").localizedCaseInsensitiveCompare($1.title ?? "") == .orderedDescending }
        }
    }
}
