//
//  MyPlacesSortModeHelper.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 22.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

enum MyPlacesSortMode: String, CaseIterable {
    case lastModified = "LAST_MODIFIED"
    case nameAZ = "NAME_ASCENDING"
    case nameZA = "NAME_DESCENDING"
    
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
}

@objcMembers
final class MyPlacesSortModeHelper: NSObject {
    static func defaultTravelGuidesSortMode() -> MyPlacesSortMode {
        .lastModified
    }
    
    static func defaultTravelGuidesSortModeValue() -> String {
        defaultTravelGuidesSortMode().rawValue
    }
    
    static func defaultOsmEditsSortMode() -> MyPlacesSortMode {
        .nameAZ
    }
    
    static func defaultOsmEditsSortModeValue() -> String {
        defaultOsmEditsSortMode().rawValue
    }
    
    static func sortTravelGuidesWithMode(_ travelGuides: [TravelArticle], mode: MyPlacesSortMode) -> [TravelArticle] {
        switch mode {
        case .lastModified: travelGuides.sorted { $0.lastModified > $1.lastModified }
        case .nameAZ: travelGuides.sorted { ($0.title ?? "").localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending }
        case .nameZA: travelGuides.sorted { ($0.title ?? "").localizedCaseInsensitiveCompare($1.title ?? "") == .orderedDescending }
        }
    }
    
    static func sortOsmEditsWithMode(_ osmEdits: [OAOsmPoint], mode: MyPlacesSortMode) -> [OAOsmPoint] {
        switch mode {
        case .nameAZ: osmEdits.sorted { ($0.getName()).localizedCaseInsensitiveCompare($1.getName()) == .orderedAscending }
        case .nameZA: osmEdits.sorted { ($0.getName()).localizedCaseInsensitiveCompare($1.getName()) == .orderedDescending }
        default: []
        }
    }
}
