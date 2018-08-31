//
//  OADebugSettings.h
//  OsmAnd
//
//  Created by AntonRogachevskiy on 10/16/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OAApplicationMode.h"

#define kNotificationSetProfileSetting @"kNotificationSetProfileSetting"
#define VOICE_PROVIDER_NOT_USE @"VOICE_PROVIDER_NOT_USE"

#define settingAppModeKey @"settingAppModeKey"

typedef NS_ENUM(NSInteger, EOAMetricsConstant)
{
    KILOMETERS_AND_METERS = 0,
    MILES_AND_FEET,
    MILES_AND_YARDS,
    MILES_AND_METERS,
    NAUTICAL_MILES
};

@interface OAMetricsConstant : NSObject

@property (nonatomic, readonly) EOAMetricsConstant mc;

+ (instancetype) withMetricConstant:(EOAMetricsConstant)mc;

+ (NSString *) toHumanString:(EOAMetricsConstant)mc;
+ (NSString *) toTTSString:(EOAMetricsConstant)mc;

@end

typedef NS_ENUM(NSInteger, EOASpeedConstant)
{
    KILOMETERS_PER_HOUR = 0,
    MILES_PER_HOUR,
    METERS_PER_SECOND,
    MINUTES_PER_MILE,
    MINUTES_PER_KILOMETER,
    NAUTICALMILES_PER_HOUR
};

@interface OASpeedConstant : NSObject

@property (nonatomic, readonly) EOASpeedConstant sc;
@property (nonatomic, readonly) NSString *key;
@property (nonatomic, readonly) NSString *descr;

+ (instancetype) withSpeedConstant:(EOASpeedConstant)sc;
+ (NSArray<OASpeedConstant *> *) values;

+ (NSString *) toHumanString:(EOASpeedConstant)sc;
+ (NSString *) toShortString:(EOASpeedConstant)sc;

@end

typedef NS_ENUM(NSInteger, EOADrivingRegion)
{
    DR_EUROPE_ASIA = 0,
    DR_US,
    DR_CANADA,
    DR_UK_AND_OTHERS,
    DR_JAPAN,
    DR_AUSTRALIA
};

@interface OADrivingRegion : NSObject

@property (nonatomic, readonly) EOADrivingRegion region;

+ (instancetype) withRegion:(EOADrivingRegion)region;

+ (NSArray<OADrivingRegion *> *) values;

+ (BOOL) isLeftHandDriving:(EOADrivingRegion)region;
+ (BOOL) isAmericanSigns:(EOADrivingRegion)region;
+ (EOAMetricsConstant) getDefMetrics:(EOADrivingRegion)region;
+ (NSString *) getName:(EOADrivingRegion)region;
+ (NSString *) getDescription:(EOADrivingRegion)region;

+ (EOADrivingRegion) getDefaultRegion;

@end

typedef NS_ENUM(NSInteger, EOAAutoZoomMap)
{
    AUTO_ZOOM_MAP_FARTHEST = 0,
    AUTO_ZOOM_MAP_FAR,
    AUTO_ZOOM_MAP_CLOSE
};

@interface OAAutoZoomMap : NSObject

@property (nonatomic, readonly) EOAAutoZoomMap autoZoomMap;
@property (nonatomic, readonly) float coefficient;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) float maxZoom;

+ (instancetype) withAutoZoomMap:(EOAAutoZoomMap)autoZoomMap;
+ (NSArray<OAAutoZoomMap *> *) values;

+ (float) getCoefficient:(EOAAutoZoomMap)autoZoomMap;
+ (NSString *) getName:(EOAAutoZoomMap)autoZoomMap;
+ (float) getMaxZoom:(EOAAutoZoomMap)autoZoomMap;

@end

typedef NS_ENUM(NSInteger, EOAMapMarkersMode)
{
    MAP_MARKERS_MODE_TOOLBAR = 0,
    MAP_MARKERS_MODE_WIDGETS,
    MAP_MARKERS_MODE_NONE
};

@interface OAMapMarkersMode : NSObject

@property (nonatomic, readonly) EOAMapMarkersMode mode;
@property (nonatomic, readonly) NSString *name;

