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

#define VOICE_PROVIDER_NOT_USE @"VOICE_PROVIDER_NOT_USE"

#define settingShowMapRuletKey @"settingShowMapRuletKey"
#define settingAppModeKey @"settingAppModeKey"
#define settingMetricSystemKey @"settingMetricSystemKey"
#define settingDrivingRegionKey @"settingDrivingRegion"
#define settingZoomButtonKey @"settingZoomButtonKey"
#define settingGeoFormatKey @"settingGeoFormatKey"
#define settingMapArrowsKey @"settingMapArrowsKey"
#define settingMapShowAltInDriveModeKey @"settingMapShowAltInDriveModeKey"
#define settingDoNotShowPromotionsKey @"settingDoNotShowPromotionsKey"
#define settingDoNotUseFirebaseKey @"settingDoNotUseFirebaseKey"


#define mapSettingShowFavoritesKey @"mapSettingShowFavoritesKey"
#define mapSettingVisibleGpxKey @"mapSettingVisibleGpxKey"

#define mapSettingTrackRecordingKey @"mapSettingTrackRecordingKey"
#define mapSettingSaveTrackIntervalKey @"mapSettingSaveTrackIntervalKey"
#define mapSettingSaveTrackIntervalGlobalKey @"mapSettingSaveTrackIntervalGlobalKey"

#define mapSettingShowRecordingTrackKey @"mapSettingShowRecordingTrackKey"
#define mapSettingRecordingIntervalKey @"mapSettingRecordingIntervalKey"

#define mapSettingSaveTrackIntervalApprovedKey @"mapSettingSaveTrackIntervalApprovedKey"

#define settingMapLanguageKey @"settingMapLanguageKey"
#define settingPrefMapLanguageKey @"settingPrefMapLanguageKey"
#define settingMapLanguageShowLocalKey @"settingMapLanguageShowLocalKey"
#define settingMapLanguageTranslitKey @"settingMapLanguageTranslitKey"

#define mapSettingActiveRouteFileNameKey @"mapSettingActiveRouteFileNameKey"
#define mapSettingActiveRouteVariantTypeKey @"mapSettingActiveRouteVariantTypeKey"

#define selectedPoiFiltersKey @"selectedPoiFiltersKey"

#define discountIdKey @"discountId"
#define discountShowNumberOfStartsKey @"discountShowNumberOfStarts"
#define discountTotalShowKey @"discountTotalShow"
#define discountShowDatetimeKey @"discountShowDatetime"

#define lastSearchedCityKey @"lastSearchedCity"
#define lastSearchedCityNameKey @"lastSearchedCityName"
#define lastSearchedPointLatKey @"lastSearchedPointLat"
#define lastSearchedPointLonKey @"lastSearchedPointLon"

#define defaultApplicationModeKey @"defaultApplicationMode"

// navigation settings
#define useFastRecalculationKey @"useFastRecalculation"
#define fastRouteModeKey @"fastRouteMode"
#define disableComplexRoutingKey @"disableComplexRouting"
#define followTheRouteKey @"followTheRoute"
#define followTheGpxRouteKey @"followTheGpxRoute"
#define arrivalDistanceFactorKey @"arrivalDistanceFactor"
#define useIntermediatePointsNavigationKey @"useIntermediatePointsNavigation"
#define disableOffrouteRecalcKey @"disableOffrouteRecalc"
#define disableWrongDirectionRecalcKey @"disableWrongDirectionRecalc"
#define routerServiceKey @"routerService"
#define announceNearbyFavoritesKey @"announceNearbyFavorites"

#define voiceMuteKey @"voiceMute"
#define voiceProviderKey @"voiceProvider"
#define interruptMusicKey @"interruptMusic"

#define gpxRouteCalcOsmandPartsKey @"gpxRouteCalcOsmandParts"
#define gpxCalculateRteptKey @"gpxCalculateRtept"
#define gpxRouteCalcKey @"gpxRouteCalc"


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

+ (instancetype)withMetricConstant:(EOAMetricsConstant)mc;

+ (NSString *) toHumanString:(EOAMetricsConstant)mc;
+ (NSString *) toTTSString:(EOAMetricsConstant)mc;

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

