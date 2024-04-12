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

    private static let minAltitudeValue = -20000.0

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
            guard let self else { return }

            forceUpdate = true
            self.widgetState?.changeToNextState()
            updateInfo()
            setContentTitle(getWidgetName())
        }
        setContentTitle(getWidgetName())
        setIcon("widget_glide_ratio_to_target")
    }

    override init(frame: CGRect) {
        widgetState = GlideTargetWidgetState(nil)
        super.init(frame: frame)
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

    override func getSettingsData(_ appMode: OAApplicationMode) -> OATableDataModel? {
        let data = OATableDataModel()
        let section = data.createNewSection()
        section.headerText = localizedString("shared_string_settings")
        section.footerText = localizedString("time_to_navigation_point_widget_settings_desc")

        if let preference = widgetState?.getPreference() {
            let settingRow = section.createNewRow()
            settingRow.cellType = OAValueTableViewCell.reuseIdentifier
            settingRow.key = "value_pref"
            settingRow.title = localizedString("shared_string_mode")
            settingRow.setObj(preference, forKey: "pref")
            settingRow.setObj(getWidgetName() ?? localizedString("glide_ratio_to_target"), forKey: "value")
            settingRow.setObj(getPossibleValues(), forKey: "possible_values")
        }
        return data
    }

    private func getPossibleValues() -> [OATableRowData] {
        var res = [OATableRowData]()
        for i in 0..<2 {
            let row = OATableRowData()
            row.cellType = OASimpleTableViewCell.getIdentifier()
            row.setObj(i == 0 ? "false" : "true", forKey: "value")
            row.title = localizedString(i == 0 ? "glide_ratio_to_target" : "target_elevation")
            res.append(row)
        }
        return res
    }

    func getWidgetName() -> String? {
        guard widgetState != nil else {
            return widgetType?.title
        }
        return localizedString(isInTargetAltitudeState() ? "target_elevation" : "glide_ratio_to_target")
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
                if let targetAltitude = targetAltitude, targetAltitude != GlideTargetWidget.minAltitudeValue,
                   let formattedAltitude = OAOsmAndFormatter.getFormattedAlt(targetAltitude) {
                    let components = formattedAltitude.components(separatedBy: " ")
                    if components.count == 2 {
                        let numberPart = components[0]
                        let unitPart = components[1]
                        setText(numberPart.trimWhitespaces(), subtext: unitPart)
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
        OsmAndApp.swiftInstance().locationServices?.lastKnownLocation
    }

    private func getTargetLocation() -> CLLocationCoordinate2D? {
        if let mapMarker = OADestinationsHelper.instance().sortedDestinations.firstObject as? OADestination {
            return CLLocationCoordinate2D(latitude: mapMarker.latitude, longitude: mapMarker.longitude)
        }
        return nil
    }

    private func calculateAltitude(_ location: CLLocationCoordinate2D, completion: @escaping (Double?) -> Void) {
        completion(CLLocationCoordinate2DIsValid(location) ? OAMapUtils.getAltitudeForLatLon(location) : Self.minAltitudeValue)
    }

    private func calculateFormattedRatio(_ l1: CLLocation?, a1: Double?, l2: CLLocationCoordinate2D?, a2: Double?) -> String? {
        guard let l1, let a1, let l2, let a2 else { return nil }
        return GlideUtils.calculateFormattedRatio(CLLocationCoordinate2D(latitude: l1.coordinate.latitude, longitude: l1.coordinate.longitude), l2: l2, a1: a1, a2: a2)
    }

    func isInTargetAltitudeState() -> Bool {
        widgetState?.getPreference().get() ?? false
    }
}
