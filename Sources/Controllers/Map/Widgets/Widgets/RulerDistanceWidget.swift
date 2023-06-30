//
//  RulerDistanceWidget.swift
//  OsmAnd Maps
//
//  Created by Paul on 20.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OARulerDistanceWidget)
@objcMembers
class RulerDistanceWidget: OATextInfoWidget {
    
    init() {
        super.init(type: .radiusRuler)
        setIcons(.radiusRuler)
        onClickFunction = { [weak self] _ in
            let settings = OAAppSettings.sharedManager()!
            let mode = settings.rulerMode.get()
            if (mode == .RULER_MODE_DARK) {
                settings.rulerMode.set(.RULER_MODE_LIGHT)
            } else if (mode == .RULER_MODE_LIGHT) {
                settings.rulerMode.set(.RULER_MODE_NO_CIRCLES)
            } else if (mode == .RULER_MODE_NO_CIRCLES) {
                settings.rulerMode.set(.RULER_MODE_DARK)
            }
            if (settings.rulerMode.get() == .RULER_MODE_NO_CIRCLES) {
                self?.setIcons("widget_ruler_circle_hide_day", widgetNightIcon: "widget_ruler_circle_hide_night")
            } else {
                self?.setIcons(.radiusRuler)
            }
            OARootViewController.instance().mapPanel.hudViewController.mapInfoController.updateRuler()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateInfo() -> Bool {
        if let currentLocation = OsmAndApp.swiftInstance().locationServices.lastKnownLocation,
           let centerLocation = OARootViewController.instance().mapPanel.mapViewController.getMapLocation() {
            let trackingUtilities = OAMapViewTrackingUtilities.instance()!
            if trackingUtilities.isMapLinkedToLocation() {
                setText(OAOsmAndFormatter.getFormattedDistance(0), subtext: nil)
            } else {
                let distance = OAOsmAndFormatter.getFormattedDistance(Float(currentLocation.distance(from: centerLocation)))!
                if let ls = distance.range(of: " ", options: .backwards)?.lowerBound {
                    setText(String(distance[..<ls]), subtext: String(distance[distance.index(after: ls)...]))
                }
            }
        } else {
            setText("-", subtext: nil)
        }
        return true
    }
    
    override func getSettingsData(_ appMode: OAApplicationMode) -> OATableDataModel? {
        let settings = OAAppSettings.sharedManager()!
        let pref = settings.rulerMode!
        let data = OATableDataModel()
        let section = data.createNewSection()
        section.headerText = localizedString("shared_string_settings")
        
        let settingRow = section.createNewRow()
        settingRow.cellType = OAValueTableViewCell.getIdentifier()
        settingRow.key = "value_pref"
        settingRow.title = localizedString("distance_circles")
        settingRow.iconName = pref.get(appMode) == .RULER_MODE_NO_CIRCLES ? "ic_action_ruler_circle_hide" : "ic_action_ruler_circle"
        settingRow.descr = localizedString("ruler_circles")
        settingRow.setObj(getModeTitle(pref.get(appMode)), forKey: "value")
        settingRow.setObj(getPossibleValues(pref), forKey: "possible_values")
        
        let compassRow = section.createNewRow()
        compassRow.cellType = OASwitchTableViewCell.getIdentifier()
        compassRow.title = localizedString("compass_on_circles")
        compassRow.iconName = "ic_custom_compass_widget"
        compassRow.setObj("ic_custom_compass_widget_hide", forKey: "hide_icon")
        compassRow.setObj(settings.showCompassControlRuler!, forKey: "pref")
        
        return data
    }
    
    private func getPossibleValues(_ pref: OACommonPreference) -> [OATableRowData] {
        let darkRow = OATableRowData()
        darkRow.cellType = OASimpleTableViewCell.getIdentifier()
        darkRow.setObj(OACommonRulerWidgetMode.rulerWidgetMode(toString: .RULER_MODE_DARK)!, forKey: "value")
        darkRow.setObj(pref, forKey: "pref")
        darkRow.title = getModeTitle(.RULER_MODE_DARK)
        
        let lightRow = OATableRowData()
        lightRow.cellType = OASimpleTableViewCell.getIdentifier()
        lightRow.setObj(OACommonRulerWidgetMode.rulerWidgetMode(toString: .RULER_MODE_LIGHT)!, forKey: "value")
        lightRow.setObj(pref, forKey: "pref")
        lightRow.title = getModeTitle(.RULER_MODE_LIGHT)
        
        let disabledRow = OATableRowData()
        disabledRow.cellType = OASimpleTableViewCell.getIdentifier()
        disabledRow.setObj(OACommonRulerWidgetMode.rulerWidgetMode(toString: .RULER_MODE_NO_CIRCLES)!, forKey: "value")
        disabledRow.setObj(pref, forKey: "pref")
        disabledRow.title = getModeTitle(.RULER_MODE_NO_CIRCLES)
        
        return [darkRow, lightRow, disabledRow]
    }
    
    private func getModeTitle(_ mode: EOARulerWidgetMode) -> String {
        switch mode {
        case .RULER_MODE_DARK:
            return localizedString("shared_string_dark")
        case .RULER_MODE_LIGHT:
            return localizedString("shared_string_light")
        case .RULER_MODE_NO_CIRCLES:
            return localizedString("shared_string_hide")
        @unknown default:
            fatalError()
        }
    }
    
}
