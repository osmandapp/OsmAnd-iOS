//
//  WidgetType.swift
//  OsmAnd Maps
//
//  Created by Paul on 28.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAWidgetType)
@objcMembers
class WidgetType: NSObject {

    static let complexWidgetIds: [String] = [WidgetType.elevationProfile.id,
                                             WidgetType.coordinatesMapCenter.id,
                                             WidgetType.coordinatesCurrentLocation.id,
                                             WidgetType.streetName.id,
                                             WidgetType.markersTopBar.id,
                                             WidgetType.lanes.id]

    let ordinal: Int
    let id: String
    let title: String
    let descr: String
    let iconName: String
    let disabledIconName: String?
    let docsUrl: String?
    let group: WidgetGroup?
    let defaultPanel: WidgetsPanel
    let special: Bool

    var isAllowed: Bool {
        if self == .altitudeMapCenter {
            if let plugin = OAPlugin.getEnabledPlugin(OASRTMPlugin.self) as? OASRTMPlugin {
                return plugin.is3DMapsEnabled()
            }
        }
        return true;
    }

    private init(ordinal: Int, id: String, title: String, descr: String, iconName: String, disabledIconName: String? = nil, docsUrl: String? = nil, group: WidgetGroup? = nil, defaultPanel: WidgetsPanel, special: Bool = false) {
        self.ordinal = ordinal
        self.id = id
        self.title = title
        self.descr = descr
        self.iconName = iconName
        self.disabledIconName = disabledIconName
        self.docsUrl = docsUrl
        self.group = group
        self.defaultPanel = defaultPanel
        self.special = special
    }
    
    static func isComplexWidget(_ widgetId: String) -> Bool {
        Self.complexWidgetIds.contains(widgetId.contains(MapWidgetInfo.DELIMITER) ? widgetId.substring(to: widgetId.find(MapWidgetInfo.DELIMITER)) : widgetId)
    }

    func getGroup() -> WidgetGroup? {
        if (group == .altitude) {
            let plugin: OASRTMPlugin? = OAPlugin.getEnabledPlugin(OASRTMPlugin.self) as? OASRTMPlugin
            if plugin == nil || !(plugin?.is3DMapsEnabled() ?? false) {
                return nil
            }
        }
        return group
    }

    func getGroupDescription() -> String {
        if self == .magneticBearing {
            return localizedString("magnetic_bearing_widget_desc")
        }
//        else if (self == AV_NOTES_ON_REQUEST) {
//            return R.string.av_notes_choose_action_widget_desc;
//        }
        return "";
    }

    func getSecondaryDescription() -> String? {
        if self == .coordinatesCurrentLocation || self == .coordinatesMapCenter {
            let configureProfile = localizedString("configure_profile")
            let generalSettings = localizedString("general_settings_2")
            let coordinatesFormat = localizedString("coordinates_format")
            return String(format: localizedString("coordinates_widget_secondary_desc"), configureProfile, generalSettings, coordinatesFormat)
        } else if self == .devFps {
            return WidgetGroup.getPartOfPluginDesc(plugin: OAOsmandDevelopmentPlugin.self)
        } else if self == .mapillary {
            return WidgetGroup.getPartOfPluginDesc(plugin: OAMapillaryPlugin.self)
        } else if self == .parking {
            return WidgetGroup.getPartOfPluginDesc(plugin: OAParkingPositionPlugin.self)
        } else if let group {
            if group == .weather {
                return localizedString("weather_widgets_secondary_desc")
            } else {
                return group.getSecondaryDescription()
            }
        }
        return nil;
    }

    func getSecondaryIconName() -> String? {
        if (self == .coordinatesCurrentLocation || self == .coordinatesMapCenter) {
            return "ic_action_help"
        } else if (self == .devFps || self == .mapillary || self == .parking) {
            return "ic_extension_dark"
        } else if let group {
            return group.getSecondaryIconName()
        }
        return nil
    }

    func isPurchased() -> Bool {
        if (WidgetType.getProWidgets().contains(where: { $0 == self } )) {
            return OAIAPHelper.isOsmAndProAvailable()
        }
        return true
    }

