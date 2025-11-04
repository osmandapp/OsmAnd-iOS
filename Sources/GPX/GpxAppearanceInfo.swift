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
    var showArrows: Bool = false
    var showStartFinish: Bool = false
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
    
    var isJoinSegments: Bool = false // Don't exit in android

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
        self.maxFilterAltitude = dataItem.getParameter(parameter: GpxParameter.minFilterAltitude) as? Double ?? 0
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
        gpxAppearanceInfo.showArrows = json[TAG_SHOW_ARROWS] as? Bool ?? false
        gpxAppearanceInfo.showStartFinish = json[TAG_START_FINISH] as? Bool ?? false
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
        
        gpxAppearanceInfo.isJoinSegments = json["is_join_segments"] as? Bool ?? false
        
        return gpxAppearanceInfo
    }
    
    static func isGpxAppearanceTag(_ tag: String) -> Bool {
        gpxAppearanceTags.contains(tag)
    }
    
    func toJson(_ json: inout [String: Any]) {
        json[Self.TAG_COLOR] = UIColor(argb: color).toHexARGBString()
        json[Self.TAG_WIDTH] = width
        json[Self.TAG_SHOW_ARROWS] = showArrows ? "true" : "false"
        json[Self.TAG_START_FINISH] = showStartFinish ? "true" : "false"
        
        json[Self.TAG_SPLIT_TYPE] = OAGPXDatabase.splitTypeName(byValue: splitType)
        json[Self.TAG_SPLIT_INTERVAL] = String(format: "%f", splitInterval)
        json[Self.TAG_COLORING_TYPE] = coloringType
        if let gradientPaletteName {
            json[Self.TAG_COLOR_PALETTE] = gradientPaletteName
        }
        
        json[Self.TAG_LINE_3D_VISUALIZATION_BY_TYPE] = OAGPXDatabase.lineVisualizationByTypeName(for: trackVisualizationType)
        json[Self.TAG_LINE_3D_VISUALIZATION_WALL_COLOR_TYPE] = OAGPXDatabase.lineVisualizationWallColorTypeName(for: trackWallColorType)
        json[Self.TAG_LINE_3D_VISUALIZATION_POSITION_TYPE] = OAGPXDatabase.lineVisualizationPositionTypeName(for: trackLinePositionType)
        
        json[Self.TAG_VERTICAL_EXAGGERATION_SCALE] = String(format: "%f", verticalExaggeration)
        json[Self.TAG_ELEVATION_METERS] = String(format: "%ld", elevationMeters)
        
        json[Self.TAG_TIME_SPAN] = String(format: "%ld", timeSpan)
        json[Self.TAG_WPT_POINTS] = String(format: "%ld", wptPoints)
        json[Self.TAG_TOTAL_DISTANCE] = String(format: "%f", totalDistance)
        
        json[Self.TAG_SMOOTHING_THRESHOLD] = String(format: "%f", smoothingThreshold)
        json[Self.TAG_MIN_FILTER_SPEED] = String(format: "%f", minFilterSpeed)
        json[Self.TAG_MAX_FILTER_SPEED] = String(format: "%f", maxFilterSpeed)
        json[Self.TAG_MIN_FILTER_ALTITUDE] = String(format: "%f", minFilterAltitude)
        json[Self.TAG_MAX_FILTER_ALTITUDE] = String(format: "%f", maxFilterSpeed)
        json[Self.TAG_MAX_FILTER_HDOP] = String(format: "%f", maxFilterHdop)
        
        json["is_join_segments"] = isJoinSegments ? "true" : "false"
    }
    
    // to run from obj-c
    func toJson(_ json: [String: Any]) -> [String: Any] {
        var newJson = json
        toJson(&newJson)
        return newJson
    }
    
    private static func writeParam(_ json: inout [String: Any], name: String, value: Any?) {
        guard let value = value else { return }
        
        switch value {
        case let v as Int:
            if v != 0 { json[name] = v }
        case let v as Int64:
            if v != 0 { json[name] = v }
        case let v as UInt:
            if v != 0 { json[name] = v }
        case let v as Double:
            if v != 0.0, !v.isNaN { json[name] = v }
        case let v as Float:
            let d = Double(v)
            if d != 0.0, !d.isNaN { json[name] = d }
        case let v as Bool:
            json[name] = v ? "true" : "false"
        case let s as String:
            if !s.isEmpty { json[name] = s }
        default:
            json[name] = value
        }
    }

    private static func writeValidDouble(_ json: inout [String: Any], name: String, value: Double) {
        if !value.isNaN {
            json[name] = value
        }
    }
}
