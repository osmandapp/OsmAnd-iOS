//
//  GlideTargetWidget.swift
//  OsmAnd Maps
//
//  Created by Skalii on 06.03.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAGlideTargetWidget)
@objcMembers
final class GlideTargetWidget: GlideBaseWidget {
    
    private let widgetState: GlideTargetWidgetState?
    private var cachedCurrentLocation: CLLocation?
    private var cachedCurrentAltitude: Double?
    private var cachedTargetLocation: CLLocationCoordinate2D?
    private var cachedTargetAltitude: Double?
    private var cachedFormattedRatio: String?
    
    private var forceUpdate = false // Becomes 'true' when widget state switches

    init(with widgetState: GlideTargetWidgetState, customId: String?, appMode: OAApplicationMode, widgetParams: ([String: Any])? = nil) {
        self.widgetState = widgetState
        super.init(.glideTarget, customId: customId, appMode: appMode, widgetParams: widgetParams)

        updateInfo()
        onClickFunction = { [weak self] _ in
            self?.forceUpdate = true
            self?.widgetState?.changeToNextState()
            self?.updateInfo()
            self?.setContentTitle(self?.getWidgetName())
        }
        setContentTitle(getWidgetName())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateInfo() -> Bool {
        if isInTargetAltitudeState() {
            updateTargetAltitude()
        } else {
            updateRequiredRatioToTarget()
        }
        return true
    }
    
    func getWidgetName() -> String? {
        guard let widgetState else {
            return widgetType?.title ?? nil
        }
        return isInTargetAltitudeState() ? localizedString("target_elevation") : localizedString("glide_ratio_to_target")
    }
    
    private func updateTargetAltitude() {
        let targetLocation: CLLocationCoordinate2D? = getTargetLocation()
        let locationChanged: Bool = !OAMapUtils.areLatLonEqual(targetLocation ?? kCLLocationCoordinate2DInvalid,
                                                               l2: cachedTargetLocation ?? kCLLocationCoordinate2DInvalid)
        
        let metricSystemChanged: Bool = isUpdateNeeded()
        let updateNeeded = locationChanged || metricSystemChanged
        
        if !forceUpdate && !updateNeeded && !isTimeToUpdate(GlideBaseWidget.longUpdateIntervalMillis) {
            // Avoid too frequent calculations
            return
        }
        
        cachedTargetLocation = targetLocation
        
        calculateAltitude(targetLocation ?? kCLLocationCoordinate2DInvalid) { [weak self] targetAltitude in
            guard let self else { return }

            markUpdated()
            if forceUpdate || metricSystemChanged || !GlideUtils.areAltitudesEqual(cachedTargetAltitude, targetAltitude) {
                cachedTargetAltitude = targetAltitude
                if let cachedTargetAltitude {
                    let formattedAltitude: String = OAOsmAndFormatter.getFormattedAlt(cachedTargetAltitude)
                    let components = formattedAltitude.components(separatedBy: " ")
                    if components.count > 1 {
                        setText(components[0], subtext: components[1])
                    } else {
                        setText(formattedAltitude, subtext: "")
                    }
                } else {
                    setText("-", subtext: "")
                }
            }
        }
    }
    
    private func updateRequiredRatioToTarget() {
        let currentLocation: CLLocation? = getCurrentLocation()
        let currentLocationChanged: Bool = !OAMapUtils.areLocationEqual(currentLocation, l2: cachedCurrentLocation)
        let currentAltitude: Double? = currentLocation?.altitude != 0 ? currentLocation?.altitude : nil
        let currentAltitudeChanged: Bool = !GlideUtils.areAltitudesEqual(cachedCurrentAltitude, currentAltitude)

        let targetLocation: CLLocationCoordinate2D? = getTargetLocation()
        let targetLocationChanged: Bool = !OAMapUtils.areLatLonEqual(targetLocation ?? kCLLocationCoordinate2DInvalid,
                                                                     l2: cachedTargetLocation ?? kCLLocationCoordinate2DInvalid)

        let anyChanged = currentLocationChanged || currentAltitudeChanged || targetLocationChanged
        if !forceUpdate && !anyChanged && !isTimeToUpdate(GlideBaseWidget.longUpdateIntervalMillis) {
            // Avoid too frequent calculations
            return
        }

        markUpdated()
        cachedCurrentLocation = currentLocation
        cachedCurrentAltitude = currentAltitude
        cachedTargetLocation = targetLocation

        calculateAltitude(targetLocation ?? kCLLocationCoordinate2DInvalid) { [weak self] targetAltitude in
            guard let self else { return }

            markUpdated()
            if forceUpdate || anyChanged || !GlideUtils.areAltitudesEqual(cachedTargetAltitude, targetAltitude) {
                cachedTargetAltitude = targetAltitude
                let ratio: String? = calculateFormattedRatio(currentLocation, a1: currentAltitude, l2: targetLocation, a2: targetAltitude)
                if forceUpdate || cachedFormattedRatio != ratio {
                    cachedFormattedRatio = ratio
                    setText(cachedFormattedRatio, subtext: "")
                } else {
                    setText("-", subtext: "")
                }
            }
        }
    }
    
    private func getCurrentLocation() -> CLLocation? {
        return OsmAndApp.swiftInstance().locationServices.lastKnownLocation
    }
    
    private func getTargetLocation() -> CLLocationCoordinate2D? {
        if let mapMarker = OADestinationsHelper.instance().sortedDestinations.firstObject as? OADestination {
            return CLLocationCoordinate2D(latitude: mapMarker.latitude, longitude: mapMarker.longitude)
        }
        return nil
    }
    
    private func calculateAltitude(_ location: CLLocationCoordinate2D, completion: @escaping (Double?) -> Void) {
        completion(CLLocationCoordinate2DIsValid(location) ? nil : OAMapUtils.getAltitudeForLatLon(location))
    }
    
    private func calculateFormattedRatio(_ l1: CLLocation?, a1: Double?, l2: CLLocationCoordinate2D?, a2: Double?) -> String? {
        guard let l1, let a1, let l2, let a2, a2 != -2000.0 else { return nil }
        return GlideUtils.calculateFormattedRatio(CLLocationCoordinate2D(latitude: l1.coordinate.latitude, longitude: l1.coordinate.longitude), l2: l2, a1: a1, a2: a2)
    }
    
    func isInTargetAltitudeState() -> Bool {
        widgetState?.getPreference().get() ?? false
    }
}