    func getDefaultOrder() -> Int {
        return defaultPanel.getOriginalWidgetOrder(widgetId: id);
    }

    func getPanel() -> WidgetsPanel {
        return getPanel(id, appMode: OAAppSettings.sharedManager().applicationMode.get());
    }

    func getPanel(_ widgetId: String, appMode: OAApplicationMode) -> WidgetsPanel {
        var widgetsPanel: WidgetsPanel? = Self.findWidgetPanel(widgetId: widgetId, mode: appMode)
        if let widgetsPanel {
            return widgetsPanel
        }
        return defaultPanel
    }

    static func findWidgetPanel(widgetId: String, mode: OAApplicationMode? = nil) -> WidgetsPanel? {
        let settings: OAAppSettings = OAAppSettings.sharedManager()
        let appMode: OAApplicationMode = mode ?? settings.applicationMode.get()
        var setPanels: [WidgetsPanel] = []
        var unsetPanels: [WidgetsPanel] = []

        for panel in [WidgetsPanel.leftPanel, WidgetsPanel.topPanel, WidgetsPanel.rightPanel, WidgetsPanel.bottomPanel] {
            if panel.getOrderPreference().isSet(for: appMode) {
                setPanels.append(panel)
            } else {
                unsetPanels.append(panel)
            }
        }

        for panel in setPanels where panel.contains(widgetId: widgetId, appMode: appMode) {
            return panel
        }

        for panel in unsetPanels where panel.contains(widgetId: widgetId, appMode: appMode) {
            return panel
        }

        return nil
    }

    static func getById(_ id: String) -> WidgetType? {
        for type in values {
            let defaultId = getDefaultWidgetId(id)
            if defaultId == type.id {
                return type
            }
        }
        return nil
    }

    static func getProWidgets() -> [WidgetType] {
        return [.elevationProfile];
    }

    static func isOriginalWidget(_ id: String) -> Bool {
        return id == getDefaultWidgetId(id)
    }

    static func getDefaultWidgetId(_ id: String) -> String {
        let range = id.range(of: MapWidgetInfo.DELIMITER)
        if let range {
            let index = id.distance(from: id.startIndex, to: range.lowerBound)
            return id.substring(to: index)
        }
        return id
    }

    static func getDuplicateWidgetId(widgetType: WidgetType) -> String {
        return getDuplicateWidgetId(widgetType.id)
    }

    static func getDuplicateWidgetId(_ widgetId: String) -> String {
        return getDefaultWidgetId(widgetId) + MapWidgetInfo.DELIMITER + String(UInt64(Date.now.timeIntervalSince1970 * 1000))
    }
}

extension WidgetType {
    // Left panel
    static let nextTurn = WidgetType(ordinal: 1, id: "next_turn", title: localizedString("map_widget_next_turn"), descr: localizedString("next_turn_widget_desc"), iconName: "widget_next_turn", group: WidgetGroup.routeManeuvers, defaultPanel: WidgetsPanel.leftPanel)
    
    static let smallNextTurn = WidgetType(ordinal: 2, id: "next_turn_small", title: localizedString("map_widget_next_turn_small"), descr: localizedString("next_turn_widget_desc"), iconName: "widget_next_turn_small", group: WidgetGroup.routeManeuvers, defaultPanel: WidgetsPanel.leftPanel)
    static let secondNextTurn = WidgetType(ordinal: 3, id: "next_next_turn", title: localizedString("map_widget_next_next_turn"), descr: localizedString("second_next_turn_widget_desc"), iconName: "widget_second_next_turn", group: WidgetGroup.routeManeuvers, defaultPanel: WidgetsPanel.leftPanel)

