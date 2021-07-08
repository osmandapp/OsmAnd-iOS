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

typedef NS_ENUM(NSInteger, EOAWikiArticleShowConstant)
{
    EOAWikiArticleShowConstantOn = 0,
    EOAWikiArticleShowConstantOff,
    EOAWikiArticleShowConstantWiFi
};

@interface OAWikiArticleShowConstant : NSObject

@property (nonatomic, readonly) EOAWikiArticleShowConstant wasc;

+ (instancetype) withWikiArticleShowConstant:(EOAWikiArticleShowConstant)wasc;

+ (NSString *) toHumanString:(EOAWikiArticleShowConstant)wasc;

@end

typedef NS_ENUM(NSInteger, EOAGradientScaleType)
{
    EOAGradientScaleTypeSpeed = 0,
    EOAGradientScaleTypeAltitude,
    EOAGradientScaleTypeSlope,
    EOAGradientScaleTypeNone
};

@interface OAGradientScaleType : NSObject

@property (nonatomic, readonly) EOAGradientScaleType gst;

+ (instancetype) withGradientScaleType:(EOAGradientScaleType)gst;

+ (NSString *) toHumanString:(EOAGradientScaleType)gst;
+ (NSString *) toTypeName:(EOAGradientScaleType)gst;
+ (NSString *) toColorTypeName:(EOAGradientScaleType)gst;

@end

typedef NS_ENUM(NSInteger, EOAUploadVisibility)
{
    EOAUploadVisibilityPublic = 0,
    EOAUploadVisibilityIdentifiable,
    EOAUploadVisibilityTrackable,
    EOAUploadVisibilityPrivate
};

@interface OAUploadVisibility : NSObject

@property (nonatomic, readonly) EOAUploadVisibility uv;

+ (instancetype) withUploadVisibility:(EOAUploadVisibility)uv;

+ (NSString *) toTitle:(EOAUploadVisibility)uv;
+ (NSString *) toDescription:(EOAUploadVisibility)uv;

@end

typedef NS_ENUM(NSInteger, EOACoordinateInputFormats)
{
    EOACoordinateInputFormatsDdMmMmm = 0,
    EOACoordinateInputFormatsDdMmMmmm,
    EOACoordinateInputFormatsDdDdddd,
    EOACoordinateInputFormatsDdDddddd,
    EOACoordinateInputFormatsDdMmSs
};

@interface OACoordinateInputFormats : NSObject

@property (nonatomic, readonly) EOACoordinateInputFormats cif;

+ (instancetype) withUploadVisibility:(EOACoordinateInputFormats)cif;

+ (NSString *) toHumanString:(EOACoordinateInputFormats)cif;
+ (BOOL) containsThirdPart:(EOACoordinateInputFormats)cif;
+ (int) toSecondPartSymbolsCount:(EOACoordinateInputFormats)cif;
+ (int) toThirdPartSymbolsCount:(EOACoordinateInputFormats)cif;
+ (NSString *) toFirstSeparator:(EOACoordinateInputFormats)cif;
+ (NSString *) toSecondSeparator:(EOACoordinateInputFormats)cif;

@end

@interface OACommonPreference : NSObject

@property (nonatomic, readonly) NSString *key;
@property (nonatomic, readonly) BOOL global;
@property (nonatomic, readonly) BOOL shared;

- (id) makeGlobal;
- (id) makeShared;

- (NSObject *) getProfileDefaultValue:(OAApplicationMode *)mode;
- (void) resetModeToDefault:(OAApplicationMode *)mode;
- (void) resetToDefault;
- (void) setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode;
- (NSString *) toStringValue:(OAApplicationMode *)mode;
- (void) copyValueFromAppMode:(OAApplicationMode *)sourceAppMode targetAppMode:(OAApplicationMode *)targetAppMode;

@end

@interface OACommonAppMode : OACommonPreference

+ (instancetype) withKey:(NSString *)key defValue:(OAApplicationMode *)defValue;

- (OAApplicationMode *) get;
- (OAApplicationMode *) get:(OAApplicationMode *)mode;
- (void) set:(OAApplicationMode *)appMode;
- (void) set:(OAApplicationMode *)appMode mode:(OAApplicationMode *)mode;

@end

@interface OACommonBoolean : OACommonPreference

+ (instancetype) withKey:(NSString *)key defValue:(BOOL)defValue;

- (BOOL) get;
- (BOOL) get:(OAApplicationMode *)mode;
- (void) set:(BOOL)boolean;
- (void) set:(BOOL)boolean mode:(OAApplicationMode *)mode;

