//
//  MigrationManager.swift
//  OsmAnd Maps
//
//  Created by Skalii on 13.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAMigrationManager)
@objcMembers
final class MigrationManager: NSObject {

    static let importExportVersionMigration1 = 1
    static let importExportVersionMigration2 = 2

    enum MigrationKey: String {
        case migrationChangeWidgetIds1Key
        case migrationChangeQuickActionIds1Key
    }

    static let shared = MigrationManager()
    let defaults = UserDefaults.standard
    private let settings = OAAppSettings.sharedManager()

    private override init() {}

    func migrateIfNeeded(_ isFirstLaunch: Bool) {
        if isFirstLaunch {
            defaults.set(true, forKey: MigrationKey.migrationChangeWidgetIds1Key.rawValue)
            defaults.set(true, forKey: MigrationKey.migrationChangeQuickActionIds1Key.rawValue)
        } else {

            /*  Migration 1, sync with android

                widget panels:

                top_widget_panel_order -> widget_top_panel_order
                bottom_widget_panel_order -> widget_bottom_panel_order

                BLE sensor widget IDs:

                heartRate -> ant_heart_rate
                bicycleCadence -> ant_bicycle_cadence
                bicycleDistance -> ant_bicycle_distance
                bicycleSpeed -> ant_bicycle_speed
                temperature -> temperature_sensor

                saved device ids:

                OATrackRecordingNone -> ""
                OATrackRecordingAnyConnected -> any_connected_device_write_sensor_data_to_track_key */

            if !defaults.bool(forKey: MigrationKey.migrationChangeWidgetIds1Key.rawValue) {
                changeWidgetIdsMigration1()
                defaults.set(true, forKey: MigrationKey.migrationChangeWidgetIds1Key.rawValue)
            }
            if !defaults.bool(forKey: MigrationKey.migrationChangeQuickActionIds1Key.rawValue) {
                changeQuickActionIdsMigration1()
                migrateActionButtons()
                defaults.set(true, forKey: MigrationKey.migrationChangeQuickActionIds1Key.rawValue)
            }
        }
    }

    private func changeWidgetIdsMigration1() {
        if let settings = OAAppSettings.sharedManager() {
            let externalPlugin = OAPluginsHelper.getPlugin(OAExternalSensorsPlugin.self) as? OAExternalSensorsPlugin
            let externalSensorsPluginPrefs: [OACommonPreference]? = externalPlugin?.getPreferences()
            let changeWidgetIds = [
                "heartRate": "ant_heart_rate",
                "bicycleCadence": "ant_bicycle_cadence",
                "bicycleDistance": "ant_bicycle_distance",
                "bicycleSpeed": "ant_bicycle_speed",
                "temperature": "temperature_sensor"
            ]
            for mode in OAApplicationMode.allPossibleValues() {
                updateExistingWidgetIds(mode,
                                        changeWidgetIds: changeWidgetIds,
                                        panelPreference: settings.topWidgetPanelOrderOld,
                                        newPanelPreference: settings.topWidgetPanelOrder)

                updateExistingWidgetIds(mode,
                                        changeWidgetIds: changeWidgetIds,
                                        panelPreference: settings.bottomWidgetPanelOrderOld,
                                        newPanelPreference: settings.bottomWidgetPanelOrder)

                updateExistingWidgetIds(mode,
                                        changeWidgetIds: changeWidgetIds,
                                        panelPreference: settings.leftWidgetPanelOrder)

                updateExistingWidgetIds(mode,
                                        changeWidgetIds: changeWidgetIds,
                                        panelPreference: settings.rightWidgetPanelOrder)

                updateCustomWidgetKeys(mode, changeWidgetIds: changeWidgetIds)
                updateMapInfoControls(mode, changeWidgetIds: changeWidgetIds)

                if let externalPlugin, let externalSensorsPluginPrefs {
                    for pref in externalSensorsPluginPrefs {
                        if let value = pref.toStringValue(mode) {
                            if value == "OATrackRecordingNone" {
                                pref.setValueFrom("", appMode: mode)
                            } else if value == "OATrackRecordingAnyConnected" {
                                pref.setValueFrom(externalPlugin.getAnyConnectedDeviceId(), appMode: mode)
                            }
                        }
                    }
                }
            }
        }
    }

