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
    
    var width: String?
    var coloringType: String?
    var gradientPaletteName: String?
    var color: Int = 0
    var splitType: EOAGpxSplitType = .none
    var splitInterval: Double = 0.0
    var showArrows = false
    var showStartFinish = false
    var timeSpan: Int = 0
    var wptPoints: Int = 0
    var totalDistance: Float = 0.0
    
    var smoothingThreshold: Double = 0.0
    var minFilterSpeed: Double = 0.0
    var maxFilterSpeed: Double = 0.0
    var minFilterAltitude: Double = 0.0
    var maxFilterAltitude: Double = 0.0
    var maxFilterHdop: Double = 0.0
    
    var trackVisualizationType: EOAGPX3DLineVisualizationByType = .none
    var trackWallColorType: EOAGPX3DLineVisualizationWallColorType = .none
    var trackLinePositionType: EOAGPX3DLineVisualizationPositionType = .top
    
    var verticalExaggeration: Double = 0.0
    var elevationMeters: Int = 0
    
    var isJoinSegments = false // Don't exit in android

    convenience init(dataItem: GpxDataItem) {
        self.init()
        self.color = dataItem.color
        self.width = dataItem.width
        self.showArrows = dataItem.showArrows
        self.showStartFinish = dataItem.showStartFinish
        self.splitType = dataItem.splitType
        self.splitInterval = dataItem.splitInterval
        self.coloringType = dataItem.coloringType
        self.gradientPaletteName = dataItem.gradientPaletteName
        
        self.trackVisualizationType = dataItem.visualization3dByType
        self.trackWallColorType = dataItem.visualization3dWallColorType
        self.trackLinePositionType = dataItem.visualization3dPositionType
        self.verticalExaggeration = dataItem.verticalExaggerationScale
        self.elevationMeters = Int(dataItem.elevationMeters)
        
        self.timeSpan = dataItem.timeSpan
        self.wptPoints = Int(dataItem.wptPoints)
        self.totalDistance = dataItem.totalDistance
        
        self.smoothingThreshold = dataItem.getParameter(parameter: GpxParameter.smoothingThreshold) as? Double ?? 0
        self.minFilterSpeed = dataItem.getParameter(parameter: GpxParameter.minFilterSpeed) as? Double ?? 0
        self.maxFilterSpeed = dataItem.getParameter(parameter: GpxParameter.maxFilterSpeed) as? Double ?? 0
        self.minFilterAltitude = dataItem.getParameter(parameter: GpxParameter.minFilterAltitude) as? Double ?? 0
        self.maxFilterAltitude = dataItem.getParameter(parameter: GpxParameter.maxFilterAltitude) as? Double ?? 0
        self.maxFilterHdop = dataItem.getParameter(parameter: GpxParameter.maxFilterHdop) as? Double ?? 0
        
        self.isJoinSegments = dataItem.joinSegments
    }
    
    override init() {
        super.init()
    }
    
    static func fromJson(_ json: [String: Any]) -> GpxAppearanceInfo {
        let gpxAppearanceInfo = GpxAppearanceInfo()

        gpxAppearanceInfo.color = Int(UIColor.toNumber(from: ""))

        if let color = json[TAG_COLOR] {
            if let number = color as? NSNumber {
                gpxAppearanceInfo.color = number.intValue
            } else if let string = color as? String {
                gpxAppearanceInfo.color = Int(UIColor.toNumber(from: string))
            }
        }
        
        if let value = json[TAG_WIDTH] as? String {
            gpxAppearanceInfo.width = value
        }
        
        if let value = json[TAG_SHOW_ARROWS] {
            gpxAppearanceInfo.showArrows = boolValue(from: value)
        }
        if let value = json[TAG_START_FINISH] {
            gpxAppearanceInfo.showStartFinish = boolValue(from: value)
        }
        if let value = json[TAG_IS_JOIN_SEGMENTS] {
            gpxAppearanceInfo.isJoinSegments = boolValue(from: value)
        }

        gpxAppearanceInfo.splitType = OAGPXDatabase.splitType(byName: json[TAG_SPLIT_TYPE] as? String ?? "")
        gpxAppearanceInfo.splitInterval = json[TAG_SPLIT_INTERVAL] as? Double ?? 0
        
        if let value = json[TAG_COLORING_TYPE] as? String {
            gpxAppearanceInfo.coloringType = value
        }
        if gpxAppearanceInfo.coloringType == nil, let value = json[TAG_GRADIENT_SCALE_TYPE] as? String {
            gpxAppearanceInfo.coloringType = value
        }
        
        if let value = json[TAG_COLOR_PALETTE] as? String {
            gpxAppearanceInfo.gradientPaletteName = value
        }
        if let value = json[TAG_LINE_3D_VISUALIZATION_BY_TYPE] as? String {
            gpxAppearanceInfo.trackVisualizationType = OAGPXDatabase.lineVisualizationByType(forName: value)
        }
        if let value = json[TAG_LINE_3D_VISUALIZATION_WALL_COLOR_TYPE] as? String {
            gpxAppearanceInfo.trackWallColorType = OAGPXDatabase.lineVisualizationWallColorType(forName: value)
        }
        if let value = json[TAG_LINE_3D_VISUALIZATION_POSITION_TYPE] as? String {
            gpxAppearanceInfo.trackLinePositionType = OAGPXDatabase.lineVisualizationPositionType(forName: value)
        }
        
        gpxAppearanceInfo.verticalExaggeration = json[TAG_VERTICAL_EXAGGERATION_SCALE] as? Double ?? 0
        gpxAppearanceInfo.elevationMeters = json[TAG_ELEVATION_METERS] as? Int ?? 0
        gpxAppearanceInfo.timeSpan = json[TAG_TIME_SPAN] as? Int ?? 0
        gpxAppearanceInfo.wptPoints = json[TAG_WPT_POINTS] as? Int ?? 0
        gpxAppearanceInfo.totalDistance = json[TAG_TOTAL_DISTANCE] as? Float ?? 0
        gpxAppearanceInfo.smoothingThreshold = json[TAG_SMOOTHING_THRESHOLD] as? Double ?? 0
        
        gpxAppearanceInfo.minFilterSpeed = json[TAG_MIN_FILTER_SPEED] as? Double ?? 0
        gpxAppearanceInfo.maxFilterSpeed = json[TAG_MAX_FILTER_SPEED] as? Double ?? 0
        gpxAppearanceInfo.minFilterAltitude = json[TAG_MIN_FILTER_ALTITUDE] as? Double ?? 0
        gpxAppearanceInfo.maxFilterAltitude = json[TAG_MAX_FILTER_ALTITUDE] as? Double ?? 0
        gpxAppearanceInfo.maxFilterHdop = json[TAG_MAX_FILTER_HDOP] as? Double ?? 0
        
        return gpxAppearanceInfo
    }
    
    static func isGpxAppearanceTag(_ tag: String) -> Bool {
        gpxAppearanceTags.contains(tag)
    }
    
    func toJson(_ json: inout [String: Any]) {
        Self.writeParam(&json, name: Self.TAG_COLOR, value: UIColor(argb: color).toHexARGBString())
        Self.writeParam(&json, name: Self.TAG_WIDTH, value: width)
        Self.writeParam(&json, name: Self.TAG_SHOW_ARROWS, value: showArrows)
        Self.writeParam(&json, name: Self.TAG_START_FINISH, value: showStartFinish)
        
        Self.writeParam(&json, name: Self.TAG_SPLIT_TYPE, value: OAGPXDatabase.splitTypeName(byValue: splitType))
        Self.writeParam(&json, name: Self.TAG_SPLIT_INTERVAL, value: splitInterval)
        Self.writeParam(&json, name: Self.TAG_COLORING_TYPE, value: coloringType)
        Self.writeParam(&json, name: Self.TAG_COLOR_PALETTE, value: gradientPaletteName)

        Self.writeParam(&json, name: Self.TAG_LINE_3D_VISUALIZATION_BY_TYPE, value: OAGPXDatabase.lineVisualizationByTypeName(for: trackVisualizationType))
        Self.writeParam(&json, name: Self.TAG_LINE_3D_VISUALIZATION_WALL_COLOR_TYPE, value: OAGPXDatabase.lineVisualizationWallColorTypeName(for: trackWallColorType))
        Self.writeParam(&json, name: Self.TAG_LINE_3D_VISUALIZATION_POSITION_TYPE, value: OAGPXDatabase.lineVisualizationPositionTypeName(for: trackLinePositionType))
        
        Self.writeParam(&json, name: Self.TAG_VERTICAL_EXAGGERATION_SCALE, value: verticalExaggeration)
        Self.writeParam(&json, name: Self.TAG_ELEVATION_METERS, value: elevationMeters)
        
        Self.writeParam(&json, name: Self.TAG_TIME_SPAN, value: timeSpan)
        Self.writeParam(&json, name: Self.TAG_WPT_POINTS, value: wptPoints)
        Self.writeParam(&json, name: Self.TAG_TOTAL_DISTANCE, value: totalDistance)
        
        Self.writeValidDouble(&json, name: Self.TAG_SMOOTHING_THRESHOLD, value: smoothingThreshold)
        Self.writeValidDouble(&json, name: Self.TAG_MIN_FILTER_SPEED, value: minFilterSpeed)
        Self.writeValidDouble(&json, name: Self.TAG_MAX_FILTER_SPEED, value: maxFilterSpeed)
        Self.writeValidDouble(&json, name: Self.TAG_MIN_FILTER_ALTITUDE, value: minFilterAltitude)
        Self.writeValidDouble(&json, name: Self.TAG_MAX_FILTER_ALTITUDE, value: maxFilterAltitude)
        Self.writeValidDouble(&json, name: Self.TAG_MAX_FILTER_HDOP, value: maxFilterHdop)
        
        Self.writeParam(&json, name: Self.TAG_IS_JOIN_SEGMENTS, value: isJoinSegments)
    }
    
    // to run from obj-c
    func toJson(_ json: [String: Any]) -> [String: Any] {
        var newJson = json
        toJson(&newJson)
        return newJson
    }
    
    private static func writeParam(_ json: inout [String: Any], name: String, value: Any?) {
        guard let value else { return }
        
        switch value {
        case let v as Int where v != 0:
            json[name] = "\(v)"
        case let v as Int32 where v != 0:
            json[name] = "\(v)"
        case let v as Int64 where v != 0:
            json[name] = "\(v)"
        case let v as Double where !v.isZero && !v.isNaN:
            json[name] = "\(v)"
        case let v as Float where !v.isZero && !v.isNaN:
            json[name] = "\(v)"
        case let v as Bool:
            json[name] = v
        case let v as String where !v.isEmpty:
            json[name] = v
        default:
            json[name] = value
        }
    }

    private static func writeValidDouble(_ json: inout [String: Any], name: String, value: Double) {
        if !value.isNaN {
            json[name] = value
        }
    }
    
    private static func boolValue(from any: Any?) -> Bool {
        if let bool = any as? Bool { return bool }
        if let string = any as? String { return (string as NSString).boolValue }
        return false
    }
}