+ (instancetype) withMode:(EOAMapMarkersMode)mode;
+ (NSArray<OAAutoZoomMap *> *) possibleValues;

+ (NSString *) getName:(EOAMapMarkersMode)mode;

@end

@interface OAProfileSetting : NSObject

@property (nonatomic, readonly) NSString *key;

- (NSObject *) getProfileDefaultValue:(OAApplicationMode *)mode;
- (void) resetToDefault;

@end

@interface OAProfileBoolean : OAProfileSetting

+ (instancetype) withKey:(NSString *)key defValue:(BOOL)defValue;

- (BOOL) get;
- (void) set:(BOOL)boolean;
- (BOOL) get:(OAApplicationMode *)mode;
- (void) set:(BOOL)boolean mode:(OAApplicationMode *)mode;

@end

@interface OAProfileInteger : OAProfileSetting

+ (instancetype) withKey:(NSString *)key defValue:(int)defValue;

- (int) get;
- (void) set:(int)integer;
- (int) get:(OAApplicationMode *)mode;
- (void) set:(int)integer mode:(OAApplicationMode *)mode;

@end

@interface OAProfileString : OAProfileSetting

+ (instancetype) withKey:(NSString *)key defValue:(NSString *)defValue;

- (NSString *) get;
- (void) set:(NSString *)string;
- (NSString *) get:(OAApplicationMode *)mode;
- (void) set:(NSString *)string mode:(OAApplicationMode *)mode;

@end

@interface OAProfileDouble : OAProfileSetting

+ (instancetype) withKey:(NSString *)key defValue:(double)defValue;

- (double) get;
- (void) set:(double)dbl;
- (double) get:(OAApplicationMode *)mode;
- (void) set:(double)dbl mode:(OAApplicationMode *)mode;

@end

@interface OAProfileAutoZoomMap : OAProfileInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOAAutoZoomMap)defValue;

- (EOAAutoZoomMap) get;
- (void) set:(EOAAutoZoomMap)autoZoomMap;
- (EOAAutoZoomMap) get:(OAApplicationMode *)mode;
- (void) set:(EOAAutoZoomMap)autoZoomMap mode:(OAApplicationMode *)mode;

@end

@interface OAProfileSpeedConstant : OAProfileInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOASpeedConstant)defValue;

- (EOASpeedConstant) get;
- (void) set:(EOASpeedConstant)speedConstant;
- (EOASpeedConstant) get:(OAApplicationMode *)mode;
- (void) set:(EOASpeedConstant)speedConstant mode:(OAApplicationMode *)mode;

@end

@interface OAProfileMapMarkersMode : OAProfileInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOAMapMarkersMode)defValue;

- (EOAMapMarkersMode) get;
- (void) set:(EOAMapMarkersMode)mapMarkersMode;
- (EOAMapMarkersMode) get:(OAApplicationMode *)mode;
- (void) set:(EOAMapMarkersMode)mapMarkersMode mode:(OAApplicationMode *)mode;

@end

@interface OAAppSettings : NSObject

+ (OAAppSettings *)sharedManager;
@property (assign, nonatomic) BOOL settingShowMapRulet;

@property (assign, nonatomic) int settingMapLanguage;
@property (nonatomic) NSString *settingPrefMapLanguage;
@property (assign, nonatomic) BOOL settingMapLanguageShowLocal;
@property (assign, nonatomic) BOOL settingMapLanguageTranslit;

#define APPEARANCE_MODE_DAY 0
#define APPEARANCE_MODE_NIGHT 1
#define APPEARANCE_MODE_AUTO 2

#define MAP_ARROWS_LOCATION 0
#define MAP_ARROWS_MAP_CENTER 1

#define SAVE_TRACK_INTERVAL_DEFAULT 5000
#define REC_FILTER_DEFAULT 0.f

#define MAP_GEO_FORMAT_DEGREES 0
#define MAP_GEO_FORMAT_MINUTES 1

#define ROTATE_MAP_NONE 0
#define ROTATE_MAP_BEARING 1
#define ROTATE_MAP_COMPASS 2