@end

@interface OACommonInteger : OACommonPreference

+ (instancetype) withKey:(NSString *)key defValue:(int)defValue;

- (int) get;
- (int) get:(OAApplicationMode *)mode;
- (void) set:(int)integer;
- (void) set:(int)integer mode:(OAApplicationMode *)mode;

@end

@interface OACommonLong : OACommonPreference

+ (instancetype) withKey:(NSString *)key defValue:(long)defValue;

- (long) get;
- (long) get:(OAApplicationMode *)mode;
- (void) set:(long)_long;
- (void) set:(long)_long mode:(OAApplicationMode *)mode;

@end

@interface OACommonString : OACommonPreference

+ (instancetype) withKey:(NSString *)key defValue:(NSString *)defValue;

- (NSString *) get;
- (void) set:(NSString *)string;
- (NSString *) get:(OAApplicationMode *)mode;
- (void) set:(NSString *)string mode:(OAApplicationMode *)mode;

@end

@interface OACommonDouble : OACommonPreference

+ (instancetype) withKey:(NSString *)key defValue:(double)defValue;

- (double) get;
- (double) get:(OAApplicationMode *)mode;
- (void) set:(double)dbl;
- (void) set:(double)dbl mode:(OAApplicationMode *)mode;

@end

@interface OACommonStringList : OACommonPreference

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

@interface OACommonMapSource : OACommonPreference

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

@interface OACommonTerrain : OACommonInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOATerrainType)defValue;

- (EOATerrainType) get;
- (EOATerrainType) get:(OAApplicationMode *)mode;
- (void) set:(EOATerrainType)autoZoomMap;
- (void) set:(EOATerrainType)autoZoomMap mode:(OAApplicationMode *)mode;

@end

@interface OACommonAutoZoomMap : OACommonInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOAAutoZoomMap)defValue;

- (EOAAutoZoomMap) get;
- (EOAAutoZoomMap) get:(OAApplicationMode *)mode;
- (void) set:(EOAAutoZoomMap)autoZoomMap;
- (void) set:(EOAAutoZoomMap)autoZoomMap mode:(OAApplicationMode *)mode;

@end

@interface OACommonSpeedConstant : OACommonInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOASpeedConstant)defValue;

- (EOASpeedConstant) get;
- (EOASpeedConstant) get:(OAApplicationMode *)mode;
- (void) set:(EOASpeedConstant)speedConstant;
- (void) set:(EOASpeedConstant)speedConstant mode:(OAApplicationMode *)mode;

@end

@interface OACommonAngularConstant : OACommonInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOAAngularConstant)defValue;

- (EOAAngularConstant) get;
- (EOAAngularConstant) get:(OAApplicationMode *)mode;
- (void) set:(EOAAngularConstant)angularConstant;
- (void) set:(EOAAngularConstant)angularConstant mode:(OAApplicationMode *)mode;

@end

typedef NS_ENUM(NSInteger, EOAActiveMarkerConstant)
{
    ONE_ACTIVE_MARKER = 0,
    TWO_ACTIVE_MARKERS
};

@interface OACommonActiveMarkerConstant : OACommonInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOAActiveMarkerConstant)defValue;

- (EOAActiveMarkerConstant) get;
- (EOAActiveMarkerConstant) get:(OAApplicationMode *)mode;
- (void) set:(EOAActiveMarkerConstant)activeMarkerConstant;
- (void) set:(EOAActiveMarkerConstant)activeMarkerConstant mode:(OAApplicationMode *)mode;

@end

typedef NS_ENUM(NSInteger, EOADistanceIndicationConstant)
{
    TOP_BAR_DISPLAY = 0,
    WIDGET_DISPLAY,
    NONE_DISPLAY
};

@interface OACommonDistanceIndicationConstant : OACommonInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOADistanceIndicationConstant)defValue;

- (EOADistanceIndicationConstant) get;
- (EOADistanceIndicationConstant) get:(OAApplicationMode *)mode;
- (void) set:(EOADistanceIndicationConstant)distanceIndicationConstant;
- (void) set:(EOADistanceIndicationConstant)distanceIndicationConstant mode:(OAApplicationMode *)mode;

@end

@interface OACommonDrivingRegion : OACommonInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOADrivingRegion)defValue;

- (EOADrivingRegion) get;
- (EOADrivingRegion) get:(OAApplicationMode *)mode;
- (void) set:(EOADrivingRegion)drivingRegionConstant;
- (void) set:(EOADrivingRegion)drivingRegionConstant mode:(OAApplicationMode *)mode;

