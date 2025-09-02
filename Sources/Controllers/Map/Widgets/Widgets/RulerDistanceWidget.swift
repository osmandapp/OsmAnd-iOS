//
//  RulerDistanceWidget.swift
//  OsmAnd Maps
//
//  Created by Paul on 20.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

@objcMembers
final class RulerDistanceWidget: OATextInfoWidget {

    let updateRulerObservable = OAObservable()
    
    private let settings = OAAppSettings.sharedManager()
    private var updateRulerObserver: OAAutoObserverProxy?
    
    init(customId: String?, appMode: OAApplicationMode, widgetParams: ([String: Any])? = nil) {
        super.init(type: .radiusRuler)
        updateRulerObserver = OAAutoObserverProxy(self,
                                                  withHandler: #selector(onRulerUpdate),
                                                  andObserve: updateRulerObservable)
        setIconFor(.radiusRuler)
        onClickFunction = { [weak self] _ in
            guard let self else { return }
            let mode = settings.rulerMode.get()
            if mode == .RULER_MODE_DARK {
                settings.rulerMode.set(.RULER_MODE_LIGHT)
            } else if mode == .RULER_MODE_LIGHT {
                settings.rulerMode.set(.RULER_MODE_NO_CIRCLES)
            } else if mode == .RULER_MODE_NO_CIRCLES {
                settings.rulerMode.set(.RULER_MODE_DARK)
            }
            onRulerUpdate()
        }
        configurePrefs(withId: customId, appMode: appMode, widgetParams: widgetParams)
        applySettingsWith(params: widgetParams, appMode: appMode)
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

    override func getSettingsData(_ appMode: OAApplicationMode,
                                  widgetConfigurationParams: [String: Any]?,
                                  isCreate: Bool) -> OATableDataModel? {
        let pref = settings.rulerMode
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
        
        if var currentValue = EOARulerWidgetMode(rawValue: Int(pref.defValue)) {
            if let widgetConfigurationParams,
               let key = widgetConfigurationParams.keys.first(where: { $0.hasPrefix("rulerMode") }),
               let value = widgetConfigurationParams[key] as? String {
                currentValue = getModeFrom(value: value, appMode: appMode)
            } else {
                if !isCreate {
                    currentValue = pref.get(appMode)
                }
            }
            settingRow.setObj(getModeTitle(currentValue), forKey: "value")
        }
        settingRow.setObj(getPossibleValues(), forKey: "possible_values")
        
        let compassRow = section.createNewRow()
        compassRow.cellType = OASwitchTableViewCell.getIdentifier()
        compassRow.title = localizedString("compass_on_circles")
        compassRow.iconName = "ic_custom_compass_widget"
        compassRow.setObj("ic_custom_compass_widget_hide", forKey: "hide_icon")
        compassRow.setObj(settings.showCompassControlRuler, forKey: "pref")
        
        return data
    }
    
    private func applySettingsWith(params: ([String: Any])?, appMode: OAApplicationMode) {
        guard let params else { return }
        
        if let value = params["rulerMode"] as? String {
            settings.rulerMode.set(getModeFrom(value: value, appMode: appMode), mode: appMode)
        } else {
            settings.rulerMode.resetToDefault()
        }
        if let value = params["showCompassRuler"] as? Bool {
            settings.showCompassControlRuler.set(value, mode: appMode)
        } else {
            settings.showCompassControlRuler.resetToDefault()
        }
    }
    
    private func getPossibleValues() -> [OATableRowData] {
        let darkRow = OATableRowData()
        darkRow.cellType = OASimpleTableViewCell.getIdentifier()
        darkRow.setObj(OACommonRulerWidgetMode.rulerWidgetMode(toString: .RULER_MODE_DARK), forKey: "value")
        darkRow.title = getModeTitle(.RULER_MODE_DARK)
        
        let lightRow = OATableRowData()
        lightRow.cellType = OASimpleTableViewCell.getIdentifier()
        lightRow.setObj(OACommonRulerWidgetMode.rulerWidgetMode(toString: .RULER_MODE_LIGHT), forKey: "value")
        lightRow.title = getModeTitle(.RULER_MODE_LIGHT)
        
        let disabledRow = OATableRowData()
        disabledRow.cellType = OASimpleTableViewCell.getIdentifier()
        disabledRow.setObj(OACommonRulerWidgetMode.rulerWidgetMode(toString: .RULER_MODE_NO_CIRCLES), forKey: "value")
        disabledRow.title = getModeTitle(.RULER_MODE_NO_CIRCLES)
        
        return [darkRow, lightRow, disabledRow]
    }
    
    private func getModeFrom(value: String, appMode: OAApplicationMode) -> EOARulerWidgetMode {
        switch value {
        case "FIRST": .RULER_MODE_DARK
        case "SECOND": .RULER_MODE_LIGHT
        case "EMPTY": .RULER_MODE_NO_CIRCLES
        default: fatalError("Unexpected value: \(value)")
        }
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
            fatalError("getModeTitle unknown mode")
        }
    }
    
    @objc private func onRulerUpdate() {
        if OAAppSettings.sharedManager().rulerMode.get() == .RULER_MODE_NO_CIRCLES {
            setIcon("widget_hidden")
        } else {
            setIconFor(.radiusRuler)
        }
        OARootViewController.instance().mapPanel.hudViewController?.mapInfoController.updateRuler()
    }
}
