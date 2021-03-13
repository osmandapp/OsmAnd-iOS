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

#define mapDensityKey @"mapDensity"
#define textSizeKey @"textSize"

#define kBillingUserDonationNone @"none"
#define kSubscriptionHoldingTimeMsec 60.0 * 60.0 * 24.0 * 3.0 // 3 days
#define kReceiptValidationMinPeriod 60.0 * 60.0 * 24.0 * 1.0 // 1 day
#define kReceiptValidationMaxPeriod 60.0 * 60.0 * 24.0 * 30.0 // 30 days

@class OAAvoidRoadInfo, OAMapSource, OAMapLayersConfiguration;

typedef NS_ENUM(NSInteger, EOARouteService)
{
    OSMAND = 0,
    /*YOURS,
    OSRM,
    BROUTER,*/
    DIRECT_TO,
    STRAIGHT
};

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
+ (BOOL) imperial:(EOASpeedConstant)sc;

+ (NSString *) toHumanString:(EOASpeedConstant)sc;
+ (NSString *) toShortString:(EOASpeedConstant)sc;

@end

typedef NS_ENUM(NSInteger, EOAAngularConstant)
{
    DEGREES = 0,
    DEGREES360,
    MILLIRADS
};

@interface OAAngularConstant : NSObject

@property (nonatomic, readonly) EOAAngularConstant sc;
@property (nonatomic, readonly) NSString *key;
@property (nonatomic, readonly) NSString *descr;

+ (instancetype) withAngularConstant:(EOAAngularConstant)sc;
+ (NSArray<OAAngularConstant *> *) values;

+ (NSString *) toHumanString:(EOAAngularConstant)sc;
+ (NSString *) getUnitSymbol:(EOAAngularConstant)sc;

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

@interface OAProfileSetting : NSObject

@property (nonatomic, readonly) NSString *key;

- (NSObject *) getProfileDefaultValue:(OAApplicationMode *)mode;
- (void) resetModeToDefault:(OAApplicationMode *)mode;
- (void) resetToDefault;
- (void) setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode;
- (NSString *) toStringValue:(OAApplicationMode *)mode;
- (void) copyValueFromAppMode:(OAApplicationMode *)sourceAppMode targetAppMode:(OAApplicationMode *)targetAppMode;

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

@interface OAProfileStringList : OAProfileSetting

+ (instancetype) withKey:(NSString *)key defValue:(NSArray<NSString *> *)defValue;

- (NSArray<NSString *> *) get;
- (NSArray<NSString *> *) get:(OAApplicationMode *)mode;
- (void) set:(NSArray<NSString *> *)arr;
- (void) set:(NSArray<NSString *> *)arr mode:(OAApplicationMode *)mode;
- (void) add:(NSString *)string;
- (void) addUnique:(NSString *)string;
- (void) remove:(NSString *)string;
- (BOOL) contains:(NSString *)string;

@end

@interface OAProfileMapSource : OAProfileSetting

+ (instancetype) withKey:(NSString *)key defValue:(OAMapSource *)defValue;

- (OAMapSource *) get;
- (OAMapSource *) get:(OAApplicationMode *)mode;
- (void) set:(OAMapSource *)mapSource;
- (void) set:(OAMapSource *)mapSource mode:(OAApplicationMode *)mode;

@end

typedef NS_ENUM(NSInteger, EOATerrainType)
{
    EOATerrainTypeDisabled = 0,
    EOATerrainTypeHillshade,
    EOATerrainTypeSlope
};

@interface OAProfileTerrain : OAProfileInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOATerrainType)defValue;

- (EOATerrainType) get;
- (void) set:(EOATerrainType)autoZoomMap;
- (EOATerrainType) get:(OAApplicationMode *)mode;
- (void) set:(EOATerrainType)autoZoomMap mode:(OAApplicationMode *)mode;

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

@interface OAProfileAngularConstant : OAProfileInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOAAngularConstant)defValue;