@end

@interface OACommonMetricSystem : OACommonInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOAMetricsConstant)defValue;

- (EOAMetricsConstant) get;
- (EOAMetricsConstant) get:(OAApplicationMode *)mode;
- (void) set:(EOAMetricsConstant)metricsConstant;
- (void) set:(EOAMetricsConstant)metricsConstant mode:(OAApplicationMode *)mode;

@end

typedef NS_ENUM(NSInteger, EOARulerWidgetMode)
{
    RULER_MODE_DARK = 0,
    RULER_MODE_LIGHT,
    RULER_MODE_NO_CIRCLES
};

@interface OACommonRulerWidgetMode : OACommonInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOARulerWidgetMode)defValue;

- (EOARulerWidgetMode) get;
- (EOARulerWidgetMode) get:(OAApplicationMode *)mode;
- (void) set:(EOARulerWidgetMode)rulerWidgetMode;
- (void) set:(EOARulerWidgetMode)rulerWidgetMode mode:(OAApplicationMode *)mode;

@end

@interface OACommonWikiArticleShowImages : OACommonInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOAWikiArticleShowConstant)defValue;

- (EOAWikiArticleShowConstant) get;
- (EOAWikiArticleShowConstant) get:(OAApplicationMode *)mode;
- (void) set:(EOAWikiArticleShowConstant)wikiArticleShow;
- (void) set:(EOAWikiArticleShowConstant)wikiArticleShow mode:(OAApplicationMode *)mode;

@end

typedef NS_ENUM(NSInteger, EOARateUsState)
{
    EOARateUsStateInitialState = 0,
    EOARateUsStateIgnored,
    EOARateUsStateLiked,
    EOARateUsStateDislikedWithMessage,
    EOARateUsStateDislikedWithoutMessage,
    EOARateUsStateDislikedOrIgnoredAgain
};

@interface OACommonRateUsState : OACommonInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOARateUsState)defValue;

- (EOARateUsState) get;
- (EOARateUsState) get:(OAApplicationMode *)mode;
- (void) set:(EOARateUsState)rateUsState;
- (void) set:(EOARateUsState)rateUsState mode:(OAApplicationMode *)mode;

@end

@interface OACommonGradientScaleType : OACommonInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOAGradientScaleType)defValue;

- (EOAGradientScaleType) get;
- (EOAGradientScaleType) get:(OAApplicationMode *)mode;
- (void) set:(EOAGradientScaleType)gradientScaleType;
- (void) set:(EOAGradientScaleType)gradientScaleType mode:(OAApplicationMode *)mode;

@end

@interface OACommonUploadVisibility : OACommonInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOAUploadVisibility)defValue;

- (EOAUploadVisibility) get;
- (EOAUploadVisibility) get:(OAApplicationMode *)mode;
- (void) set:(EOAUploadVisibility)uploadVisibility;
- (void) set:(EOAUploadVisibility)uploadVisibility mode:(OAApplicationMode *)mode;

@end

@interface OACommonCoordinateInputFormats : OACommonInteger

+ (instancetype) withKey:(NSString *)key defValue:(EOACoordinateInputFormats)defValue;

- (EOACoordinateInputFormats) get;
- (EOACoordinateInputFormats) get:(OAApplicationMode *)mode;
- (void) set:(EOACoordinateInputFormats)coordinateInputFormats;
- (void) set:(EOACoordinateInputFormats)coordinateInputFormats mode:(OAApplicationMode *)mode;

@end

@interface OAAppSettings : NSObject

+ (OAAppSettings *)sharedManager;
@property (assign, nonatomic) BOOL settingShowMapRulet;

@property (nonatomic) OACommonInteger *settingMapLanguage;
@property (nonatomic) OACommonString *settingPrefMapLanguage;
@property (assign, nonatomic) BOOL settingMapLanguageShowLocal;
@property (nonatomic) OACommonBoolean *settingMapLanguageTranslit;

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
#define LAYER_TRANSPARENCY_SEEKBAR_MODE_UNDEFINED 3
#define LAYER_TRANSPARENCY_SEEKBAR_MODE_ALL 4

@property (nonatomic, readonly) NSArray *trackIntervalArray;
@property (nonatomic, readonly) NSArray *mapLanguages;
@property (nonatomic, readonly) NSArray *ttsAvailableVoices;
@property (nonatomic, readonly) NSArray *rtlLanguages;


