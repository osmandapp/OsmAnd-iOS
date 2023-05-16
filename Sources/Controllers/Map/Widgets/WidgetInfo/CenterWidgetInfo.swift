//
//  CenterWidgetInfo.swift
//  OsmAnd Maps
//
//  Created by Paul on 04.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OACenterWidgetInfo)
class CenterWidgetInfo: MapWidgetInfo {
    
    override func getUpdatedPanel() -> WidgetsPanel {
        return widgetPanel
    }
    
    override func isEnabledForAppMode(_ appMode: OAApplicationMode) -> Bool {
        let visibilityPref = widget.getWidgetVisibilityPref()
        return visibilityPref == nil || visibilityPref!.get(appMode)
    }
    
    override func enableDisable(appMode: OAApplicationMode, enabled: NSNumber?) {
        let visibilityPref = widget.getWidgetVisibilityPref()
        if let visibilityPref = visibilityPref {
            if enabled == nil {
                visibilityPref.resetMode(toDefault: appMode)
            } else {
                visibilityPref.set(enabled!.boolValue, mode: appMode)
            }
        }
        let settingsPref = widget.getWidgetSettingsPref(toReset: appMode)
        if (enabled == nil || enabled!.boolValue == false), let settingsPref {
            settingsPref.resetMode(toDefault: appMode)
        }
    }
}
