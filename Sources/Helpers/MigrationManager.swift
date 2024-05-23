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

    enum MigrationKey: String {
        case migrationChangeWidgetIds1Key
        case migrationChangeQuickActionIds1Key
    }

    static let shared = MigrationManager()
    let defaults = UserDefaults.standard

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
                defaults.set(true, forKey: MigrationKey.migrationChangeQuickActionIds1Key.rawValue)
            }
        }
    }

    private func changeQuickActionIdsMigration1() {
        if let settings = OAAppSettings.sharedManager() {
            if let jsonData = settings.quickActionsList.get()?.data(using: .utf8),
               let arr = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] {
                let changeQuickActionIntStringIds = [
                    Pair(first: 4, second: "transport.showhide"): Pair(first: QuickActionIds.showHideTransportLinesActionId.rawValue, second: "transport.showhide"),
                    Pair(first: 31, second: "osmedit.showhide"): Pair(first: QuickActionIds.showHideLocalOsmChangesActionId.rawValue, second: "osmedit.showhide"),
                    Pair(first: 32, second: "nav.directions"): Pair(first: QuickActionIds.navDirectionsFromActionId.rawValue, second: "nav.directions"),
                    Pair(first: 36, second: "weather.temperature.showhide"): Pair(first: QuickActionIds.showHideTemperatureLayerActionId.rawValue, second: "temperature.layer.showhide"),
                    Pair(first: 37, second: "weather.pressure.showhide"): Pair(first: QuickActionIds.showHideAirPressureLayerActionId.rawValue, second: "pressure.layer.showhide"),
                    Pair(first: 38, second: "weather.wind.showhide"): Pair(first: QuickActionIds.showHideWindLayerActionId.rawValue, second: "wind.layer.showhide"),
                    Pair(first: 39, second: "weather.cloud.showhide"): Pair(first: QuickActionIds.showHideCloudLayerActionId.rawValue, second: "cloud.layer.showhide"),
                    Pair(first: 40, second: "weather.precipitation.showhide"): Pair(first: QuickActionIds.showHidePrecipitationLayerActionId.rawValue, second: "precipitation.layer.showhide")
                ]
                var mutableArr = arr
                for i in 0..<mutableArr.count {
                    var data = mutableArr[i]
                    let id = data["type"] as? Int
                    let stringId = data["actionType"] as? String
                    if let index = changeQuickActionIntStringIds.firstIndex(where: { (id == -1 && $0.value.second == stringId) || $0.key.first == id || $0.key.second == stringId }) {
                        let newValues = changeQuickActionIntStringIds[index].value
                        data["type"] = newValues.first
                        data["actionType"] = newValues.second
                        mutableArr[i] = data
                    }
                }
                if !dictionariesAreEqual(arr, mutableArr) {
                    if let jsonData = try? JSONSerialization.data(withJSONObject: mutableArr, options: .prettyPrinted) {
                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                            settings.quickActionsList.set(jsonString/*, mode: mode*/)
                        }
                    }
                }
            }
            OAQuickActionRegistry.sharedInstance().updateQuickActions()
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

    func changeJsonMigration(_ json: [String: String]) -> [String: String] {

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
}