    private func updateExistingWidgetIds(_ appMode: OAApplicationMode,
                                         changeWidgetIds: [String: String],
                                         panelPreference: OACommonListOfStringList,
                                         newPanelPreference: OACommonListOfStringList? = nil) {
        guard let pages = panelPreference.get(appMode) else { return }
        if newPanelPreference == nil {
            guard (pages.flatMap({ $0 }).contains { changeWidgetIds.keys.contains(WidgetType.getDefaultWidgetId($0)) }) else { return }
        }

        var newPages = [[String]]()
        for page in pages {
            newPages.append(getUpdatedWidgetIds(page, changeWidgetIds: changeWidgetIds))
        }
        if pages != newPages {
            panelPreference.set(newPages, mode: appMode)
        }
        if let newPanelPreference {
            newPanelPreference.set(newPages, mode: appMode)
        }
    }

    private func updateCustomWidgetKeys(_ appMode: OAApplicationMode, changeWidgetIds: [String: String]) {
        let customWidgetKeys: OACommonStringList = OAAppSettings.sharedManager().customWidgetKeys
        guard let customIds = customWidgetKeys.get(appMode),
              (customIds.contains { changeWidgetIds.keys.contains(WidgetType.getDefaultWidgetId($0)) }) else { return }

        let newCustomIds = getUpdatedWidgetIds(customIds, changeWidgetIds: changeWidgetIds)
        if customIds != newCustomIds {
            customWidgetKeys.set(newCustomIds, mode: appMode)
        }
    }

    private func updateMapInfoControls(_ appMode: OAApplicationMode, changeWidgetIds: [String: String]) {
        let mapInfoControls: OACommonString = OAAppSettings.sharedManager().mapInfoControls
        guard let widgetsVisibilityString: String = mapInfoControls.get(appMode) else { return }

        let widgetsVisibility = widgetsVisibilityString.components(separatedBy: SETTINGS_SEPARATOR)
        if !widgetsVisibility.contains(where: { changeWidgetIds.keys.contains(WidgetType.getDefaultWidgetId($0)) }) {
            return
        }

        let newWidgetsVisibility = getUpdatedWidgetIds(widgetsVisibility, changeWidgetIds: changeWidgetIds)
        if widgetsVisibility != newWidgetsVisibility {
            mapInfoControls.set(newWidgetsVisibility.joined(separator: SETTINGS_SEPARATOR), mode: appMode)
            changeWidgetPrefs1(appMode, oldWidgetIds: widgetsVisibility, changeWidgetIds: changeWidgetIds)
        }
    }

