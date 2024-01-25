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
    func addWidget(_ widgetInfo: MapWidgetInfo)
}

@objc(OAWidgetsInitializer)
@objcMembers
class WidgetsInitializer: NSObject, WidgetRegistrationDelegate {
    private let appMode: OAApplicationMode
    private let factory: MapWidgetsFactory
    private let creator: WidgetInfoCreator
    private var mapWidgetsCache: [MapWidgetInfo] = []
    
    private init(_ appMode: OAApplicationMode) {
        self.appMode = appMode
        self.factory = MapWidgetsFactory()
        self.creator = WidgetInfoCreator(appMode: appMode)
    }
    
    private func createAllControls() -> [MapWidgetInfo] {
        createCommonWidgets()
        OAPlugin.createMapWidgets(self, appMode: appMode)
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
        addWidgetInfo(.sunrise)
        addWidgetInfo(.sunset)
    }
    
    private func addWidgetInfo(_ widgetType: WidgetType) {
        guard let widgetInfo = creator.createWidgetInfo(factory: factory, widgetType: widgetType) else {
            return
        }
        mapWidgetsCache.append(widgetInfo)
    }
    
    private func createCustomWidgets() {
        let widgetKeys = OAAppSettings.sharedManager().customWidgetKeys.get(appMode)
        if let widgetKeys, !widgetKeys.isEmpty {
            checkAndResetCustomIdsIfNeeded()
            for key in widgetKeys {
                if let widgetType = WidgetType.getById(key) {
                    if let widgetInfo = creator.createCustomWidgetInfo(factory: factory, key: key, widgetType: widgetType) {
                        mapWidgetsCache.append(widgetInfo)
                    }
                }
            }
        }
    }

    private func checkAndResetCustomIdsIfNeeded() {
        let customWidgetKeys = OAAppSettings.sharedManager().customWidgetKeys
        let widgetKeys = customWidgetKeys?.get(appMode)
        if let widgetKeys, !widgetKeys.isEmpty {
            var checkedWidgetKeys = [String]()
            let hasDuplicates: Bool = hasDuplicates(widgetKeys, checkedKeys: &checkedWidgetKeys)
            if hasDuplicates {
                customWidgetKeys?.set(checkedWidgetKeys, mode: appMode)
            }
        }
    }

    private func hasDuplicates(_ checkingKeys: [String], checkedKeys: inout [String]) -> Bool {
        var hasDuplicates = false
        for checkingKey in checkingKeys {
            if checkedKeys.contains(checkingKey) {
                hasDuplicates = true
            } else {
                checkedKeys.append(checkingKey)
            }
        }
        return hasDuplicates
    }

    static func createAllControls(appMode: OAApplicationMode) -> [MapWidgetInfo] {
        let initializer = WidgetsInitializer(appMode)
        return initializer.createAllControls()
    }
    
    // MARK: WidgetRegistrationDelegate
    
    func addWidget(_ widgetInfo: MapWidgetInfo) {
        mapWidgetsCache.append(widgetInfo)
    }
}
