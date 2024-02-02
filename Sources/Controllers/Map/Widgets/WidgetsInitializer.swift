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
        OAPlugin.createMapWidgets(self, appMode: appMode, widgetParams: nil)
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
        updateUniqueKeys()
        if let widgetKeys = OAAppSettings.sharedManager().customWidgetKeys.get(appMode), !widgetKeys.isEmpty {
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
        let customWidgetKeys = OAAppSettings.sharedManager().customWidgetKeys
        if let widgetKeys = customWidgetKeys?.get(appMode), !widgetKeys.isEmpty {
            let uniqueKeys = Array(Set(widgetKeys))
            if uniqueKeys.count != widgetKeys.count {
                customWidgetKeys?.set(uniqueKeys, mode: appMode)
            }
        }
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
