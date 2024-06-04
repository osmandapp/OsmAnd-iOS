//
//  CompassButtonState.swift
//  OsmAnd Maps
//
//  Created by Skalii on 27.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

@objc(OACompassButtonState)
@objcMembers
class CompassButtonState: MapButtonState {

    public static let compassHudId = "compass"

    let visibilityPref: OACommonInteger

    init() {
        visibilityPref = Self.createVisibilityPref()
        super.init(Self.compassHudId)
    }

    override func getName() -> String {
        return localizedString("map_widget_compass")
    }

    override func isEnabled() -> Bool {
        return getVisibility() != .alwaysHidden
    }

    override func getIcon() -> UIImage? {
        return UIImage.templateImageNamed(getVisibility().iconName)
    }

    func getVisibility() -> CompassVisibility {
        return CompassVisibility(rawValue: visibilityPref.get())!
    }

    func getVisibility(_ mode: OAApplicationMode) -> CompassVisibility {
        return CompassVisibility(rawValue: visibilityPref.get(mode))!
    }

    private static func createVisibilityPref() -> OACommonInteger {
        let settings = OAAppSettings.sharedManager()!
        var preference = settings.getPreferenceByKey("compass_visibility") as? OACommonInteger
        if preference == nil {
            preference = settings.registerIntPreference("compass_visibility", defValue: CompassVisibility.visibleIfMapRotated.rawValue).makeProfile()//.cache()
        }
        return preference!
    }
}