- (EOAAngularConstant) get;
- (void) set:(EOAAngularConstant)angularConstant;
- (EOAAngularConstant) get:(OAApplicationMode *)mode;
- (void) set:(EOAAngularConstant)angularConstant mode:(OAApplicationMode *)mode;

@end

@interface OAProfileDrivingRegion : OAProfileInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOADrivingRegion)defValue;

- (EOADrivingRegion) get;
- (void) set:(EOADrivingRegion)drivingRegionConstant;
- (EOADrivingRegion) get:(OAApplicationMode *)mode;
- (void) set:(EOADrivingRegion)drivingRegionConstant mode:(OAApplicationMode *)mode;

@end

@interface OAProfileMetricSystem : OAProfileInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOAMetricsConstant)defValue;

- (EOAMetricsConstant) get;
- (void) set:(EOAMetricsConstant)metricsConstant;
- (EOAMetricsConstant) get:(OAApplicationMode *)mode;
- (void) set:(EOAMetricsConstant)metricsConstant mode:(OAApplicationMode *)mode;

@end

typedef NS_ENUM(NSInteger, EOAActiveMarkerConstant)
{
    ONE_ACTIVE_MARKER = 0,
    TWO_ACTIVE_MARKERS
};

typedef NS_ENUM(NSInteger, EOADistanceIndicationConstant)
{
    TOP_BAR_DISPLAY = 0,
    WIDGET_DISPLAY,
    NONE_DISPLAY
};

@interface OAProfileActiveMarkerConstant : OAProfileInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOAActiveMarkerConstant)defValue;

- (EOAActiveMarkerConstant) get;
- (void) set:(EOAActiveMarkerConstant)angularConstant;
- (EOAActiveMarkerConstant) get:(OAApplicationMode *)mode;
- (void) set:(EOAActiveMarkerConstant)angularConstant mode:(OAApplicationMode *)mode;

@end

@interface OAProfileDistanceIndicationConstant : OAProfileInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOADistanceIndicationConstant)defValue;

- (EOADistanceIndicationConstant) get;
- (void) set:(EOADistanceIndicationConstant)angularConstant;
- (EOADistanceIndicationConstant) get:(OAApplicationMode *)mode;
- (void) set:(EOADistanceIndicationConstant)angularConstant mode:(OAApplicationMode *)mode;

@end

typedef NS_ENUM(NSInteger, EOARulerWidgetMode)
{
    RULER_MODE_DARK = 0,
    RULER_MODE_LIGHT,
    RULER_MODE_NO_CIRCLES
};

@interface OAAppSettings : NSObject

+ (OAAppSettings *)sharedManager;
@property (assign, nonatomic) BOOL settingShowMapRulet;

@property (assign, nonatomic) int settingMapLanguage;
@property (nonatomic) NSString *settingPrefMapLanguage;
@property (assign, nonatomic) BOOL settingMapLanguageShowLocal;
@property (assign, nonatomic) BOOL settingMapLanguageTranslit;

@property (assign, nonatomic) BOOL shouldShowWhatsNewScreen;

#define APPEARANCE_MODE_DAY 0
#define APPEARANCE_MODE_NIGHT 1
#define APPEARANCE_MODE_AUTO 2

#define MAP_ARROWS_LOCATION 0
#define MAP_ARROWS_MAP_CENTER 1

#define SAVE_TRACK_INTERVAL_DEFAULT 5
#define REC_FILTER_DEFAULT 0.f

#define MAP_GEO_FORMAT_DEGREES 0
#define MAP_GEO_FORMAT_MINUTES 1
#define MAP_GEO_FORMAT_SECONDS 2
#define MAP_GEO_UTM_FORMAT 3
#define MAP_GEO_OLC_FORMAT 4

#define ROTATE_MAP_NONE 0
#define ROTATE_MAP_BEARING 1
#define ROTATE_MAP_COMPASS 2

