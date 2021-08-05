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
//        _width = dataItem.width;
//        _showArrows = dataItem.showArrows;
//        _showStartFinish = dataItem.showStartFinish;
//        _splitType = dataItem.splitType;
//        _splitInterval = dataItem.splitInterval;
//        _scaleType = dataItem.scaleType;
//        _gradientSpeedColor = dataItem.getGradientSpeedColor;
//        _gradientSlopeColor = dataItem.getGradientSlopeColor;
//        _gradientAltitudeColor = dataItem.getGradientAltitudeColor;
//
        OAGPXDocument *doc = [[OAGPXDocument alloc] initWithGpxFile:dataItem.gpxFilePath];
        OAGPXTrackAnalysis *analysis = [doc getAnalysis:0];
        if (analysis)
        {
            _timeSpan = analysis.timeSpan;
            _wptPoints = analysis.wptPoints;
            _totalDistance = analysis.totalDistance;
        }
    }
    return self;
}

- (void) toJson:(id)json
{
    NSMutableDictionary *jsonObject = [NSMutableDictionary dictionary];
    
    jsonObject[@"color"] = [NSString stringWithFormat:@"%ld", _color];
    jsonObject[@"width"] = _width;
    jsonObject[@"show_arrows"] = @(_showArrows);
    jsonObject[@"show_start_finish"] = @(_showStartFinish);
    jsonObject[@"split_type"] = [NSString stringWithFormat:@"%ld", _splitType];
    
    jsonObject[@"split_interval"] = [NSString stringWithFormat:@"%f", _splitInterval];
    //jsonObject[@"gradient_scale_type"] = _scaleType;
    //jsonObject[GradientScaleType.SPEED.getColorTypeName] = _show_arrows;
    //jsonObject[GradientScaleType.SLOPE.getColorTypeName] = _show_start_finish;
    //jsonObject[GradientScaleType.ALTITUDE.getColorTypeName] = _color;
    jsonObject[@"time_span"] = [NSString stringWithFormat:@"%ld", _timeSpan];
    jsonObject[@"wpt_points"] = [NSString stringWithFormat:@"%ld", _wptPoints];
    jsonObject[@"total_distance"] = [NSString stringWithFormat:@"%f", _totalDistance];
    
    json = [NSDictionary dictionaryWithDictionary:jsonObject];
}

+ (OAGpxAppearanceInfo *) fromJson:()json
{
    OAGpxAppearanceInfo *gpxAppearanceInfo = [[OAGpxAppearanceInfo alloc] init];
    
    gpxAppearanceInfo.color = [json[@"color"] intValue];
    gpxAppearanceInfo.width = json[@"width"];
    gpxAppearanceInfo.showArrows = [json[@"show_arrows"] boolValue];
    gpxAppearanceInfo.showStartFinish = [json[@"show_start_finish"] boolValue];
    //gpxAppearanceInfo.splitType = GpxSplitType.getSplitTypeByName(json.optString("split_type")).getType();
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
