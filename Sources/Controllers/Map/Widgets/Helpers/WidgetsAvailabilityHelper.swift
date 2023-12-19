//
//  WidgetsAvailabilityHelper.swift
//  OsmAnd Maps
//
//  Created by Paul on 04.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAWidgetsAvailabilityHelper)
@objcMembers
class WidgetsAvailabilityHelper: NSObject {
    private static var widgetsVisibilityMap = [String: Set<OAApplicationMode>]()
    private static var widgetsAvailabilityMap = [String: Set<OAApplicationMode>]()
    
    static func isWidgetAvailable(widgetId: String, appMode: OAApplicationMode) -> Bool {
//        if app.getAppCustomization().areWidgetsCustomized() {
//            return app.getAppCustomization().isWidgetAvailable(widgetId: widgetId, appMode: appMode)
//        }
        let defaultWidgetId = WidgetType.getDefaultWidgetId(widgetId)
        let availableForModes = widgetsAvailabilityMap[defaultWidgetId]
        return availableForModes == nil || availableForModes!.contains(appMode)
    }
    
    static func isWidgetVisibleByDefault(widgetId: String, appMode: OAApplicationMode) -> Bool {
//        if app.getAppCustomization().areWidgetsCustomized() {
//            return app.getAppCustomization().isWidgetVisible(widgetId: widgetId, appMode: appMode)
//        }
        let widgetsVisibility = widgetsVisibilityMap[widgetId]
        return widgetsVisibility != nil && widgetsVisibility!.contains(appMode)
    }
    
    static func initRegVisibility() {
        let exceptDefault: [OAApplicationMode] = [.car(), .bicycle(), .pedestrian(), .public_TRANSPORT(), .boat(), .aircraft(), .ski(), .truck(), .motorcycle(), .horse(), .moped()]
        
        // left
        let navigationSet1: [OAApplicationMode] = [.car(), .bicycle(), .boat(), .ski(), .truck(), .motorcycle(), .horse(), .moped()]
        let navigationSet2: [OAApplicationMode] = [.pedestrian(), .public_TRANSPORT(), .aircraft()]
        
        regWidgetVisibility(widgetType: .nextTurn, appModes: navigationSet1)
        regWidgetVisibility(widgetType: .smallNextTurn, appModes: navigationSet2)
        regWidgetVisibility(widgetType: .secondNextTurn, appModes: navigationSet1 + [.pedestrian()])
        regWidgetAvailability(widgetType: .nextTurn, appModes: exceptDefault)
        regWidgetAvailability(widgetType: .smallNextTurn, appModes: exceptDefault)
        regWidgetAvailability(widgetType: .secondNextTurn, appModes: exceptDefault)
        
        // right
        regWidgetVisibility(widgetType: .intermediateDestination)
        regWidgetVisibility(widgetType: .distanceToDestination)
        regWidgetVisibility(widgetType: .timeToIntermediate)
        regWidgetVisibility(widgetType: .timeToDestination)
        regWidgetVisibility(widgetType: .currentSpeed, appModes: [.car(), .bicycle(), .boat(), .ski(), .public_TRANSPORT(), .aircraft(), .truck(), .motorcycle(), .horse(), .moped()])
        regWidgetVisibility(widgetType: .maxSpeed, appModes: [.car(), .truck(), .motorcycle(), .moped()])
        regWidgetVisibility(widgetType: .altitudeMapCenter, appModes: [.pedestrian(), .bicycle()])
        regWidgetVisibility(widgetType: .altitudeMyLocation, appModes: [.pedestrian(), .bicycle()])
        regWidgetAvailability(widgetType: .intermediateDestination)
        regWidgetAvailability(widgetType: .distanceToDestination)
        regWidgetAvailability(widgetType: .timeToIntermediate)
        regWidgetAvailability(widgetType: .timeToDestination)
        regWidgetAvailability(widgetType: .currentSpeed)
        regWidgetAvailability(widgetType: .maxSpeed)
        regWidgetAvailability(widgetType: .averageSpeed)
        regWidgetAvailability(widgetType: .altitudeMyLocation)
        regWidgetAvailability(widgetType: .altitudeMapCenter)
        regWidgetAvailability(widgetType: .sunrise)
        regWidgetAvailability(widgetType: .sunset)
        
        // vertical
        regWidgetVisibility(widgetType: .streetName, appModes: [.car()])
        regWidgetVisibility(widgetType: .lanes, appModes: [.car(), .bicycle()])
        regWidgetVisibility(widgetType: .markersTopBar)

        // all = nil everything
        regWidgetAvailability(widgetType: .sideMarker1)
        regWidgetAvailability(widgetType: .sideMarker2)
        regWidgetAvailability(widgetType: .gpsInfo)
        regWidgetAvailability(widgetType: .battery)
        regWidgetAvailability(widgetType: .relativeBearing)
        regWidgetAvailability(widgetType: .magneticBearing)
        regWidgetAvailability(widgetType: .trueBearing)
        regWidgetAvailability(widgetType: .radiusRuler)
        regWidgetAvailability(widgetType: .currentTime)
    }
    
    static func regWidgetVisibility(widgetType: WidgetType, appModes: [OAApplicationMode]? = nil) {
        regWidgetVisibility(widgetId: widgetType.id, appModes: appModes)
    }
    
    static func regWidgetVisibility(widgetId: String, appModes: [OAApplicationMode]? = nil) {
        registerWidget(widgetId: widgetId, map: &widgetsVisibilityMap, appModes: appModes)
    }
    
    static func regWidgetAvailability(widgetType: WidgetType, appModes: [OAApplicationMode]? = nil) {
        regWidgetAvailability(widgetId: widgetType.id, appModes: appModes)
    }
    
    static func regWidgetAvailability(widgetId: String, appModes: [OAApplicationMode]? = nil) {
        registerWidget(widgetId: widgetId, map: &widgetsAvailabilityMap, appModes: appModes)
    }
    
    private static func registerWidget(widgetId: String,
                                       map: inout [String: Set<OAApplicationMode>],
                                       appModes: [OAApplicationMode]?) {
        var set = Set<OAApplicationMode>()
        if appModes == nil {
            set.formUnion(OAApplicationMode.allPossibleValues())
        } else {
            set.formUnion(appModes!)
        }
        for mode in OAApplicationMode.allPossibleValues() {
            // add derived modes
            if let parent = mode.parent, set.contains(parent) {
                set.insert(mode)
            }
        }
        map[widgetId] = set
    }
}