#define NO_EXTERNAL_DEVICE 0
#define GENERIC_EXTERNAL_DEVICE 1
#define WUNDERLINQ_EXTERNAL_DEVICE 2

#define MAGNIFIER_DEFAULT_VALUE 1.0
#define MAGNIFIER_DEFAULT_CAR 1.5

#define LAYER_TRANSPARENCY_SEEKBAR_MODE_OVERLAY 0
#define LAYER_TRANSPARENCY_SEEKBAR_MODE_UNDERLAY 1
#define LAYER_TRANSPARENCY_SEEKBAR_MODE_OFF 2
#define LAYER_TRANSPARENCY_SEEKBAR_MODE_OVERLAY 3
#define LAYER_TRANSPARENCY_SEEKBAR_MODE_ALL 4

@property (nonatomic, readonly) NSArray *trackIntervalArray;
@property (nonatomic, readonly) NSArray *mapLanguages;
@property (nonatomic, readonly) NSArray *ttsAvailableVoices;
@property (nonatomic, readonly) NSArray *rtlLanguages;


@property (nonatomic) OAProfileInteger *appearanceMode; // 0 - Day; 1 - Night; 2 - Auto
@property (readonly, nonatomic) BOOL nightMode;
@property (nonatomic) OAProfileMetricSystem *metricSystem;
@property (nonatomic) OAProfileBoolean *drivingRegionAutomatic;
@property (nonatomic) OAProfileDrivingRegion *drivingRegion;
@property (assign, nonatomic) BOOL settingShowZoomButton;
@property (nonatomic) OAProfileInteger *settingGeoFormat; // 0 - degrees, 1 - minutes/seconds
@property (assign, nonatomic) BOOL settingShowAltInDriveMode;
@property (nonatomic) OAProfileBoolean *metricSystemChangedManually;
@property (nonatomic) OAProfileBoolean *settingAllow3DView;

@property (assign, nonatomic) int settingMapArrows; // 0 - from Location; 1 - from Map Center
@property (assign, nonatomic) CLLocationCoordinate2D mapCenter;

@property (nonatomic) OAProfileBoolean *mapSettingShowFavorites;
@property (nonatomic) OAProfileBoolean *mapSettingShowPoiLabel;
@property (nonatomic) OAProfileBoolean *mapSettingShowOfflineEdits;
@property (nonatomic) OAProfileBoolean *mapSettingShowOnlineNotes;
@property (nonatomic) NSArray *mapSettingVisibleGpx;
@property (nonatomic) OAProfileInteger *layerTransparencySeekbarMode; // 0 - overlay, 1 - underlay, 2 - off, 3 - undefined, 4 - overlay&underlay
- (BOOL) getOverlayOpacitySliderVisibility;
- (BOOL) getUnderlayOpacitySliderVisibility;
- (void) setOverlayOpacitySliderVisibility:(BOOL)visibility;
- (void) setUnderlayOpacitySliderVisibility:(BOOL)visibility;

@property (nonatomic) NSString *billingUserId;
@property (nonatomic) NSString *billingUserName;
@property (nonatomic) NSString *billingUserToken;
@property (nonatomic) NSString *billingUserEmail;
@property (nonatomic) NSString *billingUserCountry;
@property (nonatomic) NSString *billingUserCountryDownloadName;
@property (nonatomic, assign) BOOL billingHideUserName;
@property (nonatomic, assign) NSTimeInterval liveUpdatesPurchaseCancelledTime;
@property (nonatomic, assign) BOOL liveUpdatesPurchaseCancelledFirstDlgShown;
@property (nonatomic, assign) BOOL liveUpdatesPurchaseCancelledSecondDlgShown;
@property (nonatomic, assign) BOOL emailSubscribed;
@property (nonatomic, assign) BOOL displayDonationSettings;
@property (nonatomic) NSDate* lastReceiptValidationDate;
@property (nonatomic, assign) BOOL eligibleForIntroductoryPrice;
@property (nonatomic, assign) BOOL eligibleForSubscriptionOffer;

