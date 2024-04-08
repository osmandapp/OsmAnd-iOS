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
    
    static let routeManeuvers = WidgetGroup(title: localizedString("route_maneuvers"), descr: localizedString("route_maneuvers_desc"), iconName: "widget_lanes", docsUrl: docs_widget_route_maneuvers)
    static let navigationPoints = WidgetGroup(title: localizedString("navigation_points"), descr: localizedString("navigation_points_desc"), iconName: "widget_navigation", docsUrl: docs_widget_navigation_points)
    static let coordinatesWidget = WidgetGroup(title: localizedString("coordinates"), descr: localizedString("coordinates_widget_desc"), iconName: "widget_coordinates_longitude_east", docsUrl: "docs_widget_coordinates")
    static let mapMarkers = WidgetGroup(title: localizedString("map_markers"), descr: localizedString("map_markers_desc"), iconName: "widget_marker", docsUrl: docs_widget_markers)
    static let bearing = WidgetGroup(title: localizedString("shared_string_bearing"), descr: localizedString("bearing_desc"), iconName: "widget_relative_bearing", docsUrl: docs_widget_bearing)
    static let tripRecording = WidgetGroup(title: localizedString("record_plugin_name"), iconName: "widget_trip_recording", docsUrl: docs_widget_trip_recording)
    static let developerOptions = WidgetGroup(title: localizedString("developer_widgets"), iconName: "widget_developer")
    static let altitude = WidgetGroup(title: localizedString("altitude"), descr: localizedString("map_widget_altitude_desc"), iconName: "widget_altitude")
    static let weather = WidgetGroup(title: localizedString("shared_string_weather"), descr: localizedString("weather_widget_group_desc"), iconName: "widget_weather_umbrella")
    static let sunriseSunset = WidgetGroup(title: localizedString("map_widget_sun_position"), descr: localizedString("map_widget_group_sunrise_sunset_desc"), iconName: "widget_sunset")
    static let externalSensors = WidgetGroup(title: localizedString("external_sensors_plugin_name"), descr: localizedString("external_sensors_plugin_description"), iconName: "widget_sensor_external")
    static let glide = WidgetGroup(title: localizedString("map_widget_group_glide_ratio"), descr: localizedString("map_widget_group_glide_desc"), iconName: "widget_glide_ratio_to_target")
    
    static let values = [routeManeuvers, navigationPoints, coordinatesWidget, mapMarkers, bearing, tripRecording, developerOptions, altitude, weather, sunriseSunset, externalSensors]
    
    let title: String
    let descr: String?
    let iconName: String
    let docsUrl: String?
    
    private init(title: String, descr: String? = nil, iconName: String, docsUrl: String? = nil) {
        self.title = title
        self.descr = descr
        self.iconName = iconName
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
        case .externalSensors:
            return WidgetGroup.getPartOfPluginDesc(plugin: OAExternalSensorsPlugin.self)
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
    
    override func isEqual(_ object: Any?) -> Bool {
        if object == nil {
            return false
        }
        
        if let object = object as? WidgetGroup
        {
            return title == object.title
                && object.descr == descr
                && object.iconName == iconName
                && object.docsUrl == docsUrl
        }
        return false
    }
    
    class func getPartOfPluginDesc(plugin: AnyClass) -> String? {
        let plugin = OAPluginsHelper.getPlugin(plugin)
        if let plugin {
            return String(format: localizedString("widget_secondary_desc_part_of"), plugin.getName())
        }
        return nil
    }
}
