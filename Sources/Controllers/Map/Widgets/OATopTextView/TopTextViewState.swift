//
//  TopTextViewState.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 14.08.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objc(OATopTextViewState)
final class TopTextViewState: OAWidgetState {
    private static let showNextTurnPrefId = "show_next_turn_info"
    
    private let widgetType: WidgetType = .streetName
    @objc let showNextTurnPref: OACommonBoolean
    
    @objc
    init(customId: String?, widgetParams: ([String: Any])?) {
        showNextTurnPref = Self.registerShowNextTurnPreference(customId: customId, widgetParams: widgetParams)
    }
    
    override func getMenuTitle() -> String {
        widgetType.title
    }
    
    override func getSettingsIconId(_ night: Bool) -> String {
        widgetType.iconName
    }
    
    override func changeToNextState() {
        showNextTurnPref.set(!showNextTurnPref.get())
    }
    
    @objc
    func isShowNextTurnEnabled(with appMode: OAApplicationMode) -> Bool {
        showNextTurnPref.get(appMode)
    }
    
    override func copyPrefs(_ appMode: OAApplicationMode, customId: String?) {
        Self.registerShowNextTurnPreference(customId: customId).set(showNextTurnPref.get(appMode), mode: appMode)
    }
    
    private static func registerShowNextTurnPreference(customId: String?, widgetParams: ([String: Any])? = nil) -> OACommonBoolean {
        var prefId = showNextTurnPrefId
        if let customId, !customId.isEmpty {
            prefId += "_" + customId
        }
        let preference = OAAppSettings.sharedManager().registerBooleanPreference(prefId, defValue: false)!
        if let widgetValue = widgetParams?[showNextTurnPrefId] as? Bool {
            preference.set(widgetValue)
        }
        return preference
    }
}
