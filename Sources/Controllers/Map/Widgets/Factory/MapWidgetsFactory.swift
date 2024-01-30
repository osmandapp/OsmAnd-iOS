//
//  OABaseWidgetViewsFactory.swift
//  OsmAnd Maps
//
//  Created by Paul on 10.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAMapWidgetsFactory)
class MapWidgetsFactory: NSObject {
    
    func createMapWidget(widgetType: WidgetType, widgetParams: [String: Any]? = nil) -> OABaseWidgetView? {
        return createMapWidget(customId: nil, widgetType: widgetType, widgetParams: widgetParams)
    }
    
    func createMapWidget(customId: String?, widgetType: WidgetType, widgetParams: [String: Any]? = nil) -> OABaseWidgetView? {
        if isWidgetCreationAllowed(widgetType: widgetType) {
            return createMapWidgetImpl(customId: customId, widgetType: widgetType, widgetParams: widgetParams)
        }
        return nil
    }
    
    private func createMapWidgetImpl(customId: String?, widgetType: WidgetType, widgetParams: ([String: Any])? = nil) -> OABaseWidgetView? {
        let appMode = OAAppSettings.sharedManager().applicationMode.get()!
        switch widgetType {
        case .nextTurn:
            return OANextTurnWidget(horisontalMini: false, nextNext: false, customId: customId, appMode: appMode)
        case .smallNextTurn:
            return OANextTurnWidget(horisontalMini: true, nextNext: false, customId: customId, appMode: appMode)
        case .secondNextTurn:
            return OANextTurnWidget(horisontalMini: true, nextNext: true, customId: customId, appMode: appMode)
        case .coordinatesCurrentLocation:
            let widget = CoordinatesCurrentLocationWidget()
            widget.delegate = OARootViewController.instance().mapPanel.hudViewController.mapInfoController
            return widget
        case .coordinatesMapCenter:
            let widget = CoordinatesMapCenterWidget()
            widget.delegate = OARootViewController.instance().mapPanel.hudViewController.mapInfoController
            return widget
        case .streetName:
            let widget = OATopTextView()
            widget.delegate = OARootViewController.instance().mapPanel.hudViewController.mapInfoController
            return widget
        case .markersTopBar:
            let widget = OADestinationBarWidget()
            widget.delegate = OARootViewController.instance().mapPanel.hudViewController.mapInfoController
            return widget
        case .lanes:
            let widget = OALanesControl()
            widget.delegate = OARootViewController.instance().mapPanel.hudViewController.mapInfoController
            return widget
        case .distanceToDestination:
            return DistanceToDestinationWidget(customId: customId, appMode: appMode)
        case .intermediateDestination:
            return DistanceToIntermediateDestinationWidget(customId: customId, appMode: appMode)
        case .timeToIntermediate:
            let state = TimeToNavigationPointWidgetState(customId: customId, intermediate: true)
            return TimeToNavigationPointWidget(widgetState: state, appMode: appMode)
        case .timeToDestination:
            let widgetState = TimeToNavigationPointWidgetState(customId: customId, intermediate: false)
            return TimeToNavigationPointWidget(widgetState: widgetState, appMode: appMode)
        case .sideMarker1:
            let firstMarkerState = MapMarkerSideWidgetState(customId: customId, firstMarker: true)
            return MapMarkerSideWidget(widgetState: firstMarkerState, appMode: appMode)
        case .sideMarker2:
            let secondMarkerState = MapMarkerSideWidgetState(customId: customId, firstMarker: false)
            return MapMarkerSideWidget(widgetState: secondMarkerState, appMode: appMode)
        case .relativeBearing:
            return OABearingWidget(bearingType: .relative, customId: customId, appMode: appMode)
        case .magneticBearing:
            return OABearingWidget(bearingType: .magnetic, customId: customId, appMode: appMode)
        case .trueBearing:
            return OABearingWidget(bearingType: .true, customId: customId, appMode: appMode)
        case .currentSpeed:
            return OACurrentSpeedWidget(customId: customId, appMode: appMode)
        case .averageSpeed:
            if let widgetParams {
                return AverageSpeedWidget(customId: customId,
                                          appMode: appMode,
                                          widgetParams: widgetParams)
            } else {
                return AverageSpeedWidget(customId: customId, appMode: appMode)
            }
        case .maxSpeed:
            return OAMaxSpeedWidget(customId: customId, appMode: appMode)
        case .altitudeMyLocation:
            return OAAltitudeWidget(type: .myLocation, customId: customId, appMode: appMode)
        case .altitudeMapCenter:
            return OAAltitudeWidget(type: .mapCenter, customId: customId, appMode: appMode)
        case .gpsInfo:
            return /*GpsInfoWidget(mapActivity: mapActivity)*/nil
        case .currentTime:
            return CurrentTimeWidget(customId: customId, appMode: appMode)
        case .battery:
            return BatteryWidget(customId: customId, appMode: appMode, widgetParams: widgetParams)
        case .radiusRuler:
            return RulerDistanceWidget(customId: customId, appMode: appMode)
        case .sunrise:
            let sunriseState = OASunriseSunsetWidgetState(type: true, customId: customId)
            return OASunriseSunsetWidget(state: sunriseState, appMode: appMode)
        case .sunset:
            let sunsetState = OASunriseSunsetWidgetState(type: false, customId: customId)
            return OASunriseSunsetWidget(state: sunsetState, appMode: appMode)
        case .elevationProfile:
            return /*ElevationProfileWidget(mapActivity: mapActivity)*/nil
        case .heartRate, .bicycleCadence, .bicycleDistance, .bicycleSpeed, .temperature:
            return SensorTextWidget(customId: customId, widgetType: widgetType, appMode: appMode, widgetParams: widgetParams)
        default:
            return OAPlugin.createMapWidget(widgetType, customId: customId, appMode: appMode)
        }
    }
    
    private func isWidgetCreationAllowed(widgetType: WidgetType) -> Bool {
        if widgetType == .altitudeMapCenter {
            let plugin = OAPlugin.getEnabledPlugin(OASRTMPlugin.self) as? OASRTMPlugin
            return plugin != nil && plugin!.is3DMapsEnabled()
        }
        return true
    }
}
