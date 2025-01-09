//
//  ZoomLevelWidgetState.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 28.10.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objcMembers
final class ZoomLevelWidgetState: OAWidgetState {
    static let zoomLevelType = "zoom_level_type"
    
    private(set) var typePreference: OACommonWidgetZoomLevelType
    private(set) var widgetType: WidgetType
    
    init(customId: String?, widgetType: WidgetType, widgetParams: ([String: Any])? = nil) {
        self.typePreference = Self.registerPreference(customId, widgetParams: widgetParams)
        self.widgetType = widgetType
    }

    override func getMenuTitle() -> String {
        widgetType.title
    }
    
    override func getSettingsIconId(_ night: Bool) -> String {
        widgetType.iconName
    }
    
    override func copyPrefs(_ appMode: OAApplicationMode, customId: String?) {
        Self.registerPreference(customId).set(typePreference.get(appMode), mode: appMode)
    }
    
    func getZoomLevelType() -> EOAWidgetZoomLevelType {
        typePreference.get()
    }
    
    private static func registerPreference(_ customId: String?, widgetParams: ([String: Any])? = nil) -> OACommonWidgetZoomLevelType {
        var prefId = Self.zoomLevelType
        if let customId, !customId.isEmpty {
            prefId += "\(customId)"
        }
        
        let preference = OAAppSettings.sharedManager().registerWidgetZoomLevelTypePreference(prefId, defValue: .zoom).makeProfile()!
        if let string = widgetParams?[Self.zoomLevelType] as? String, string == "MAP_SCALE" {
            preference.set(.mapScale)
        }
        return preference
    }
}