    // Top panel
    static let coordinatesMapCenter = WidgetType(ordinal: 4, id: "coordinates_map_center", title: localizedString("coordinates_widget_map_center"), descr: localizedString("coordinates_widget_map_center_desc"), iconName: "widget_coordinates_map_center", docsUrl:docs_widget_coordinates, group: .coordinatesWidget, defaultPanel: .topPanel)
    static let coordinatesCurrentLocation = WidgetType(ordinal: 5, id: "coordinates_current_location", title: localizedString("coordinates_widget_current_location"), descr: localizedString("coordinates_widget_current_location_desc"), iconName: "widget_coordinates_location", docsUrl:docs_widget_coordinates, group: .coordinatesWidget, defaultPanel: .topPanel)
    static let streetName = WidgetType(ordinal: 6, id: "street_name", title: localizedString("map_widget_top_text"), descr: localizedString("street_name_widget_desc"), iconName: "widget_street_name", docsUrl:docs_widget_street_name, defaultPanel: .topPanel)
    static let markersTopBar = WidgetType(ordinal: 7, id: "map_markers_top", title: localizedString("map_markers_bar"), descr: localizedString("map_markers_bar_widget_desc"), iconName: "widget_markers_topbar", docsUrl:docs_widget_markers, defaultPanel: .topPanel)
    static let lanes = WidgetType(ordinal: 8, id: "lanes", title: localizedString("show_lanes"), descr: localizedString("lanes_widgets_desc"), iconName: "widget_lanes", docsUrl:docs_widget_lanes, defaultPanel: .topPanel, special: true)

    // Right panel
    static let distanceToDestination = WidgetType(ordinal: 9, id: "distance", title: localizedString("map_widget_distance_to_destination"), descr: localizedString("distance_to_destination_widget_desc"), iconName: "widget_target", group: .navigationPoints, defaultPanel: .rightPanel)
    static let intermediateDestination = WidgetType(ordinal: 10, id: "intermediate_distance", title: localizedString("map_widget_distance_to_intermediate"), descr: localizedString("distance_to_intermediate_widget_desc"), iconName: "widget_intermediate", group: .navigationPoints, defaultPanel: .rightPanel)
    static let timeToIntermediate = WidgetType(ordinal: 11, id: "time_to_intermediate", title: localizedString("map_widget_time_to_intermediate"), descr: localizedString("time_to_intermediate_widget_desc"), iconName: "widget_intermediate_time", group: .navigationPoints, defaultPanel: .rightPanel)
    static let timeToDestination = WidgetType(ordinal: 12, id: "time_to_destination", title: localizedString("map_widget_time_to_destination"), descr: localizedString("time_to_destination_widget_desc"), iconName: "widget_time_to_distance", group: .navigationPoints, defaultPanel: .rightPanel)

    static let sideMarker1 = WidgetType(ordinal: 13, id: "map_marker_1st", title: localizedString("map_marker_1st"), descr: localizedString("first_marker_widget_desc"), iconName: "widget_marker", group: .mapMarkers, defaultPanel: .rightPanel)
    static let sideMarker2 = WidgetType(ordinal: 14, id: "map_marker_2nd", title: localizedString("map_marker_2nd"), descr: localizedString("second_marker_widget_desc"), iconName: "widget_marker", group: .mapMarkers, defaultPanel: .rightPanel)

