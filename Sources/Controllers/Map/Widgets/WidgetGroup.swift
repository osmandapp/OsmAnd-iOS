//
//  WidgetGroup.swift
//  OsmAnd Maps
//
//  Created by Paul on 28.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAWidgetGroup)
@objcMembers
class WidgetGroup: NSObject {
    
    static let routeManeuvers = WidgetGroup(title: localizedString("route_maneuvers"), descr: localizedString("route_maneuvers_desc"), dayIconName: "widget_lanes_day", nightIconName: "widget_lanes_night", docsUrl: docs_widget_route_maneuvers)
    static let navigationPoints = WidgetGroup(title: localizedString("navigation_points"), descr: localizedString("navigation_points_desc"), dayIconName: "widget_navigation_day", nightIconName: "widget_navigation_night", docsUrl: docs_widget_navigation_points)
    static let coordinatesWidget = WidgetGroup(title: localizedString("coordinates_widget_current_location"), descr: localizedString("coordinates_widget_desc"), dayIconName: "widget_coordinates_longitude_west_day", nightIconName: "widget_coordinates_longitude_west_night", docsUrl: "docs_widget_coordinates")
    static let mapMarkers = WidgetGroup(title: localizedString("map_markers"), descr: localizedString("map_markers_desc"), dayIconName: "widget_marker_day", nightIconName: "widget_marker_night", docsUrl: docs_widget_markers)
    static let bearing = WidgetGroup(title: localizedString("shared_string_bearing"), descr: localizedString("bearing_desc"), dayIconName: "widget_relative_bearing_day", nightIconName: "widget_relative_bearing_night", docsUrl: docs_widget_bearing)
    static let tripRecording = WidgetGroup(title: localizedString("record_plugin_name"), dayIconName: "widget_trip_recording_day", nightIconName: "widget_trip_recording_night", docsUrl: docs_widget_trip_recording)
    static let developerOptions = WidgetGroup(title: localizedString("developer_widgets"), dayIconName: "widget_developer_day", nightIconName: "widget_developer_night")
    static let altitude = WidgetGroup(title: localizedString("altitude"), descr: localizedString("map_widget_altitude_desc"), dayIconName: "widget_altitude_day", nightIconName: "widget_altitude_night")
    static let weather = WidgetGroup(title: localizedString("shared_string_weather"), descr:localizedString("weather_widget_group_desc") , dayIconName: "widget_weather_umbrella_day", nightIconName: "widget_weather_umbrella_night")
    static let sunriseSunset = WidgetGroup(title: localizedString("map_widget_group_sunrise_sunset"), descr:localizedString("map_widget_group_sunrise_sunset_desc") , dayIconName: "widget_sunset_day", nightIconName: "widget_sunset_night")
//        ANT_PLUS(R.string.external_sensor_widgets, 0, R.drawable.widget_sensor_external_day, R.drawable.widget_sensor_external_night, 0),
    //        AUDIO_VIDEO_NOTES(R.string.map_widget_av_notes, R.string.audio_video_notes_desc, R.drawable.widget_av_photo_day, R.drawable.widget_av_photo_night, R.string.docs_widget_av_notes),
    
    static let values = [routeManeuvers, navigationPoints, coordinatesWidget, mapMarkers, bearing, tripRecording, developerOptions, altitude, weather, sunriseSunset]
    
    let title: String
    let descr: String?
    let dayIconName: String
    let nightIconName: String
    let docsUrl: String?
    
    private init(title: String, descr: String? = nil, dayIconName: String, nightIconName: String, docsUrl: String? = nil) {
        self.title = title
        self.descr = descr
        self.dayIconName = dayIconName
        self.nightIconName = nightIconName
        self.docsUrl = docsUrl
    }
    
    override init() {
        fatalError("Widget group initialization is not permitted")
    }
    
    @objc func getWidgets() -> [WidgetType] {
        var widgets = [WidgetType]()
        for widget in WidgetType.values {
            if self == widget.group {
                widgets.append(widget)
            }
        }
        return widgets
    }
    
    @objc func getWidgetsIds() -> [String] {
        var widgetsIds = [String]()
        for widget in getWidgets() {
            widgetsIds.append(widget.id)
        }
        return widgetsIds
    }
    
    
    @objc func getMainWidget() -> WidgetType? {
        switch self {
        case .bearing:
            return WidgetType.relativeBearing
        case .tripRecording:
            return WidgetType.tripRecordingDistance
//        case AUDIO_VIDEO_NOTES():
//            return WidgetType.AV_NOTES_ON_REQUEST;
        default:
            return nil
        }
    }
    
    
    @objc func getIconName(nightMode: Bool) -> String {
        return nightMode ? nightIconName : dayIconName;
    }
    
    @objc func getSecondaryDescription() -> String? {
        switch self {
        case .bearing:
            let configureProfile = localizedString("configure_profile")
            let generalSettings = localizedString("general_settings_2")
            let angularUnit = localizedString("angular_measeurement")
            return String(format: localizedString("bearing_secondary_desc"), configureProfile, generalSettings, angularUnit)
        case .tripRecording:
            return WidgetGroup.getPartOfPluginDesc(plugin: OAMonitoringPlugin.self)
        case .coordinatesWidget:
            let configureProfile = localizedString("configure_profile")
            let generalSettings = localizedString("general_settings_2")
            let coordinatesFormat = localizedString("coordinates_format")
            return String(format: "coordinates_widget_secondary_desc", configureProfile,
                          generalSettings, coordinatesFormat)
        case .developerOptions:
            return WidgetGroup.getPartOfPluginDesc(plugin: OAOsmandDevelopmentPlugin.self)
        case .weather:
            return WidgetGroup.getPartOfPluginDesc(plugin: OAWeatherPlugin.self)
        default:
            return nil
        }
//        else if (this == AUDIO_VIDEO_NOTES) {
//            return getPartOfPluginDesc(context, AudioVideoNotesPlugin.class);
//        }
//        else if (this == ANT_PLUS) {
//            return getPartOfPluginDesc(context, AntPlusPlugin.class);
//        }
    }
    
    @objc func getSecondaryIconName() -> String {
        if self == .bearing || self == .coordinatesWidget {
            return "ic_action_help"
        } else if (self == .tripRecording /*|| self == AUDIO_VIDEO_NOTES*/ || self == .developerOptions
                   || self == .weather /*|| this == ANT_PLUS*/) {
            return "ic_extension_dark"
        }
        return ""
    }
    
    @objc func getOrder() -> Int {
        getWidgets().first!.ordinal;
    }
    
    class func getPartOfPluginDesc(plugin: AnyClass) -> String? {
        let plugin = OAPlugin.getPlugin(plugin)
        if let plugin {
            return String(format: localizedString("widget_secondary_desc_part_of"), plugin.getName())
        }
        return nil
    }
}