+ (BOOL) isLeftHandDriving:(EOADrivingRegion)region;
+ (BOOL) isAmericanSigns:(EOADrivingRegion)region;
+ (EOAMetricsConstant) getDefMetrics:(EOADrivingRegion)region;
+ (NSString *) getName:(EOADrivingRegion)region;
+ (NSString *) getDescription:(EOADrivingRegion)region;

+ (EOADrivingRegion) getDefaultRegion;

@end

@interface OAProfileSetting : NSObject

@property (nonatomic, readonly) NSString *key;

@end

@interface OAProfileBoolean : OAProfileSetting

+ (instancetype) withKey:(NSString *)key defValue:(BOOL)defValue;

- (BOOL) get;
- (void) set:(BOOL)boolean;
- (BOOL) get:(OAMapVariantType)mode;
- (void) set:(BOOL)boolean mode:(OAMapVariantType)mode;

@end

@interface OAProfileInteger : OAProfileSetting

+ (instancetype) withKey:(NSString *)key defValue:(int)defValue;

- (int) get;
- (void) set:(int)integer;
- (int) get:(OAMapVariantType)mode;
- (void) set:(int)integer mode:(OAMapVariantType)mode;

@end

@interface OAProfileString : OAProfileSetting

+ (instancetype) withKey:(NSString *)key defValue:(NSString *)defValue;

- (NSString *) get;
- (void) set:(NSString *)string;
- (NSString *) get:(OAMapVariantType)mode;
- (void) set:(NSString *)string mode:(OAMapVariantType)mode;

@end

@interface OAProfileDouble : OAProfileSetting

+ (instancetype) withKey:(NSString *)key defValue:(double)defValue;

- (double) get;
- (void) set:(double)dbl;
- (double) get:(OAMapVariantType)mode;
- (void) set:(double)dbl mode:(OAMapVariantType)mode;

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

#define SAVE_TRACK_INTERVAL_DEFAULT 0

#define MAP_GEO_FORMAT_DEGREES 0
#define MAP_GEO_FORMAT_MINUTES 1

@property (nonatomic, readonly) NSArray *trackIntervalArray;
@property (nonatomic, readonly) NSArray *mapLanguages;
@property (nonatomic, readonly) NSArray *ttsAvailableVoices;


@property (assign, nonatomic) int settingAppMode; // 0 - Day; 1 - Night; 2 - Auto
@property (assign, nonatomic) EOAMetricsConstant settingMetricSystem;
@property (assign, nonatomic) EOADrivingRegion settingDrivingRegion;
@property (assign, nonatomic) BOOL settingShowZoomButton;
@property (assign, nonatomic) int settingGeoFormat; // 0 - degrees, 1 - minutes/seconds
@property (assign, nonatomic) BOOL settingShowAltInDriveMode;

@property (assign, nonatomic) int settingMapArrows; // 0 - from Location; 1 - from Map Center
@property (assign, nonatomic) CLLocationCoordinate2D mapCenter;

@property (assign, nonatomic) BOOL mapSettingShowFavorites;
@property (nonatomic) NSArray *mapSettingVisibleGpx;

@property (assign, nonatomic) BOOL mapSettingTrackRecording;
@property (assign, nonatomic) int mapSettingSaveTrackInterval;
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

@property (nonatomic) EOAMetricsConstant metricSystem;
@property (nonatomic) EOADrivingRegion drivingRegion;

- (OAProfileBoolean *) getCustomRoutingBooleanProperty:(NSString *)attrName defaultValue:(BOOL)defaultValue;
- (OAProfileString *) getCustomRoutingProperty:(NSString *)attrName defaultValue:(NSString *)defaultValue;

@property (nonatomic) NSString* defaultApplicationMode;
@property (nonatomic) NSString* lastRoutingApplicationMode;

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
@property (nonatomic) OAProfileBoolean *announceNearbyFavorites;

- (void) showGpx:(NSArray<NSString *> *)fileNames;
- (void) updateGpx:(NSArray<NSString *> *)fileNames;
- (void) hideGpx:(NSArray<NSString *> *)fileNames;
- (void) hideRemovedGpx;

- (NSString *) getFormattedTrackInterval:(int)value;
- (NSString *) getDefaultVoiceProvider;

@end