// Track recording settings
@property (nonatomic) OAProfileBoolean *saveTrackToGPX;
@property (nonatomic) OAProfileInteger *mapSettingSaveTrackInterval;
@property (nonatomic) OAProfileDouble *saveTrackMinDistance;
@property (nonatomic) OAProfileDouble *saveTrackPrecision;
@property (nonatomic) OAProfileDouble *saveTrackMinSpeed;
@property (nonatomic) OAProfileBoolean *autoSplitRecording;


@property (assign, nonatomic) BOOL mapSettingTrackRecording;
@property (nonatomic) OAProfileInteger *mapSettingSaveTrackIntervalGlobal;
@property (nonatomic) OAProfileBoolean *mapSettingSaveTrackIntervalApproved;

@property (assign, nonatomic) BOOL mapSettingShowRecordingTrack;

@property (nonatomic) NSString* mapSettingActiveRouteFilePath;
@property (nonatomic) int mapSettingActiveRouteVariantType;

@property (nonatomic) OAProfileString *selectedPoiFilters;

@property (nonatomic) NSInteger discountId;
@property (nonatomic) NSInteger discountShowNumberOfStarts;
@property (nonatomic) NSInteger discountTotalShow;
@property (nonatomic) double discountShowDatetime;

@property (nonatomic) unsigned long long lastSearchedCity;
@property (nonatomic) NSString* lastSearchedCityName;
@property (nonatomic) CLLocation *lastSearchedPoint;

@property (assign, nonatomic) BOOL settingDoNotShowPromotions;
@property (assign, nonatomic) BOOL settingUseAnalytics;
@property (nonatomic) OAProfileInteger *settingExternalInputDevice; // 0 - None, 1 - Generic, 2 - WunderLINQ

@property (assign, nonatomic) BOOL liveUpdatesPurchased;
@property (assign, nonatomic) BOOL settingOsmAndLiveEnabled;

- (OAProfileBoolean *) getCustomRoutingBooleanProperty:(NSString *)attrName defaultValue:(BOOL)defaultValue;
- (OAProfileString *) getCustomRoutingProperty:(NSString *)attrName defaultValue:(NSString *)defaultValue;

@property (nonatomic) NSArray<NSString *> *appModeBeanPrefsIds;
@property (nonatomic) OAApplicationMode* applicationMode;
@property (nonatomic) NSString* availableApplicationModes;
@property (nonatomic) OAApplicationMode* defaultApplicationMode;
@property (nonatomic) OAApplicationMode* lastRoutingApplicationMode;
@property (nonatomic) OAProfileInteger *rotateMap;

// Application mode related settings
@property (nonatomic) OAProfileString *profileIconName;
@property (nonatomic) OAProfileInteger *profileIconColor;
@property (nonatomic) OAProfileString *userProfileName;
@property (nonatomic) OAProfileString *parentAppMode;
@property (nonatomic) OAProfileInteger *navigationIcon;
@property (nonatomic) OAProfileInteger *locationIcon;
@property (nonatomic) OAProfileInteger *appModeOrder;

@property (nonatomic) OAProfileDouble *defaultSpeed;
@property (nonatomic) OAProfileDouble *minSpeed;
@property (nonatomic) OAProfileDouble *maxSpeed;
@property (nonatomic) OAProfileDouble *routeStraightAngle;
@property (nonatomic) OAProfileInteger *routerService;

@property (nonatomic) OAProfileString *routingProfile;

@property (nonatomic) NSString *customAppModes;

@property (nonatomic) OAProfileDouble *mapDensity;
@property (nonatomic) OAProfileDouble *textSize;

@property (nonatomic) OAProfileString *mapInfoControls;
@property (nonatomic) NSSet<NSString *> *plugins;
@property (assign, nonatomic) BOOL firstMapIsDownloaded;

@property (nonatomic) OAProfileString *renderer;