@property (nonatomic) OACommonInteger *appearanceMode; // 0 - Day; 1 - Night; 2 - Auto
@property (readonly, nonatomic) BOOL nightMode;
@property (nonatomic) OACommonMetricSystem *metricSystem;
@property (nonatomic) OACommonBoolean *drivingRegionAutomatic;
@property (nonatomic) OACommonDrivingRegion *drivingRegion;
@property (assign, nonatomic) BOOL settingShowZoomButton;
@property (nonatomic) OACommonInteger *settingGeoFormat; // 0 - degrees, 1 - minutes/seconds
@property (assign, nonatomic) BOOL settingShowAltInDriveMode;
@property (nonatomic) OACommonBoolean *metricSystemChangedManually;
@property (nonatomic) OACommonBoolean *settingAllow3DView;

@property (assign, nonatomic) int settingMapArrows; // 0 - from Location; 1 - from Map Center
@property (assign, nonatomic) CLLocationCoordinate2D mapCenter;

@property (nonatomic) OACommonBoolean *mapSettingShowFavorites;
@property (nonatomic) OACommonBoolean *mapSettingShowPoiLabel;
@property (nonatomic) OACommonBoolean *mapSettingShowOfflineEdits;
@property (nonatomic) OACommonBoolean *mapSettingShowOnlineNotes;
@property (nonatomic) OACommonStringList *mapSettingVisibleGpx;
@property (nonatomic) OACommonInteger *layerTransparencySeekbarMode; // 0 - overlay, 1 - underlay, 2 - off, 3 - undefined, 4 - overlay&underlay
- (BOOL) getOverlayOpacitySliderVisibility;
- (BOOL) getUnderlayOpacitySliderVisibility;
- (void) setOverlayOpacitySliderVisibility:(BOOL)visibility;
- (void) setUnderlayOpacitySliderVisibility:(BOOL)visibility;

@property (nonatomic) OACommonString *billingUserId;
@property (nonatomic) OACommonString *billingUserName;
@property (nonatomic) OACommonString *billingUserToken;
@property (nonatomic) OACommonString *billingUserEmail;
@property (nonatomic) OACommonString *billingUserCountry;
@property (nonatomic) OACommonString *billingUserCountryDownloadName;
@property (nonatomic) OACommonBoolean *billingHideUserName;
@property (nonatomic) OACommonBoolean *billingPurchaseTokenSent;
@property (nonatomic) OACommonString *billingPurchaseTokensSent;
@property (nonatomic) OACommonDouble *liveUpdatesPurchaseCancelledTime;
@property (nonatomic) OACommonBoolean *liveUpdatesPurchaseCancelledFirstDlgShown;
@property (nonatomic) OACommonBoolean *liveUpdatesPurchaseCancelledSecondDlgShown;
@property (nonatomic) OACommonBoolean *fullVersionPurchased;
@property (nonatomic) OACommonBoolean *depthContoursPurchased;
@property (nonatomic) OACommonBoolean *contourLinesPurchased;
@property (nonatomic) OACommonBoolean *emailSubscribed;
@property (nonatomic) OACommonBoolean *osmandProPurchased;
@property (nonatomic) OACommonBoolean *osmandMapsPurchased;
@property (nonatomic, assign) BOOL displayDonationSettings; //global ?
@property (nonatomic) NSDate* lastReceiptValidationDate; //global ?
@property (nonatomic, assign) BOOL eligibleForIntroductoryPrice; //global ?
@property (nonatomic, assign) BOOL eligibleForSubscriptionOffer; //global ?

// Track recording settings
@property (nonatomic) OACommonBoolean *saveTrackToGPX;
@property (nonatomic) OACommonInteger *mapSettingSaveTrackInterval;
@property (nonatomic) OACommonDouble *saveTrackMinDistance;
@property (nonatomic) OACommonDouble *saveTrackPrecision;
@property (nonatomic) OACommonDouble *saveTrackMinSpeed;
@property (nonatomic) OACommonBoolean *autoSplitRecording;


@property (assign, nonatomic) BOOL mapSettingTrackRecording;

@property (nonatomic) OACommonBoolean *mapSettingSaveGlobalTrackToGpx;
@property (nonatomic) OACommonInteger *mapSettingSaveTrackIntervalGlobal;
@property (nonatomic) OACommonBoolean *mapSettingSaveTrackIntervalApproved;
@property (nonatomic) OACommonBoolean *mapSettingShowRecordingTrack;
@property (nonatomic) OACommonBoolean *mapSettingShowTripRecordingStartDialog;

