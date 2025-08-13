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

    static let prefBaseId = "glide_widget_show_target_altitude"

    private let widgetType: WidgetType
    private let preference: OACommonBoolean

    init(_ customId: String?, widgetParams: ([String: Any])? = nil) {
        widgetType = .glideTarget
        preference = Self.registerPreference(customId, widgetParams: widgetParams)
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

    private static func registerPreference(_ customId: String?, widgetParams: ([String: Any])? = nil) -> OACommonBoolean {
        var prefId = Self.prefBaseId
        if let customId, !customId.isEmpty {
            prefId += "_\(customId)"
        }
        
        let preference = OAAppSettings.sharedManager().registerBooleanPreference(prefId, defValue: false).makeProfile()!
        if let string = widgetParams?[Self.prefBaseId] as? String, let widgetValue = Bool(string) {
            preference.set(widgetValue)
        }
        return preference
    }
}