    static let relativeBearing = WidgetType(ordinal: 15, id: "relative_bearing", title: localizedString("map_widget_bearing"), descr: localizedString("relative_bearing_widget_desc"), iconName: "widget_relative_bearing", group: .bearing, defaultPanel: .rightPanel)
    static let magneticBearing = WidgetType(ordinal: 16, id: "magnetic_bearing", title: localizedString("map_widget_magnetic_bearing"), descr: localizedString("magnetic_bearing_widget_desc"), iconName: "widget_bearing", group: .bearing, defaultPanel: .rightPanel)
    static let trueBearing = WidgetType(ordinal: 17, id: "true_bearing", title: localizedString("map_widget_true_bearing"), descr: localizedString("true_bearing_wdiget_desc"), iconName: "widget_true_bearing", group: .bearing, defaultPanel: .rightPanel)
    static let currentSpeed = WidgetType(ordinal: 18, id: "speed", title: localizedString("map_widget_current_speed"), descr: localizedString("current_speed_widget_desc"), iconName: "widget_speed", docsUrl:docs_widget_current_speed, defaultPanel: .rightPanel)
    static let averageSpeed = WidgetType(ordinal: 19, id: "average_speed", title: localizedString("map_widget_average_speed"), descr: localizedString("average_speed_widget_desc"), iconName: "widget_average_speed", defaultPanel: .rightPanel)
    static let maxSpeed = WidgetType(ordinal: 20, id: "max_speed", title: localizedString("map_widget_max_speed"), descr: localizedString("max_speed_widget_desc"), iconName: "widget_max_speed", docsUrl:docs_widget_max_speed, defaultPanel: .rightPanel)
    static let altitudeMyLocation = WidgetType(ordinal: 21, id: "altitude", title: localizedString("map_widget_altitude_current_location"), descr: localizedString("altitude_widget_desc"), iconName: "widget_altitude_location", docsUrl:docs_widget_altitude, group: .altitude, defaultPanel: .rightPanel)
    static let altitudeMapCenter = WidgetType(ordinal: 22, id: "altitude_map_center", title: localizedString("map_widget_altitude_map_center"), descr: localizedString("map_widget_altitude_map_center_desc"), iconName: "widget_altitude_map_center", group: .altitude, defaultPanel: .rightPanel)
    static let gpsInfo = WidgetType(ordinal: 23, id: "gps_info", title: localizedString("map_widget_gps_info"), descr: localizedString("gps_info_widget_desc"), iconName: "widget_gps_info", docsUrl:docs_widget_gps_info, defaultPanel: .rightPanel)

    static let tripRecordingDistance = WidgetType(ordinal: 24, id: "monitoring", title: localizedString("map_widget_trip_recording_distance"), descr: localizedString("trip_recording_distance_widget_desc"), iconName: "widget_trip_recording", group: .tripRecording, defaultPanel: .rightPanel)
    static let tripRecordingTime = WidgetType(ordinal: 25, id: "trip_recording_time", title: localizedString("map_widget_trip_recording_duration"), descr: localizedString("trip_recording_duration_widget_desc"), iconName: "widget_track_recording_duration", group: .tripRecording, defaultPanel: .rightPanel)
    static let tripRecordingUphill = WidgetType(ordinal: 26, id: "trip_recording_uphill", title: localizedString("map_widget_trip_recording_uphill"), descr: localizedString("trip_recording_uphill_widget_desc"), iconName: "widget_track_recording_uphill", group: .tripRecording, defaultPanel: .rightPanel)
    static let tripRecordingDownhill = WidgetType(ordinal: 27, id: "trip_recording_downhill", title: localizedString("map_widget_trip_recording_downhill"), descr: localizedString("trip_recording_downhill_widget_desc"), iconName: "widget_track_recording_downhill", group: .tripRecording, defaultPanel: .rightPanel)

    static let currentTime = WidgetType(ordinal: 28, id: "plain_time", title: localizedString("map_widget_plain_time"), descr: localizedString("current_time_widget_desc"), iconName: "widget_time", docsUrl:docs_widget_current_time, defaultPanel: .rightPanel)
    static let battery = WidgetType(ordinal: 29, id: "battery", title: localizedString("map_widget_battery"), descr: localizedString("battery_widget_desc"), iconName: "widget_battery", docsUrl:docs_widget_battery, defaultPanel: .rightPanel)

    static let radiusRuler = WidgetType(ordinal: 30, id: "ruler", title: localizedString("map_widget_ruler_control"), descr: localizedString("radius_rules_widget_desc"), iconName: "widget_ruler_circle", docsUrl:docs_widget_radius_ruler, defaultPanel: .rightPanel)

