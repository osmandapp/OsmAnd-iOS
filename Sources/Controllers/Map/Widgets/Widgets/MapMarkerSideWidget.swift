//
//  MapMarkerSideWidget.swift
//  OsmAnd Maps
//
//  Created by Paul on 11.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation
import CoreLocation

@objc(OAMapMarkerSideWidget)
@objcMembers
class MapMarkerSideWidget: OATextInfoWidget, CustomLatLonListener {
    private static let DASH = "—"
    
    private var mapMarkersHelper: OADestinationsHelper = OADestinationsHelper.instance()!
    private var widgetState: MapMarkerSideWidgetState
    private var markerModePref: OACommonString
    private var markerClickBehaviourPref: OACommonString
    
    private var cachedMode: SideMarkerMode?
    private var cachedMeters: Int = 0
    private var lastUpdatedTime: TimeInterval = 0
    private var cachedMarkerColorIndex: Int = -1
    private var cachedNightMode: Bool = false
    
    private var customLatLon: CLLocation?
    
    convenience init(widgetState: MapMarkerSideWidgetState) {
        
        self.init(frame: .zero)
        
        self.widgetType = widgetState.isFirstMarker() ? WidgetType.sideMarker1 : WidgetType.sideMarker2
        self.widgetState = widgetState
        self.markerModePref = widgetState.mapMarkerModePref
        self.markerClickBehaviourPref = widgetState.markerClickBehaviourPref
        self.cachedNightMode = self.nightMode
        self.cachedMode = SideMarkerMode.markerModeByName(markerModePref.get())
        
        setText(nil, subtext: nil)
        
        onClickFunction = { [weak self] _ in
            if self?.markerClickBehaviourPref.get() == MarkerClickBehaviour.switchMode.name {
                self?.changeWidgetState()
            } else if self?.markerClickBehaviourPref.get() == MarkerClickBehaviour.goToMarkerLocation.name {
                self?.showMarkerOnMap()
            }
        }
    }
    
    override init(frame: CGRect) {
        let widgetState = MapMarkerSideWidgetState(customId: "", firstMarker: true)
        self.widgetState = widgetState
        self.markerModePref = widgetState.mapMarkerModePref
        self.markerClickBehaviourPref = widgetState.markerClickBehaviourPref
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func changeWidgetState() {
        widgetState.changeToNextState()
        _ = updateInfo()
    }
    
    private func showMarkerOnMap() {
        MarkerWidgetsHelper.showMarkerOnMap(widgetState.isFirstMarker() ? 0 : 1)
    }
    
    override func getWidgetState() -> OAWidgetState {
        return widgetState
    }
    
    func setCustomLatLon(_ customLatLon: CLLocation?) {
        self.customLatLon = customLatLon!
    }
    
    override func updateInfo() -> Bool {
        let routingHelper = OARoutingHelper.sharedInstance()!
        guard let marker = getMarker(), !routingHelper.isRoutePlanningMode(), !routingHelper.isFollowingMode() else {
            cachedMeters = 0
            lastUpdatedTime = 0
            setText(nil, subtext: nil)
            return true
        }
        
        let newModeStr = markerModePref.get()!
        let newMode = SideMarkerMode.markerModeByName(newModeStr)!
        let modeChanged = cachedMode != newMode
        if modeChanged {
            cachedMode = newMode
        }
        
        updateTextIfNeeded(newMode: newMode, modeChanged: modeChanged)
        updateIconIfNeeded(marker: marker, newMode: newMode, modeChanged: modeChanged)
        return true
    }
    
    private func updateTextIfNeeded(newMode: SideMarkerMode, modeChanged: Bool) {
        let distance = getDistance()
        let currentTime = Date().timeIntervalSince1970
        
        let distanceChanged = cachedMeters != distance
        let timePassed = currentTime - lastUpdatedTime > TimeInterval(UPDATE_INTERVAL_MILLIS) / 1000.0
        let shouldUpdateDistance = newMode == .distance && distanceChanged
        let shouldUpdateArrivalTime = newMode == SideMarkerMode.estimatedArrivalTime && (distanceChanged || timePassed)
        
        if isUpdateNeeded() || modeChanged || shouldUpdateDistance || shouldUpdateArrivalTime {
            if newMode == .distance {
                updateDistance(distance: distance)
            } else if newMode == .estimatedArrivalTime {
                updateArrivalTime(distance: distance, currentTime: currentTime)
            }
        }
    }
    
    private func updateDistance(distance: Int) {
        cachedMeters = distance
        let formattedDistance = OAOsmAndFormatter.getFormattedDistance(Float(distance)).components(separatedBy: " ")
        setText(formattedDistance.first, subtext: formattedDistance.last)
    }
    
    private func updateArrivalTime(distance: Int, currentTime: TimeInterval) {
        cachedMeters = distance
        lastUpdatedTime = currentTime
        
        let averageSpeedComputer = OAAverageSpeedComputer.sharedInstance()
        let interval = widgetState.averageSpeedIntervalPref.get()
        let averageSpeed = averageSpeedComputer.getAverageSpeed(interval, skipLowSpeed: false)
        
        if averageSpeed.isNaN || averageSpeed == 0 {
            setText(Self.DASH, subtext: nil)
            return
        }
        
        let estimatedLeftSeconds = Int(Double(distance) / Double(averageSpeed))
        let estimatedArrivalTime = currentTime + TimeInterval(estimatedLeftSeconds)
        setTimeText(estimatedArrivalTime)
    }
    
    private func updateIconIfNeeded(marker: OADestination, newMode: SideMarkerMode, modeChanged: Bool) {
//        let colorIndex = marker.color
//        let colorChanged = colorIndex != -1 && (colorIndex != cachedMarkerColorIndex || cachedNightMode != isNightMode())
//
//        if colorChanged || modeChanged {
//            cachedMarkerColorIndex = colorIndex
//            cachedNightMode = isNightMode()
//
//            let backgroundIconId = widgetState.getSettingsIconId(isNightMode: cachedNightMode)
//            let foregroundColorId = MapMarker.getColorId(colorIndex: colorIndex)
//            let drawable = iconsCache.getLayeredIcon(backgroundIconId: backgroundIconId, foregroundIconId: newMode.foregroundIconId, secondForegroundIconId: 0, foregroundColorId: foregroundColorId)
//            setImageDrawable(drawable)
//        }
    }
    
    func getDistance() -> Int {
        var distance = 0
        if let pointToNavigate = getPointToNavigate() {
            let latLon = customLatLon ?? OAMapViewTrackingUtilities.instance().getDefaultLocation()!
            distance = Int(latLon.distance(from: pointToNavigate))
        }
        return distance
    }
    
    private func getPointToNavigate() -> CLLocation? {
        let markers = mapMarkersHelper.sortedDestinationsWithoutParking() as? [OADestination] ?? [OADestination]()
        if markers.count > 0 {
            var marker: OADestination?
            if widgetState.isFirstMarker() {
                marker = markers[0]
            } else if markers.count > 1 {
                marker = markers[1]
            }
            if let marker {
                return CLLocation(latitude: marker.latitude, longitude: marker.longitude)
            }
        }
        return nil
    }
    
    private func getMarker() -> OADestination? {
        let markers = mapMarkersHelper.sortedDestinationsWithoutParking() as? [OADestination] ?? [OADestination]()
        if (!markers.isEmpty) {
            if (widgetState.isFirstMarker()) {
                return markers[0]
            } else if (markers.count > 1) {
                return markers[1]
            }
        }
        return nil;
    }
    
    override func isMetricSystemDepended() -> Bool {
        return true
    }
}
