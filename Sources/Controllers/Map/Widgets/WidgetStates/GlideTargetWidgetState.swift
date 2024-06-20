//
//  GlideTargetWidgetState.swift
//  OsmAnd Maps
//
//  Created by Skalii on 06.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAGlideTargetWidgetState)
@objcMembers
final class GlideTargetWidgetState: OAWidgetState {

    private static let prefBaseId = "glide_widget_show_target_altitude"

    private let widgetType: WidgetType
    private let preference: OACommonBoolean

    init(_ customId: String?) {
        widgetType = .glideTarget
        preference = Self.registerPreference(customId)
    }

    func getPreference() -> OACommonBoolean {
        preference
    }

    override func getMenuTitle() -> String {
        widgetType.title
    }

    override func getSettingsIconId(_ night: Bool) -> String {
        widgetType.iconName
    }

    override func changeToNextState() {
        preference.set(!preference.get())
    }

    override func copyPrefs(_ appMode: OAApplicationMode, customId: String?) {
        Self.registerPreference(customId).set(preference.get(appMode), mode: appMode)
    }

    private static func registerPreference(_ customId: String?) -> OACommonBoolean {
        var prefId = Self.prefBaseId
        if let customId, !customId.isEmpty {
            prefId += "_\(customId)"
        }
        return OAAppSettings.sharedManager().registerBooleanPreference(prefId, defValue: false).makeProfile()
    }
}
