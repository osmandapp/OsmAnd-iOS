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
    
    private static func registerPreference(_ customId: String?) -> OACommonWidgetZoomLevelType {
        var prefId = "zoom_level_type"
        if let customId, !customId.isEmpty {
            prefId += "_\(customId)"
        }
        return OAAppSettings.sharedManager().registerWidgetZoomLevelTypePreference(prefId, defValue: .zoom).makeProfile()
    }
    
    override func getMenuTitle() -> String {
        widgetType.title
    }
    
    override func getSettingsIconId(_ night: Bool) -> String {
        widgetType.iconName
    }
    
//    override func changeToNextState() {
//        print("changeToNextState")
//        // typePreference.set(!typePreference.get())
//    }
    
    override func copyPrefs(_ appMode: OAApplicationMode, customId: String?) {
        Self.registerPreference(customId).set(typePreference.get(appMode), mode: appMode)
    }
    
    func getZoomLevelType() -> EOAWidgetZoomLevelType {
        typePreference.get()
    }
    
    //    enum ZoomLevelType: Int, CaseIterable {
    //        case zoom = 0
    //        case mapScale = 1
    //
    //        var titleId: Int {
    //            switch self {
    //            case .zoom:
    //                return R.string.map_widget_zoom_level
    //            case .mapScale:
    //                return R.string.map_widget_map_scale
    //            }
    //        }
    //
    //        func next() -> ZoomLevelType {
    //            let nextIndex = (self.rawValue + 1) % ZoomLevelType.allCases.count
    //            return ZoomLevelType(rawValue: nextIndex)!
    //        }
    //    }
}
