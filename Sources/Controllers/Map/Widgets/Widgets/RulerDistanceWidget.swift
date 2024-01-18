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

    let updateRulerObservable = OAObservable()
    private var updateRulerObserver: OAAutoObserverProxy?
    
    init(customId: String?, appMode: OAApplicationMode, widgetParams: ([String: Any])? = nil) {
        super.init(type: .radiusRuler)
        self.updateRulerObserver = OAAutoObserverProxy(self,
                                                       withHandler: #selector(onRulerUpdate),
                                                       andObserve: self.updateRulerObservable)
        setIconFor(.radiusRuler)
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
            self?.onRulerUpdate()
        }
        configurePrefs(withId: customId, appMode: appMode)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.updateRulerObserver = OAAutoObserverProxy(self,
                                                       withHandler: #selector(onRulerUpdate),
                                                       andObserve: self.updateRulerObservable)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        updateRulerObserver?.detach()
    }

    override func updateInfo() -> Bool {
        if let currentLocation = OsmAndApp.swiftInstance().locationServices?.lastKnownLocation,
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

    @objc private func onRulerUpdate() {
        if OAAppSettings.sharedManager().rulerMode.get() == .RULER_MODE_NO_CIRCLES {
            self.setIcon("widget_hidden")
        } else {
            self.setIconFor(.radiusRuler)
        }
        OARootViewController.instance().mapPanel.hudViewController.mapInfoController.updateRuler()
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
        settingRow.setObj(pref, forKey: "pref")
        settingRow.setObj(getModeTitle(pref.get(appMode)), forKey: "value")
        settingRow.setObj(getPossibleValues(), forKey: "possible_values")
        
        let compassRow = section.createNewRow()
        compassRow.cellType = OASwitchTableViewCell.getIdentifier()
        compassRow.title = localizedString("compass_on_circles")
        compassRow.iconName = "ic_custom_compass_widget"
        compassRow.setObj("ic_custom_compass_widget_hide", forKey: "hide_icon")
        compassRow.setObj(settings.showCompassControlRuler!, forKey: "pref")
        
        return data
    }
    
    private func getPossibleValues() -> [OATableRowData] {
        let darkRow = OATableRowData()
        darkRow.cellType = OASimpleTableViewCell.getIdentifier()
        darkRow.setObj(OACommonRulerWidgetMode.rulerWidgetMode(toString: .RULER_MODE_DARK)!, forKey: "value")
        darkRow.title = getModeTitle(.RULER_MODE_DARK)
        
        let lightRow = OATableRowData()
        lightRow.cellType = OASimpleTableViewCell.getIdentifier()
        lightRow.setObj(OACommonRulerWidgetMode.rulerWidgetMode(toString: .RULER_MODE_LIGHT)!, forKey: "value")
        lightRow.title = getModeTitle(.RULER_MODE_LIGHT)
        
        let disabledRow = OATableRowData()
        disabledRow.cellType = OASimpleTableViewCell.getIdentifier()
        disabledRow.setObj(OACommonRulerWidgetMode.rulerWidgetMode(toString: .RULER_MODE_NO_CIRCLES)!, forKey: "value")
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