@property (nonatomic, readonly) NSArray *trackIntervalArray;
@property (nonatomic, readonly) NSArray *mapLanguages;
@property (nonatomic, readonly) NSArray *ttsAvailableVoices;
@property (nonatomic, readonly) NSArray *rtlLanguages;


@property (assign, nonatomic) int settingAppMode; // 0 - Day; 1 - Night; 2 - Auto
@property (readonly, nonatomic) BOOL nightMode;
@property (assign, nonatomic) EOAMetricsConstant metricSystem;
@property (assign, nonatomic) BOOL drivingRegionAutomatic;
@property (assign, nonatomic) EOADrivingRegion drivingRegion;
@property (assign, nonatomic) BOOL settingShowZoomButton;
@property (assign, nonatomic) int settingGeoFormat; // 0 - degrees, 1 - minutes/seconds
@property (assign, nonatomic) BOOL settingShowAltInDriveMode;
@property (assign, nonatomic) BOOL metricSystemChangedManually;

@property (assign, nonatomic) int settingMapArrows; // 0 - from Location; 1 - from Map Center
@property (assign, nonatomic) CLLocationCoordinate2D mapCenter;

@property (assign, nonatomic) BOOL mapSettingShowFavorites;
@property (nonatomic) NSArray *mapSettingVisibleGpx;

// Track recording settings
@property (nonatomic) OAProfileBoolean *saveTrackToGPX;
@property (nonatomic) OAProfileInteger *mapSettingSaveTrackInterval;
@property (assign, nonatomic) float saveTrackMinDistance;
@property (assign, nonatomic) float saveTrackPrecision;
@property (assign, nonatomic) float saveTrackMinSpeed;

@property (assign, nonatomic) BOOL mapSettingTrackRecording;
@property (assign, nonatomic) int mapSettingSaveTrackIntervalGlobal;
@property (assign, nonatomic) BOOL mapSettingSaveTrackIntervalApproved;

@property (assign, nonatomic) BOOL mapSettingShowRecordingTrack;

@property (nonatomic) NSString* mapSettingActiveRouteFileName;
@property (nonatomic) int mapSettingActiveRouteVariantType;

@property (nonatomic) NSArray<NSString *> *selectedPoiFilters;

@property (nonatomic) NSInteger discountId;
@property (nonatomic) NSInteger discountShowNumberOfStarts;
@property (nonatomic) NSInteger discountTotalShow;
@property (nonatomic) double discountShowDatetime;

@property (nonatomic) unsigned long long lastSearchedCity;
@property (nonatomic) NSString* lastSearchedCityName;
@property (nonatomic) CLLocation *lastSearchedPoint;

@property (assign, nonatomic) BOOL settingDoNotShowPromotions;
@property (assign, nonatomic) BOOL settingDoNotUseFirebase;

- (OAProfileBoolean *) getCustomRoutingBooleanProperty:(NSString *)attrName defaultValue:(BOOL)defaultValue;
- (OAProfileString *) getCustomRoutingProperty:(NSString *)attrName defaultValue:(NSString *)defaultValue;

@property (nonatomic) OAApplicationMode* applicationMode;
@property (nonatomic) NSString* availableApplicationModes;
@property (nonatomic) OAApplicationMode* defaultApplicationMode;
@property (nonatomic) OAApplicationMode* lastRoutingApplicationMode;
@property (nonatomic) OAProfileInteger *rotateMap;

@property (nonatomic) OAProfileString *mapInfoControls;
@property (nonatomic) NSSet<NSString *> *plugins;
@property (assign, nonatomic) BOOL firstMapIsDownloaded;