    private func changeWidgetPrefs1(_ appMode: OAApplicationMode, oldWidgetIds: [String], changeWidgetIds: [String: String]) {
        if let settings = OAAppSettings.sharedManager(),
           let plugin = OAPluginsHelper.getPlugin(OAExternalSensorsPlugin.self) as? OAExternalSensorsPlugin {
            for oldCustomWidgetId in oldWidgetIds {
                let oldOriginalWidgetId = oldCustomWidgetId.substring(to: Int(oldCustomWidgetId.index(of: MapWidgetInfo.DELIMITER)))
                if let newOriginalWidgetId = changeWidgetIds[oldOriginalWidgetId] {
                    let hasCustomSuffix = oldCustomWidgetId.contains(MapWidgetInfo.DELIMITER)
                    let newCustomWidgetId = oldCustomWidgetId.replacingOccurrences(of: oldOriginalWidgetId, with: newOriginalWidgetId)
                    if let widgetType = WidgetType.getById(newCustomWidgetId) {
                        let appModeStringKey: String = appMode.stringKey
                        var prefKeySuffix = hasCustomSuffix ? oldCustomWidgetId : ""

                        // sync preference key and value for saved BLE sensor devices

                        let useAnyDevicePrefKey = "\(widgetType.title)_useAnyDevicePref_\(prefKeySuffix)_\(appModeStringKey)"
                        if let useAnyDevicePref = defaults.object(forKey: useAnyDevicePrefKey) as? Bool,
                           let fieldType = plugin.getWidgetDataFieldTypeName(byWidgetId: newOriginalWidgetId) {
                            let newPrefKey = fieldType + (hasCustomSuffix ? newCustomWidgetId : "")
                            let newPref: OACommonString = settings.registerStringPreference(newPrefKey, defValue: plugin.getAnyConnectedDeviceId())
                            if !useAnyDevicePref {
                                let oldPrefKey = "\(widgetType.title)\(oldCustomWidgetId)_\(appModeStringKey)"
                                if let oldPref = defaults.string(forKey: oldPrefKey) {
                                    newPref.set(oldPref, mode: appMode)
                                }
                            }
                        }

                        // sync show_icon preference key of simple widgets

                        prefKeySuffix = hasCustomSuffix ? "_\(prefKeySuffix)" : ""
                        let hideIconPrefKey = "\(widgetType.title)kHideIconPref\(prefKeySuffix)_\(appModeStringKey)"
                        if let hideIconPref = defaults.object(forKey: hideIconPrefKey) as? Bool {
                            var newPrefKey = "simple_widget_show_icon\(widgetType.id)"
                            if hasCustomSuffix {
                                newPrefKey = newPrefKey.appending(newCustomWidgetId)
                            }
                            let newPref: OACommonBoolean = settings.registerBooleanPreference(newPrefKey, defValue: true)
                            if !hideIconPref {
                                newPref.set(hideIconPref, mode: appMode)
                            }
                        }

                        // sync size preference key of simple widgets

                        let sizeStylePrefKey = "\(widgetType.title)kSizeStylePref\(prefKeySuffix)_\(appModeStringKey)"
                        if let sizeStylePref = defaults.object(forKey: sizeStylePrefKey) as? Int {
                            var newPrefKey = "simple_widget_show_icon\(widgetType.id)"
                            if hasCustomSuffix {
                                newPrefKey = newPrefKey.appending(newCustomWidgetId)
                            }
                            let newPref: OACommonWidgetSizeStyle = settings.registerWidgetSizeStylePreference(newPrefKey, defValue: .medium)
                            if sizeStylePref != EOAWidgetSizeStyle.medium.rawValue {
                                newPref.set(EOAWidgetSizeStyle(rawValue: sizeStylePref) ?? .medium, mode: appMode)
                            }
                        }
                    }
                }
            }
        }
    }

    private func getUpdatedWidgetIds(_ widgetIds: [String], changeWidgetIds: [String: String]) -> [String] {
        var newWidgetsList = [String]()
        for widgetId in widgetIds {
            let originalId = WidgetType.getDefaultWidgetId(widgetId)
            if let newId = changeWidgetIds[originalId], !newId.isEmpty {
                newWidgetsList.append(widgetId.replacingOccurrences(of: originalId, with: newId))
            } else {
                newWidgetsList.append(widgetId)
            }
        }
        return newWidgetsList
    }

