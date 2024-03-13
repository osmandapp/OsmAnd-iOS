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
        "heartRate" : "ant_heart_rate",
        "bicycleCadence" : "ant_bicycle_cadence",
        "bicycleDistance" : "ant_bicycle_distance",
        "bicycleSpeed" : "ant_bicycle_speed",
        "temperature" : "temperature_sensor"
    ]

    private override init() {}

    func changeWidgetIdsMigration1(_ firstLaunch: Bool) {
        if firstLaunch {
            defaults.set(true, forKey:  MigrationKey.migrationChangeWidgetIds1Key.rawValue)
            return
        }

        guard let isOldWidgetKeysMigrated = defaults.object(forKey: MigrationKey.migrationChangeWidgetIds1Key.rawValue),
              isOldWidgetKeysMigrated as! Bool == false else { return }

        if let settings = OAAppSettings.sharedManager() {
            for mode in OAApplicationMode.allPossibleValues() {
                updateExistingWidgetIds(mode,
                                        changeWidgetIds: changeWidgetIds1,
                                        panelPreference:settings.topWidgetPanelOrderOld,
                                        newPanelPreference:settings.topWidgetPanelOrder)

                updateExistingWidgetIds(mode,
                                        changeWidgetIds: changeWidgetIds1,
                                        panelPreference:settings.bottomWidgetPanelOrderOld,
                                        newPanelPreference:settings.bottomWidgetPanelOrder)

                updateExistingWidgetIds(mode,
                                        changeWidgetIds: changeWidgetIds1,
                                        panelPreference:settings.leftWidgetPanelOrder)

                updateExistingWidgetIds(mode,
                                        changeWidgetIds: changeWidgetIds1,
                                        panelPreference:settings.rightWidgetPanelOrder)

                updateExistingCustomWidgetIds(mode,
                                              changeWidgetIds: changeWidgetIds1,
                                              customIdsPreference:settings.customWidgetKeys)

                updateExistingWidgetsVisibility(mode,
                                                changeWidgetIds: changeWidgetIds1,
                                                visibilityPreference:settings.mapInfoControls)
            }
            defaults.set(true, forKey:  MigrationKey.migrationChangeWidgetIds1Key.rawValue)
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

    func updateExistingCustomWidgetIds(_ appMode: OAApplicationMode,
                                       changeWidgetIds: [String: String],
                                       customIdsPreference: OACommonStringList) {
        guard let customIds = customIdsPreference.get(appMode),
              (customIds.contains { changeWidgetIds.keys.contains(WidgetType.getDefaultWidgetId($0)) }) else { return }

        let newCustomIds = getUpdatedWidgetIds(customIds, changeWidgetIds: changeWidgetIds)
        if customIds != newCustomIds {
            customIdsPreference.set(newCustomIds, mode: appMode)
        }
    }

    func updateExistingWidgetsVisibility(_ appMode: OAApplicationMode,
                                         changeWidgetIds: [String: String],
                                         visibilityPreference: OACommonString) {
        guard let widgetsVisibilityString = visibilityPreference.get(appMode) else { return  }

        let widgetsVisibility = widgetsVisibilityString.components(separatedBy: SETTINGS_SEPARATOR);
        guard (widgetsVisibility.contains { changeWidgetIds.keys.contains(WidgetType.getDefaultWidgetId($0)) }) else { return }

        let newWidgetsVisibility = getUpdatedWidgetIds(widgetsVisibility, changeWidgetIds: changeWidgetIds)
        if widgetsVisibility != newWidgetsVisibility {
            visibilityPreference.set(newWidgetsVisibility.joined(separator: SETTINGS_SEPARATOR), mode: appMode)
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
}