    static let devFps = WidgetType(ordinal: 31, id: "fps", title: localizedString("map_widget_rendering_fps"), descr: localizedString("map_widget_rendering_fps_desc"), iconName: "widget_fps", docsUrl:docs_widget_fps, group: .developerOptions, defaultPanel: .rightPanel)
    static let devCameraTilt = WidgetType(ordinal: 32, id: "dev_camera_tilt", title: localizedString("map_widget_camera_tilt"), descr: localizedString("map_widget_camera_tilt_desc"), iconName: "widget_developer_camera_tilt", group: .developerOptions, defaultPanel: .rightPanel)
    static let devCameraDistance = WidgetType(ordinal: 33, id: "dev_camera_distance", title: localizedString("map_widget_camera_distance"), descr: localizedString("map_widget_camera_distance_desc"), iconName: "widget_developer_camera_distance", group: .developerOptions, defaultPanel: .rightPanel)
    static let devZoomLevel = WidgetType(ordinal: 34, id: "dev_zoom_level", title: localizedString("map_widget_zoom_level"), descr: localizedString("map_widget_zoom_level_desc"), iconName: "widget_developer_map_zoom", group: .developerOptions, defaultPanel: .rightPanel)
    static let devTargetDistance = WidgetType(ordinal: 35, id: "dev_target_distance", title: localizedString("map_widget_target_distance"), descr: localizedString("map_widget_target_distance_desc"), iconName: "widget_developer_target_distance", group: .developerOptions, defaultPanel: .rightPanel)

//        static let AV_NOTES_ON_REQUEST = WidgetType(ordinal: 1, id: "av_notes_on_request", title: localizedString("av_def_action_choose"), descr: localizedString("av_notes_choose_action_widget_desc"), dayIconName: "widget_av_photo_day", nightIconName: "widget_av_photo_night", docsUrl:0 group: WidgetGroup.AUDIO_VIDEO_NOTES, defaultPanel: RIGHT)
//        static let AV_NOTES_RECORD_AUDIO = WidgetType(ordinal: 1, id: "av_notes_record_audio", title: localizedString("av_def_action_audio"), descr: localizedString("av_notes_audio_widget_desc"), dayIconName: "widget_av_audio_day", nightIconName: "widget_av_audio_night", docsUrl:0 group: WidgetGroup.AUDIO_VIDEO_NOTES, defaultPanel: RIGHT)
//        static let AV_NOTES_RECORD_VIDEO = WidgetType(ordinal: 1, id: "av_notes_record_video", title: localizedString("av_def_action_video"), descr: localizedString("av_notes_video_widget_desc"), dayIconName: "widget_av_video_day", nightIconName: "widget_av_video_night", docsUrl:0 group: WidgetGroup.AUDIO_VIDEO_NOTES, defaultPanel: RIGHT)
//        static let AV_NOTES_TAKE_PHOTO = WidgetType(ordinal: 1, id: "av_notes_take_photo", title: localizedString("av_def_action_picture"), descr: localizedString("av_notes_photo_widget_desc"), dayIconName: "widget_av_photo_day", nightIconName: "widget_av_photo_night", docsUrl:0 group: WidgetGroup.AUDIO_VIDEO_NOTES, defaultPanel: RIGHT)

    static let mapillary = WidgetType(ordinal: 36, id: "mapillary", title: localizedString("mapillary"), descr: localizedString("mapillary_widget_desc"), iconName: "widget_mapillary", docsUrl:docs_widget_mapillary, defaultPanel: .rightPanel)