@property (nonatomic) NSString* mapSettingActiveRouteFilePath;
@property (nonatomic) int mapSettingActiveRouteVariantType;

@property (nonatomic) OACommonString *selectedPoiFilters;

@property (nonatomic) OACommonInteger *discountId;
@property (nonatomic) OACommonInteger *discountShowNumberOfStarts;
@property (nonatomic) OACommonInteger *discountTotalShow;
@property (nonatomic) OACommonDouble *discountShowDatetime;

@property (nonatomic) unsigned long long lastSearchedCity;
@property (nonatomic) NSString* lastSearchedCityName;
@property (nonatomic) CLLocation *lastSearchedPoint;

@property (nonatomic) OACommonBoolean *settingDoNotShowPromotions;
@property (nonatomic) OACommonBoolean *settingUseAnalytics;
@property (nonatomic) OACommonInteger *settingExternalInputDevice; // 0 - None, 1 - Generic, 2 - WunderLINQ

@property (nonatomic) OACommonBoolean *liveUpdatesPurchased;
@property (nonatomic) OACommonBoolean *settingOsmAndLiveEnabled;
@property (nonatomic) OACommonInteger *liveUpdatesRetries;

- (OACommonBoolean *)getCustomRoutingBooleanProperty:(NSString *)attrName defaultValue:(BOOL)defaultValue;
- (OACommonString *)getCustomRoutingProperty:(NSString *)attrName defaultValue:(NSString *)defaultValue;

@property (nonatomic) NSArray<NSString *> *appModeBeanPrefsIds;
@property (nonatomic) OAApplicationMode *currentMode;
@property (nonatomic) OACommonAppMode *applicationMode;
@property (nonatomic) OACommonString *availableApplicationModes;
@property (nonatomic) OACommonAppMode *defaultApplicationMode;
@property (nonatomic) OACommonAppMode *carPlayMode;
@property (nonatomic) OACommonBoolean *isCarPlayModeDefault;
@property (nonatomic) OAApplicationMode *lastRoutingApplicationMode;
@property (nonatomic) OACommonInteger *rotateMap;

// Application mode related settings
@property (nonatomic) OACommonString *profileIconName;
@property (nonatomic) OACommonInteger *profileIconColor;
@property (nonatomic) OACommonString *userProfileName;
@property (nonatomic) OACommonString *parentAppMode;
@property (nonatomic) OACommonInteger *navigationIcon;
@property (nonatomic) OACommonInteger *locationIcon;
@property (nonatomic) OACommonInteger *appModeOrder;

@property (nonatomic) OACommonDouble *defaultSpeed;
@property (nonatomic) OACommonDouble *minSpeed;
@property (nonatomic) OACommonDouble *maxSpeed;
@property (nonatomic) OACommonDouble *routeStraightAngle;
@property (nonatomic) OACommonInteger *routerService;

@property (nonatomic) OACommonString *routingProfile;

@property (nonatomic) OACommonString *customAppModes;

@property (nonatomic) OACommonDouble *mapDensity;
@property (nonatomic) OACommonDouble *textSize;

@property (nonatomic) OACommonString *mapInfoControls;
@property (nonatomic) OACommonStringList *plugins;
@property (assign, nonatomic) BOOL firstMapIsDownloaded;

@property (nonatomic) OACommonString *renderer;

// navigation settings
@property (assign, nonatomic) BOOL useFastRecalculation;
@property (nonatomic) OACommonBoolean *fastRouteMode;
@property (assign, nonatomic) BOOL disableComplexRouting;
@property (nonatomic) OACommonBoolean *followTheRoute;
@property (nonatomic) OACommonString *followTheGpxRoute;
@property (nonatomic) OACommonBoolean *enableTimeConditionalRouting;
@property (nonatomic) OACommonDouble *arrivalDistanceFactor;
@property (nonatomic) OACommonBoolean *useIntermediatePointsNavigation;
@property (nonatomic) OACommonBoolean *disableOffrouteRecalc;
@property (nonatomic) OACommonBoolean *disableWrongDirectionRecalc;
@property (nonatomic) OACommonBoolean *gpxRouteCalcOsmandParts;
@property (nonatomic) OACommonBoolean *gpxCalculateRtept;
@property (nonatomic) OACommonBoolean *gpxRouteCalc;
@property (nonatomic) OACommonInteger *gpxRouteSegment;
@property (nonatomic) OACommonBoolean *showStartFinishIcons;
@property (nonatomic) OACommonBoolean *voiceMute;
@property (nonatomic) OACommonString *voiceProvider;
@property (nonatomic) OACommonBoolean *interruptMusic;
@property (nonatomic) OACommonBoolean *snapToRoad;
@property (nonatomic) OACommonInteger *autoFollowRoute;
@property (nonatomic) OACommonBoolean *autoZoomMap;
@property (nonatomic) OACommonAutoZoomMap *autoZoomMapScale;
@property (nonatomic) OACommonInteger *keepInforming;
@property (nonatomic) OACommonSpeedConstant *speedSystem;
@property (nonatomic) OACommonAngularConstant *angularUnits;
@property (nonatomic) OACommonDouble *speedLimitExceedKmh;
@property (nonatomic) OACommonDouble *switchMapDirectionToCompass;
@property (nonatomic) OACommonDouble *routeRecalculationDistance;

