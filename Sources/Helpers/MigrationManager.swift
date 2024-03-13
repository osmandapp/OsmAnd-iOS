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

    enum MigrationKey: String {
        case migrationChangeWidgetIds1Key
    }

    static let shared = MigrationManager()
    let defaults = UserDefaults.standard

    let changeWidgetIds1 = [
        "heartRate": "ant_heart_rate",
        "bicycleCadence": "ant_bicycle_cadence",
        "bicycleDistance": "ant_bicycle_distance",
        "bicycleSpeed": "ant_bicycle_speed",
        "temperature": "temperature_sensor"
    ]

    let changeWidgetPrefs1 = [
        "kHideIconPref": kShowIconPref,
        "kSizeStylePref": kSizeStylePref
    ]

    private override init() {}

    func changeWidgetIdsMigration1(_ firstLaunch: Bool) {
        if firstLaunch {
            defaults.set(true, forKey: MigrationKey.migrationChangeWidgetIds1Key.rawValue)
            return
        }

        guard let isOldWidgetKeysMigrated = defaults.object(forKey: MigrationKey.migrationChangeWidgetIds1Key.rawValue),
              isOldWidgetKeysMigrated as! Bool == false else { return }

        if let settings = OAAppSettings.sharedManager() {
            for mode in OAApplicationMode.allPossibleValues() {
                updateExistingWidgetIds(mode,
                                        changeWidgetIds: changeWidgetIds1,
                                        panelPreference: settings.topWidgetPanelOrderOld,
                                        newPanelPreference: settings.topWidgetPanelOrder)

                updateExistingWidgetIds(mode,
                                        changeWidgetIds: changeWidgetIds1,
                                        panelPreference: settings.bottomWidgetPanelOrderOld,
                                        newPanelPreference: settings.bottomWidgetPanelOrder)

                updateExistingWidgetIds(mode,
                                        changeWidgetIds: changeWidgetIds1,
                                        panelPreference:settings.leftWidgetPanelOrder)

                updateExistingWidgetIds(mode,
                                        changeWidgetIds: changeWidgetIds1,
                                        panelPreference: settings.rightWidgetPanelOrder)

                updateCustomWidgetKeys(mode, changeWidgetIds: changeWidgetIds1)
                updateMapInfoControls(mode, changeWidgetIds: changeWidgetIds1)
            }
            defaults.set(true, forKey: MigrationKey.migrationChangeWidgetIds1Key.rawValue)
        }
    }

    func updateExistingWidgetIds(_ appMode: OAApplicationMode,
                                 changeWidgetIds: [String: String],
                                 panelPreference: OACommonListOfStringList,
                                 newPanelPreference: OACommonListOfStringList? = nil) {
        guard let pages = panelPreference.get(appMode) else { return }
        if newPanelPreference == nil {
            guard (pages.flatMap({ $0 }).contains { changeWidgetIds.keys.contains(WidgetType.getDefaultWidgetId($0)) }) else { return }
        }

        var newPages = [Array<String>]()
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

    func updateCustomWidgetKeys(_ appMode: OAApplicationMode, changeWidgetIds: [String: String]) {
        let customWidgetKeys: OACommonStringList = OAAppSettings.sharedManager().customWidgetKeys
        guard let customIds = customWidgetKeys.get(appMode),
              (customIds.contains { changeWidgetIds.keys.contains(WidgetType.getDefaultWidgetId($0)) }) else { return }

        let newCustomIds = getUpdatedWidgetIds(customIds, changeWidgetIds: changeWidgetIds)
        if customIds != newCustomIds {
            customWidgetKeys.set(newCustomIds, mode: appMode)
        }
    }

    func updateMapInfoControls(_ appMode: OAApplicationMode, changeWidgetIds: [String: String]) {
        let mapInfoControls: OACommonString = OAAppSettings.sharedManager().mapInfoControls
        guard let widgetsVisibilityString = mapInfoControls.get(appMode) else { return  }

        let widgetsVisibility = widgetsVisibilityString.components(separatedBy: SETTINGS_SEPARATOR)
        guard (widgetsVisibility.contains { changeWidgetIds.keys.contains(WidgetType.getDefaultWidgetId($0)) }) else { return }

        let newWidgetsVisibility = getUpdatedWidgetIds(widgetsVisibility, changeWidgetIds: changeWidgetIds)
        if widgetsVisibility != newWidgetsVisibility {
            mapInfoControls.set(newWidgetsVisibility.joined(separator: SETTINGS_SEPARATOR), mode: appMode)
        }
        for widgetId in newWidgetsVisibility {
            if let widgetType = WidgetType.getById(widgetId) {
                resetWidgetPrefs(appMode,
                                 widgetType: widgetType,
                                 prefKeys: changeWidgetPrefs1,
                                 customId: widgetId.range(of: MapWidgetInfo.DELIMITER) != nil ? widgetId : nil)
            }
        }
    }

    func getUpdatedWidgetIds(_ widgetIds: [String], changeWidgetIds: [String: String]) -> [String] {
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

    func resetWidgetPrefs(_ appMode: OAApplicationMode, widgetType: WidgetType, prefKeys: [String: String], customId: String?) {
        if let settings = OAAppSettings.sharedManager() {
            var prefIdOld = widgetType.title
            for (prefKeyOld, prefKeyNew) in prefKeys {
                if let customId, !customId.isEmpty {
                    prefIdOld = prefIdOld.appendingFormat("%@_%@", prefKeyOld, customId)
                } else {
                    prefIdOld = prefIdOld.appending(prefKeyOld)
                }
                if let preferenceOld = settings.getPreferenceByKey(prefIdOld),
                   let preferenceNew = registerWidgetPref(widgetType, prefKey: prefKeyNew, customId: customId) {
                        preferenceNew.setValueFrom(preferenceOld.toStringValue(appMode), appMode: appMode)
                }
            }
        }
    }

    func registerWidgetPref(_ widgetType: WidgetType, prefKey: String, customId: String?) -> OACommonPreference? {
        var prefId = prefKey
        prefId = prefId.appending(widgetType.id)
        if let customId, !customId.isEmpty {
            prefId = prefId.appending(customId)
        }
        if prefKey == kShowIconPref {
            return OAAppSettings.sharedManager().registerBooleanPreference(prefId, defValue: true)
        }
        else if prefKey == kSizeStylePref {
            return OAAppSettings.sharedManager().registerIntPreference(prefId, defValue: Int32(WidgetSizeStyle.medium.rawValue))
        }
        return nil
    }
}
