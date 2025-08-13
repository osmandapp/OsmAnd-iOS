//
//  MapMarkerSideWidget.swift
//  OsmAnd Maps
//
//  Created by Paul on 11.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import CoreLocation

@objc(OAMapMarkerSideWidget)
@objcMembers
final class MapMarkerSideWidget: OASimpleWidget, CustomLatLonListener {
    private static let DASH = "—"
    
    private var mapMarkersHelper: OADestinationsHelper = OADestinationsHelper.instance()!
    private var widgetState: MapMarkerSideWidgetState
    private var markerModePref: OACommonString
    private var averageSpeedIntervalPref: OACommonLong
    private var markerClickBehaviourPref: OACommonString
    
    private var cachedMode: SideMarkerMode?
    private var cachedMeters: Int = 0
    private var lastUpdatedTime: TimeInterval = 0
    private var cachedMarkerColor: UIColor?
    private var cachedNightMode: Bool = false
    
    private var customLatLon: CLLocation?
    
    convenience init(widgetState: MapMarkerSideWidgetState, appMode: OAApplicationMode, widgetParams: ([String: Any])? = nil) {
        
        self.init(frame: .zero)
        self.widgetType = widgetState.isFirstMarker() ? WidgetType.sideMarker1 : WidgetType.sideMarker2
        configurePrefs(withId: widgetState.customId, appMode: appMode, widgetParams: widgetParams)
        self.widgetState = widgetState
        self.markerModePref = widgetState.mapMarkerModePref
        self.averageSpeedIntervalPref = widgetState.averageSpeedIntervalPref
        self.markerClickBehaviourPref = widgetState.markerClickBehaviourPref
        self.cachedNightMode = isNightMode()
        self.cachedMode = SideMarkerMode.markerModeByName(markerModePref.get())
        if let computerID = speedComputerId() {
            AverageSpeedComputerService.shared.addComputer(for: computerID)
        }
        
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
        let widgetState = MapMarkerSideWidgetState(customId: "", firstMarker: true, widgetParams: nil)
        self.widgetState = widgetState
        self.markerModePref = widgetState.mapMarkerModePref
        self.averageSpeedIntervalPref = widgetState.averageSpeedIntervalPref
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
    
    private func speedComputerId() -> String? {
        widgetState.customId ?? widgetType?.id
    }
    
    override func getWidgetState() -> OAWidgetState {
        return widgetState
    }
    
    func setCustomLatLon(_ customLatLon: CLLocation?) {
        self.customLatLon = customLatLon!
    }
    
    override func updateInfo() -> Bool {
        let routingHelper = OARoutingHelper.sharedInstance()!
        guard let marker = getMarker() else {
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

        let interval = widgetState.averageSpeedIntervalPref.get()
        var averageSpeed: Float?
        if let computerID = speedComputerId(), let computer = AverageSpeedComputerService.shared.getComputer(for: computerID) {
            averageSpeed = computer.getAverageSpeed(interval, skipLowSpeed: false)
        }
        
        if let speed = averageSpeed, !speed.isNaN, speed != 0 {
            let estimatedLeftSeconds = Int(Double(distance) / Double(speed))
            updateArrivalTime(estimatedLeftSeconds)
        } else {
            setText(Self.DASH, subtext: nil)
        }
    }

    private func updateArrivalTime(_ leftSeconds: Int) -> Bool {
        let toFindTime = Date().timeIntervalSince1970 + TimeInterval(leftSeconds)
        let dateFormatter = DateFormatter()
        let toFindDate = Date(timeIntervalSince1970: toFindTime)
        if !OAUtilities.is12HourTimeFormat() {
            dateFormatter.dateFormat = "HH:mm"
            setText(dateFormatter.string(from: toFindDate), subtext: nil)
        } else {
            dateFormatter.dateFormat = "h:mm"
            let timeStr = dateFormatter.string(from: toFindDate)
            dateFormatter.dateFormat = "a"
            let aStr = dateFormatter.string(from: toFindDate)
            setText(timeStr, subtext: aStr)
        }
        return true
    }
    
    private func updateIconIfNeeded(marker: OADestination, newMode: SideMarkerMode, modeChanged: Bool) {
        let colorChanged = marker.color != cachedMarkerColor || cachedNightMode != isNightMode()
        if colorChanged || modeChanged {
            let iconName = newMode.iconName
            cachedMarkerColor = marker.color
            cachedNightMode = isNightMode()
            if let cachedMarkerColor = cachedMarkerColor {
                setImage(UIImage.templateImageNamed(iconName), with: cachedMarkerColor, iconName: iconName)
            }
        }
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
        let destinatoins = mapMarkersHelper.sortedDestinationsWithoutParking()
        if let markers = destinatoins, !markers.isEmpty {
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
        let destinatoins = mapMarkersHelper.sortedDestinationsWithoutParking()
        if let markers = destinatoins, !markers.isEmpty {
            if widgetState.isFirstMarker() {
                return markers[0]
            } else if markers.count > 1 {
                return markers[1]
            }
        }
        return nil
    }
    
    override func isMetricSystemDepended() -> Bool {
        true
    }

    override func getSettingsData(_ appMode: OAApplicationMode,
                                  widgetConfigurationParams: [String: Any]?,
                                  isCreate: Bool) -> OATableDataModel? {
        let data = OATableDataModel()
        let section = data.createNewSection()
        section.headerText = localizedString("shared_string_settings")

        let showRow = section.createNewRow()
        showRow.cellType = OAValueTableViewCell.getIdentifier()
        showRow.key = "value_pref"
        showRow.title = localizedString("recording_context_menu_show")
        showRow.descr = localizedString("recording_context_menu_show")
        showRow.iconName = markerModePref.get(appMode) == SideMarkerMode.distance.name ? "widget_marker" : "widget_marker_eta"
        showRow.setObj(markerModePref, forKey: "pref")
        showRow.setObj(getModeTitle(markerModePref, appMode, widgetConfigurationParams: widgetConfigurationParams, isCreate: isCreate), forKey: "value")
        showRow.setObj(getPossibleValues(markerModePref, appMode), forKey: "possible_values")
        
        var shouldAddIntervalRow = true
        if !isCreate {
            shouldAddIntervalRow = markerModePref.get(appMode) == SideMarkerMode.estimatedArrivalTime.name
        } else {
            let firstMode = widgetConfigurationParams?["first_map_marker_mode"] as? String
            let secondMode = widgetConfigurationParams?["second_map_marker_mode"] as? String
            
            shouldAddIntervalRow = firstMode == SideMarkerMode.estimatedArrivalTime.name || secondMode == SideMarkerMode.estimatedArrivalTime.name
        }
       
        if shouldAddIntervalRow {
            let intervalRow = section.createNewRow()
            intervalRow.cellType = OAValueTableViewCell.getIdentifier()
            intervalRow.key = "value_pref"
            intervalRow.title = localizedString("shared_string_interval")
            intervalRow.descr = localizedString("shared_string_interval")
            intervalRow.iconName = "ic_small_time_interval"
            intervalRow.setObj(averageSpeedIntervalPref, forKey: "pref")
            intervalRow.setObj(getModeTitle(averageSpeedIntervalPref, appMode, widgetConfigurationParams: widgetConfigurationParams, isCreate: isCreate), forKey: "value")
            
            intervalRow.setObj(getPossibleValues(averageSpeedIntervalPref, appMode), forKey: "possible_values")
            intervalRow.setObj(localizedString("map_marker_interval_dialog_desc"), forKey: "footer")
        }

        let clickRow = section.createNewRow()
        clickRow.cellType = OAValueTableViewCell.getIdentifier()
        clickRow.key = "value_pref"
        clickRow.title = localizedString("click_on_widget")
        clickRow.descr = localizedString("click_on_widget")
        clickRow.iconName = "ic_custom_quick_action"
        clickRow.setObj(markerClickBehaviourPref, forKey: "pref")
        clickRow.setObj(getModeTitle(markerClickBehaviourPref, appMode, widgetConfigurationParams: widgetConfigurationParams, isCreate: isCreate), forKey: "value")
        clickRow.setObj(getPossibleValues(markerClickBehaviourPref, appMode), forKey: "possible_values")

        return data
    }

    private func getPossibleValues(_ pref: OACommonPreference, _ appMode: OAApplicationMode) -> [OATableRowData] {
        var rows = [OATableRowData]()
        if pref.key == markerModePref.key {
            for mode in SideMarkerMode.values {
                let row = OATableRowData()
                row.cellType = OASimpleTableViewCell.getIdentifier()
                row.setObj(mode.name, forKey: "value")
                row.title = mode.title
                rows.append(row)
            }
        } else if pref.key == markerClickBehaviourPref.key {
            for mode in MarkerClickBehaviour.values {
                let row = OATableRowData()
                row.cellType = OASimpleTableViewCell.getIdentifier()
                row.setObj(mode.name, forKey: "value")
                row.title = mode.title
                rows.append(row)
            }
        } else if pref.key == averageSpeedIntervalPref.key {
            let valuesRow = OATableRowData()
            valuesRow.key = "values"
            valuesRow.cellType = OASegmentSliderTableViewCell.getIdentifier()
            valuesRow.title = localizedString("shared_string_interval")
            valuesRow.setObj(MapMarkerSideWidgetState.availableIntervals, forKey: "values")
            rows.append(valuesRow)
        }
        return rows
    }

    private func getModeTitle(_ pref: OACommonPreference,
                              _ appMode: OAApplicationMode,
                              widgetConfigurationParams: [String: Any]?,
                              isCreate: Bool) -> String {
        if let prefStr = pref as? OACommonString {
            var currentValue = prefStr.defValue!
            if let widgetConfigurationParams,
               let key = widgetConfigurationParams.keys.first(where: { $0.hasPrefix(prefStr.key) }),
               let value = widgetConfigurationParams[key] as? String {
                currentValue = value
            } else if !isCreate{
                currentValue = prefStr.get(appMode)
            }
            if prefStr.key == "first_map_marker_mode" || prefStr.key == "second_map_marker_mode" {
                return SideMarkerMode.markerModeByName(currentValue)?.title ?? ""
            } else if prefStr.key == "first_map_marker_click_behaviour" || prefStr.key == "second_map_marker_click_behaviour" {
                return MarkerClickBehaviour.behaviorByName(currentValue)?.title ?? ""
            }
        } else if let prefLong = pref as? OACommonLong {
            if prefLong.key == "first_map_marker_interval" || prefLong.key == "second_map_marker_interval" {
                var currentValue = prefLong.defValue
            
                if let widgetConfigurationParams,
                   let key = widgetConfigurationParams.keys.first(where: { $0.hasPrefix(prefLong.key) }),
                   let value = widgetConfigurationParams[key] as? String,
                   let widgetValue = Int(value) {
                    currentValue = widgetValue
                } else if  !isCreate {
                    currentValue = prefLong.get(appMode)
                }
                
                return MapMarkerSideWidgetState.availableIntervals[currentValue] ?? ""
            }
        }
        return ""
    }
}
