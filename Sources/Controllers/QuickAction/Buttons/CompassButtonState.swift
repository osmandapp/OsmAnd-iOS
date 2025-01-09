//
//  CompassButtonState.swift
//  OsmAnd Maps
//
//  Created by Skalii on 27.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class CompassButtonState: MapButtonState {

    static let compassHudId = "compass"

    let visibilityPref: OACommonCompassVisibility

    init() {
        visibilityPref = Self.createVisibilityPref()
        super.init(withId: Self.compassHudId)
    }

    override func getName() -> String {
        localizedString("map_widget_compass")
    }

    override func isEnabled() -> Bool {
        getVisibility() != .alwaysHidden
    }

    override func getIcon() -> UIImage? {
        UIImage.templateImageNamed(getVisibility().iconName)
    }

    func getVisibility() -> CompassVisibility {
        CompassVisibility(rawValue: visibilityPref.get())!
    }

    func getVisibility(_ mode: OAApplicationMode) -> CompassVisibility {
        CompassVisibility(rawValue: visibilityPref.get(mode))!
    }

    private static func createVisibilityPref() -> OACommonCompassVisibility {
        return OAAppSettings.sharedManager()!.registerCompassVisibilityPreference("compass_visibility", defValue: CompassVisibility.alwaysVisible.rawValue).makeProfile()
    }
}
