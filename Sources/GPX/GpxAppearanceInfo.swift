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
    // public GradientScaleType scaleType;
    var color: Int = 0
    var coloringType: String?
    var gradientSpeedColor: Int = 0
    var gradientSlopeColor: Int = 0
    var splitType: EOAGpxSplitType = .none
    var splitInterval: CGFloat = 0.0
    var showArrows: Bool = false
    var showStartFinish: Bool = false
    var isJoinSegments: Bool = false
    var verticalExaggerationScale: Double = 0.0
    var elevationMeters: Int = 0
    var visualization3dByType: EOAGPX3DLineVisualizationByType = .none
    var visualization3dWallColorType: EOAGPX3DLineVisualizationWallColorType = .none
    var visualization3dPositionType: EOAGPX3DLineVisualizationPositionType = .top

    var timeSpan: Int = 0
    var wptPoints: Int = 0
    var totalDistance: Float = 0.0

    convenience init(dataItem: GpxDataItem) {
        self.init()
        self.color = dataItem.color
        self.coloringType = dataItem.coloringType
        self.width = dataItem.width
        self.showArrows = dataItem.showArrows
        self.showStartFinish = dataItem.showStartFinish
        self.isJoinSegments = dataItem.joinSegments
        self.verticalExaggerationScale = dataItem.verticalExaggerationScale
        self.elevationMeters = Int(dataItem.elevationMeters)
        self.visualization3dByType = dataItem.visualization3dByType
        self.visualization3dWallColorType = dataItem.visualization3dWallColorType
        self.visualization3dPositionType = dataItem.visualization3dPositionType
        self.splitType = dataItem.splitType
        self.splitInterval = dataItem.splitInterval
        
        // self.scaleType = dataItem.scaleType
        // self.gradientSpeedColor = dataItem.getGradientSpeedColor
        // self.gradientSlopeColor = dataItem.getGradientSlopeColor
        // self.gradientAltitudeColor = dataItem.getGradientAltitudeColor

        self.timeSpan = dataItem.timeSpan
        self.wptPoints = Int(dataItem.wptPoints)
        self.totalDistance = dataItem.totalDistance
    }
    
    override init() {
        super.init()
    }
    
    static func fromJson(_ json: [String: Any]) -> GpxAppearanceInfo {
        let gpxAppearanceInfo = GpxAppearanceInfo()

        gpxAppearanceInfo.color = Int(UIColor.toNumber(from: ""))
        if let color = json["color"] {
            if let number = color as? NSNumber {
                gpxAppearanceInfo.color = number.intValue
            } else if let string = color as? String {
                gpxAppearanceInfo.color = Int(UIColor.toNumber(from: string))
            }
        }

        gpxAppearanceInfo.coloringType = json["coloring_type"] as? String
        gpxAppearanceInfo.width = json["width"] as? String
        gpxAppearanceInfo.showArrows = (json["show_arrows"] as? NSString)?.boolValue ?? false
        gpxAppearanceInfo.showStartFinish = (json["show_start_finish"] as? NSString)?.boolValue ?? false
        gpxAppearanceInfo.isJoinSegments = (json["is_join_segments"] as? NSString)?.boolValue ?? false
        gpxAppearanceInfo.verticalExaggerationScale = (json["elevation_meters"] as? NSString)?.doubleValue ?? 0
        gpxAppearanceInfo.elevationMeters = (json["elevation_meters"] as? NSString)?.integerValue ?? 0
        
        gpxAppearanceInfo.visualization3dByType = OAGPXDatabase.lineVisualizationByType(forName: json["elevation_meters"] as? String ?? "")
        gpxAppearanceInfo.visualization3dWallColorType = OAGPXDatabase.lineVisualizationWallColorType(forName: json["line_3d_visualization_wall_color_type"] as? String ?? "")
        gpxAppearanceInfo.visualization3dPositionType = OAGPXDatabase.lineVisualizationPositionType(forName: json["line_3d_visualization_position_type"] as? String ?? "")
        
        gpxAppearanceInfo.splitType = OAGPXDatabase.splitType(byName: json["split_type"] as? String ?? "")
        gpxAppearanceInfo.splitInterval = json["split_interval"] as? Double ?? 0
        
        // gpxAppearanceInfo.scaleType = [self getScaleType:json[@"gradient_scale_type"]];
        // gpxAppearanceInfo.gradientSpeedColor = json.optInt(GradientScaleType.SPEED.getColorTypeName());
        // gpxAppearanceInfo.gradientSlopeColor = json.optInt(GradientScaleType.SLOPE.getColorTypeName());
        // gpxAppearanceInfo.gradientAltitudeColor = json.optInt(GradientScaleType.ALTITUDE.getColorTypeName());
        
        gpxAppearanceInfo.timeSpan = json["split_interval"] as? Int ?? 0
        gpxAppearanceInfo.wptPoints = json["wpt_points"] as? Int ?? 0
        gpxAppearanceInfo.totalDistance = json["total_distance"] as? Float ?? 0
       
        return gpxAppearanceInfo
    }
    
    static func isGpxAppearanceTag(_ tag: String) -> Bool {
        gpxAppearanceTags.contains(tag)
    }
    
    func myToJson(json: inout [String: Any]) {
    }
    
    func toJson(_ json: [String: Any]) -> [String: Any] {
        var newJson = json
        toJson(&newJson)
        return newJson
    }
    
    func toJson(_ json: inout [String: Any]) {
        json["color"] = UIColor(argb: color).toHexARGBString()
        json["coloring_type"] = coloringType
        json["width"] = width
        json["show_arrows"] = showArrows ? "true" : "false"
        json["show_start_finish"] = showStartFinish ? "true" : "false"
        json["is_join_segments"] = isJoinSegments ? "true" : "false"
        json["vertical_exaggeration_scale"] = String(format: "%f", verticalExaggerationScale)
        json["elevation_meters"] = String(format: "%ld", elevationMeters)
        
        json["line_3d_visualization_by_type"] = OAGPXDatabase.lineVisualizationByTypeName(for: visualization3dByType)
        json["line_3d_visualization_wall_color_type"] = OAGPXDatabase.lineVisualizationWallColorTypeName(for: visualization3dWallColorType)
        json["line_3d_visualization_position_type"] = OAGPXDatabase.lineVisualizationPositionTypeName(for: visualization3dPositionType)
        
        json["split_type"] = OAGPXDatabase.splitTypeName(byValue: splitType)
        json["split_interval"] = String(format: "%f", splitInterval)
        
//        json["gradient_scale_type"] = scaleType
//        json[GradientScaleType.SPEED.getColorTypeName] = show_arrows
//        json[GradientScaleType.SLOPE.getColorTypeName] = show_start_finish
//        json[GradientScaleType.ALTITUDE.getColorTypeName] = color
        
        json["time_span"] = String(format: "%ld", timeSpan)
        json["wpt_points"] = String(format: "%ld", wptPoints)
        json["total_distance"] = String(format: "%f", totalDistance)
    }
}