    static let parking = WidgetType(ordinal: 37, id: "parking", title: localizedString("map_widget_parking"), descr: localizedString("parking_widget_desc"), iconName: "widget_parking", docsUrl:docs_widget_parking, defaultPanel: .rightPanel)

//        static let AIDL_WIDGET = WidgetType(ordinal: 1, id: "aidl_widget", title: localizedString("map_widget_parking"), descr: localizedString("parking_widget_desc"), dayIconName: "widget_parking_day", nightIconName: "widget_parking_night", docsUrl:R.string.docs_widget_parking group: null, defaultPanel: RIGHT)
//
//        static let ANT_HEART_RATE = WidgetType(ordinal: 1, id: "ant_heart_rate", title: localizedString("map_widget_ant_heart_rate"), descr: localizedString("map_widget_ant_heart_rate_desc"), dayIconName: "widget_sensor_heart_rate_day", nightIconName: "widget_sensor_heart_rate_night", docsUrl:0 group: ANT_PLUS, defaultPanel: RIGHT)
//        static let ANT_BICYCLE_POWER = WidgetType(ordinal: 1, id: "ant_bicycle_power", title: localizedString("map_widget_ant_bicycle_power"), descr: localizedString("map_widget_ant_bicycle_power_desc"), dayIconName: "widget_sensor_bicycle_power_day", nightIconName: "widget_sensor_bicycle_power_night", docsUrl:0 group: ANT_PLUS, defaultPanel: RIGHT)
//        static let ANT_BICYCLE_CADENCE = WidgetType(ordinal: 1, id: "ant_bicycle_cadence", title: localizedString("map_widget_ant_bicycle_cadence"), descr: localizedString("map_widget_ant_bicycle_cadence_desc"), dayIconName: "widget_sensor_cadence_day", nightIconName: "widget_sensor_cadence_night", docsUrl:0 group: ANT_PLUS, defaultPanel: RIGHT)
//        static let ANT_BICYCLE_SPEED = WidgetType(ordinal: 1, id: "ant_bicycle_speed", title: localizedString("map_widget_ant_bicycle_speed"), descr: localizedString("map_widget_ant_bicycle_speed_desc"), dayIconName: "widget_sensor_speed_day", nightIconName: "widget_sensor_speed_night", docsUrl:0 group: ANT_PLUS, defaultPanel: RIGHT)
//        static let ANT_BICYCLE_DISTANCE = WidgetType(ordinal: 1, id: "ant_bicycle_distance", title: localizedString("map_widget_ant_bicycle_dist"), descr: localizedString("map_widget_ant_bicycle_dist_desc"), dayIconName: "widget_sensor_distance_day", nightIconName: "widget_sensor_distance_night", docsUrl:0 group: ANT_PLUS, defaultPanel: RIGHT)

    static let weatherTemperatureWidget = WidgetType(ordinal: 38, id: "weather_temp", title: localizedString("map_settings_weather_temp"), descr: localizedString("temperature_widget_desc"), iconName: "widget_weather_temperature", group: .weather, defaultPanel: .rightPanel)
    static let weatherPrecipitationWidget = WidgetType(ordinal: 39, id: "weather_precip", title: localizedString("map_settings_weather_precip"), descr: localizedString("precipitation_widget_desc"), iconName: "widget_weather_precipitation", group: .weather, defaultPanel: .rightPanel)
    static let weatherWindWidget = WidgetType(ordinal: 40, id: "weather_wind", title: localizedString("map_settings_weather_wind"), descr: localizedString("wind_widget_desc"), iconName: "widget_weather_wind", group: .weather, defaultPanel: .rightPanel)
    static let weatherCloudsWidget = WidgetType(ordinal: 41, id: "weather_cloud", title: localizedString("map_settings_weather_cloud"), descr: localizedString("clouds_widget_desc"), iconName: "widget_weather_clouds", group: .weather, defaultPanel: .rightPanel)
    static let weatherAirPressureWidget = WidgetType(ordinal: 42, id: "weather_pressure", title: localizedString("map_settings_weather_pressure"), descr: localizedString("air_pressure_widget_desc"), iconName: "widget_weather_air_pressure", group: .weather, defaultPanel: .rightPanel)
    
    static let sunPosition = WidgetType(ordinal: 43,
                                        id: "day_night_mode_sun_position",
                                        title: localizedString("map_widget_sun_position"),
                                        descr: localizedString("map_widget_sun_position_desc"),
                                        iconName: "widget_sunset",
                                        group: .sunriseSunset,
                                        defaultPanel: .rightPanel)

    static let sunrise = WidgetType(ordinal: 44, id: "day_night_mode_sunrise", title: localizedString("map_widget_sunrise"), descr: localizedString("map_widget_sunrise_desc"), iconName: "widget_sunrise", group: .sunriseSunset, defaultPanel: .rightPanel)
    static let sunset = WidgetType(ordinal: 45, id: "day_night_mode_sunset", title: localizedString("map_widget_sunset"), descr: localizedString("map_widget_sunset_desc"), iconName: "widget_sunset", group: .sunriseSunset, defaultPanel: .rightPanel)