// navigation settings
@property (assign, nonatomic) BOOL useFastRecalculation;
@property (nonatomic) OAProfileBoolean *fastRouteMode;
@property (assign, nonatomic) BOOL disableComplexRouting;
@property (assign, nonatomic) BOOL followTheRoute;
@property (nonatomic) NSString *followTheGpxRoute;
@property (nonatomic) OAProfileDouble *arrivalDistanceFactor;
@property (assign, nonatomic) BOOL useIntermediatePointsNavigation;
@property (assign, nonatomic) BOOL disableOffrouteRecalc;
@property (assign, nonatomic) BOOL disableWrongDirectionRecalc;
@property (nonatomic) OAProfileInteger *routerService;
@property (assign, nonatomic) BOOL gpxRouteCalcOsmandParts;
@property (assign, nonatomic) BOOL gpxCalculateRtept;
@property (assign, nonatomic) BOOL gpxRouteCalc;
@property (assign, nonatomic) BOOL voiceMute;
@property (nonatomic) NSString *voiceProvider;
@property (nonatomic) OAProfileBoolean *interruptMusic;
@property (nonatomic) OAProfileBoolean *snapToRoad;
@property (nonatomic) OAProfileInteger *autoFollowRoute;
@property (nonatomic) OAProfileBoolean *autoZoomMap;
@property (nonatomic) OAProfileAutoZoomMap *autoZoomMapScale;
@property (nonatomic) OAProfileInteger *keepInforming;
@property (nonatomic) OAProfileSpeedConstant *speedSystem;
@property (nonatomic) OAProfileDouble *speedLimitExceed;
@property (nonatomic) OAProfileDouble *switchMapDirectionToCompass;
@property (nonatomic) OAProfileInteger *wakeOnVoiceInt;

@property (nonatomic) OAProfileBoolean *showTrafficWarnings;
@property (nonatomic) OAProfileBoolean *showPedestrian;
@property (nonatomic) OAProfileBoolean *showCameras;
@property (nonatomic) OAProfileBoolean *showLanes;
@property (nonatomic) OAProfileBoolean *showArrivalTime;
@property (assign, nonatomic) BOOL showRelativeBearing;

@property (nonatomic) OAProfileBoolean *speakStreetNames;
@property (nonatomic) OAProfileBoolean *speakTrafficWarnings;
@property (nonatomic) OAProfileBoolean *speakPedestrian;
@property (nonatomic) OAProfileBoolean *speakSpeedLimit;
@property (nonatomic) OAProfileBoolean *speakCameras;
@property (nonatomic) OAProfileBoolean *speakTunnels;
@property (nonatomic) OAProfileBoolean *announceNearbyFavorites;
@property (nonatomic) OAProfileBoolean *announceNearbyPoi;

@property (assign, nonatomic) BOOL showGpxWpt;
@property (assign, nonatomic) BOOL announceWpt;
@property (nonatomic) OAProfileBoolean *showNearbyFavorites;
@property (nonatomic) OAProfileBoolean *showNearbyPoi;

@property (nonatomic) OAProfileBoolean *showDestinationArrow;
@property (nonatomic) OAProfileBoolean *transparentMapTheme;
@property (nonatomic) OAProfileBoolean *showStreetName;
@property (nonatomic) OAProfileBoolean *centerPositionOnMap;
@property (nonatomic) OAProfileMapMarkersMode *mapMarkersMode;

@property (assign, nonatomic) BOOL simulateRouting;
@property (assign, nonatomic) BOOL useOsmLiveForRouting;

@property (nonatomic, readonly) NSSet<CLLocation *> *impassableRoads;

- (void) addImpassableRoad:(CLLocation *)location;
- (void) removeImpassableRoad:(CLLocation *)location;
- (void) clearImpassableRoads;

- (void) showGpx:(NSArray<NSString *> *)fileNames;
- (void) updateGpx:(NSArray<NSString *> *)fileNames;
- (void) hideGpx:(NSArray<NSString *> *)fileNames;
- (void) hideRemovedGpx;

- (NSString *) getFormattedTrackInterval:(int)value;
- (NSString *) getDefaultVoiceProvider;

- (void) setTrackMinDistance:(float)saveTrackMinDistance;
- (void) setTrackPrecision:(float)trackPrecision;
- (void) setTrackMinSpeed:(float)trackMinSpeeed;

- (NSSet<NSString *> *) getEnabledPlugins;
- (NSSet<NSString *> *) getPlugins;
- (void) enablePlugin:(NSString *)pluginId enable:(BOOL)enable;

@end
