//
//  OAGpxAppearanceInfo.m
//  OsmAnd
//
//  Created by Anna Bibyk on 29.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAGpxAppearanceInfo.h"
#import "OAGPXTrackAnalysis.h"
#import "OAGPXDocument.h"

@interface OAGpxAppearanceInfo()

@end

@implementation OAGpxAppearanceInfo

- (instancetype) initWithItem:(OAGPX *)dataItem
{
    self = [super init];
    if (self)
    {
        _color = dataItem.color;
        _coloringType = dataItem.coloringType;
        _width = dataItem.width;
        _showArrows = dataItem.showArrows;
        _showStartFinish = dataItem.showStartFinish;
        _verticalExaggerationScale = dataItem.verticalExaggerationScale;
        _elevationMeters = dataItem.elevationMeters;
        _visualization3dByType = dataItem.visualization3dByType;
        _visualization3dWallColorType = dataItem.visualization3dWallColorType;
        _visualization3dPositionType = dataItem.visualization3dPositionType;
        _splitType = dataItem.splitType;
        _splitInterval = dataItem.splitInterval;
//        _scaleType = dataItem.scaleType;
//        _gradientSpeedColor = dataItem.getGradientSpeedColor;
//        _gradientSlopeColor = dataItem.getGradientSlopeColor;
//        _gradientAltitudeColor = dataItem.getGradientAltitudeColor;
//
        _timeSpan = dataItem.timeSpan;
        _wptPoints = dataItem.wptPoints;
        _totalDistance = dataItem.totalDistance;
    }
    return self;
}

- (void) toJson:(id)json
{
    json[@"color"] = [UIColorFromARGB(_color) toHexARGBString];;
    json[@"coloring_type"] = _coloringType;
    json[@"width"] = _width;
    json[@"show_arrows"] = _showArrows ? @"true" : @"false";
    json[@"show_start_finish"] = _showStartFinish ? @"true" : @"false";
    json[@"vertical_exaggeration_scale"] = [NSString stringWithFormat:@"%f", _verticalExaggerationScale];
    json[@"elevation_meters"] = [NSString stringWithFormat:@"%ld", _elevationMeters];
    
    json[@"line_3d_visualization_by_type"] = [OAGPXDatabase lineVisualizationByTypeNameForType:_visualization3dByType];
    json[@"line_3d_visualization_wall_color_type"] = [OAGPXDatabase lineVisualizationWallColorTypeNameForType:_visualization3dWallColorType];
    json[@"line_3d_visualization_position_type"] = [OAGPXDatabase lineVisualizationPositionTypeNameForType:_visualization3dPositionType];
    
    json[@"split_type"] = [OAGPXDatabase splitTypeNameByValue:_splitType];

    json[@"split_interval"] = [NSString stringWithFormat:@"%f", _splitInterval];
    //jsonObject[@"gradient_scale_type"] = _scaleType;
    //jsonObject[GradientScaleType.SPEED.getColorTypeName] = _show_arrows;
    //jsonObject[GradientScaleType.SLOPE.getColorTypeName] = _show_start_finish;
    //jsonObject[GradientScaleType.ALTITUDE.getColorTypeName] = _color;
    json[@"time_span"] = [NSString stringWithFormat:@"%ld", _timeSpan];
    json[@"wpt_points"] = [NSString stringWithFormat:@"%ld", _wptPoints];
    json[@"total_distance"] = [NSString stringWithFormat:@"%f", _totalDistance];
}

+ (OAGpxAppearanceInfo *) fromJson:()json
{
    OAGpxAppearanceInfo *gpxAppearanceInfo = [[OAGpxAppearanceInfo alloc] init];
    id color = json[@"color"];
    BOOL hasColor = color != nil;
    if (hasColor)
        gpxAppearanceInfo.color = [color isKindOfClass:NSNumber.class] ? ((NSNumber *) color).intValue : [UIColor toNumberFromString:color];
    else
        gpxAppearanceInfo.color = [UIColor toNumberFromString:nil];
    gpxAppearanceInfo.coloringType = json[@"coloring_type"];
    gpxAppearanceInfo.width = json[@"width"];
    gpxAppearanceInfo.showArrows = [json[@"show_arrows"] boolValue];
    gpxAppearanceInfo.showStartFinish = [json[@"show_start_finish"] boolValue];
    gpxAppearanceInfo.verticalExaggerationScale = [json[@"vertical_exaggeration_scale"] floatValue];
    gpxAppearanceInfo.elevationMeters = [json[@"elevation_meters"] integerValue];
    
    gpxAppearanceInfo.visualization3dByType = [OAGPXDatabase lineVisualizationByTypeForName:json[@"line_3d_visualization_by_type"]];
    
    gpxAppearanceInfo.visualization3dWallColorType = [OAGPXDatabase lineVisualizationWallColorTypeForName:json[@"line_3d_visualization_wall_color_type"]];
    gpxAppearanceInfo.visualization3dPositionType = [OAGPXDatabase lineVisualizationPositionTypeForName:json[@"line_3d_visualization_position_type"]];
    
    gpxAppearanceInfo.splitType = [OAGPXDatabase splitTypeByName:json[@"split_type"]];
    gpxAppearanceInfo.splitInterval = [json[@"split_interval"] floatValue];
    //gpxAppearanceInfo.scaleType = [self getScaleType:json[@"gradient_scale_type"]];
    //gpxAppearanceInfo.gradientSpeedColor = json.optInt(GradientScaleType.SPEED.getColorTypeName());
    //gpxAppearanceInfo.gradientSlopeColor = json.optInt(GradientScaleType.SLOPE.getColorTypeName());
    //gpxAppearanceInfo.gradientAltitudeColor = json.optInt(GradientScaleType.ALTITUDE.getColorTypeName());
    
    gpxAppearanceInfo.timeSpan = [json[@"time_span"] intValue];
    gpxAppearanceInfo.wptPoints = [json[@"wpt_points"] intValue];
    gpxAppearanceInfo.totalDistance = [json[@"total_distance"] floatValue];
    return gpxAppearanceInfo;
}

//- (GradientScaleType) getScaleType:(NSString *)name
//{
//    if (!Algorithms.isEmpty(name)) {
//        try {
//            return GradientScaleType.valueOf(name);
//        } catch (IllegalStateException e) {
//            SettingsHelper.LOG.error("Failed to read gradientScaleType", e);
//        }
//    }
//    return null;
//}
 
 /*
private static void writeParam(@NonNull JSONObject json, @NonNull String name, @Nullable Object value) throws JSONException {
    if (value instanceof Integer) {
        if ((Integer) value != 0) {
            json.putOpt(name, value);
        }
    } else if (value instanceof Long) {
        if ((Long) value != 0) {
            json.putOpt(name, value);
        }
    } else if (value instanceof Double) {
        if ((Double) value != 0.0 && !Double.isNaN((Double) value)) {
            json.putOpt(name, value);
        }
    } else if (value instanceof String) {
        if (!Algorithms.isEmpty((String) value)) {
            json.putOpt(name, value);
        }
    } else if (value != null) {
        json.putOpt(name, value);
    }
}
*/

@end