// navigation settings
@property (assign, nonatomic) BOOL useFastRecalculation;
@property (nonatomic) OAProfileBoolean *fastRouteMode;
@property (assign, nonatomic) BOOL disableComplexRouting;
@property (assign, nonatomic) BOOL followTheRoute;
@property (nonatomic) NSString *followTheGpxRoute;
@property (nonatomic) OAProfileBoolean *enableTimeConditionalRouting;
@property (nonatomic) OAProfileDouble *arrivalDistanceFactor;
@property (assign, nonatomic) BOOL useIntermediatePointsNavigation;
@property (nonatomic) OAProfileBoolean *disableOffrouteRecalc;
@property (nonatomic) OAProfileBoolean *disableWrongDirectionRecalc;
@property (assign, nonatomic) BOOL gpxRouteCalcOsmandParts;
@property (assign, nonatomic) BOOL gpxCalculateRtept;
@property (assign, nonatomic) BOOL gpxRouteCalc;
@property (nonatomic) NSInteger gpxRouteSegment;
@property (nonatomic) OAProfileBoolean *voiceMute;
@property (nonatomic) OAProfileString *voiceProvider;
@property (nonatomic) OAProfileBoolean *interruptMusic;
@property (nonatomic) OAProfileBoolean *snapToRoad;
@property (nonatomic) OAProfileInteger *autoFollowRoute;
@property (nonatomic) OAProfileBoolean *autoZoomMap;
@property (nonatomic) OAProfileAutoZoomMap *autoZoomMapScale;
@property (nonatomic) OAProfileInteger *keepInforming;
@property (nonatomic) OAProfileSpeedConstant *speedSystem;
@property (nonatomic) OAProfileAngularConstant *angularUnits;
@property (nonatomic) OAProfileDouble *speedLimitExceedKmh;
@property (nonatomic) OAProfileDouble *switchMapDirectionToCompass;
@property (nonatomic) OAProfileDouble *routeRecalculationDistance;

@property (nonatomic) OAProfileBoolean *showScreenAlerts;
@property (nonatomic) OAProfileBoolean *showRoutingAlarms;
@property (nonatomic) OAProfileBoolean *showTrafficWarnings;
@property (nonatomic) OAProfileBoolean *showPedestrian;
@property (nonatomic) OAProfileBoolean *showCameras;
@property (nonatomic) OAProfileBoolean *showTunnels;
@property (nonatomic) OAProfileBoolean *showLanes;
@property (nonatomic) OAProfileBoolean *showArrivalTime;
@property (nonatomic) OAProfileBoolean *showIntermediateArrivalTime;
@property (nonatomic) OAProfileBoolean *showRelativeBearing;
@property (nonatomic) OAProfileBoolean *showCompassControlRuler;
@property (nonatomic) NSArray<OAAvoidRoadInfo *> *impassableRoads;

@property (nonatomic) OAProfileBoolean *speakStreetNames;
@property (nonatomic) OAProfileBoolean *speakTrafficWarnings;
@property (nonatomic) OAProfileBoolean *speakPedestrian;
@property (nonatomic) OAProfileBoolean *speakSpeedLimit;
@property (nonatomic) OAProfileBoolean *speakCameras;
@property (nonatomic) OAProfileBoolean *speakTunnels;
@property (nonatomic) OAProfileBoolean *announceNearbyFavorites;
@property (nonatomic) OAProfileBoolean *announceNearbyPoi;

@property (assign, nonatomic) BOOL showGpxWpt;
@property (nonatomic) OAProfileBoolean *announceWpt;
@property (nonatomic) OAProfileBoolean *showNearbyFavorites;
@property (nonatomic) OAProfileBoolean *showNearbyPoi;

@property (nonatomic) OAProfileBoolean *transparentMapTheme;
@property (nonatomic) OAProfileBoolean *showStreetName;
@property (nonatomic) OAProfileBoolean *centerPositionOnMap;

@property (assign, nonatomic) BOOL simulateRouting;
@property (assign, nonatomic) BOOL useOsmLiveForRouting;

