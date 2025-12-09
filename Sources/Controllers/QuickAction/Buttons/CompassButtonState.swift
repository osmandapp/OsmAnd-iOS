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

    static let compassHudId = "map.view.compass"

    let visibilityPref: OACommonInteger

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
    
    override func getPreviewIcon() -> UIImage? {
        UIImage(named: CompassModeWrapper.iconName(forValue: Int(OAAppSettings.sharedManager().rotateMap.get()), isLightMode: ThemeManager.shared.isLightTheme()))
    }
    
    override func setupButtonPosition(_ position: ButtonPositionSize) -> ButtonPositionSize {
        setupButtonPosition(position, posH: ButtonPositionSize.companion.POS_LEFT, posV: ButtonPositionSize.companion.POS_TOP, xMove: false, yMove: true)
    }
    
    override func storedVisibilityPref() -> OACommonInteger {
        visibilityPref
    }
    
    override func copyPrefs(from fromMode: OAApplicationMode, to toMode: OAApplicationMode) {
        visibilityPref.set(getVisibility(fromMode).rawValue, mode: toMode)
    }

    func getVisibility() -> CompassVisibility {
        CompassVisibility(rawValue: visibilityPref.get())!
    }

    func getVisibility(_ mode: OAApplicationMode) -> CompassVisibility {
        CompassVisibility(rawValue: visibilityPref.get(mode))!
    }

    private static func createVisibilityPref() -> OACommonInteger {
        let settings = OAAppSettings.sharedManager()
        guard let preference = settings.getPreferenceByKey("compass_visibility") as? OACommonInteger else {
            let defaultValue = CompassVisibility.alwaysVisible.rawValue
            return settings.registerIntPreference("compass_visibility", defValue: defaultValue).makeProfile()
        }
        return preference
    }
}
