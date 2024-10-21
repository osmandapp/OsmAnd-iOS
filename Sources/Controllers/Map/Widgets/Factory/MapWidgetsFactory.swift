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
        return createMapWidgetImpl(customId: customId, widgetType: widgetType, widgetParams: widgetParams)
    }
    
    private func createMapWidgetImpl(customId: String?, widgetType: WidgetType, widgetParams: ([String: Any])? = nil) -> OABaseWidgetView? {
        let appMode = OAAppSettings.sharedManager().applicationMode.get()!
        switch widgetType {
        case .nextTurn:
            return OANextTurnWidget(horisontalMini: false, nextNext: false, customId: customId, appMode: appMode, widgetParams: widgetParams)
        case .smallNextTurn:
            return OANextTurnWidget(horisontalMini: true, nextNext: false, customId: customId, appMode: appMode, widgetParams: widgetParams)
        case .secondNextTurn:
            return OANextTurnWidget(horisontalMini: true, nextNext: true, customId: customId, appMode: appMode, widgetParams: widgetParams)
        case .coordinatesCurrentLocation:
            let widget = CoordinatesCurrentLocationWidget()
            widget.delegate = OARootViewController.instance().mapPanel.hudViewController?.mapInfoController
            return widget
        case .coordinatesMapCenter:
            let widget = CoordinatesMapCenterWidget()
            widget.delegate = OARootViewController.instance().mapPanel.hudViewController?.mapInfoController
            return widget
        case .streetName:
            let widget = OATopTextView()
            widget.delegate = OARootViewController.instance().mapPanel.hudViewController?.mapInfoController
            return widget
        case .markersTopBar:
            let widget = OADestinationBarWidget()
            widget.delegate = OARootViewController.instance().mapPanel.hudViewController?.mapInfoController
            return widget
        case .lanes:
            let widget = OALanesControl()
            widget.delegate = OARootViewController.instance().mapPanel.hudViewController?.mapInfoController
            return widget
        case .distanceToDestination:
            return DistanceToDestinationWidget(customId: customId, appMode: appMode, widgetParams: widgetParams)
        case .intermediateDestination:
            return DistanceToIntermediateDestinationWidget(customId: customId, appMode: appMode, widgetParams: widgetParams)
        case .timeToIntermediate:
            let state = TimeToNavigationPointWidgetState(customId: customId, intermediate: true)
            return TimeToNavigationPointWidget(widgetState: state, appMode: appMode, widgetParams: widgetParams)
        case .timeToDestination:
            let widgetState = TimeToNavigationPointWidgetState(customId: customId, intermediate: false)
            return TimeToNavigationPointWidget(widgetState: widgetState, appMode: appMode, widgetParams: widgetParams)
        case .sideMarker1:
            let firstMarkerState = MapMarkerSideWidgetState(customId: customId, firstMarker: true)
            return MapMarkerSideWidget(widgetState: firstMarkerState, appMode: appMode, widgetParams: widgetParams)
        case .sideMarker2:
            let secondMarkerState = MapMarkerSideWidgetState(customId: customId, firstMarker: false)
            return MapMarkerSideWidget(widgetState: secondMarkerState, appMode: appMode, widgetParams: widgetParams)
        case .relativeBearing:
            return OABearingWidget(bearingType: .relative, customId: customId, appMode: appMode, widgetParams: widgetParams)
        case .magneticBearing:
            return OABearingWidget(bearingType: .magnetic, customId: customId, appMode: appMode, widgetParams: widgetParams)
        case .trueBearing:
            return OABearingWidget(bearingType: .true, customId: customId, appMode: appMode, widgetParams: widgetParams)
        case .currentSpeed:
            return OACurrentSpeedWidget(customId: customId, appMode: appMode, widgetParams: widgetParams)
        case .averageSpeed:
            if let widgetParams {
                return AverageSpeedWidget(customId: customId,
                                          appMode: appMode,
                                          widgetParams: widgetParams)
            } else {
                return AverageSpeedWidget(customId: customId, appMode: appMode)
            }
        case .maxSpeed:
            return OAMaxSpeedWidget(customId: customId, appMode: appMode, widgetParams: widgetParams)
        case .altitudeMyLocation:
            return OAAltitudeWidget(type: .myLocation, customId: customId, appMode: appMode, widgetParams: widgetParams)
        case .altitudeMapCenter:
            return OAAltitudeWidget(type: .mapCenter, customId: customId, appMode: appMode, widgetParams: widgetParams)
        case .gpsInfo:
            return /*GpsInfoWidget(mapActivity: mapActivity)*/nil
        case .currentTime:
            return CurrentTimeWidget(customId: customId, appMode: appMode, widgetParams: widgetParams)
        case .battery:
            return BatteryWidget(customId: customId, appMode: appMode, widgetParams: widgetParams)
        case .radiusRuler:
            return RulerDistanceWidget(customId: customId, appMode: appMode, widgetParams: widgetParams)
        case .sunrise:
            let sunriseState = OASunriseSunsetWidgetState(widgetType: .sunrise, customId: customId)
            return OASunriseSunsetWidget(state: sunriseState, appMode: appMode, widgetParams: widgetParams)
        case .sunset:
            let sunsetState = OASunriseSunsetWidgetState(widgetType: .sunset, customId: customId)
            return OASunriseSunsetWidget(state: sunsetState, appMode: appMode, widgetParams: widgetParams)
        case .sunPosition:
            let sunPositiontState = OASunriseSunsetWidgetState(widgetType: .sunPosition, customId: customId)
            return OASunriseSunsetWidget(state: sunPositiontState, appMode: appMode, widgetParams: widgetParams)
        case .glideTarget:
            let glideWidgetState = GlideTargetWidgetState(customId)
            return GlideTargetWidget(with: glideWidgetState, customId: customId, appMode: appMode, widgetParams: widgetParams)
        case .glideAverage:
            let glideWidgetState = GlideAverageWidgetState(customId)
            return GlideAverageWidget(with: glideWidgetState, customId: customId, appMode: appMode, widgetParams: widgetParams)
        case .elevationProfile:
            return /*ElevationProfileWidget(mapActivity: mapActivity)*/nil
        case .heartRate, .bicycleCadence, .bicycleDistance, .bicycleSpeed, .temperature:
            return SensorTextWidget(customId: customId, widgetType: widgetType, appMode: appMode, widgetParams: widgetParams)
        default:
            return OAPluginsHelper.createMapWidget(widgetType, customId: customId, appMode: appMode, widgetParams: widgetParams)
        }
    }
}