@property (nonatomic) EOARulerWidgetMode rulerMode;

@property (nonatomic) OAProfileStringList *poiFiltersOrder;
@property (nonatomic) OAProfileStringList *inactivePoiFilters;

// OSM Editing
@property (nonatomic) NSString *osmUserName;
@property (nonatomic) NSString *osmUserPassword;
@property (nonatomic) BOOL offlineEditing;

// Mapillary
@property (nonatomic) BOOL onlinePhotosRowCollapsed;
@property (nonatomic) BOOL mapillaryFirstDialogShown;

@property (nonatomic) BOOL useMapillaryFilter;
@property (nonatomic) NSString *mapillaryFilterUserKey;
@property (nonatomic) NSString *mapillaryFilterUserName;
@property (nonatomic) double mapillaryFilterStartDate;
@property (nonatomic) double mapillaryFilterEndDate;
@property (nonatomic) BOOL mapillaryFilterPano;

// Quick Action
@property (nonatomic) OAProfileBoolean *quickActionIsOn;
@property (nonatomic) NSString *quickActionsList;

@property (nonatomic, readonly) OAProfileDouble *quickActionLandscapeX;
@property (nonatomic, readonly) OAProfileDouble *quickActionLandscapeY;
@property (nonatomic, readonly) OAProfileDouble *quickActionPortraitX;
@property (nonatomic, readonly) OAProfileDouble *quickActionPortraitY;

// Contour Lines
@property (nonatomic) OAProfileString *contourLinesZoom;

- (OAProfileSetting *) getSettingById:(NSString *)stringId;

- (void) setQuickActionCoordinatesPortrait:(float)x y:(float)y;
- (void) setQuickActionCoordinatesLandscape:(float)x y:(float)y;

- (void) setShowOnlineNotes:(BOOL)mapSettingShowOnlineNotes;
- (void) setShowOfflineEdits:(BOOL)mapSettingShowOfflineEdits;
- (void) setAppearanceMode:(int)settingAppMode;
- (void) setShowFavorites:(BOOL)mapSettingShowFavorites;
- (void) setShowPoiLabel:(BOOL)mapSettingShowPoiLabel;

- (void) addImpassableRoad:(OAAvoidRoadInfo *)roadInfo;
- (void) updateImpassableRoad:(OAAvoidRoadInfo *)roadInfo;
- (BOOL) removeImpassableRoad:(CLLocation *)location;
- (void) clearImpassableRoads;

- (void) showGpx:(NSArray<NSString *> *)filePaths;
- (void) showGpx:(NSArray<NSString *> *)filePaths update:(BOOL)update;
- (void) updateGpx:(NSArray<NSString *> *)filePaths;
- (void) hideGpx:(NSArray<NSString *> *)filePaths;
- (void) hideGpx:(NSArray<NSString *> *)filePaths update:(BOOL)update;
- (void) hideRemovedGpx;

- (NSString *) getFormattedTrackInterval:(int)value;
- (NSString *) getDefaultVoiceProvider;

- (NSSet<NSString *> *) getEnabledPlugins;
- (NSSet<NSString *> *) getPlugins;
- (void) enablePlugin:(NSString *)pluginId enable:(BOOL)enable;

- (NSSet<NSString *> *) getCustomAppModesKeys;

- (void) registerPreference:(OAProfileSetting *)pref forKey:(NSString *)key;
- (NSMapTable<NSString *, OAProfileSetting *> *) getRegisteredSettings;
- (void) resetPreferencesForProfile:(OAApplicationMode *)appMode;

- (void) setupAppMode;

// Direction Appearance

@property (nonatomic) OAProfileActiveMarkerConstant* activeMarkers;
@property (nonatomic) OAProfileBoolean *distanceIndicationVisibility;
@property (nonatomic) OAProfileDistanceIndicationConstant *distanceIndication;
@property (nonatomic) OAProfileBoolean *arrowsOnMap;
@property (nonatomic) OAProfileBoolean *directionLines;

@end