@property (nonatomic) OACommonBoolean *showScreenAlerts;
@property (nonatomic) OACommonBoolean *showRoutingAlarms;
@property (nonatomic) OACommonBoolean *showTrafficWarnings;
@property (nonatomic) OACommonBoolean *showPedestrian;
@property (nonatomic) OACommonBoolean *showCameras;
@property (nonatomic) OACommonBoolean *showTunnels;
@property (nonatomic) OACommonBoolean *showLanes;
@property (nonatomic) OACommonBoolean *showArrivalTime;
@property (nonatomic) OACommonBoolean *showIntermediateArrivalTime;
@property (nonatomic) OACommonBoolean *showRelativeBearing;
@property (nonatomic) OACommonBoolean *showCompassControlRuler;
@property (nonatomic) OACommonBoolean *showCoordinatesWidget;
@property (nonatomic) NSArray<OAAvoidRoadInfo *> *impassableRoads;

@property (nonatomic) OACommonBoolean *speakStreetNames;
@property (nonatomic) OACommonBoolean *speakTrafficWarnings;
@property (nonatomic) OACommonBoolean *speakPedestrian;
@property (nonatomic) OACommonBoolean *speakSpeedLimit;
@property (nonatomic) OACommonBoolean *speakCameras;
@property (nonatomic) OACommonBoolean *speakTunnels;
@property (nonatomic) OACommonBoolean *announceNearbyFavorites;
@property (nonatomic) OACommonBoolean *announceNearbyPoi;

@property (nonatomic) OACommonBoolean *showGpxWpt;
@property (nonatomic) OACommonBoolean *announceWpt;
@property (nonatomic) OACommonBoolean *showNearbyFavorites;
@property (nonatomic) OACommonBoolean *showNearbyPoi;

@property (nonatomic) OACommonBoolean *transparentMapTheme;
@property (nonatomic) OACommonBoolean *showStreetName;
@property (nonatomic) OACommonBoolean *centerPositionOnMap;
@property (nonatomic) OACommonBoolean *showDistanceRuler;

@property (assign, nonatomic) BOOL simulateRouting;
@property (assign, nonatomic) BOOL useOsmLiveForRouting;

@property (nonatomic) OACommonRulerWidgetMode *rulerMode;

@property (nonatomic) OACommonStringList *poiFiltersOrder;
@property (nonatomic) OACommonStringList *inactivePoiFilters;

// OSM Editing
@property (nonatomic) OACommonString *osmUserName;
@property (nonatomic) OACommonString *osmUserPassword;
@property (nonatomic) OACommonString *osmUserAccessToken;
@property (nonatomic) OACommonString *osmUserAccessTokenSecret;
@property (nonatomic) OACommonString *oprAccessToken;
@property (nonatomic) OACommonString *oprUsername;
@property (nonatomic) OACommonString *oprBlockchainName;
@property (nonatomic) OACommonBoolean *oprUseDevUrl;
@property (nonatomic) OACommonBoolean *offlineEditing;
@property (nonatomic) OACommonBoolean *osmUseDevUrl;

// Mapillary
@property (nonatomic) OACommonBoolean *onlinePhotosRowCollapsed;
@property (nonatomic) OACommonBoolean *mapillaryFirstDialogShown;

@property (nonatomic) OACommonBoolean *useMapillaryFilter;
@property (nonatomic) OACommonString *mapillaryFilterUserKey;
@property (nonatomic) OACommonString *mapillaryFilterUserName;
@property (nonatomic) OACommonDouble *mapillaryFilterStartDate;
@property (nonatomic) OACommonDouble *mapillaryFilterEndDate;
@property (nonatomic) OACommonBoolean *mapillaryFilterPano;

