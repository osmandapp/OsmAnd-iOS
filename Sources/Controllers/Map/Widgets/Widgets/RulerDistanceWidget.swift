//
//  RulerDistanceWidget.swift
//  OsmAnd Maps
//
//  Created by Paul on 20.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//
import Foundation

@objcMembers
class RulerDistanceWidget: OATextInfoWidget {

    let updateRulerObservable = OAObservable()
    private var updateRulerObserver: OAAutoObserverProxy?
    
    init(customId: String?, appMode: OAApplicationMode, widgetParams: ([String: Any])? = nil) {
        super.init(type: .radiusRuler)
        updateRulerObserver = OAAutoObserverProxy(self,
                                                       withHandler: #selector(onRulerUpdate),
                                                       andObserve: self.updateRulerObservable)
        setIconFor(.radiusRuler)
        onClickFunction = { [weak self] _ in
            let settings = OAAppSettings.sharedManager()!
            let mode = EOARulerWidgetMode(rawValue: Int(settings.rulerMode.get()))!
            if mode == .RULER_MODE_DARK {
                settings.rulerMode.set(Int32(EOARulerWidgetMode.RULER_MODE_LIGHT.rawValue))
            } else if mode == .RULER_MODE_LIGHT {
                settings.rulerMode.set(Int32(EOARulerWidgetMode.RULER_MODE_NO_CIRCLES.rawValue))
            } else if mode == .RULER_MODE_NO_CIRCLES {
                settings.rulerMode.set(Int32(EOARulerWidgetMode.RULER_MODE_DARK.rawValue))
            }
            self?.onRulerUpdate()
        }
        configurePrefs(withId: customId, appMode: appMode, widgetParams: widgetParams)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        updateRulerObserver = OAAutoObserverProxy(self,
                                                       withHandler: #selector(onRulerUpdate),
                                                       andObserve: updateRulerObservable)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        updateRulerObserver?.detach()
    }

    override func updateInfo() -> Bool {
        if let currentLocation = OsmAndApp.swiftInstance().locationServices?.lastKnownLocation {
            let centerLocation = OARootViewController.instance().mapPanel.mapViewController.getMapLocation()
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
        if OAAppSettings.sharedManager().rulerMode.get() == EOARulerWidgetMode.RULER_MODE_NO_CIRCLES.rawValue {
            setIcon("widget_hidden")
        } else {
            setIconFor(.radiusRuler)
        }
        OARootViewController.instance().mapPanel.hudViewController?.mapInfoController.updateRuler()
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
        settingRow.iconName = pref.get(appMode) == EOARulerWidgetMode.RULER_MODE_NO_CIRCLES.rawValue ? "ic_action_ruler_circle_hide" : "ic_action_ruler_circle"
        settingRow.descr = localizedString("ruler_circles")
        settingRow.setObj(pref, forKey: "pref")
        settingRow.setObj(getModeTitle(Int(pref.get(appMode))), forKey: "value")
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
        darkRow.setObj(OACommonRulerWidgetMode.getKeyForValue(NSNumber(value: EOARulerWidgetMode.RULER_MODE_DARK.rawValue), defValue: "")!, forKey: "value")
        darkRow.title = getModeTitle(EOARulerWidgetMode.RULER_MODE_DARK.rawValue)
        
        let lightRow = OATableRowData()
        lightRow.cellType = OASimpleTableViewCell.getIdentifier()
        lightRow.setObj(OACommonRulerWidgetMode.getKeyForValue(NSNumber(value: EOARulerWidgetMode.RULER_MODE_LIGHT.rawValue), defValue: "")!, forKey: "value")
        lightRow.title = getModeTitle(EOARulerWidgetMode.RULER_MODE_LIGHT.rawValue)
        
        let disabledRow = OATableRowData()
        disabledRow.cellType = OASimpleTableViewCell.getIdentifier()
        disabledRow.setObj(OACommonRulerWidgetMode.getKeyForValue(NSNumber(value: EOARulerWidgetMode.RULER_MODE_NO_CIRCLES.rawValue), defValue: "")!, forKey: "value")
        disabledRow.title = getModeTitle(EOARulerWidgetMode.RULER_MODE_NO_CIRCLES.rawValue)
        
        return [darkRow, lightRow, disabledRow]
    }
    
    private func getModeTitle(_ mode: Int) -> String {
        switch EOARulerWidgetMode(rawValue: mode) {
        case .RULER_MODE_DARK:
            return localizedString("shared_string_dark")
        case .RULER_MODE_LIGHT:
            return localizedString("shared_string_light")
        case .RULER_MODE_NO_CIRCLES:
            return localizedString("shared_string_hide")
        default:
            fatalError()
        }
    }
    
}