    // Bottom panel
    static let elevationProfile = WidgetType(ordinal: 46, id: "elevation_profile", title: localizedString("elevation_profile"), descr: localizedString("elevation_profile_widget_desc"), iconName: "widget_route_elevation", defaultPanel: .bottomPanel)
    
    // External sensors
    static let heartRate = WidgetType(ordinal: 47, id: "heartRate", title: localizedString("map_widget_ant_heart_rate"), descr: localizedString("map_widget_ant_heart_rate_desc"), iconName: "widget_sensor_heart_rate", disabledIconName: "ic_custom_sensor_heart_rate_outlined", group: .externalSensors, defaultPanel: .rightPanel)
    
    static let bicycleCadence = WidgetType(ordinal: 48, id: "bicycleCadence", title: localizedString("map_widget_ant_bicycle_cadence"), descr: localizedString("map_widget_ant_bicycle_cadence_desc"), iconName: "widget_sensor_cadence", disabledIconName: "ic_custom_sensor_cadence_outlined", group: .externalSensors, defaultPanel: .rightPanel)
    
    static let bicycleDistance = WidgetType(ordinal: 49, id: "bicycleDistance", title: localizedString("map_widget_ant_bicycle_dist"), descr: localizedString("map_widget_ant_bicycle_dist_desc"), iconName: "widget_sensor_distance", disabledIconName: "ic_custom_sensor_distance_outlined", group: .externalSensors, defaultPanel: .rightPanel)
    
    static let bicycleSpeed = WidgetType(ordinal: 50, id: "bicycleSpeed", title: localizedString("map_widget_ant_bicycle_speed"), descr: localizedString("map_widget_ant_bicycle_speed_desc"), iconName: "widget_sensor_speed", disabledIconName: "ic_custom_sensor_speed_outlined", group: .externalSensors, defaultPanel: .rightPanel)
    
    static let temperature = WidgetType(ordinal: 51, id: "temperature", title: localizedString("shared_string_temperature"), descr: localizedString("sensor_temperature_desc"), iconName: "widget_weather_temperature", disabledIconName: "ic_custom_sensor_thermometer", group: .externalSensors, defaultPanel: .rightPanel)
        
    static let values = [nextTurn,
                         smallNextTurn,
                         secondNextTurn,
                         coordinatesMapCenter,
                         coordinatesCurrentLocation,
                         streetName,
                         markersTopBar,
                         lanes,
                         distanceToDestination,
                         intermediateDestination,
                         timeToIntermediate,
                         timeToDestination,
                         sideMarker1,
                         sideMarker2,
                         relativeBearing,
                         magneticBearing,
                         trueBearing,
                         currentSpeed,
                         averageSpeed,
                         maxSpeed,
                         altitudeMyLocation,
                         altitudeMapCenter,
                         gpsInfo,
                         tripRecordingDistance,
                         tripRecordingTime,
                         tripRecordingUphill,
                         tripRecordingDownhill,
                         currentTime,
                         battery,
                         radiusRuler,
                         devFps,
                         devCameraTilt,
                         devCameraDistance,
                         devZoomLevel,
                         devTargetDistance,

                     //        AV_NOTES_ON_REQUEST,
                     //        AV_NOTES_RECORD_AUDIO,
                     //        AV_NOTES_RECORD_VIDEO,
                     //        AV_NOTES_TAKE_PHOTO,
                         mapillary,
                         parking,
                     //        AIDL_WIDGET,
                     //
                     //        ANT_HEART_RATE,
                     //        ANT_BICYCLE_POWER,
                     //        ANT_BICYCLE_CADENCE,
                     //        ANT_BICYCLE_SPEED,
                     //        ANT_BICYCLE_DISTANCE,

                         weatherTemperatureWidget,
                         weatherPrecipitationWidget,
                         weatherWindWidget,
                         weatherCloudsWidget,
                         weatherAirPressureWidget,
                         sunPosition,
                         sunrise,
                         sunset,
                         // Bottom panel
                         elevationProfile,
                         // External sensors
                         heartRate,
                         bicycleCadence,
                         bicycleDistance,
                         bicycleSpeed,
                         temperature
    ]
}
