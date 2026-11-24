//
//  OAPOIUIFilter+SearchIcon.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

extension OAPOIUIFilter {
    private static let customCategoryIconName = "mx_special_custom_category"

    var searchIcon: UIImage? {
        if isTopWikiFilter() {
            return .icCustomPopularPlaces
        }
        if let iconName = getIconResource() as? String, let icon = OAUtilities.getMxIcon(iconName) {
            return icon
        }
        return OAUtilities.getMxIcon(OAPOIUIFilter.getCustomFilterIconName(self)) ?? OAUtilities.getMxIcon(OAPOIUIFilter.customCategoryIconName)
    }
}
