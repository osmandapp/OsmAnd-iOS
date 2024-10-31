//
//  ZoomLevelWidgetState.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 28.10.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

@objcMembers
final class ZoomLevelWidgetState: OAWidgetState {
    
    private(set) var typePreference: OACommonWidgetZoomLevelType
    private(set) var widgetType: WidgetType
    
    init(customId: String?, widgetType: WidgetType) {
        self.typePreference = Self.registerPreference(customId)
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
    
    private static func registerPreference(_ customId: String?) -> OACommonWidgetZoomLevelType {
        var prefId = "zoom_level_type" // zoom_level_typedev_zoom_level__17303691733
        if let customId, !customId.isEmpty {
            prefId += "\(customId)"
        }
        return OAAppSettings.sharedManager().registerWidgetZoomLevelTypePreference(prefId, defValue: .zoom).makeProfile()
    }
}
