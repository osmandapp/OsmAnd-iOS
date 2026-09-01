//
//  WidgetsInitializer.swift
//  OsmAnd Maps
//
//  Created by Paul on 31.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAWidgetRegistrationDelegate)
protocol WidgetRegistrationDelegate {
    var screenLayoutMode: ScreenLayoutMode { get }
    func addWidget(_ widgetInfo: MapWidgetInfo)
}

@objc(OAWidgetsInitializer)
@objcMembers
class WidgetsInitializer: NSObject, WidgetRegistrationDelegate {
    private let appMode: OAApplicationMode
    let screenLayoutMode: ScreenLayoutMode
    private let screenElementsMode: ScreenElementsMode
    private let factory: MapWidgetsFactory
    private let creator: WidgetInfoCreator
    private var mapWidgetsCache: [MapWidgetInfo] = []
    
    private init(_ appMode: OAApplicationMode,
                 screenLayoutMode: ScreenLayoutMode,
                 screenElementsMode: ScreenElementsMode) {
        self.appMode = appMode
        self.screenLayoutMode = screenLayoutMode
        self.screenElementsMode = screenElementsMode
        self.factory = MapWidgetsFactory()
        self.creator = WidgetInfoCreator(appMode: appMode, screenLayoutMode: screenLayoutMode)
    }
    
    private func createAllControls() -> [MapWidgetInfo] {
        createCommonWidgets()
        OAPluginsHelper.createMapWidgets(self, appMode: appMode, widgetParams: nil)
//        app.getAidlApi().createWidgetControls(mapActivity, mapWidgetsCache, appMode)
        createCustomWidgets()
        return mapWidgetsCache
    }
    
    private func createCommonWidgets() {
        createTopWidgets()
        createBottomWidgets()
        createLeftWidgets()
        createRightWidgets()
    }
    
    private func createTopWidgets() {
        addWidgetInfo(.coordinatesCurrentLocation)
        addWidgetInfo(.coordinatesMapCenter)
        addWidgetInfo(.streetName)
        addWidgetInfo(.lanes)
        addWidgetInfo(.routeInfo)
        addWidgetInfo(.markersTopBar)
    }
    
    private func createBottomWidgets() {
        addWidgetInfo(.elevationProfile)
    }
    
    private func createLeftWidgets() {
        addWidgetInfo(.nextTurn)
        addWidgetInfo(.smallNextTurn)
        addWidgetInfo(.secondNextTurn)
    }
    
    private func createRightWidgets() {
        addWidgetInfo(.intermediateDestination)
        addWidgetInfo(.distanceToDestination)
        addWidgetInfo(.relativeBearing)
        addWidgetInfo(.magneticBearing)
        addWidgetInfo(.trueBearing)
        addWidgetInfo(.currentSpeed)
        addWidgetInfo(.averageSpeed)
        addWidgetInfo(.maxSpeed)
        addWidgetInfo(.altitudeMapCenter)
        addWidgetInfo(.altitudeMyLocation)
        addWidgetInfo(.gpsInfo)
        addWidgetInfo(.currentTime)
        addWidgetInfo(.battery)
        addWidgetInfo(.radiusRuler)
        addWidgetInfo(.timeToIntermediate)
        addWidgetInfo(.timeToDestination)
        addWidgetInfo(.sideMarker1)
        addWidgetInfo(.sideMarker2)
        addWidgetInfo(.sunPosition)
        addWidgetInfo(.sunrise)
        addWidgetInfo(.sunset)
        addWidgetInfo(.glideTarget)
        addWidgetInfo(.glideAverage)
    }
    
    private func addWidgetInfo(_ widgetType: WidgetType) {
        guard let widgetInfo = creator.createWidgetInfo(factory: factory, widgetType: widgetType) else {
            return
        }
        mapWidgetsCache.append(widgetInfo)
    }
    
    private func createCustomWidgets() {
        updateUniqueKeys()
        let widgetKeys = customWidgetKeysPreference().get(appMode)
        if !widgetKeys.isEmpty {
            for key in widgetKeys {
                if let widgetType = WidgetType.getById(key) {
                    if let widgetInfo = creator.createCustomWidgetInfo(factory: factory, key: key, widgetType: widgetType) {
                        mapWidgetsCache.append(widgetInfo)
                    }
                }
            }
        }
    }

    private func updateUniqueKeys() {
        let customWidgetKeys = customWidgetKeysPreference()
        let widgetKeys = customWidgetKeys.get(appMode)
        if !widgetKeys.isEmpty {
            let uniqueKeys = Array(Set(widgetKeys))
            if uniqueKeys.count != widgetKeys.count {
                customWidgetKeys.set(uniqueKeys, mode: appMode)
            }
        }
    }

    static func createAllControls(appMode: OAApplicationMode, screenLayoutMode: ScreenLayoutMode) -> [MapWidgetInfo] {
        let screenElementsMode = ScreenElementsMode(usesSeparateLayouts: OAAppSettings.sharedManager().useSeparateLayouts.get(appMode))
        return createAllControls(appMode: appMode,
                                 screenLayoutMode: screenLayoutMode,
                                 screenElementsMode: screenElementsMode)
    }

    static func createAllControls(appMode: OAApplicationMode,
                                  screenLayoutMode: ScreenLayoutMode,
                                  screenElementsMode: ScreenElementsMode) -> [MapWidgetInfo] {
        let initializer = WidgetsInitializer(appMode,
                                             screenLayoutMode: screenLayoutMode,
                                             screenElementsMode: screenElementsMode)
        return initializer.createAllControls()
    }

    private func customWidgetKeysPreference() -> OACommonStringList {
        let settings = OAAppSettings.sharedManager()
        return settings.customWidgetKeys(screenLayoutMode.rawValue,
                                         screenElementsMode: screenElementsMode.rawValue)
    }

    // MARK: WidgetRegistrationDelegate
    
    func addWidget(_ widgetInfo: MapWidgetInfo) {
        mapWidgetsCache.append(widgetInfo)
    }
}
