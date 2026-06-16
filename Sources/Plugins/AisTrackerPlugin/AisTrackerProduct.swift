//
//  AisTrackerProduct.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 15.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@objcMembers
final class AisTrackerProduct: OAProduct {
    override init() {
        super.init(identifier: kInAppId_Addon_Ais_Tracker)
    }

    override var free: Bool {
        true
    }

    override func productIconName() -> String {
        "ic_plugin_nautical"
    }

    override func productScreenshotName() -> String {
        "ais_map"
    }

    override var localizedTitle: String {
        localizedString("plugin_ais_tracker_name")
    }

    override var localizedDescription: String {
        localizedString("plugin_ais_tracker_description")
    }

    override var localizedDescriptionExt: String {
        localizedString("plugin_ais_tracker_description") + "\n\n" + localizedString("plugin_ais_tracker_disclaimer")
    }
}