    private func changeQuickActionIdsMigration1() {
        let prefKey = "quickActionsList"
        if let pref = defaults.string(forKey: prefKey), let jsonData = pref.data(using: .utf8),
           let arr = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] {
            let changeQuickActionIntStringIds = [
                Pair(4, "transport.showhide"): OAShowHideTransportLinesAction.type(),
                Pair(31, "osmedit.showhide"): OAShowHideLocalOSMChanges.type(),
                Pair(32, "nav.directions"): OANavDirectionsFromAction.type(),
                Pair(36, "weather.temperature.showhide"): OAShowHideTemperatureAction.type(),
                Pair(37, "weather.pressure.showhide"): OAShowHideAirPressureAction.type(),
                Pair(38, "weather.wind.showhide"): OAShowHideWindAction.type(),
                Pair(39, "weather.cloud.showhide"): OAShowHideCloudAction.type(),
                Pair(40, "weather.precipitation.showhide"): OAShowHidePrecipitationAction.type()
            ]
            let excludedIds = [
                Pair(4, "favorites.showhide"),
                Pair(31, "transport.showhide"),
                Pair(32, "profile.change"),
                Pair(39, "temperature.layer.showhide"),
                Pair(40, "precipitation.layer.showhide")
            ]
            var mutableArr = arr
            for i in 0..<mutableArr.count {
                var data = mutableArr[i]
                let id = data["type"] as? Int
                let stringId = data["actionType"] as? String
                if let index = changeQuickActionIntStringIds.firstIndex(where: {
                    (id == -1 && $0.value?.stringId == stringId)
                    || (($0.key.first == id || $0.key.second == stringId)
                        && !excludedIds.contains(where: { $0.first == id && $0.second == stringId }))
                }) {
                    if let quickActionType = changeQuickActionIntStringIds[index].value {
                        data["type"] = quickActionType.id
                        data["actionType"] = quickActionType.stringId
                        if let oldName = data["name"] as? String,
                           (oldName.contains(changeQuickActionIntStringIds[index].key.second) || oldName.contains(quickActionType.stringId)) {
                            data["name"] = quickActionType.name
                        }
                        mutableArr[i] = data
                    }
                } else if stringId == "profile.change" {
                    if let params = data["params"] as? [AnyHashable: Any] {
                        var newParams = params
                        newParams.removeValue(forKey: "iconsColors")
                        newParams.removeValue(forKey: "iconsNames")
                        newParams.removeValue(forKey: "names")
                        newParams["profiles"] = newParams.removeValue(forKey: "stringKeys")
                        data["params"] = newParams
                        mutableArr[i] = data
                    }
                }
            }
            if !dictionariesAreEqual(arr, mutableArr) {
                if let newData = try? JSONSerialization.data(withJSONObject: mutableArr) {
                    if let newValue = String(data: newData, encoding: .utf8) {
                        defaults.set(newValue, forKey: prefKey)
                    }
                }
            }
        }
    }

    private func dictionariesAreEqual(_ leftArr: [[String: Any]], _ rightArr: [[String: Any]]) -> Bool {
        guard leftArr.count == rightArr.count else { return false }
        for (index, leftDict) in leftArr.enumerated() {
            let rightDict = rightArr[index]
            if !NSDictionary(dictionary: leftDict).isEqual(to: rightDict) {
                return false
            }
        }
        return true
    }
    
    private func migrateActionButtons() {
        let helper = OAMapButtonsHelper.sharedInstance()
        guard let buttonState = helper.getButtonState(byId: QuickActionButtonState.defaultButtonId) else {
            return
        }
        
        if let oldStatePref = OACommonBoolean.withKey("qiuckActionIsOn", defValue: false).makeProfile() {
            for appMode in OAApplicationMode.allPossibleValues() {
                buttonState.statePref.set(oldStatePref.get(appMode), mode: appMode)
                settings?.quickActionButtons.set([QuickActionButtonState.defaultButtonId], mode: appMode)
            }
        }
        
        if let value = defaults.string(forKey: "quickActionsList"), !value.isEmpty{
            for appMode in OAApplicationMode.allPossibleValues() {
                buttonState.quickActionsPref.set(value, mode: appMode)
            }
        }
        
        if let oldQuickActionPortraitX = OACommonDouble.withKey("quickActionPortraitX", defValue: 0),
           let oldQuickActionPortraitY = OACommonDouble.withKey("quickActionPortraitY", defValue: 0),
           let oldQuickActionLandscapeX = OACommonDouble.withKey("quickActionLandscapeX", defValue: 0),
           let oldQuickActionLandscapeY = OACommonDouble.withKey("quickActionLandscapeY", defValue: 0) {
            for appMode in OAApplicationMode.allPossibleValues() {
                buttonState.fabMarginPref.setPortraitFabMargin(appMode,
                                                               x: Int32(oldQuickActionPortraitX.get(appMode)),
                                                               y: Int32(oldQuickActionPortraitY.get(appMode)))
                buttonState.fabMarginPref.setLandscapeFabMargin(appMode,
                                                                x: Int32(oldQuickActionLandscapeX.get(appMode)),
                                                                y: Int32(oldQuickActionLandscapeY.get(appMode)))
            }
        }
        helper.updateActiveActions()

        if let map3DModeState = helper.getMap3DButtonState() as Map3DButtonState? {
            if let oldMap3DPortraitX = OACommonDouble.withKey("map3dModePortraitX", defValue: 0),
               let oldMap3DPortraitY = OACommonDouble.withKey("map3dModePortraitY", defValue: 0),
               let oldMap3DLandscapeX = OACommonDouble.withKey("map3dModeLandscapeX", defValue: 0),
               let oldMap3DLandscapeY = OACommonDouble.withKey("map3dModeLandscapeY", defValue: 0) {
                for appMode in OAApplicationMode.allPossibleValues() {
                    map3DModeState.fabMarginPref.setPortraitFabMargin(appMode,
                                                                      x: Int32(oldMap3DPortraitX.get(appMode)),
                                                                      y: Int32(oldMap3DPortraitY.get(appMode)))
                    map3DModeState.fabMarginPref.setLandscapeFabMargin(appMode,
                                                                       x: Int32(oldMap3DLandscapeX.get(appMode)),
                                                                       y: Int32(oldMap3DLandscapeY.get(appMode)))
                }
            }
        }

        if let compassState = helper.getCompassButtonState() as CompassButtonState?,
           let oldCompassMode = OACommonInteger.withKey("compassMode", defValue: CompassVisibility.visibleIfMapRotated.rawValue) {
            for appMode in OAApplicationMode.allPossibleValues() {
                compassState.visibilityPref.set(oldCompassMode.get(appMode), mode: appMode)
            }
        }
    }

    func changeJsonMigrationToV2(_ json: [String: String]) -> [String: String] {

        // change keys inside old json import file after "Migration 1"

        let changeSettingKeys = [
            "top_widget_panel_order": "widget_top_panel_order",
            "bottom_widget_panel_order": "widget_bottom_panel_order"
        ]

        let changeWidgetIds = [
            "heartRate": "ant_heart_rate",
            "bicycleCadence": "ant_bicycle_cadence",
            "bicycleDistance": "ant_bicycle_distance",
            "bicycleSpeed": "ant_bicycle_speed",
            "temperature": "temperature_sensor"
        ]

        let widgetSettingKeys = [
            "left_widget_panel_order",
            "right_widget_panel_order",
            "widget_top_panel_order",
            "widget_bottom_panel_order",
            "custom_widgets_keys",
            "map_info_controls"
        ]

        return Dictionary(uniqueKeysWithValues: json.map {
            var settingKey = $0
            var value = $1
            if let newKey = changeSettingKeys[settingKey], !newKey.isEmpty {
                settingKey = newKey
            }
            if widgetSettingKeys.contains(settingKey) {
                for (widgetIdOld, widgetIdNew) in changeWidgetIds {
                    value = value.replacingOccurrences(of: "(?<=^|;|,)(\(widgetIdOld))(?=(__|;|,|$)|$)",
                                                       with: widgetIdNew,
                                                       options: .regularExpression)
                }
            }
            return (settingKey, value)
        })
    }

    func changeJsonMigrationToV3(_ jsonArray: [[String: String]]) -> [[String: String]] {

        // change keys inside old json import file after "Migration 2"

        let changeQuickActionStringIds = [
            "weather.temperature.showhide": "temperature.layer.showhide",
            "weather.pressure.showhide": "pressure.layer.showhide",
            "weather.wind.showhide": "wind.layer.showhide",
            "weather.cloud.showhide": "cloud.layer.showhide",
            "weather.precipitation.showhide": "precipitation.layer.showhide"
        ]

        return Array(jsonArray.map {
            let json = $0
            if let stringId = json["actionType"], changeQuickActionStringIds.keys.contains(stringId) {
                return Dictionary(uniqueKeysWithValues: json.map({
                    let key = $0
                    let value = $1
                    if key == "actionType", let newValue = changeQuickActionStringIds[value] {
                        return (key, newValue)
                    } else {
                        return (key, value)
                    }
                }))
            } else {
                return json
            }
        })
    }
}
