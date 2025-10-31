//
//  GpxAppearanceInfo.swift
//  OsmAnd
//
//  Created by Max Kojin on 24/10/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class GpxAppearanceInfo: NSObject {
    
    static let TAG_COLOR = "color"
    static let TAG_WIDTH = "width"
    static let TAG_SHOW_ARROWS = "show_arrows"
    static let TAG_START_FINISH = "show_start_finish"
    static let TAG_SPLIT_TYPE = "split_type"
    static let TAG_SPLIT_INTERVAL = "split_interval"
    static let TAG_COLORING_TYPE = "coloring_type"
    static let TAG_COLOR_PALETTE = "color_palette"
    static let TAG_LINE_3D_VISUALIZATION_BY_TYPE = "line_3d_visualization_by_type"
    static let TAG_LINE_3D_VISUALIZATION_WALL_COLOR_TYPE = "line_3d_visualization_wall_color_type"
    static let TAG_LINE_3D_VISUALIZATION_POSITION_TYPE = "line_3d_visualization_position_type"
    static let TAG_VERTICAL_EXAGGERATION_SCALE = "vertical_exaggeration_scale"
    static let TAG_ELEVATION_METERS = "elevation_meters"
    static let TAG_TIME_SPAN = "time_span"
    static let TAG_WPT_POINTS = "wpt_points"
    static let TAG_TOTAL_DISTANCE = "total_distance"
    static let TAG_GRADIENT_SCALE_TYPE = "gradient_scale_type"
    static let TAG_SMOOTHING_THRESHOLD = "smoothing_threshold"
    static let TAG_MIN_FILTER_SPEED = "min_filter_speed"
    static let TAG_MAX_FILTER_SPEED = "max_filter_speed"
    static let TAG_MIN_FILTER_ALTITUDE = "min_filter_altitude"
    static let TAG_MAX_FILTER_ALTITUDE = "max_filter_altitude"
    static let TAG_MAX_FILTER_HDOP = "max_filter_hdop"
    static let TAG_IS_JOIN_SEGMENTS = "is_join_segments"
    
    static let gpxAppearanceTags: Set<String> = Set([
        TAG_COLOR,
        TAG_WIDTH,
        TAG_SHOW_ARROWS,
        TAG_START_FINISH,
        TAG_SPLIT_TYPE,
        TAG_SPLIT_INTERVAL,
        TAG_COLORING_TYPE,
        TAG_COLOR_PALETTE,
        TAG_LINE_3D_VISUALIZATION_BY_TYPE,
        TAG_LINE_3D_VISUALIZATION_WALL_COLOR_TYPE,
        TAG_LINE_3D_VISUALIZATION_POSITION_TYPE,
        TAG_VERTICAL_EXAGGERATION_SCALE,
        TAG_ELEVATION_METERS,
        TAG_TIME_SPAN,
        TAG_WPT_POINTS,
        TAG_TOTAL_DISTANCE,
        TAG_GRADIENT_SCALE_TYPE,
        TAG_SMOOTHING_THRESHOLD,
        TAG_MIN_FILTER_SPEED,
        TAG_MAX_FILTER_SPEED,
        TAG_MIN_FILTER_ALTITUDE,
        TAG_MAX_FILTER_ALTITUDE,
        TAG_MAX_FILTER_HDOP,
        TAG_IS_JOIN_SEGMENTS
    ])
    
    static func isGpxAppearanceTag(_ tag: String) -> Bool {
        gpxAppearanceTags.contains(tag)
    }
}
