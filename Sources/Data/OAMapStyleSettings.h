//
//  OAMapStyleSettings.h
//  OsmAnd
//
//  Created by Alexey Kulish on 14/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * const HORSE_ROUTES_ATTR = @"horseRoutes";
static NSString * const PISTE_ROUTES_ATTR = @"pisteRoutes";
static NSString * const ALPINE_HIKING_ATTR = @"alpineHiking";
static NSString * const SHOW_CYCLE_ROUTES_ATTR = @"showCycleRoutes";
static NSString * const DIRTBIKE_ROUTES_ATTR = @"showDirtbikeTrails";
static NSString * const WHITE_WATER_SPORTS_ATTR = @"whiteWaterSports";
static NSString * const HIKING_ROUTES_OSMC_ATTR = @"hikingRoutesOSMC";
static NSString * const CYCLE_NODE_NETWORK_ROUTES_ATTR = @"showCycleNodeNetworkRoutes";
static NSString * const TRAVEL_ROUTES = @"travel_routes";
static NSString * const SHOW_FITNESS_TRAILS_ATTR = @"showFitnessTrails";
static NSString * const SHOW_RUNNING_ROUTES_ATTR = @"showRunningRoutes";

static NSString * const SHOW_MTB_ROUTES = @"showMtbRoutes";
static NSString * const SHOW_MTB_SCALE = @"showMtbScale";

static NSString * const SHOW_ALPINE_HIKING_SCALE_SCHEME_ROUTES = @"alpineHikingScaleScheme";

static NSString * const SHOW_MTB_SCALE_UPHILL = @"showMtbScaleUphill";
static NSString * const SHOW_MTB_SCALE_IMBA_TRAILS = @"showMtbScaleIMBATrails";

static NSString * const TRANSPORT_CATEGORY = @"transport";
static NSString * const TRANSPORT_STOPS_ATTR = @"transportStops";
static NSString * const BUS_ROUTES_ATTR = @"showBusRoutes";
static NSString * const TROLLEYBUS_ROUTES_ATTR = @"showTrolleybusRoutes";
static NSString * const SUBWAY_MODE_ATTR = @"subwayMode";
static NSString * const SHARE_TAXI_ROUTES_ATTR = @"showShareTaxiRoutes";
static NSString * const TRAM_ROUTES_ATTR = @"showTramRoutes";
static NSString * const TRAIN_ROUTES_ATTR = @"showTrainRoutes";
static NSString * const LIGHT_RAIL_ROUTES_ATTR = @"showLightRailRoutes";
static NSString * const FUNICULAR_ROUTES = @"showFunicularRoutes";
static NSString * const MONORAIL_ROUTES_ATTR = @"showMonorailRoutes";

static NSString * const CONTOUR_LINES = @"contourLines";
static NSString * const CONTOUR_DENSITY_ATTR = @"contourDensity";
static NSString * const CONTOUR_WIDTH_ATTR = @"contourWidth";
static NSString * const CONTOUR_COLOR_SCHEME_ATTR = @"contourColorScheme";

static NSString * const NAUTICAL_DEPTH_CONTOURS = @"depthContours";
static NSString * const NAUTICAL_DEPTH_CONTOUR_WIDTH_ATTR = @"depthContourWidth";
static NSString * const NAUTICAL_DEPTH_CONTOUR_COLOR_SCHEME_ATTR = @"depthContourColorScheme";

static NSString * const CURRENT_TRACK_COLOR_ATTR = @"currentTrackColor";
static NSString * const CURRENT_TRACK_WIDTH_ATTR = @"currentTrackWidth";

static NSString * const WEATHER_TEMP_CONTOUR_LINES_ATTR = @"weatherTempContours";
static NSString * const WEATHER_PRESSURE_CONTOURS_LINES_ATTR = @"weatherPressureContours";
static NSString * const WEATHER_CLOUD_CONTOURS_LINES_ATTR = @"weatherCloudContours";
static NSString * const WEATHER_WIND_CONTOURS_LINES_ATTR = @"weatherWindSpeedContours";
static NSString * const WEATHER_PRECIPITATION_CONTOURS_LINES_ATTR = @"weatherPrecipitationContours";
static NSString * const WEATHER_NONE_CONTOURS_LINES_VALUE = @"none";

typedef NS_ENUM(NSInteger, OAMapStyleValueDataType)
{
    OABoolean,
    OAInteger,
    OAFloat,
    OAString,
    OAColor,
};

@interface OAMapStyleParameterValue : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *title;

@end

@interface OAMapStyleParameter : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *mapStyleName;
@property (nonatomic) NSString *mapPresetName;
@property (nonatomic) NSString *category;
@property (nonatomic) OAMapStyleValueDataType dataType;
@property (nonatomic) NSString *value;
@property (nonatomic) NSString *storedValue;
@property (nonatomic) NSString *defaultValue;
@property (nonatomic) NSArray<OAMapStyleParameterValue *> *possibleValues;
@property (nonatomic) NSArray<OAMapStyleParameterValue *> *possibleValuesUnsorted;

- (NSString *) getValueTitle;

@end

@interface OAMapStyleSettings : NSObject

- (instancetype) initWithStyleName:(NSString *)mapStyleName mapPresetName:(NSString *)mapPresetName;

+ (OAMapStyleSettings *) sharedInstance;

- (void) loadParameters;
- (NSArray<OAMapStyleParameter *> *) getAllParameters;
- (OAMapStyleParameter *) getParameter:(NSString *)name;

- (NSArray<NSString *> *) getAllCategories;
- (NSString *) getCategoryTitle:(NSString *)categoryName;
- (NSArray<OAMapStyleParameter *> *) getParameters:(NSString *)category;
- (NSArray<OAMapStyleParameter *> *) getParameters:(NSString *)category sorted:(BOOL)sorted;

- (BOOL) isCategoryEnabled:(NSString *)categoryName;
- (BOOL) isCategoryDisabled:(NSString *)categoryName;
- (void) setCategoryEnabled:(BOOL)isVisible categoryName:(NSString *)categoryName;

- (void) saveParameters;
- (void) save:(OAMapStyleParameter *)parameter;
- (void) save:(OAMapStyleParameter *)parameter refreshMap:(BOOL)refreshMap;

- (void) resetMapStyleForAppMode:(NSString *)mapPresetName
                      onComplete:(void(^)(void))onComplete;

- (BOOL)isAnyWeatherContourLinesEnabled;
- (BOOL)isWeatherContourLinesEnabled:(NSString *)attr;
- (void)setWeatherContourLinesEnabled:(BOOL)enabled weatherContourLinesAttr:(NSString *)attr;

+ (NSString *)getTransportIconForName:(NSString *)name;
+ (int)getTransportSortIndexForName:(NSString *)name;


@end
