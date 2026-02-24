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

    enum MigrationKey: String, CaseIterable {
        case migrationChangeWidgetIds1Key
        case migrationChangeQuickActionIds1Key
        case migrationLocationNavigationIconsKey
        case migrationChangeTerrainIds1Key
        case migrationTerrainModeDefaultPreferences
        case migrateExternalInputDevicePreferenceType
        case migrationHudButtonPositionsKey
        case migrateRouteRecalculationValues
        case migrateLocationIconSizeAndCourseIconSize
    }
    
    private struct HudMigrationScenario {
        let need: Bool
        let x: CGFloat
        let y: CGFloat
        let parentWidth: CGFloat
        let parentHeight: CGFloat
        let pref: OACommonLong
    }

    static let shared = MigrationManager()
    static let importExportVersionMigration2 = 2
    
    let defaults = UserDefaults.standard
    private let settings = OAAppSettings.sharedManager()
    private let routeRecalculationDisableMode = -1.0

    private override init() {}

    func migrateIfNeeded(_ isFirstLaunch: Bool) {
        if isFirstLaunch {
            MigrationKey.allCases.forEach { defaults.set(true, forKey: $0.rawValue) }
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
            if !defaults.bool(forKey: MigrationKey.migrationLocationNavigationIconsKey.rawValue) {
                migrateLocationNavigationIcons()
                defaults.set(true, forKey: MigrationKey.migrationLocationNavigationIconsKey.rawValue)
            }
            if !defaults.bool(forKey: MigrationKey.migrationChangeTerrainIds1Key.rawValue) {
                changeTerrainSettingsMigration1()
                defaults.set(true, forKey: MigrationKey.migrationChangeTerrainIds1Key.rawValue)
            }
            if !defaults.bool(forKey: MigrationKey.migrationTerrainModeDefaultPreferences.rawValue) {
                migrateTerrainModeDefaultPreferences()
                defaults.set(true, forKey: MigrationKey.migrationTerrainModeDefaultPreferences.rawValue)
            }
            if !defaults.bool(forKey: MigrationKey.migrateExternalInputDevicePreferenceType.rawValue) {
                migrateExternalInputDevicePreferenceType()
                defaults.set(true, forKey: MigrationKey.migrateExternalInputDevicePreferenceType.rawValue)
            }
            if !defaults.bool(forKey: MigrationKey.migrationHudButtonPositionsKey.rawValue) {
                migrateHudButtonPositions()
                defaults.set(true, forKey: MigrationKey.migrationHudButtonPositionsKey.rawValue)
            }
            if !defaults.bool(forKey: MigrationKey.migrateRouteRecalculationValues.rawValue) {
                migrateRouteRecalulationValues()
                defaults.set(true, forKey: MigrationKey.migrateRouteRecalculationValues.rawValue)
            }
            if !defaults.bool(forKey: MigrationKey.migrateLocationIconSizeAndCourseIconSize.rawValue) {
                migrateLocationIconSizeAndCourseIconSize()
                defaults.set(true, forKey: MigrationKey.migrateLocationIconSizeAndCourseIconSize.rawValue)
            }
        }
    }
    
    private func changeWidgetIdsMigration1() {
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
                    let value = pref.toStringValue(mode)
                    if value == "OATrackRecordingNone" {
                        pref.setValueFrom("", appMode: mode)
                    } else if value == "OATrackRecordingAnyConnected" {
                        pref.setValueFrom(externalPlugin.getAnyConnectedDeviceId(), appMode: mode)
                    }
                }
            }
        }
    }

    private func updateExistingWidgetIds(_ appMode: OAApplicationMode,
                                         changeWidgetIds: [String: String],
                                         panelPreference: OACommonListOfStringList,
                                         newPanelPreference: OACommonListOfStringList? = nil) {
        let pages = panelPreference.get(appMode)
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
        let customIds = customWidgetKeys.get(appMode)
        guard (customIds.contains { changeWidgetIds.keys.contains(WidgetType.getDefaultWidgetId($0)) }) else { return }

        let newCustomIds = getUpdatedWidgetIds(customIds, changeWidgetIds: changeWidgetIds)
        if customIds != newCustomIds {
            customWidgetKeys.set(newCustomIds, mode: appMode)
        }
    }

    private func updateMapInfoControls(_ appMode: OAApplicationMode, changeWidgetIds: [String: String]) {
        let mapInfoControls: OACommonString = OAAppSettings.sharedManager().mapInfoControls
        let widgetsVisibilityString: String = mapInfoControls.get(appMode)

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
        if let plugin = OAPluginsHelper.getPlugin(OAExternalSensorsPlugin.self) as? OAExternalSensorsPlugin {
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
                Pair(4, "transport.showhide"): OAShowHideTransportLinesAction.getType(),
                Pair(31, "osmedit.showhide"): OAShowHideLocalOSMChanges.getType(),
                Pair(32, "nav.directions"): OANavDirectionsFromAction.getType(),
                Pair(36, "weather.temperature.showhide"): ShowHideTemperatureAction.getType(),
                Pair(37, "weather.pressure.showhide"): ShowHideAirPressureAction.getType(),
                Pair(38, "weather.wind.showhide"): ShowHideWindAction.getType(),
                Pair(39, "weather.cloud.showhide"): ShowHideCloudAction.getType(),
                Pair(40, "weather.precipitation.showhide"): ShowHidePrecipitationAction.getType()
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
                    (id == -1 && $0.value.stringId == stringId)
                    || (($0.key.first == id || $0.key.second == stringId)
                        && !excludedIds.contains(where: { $0.first == id && $0.second == stringId }))
                }) {
                    let quickActionType = changeQuickActionIntStringIds[index].value
                    data["type"] = quickActionType.id
                    data["actionType"] = quickActionType.stringId
                    if let oldName = data["name"] as? String,
                       (oldName.contains(changeQuickActionIntStringIds[index].key.second) || oldName.contains(quickActionType.stringId)) {
                        data["name"] = quickActionType.name
                    }
                    mutableArr[i] = data
                } else {
                    let isMapSource = stringId == "mapsource.change"
                    let isProfile = stringId == "profile.change"
                    if isMapSource || isProfile, let params = data["params"] as? [AnyHashable: Any] {
                        var newParams = params
                        if isMapSource {
                            if let sourceParams = newParams["source"] as? [[String]] {
                                var newSourceParams = [[String]]()
                                for sourcePair in sourceParams {
                                    if sourcePair.first == "type_default", let sourceValue = sourcePair.last {
                                        newSourceParams.append(["LAYER_OSM_VECTOR", sourceValue])
                                    } else {
                                        newSourceParams.append(sourcePair)
                                    }
                                }
                                newParams["source"] = newSourceParams
                            }
                        } else if isProfile {
                            newParams.removeValue(forKey: "iconsColors")
                            newParams.removeValue(forKey: "iconsNames")
                            newParams.removeValue(forKey: "names")
                            newParams["profiles"] = newParams.removeValue(forKey: "stringKeys")
                        }
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
    
    private func migrateLocationNavigationIcons() {
        for appMode in OAApplicationMode.allPossibleValues() {
            let oldLocationIconPref = OACommonInteger.withKey("locationIcon", defValue: 0).makeProfile()
            switch oldLocationIconPref.get(appMode) {
            case 0:
                settings.locationIcon.set(OALocationIcon.default().name(), mode: appMode)
            case 1:
                settings.locationIcon.set(OALocationIcon.car().name(), mode: appMode)
            case 2:
                settings.locationIcon.set(OALocationIcon.bicycle().name(), mode: appMode)
            default:
                settings.locationIcon.set(OALocationIcon.default().name(), mode: appMode)
            }
            let oldNavigationIconPref = OACommonInteger.withKey("navigationIcon", defValue: 0).makeProfile()
            switch oldNavigationIconPref.get(appMode) {
            case 0:
                settings.navigationIcon.set(OALocationIcon.movement_DEFAULT().name(), mode: appMode)
            case 1:
                settings.navigationIcon.set(OALocationIcon.movement_NAUTICAL().name(), mode: appMode)
            case 2:
                settings.navigationIcon.set(OALocationIcon.movement_CAR().name(), mode: appMode)
            default:
                settings.navigationIcon.set(OALocationIcon.movement_DEFAULT().name(), mode: appMode)
            }
        }
    }

    private func migrateActionButtons() {
        let helper = OAMapButtonsHelper.sharedInstance()
        guard let buttonState = helper.getButtonState(byId: QuickActionButtonState.defaultButtonId) else {
            return
        }
        
        let oldStatePref = OACommonBoolean.withKey("qiuckActionIsOn", defValue: false).makeProfile()
        for appMode in OAApplicationMode.allPossibleValues() {
            buttonState.statePref.set(oldStatePref.get(appMode), mode: appMode)
            settings.quickActionButtons.set([QuickActionButtonState.defaultButtonId], mode: appMode)
        }
        
        if let value = defaults.string(forKey: "quickActionsList"), !value.isEmpty {
            for appMode in OAApplicationMode.allPossibleValues() {
                buttonState.quickActionsPref.set(value, mode: appMode)
            }
        }
        
        let oldQuickActionPortraitX = OACommonDouble.withKey("quickActionPortraitX", defValue: 0)
        let oldQuickActionPortraitY = OACommonDouble.withKey("quickActionPortraitY", defValue: 0)
        let oldQuickActionLandscapeX = OACommonDouble.withKey("quickActionLandscapeX", defValue: 0)
        let oldQuickActionLandscapeY = OACommonDouble.withKey("quickActionLandscapeY", defValue: 0)
            for appMode in OAApplicationMode.allPossibleValues() {
                buttonState.fabMarginPref.setPortraitFabMargin(appMode,
                                                               x: Int32(oldQuickActionPortraitX.get(appMode)),
                                                               y: Int32(oldQuickActionPortraitY.get(appMode)))
                buttonState.fabMarginPref.setLandscapeFabMargin(appMode,
                                                                x: Int32(oldQuickActionLandscapeX.get(appMode)),
                                                                y: Int32(oldQuickActionLandscapeY.get(appMode)))
            }

        helper.updateActiveActions()

        if let map3DModeState = helper.getMap3DButtonState() as Map3DButtonState? {
            let oldMap3DPortraitX = OACommonDouble.withKey("map3dModePortraitX", defValue: 0)
            let oldMap3DPortraitY = OACommonDouble.withKey("map3dModePortraitY", defValue: 0)
            let oldMap3DLandscapeX = OACommonDouble.withKey("map3dModeLandscapeX", defValue: 0)
            let oldMap3DLandscapeY = OACommonDouble.withKey("map3dModeLandscapeY", defValue: 0)
                for appMode in OAApplicationMode.allPossibleValues() {
                    map3DModeState.fabMarginPref.setPortraitFabMargin(appMode,
                                                                      x: Int32(oldMap3DPortraitX.get(appMode)),
                                                                      y: Int32(oldMap3DPortraitY.get(appMode)))
                    map3DModeState.fabMarginPref.setLandscapeFabMargin(appMode,
                                                                       x: Int32(oldMap3DLandscapeX.get(appMode)),
                                                                       y: Int32(oldMap3DLandscapeY.get(appMode)))
                }
        }

        if let compassState = helper.getCompassButtonState() as CompassButtonState? {
            let oldCompassMode = OACommonInteger.withKey("compassMode", defValue: CompassVisibility.visibleIfMapRotated.rawValue)
            for appMode in OAApplicationMode.allPossibleValues() {
                compassState.visibilityPref.set(oldCompassMode.get(appMode), mode: appMode)
            }
        }
    }

    private func changeTerrainSettingsMigration1() {
        if let plugin = OAPluginsHelper.getPlugin(OASRTMPlugin.self) as? OASRTMPlugin {
            if let newTerrain = plugin.terrainEnabledPref,
               let newTerrainMode = plugin.terrainModeTypePref {
                
                let oldTerrainMode = OACommonInteger.withKey("terrainType", defValue: 0)
                let oldLastTerrainMode = OACommonInteger.withKey("lastTerrainType", defValue: 1)
                
                for appMode in OAApplicationMode.allPossibleValues() {
                    let oldValue = oldTerrainMode.get(appMode)
                    if oldValue == 0 {
                        newTerrain.set(false, mode: appMode)
                        newTerrainMode.set(oldLastTerrainMode.get(appMode) == 2 ? "slope" : "hillshade", mode: appMode)
                    } else {
                        newTerrain.set(true, mode: appMode)
                        newTerrainMode.set(oldValue == 2 ? "slope" : "hillshade", mode: appMode)
                    }
                }
            }

            let oldHillshadeMinZoom = OACommonInteger.withKey("hillshadeMinZoom", defValue: 3)
            let oldHillshadeMaxZoom = OACommonInteger.withKey("hillshadeMaxZoom", defValue: 16)
            let oldSlopeMinZoom = OACommonInteger.withKey("slopeMinZoom", defValue: 3)
            let oldSlopeMaxZoom = OACommonInteger.withKey("slopeMaxZoom", defValue: 16)

            let oldHillshadeAlpha = OACommonDouble.withKey("hillshadeAlpha", defValue: 0.45)
            let oldSlopeAlpha = OACommonDouble.withKey("slopeAlpha", defValue: 0.35)

            let terrainMode = plugin.getTerrainMode()
            for appMode in OAApplicationMode.allPossibleValues() {
                if plugin.terrainModeTypePref.get(appMode) == TerrainMode.TerrainType.hillshade.name {
                    terrainMode?.setZoomValues(minZoom: oldHillshadeMinZoom.get(appMode), maxZoom: oldHillshadeMaxZoom.get(appMode), mode: appMode)
                    terrainMode?.setTransparency(Int32(oldHillshadeAlpha.get(appMode) / 0.01), mode: appMode)
                } else {
                    terrainMode?.setZoomValues(minZoom: oldSlopeMinZoom.get(appMode), maxZoom: oldSlopeMaxZoom.get(appMode), mode: appMode)
                    terrainMode?.setTransparency(Int32(oldSlopeAlpha.get(appMode) / 0.01), mode: appMode)
                }
            }
        }
    }

    private func migrateTerrainModeDefaultPreferences() {
        let oldDefaultMinZoomPref = OACommonInteger.withKey(TerrainMode.defaultKey + "_min_zoom", defValue: 0)
        let oldDefaultMaxZoomPref = OACommonInteger.withKey(TerrainMode.defaultKey + "_max_zoom", defValue: 0)
        let oldDefaultTransparencyPref = OACommonInteger.withKey(TerrainMode.defaultKey + "_transparency", defValue: 0)

        for mode in OAApplicationMode.allPossibleValues() {
            let oldMinZoom = oldDefaultMinZoomPref.get(mode)
            let oldMaxZoom = oldDefaultMaxZoomPref.get(mode)
            let oldTransparencyZoom = oldDefaultTransparencyPref.get(mode)
            for terrainMode in TerrainMode.values where terrainMode.isDefaultMode() && terrainMode.type != .height {
                if oldDefaultMinZoomPref.isSet(for: mode),
                   oldDefaultMaxZoomPref.isSet(for: mode) {
                    terrainMode.setZoomValues(minZoom: oldMinZoom,
                                              maxZoom: oldMaxZoom)
                }
                if oldDefaultTransparencyPref.isSet(for: mode) {
                    terrainMode.setTransparency(oldTransparencyZoom)
                }
            }
        }
    }
    
    private func migrateExternalInputDevicePreferenceType() {
        let settings = OAAppSettings.sharedManager()
        let oldExternalInputDevicePref = OACommonInteger.withKey("settingExternalInputDeviceKey", defValue: 1)
        
        for appMode in OAApplicationMode.allPossibleValues() {
            switch oldExternalInputDevicePref.get(appMode) {
            case 0:
                settings.settingExternalInputDevice.set(NoneDeviceProfile.deviceId, mode: appMode)
            case 1:
                settings.settingExternalInputDevice.set(KeyboardDeviceProfile.deviceId, mode: appMode)
            case 2:
                settings.settingExternalInputDevice.set(WunderLINQDeviceProfile.deviceId, mode: appMode)
            default:
                settings.settingExternalInputDevice.set(KeyboardDeviceProfile.deviceId, mode: appMode)
            }
        }
    }
    
    private func migrateHudButtonPositions() {
        let helper = OAMapButtonsHelper.sharedInstance()
        let screenWidth = CGFloat(OAUtilities.calculateScreenWidth())
        let screenHeight = CGFloat(OAUtilities.calculateScreenHeight())
        let portraitWidth = min(screenWidth, screenHeight)
        let portraitHeight = max(screenWidth, screenHeight)
        let landscapeWidth = max(screenWidth, screenHeight)
        let landscapeHeight = min(screenWidth, screenHeight)
        let cellSizePt = CGFloat(ButtonPositionSize.companion.CELL_SIZE_DP)
        let buttonCells = Int32(50 / cellSizePt) + 1
        let buttonSizePt = CGFloat(buttonCells) * cellSizePt
        var items: [(id: String, fab: FabMarginPreference)] = []
        let map3DState = helper.getMap3DButtonState()
        items.append((id: Map3DButtonState.map3DHudId, fab: map3DState.fabMarginPref))
        var quickIds = Set<String>()
        for mode in OAApplicationMode.allPossibleValues() {
            for qid in OAAppSettings.sharedManager().quickActionButtons.get(mode) {
                quickIds.insert(qid)
            }
        }
        
        if quickIds.isEmpty {
            quickIds.insert(QuickActionButtonState.defaultButtonId)
        }
        
        for qid in quickIds {
            if let quickState = helper.getButtonState(byId: qid) {
                items.append((id: qid, fab: quickState.fabMarginPref))
            }
        }
        
        for (hudId, fabPref) in items {
            let portraitPref = settings.registerLongPreference("\(hudId)_position_portrait", defValue: -1).makeProfile()
            let landscapePref = settings.registerLongPreference("\(hudId)_position_landscape", defValue: -1).makeProfile()
            for mode in OAApplicationMode.allPossibleValues() {
                let needPortrait = portraitPref.get(mode) == -1
                let needLandscape = landscapePref.get(mode) == -1
                if !needPortrait && !needLandscape {
                    continue
                }
                
                let portMargin = fabPref.getPortraitFabMargin(mode)
                let landMargin = fabPref.getLandscapeFabMargin(mode)
                let portX = CGFloat(portMargin.first?.doubleValue ?? 0)
                let portY = CGFloat(portMargin.last?.doubleValue ?? 0)
                let landX = CGFloat(landMargin.first?.doubleValue ?? 0)
                let landY = CGFloat(landMargin.last?.doubleValue ?? 0)
                let scenarios = [HudMigrationScenario(need: needPortrait, x: portX, y: portY, parentWidth: portraitWidth, parentHeight: portraitHeight, pref: portraitPref), HudMigrationScenario(need: needLandscape, x: landX, y: landY, parentWidth: landscapeWidth, parentHeight: landscapeHeight, pref: landscapePref)]
                for scn in scenarios where scn.need && scn.x > 0 && scn.y > 0 {
                    let distRight = max(0, scn.parentWidth - scn.x - buttonSizePt)
                    let distBottom = max(0, scn.parentHeight - scn.y - buttonSizePt)
                    let pos = ButtonPositionSize(id: hudId)
                    pos.setSize(width8dp: buttonCells, height8dp: buttonCells)
                    pos.setPositionHorizontal(posH: ButtonPositionSize.companion.POS_RIGHT)
                    pos.setPositionVertical(posV: ButtonPositionSize.companion.POS_BOTTOM)
                    pos.setMoveHorizontal()
                    pos.setMoveVertical()
                    pos.calcGridPositionFromPixel(dpToPix: 1.0, widthPx: Int32(scn.parentWidth.rounded()), heightPx: Int32(scn.parentHeight.rounded()), gravLeft: false, x: Int32(max(0, distRight.rounded())), gravTop: false, y: Int32(max(0, distBottom.rounded())))
                    scn.pref.set(Int(pos.toLongValue()), mode: mode)
                }
            }
        }
    }
    
    private func migrateRouteRecalulationValues() {
        let settings = OAAppSettings.sharedManager()
        for appMode in OAApplicationMode.allPossibleValues() {
            if settings.routeRecalculationDistance.get(appMode) == routeRecalculationDisableMode && !settings.disableOffrouteRecalc.get(appMode) {
                settings.routeRecalculationDistance.resetMode(toDefault: appMode)
            } else if settings.routeRecalculationDistance.get(appMode) != routeRecalculationDisableMode && settings.disableOffrouteRecalc.get(appMode) {
                settings.routeRecalculationDistance.set(routeRecalculationDisableMode, mode: appMode)
            }
        }
    }

    // MARK: - Import old versions

    func changeJsonMigrationToV2(_ json: [String: String]) -> [String: String] {

        // change keys inside old json import file after "Migration 1"

        let changeSettingKeys = [
            "top_widget_panel_order": "widget_top_panel_order",
            "bottom_widget_panel_order": "widget_bottom_panel_order",
            "shared_string_automatic": "driving_region_automatic",
            "external_input_device": "selected_external_input_device"
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
        
        let json = changeRouteRecalculationValuesForJson(json)

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

    func changeJsonMigrationToV3(_ jsonArray: [[String: String]]) throws -> [[String: String]] {

        // change keys inside old json import file after "Migration 2"

        let changeQuickActionStringIds = [
            "weather.temperature.showhide": "temperature.layer.showhide",
            "weather.pressure.showhide": "pressure.layer.showhide",
            "weather.wind.showhide": "wind.layer.showhide",
            "weather.cloud.showhide": "cloud.layer.showhide",
            "weather.precipitation.showhide": "precipitation.layer.showhide"
        ]

        return try Array(jsonArray.map {
            var json = $0
            if let stringId = json["actionType"] {
                let isMapSource = stringId == "mapsource.change"
                let isProfile = stringId == "profile.change"
                if isMapSource || isProfile, let paramsString = json["params"], let paramsData = paramsString.data(using: .utf8) {
                    var needToChange = false
                    if let paramsJson = try JSONSerialization.jsonObject(with: paramsData) as? [AnyHashable: Any] {
                        let paramsDict = NSMutableDictionary(dictionary: paramsJson)
                        if isMapSource {
                            OAQuickActionsSettingsItem.parseParams(withKey: "source", params: paramsDict, toString: false)
                        } else if isProfile {
                            needToChange = paramsDict["names"] != nil || paramsDict["iconsNames"] != nil || paramsDict["iconsColors"] != nil
                            paramsDict.removeObject(forKey: "names")
                            paramsDict.removeObject(forKey: "iconsNames")
                            paramsDict.removeObject(forKey: "iconsColors")
                        }
                        if let sourceParams = paramsDict["source"] as? [[String]] {
                            var newSourceParams = [[String]]()
                            for sourcePair in sourceParams {
                                if sourcePair.first == "type_default", let sourceValue = sourcePair.last {
                                    newSourceParams.append(["LAYER_OSM_VECTOR", sourceValue])
                                    needToChange = true
                                } else {
                                    newSourceParams.append(sourcePair)
                                }
                            }
                            if !sourceParams.elementsEqual(newSourceParams) {
                                if let newParamsData = QuickActionSerializer.paramsToExportArray(newSourceParams) {
                                    paramsDict["source"] = String(data: newParamsData, encoding: .utf8)
                                }
                            }
                        }
                        if needToChange {
                            let lisKey = isMapSource ? "source" : "profiles"
                            let newParams = QuickActionSerializer.adjustParamsForExport(paramsDict as! [AnyHashable: Any], listKey: lisKey)
                            if let jsonData = try? JSONSerialization.data(withJSONObject: newParams) {
                                json["params"] = String(data: jsonData, encoding: .utf8)
                            }
                        }
                    }
                } else if changeQuickActionStringIds.keys.contains(stringId) {
                    return Dictionary(uniqueKeysWithValues: json.map({
                        let key = $0
                        let value = $1
                        if key == "actionType", let newValue = changeQuickActionStringIds[value] {
                            return (key, newValue)
                        } else {
                            return (key, value)
                        }
                    }))
                }
            }
            return json
        })
    }
    
    private func changeRouteRecalculationValuesForJson(_ json: [String: String]) -> [String: String] {
        var json = json
        if let disableOffrouteRecalc = json["disable_offroute_recalc"],
           let routingRecalcDistance = json["routing_recalc_distance"] {
            let disableMode = String(routeRecalculationDisableMode)
            if routingRecalcDistance == disableMode && disableOffrouteRecalc == "false" {
                // Set default value
                json["routing_recalc_distance"] = "0.0"
            } else if routingRecalcDistance != disableMode && disableOffrouteRecalc == "true" {
                json["routing_recalc_distance"] = disableMode
            }
        }
        return json
    }
    
    private func migrateLocationIconSizeAndCourseIconSize() {
        let settings = OAAppSettings.sharedManager()
        for appMode in OAApplicationMode.allPossibleValues() {
            let locationIconSize = settings.locationIconSize.get(appMode)
            if locationIconSize <= 0 {
                settings.locationIconSize.resetToDefault()
            }
            let courseIconSize = settings.courseIconSize.get(appMode)
            if courseIconSize <= 0 {
                settings.courseIconSize.resetToDefault()
            }
        }
    }
}