// Quick Action
@property (nonatomic) OACommonBoolean *quickActionIsOn;
@property (nonatomic) OACommonString *quickActionsList;
@property (nonatomic) OACommonBoolean *isQuickActionTutorialShown;

@property (nonatomic, readonly) OACommonDouble *quickActionLandscapeX;
@property (nonatomic, readonly) OACommonDouble *quickActionLandscapeY;
@property (nonatomic, readonly) OACommonDouble *quickActionPortraitX;
@property (nonatomic, readonly) OACommonDouble *quickActionPortraitY;

// Contour Lines
@property (nonatomic) OACommonString *contourLinesZoom;

// Custom plugins
@property (nonatomic) NSString *customPluginsJson;

- (void) setApplicationModePref:(OAApplicationMode *)applicationMode;
- (void) setApplicationModePref:(OAApplicationMode *)applicationMode markAsLastUsed:(BOOL)markAsLastUsed;

- (void) setQuickActionCoordinatesPortrait:(float)x y:(float)y;
- (void) setQuickActionCoordinatesLandscape:(float)x y:(float)y;

- (void) setShowOnlineNotes:(BOOL)mapSettingShowOnlineNotes;
- (void) setShowOfflineEdits:(BOOL)mapSettingShowOfflineEdits;
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

- (NSMapTable<NSString *, OACommonPreference *> *)getPreferences:(BOOL)global;
- (OACommonPreference *)getGlobalPreference:(NSString *)key;
- (void)setGlobalPreference:(NSString *)value key:(NSString *)key;
- (OACommonPreference *)getProfilePreference:(NSString *)key;
- (void)setProfilePreference:(NSString *)value key:(NSString *)key;

- (NSMapTable<NSString *, OACommonPreference *> *)getRegisteredPreferences;
- (OACommonPreference *)getPreferenceByKey:(NSString *)key;
- (void)registerPreference:(OACommonPreference *)preference forKey:(NSString *)key;
- (void)resetPreferencesForProfile:(OAApplicationMode *)mode;

// Direction Appearance

@property (nonatomic) OACommonActiveMarkerConstant* activeMarkers;
@property (nonatomic) OACommonBoolean *distanceIndicationVisibility;
@property (nonatomic) OACommonDistanceIndicationConstant *distanceIndication;
@property (nonatomic) OACommonBoolean *arrowsOnMap;
@property (nonatomic) OACommonBoolean *directionLines;

// global

@property (nonatomic) OACommonBoolean *wikiArticleShowImagesAsked;
@property (nonatomic) OACommonWikiArticleShowImages *wikivoyageShowImgs;

@property (nonatomic) OACommonBoolean *coordsInputUseRightSide;
@property (nonatomic) OACommonCoordinateInputFormats *coordsInputFormat;
@property (nonatomic) OACommonBoolean *coordsInputUseOsmandKeyboard;
@property (nonatomic) OACommonBoolean *coordsInputTwoDigitsLongitude;

@property (nonatomic) OACommonBoolean *shouldShowDashboardOnStart;
@property (nonatomic) OACommonBoolean *showDashboardOnMapScreen;
@property (nonatomic) OACommonBoolean *showOsmandWelcomeScreen;
@property (nonatomic) OACommonBoolean *showCardToChooseDrawer;

@property (nonatomic) OACommonString *apiNavDrawerItemsJson;
@property (nonatomic) OACommonString *apiConnectedAppsJson;

@property (nonatomic) OACommonInteger *numberOfStartsFirstXmasShown;
@property (nonatomic) OACommonString *lastFavCategoryEntered;
@property (nonatomic) OACommonBoolean *useLastApplicationModeByDefault;
@property (nonatomic) OACommonString *lastUsedApplicationMode;
@property (nonatomic) OACommonAppMode * lastRouteApplicationMode;

@property (nonatomic) OACommonString *onlineRoutingEngines;

@property (nonatomic) OACommonBoolean *doNotShowStartupMessages;
@property (nonatomic) OACommonBoolean *showDownloadMapDialog;

@property (nonatomic) OACommonBoolean *sendAnonymousMapDownloadsData;
@property (nonatomic) OACommonBoolean *sendAnonymousAppUsageData;
@property (nonatomic) OACommonBoolean *sendAnonymousDataRequestProcessed;
@property (nonatomic) OACommonInteger *sendAnonymousDataRequestCount;
@property (nonatomic) OACommonInteger *sendAnonymousDataLastRequestNs;

@property (nonatomic) OACommonBoolean *webglSupported;

@property (nonatomic) OACommonString *osmUserDisplayName;
@property (nonatomic) OACommonUploadVisibility *osmUploadVisibility;

@property (nonatomic) OACommonBoolean *inappsRead;

@property (nonatomic) OACommonString *backupUserEmail;
@property (nonatomic) OACommonString *backupUserId;
@property (nonatomic) OACommonString *backupDeviceId;
@property (nonatomic) OACommonString *backupNativeDeviceId;
@property (nonatomic) OACommonString *backupAccessToken;
@property (nonatomic) OACommonString *backupAccessTokenUpdateTime;

@property (nonatomic) OACommonLong *favoritesLastUploadedTime;
@property (nonatomic) OACommonLong *backupLastUploadedTime;

@property (nonatomic) OACommonString *userOsmBugName;

@property (nonatomic) OACommonInteger *delayToStartNavigation;

@property (nonatomic) OACommonBoolean *enableProxy;
@property (nonatomic) OACommonString *proxyHost;
@property (nonatomic) OACommonInteger *proxyPort;
//@property (nonatomic) OACommonString *userAndroidId; //need ?

@property (nonatomic) OACommonBoolean *speedCamerasUninstalled;
@property (nonatomic) OACommonBoolean *speedCamerasAlertShowed;

@property (nonatomic) OACommonLong *lastUpdatesCardRefresh;

@property (nonatomic) OACommonInteger *currentTrackColor;
@property (nonatomic) OACommonGradientScaleType *currentTrackColorization;
@property (nonatomic) OACommonString *currentTrackSpeedGradientPalette;
@property (nonatomic) OACommonString *currentTrackAltitudeGradientPalette;
@property (nonatomic) OACommonString *currentTrackSlopeGradientPalette;
@property (nonatomic) OACommonString *currentTrackWidth;
@property (nonatomic) OACommonBoolean *currentTrackShowArrows;
@property (nonatomic) OACommonBoolean *currentTrackShowStartFinish;
@property (nonatomic) OACommonStringList *customTrackColors;

@property (nonatomic) OACommonString *gpsStatusApp;

@property (nonatomic) OACommonBoolean *debugRenderingInfo;

@property (nonatomic) OACommonInteger *levelToSwitchVectorRaster;

//@property (nonatomic) OACommonInteger *voicePromptDelay0;
//@property (nonatomic) OACommonInteger *voicePromptDelay3;
//@property (nonatomic) OACommonInteger *voicePromptDelay5;

@property (nonatomic) OACommonBoolean *displayTtsUtterance;

@property (nonatomic) OACommonString *mapOverlayPrevious;
@property (nonatomic) OACommonString *mapUnderlayPrevious;
@property (nonatomic) OACommonString *previousInstalledVersion;
@property (nonatomic) OACommonBoolean *shouldShowFreeVersionBanner;

@property (nonatomic) OACommonBoolean *routeMapMarkersStartMyLoc;
@property (nonatomic) OACommonBoolean *routeMapMarkersRoundTrip;

@property (nonatomic) OACommonLong *osmandUsageSpace;

@property (nonatomic) OACommonString *lastSelectedGpxTrackForNewPoint;

@property (nonatomic) OACommonStringList *customRouteLineColors;

@property (nonatomic) OACommonBoolean *mapActivityEnabled;

@property (nonatomic) OACommonBoolean *safeMode;
@property (nonatomic) OACommonBoolean *nativeRenderingFailed;

@property (nonatomic) OACommonBoolean *useOpenglRender;
@property (nonatomic) OACommonBoolean *openglRenderFailed;

@property (nonatomic) OACommonString *contributionInstallAppDate;

@property (nonatomic) OACommonString *selectedTravelBook;

@property (nonatomic) OACommonLong *agpsDataLastTimeDownloaded;

@property (nonatomic) OACommonInteger *searchTab;
@property (nonatomic) OACommonInteger *favoritesTab;

@property (nonatomic) OACommonBoolean *fluorescentOverlays;

@property (nonatomic) OACommonInteger *numberOfFreeDownloads;

@property (nonatomic) OACommonLong *lastDisplayTime;
@property (nonatomic) OACommonLong *lastCheckedUpdates;
@property (nonatomic) OACommonInteger *numberOfAppStartsOnDislikeMoment;
@property (nonatomic) OACommonRateUsState *rateUsState;

@end
