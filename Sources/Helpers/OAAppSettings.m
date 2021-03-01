//
//  OADebugSettings.m
//  OsmAnd
//
//  Created by AntonRogachevskiy on 10/16/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OADayNightHelper.h"
#import "OAColors.h"
#import "OANavigationIcon.h"
#import "OALocationIcon.h"
#import "OAAvoidRoadInfo.h"
#import "OAGPXDatabase.h"

#define settingShowMapRuletKey @"settingShowMapRuletKey"
#define metricSystemKey @"settingMetricSystemKey"
#define drivingRegionAutomaticKey @"drivingRegionAutomatic"
#define drivingRegionKey @"settingDrivingRegion"
#define settingZoomButtonKey @"settingZoomButtonKey"
#define settingGeoFormatKey @"settingGeoFormatKey"
#define settingMapArrowsKey @"settingMapArrowsKey"
#define settingMapShowAltInDriveModeKey @"settingMapShowAltInDriveModeKey"
#define settingEnable3DViewKey @"settingEnable3DView"
#define settingDoNotShowPromotionsKey @"settingDoNotShowPromotionsKey"
#define settingUseFirebaseKey @"settingUseFirebaseKey"
#define metricSystemChangedManuallyKey @"metricSystemChangedManuallyKey"
#define liveUpdatesPurchasedKey @"liveUpdatesPurchasedKey"
#define settingOsmAndLiveEnabledKey @"settingOsmAndLiveEnabledKey"
#define settingExternalInputDeviceKey @"settingExternalInputDeviceKey"

#define mapSettingShowFavoritesKey @"mapSettingShowFavoritesKey"
#define mapSettingShowPoiLabelKey @"mapSettingShowPoiLabelKey"
#define mapSettingShowOfflineEditsKey @"mapSettingShowOfflineEditsKey"
#define mapSettingShowOnlineNotesKey @"mapSettingShowOnlineNotesKey"
#define layerTransparencySeekbarModeKey @"layerTransparencySeekbarModeKey"
#define mapSettingVisibleGpxKey @"mapSettingVisibleGpxKey"

#define billingUserIdKey @"billingUserIdKey"
#define billingUserNameKey @"billingUserNameKey"
#define billingUserTokenKey @"billingUserTokenKey"
#define billingUserEmailKey @"billingUserEmailKey"
#define billingUserCountryKey @"billingUserCountryKey"
#define billingUserCountryDownloadNameKey @"billingUserCountryDownloadNameKey"
#define billingHideUserNameKey @"billingHideUserNameKey"
#define liveUpdatesPurchaseCancelledTimeKey @"liveUpdatesPurchaseCancelledTimeKey"
#define liveUpdatesPurchaseCancelledFirstDlgShownKey @"liveUpdatesPurchaseCancelledFirstDlgShownKey"
#define liveUpdatesPurchaseCancelledSecondDlgShownKey @"liveUpdatesPurchaseCancelledSecondDlgShownKey"
#define emailSubscribedKey @"emailSubscribedKey"
#define displayDonationSettingsKey @"displayDonationSettingsKey"
#define lastReceiptValidationDateKey @"lastReceiptValidationDateKey"
#define eligibleForIntroductoryPriceKey @"eligibleForIntroductoryPriceKey"
#define eligibleForSubscriptionOfferKey @"eligibleForSubscriptionOfferKey"
#define shouldShowWhatsNewScreenKey @"shouldShowWhatsNewScreenKey"

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

#define mapSettingActiveRouteFilePathKey @"mapSettingActiveRouteFilePathKey"
#define mapSettingActiveRouteVariantTypeKey @"mapSettingActiveRouteVariantTypeKey"

#define selectedPoiFiltersKey @"selectedPoiFiltersKey"
#define pluginsKey @"pluginsKey"
#define impassableRoadsKey @"impassableRoadsKey"

#define discountIdKey @"discountId"
#define discountShowNumberOfStartsKey @"discountShowNumberOfStarts"
#define discountTotalShowKey @"discountTotalShow"
#define discountShowDatetimeKey @"discountShowDatetime"

#define lastSearchedCityKey @"lastSearchedCity"
#define lastSearchedCityNameKey @"lastSearchedCityName"
#define lastSearchedPointLatKey @"lastSearchedPointLat"
#define lastSearchedPointLonKey @"lastSearchedPointLon"

#define applicationModeKey @"applicationMode"
#define defaultApplicationModeKey @"defaultApplicationMode"
#define availableApplicationModesKey @"availableApplicationModes"
#define customAppModesKey @"customAppModes"

#define mapInfoControlsKey @"mapInfoControls"
#define transparentMapThemeKey @"transparentMapTheme"
#define showStreetNameKey @"showStreetName"
#define centerPositionOnMapKey @"centerPositionOnMap"
#define rotateMapKey @"rotateMap"
#define firstMapIsDownloadedKey @"firstMapIsDownloaded"

// App profiles
#define appModeBeanPrefsIdsKey @"appModeBeanPrefsIds"
#define routingProfileKey @"routingProfile"
#define profileIconNameKey @"profileIconName"
#define profileIconColorKey @"profileIconColor"
#define userProfileNameKey @"userProfileName"
#define parentAppModeKey @"parentAppMode"
#define routeServiceKey @"routeService"
#define navigationIconKey @"navigationIcon"
#define locationIconKey @"locationIcon"
#define appModeOrderKey @"appModeOrder"
#define defaultSpeedKey @"defaultSpeed"
#define minSpeedKey @"minSpeed"
#define maxSpeedKey @"maxSpeed"
#define routeStraightAngleKey @"routeStraightAngle"

#define rendererKey @"renderer"

// navigation settings
#define useFastRecalculationKey @"useFastRecalculation"
#define fastRouteModeKey @"fastRouteMode"
#define disableComplexRoutingKey @"disableComplexRouting"
#define followTheRouteKey @"followTheRoute"
#define followTheGpxRouteKey @"followTheGpxRoute"
#define arrivalDistanceFactorKey @"arrivalDistanceFactor"
#define enableTimeConditionalRoutingKey @"enableTimeConditionalRouting"
#define useIntermediatePointsNavigationKey @"useIntermediatePointsNavigation"
#define disableOffrouteRecalcKey @"disableOffrouteRecalc"
#define disableWrongDirectionRecalcKey @"disableWrongDirectionRecalc"
#define routerServiceKey @"routerService"
#define snapToRoadKey @"snapToRoad"
#define autoFollowRouteKey @"autoFollowRoute"
#define autoZoomMapKey @"autoZoomMap"
#define autoZoomMapScaleKey @"autoZoomMapScale"
#define keepInformingKey @"keepInforming"
#define speedSystemKey @"speedSystem"
#define angularUnitsKey @"angularUnits"
#define speedLimitExceedKey @"speedLimitExceed"
#define switchMapDirectionToCompassKey @"switchMapDirectionToCompass"
#define showArrivalTimeKey @"showArrivalTime"
#define showIntermediateArrivalTimeKey @"showIntermediateArrivalTime"
#define showRelativeBearingKey @"showRelativeBearing"
#define routeRecalculationDistanceKey @"routeRecalculationDistance"
#define showCompassControlRulerKey @"showCompassRuler"

#define showRoutingAlarmsKey @"showRoutingAlarms"
#define showTrafficWarningsKey @"showTrafficWarnings"
#define showPedestrianKey @"showPedestrian"
#define showCamerasKey @"showCameras"
#define showTunnelsKey @"showTunnels"
#define showLanesKey @"showLanes"
#define showGpxWptKey @"showGpxWpt"
#define showNearbyFavoritesKey @"showNearbyFavorites"
#define showNearbyPoiKey @"showNearbyPoi"

#define speakStreetNamesKey @"speakStreetNames"
#define speakTrafficWarningsKey @"speakTrafficWarnings"
#define speakPedestrianKey @"speakPedestrian"
#define speakSpeedLimitKey @"speakSpeedLimit"
#define speakCamerasKey @"speakCameras"
#define announceWptKey @"announceWpt"
#define announceNearbyFavoritesKey @"announceNearbyFavorites"
#define announceNearbyPoiKey @"announceNearbyPoi"
#define speakTunnels @"speakTunnels"

#define voiceMuteKey @"voiceMute"
#define voiceProviderKey @"voiceProvider"
#define interruptMusicKey @"interruptMusic"
#define showScreenAlertsKey @"showScreenAlerts"

#define gpxRouteCalcOsmandPartsKey @"gpxRouteCalcOsmandParts"
#define gpxCalculateRteptKey @"gpxCalculateRtept"
#define gpxRouteCalcKey @"gpxRouteCalc"

#define simulateRoutingKey @"simulateRouting"
#define useOsmLiveForRoutingKey @"useOsmLiveForRouting"

#define saveTrackToGPXKey @"saveTrackToGPX"
#define saveTrackMinDistanceKey @"saveTrackMinDistance"
#define saveTrackPrecisionKey @"saveTrackPrecision"
#define saveTrackMinSpeedKey @"saveTrackMinSpeed"
#define autoSplitRecordingKey @"autoSplitRecording"

#define rulerModeKey @"rulerMode"

#define osmUserNameKey @"osm_user_name"
#define osmPasswordKey @"osm_pass"
#define offlineEditingKey @"offline_editing"

#define onlinePhotosRowCollapsedKey @"onlinePhotosRowCollapsed"
#define mapillaryFirstDialogShownKey @"mapillaryFirstDialogShown"
#define useMapillaryFilterKey @"useMapillaryFilter"
#define mapillaryFilterUserKeyKey @"mapillaryFilterUserKey"
#define mapillaryFilterUserNameKey @"mapillaryFilterUserName"
#define mapillaryFilterStartDateKey @"mapillaryFilterStartDate"
#define mapillaryFilterEndDateKey @"mapillaryFilterEndDate"
#define mapillaryFilterPanoKey @"mapillaryFilterPano"

#define quickActionIsOnKey @"qiuckActionIsOn"
#define quickActionsListKey @"quickActionsList"

#define quickActionLandscapeXKey @"quickActionLandscapeX"
#define quickActionLandscapeYKey @"quickActionLandscapeY"
#define quickActionPortraitXKey @"quickActionPortraitX"
#define quickActionPortraitYKey @"quickActionPortraitY"

#define contourLinesZoomKey @"contourLinesZoom"

#define activeMarkerKey @"activeMarkerKey"
#define mapDistanceIndicationVisabilityKey @"mapDistanceIndicationVisabilityKey"
#define mapDistanceIndicationKey @"mapDistanceIndicationKey"
#define mapArrowsOnMapKey @"mapArrowsOnMapKey"
#define mapDirectionLinesKey @"mapDirectionLinesKey"

#define poiFiltersOrderKey @"poi_filters_order"
#define inactivePoiFiltersKey @"inactive_poi_filters"

@interface OAMetricsConstant()

@property (nonatomic) EOAMetricsConstant mc;

@end

@implementation OAMetricsConstant

+ (instancetype)withMetricConstant:(EOAMetricsConstant)mc
{
    OAMetricsConstant *obj = [[OAMetricsConstant alloc] init];
    if (obj)
    {
        obj.mc = mc;
    }
    return obj;
}

+ (NSString *) toHumanString:(EOAMetricsConstant)mc
{
    switch (mc)
    {
        case KILOMETERS_AND_METERS:
            return OALocalizedString(@"si_km_m");
        case MILES_AND_FEET:
            return OALocalizedString(@"si_mi_feet");
        case MILES_AND_METERS:
            return OALocalizedString(@"si_mi_meters");
        case MILES_AND_YARDS:
            return OALocalizedString(@"si_mi_yard");
        case NAUTICAL_MILES:
            return OALocalizedString(@"si_nm");
            
        default:
            return @"";
    }
}

+ (NSString *) toTTSString:(EOAMetricsConstant)mc
{
    switch (mc)
    {
        case KILOMETERS_AND_METERS:
            return @"km-m";
        case MILES_AND_FEET:
            return @"mi-f";
        case MILES_AND_METERS:
            return @"mi-m";
        case MILES_AND_YARDS:
            return @"mi-y";
        case NAUTICAL_MILES:
            return @"nm";
            
        default:
            return @"";
    }
}

@end

@interface OASpeedConstant ()

@property (nonatomic) EOASpeedConstant sc;
@property (nonatomic) NSString *key;
@property (nonatomic) NSString *descr;

@end

@implementation OASpeedConstant

+ (instancetype) withSpeedConstant:(EOASpeedConstant)sc
{
    OASpeedConstant *obj = [[OASpeedConstant alloc] init];
    if (obj)
    {
        obj.sc = sc;
        obj.key = [self.class toShortString:sc];
        obj.descr = [self.class toHumanString:sc];
    }
    return obj;
}

+ (NSArray<OASpeedConstant *> *) values
{
    return @[ [OASpeedConstant withSpeedConstant:KILOMETERS_PER_HOUR],
              [OASpeedConstant withSpeedConstant:MILES_PER_HOUR],
              [OASpeedConstant withSpeedConstant:METERS_PER_SECOND],
              [OASpeedConstant withSpeedConstant:MINUTES_PER_MILE],
              [OASpeedConstant withSpeedConstant:MINUTES_PER_KILOMETER],
              [OASpeedConstant withSpeedConstant:NAUTICALMILES_PER_HOUR] ];
}

+ (BOOL) imperial:(EOASpeedConstant)sc
{
    switch (sc)
    {
        case KILOMETERS_PER_HOUR:
            return NO;
        case MILES_PER_HOUR:
            return YES;
        case METERS_PER_SECOND:
            return NO;
        case MINUTES_PER_MILE:
            return YES;
        case MINUTES_PER_KILOMETER:
            return NO;
        case NAUTICALMILES_PER_HOUR:
            return YES;
            
        default:
            return NO;
    }
}

+ (NSString *) toHumanString:(EOASpeedConstant)sc
{
    switch (sc)
    {
        case KILOMETERS_PER_HOUR:
            return OALocalizedString(@"si_kmh");
        case MILES_PER_HOUR:
            return OALocalizedString(@"si_mph");
        case METERS_PER_SECOND:
            return OALocalizedString(@"si_m_s");
        case MINUTES_PER_MILE:
            return OALocalizedString(@"si_min_m");
        case MINUTES_PER_KILOMETER:
            return OALocalizedString(@"si_min_km");
        case NAUTICALMILES_PER_HOUR:
            return OALocalizedString(@"si_nm_h");
            
        default:
            return nil;
    }
}

+ (NSString *) toShortString:(EOASpeedConstant)sc
{
    switch (sc)
    {
        case KILOMETERS_PER_HOUR:
            return OALocalizedString(@"units_kmh");
        case MILES_PER_HOUR:
            return OALocalizedString(@"units_mph");
        case METERS_PER_SECOND:
            return OALocalizedString(@"m_s");
        case MINUTES_PER_MILE:
            return OALocalizedString(@"min_mile");
        case MINUTES_PER_KILOMETER:
            return OALocalizedString(@"min_km");
        case NAUTICALMILES_PER_HOUR:
            return OALocalizedString(@"nm_h");
            
        default:
            return nil;
    }
}

@end

@interface OAAngularConstant ()

@property (nonatomic) EOAAngularConstant ac;
@property (nonatomic) NSString *key;
@property (nonatomic) NSString *descr;

@end

@implementation OAAngularConstant

+ (instancetype) withAngularConstant:(EOAAngularConstant)ac
{
    OAAngularConstant *obj = [[OAAngularConstant alloc] init];
    if (obj)
    {
        obj.ac = ac;
        obj.key = [self.class toShortString:ac];
        obj.descr = [self.class getUnitSymbol:ac];
    }
    return obj;
}

+ (NSArray<OAAngularConstant *> *) values
{
    return @[ [OAAngularConstant withAngularConstant:DEGREES],
              [OAAngularConstant withAngularConstant:MILLIRADS] ];
}

+ (NSString *) toHumanString:(EOAAngularConstant)sc
{
    switch (sc)
    {
        case DEGREES:
            return OALocalizedString(@"sett_deg");
        case MILLIRADS:
            return OALocalizedString(@"shared_string_milliradians");
            
        default:
            return nil;
    }
}

+ (NSString *) getUnitSymbol:(EOAAngularConstant)sc
{
    switch (sc)
    {
        case DEGREES:
        case DEGREES360:
            return OALocalizedString(@"°");
        case MILLIRADS:
            return OALocalizedString(@"mil");
            
        default:
            return nil;
    }
}

@end

@interface OADrivingRegion()

@property (nonatomic) EOADrivingRegion region;

@end

@implementation OADrivingRegion

+ (instancetype)withRegion:(EOADrivingRegion)region
{
    OADrivingRegion *obj = [[OADrivingRegion alloc] init];
    if (obj)
    {
        obj.region = region;
    }
    return obj;
}

+ (NSArray<OADrivingRegion *> *) values
{
    return @[ [OADrivingRegion withRegion:DR_EUROPE_ASIA],
              [OADrivingRegion withRegion:DR_US],
              [OADrivingRegion withRegion:DR_CANADA],
              [OADrivingRegion withRegion:DR_UK_AND_OTHERS],
              [OADrivingRegion withRegion:DR_JAPAN],
              [OADrivingRegion withRegion:DR_AUSTRALIA] ];
}

+ (BOOL) isLeftHandDriving:(EOADrivingRegion)region
{
    return region == DR_UK_AND_OTHERS || region == DR_JAPAN || region == DR_AUSTRALIA;
}

+ (BOOL) isAmericanSigns:(EOADrivingRegion)region
{
    return region == DR_US || region == DR_CANADA || region == DR_AUSTRALIA;
}

+ (EOAMetricsConstant) getDefMetrics:(EOADrivingRegion)region
{
    switch (region)
    {
        case DR_EUROPE_ASIA:
            return KILOMETERS_AND_METERS;
        case DR_US:
            return MILES_AND_FEET;
        case DR_CANADA:
            return KILOMETERS_AND_METERS;
        case DR_UK_AND_OTHERS:
            return MILES_AND_METERS;
        case DR_JAPAN:
            return KILOMETERS_AND_METERS;
        case DR_AUSTRALIA:
            return KILOMETERS_AND_METERS;
            
        default:
            return KILOMETERS_AND_METERS;
    }
}

+ (NSString *) getName:(EOADrivingRegion)region
{
    switch (region) {
        case DR_EUROPE_ASIA:
            return OALocalizedString(@"driving_region_europe_asia");
        case DR_US:
            return OALocalizedString(@"driving_region_us");
        case DR_CANADA:
            return OALocalizedString(@"driving_region_canada");
        case DR_UK_AND_OTHERS:
            return OALocalizedString(@"driving_region_uk");
        case DR_JAPAN:
            return OALocalizedString(@"driving_region_japan");
        case DR_AUSTRALIA:
            return OALocalizedString(@"driving_region_australia");
            
        default:
            return @"";
    }
}

+ (NSString *) getDescription:(EOADrivingRegion)region
{
    return [NSString stringWithFormat:@"%@, %@", [OADrivingRegion isLeftHandDriving:region] ? OALocalizedString(@"left_side_navigation") : OALocalizedString(@"right_side_navigation"), [[OAMetricsConstant toHumanString:[OADrivingRegion getDefMetrics:region]] lowerCase]];
}

+ (EOADrivingRegion) getDefaultRegion
{
    NSLocale *locale = [NSLocale currentLocale];
    NSString *countryCode = [locale objectForKey:NSLocaleCountryCode];
    BOOL isMetricSystem = [[locale objectForKey:NSLocaleUsesMetricSystem] boolValue] && ![locale.localeIdentifier isEqualToString:@"en_GB"];
    
    if (!countryCode) {
        return DR_EUROPE_ASIA;
    }
    countryCode = [countryCode lowercaseString];
    if ([countryCode isEqualToString:@"us"]) {
        return DR_US;
    } else if ([countryCode isEqualToString:@"ca"]) {
        return DR_CANADA;
    } else if ([countryCode isEqualToString:@"jp"]) {
        return DR_JAPAN;
    } else if ([countryCode isEqualToString:@"au"]) {
        return DR_AUSTRALIA;
    } else if (!isMetricSystem) {
        return DR_UK_AND_OTHERS;
    }
    return DR_EUROPE_ASIA;
}

@end

@interface OAAutoZoomMap ()

@property (nonatomic) EOAAutoZoomMap autoZoomMap;
@property (nonatomic) float coefficient;
@property (nonatomic) NSString *name;
@property (nonatomic) float maxZoom;

@end

@implementation OAAutoZoomMap

+ (instancetype) withAutoZoomMap:(EOAAutoZoomMap)autoZoomMap
{
    OAAutoZoomMap *obj = [[OAAutoZoomMap alloc] init];
    if (obj)
    {
        obj.autoZoomMap = autoZoomMap;
        obj.coefficient = [self.class getCoefficient:autoZoomMap];
        obj.name = [self.class getName:autoZoomMap];
        obj.maxZoom = [self.class getMaxZoom:autoZoomMap];
    }
    return obj;
}

+ (NSArray<OAAutoZoomMap *> *) values
{
    return @[ [OAAutoZoomMap withAutoZoomMap:AUTO_ZOOM_MAP_FARTHEST],
              [OAAutoZoomMap withAutoZoomMap:AUTO_ZOOM_MAP_FAR],
              [OAAutoZoomMap withAutoZoomMap:AUTO_ZOOM_MAP_CLOSE] ];
}

+ (float) getCoefficient:(EOAAutoZoomMap)autoZoomMap
{
    switch (autoZoomMap)
    {
        case AUTO_ZOOM_MAP_FARTHEST:
            return 1.f;
        case AUTO_ZOOM_MAP_FAR:
            return 1.4f;
        case AUTO_ZOOM_MAP_CLOSE:
            return 2.f;
        default:
            return 0;
    }
}

+ (NSString *) getName:(EOAAutoZoomMap)autoZoomMap
{
    switch (autoZoomMap)
    {
        case AUTO_ZOOM_MAP_FARTHEST:
            return OALocalizedString(@"auto_zoom_farthest");
        case AUTO_ZOOM_MAP_FAR:
            return OALocalizedString(@"auto_zoom_far");
        case AUTO_ZOOM_MAP_CLOSE:
            return OALocalizedString(@"auto_zoom_close");
        default:
            return nil;
    }
}

+ (float) getMaxZoom:(EOAAutoZoomMap)autoZoomMap
{
    switch (autoZoomMap)
    {
        case AUTO_ZOOM_MAP_FARTHEST:
            return 15.5f;
        case AUTO_ZOOM_MAP_FAR:
            return 17.f;
        case AUTO_ZOOM_MAP_CLOSE:
            return 19.f;
        default:
            return 0;
    }
}

@end

@interface OAProfileSetting ()

@property (nonatomic, readonly) OAApplicationMode *appMode;
@property (nonatomic) NSString *key;
@property (nonatomic) NSMapTable<OAApplicationMode *, NSObject *> *cachedValues;
@property (nonatomic) NSMapTable<OAApplicationMode *, NSObject *> *defaultValues;

+ (instancetype) withKey:(NSString *)key;
- (NSObject *) getValue:(OAApplicationMode *)mode;
- (void) setValue:(NSObject *)value mode:(OAApplicationMode *)mode;

@end

@implementation OAProfileSetting

- (OAApplicationMode *) appMode
{
    return [OAAppSettings sharedManager].applicationMode;
}

- (NSString *) getModeKey:(NSString *)key mode:(OAApplicationMode *)mode
{
    return [NSString stringWithFormat:@"%@_%@", key, mode.stringKey];
}

+ (instancetype) withKey:(NSString *)key
{
    OAProfileSetting *obj = [[OAProfileSetting alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.cachedValues = [NSMapTable strongToStrongObjectsMapTable];
    }

    return obj;
}

- (NSObject *) getValue:(OAApplicationMode *)mode
{
    NSObject *cachedValue = [self.cachedValues objectForKey:mode];
    if (!cachedValue)
    {
        NSString *key = [self getModeKey:self.key mode:mode];
        cachedValue = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        [self.cachedValues setObject:cachedValue forKey:mode];
    }
    if (!cachedValue)
    {
        cachedValue = [self getProfileDefaultValue:mode];
    }
    return cachedValue;
}

- (void) setValue:(NSObject *)value mode:(OAApplicationMode *)mode
{
    [self.cachedValues setObject:value forKey:mode];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:[self getModeKey:self.key mode:mode]];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSetProfileSetting object:self];
}

- (void) setModeDefaultValue:(NSObject *)defValue mode:(OAApplicationMode *)mode
{
    if (!self.defaultValues) {
        self.defaultValues = [NSMapTable strongToStrongObjectsMapTable];
    }
    [self.defaultValues setObject:defValue forKey:mode];
}

- (void) resetModeToDefault:(OAApplicationMode *)mode
{
    NSObject *defValue = [self getProfileDefaultValue:mode];
    [self setValue:defValue mode:mode];
}

- (NSObject *) getProfileDefaultValue:(OAApplicationMode *)mode
{
    if (self.defaultValues && [self.defaultValues objectForKey:mode])
        return [self.defaultValues objectForKey:mode];
    
    OAApplicationMode *pt = mode.parent;
    if (pt)
        return [self getProfileDefaultValue:pt];

    return nil;
}

- (void) resetToDefault
{
}

- (void) setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
}

- (NSString *) toStringValue:(OAApplicationMode *)mode
{
    return @"";
}

- (void) copyValueFromAppMode:(OAApplicationMode *)sourceAppMode targetAppMode:(OAApplicationMode *)targetAppMode
{
    [self setValue:[self getValue:sourceAppMode] mode:targetAppMode];
}

@end

@interface OAProfileBoolean ()

@property (nonatomic) BOOL defValue;

@end

@implementation OAProfileBoolean

+ (instancetype) withKey:(NSString *)key defValue:(BOOL)defValue
{
    OAProfileBoolean *obj = [[OAProfileBoolean alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    
    return obj;
}

- (BOOL) get
{
    return [self get:self.appMode];
}

- (void) set:(BOOL)boolean
{
    [self set:boolean mode:self.appMode];
}

- (BOOL) get:(OAApplicationMode *)mode
{
    NSObject *value = [self getValue:mode];
    if (value)
        return ((NSNumber *)value).boolValue;
    else
        return self.defValue;
}

- (void) set:(BOOL)boolean mode:(OAApplicationMode *)mode
{
    [self setValue:@(boolean) mode:mode];
}

- (void) resetToDefault
{
    BOOL defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = ((NSNumber *)pDefault).boolValue;
    
    [self set:defaultValue];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    [self set:[strValue isEqualToString:@"true"] mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    return [self get:mode] ? @"true" : @"false";
}

@end

@interface OAProfileInteger ()

@property (nonatomic) int defValue;

@end

@implementation OAProfileInteger

+ (instancetype) withKey:(NSString *)key defValue:(int)defValue
{
    OAProfileInteger *obj = [[OAProfileInteger alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    
    return obj;
}

- (int) get
{
    return [self get:self.appMode];
}

- (void) set:(int)integer
{
    [self set:integer mode:self.appMode];
}

- (int) get:(OAApplicationMode *)mode
{
    NSObject *value = [self getValue:mode];
    if (value)
        return ((NSNumber *)value).intValue;
    else
        return self.defValue;
}

- (void) set:(int)integer mode:(OAApplicationMode *)mode
{
    [self setValue:@(integer) mode:mode];
}

- (void) resetToDefault
{
    int defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = ((NSNumber *)pDefault).intValue;
    
    [self set:defaultValue];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    [self set:strValue.intValue mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    return [NSString stringWithFormat:@"%d", [self get:mode]];
}

@end

@interface OAProfileString ()

@property (nonatomic) NSString *defValue;

@end

@implementation OAProfileString

+ (instancetype) withKey:(NSString *)key defValue:(NSString *)defValue
{
    OAProfileString *obj = [[OAProfileString alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    
    return obj;
}

- (NSString *) get
{
    return [self get:self.appMode];
}

- (void) set:(NSString *)string
{
    [self set:string  mode:self.appMode];
}

- (NSString *) get:(OAApplicationMode *)mode
{
    NSObject *value = [self getValue:mode];
    if (value)
        return (NSString *)value;
    else
        return self.defValue;
}

- (void) set:(NSString *)string mode:(OAApplicationMode *)mode
{
    [self setValue:string mode:mode];
}

- (void) resetToDefault
{
    NSString *defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = (NSString *)pDefault;
    
    [self set:defaultValue];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    [self set:strValue mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    return [self get:mode];
}

@end

@interface OAProfileDouble ()

@property (nonatomic) double defValue;

@end

@implementation OAProfileDouble

+ (instancetype) withKey:(NSString *)key defValue:(double)defValue
{
    OAProfileDouble *obj = [[OAProfileDouble alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    
    return obj;
}

- (double) get
{
    return [self get:self.appMode];
}

- (void) set:(double)dbl
{
    [self set:dbl mode:self.appMode];
}

- (double) get:(OAApplicationMode *)mode
{
    NSObject *value = [self getValue:mode];
    if (value)
        return ((NSNumber *)value).doubleValue;
    else
        return self.defValue;
}

- (void) set:(double)dbl mode:(OAApplicationMode *)mode
{
    [self setValue:@(dbl) mode:mode];
}

- (void) resetToDefault
{
    double defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = ((NSNumber *)pDefault).doubleValue;
    
    [self set:defaultValue];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    [self set:strValue.doubleValue mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    return [NSString stringWithFormat:@"%.1f", [self get:mode]];
}

@end

@interface OAProfileStringList ()

@property (nonatomic) NSArray<NSString *> *defValue;

@end

@implementation OAProfileStringList

+ (instancetype) withKey:(NSString *)key defValue:(NSArray<NSString *> *)defValue
{
    OAProfileStringList *obj = [[OAProfileStringList alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    
    return obj;
}

- (NSArray<NSString *> *) get
{
    return [self get:self.appMode];
}

- (void) set:(NSArray<NSString *> *)arr
{
    [self set:arr mode:self.appMode];
}

- (NSArray<NSString *> *) get:(OAApplicationMode *)mode
{
    NSObject *value = [self getValue:mode];
    return value ? (NSArray<NSString *> *)value : self.defValue;
}

- (void) set:(NSArray<NSString *> *)arr mode:(OAApplicationMode *)mode
{
    [self setValue:arr mode:mode];
}

- (void) add:(NSString *)string
{
    [self set:[[self get] arrayByAddingObject:string]];
}

- (void) addUnique:(NSString *)string
{
    if (![self contains:string])
        [self add:string];
}

- (void) remove:(NSString *)string
{
    if ([self contains:string])
    {
        [[self get] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != %@", string]];
    }
}

- (BOOL) contains:(NSString *)string
{
    return [[self get] indexOfObject:string] != NSNotFound;
}

- (void) resetToDefault
{
    NSArray<NSString *> *defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = (NSArray<NSString *> *)pDefault;

    [self set:defaultValue];
}

@end

@interface OAProfileMapSource ()

@property (nonatomic) OAMapSource *defValue;

@end

@implementation OAProfileMapSource

+ (instancetype) withKey:(NSString *)key defValue:(OAMapSource *)defValue
{
    OAProfileMapSource *obj = [[OAProfileMapSource alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    
    return obj;
}

- (OAMapSource *) get
{
    return [self get:self.appMode];
}

- (void) set:(OAMapSource *)mapSource
{
    [self set:mapSource mode:self.appMode];
}

- (OAMapSource *) get:(OAApplicationMode *)mode
{
    NSObject *val = [self getValue:mode];
    return val ? [OAMapSource fromDictionary:(NSDictionary *)val] : self.defValue;
}

- (void) set:(OAMapSource *)mapSource mode:(OAApplicationMode *)mode
{
    [self setValue:[mapSource toDictionary] mode:mode];
}

- (void) resetToDefault
{
    OAMapSource *defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = (OAMapSource *) pDefault;
    
    [self set:defaultValue];
}

@end

@interface OAProfileTerrain ()

@property (nonatomic) EOATerrainType defValue;

@end

@implementation OAProfileTerrain

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(EOATerrainType)defValue
{
    OAProfileTerrain *obj = [[OAProfileTerrain alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    
    return obj;
}

- (EOATerrainType) get
{
    return [super get];
}

- (void) set:(EOATerrainType)terrainType
{
    [super set:(int)terrainType];
}

- (EOATerrainType) get:(OAApplicationMode *)mode
{
    return [super get:mode];
}

- (void) set:(EOATerrainType)terrainType mode:(OAApplicationMode *)mode
{
    [super set:(int)terrainType mode:mode];
}

- (void) resetToDefault
{
    EOATerrainType defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = (EOATerrainType)((NSNumber *)pDefault).intValue;
    
    [self set:defaultValue];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    if ([strValue isEqualToString:@"HILLSHADE"])
        return [self set:EOATerrainTypeHillshade mode:mode];
    else if ([strValue isEqualToString:@"SLOPE"])
        return [self set:EOATerrainTypeSlope mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    switch ([self get:mode])
    {
        case EOATerrainTypeHillshade:
            return @"HILLSHADE";
        case EOATerrainTypeSlope:
            return @"SLOPE";
        default:
            return @"HILLSHADE";
    }
}

@end

@interface OAProfileAutoZoomMap ()

@property (nonatomic) EOAAutoZoomMap defValue;

@end

@implementation OAProfileAutoZoomMap

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(EOAAutoZoomMap)defValue
{
    OAProfileAutoZoomMap *obj = [[OAProfileAutoZoomMap alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    
    return obj;
}

- (EOAAutoZoomMap) get
{
    return [super get];
}

- (void) set:(EOAAutoZoomMap)autoZoomMap
{
    [super set:autoZoomMap];
}

- (EOAAutoZoomMap) get:(OAApplicationMode *)mode
{
    return [super get:mode];
}

- (void) set:(EOAAutoZoomMap)autoZoomMap mode:(OAApplicationMode *)mode
{
    [super set:autoZoomMap mode:mode];
}

- (void) resetToDefault
{
    EOAAutoZoomMap defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = (EOAAutoZoomMap)((NSNumber *)pDefault).intValue;
    
    [self set:defaultValue];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    if ([strValue isEqualToString:@"FARTHEST"])
        return [self set:AUTO_ZOOM_MAP_FARTHEST mode:mode];
    else if ([strValue isEqualToString:@"FAR"])
        return [self set:AUTO_ZOOM_MAP_FAR mode:mode];
    else if ([strValue isEqualToString:@"CLOSE"])
        return [self set:AUTO_ZOOM_MAP_CLOSE mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    switch ([self get:mode])
    {
        case AUTO_ZOOM_MAP_FARTHEST:
            return @"FARTHEST";
        case AUTO_ZOOM_MAP_FAR:
            return @"FAR";
        case AUTO_ZOOM_MAP_CLOSE:
            return @"CLOSE";
        default:
            @"FARTHEST";
    }
}

@end

@interface OAProfileSpeedConstant ()

@property (nonatomic) EOASpeedConstant defValue;

@end

@implementation OAProfileSpeedConstant

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(EOASpeedConstant)defValue
{
    OAProfileSpeedConstant *obj = [[OAProfileSpeedConstant alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    
    return obj;
}

- (EOASpeedConstant) get
{
    return [super get];
}

- (void) set:(EOASpeedConstant)speedConstant
{
    [super set:speedConstant];
}

- (EOASpeedConstant) get:(OAApplicationMode *)mode
{
    return [super get:mode];
}

- (void) set:(EOASpeedConstant)speedConstant mode:(OAApplicationMode *)mode
{
    [super set:speedConstant mode:mode];
}

- (NSObject *)getProfileDefaultValue:(OAApplicationMode *)mode
{
    EOAMetricsConstant mc = [[OAAppSettings sharedManager].metricSystem get];
    if ([mode isDerivedRoutingFrom:[OAApplicationMode PEDESTRIAN]])
    {
        if (mc == KILOMETERS_AND_METERS)
            return @(MINUTES_PER_KILOMETER);
        else
            return @(MILES_PER_HOUR);
    }
    if ([mode isDerivedRoutingFrom:[OAApplicationMode BOAT]])
        return @(NAUTICALMILES_PER_HOUR);
    
    if (mc == NAUTICAL_MILES)
        return @(NAUTICALMILES_PER_HOUR);
    else if (mc == KILOMETERS_AND_METERS)
        return @(KILOMETERS_PER_HOUR);
    else
        return @(MILES_PER_HOUR);
}

- (void) resetToDefault
{
    EOASpeedConstant defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = (EOASpeedConstant)((NSNumber *)pDefault).intValue;
    
    [self set:defaultValue];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    if ([strValue isEqualToString:@"KILOMETERS_PER_HOUR"])
        return [self set:KILOMETERS_PER_HOUR mode:mode];
    else if ([strValue isEqualToString:@"MILES_PER_HOUR"])
        return [self set:MILES_PER_HOUR mode:mode];
    else if ([strValue isEqualToString:@"METERS_PER_SECOND"])
        return [self set:METERS_PER_SECOND mode:mode];
    else if ([strValue isEqualToString:@"MINUTES_PER_MILE"])
        return [self set:MINUTES_PER_MILE mode:mode];
    else if ([strValue isEqualToString:@"MINUTES_PER_KILOMETER"])
        return [self set:MINUTES_PER_KILOMETER mode:mode];
    else if ([strValue isEqualToString:@"NAUTICALMILES_PER_HOUR"])
        return [self set:NAUTICALMILES_PER_HOUR mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    switch ([self get:mode])
    {
        case KILOMETERS_PER_HOUR:
            return @"KILOMETERS_PER_HOUR";
        case MILES_PER_HOUR:
            return @"MILES_PER_HOUR";
        case METERS_PER_SECOND:
            return @"METERS_PER_SECOND";
        case MINUTES_PER_MILE:
            return @"MINUTES_PER_MILE";
        case MINUTES_PER_KILOMETER:
            return @"MINUTES_PER_KILOMETER";
        case NAUTICALMILES_PER_HOUR:
            return @"NAUTICALMILES_PER_HOUR";
        default:
            return @"KILOMETERS_PER_HOUR";
    }
}

@end

@implementation OAProfileAngularConstant

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(EOAAngularConstant)defValue
{
    OAProfileAngularConstant *obj = [[OAProfileAngularConstant alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    
    return obj;
}

- (EOAAngularConstant) get
{
    return [super get];
}

- (void) set:(EOAAngularConstant)angularConstant
{
    [super set:angularConstant];
}

- (EOAAngularConstant) get:(OAApplicationMode *)mode
{
    return [super get:mode];
}

- (void) set:(EOAAngularConstant)angularConstant mode:(OAApplicationMode *)mode
{
    [super set:angularConstant mode:mode];
}

- (void) resetToDefault
{
    EOAAngularConstant defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = (EOAAngularConstant)((NSNumber *)pDefault).intValue;
    
    [self set:defaultValue];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    if ([strValue isEqualToString:@"DEGREES"])
        return [self set:DEGREES mode:mode];
    else if ([strValue isEqualToString:@"DEGREES360"])
        return [self set:DEGREES360 mode:mode];
    else if ([strValue isEqualToString:@"MILLIRADS"])
        return [self set:MILLIRADS mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    switch ([self get:mode])
    {
        case DEGREES:
            return @"DEGREES";
        case DEGREES360:
            return @"DEGREES360";
        case MILLIRADS:
            return @"MILLIRADS";
        default:
            return @"DEGREES";
    }
}

@end

@implementation OAProfileActiveMarkerConstant

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(EOAActiveMarkerConstant)defValue
{
    OAProfileActiveMarkerConstant *obj = [[OAProfileActiveMarkerConstant alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    
    return obj;
}

- (EOAActiveMarkerConstant) get
{
    return [super get];
}

- (void) set:(EOAActiveMarkerConstant)activeMarkerConstant
{
    [super set:activeMarkerConstant];
}

- (EOAActiveMarkerConstant) get:(OAApplicationMode *)mode
{
    return [super get:mode];
}

- (void) set:(EOAActiveMarkerConstant)activeMarkerConstant mode:(OAApplicationMode *)mode
{
    [super set:activeMarkerConstant mode:mode];
}

- (void) resetToDefault
{
    EOAActiveMarkerConstant defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = (EOAActiveMarkerConstant)((NSNumber *)pDefault).intValue;
    
    [self set:defaultValue];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    switch (strValue.intValue) {
        case 1:
            [self set:ONE_ACTIVE_MARKER mode:mode];
            break;
        case 2:
            [self set:TWO_ACTIVE_MARKERS mode:mode];
        default:
            break;
    }
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    switch ([self get:mode])
    {
        case ONE_ACTIVE_MARKER:
            return @"1";
        case TWO_ACTIVE_MARKERS:
            return @"2";
        default:
            return @"1";
    }
}

@end

@implementation OAProfileDistanceIndicationConstant

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(EOADistanceIndicationConstant)defValue
{
    OAProfileDistanceIndicationConstant *obj = [[OAProfileDistanceIndicationConstant alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    
    return obj;
}

- (EOADistanceIndicationConstant) get
{
    return [super get];
}

- (void) set:(EOADistanceIndicationConstant)distanceIndicationConstant
{
    [super set:distanceIndicationConstant];
}

- (EOADistanceIndicationConstant) get:(OAApplicationMode *)mode
{
    return [super get:mode];
}

- (void) set:(EOADistanceIndicationConstant)distanceIndicationConstant mode:(OAApplicationMode *)mode
{
    [super set:distanceIndicationConstant mode:mode];
}

- (void) resetToDefault
{
    EOADistanceIndicationConstant defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = (EOADistanceIndicationConstant)((NSNumber *)pDefault).intValue;
    
    [self set:defaultValue];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    if ([strValue isEqualToString:@"TOOLBAR"])
        return [self set:TOP_BAR_DISPLAY mode:mode];
    else if ([strValue isEqualToString:@"WIDGETS"])
        return [self set:WIDGET_DISPLAY mode:mode];
    else if ([strValue isEqualToString:@"NONE"])
        return [self set:NONE_DISPLAY mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    switch ([self get:mode])
    {
        case TOP_BAR_DISPLAY:
            return @"TOOLBAR";
        case WIDGET_DISPLAY:
            return @"WIDGETS";
        case NONE_DISPLAY:
            return @"NONE";
        default:
            return @"TOOLBAR";
    }
}

@end

@implementation OAProfileDrivingRegion

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(EOADrivingRegion)defValue
{
    OAProfileDrivingRegion *obj = [[OAProfileDrivingRegion alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    
    return obj;
}

- (EOADrivingRegion) get
{
    return [super get];
}

- (void) set:(EOADrivingRegion)drivingRegionConstant
{
    [super set:drivingRegionConstant];
}

- (EOADrivingRegion) get:(OAApplicationMode *)mode
{
    return [super get:mode];
}

- (void) set:(EOADrivingRegion)drivingRegionConstant mode:(OAApplicationMode *)mode
{
    [super set:drivingRegionConstant mode:mode];
    if (![[OAAppSettings sharedManager].metricSystemChangedManually get:mode])
        [[OAAppSettings sharedManager].metricSystem set:[OADrivingRegion getDefMetrics:drivingRegionConstant] mode:mode];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    if ([strValue isEqualToString:@"EUROPE_ASIA"])
        return [self set:DR_EUROPE_ASIA mode:mode];
    else if ([strValue isEqualToString:@"US"])
        return [self set:DR_US mode:mode];
    else if ([strValue isEqualToString:@"CANADA"])
        return [self set:DR_CANADA mode:mode];
    else if ([strValue isEqualToString:@"UK_AND_OTHERS"])
        return [self set:DR_UK_AND_OTHERS mode:mode];
    else if ([strValue isEqualToString:@"JAPAN"])
        return [self set:DR_JAPAN mode:mode];
    else if ([strValue isEqualToString:@"AUSTRALIA"])
        return [self set:DR_AUSTRALIA mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    switch ([self get:mode])
    {
        case DR_EUROPE_ASIA:
            return @"EUROPE_ASIA";
        case DR_US:
            return @"US";
        case DR_CANADA:
            return @"CANADA";
        case DR_UK_AND_OTHERS:
            return @"UK_AND_OTHERS";
        case DR_JAPAN:
            return @"JAPAN";
        case DR_AUSTRALIA:
            return @"AUSTRALIA";
        default:
            return @"EUROPE_ASIA";
    }
}

- (void) resetToDefault
{
    EOADrivingRegion defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = (EOADrivingRegion)((NSNumber *)pDefault).intValue;
    
    [self set:defaultValue];
}

@end

@interface OAProfileMetricSystem ()

@property (nonatomic) EOAMetricsConstant defValue;

@end

@implementation OAProfileMetricSystem

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(EOAMetricsConstant)defValue
{
    OAProfileMetricSystem *obj = [[OAProfileMetricSystem alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    return obj;
}

- (EOAMetricsConstant) get
{
    return [super get];
}

- (void) set:(EOAMetricsConstant)metricsConstant
{
    [super set:metricsConstant];
}

- (EOAMetricsConstant) get:(OAApplicationMode *)mode
{
    return [super get:mode];
}

- (void) set:(EOAMetricsConstant)metricsConstant mode:(OAApplicationMode *)mode
{
    [super set:metricsConstant mode:mode];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    if ([strValue isEqualToString:@"KILOMETERS_AND_METERS"])
        return [self set:KILOMETERS_AND_METERS mode:mode];
    else if ([strValue isEqualToString:@"MILES_AND_FEET"])
        return [self set:MILES_AND_FEET mode:mode];
    else if ([strValue isEqualToString:@"MILES_AND_METERS"])
        return [self set:MILES_AND_METERS mode:mode];
    else if ([strValue isEqualToString:@"MILES_AND_YARDS"])
        return [self set:MILES_AND_YARDS mode:mode];
    else if ([strValue isEqualToString:@"NAUTICAL_MILES"])
        return [self set:NAUTICAL_MILES mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    switch ([self get:mode])
    {
        case KILOMETERS_AND_METERS:
            return @"KILOMETERS_AND_METERS";
        case MILES_AND_FEET:
            return @"MILES_AND_FEET";
        case MILES_AND_METERS:
            return @"MILES_AND_METERS";
        case MILES_AND_YARDS:
            return @"MILES_AND_YARDS";
        case NAUTICAL_MILES:
            return @"NAUTICAL_MILES";
        default:
            return @"KILOMETERS_AND_METERS";
    }
}

- (void) resetToDefault
{
    EOAMetricsConstant defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = (EOAMetricsConstant)((NSNumber *)pDefault).intValue;

    [self set:defaultValue];
}

@end

@implementation OAAppSettings
{
    NSMapTable<NSString *, OAProfileBoolean *> *_customBooleanRoutingProps;
    NSMapTable<NSString *, OAProfileString *> *_customRoutingProps;
    NSMapTable<NSString *, OAProfileSetting *> *_registeredPreferences;
    OADayNightHelper *_dayNightHelper;
}

@synthesize settingShowMapRulet=_settingShowMapRulet, settingMapLanguage=_settingMapLanguage, appearanceMode=_appearanceMode;
@synthesize mapSettingShowFavorites=_mapSettingShowFavorites, mapSettingShowPoiLabel=_mapSettingShowPoiLabel, mapSettingShowOfflineEdits=_mapSettingShowOfflineEdits;
@synthesize mapSettingShowOnlineNotes=_mapSettingShowOnlineNotes, settingPrefMapLanguage=_settingPrefMapLanguage;
@synthesize settingMapLanguageShowLocal=_settingMapLanguageShowLocal, settingMapLanguageTranslit=_settingMapLanguageTranslit;

+ (OAAppSettings*) sharedManager
{
    static OAAppSettings *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[OAAppSettings alloc] init];
    });
    return _sharedManager;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _dayNightHelper = [OADayNightHelper instance];
        _customBooleanRoutingProps = [NSMapTable strongToStrongObjectsMapTable];
        _registeredPreferences = [NSMapTable strongToStrongObjectsMapTable];
        
        _trackIntervalArray = @[@0, @1, @2, @3, @5, @10, @15, @30, @60, @90, @120, @180, @300];
        
        _mapLanguages = @[@"af", @"ar", @"az", @"be", @"bg", @"bn", @"br", @"bs", @"ca", @"ceb", @"cs", @"cy", @"da", @"de", @"el", @"eo", @"es", @"et", @"eu", @"id", @"fa", @"fi", @"fr", @"fy", @"ga", @"gl", @"he", @"hi", @"hr", @"hsb", @"ht", @"hu", @"hy", @"is", @"it", @"ja", @"ka", @"kn", @"ko", @"ku", @"la", @"lb", @"lt", @"lv", @"mk", @"ml", @"mr", @"ms", @"nds", @"new", @"nl", @"nn", @"no", @"nv", @"os", @"pl", @"pt", @"ro", @"ru", @"sc", @"sh", @"sk", @"sl", @"sq", @"sr", @"sv", @"sw", @"ta", @"te", @"th", @"tl", @"tr", @"uk", @"vi", @"vo", @"zh"];
        
        _rtlLanguages = @[@"ar",@"dv",@"he",@"iw",@"fa",@"nqo",@"ps",@"sd",@"ug",@"ur",@"yi"];
        
        _ttsAvailableVoices = @[@"de", @"en", @"es", @"fr", @"hu", @"hu-formal", @"it", @"ja", @"nl", @"pl", @"pt", @"pt-br", @"ru", @"zh", @"zh-hk", @"ar", @"cs", @"da", @"en-gb", @"el", @"et", @"es-ar", @"fa", @"hi", @"hr", @"ko", @"ro", @"sk", @"sv", @"nb", @"tr"];

        // Common Settings
        _settingMapLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:settingMapLanguageKey] ? (int)[[NSUserDefaults standardUserDefaults] integerForKey:settingMapLanguageKey] : 0;
        
        _settingPrefMapLanguage = [[NSUserDefaults standardUserDefaults] objectForKey:settingPrefMapLanguageKey];
        _settingMapLanguageShowLocal = [[NSUserDefaults standardUserDefaults] objectForKey:settingMapLanguageShowLocalKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:settingMapLanguageShowLocalKey] : NO;
        _settingMapLanguageTranslit = [[NSUserDefaults standardUserDefaults] objectForKey:settingMapLanguageTranslitKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:settingMapLanguageTranslitKey] : NO;

        _settingShowMapRulet = [[NSUserDefaults standardUserDefaults] objectForKey:settingShowMapRuletKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:settingShowMapRuletKey] : YES;
        _appearanceMode = [OAProfileInteger withKey:settingAppModeKey defValue:0];
        [_registeredPreferences setObject:_appearanceMode forKey:@"daynight_mode"];

        _settingShowZoomButton = YES;//[[NSUserDefaults standardUserDefaults] objectForKey:settingZoomButtonKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:settingZoomButtonKey] : YES;
        _settingMapArrows = [[NSUserDefaults standardUserDefaults] objectForKey:settingMapArrowsKey] ? (int)[[NSUserDefaults standardUserDefaults] integerForKey:settingMapArrowsKey] : MAP_ARROWS_LOCATION;
        
        _settingShowAltInDriveMode = [[NSUserDefaults standardUserDefaults] objectForKey:settingMapShowAltInDriveModeKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:settingMapShowAltInDriveModeKey] : NO;
        
        _settingDoNotShowPromotions = [[NSUserDefaults standardUserDefaults] objectForKey:settingDoNotShowPromotionsKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:settingDoNotShowPromotionsKey] : NO;
        _settingUseAnalytics = [[NSUserDefaults standardUserDefaults] objectForKey:settingUseFirebaseKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:settingUseFirebaseKey] : YES;
        
        _liveUpdatesPurchased = [[NSUserDefaults standardUserDefaults] objectForKey:liveUpdatesPurchasedKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:liveUpdatesPurchasedKey] : NO;
        _settingOsmAndLiveEnabled = [[NSUserDefaults standardUserDefaults] objectForKey:settingOsmAndLiveEnabledKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:settingOsmAndLiveEnabledKey] : NO;

        _billingUserId = [[NSUserDefaults standardUserDefaults] objectForKey:billingUserIdKey];
        _billingUserName = [[NSUserDefaults standardUserDefaults] objectForKey:billingUserNameKey] ? [[NSUserDefaults standardUserDefaults] objectForKey:billingUserNameKey] : @"";
        _billingUserToken = [[NSUserDefaults standardUserDefaults] objectForKey:billingUserTokenKey] ? [[NSUserDefaults standardUserDefaults] objectForKey:billingUserTokenKey] : @"";
        _billingUserEmail = [[NSUserDefaults standardUserDefaults] objectForKey:billingUserEmailKey] ? [[NSUserDefaults standardUserDefaults] objectForKey:billingUserEmailKey] : @"";
        _billingUserCountry = [[NSUserDefaults standardUserDefaults] objectForKey:billingUserCountryKey] ? [[NSUserDefaults standardUserDefaults] objectForKey:billingUserCountryKey] : @"";
        _billingUserCountryDownloadName = [[NSUserDefaults standardUserDefaults] objectForKey:billingUserCountryDownloadNameKey] ?
            [[NSUserDefaults standardUserDefaults] objectForKey:billingUserCountryDownloadNameKey] : kBillingUserDonationNone;
        _billingHideUserName = [[NSUserDefaults standardUserDefaults] objectForKey:billingHideUserNameKey];
        _liveUpdatesPurchaseCancelledTime = [[NSUserDefaults standardUserDefaults] objectForKey:liveUpdatesPurchaseCancelledTimeKey] ? [[NSUserDefaults standardUserDefaults] doubleForKey:liveUpdatesPurchaseCancelledTimeKey] : 0;
        _liveUpdatesPurchaseCancelledFirstDlgShown = [[NSUserDefaults standardUserDefaults] objectForKey:liveUpdatesPurchaseCancelledFirstDlgShownKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:liveUpdatesPurchaseCancelledFirstDlgShownKey] : NO;
        _liveUpdatesPurchaseCancelledSecondDlgShown = [[NSUserDefaults standardUserDefaults] objectForKey:liveUpdatesPurchaseCancelledSecondDlgShownKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:liveUpdatesPurchaseCancelledSecondDlgShownKey] : NO;
        _emailSubscribed = [[NSUserDefaults standardUserDefaults] objectForKey:emailSubscribedKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:emailSubscribedKey] : NO;
        _displayDonationSettings = [[NSUserDefaults standardUserDefaults] objectForKey:displayDonationSettingsKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:displayDonationSettingsKey] : NO;
        _lastReceiptValidationDate = [[NSUserDefaults standardUserDefaults] objectForKey:lastReceiptValidationDateKey] ? [NSDate dateWithTimeIntervalSince1970:[[NSUserDefaults standardUserDefaults] doubleForKey:lastReceiptValidationDateKey]] : [NSDate dateWithTimeIntervalSince1970:0];
        _eligibleForIntroductoryPrice = [[NSUserDefaults standardUserDefaults] objectForKey:eligibleForIntroductoryPriceKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:eligibleForIntroductoryPriceKey] : NO;
        _eligibleForSubscriptionOffer = [[NSUserDefaults standardUserDefaults] objectForKey:eligibleForSubscriptionOfferKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:eligibleForSubscriptionOfferKey] : NO;
        
        _shouldShowWhatsNewScreen = [[NSUserDefaults standardUserDefaults] objectForKey:shouldShowWhatsNewScreenKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:shouldShowWhatsNewScreenKey] : YES;

        // Map Settings
        _mapSettingShowFavorites = [OAProfileBoolean withKey:mapSettingShowFavoritesKey defValue:YES];
        _mapSettingShowPoiLabel = [OAProfileBoolean withKey:_mapSettingShowPoiLabel defValue:NO];
        _mapSettingShowOfflineEdits = [OAProfileBoolean withKey:mapSettingShowOfflineEditsKey defValue:YES];
        _mapSettingShowOnlineNotes = [OAProfileBoolean withKey:mapSettingShowOnlineNotesKey defValue:NO];
        _layerTransparencySeekbarMode = [OAProfileInteger withKey:layerTransparencySeekbarModeKey defValue:LAYER_TRANSPARENCY_SEEKBAR_MODE_OFF];
        
        [_registeredPreferences setObject:_mapSettingShowFavorites forKey:@"show_favorites"];
        [_registeredPreferences setObject:_mapSettingShowPoiLabel forKey:@"show_poi_label"];
        [_registeredPreferences setObject:_mapSettingShowOfflineEdits forKey:@"show_osm_edits"];
        [_registeredPreferences setObject:_mapSettingShowOnlineNotes forKey:@"show_osm_bugs"];
        [_registeredPreferences setObject:_layerTransparencySeekbarMode forKey:@"layer_transparency_seekbar_mode"];
    
        _mapSettingVisibleGpx = [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingVisibleGpxKey] ? [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingVisibleGpxKey] : @[];

        _mapSettingTrackRecording = [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingTrackRecordingKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:mapSettingTrackRecordingKey] : NO;
        
        _mapSettingSaveTrackIntervalGlobal = [OAProfileInteger withKey:mapSettingSaveTrackIntervalGlobalKey defValue:SAVE_TRACK_INTERVAL_DEFAULT];
        [_registeredPreferences setObject:_mapSettingSaveTrackIntervalGlobal forKey:@"save_global_track_interval"];

        // TODO: redesign alert as in android to show/hide recorded trip on map
        _mapSettingShowRecordingTrack = [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingShowRecordingTrackKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:mapSettingShowRecordingTrackKey] : NO;
        
        _mapSettingSaveTrackIntervalApproved = [OAProfileBoolean withKey:mapSettingSaveTrackIntervalApprovedKey defValue:NO];
        [_registeredPreferences setObject:_mapSettingSaveTrackIntervalApproved forKey:@"save_global_track_remember"];
        
        _mapSettingActiveRouteFilePath = [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingActiveRouteFilePathKey];
        _mapSettingActiveRouteVariantType = [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingActiveRouteVariantTypeKey] ? (int)[[NSUserDefaults standardUserDefaults] integerForKey:mapSettingActiveRouteVariantTypeKey] : 0;

        _selectedPoiFilters = [OAProfileString withKey:selectedPoiFiltersKey defValue:@""];
        [_registeredPreferences setObject:_selectedPoiFilters forKey:@"selected_poi_filter_for_map"];

        _plugins = [[NSUserDefaults standardUserDefaults] objectForKey:pluginsKey] ? [NSSet setWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:pluginsKey]] : [NSSet set];

        _discountId = [[NSUserDefaults standardUserDefaults] objectForKey:discountIdKey] ? [[NSUserDefaults standardUserDefaults] integerForKey:discountIdKey] : 0;
        _discountShowNumberOfStarts = [[NSUserDefaults standardUserDefaults] objectForKey:discountShowNumberOfStartsKey] ? [[NSUserDefaults standardUserDefaults] integerForKey:discountShowNumberOfStartsKey] : 0;
        _discountTotalShow = [[NSUserDefaults standardUserDefaults] objectForKey:discountTotalShowKey] ? [[NSUserDefaults standardUserDefaults] integerForKey:discountTotalShowKey] : 0;
        _discountShowDatetime = [[NSUserDefaults standardUserDefaults] objectForKey:discountShowDatetimeKey] ? [[NSUserDefaults standardUserDefaults] doubleForKey:discountShowDatetimeKey] : 0;
        
        _lastSearchedCity = [[NSUserDefaults standardUserDefaults] objectForKey:lastSearchedCityKey] ? ((NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:lastSearchedCityKey]).unsignedLongLongValue : 0;
        _lastSearchedCityName = [[NSUserDefaults standardUserDefaults] objectForKey:lastSearchedCityNameKey];
        
        double lastSearchedPointLat = [[NSUserDefaults standardUserDefaults] objectForKey:lastSearchedPointLatKey] ? [[NSUserDefaults standardUserDefaults] doubleForKey:lastSearchedPointLatKey] : 0.0;
        double lastSearchedPointLon = [[NSUserDefaults standardUserDefaults] objectForKey:lastSearchedPointLonKey] ? [[NSUserDefaults standardUserDefaults] doubleForKey:lastSearchedPointLonKey] : 0.0;
        if (lastSearchedPointLat != 0.0 && lastSearchedPointLon != 0.0)
        {
            _lastSearchedPoint = [[CLLocation alloc] initWithLatitude:lastSearchedPointLat longitude:lastSearchedPointLon];
        }
        
        _appModeBeanPrefsIds = [[NSUserDefaults standardUserDefaults] objectForKey:appModeBeanPrefsIdsKey] ? [[NSUserDefaults standardUserDefaults] objectForKey:appModeBeanPrefsIdsKey] :
        @[
            @"app_mode_icon_color",
            @"user_profile_name",
            @"parent_app_mode",
            @"routing_profile",
            @"route_service",
            @"navigation_icon",
            @"location_icon",
            @"app_mode_order",
            @"app_mode_icon_res_name"
        ];

        _availableApplicationModes = [[NSUserDefaults standardUserDefaults] objectForKey:availableApplicationModesKey];
        if (!_availableApplicationModes)
            self.availableApplicationModes = @"car,bicycle,pedestrian,public_transport,";
        
        _customAppModes = [NSUserDefaults.standardUserDefaults objectForKey:customAppModesKey] ? [NSUserDefaults.standardUserDefaults stringForKey:customAppModesKey] : @"";

        _mapInfoControls = [OAProfileString withKey:mapInfoControlsKey defValue:@""];
        [_registeredPreferences setObject:_mapInfoControls forKey:@"map_info_controls"];
        
        _routingProfile = [OAProfileString withKey:routingProfileKey defValue:@""];
        [_routingProfile setModeDefaultValue:@"car" mode:OAApplicationMode.CAR];
        [_routingProfile setModeDefaultValue:@"bicycle" mode:OAApplicationMode.BICYCLE];
        [_routingProfile setModeDefaultValue:@"pedestrian" mode:OAApplicationMode.PEDESTRIAN];
        [_routingProfile setModeDefaultValue:@"public_transport" mode:OAApplicationMode.PUBLIC_TRANSPORT];
        [_routingProfile setModeDefaultValue:@"boat" mode:OAApplicationMode.BOAT];
        [_routingProfile setModeDefaultValue:@"STRAIGHT_LINE_MODE" mode:OAApplicationMode.AIRCRAFT];
        [_routingProfile setModeDefaultValue:@"ski" mode:OAApplicationMode.SKI];
        [_registeredPreferences setObject:_routingProfile forKey:@"routing_profile"];
        
        _profileIconName = [OAProfileString withKey:profileIconNameKey defValue:@"ic_world_globe_dark"];
        [_profileIconName setModeDefaultValue:@"ic_world_globe_dark" mode:OAApplicationMode.DEFAULT];
        [_profileIconName setModeDefaultValue:@"ic_action_car_dark" mode:OAApplicationMode.CAR];
        [_profileIconName setModeDefaultValue:@"ic_action_bicycle_dark" mode:OAApplicationMode.BICYCLE];
        [_profileIconName setModeDefaultValue:@"ic_action_pedestrian_dark" mode:OAApplicationMode.PEDESTRIAN];
        [_profileIconName setModeDefaultValue:@"ic_action_bus_dark" mode:OAApplicationMode.PUBLIC_TRANSPORT];
        [_profileIconName setModeDefaultValue:@"ic_action_sail_boat_dark" mode:OAApplicationMode.BOAT];
        [_profileIconName setModeDefaultValue:@"ic_action_aircraft" mode:OAApplicationMode.AIRCRAFT];
        [_profileIconName setModeDefaultValue:@"ic_action_skiing" mode:OAApplicationMode.SKI];
        
        _profileIconColor = [OAProfileInteger withKey:profileIconColorKey defValue:profile_icon_color_blue_dark_default];
        _userProfileName = [OAProfileString withKey:userProfileNameKey defValue:@""];
        _parentAppMode = [OAProfileString withKey:parentAppModeKey defValue:nil];
        
        _routerService = [OAProfileInteger withKey:routerServiceKey defValue:0]; // OSMAND
        // 2 = STRAIGHT
        [_routerService setModeDefaultValue:@2 mode:OAApplicationMode.AIRCRAFT];
        [_routerService setModeDefaultValue:@2 mode:OAApplicationMode.DEFAULT];
        [_routerService set:2 mode:OAApplicationMode.DEFAULT];
        
        [_registeredPreferences setObject:_routerService forKey:@"route_service"];
        _navigationIcon = [OAProfileInteger withKey:navigationIconKey defValue:NAVIGATION_ICON_DEFAULT];
        [_navigationIcon setModeDefaultValue:@(NAVIGATION_ICON_NAUTICAL) mode:OAApplicationMode.BOAT];
        [_registeredPreferences setObject:_navigationIcon forKey:@"navigation_icon"];
        
        _locationIcon = [OAProfileInteger withKey:locationIconKey defValue:LOCATION_ICON_DEFAULT];
        [_locationIcon setModeDefaultValue:@(LOCATION_ICON_CAR) mode:OAApplicationMode.CAR];
        [_locationIcon setModeDefaultValue:@(LOCATION_ICON_BICYCLE) mode:OAApplicationMode.BICYCLE];
        [_locationIcon setModeDefaultValue:@(LOCATION_ICON_CAR) mode:OAApplicationMode.AIRCRAFT];
        [_locationIcon setModeDefaultValue:@(LOCATION_ICON_BICYCLE) mode:OAApplicationMode.SKI];
        [_registeredPreferences setObject:_locationIcon forKey:@"location_icon"];    
        
        _appModeOrder = [OAProfileInteger withKey:appModeOrderKey defValue:0];
        
        _defaultSpeed = [OAProfileDouble withKey:defaultSpeedKey defValue:10.];
        [_defaultSpeed setModeDefaultValue:@1.5 mode:OAApplicationMode.DEFAULT];
        [_defaultSpeed setModeDefaultValue:@12.5 mode:OAApplicationMode.CAR];
        [_defaultSpeed setModeDefaultValue:@2.77 mode:OAApplicationMode.BICYCLE];
        [_defaultSpeed setModeDefaultValue:@1.11 mode:OAApplicationMode.PEDESTRIAN];
        [_defaultSpeed setModeDefaultValue:@1.38 mode:OAApplicationMode.BOAT];
        [_defaultSpeed setModeDefaultValue:@40.0 mode:OAApplicationMode.AIRCRAFT];
        [_defaultSpeed setModeDefaultValue:@1.38 mode:OAApplicationMode.SKI];
        [_registeredPreferences setObject:_defaultSpeed forKey:@"default_speed"];

        _minSpeed = [OAProfileDouble withKey:minSpeedKey defValue:0.];
        _maxSpeed = [OAProfileDouble withKey:maxSpeedKey defValue:0.];
        _routeStraightAngle = [OAProfileDouble withKey:routeStraightAngleKey defValue:30.];
        [_registeredPreferences setObject:_minSpeed forKey:@"min_speed"];
        [_registeredPreferences setObject:_maxSpeed forKey:@"max_speed"];
        [_registeredPreferences setObject:_routeStraightAngle forKey:@"routing_straight_angle"];

        _transparentMapTheme = [OAProfileBoolean withKey:transparentMapThemeKey defValue:YES];
        [_transparentMapTheme setModeDefaultValue:@NO mode:[OAApplicationMode CAR]];
        [_transparentMapTheme setModeDefaultValue:@NO mode:[OAApplicationMode BICYCLE]];
        [_transparentMapTheme setModeDefaultValue:@YES mode:[OAApplicationMode PEDESTRIAN]];
        [_registeredPreferences setObject:_transparentMapTheme forKey:@"transparent_map_theme"];

        _showStreetName = [OAProfileBoolean withKey:showStreetNameKey defValue:NO];
        [_showStreetName setModeDefaultValue:@NO mode:[OAApplicationMode DEFAULT]];
        [_showStreetName setModeDefaultValue:@YES mode:[OAApplicationMode CAR]];
        [_showStreetName setModeDefaultValue:@NO mode:[OAApplicationMode BICYCLE]];
        [_showStreetName setModeDefaultValue:@NO mode:[OAApplicationMode PEDESTRIAN]];
        [_registeredPreferences setObject:_showStreetName forKey:@"show_street_name"];
        
        _showArrivalTime = [OAProfileBoolean withKey:showArrivalTimeKey defValue:YES];
        _showIntermediateArrivalTime = [OAProfileBoolean withKey:showIntermediateArrivalTimeKey defValue:YES];
        _showRelativeBearing = [OAProfileBoolean withKey:showRelativeBearingKey defValue:YES];
        _showCompassControlRuler = [OAProfileBoolean withKey:showCompassControlRulerKey defValue:YES];
        
        [_registeredPreferences setObject:_showArrivalTime forKey:@"show_arrival_time"];
        [_registeredPreferences setObject:_showIntermediateArrivalTime forKey:@"show_intermediate_arrival_time"];
        [_registeredPreferences setObject:_showRelativeBearing forKey:@"show_relative_bearing"];
        [_registeredPreferences setObject:_showCompassControlRuler forKey:@"show_compass_ruler"];

        _centerPositionOnMap = [OAProfileBoolean withKey:centerPositionOnMapKey defValue:NO];
        [_registeredPreferences setObject:_centerPositionOnMap forKey:@"center_position_on_map"];

        _rotateMap = [OAProfileInteger withKey:rotateMapKey defValue:ROTATE_MAP_NONE];
        [_rotateMap setModeDefaultValue:@(ROTATE_MAP_BEARING) mode:[OAApplicationMode CAR]];
        [_rotateMap setModeDefaultValue:@(ROTATE_MAP_BEARING) mode:[OAApplicationMode BICYCLE]];
        [_rotateMap setModeDefaultValue:@(ROTATE_MAP_COMPASS) mode:[OAApplicationMode PEDESTRIAN]];
        [_registeredPreferences setObject:_rotateMap forKey:@"rotate_map"];
        
        _mapDensity = [OAProfileDouble withKey:mapDensityKey defValue:MAGNIFIER_DEFAULT_VALUE];
        [_mapDensity setModeDefaultValue:@(MAGNIFIER_DEFAULT_CAR) mode:[OAApplicationMode CAR]];
        [_mapDensity setModeDefaultValue:@(MAGNIFIER_DEFAULT_VALUE) mode:[OAApplicationMode BICYCLE]];
        [_mapDensity setModeDefaultValue:@(MAGNIFIER_DEFAULT_VALUE) mode:[OAApplicationMode PEDESTRIAN]];
        [_registeredPreferences setObject:_mapDensity forKey:@"map_density_n"];
        
        _textSize = [OAProfileDouble withKey:textSizeKey defValue:MAGNIFIER_DEFAULT_VALUE];
        [_textSize setModeDefaultValue:@(MAGNIFIER_DEFAULT_VALUE) mode:[OAApplicationMode CAR]];
        [_textSize setModeDefaultValue:@(MAGNIFIER_DEFAULT_VALUE) mode:[OAApplicationMode BICYCLE]];
        [_textSize setModeDefaultValue:@(MAGNIFIER_DEFAULT_VALUE) mode:[OAApplicationMode PEDESTRIAN]];
        [_registeredPreferences setObject:_textSize forKey:@"text_scale"];
        
        _renderer = [OAProfileString withKey:rendererKey defValue:@"OsmAnd"];
        [_registeredPreferences setObject:_renderer forKey:@"renderer"];

        _firstMapIsDownloaded = [[NSUserDefaults standardUserDefaults] objectForKey:firstMapIsDownloadedKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:firstMapIsDownloadedKey] : NO;

        // trip recording settings
        _saveTrackToGPX = [OAProfileBoolean withKey:saveTrackToGPXKey defValue:NO];
        [_registeredPreferences setObject:_saveTrackToGPX forKey:@"save_track_to_gpx"];
        
        _mapSettingSaveTrackInterval = [OAProfileInteger withKey:mapSettingSaveTrackIntervalKey defValue:SAVE_TRACK_INTERVAL_DEFAULT];
        [_mapSettingSaveTrackInterval setModeDefaultValue:@3 mode:[OAApplicationMode CAR]];
        [_mapSettingSaveTrackInterval setModeDefaultValue:@5 mode:[OAApplicationMode BICYCLE]];
        [_mapSettingSaveTrackInterval setModeDefaultValue:@10 mode:[OAApplicationMode PEDESTRIAN]];
        [_registeredPreferences setObject:_mapSettingSaveTrackInterval forKey:@"save_track_interval"];
        
        _saveTrackMinDistance = [OAProfileDouble withKey:saveTrackMinDistanceKey defValue:REC_FILTER_DEFAULT];
        _saveTrackPrecision = [OAProfileDouble withKey:saveTrackPrecisionKey defValue:REC_FILTER_DEFAULT];
        _saveTrackMinSpeed = [OAProfileDouble withKey:saveTrackMinSpeedKey defValue:REC_FILTER_DEFAULT];
        _autoSplitRecording = [OAProfileBoolean withKey:autoSplitRecordingKey defValue:NO];
        
        [_registeredPreferences setObject:_saveTrackMinDistance forKey:@"save_track_min_distance"];
        [_registeredPreferences setObject:_saveTrackPrecision forKey:@"save_track_precision"];
        [_registeredPreferences setObject:_saveTrackMinSpeed forKey:@"save_track_min_speed"];
        [_registeredPreferences setObject:_autoSplitRecording forKey:@"auto_split_recording"];
        
        // navigation settings
        _useFastRecalculation = [[NSUserDefaults standardUserDefaults] objectForKey:useFastRecalculationKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:useFastRecalculationKey] : YES;
        _fastRouteMode = [OAProfileBoolean withKey:fastRouteModeKey defValue:YES];
        [_registeredPreferences setObject:_fastRouteMode forKey:@"fast_route_mode"];
        _disableComplexRouting = [[NSUserDefaults standardUserDefaults] objectForKey:disableComplexRoutingKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:disableComplexRoutingKey] : NO;
        _followTheRoute = [[NSUserDefaults standardUserDefaults] objectForKey:followTheRouteKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:followTheRouteKey] : NO;
        _followTheGpxRoute = [[NSUserDefaults standardUserDefaults] objectForKey:followTheGpxRouteKey] ? [[NSUserDefaults standardUserDefaults] stringForKey:followTheGpxRouteKey] : nil;
        _arrivalDistanceFactor = [OAProfileDouble withKey:arrivalDistanceFactorKey defValue:1.0];
        [_registeredPreferences setObject:_arrivalDistanceFactor forKey:@"arrival_distance_factor"];
        _enableTimeConditionalRouting = [OAProfileBoolean withKey:enableTimeConditionalRoutingKey defValue:NO];
        [_registeredPreferences setObject:_enableTimeConditionalRouting forKey:@"enable_time_conditional_routing"];
        _useIntermediatePointsNavigation = [[NSUserDefaults standardUserDefaults] objectForKey:useIntermediatePointsNavigationKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:useIntermediatePointsNavigationKey] : NO;
        
        _disableOffrouteRecalc = [OAProfileBoolean withKey:disableOffrouteRecalcKey defValue:NO];
        _disableWrongDirectionRecalc = [OAProfileBoolean withKey:disableWrongDirectionRecalcKey defValue:NO];
        
        [_registeredPreferences setObject:_disableOffrouteRecalc forKey:@"disable_offroute_recalc"];
        [_registeredPreferences setObject:_disableWrongDirectionRecalc forKey:@"disable_wrong_direction_recalc"];
        
        _autoFollowRoute = [OAProfileInteger withKey:autoFollowRouteKey defValue:0];
        [_autoFollowRoute setModeDefaultValue:@15 mode:[OAApplicationMode CAR]];
        [_autoFollowRoute setModeDefaultValue:@15 mode:[OAApplicationMode BICYCLE]];
        [_autoFollowRoute setModeDefaultValue:@0 mode:[OAApplicationMode PEDESTRIAN]];
        [_registeredPreferences setObject:_autoFollowRoute forKey:@"auto_follow_route"];
        
        _autoZoomMap = [OAProfileBoolean withKey:autoZoomMapKey defValue:NO];
        [_autoZoomMap setModeDefaultValue:@YES mode:[OAApplicationMode CAR]];
        [_autoZoomMap setModeDefaultValue:@NO mode:[OAApplicationMode BICYCLE]];
        [_autoZoomMap setModeDefaultValue:@NO mode:[OAApplicationMode PEDESTRIAN]];
        [_registeredPreferences setObject:_autoZoomMap forKey:@"auto_zoom_map_on_off"];

        _autoZoomMapScale = [OAProfileAutoZoomMap withKey:autoZoomMapScaleKey defValue:AUTO_ZOOM_MAP_FAR];
        [_autoZoomMapScale setModeDefaultValue:@(AUTO_ZOOM_MAP_FAR) mode:[OAApplicationMode CAR]];
        [_autoZoomMapScale setModeDefaultValue:@(AUTO_ZOOM_MAP_CLOSE) mode:[OAApplicationMode BICYCLE]];
        [_autoZoomMapScale setModeDefaultValue:@(AUTO_ZOOM_MAP_CLOSE) mode:[OAApplicationMode PEDESTRIAN]];
        [_registeredPreferences setObject:_autoZoomMapScale forKey:@"auto_zoom_map_scale"];

        _keepInforming = [OAProfileInteger withKey:keepInformingKey defValue:0];
        [_keepInforming setModeDefaultValue:@0 mode:[OAApplicationMode CAR]];
        [_keepInforming setModeDefaultValue:@0 mode:[OAApplicationMode BICYCLE]];
        [_keepInforming setModeDefaultValue:@0 mode:[OAApplicationMode PEDESTRIAN]];
        [_registeredPreferences setObject:_keepInforming forKey:@"keep_informing"];

        _settingAllow3DView = [OAProfileBoolean withKey:settingEnable3DViewKey defValue:YES];
        _drivingRegionAutomatic = [OAProfileBoolean withKey:drivingRegionAutomaticKey defValue:YES];
        _drivingRegion = [OAProfileDrivingRegion withKey:drivingRegionKey defValue:[OADrivingRegion getDefaultRegion]];
        _metricSystem = [OAProfileMetricSystem withKey:metricSystemKey defValue:KILOMETERS_AND_METERS];
        _metricSystemChangedManually = [OAProfileBoolean withKey:metricSystemChangedManuallyKey defValue:NO];
        _settingGeoFormat = [OAProfileInteger withKey:settingGeoFormatKey defValue:MAP_GEO_FORMAT_DEGREES];
        _settingExternalInputDevice = [OAProfileInteger withKey:settingExternalInputDeviceKey defValue:NO_EXTERNAL_DEVICE];
        
        [_registeredPreferences setObject:_settingAllow3DView forKey:@"enable_3d_view"];
        [_registeredPreferences setObject:_drivingRegionAutomatic forKey:@"driving_region_automatic"];
        [_registeredPreferences setObject:_drivingRegion forKey:@"default_driving_region"];
        [_registeredPreferences setObject:_metricSystem forKey:@"default_metric_system"];
        [_registeredPreferences setObject:_metricSystemChangedManually forKey:@"metric_system_changed_manually"];
        [_registeredPreferences setObject:_settingGeoFormat forKey:@"coordinates_format"];
        [_registeredPreferences setObject:_settingExternalInputDevice forKey:@"external_input_device"];
        
        _speedSystem = [OAProfileSpeedConstant withKey:speedSystemKey defValue:KILOMETERS_PER_HOUR];
        _angularUnits = [OAProfileAngularConstant withKey:angularUnitsKey defValue:DEGREES];
        _speedLimitExceedKmh = [OAProfileDouble withKey:speedLimitExceedKey defValue:5.f];
        _switchMapDirectionToCompass = [OAProfileDouble withKey:switchMapDirectionToCompassKey defValue:0.f];
        
        [_registeredPreferences setObject:_switchMapDirectionToCompass forKey:@"speed_for_map_to_direction_of_movement"];
        [_registeredPreferences setObject:_speedLimitExceedKmh forKey:@"speed_limit_exceed"];
        [_registeredPreferences setObject:_angularUnits forKey:@"angular_measurement"];
        [_registeredPreferences setObject:_speedSystem forKey:@"default_speed_system"];
        
        _routeRecalculationDistance = [OAProfileDouble withKey:routeRecalculationDistanceKey defValue:0.];
        [_registeredPreferences setObject:_routeRecalculationDistance forKey:@"routing_recalc_distance"];

        _showTrafficWarnings = [OAProfileBoolean withKey:showTrafficWarningsKey defValue:NO];
        [_showTrafficWarnings setModeDefaultValue:@YES mode:[OAApplicationMode CAR]];
        [_registeredPreferences setObject:_showTrafficWarnings forKey:@"show_traffic_warnings"];
        
        _showPedestrian = [OAProfileBoolean withKey:showPedestrianKey defValue:NO];
        [_showPedestrian setModeDefaultValue:@YES mode:[OAApplicationMode CAR]];
        [_registeredPreferences setObject:_showPedestrian forKey:@"show_pedestrian"];

        _showCameras = [OAProfileBoolean withKey:showCamerasKey defValue:NO];
        [_registeredPreferences setObject:_showCameras forKey:@"show_cameras"];
        _showTunnels = [OAProfileBoolean withKey:showTunnelsKey defValue:NO];
        [_showTunnels setModeDefaultValue:@YES mode:[OAApplicationMode CAR]];
        [_registeredPreferences setObject:_showTunnels forKey:@"show_tunnels"];

        _showLanes = [OAProfileBoolean withKey:showLanesKey defValue:NO];
        [_showLanes setModeDefaultValue:@YES mode:[OAApplicationMode CAR]];
        [_showLanes setModeDefaultValue:@YES mode:[OAApplicationMode BICYCLE]];
        [_registeredPreferences setObject:_showLanes forKey:@"show_lanes"];
        
        _speakStreetNames = [OAProfileBoolean withKey:speakStreetNamesKey defValue:YES];
        _speakTrafficWarnings = [OAProfileBoolean withKey:speakTrafficWarningsKey defValue:YES];
        _speakPedestrian = [OAProfileBoolean withKey:speakPedestrianKey defValue:YES];
        _speakSpeedLimit = [OAProfileBoolean withKey:speakSpeedLimitKey defValue:YES];
        _speakTunnels = [OAProfileBoolean withKey:speakTunnels defValue:NO];
        _speakCameras = [OAProfileBoolean withKey:speakCamerasKey defValue:NO];
        _announceNearbyFavorites = [OAProfileBoolean withKey:announceNearbyFavoritesKey defValue:NO];
        _announceNearbyPoi = [OAProfileBoolean withKey:announceNearbyPoiKey defValue:NO];
        
        [_registeredPreferences setObject:_speakStreetNames forKey:@"speak_street_names"];
        [_registeredPreferences setObject:_speakTrafficWarnings forKey:@"speak_traffic_warnings"];
        [_registeredPreferences setObject:_speakPedestrian forKey:@"speak_pedestrian"];
        [_registeredPreferences setObject:_speakSpeedLimit forKey:@"speak_speed_limit"];
        [_registeredPreferences setObject:_speakCameras forKey:@"speak_cameras"];
        [_registeredPreferences setObject:_speakTunnels forKey:@"speak_tunnels"];
        [_registeredPreferences setObject:_announceNearbyFavorites forKey:@"announce_nearby_favorites"];
        [_registeredPreferences setObject:_announceNearbyPoi forKey:@"announce_nearby_poi"];

        _voiceProvider = [OAProfileString withKey:voiceProviderKey defValue:@""];
        _announceWpt = [OAProfileBoolean withKey:announceWptKey defValue:YES];
        _showScreenAlerts = [OAProfileBoolean withKey:showScreenAlertsKey defValue:NO];
        
        [_registeredPreferences setObject:_voiceProvider forKey:@"voice_provider"];
        [_registeredPreferences setObject:_announceWpt forKey:@"announce_wpt"];
        [_registeredPreferences setObject:_showScreenAlerts forKey:@"show_routing_alarms"];

        _showGpxWpt = [[NSUserDefaults standardUserDefaults] objectForKey:showGpxWptKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:showGpxWptKey] : YES;

        _simulateRouting = [[NSUserDefaults standardUserDefaults] objectForKey:simulateRoutingKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:simulateRoutingKey] : NO;

        _useOsmLiveForRouting = [[NSUserDefaults standardUserDefaults] objectForKey:useOsmLiveForRoutingKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:useOsmLiveForRoutingKey] : YES;

        _showNearbyFavorites = [OAProfileBoolean withKey:showNearbyFavoritesKey defValue:NO];
        _showNearbyPoi = [OAProfileBoolean withKey:showNearbyPoiKey defValue:NO];
        [_registeredPreferences setObject:_showNearbyPoi forKey:@"show_nearby_poi"];
        [_registeredPreferences setObject:_showNearbyFavorites forKey:@"show_nearby_favorites"];
        
        _gpxRouteCalcOsmandParts = [[NSUserDefaults standardUserDefaults] objectForKey:gpxRouteCalcOsmandPartsKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:gpxRouteCalcOsmandPartsKey] : YES;
        _gpxCalculateRtept = [[NSUserDefaults standardUserDefaults] objectForKey:gpxCalculateRteptKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:gpxCalculateRteptKey] : YES;
        _gpxRouteCalc = [[NSUserDefaults standardUserDefaults] objectForKey:gpxRouteCalcKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:gpxRouteCalcKey] : NO;

        _voiceMute = [OAProfileBoolean withKey:voiceMuteKey defValue:NO];
        [_registeredPreferences setObject:_voiceMute forKey:@"voice_mute"];
        
        _interruptMusic = [OAProfileBoolean withKey:interruptMusicKey defValue:NO];
        [_registeredPreferences setObject:_interruptMusic forKey:@"interrupt_music"];
        _snapToRoad = [OAProfileBoolean withKey:snapToRoadKey defValue:NO];
        [_snapToRoad setModeDefaultValue:@YES mode:[OAApplicationMode CAR]];
        [_snapToRoad setModeDefaultValue:@YES mode:[OAApplicationMode BICYCLE]];
        [_registeredPreferences setObject:_snapToRoad forKey:@"snap_to_road"];
        
        _poiFiltersOrder = [OAProfileStringList withKey:poiFiltersOrderKey defValue:nil];
        _inactivePoiFilters = [OAProfileStringList withKey:inactivePoiFiltersKey defValue:nil];
        [_registeredPreferences setObject:_poiFiltersOrder forKey:@"poi_filters_order"];
        [_registeredPreferences setObject:_inactivePoiFilters forKey:@"inactive_poi_filters"];
        
        _rulerMode = [[NSUserDefaults standardUserDefaults] objectForKey:rulerModeKey] ? [[NSUserDefaults standardUserDefaults] integerForKey:rulerModeKey] : RULER_MODE_DARK;
        
        _osmUserName = [[NSUserDefaults standardUserDefaults] objectForKey:osmUserNameKey] ? [[NSUserDefaults standardUserDefaults] stringForKey:osmUserNameKey] : nil;
        _osmUserPassword = [[NSUserDefaults standardUserDefaults] objectForKey:osmPasswordKey] ? [[NSUserDefaults standardUserDefaults] stringForKey:osmPasswordKey] : nil;
        _offlineEditing = [[NSUserDefaults standardUserDefaults] objectForKey:offlineEditingKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:offlineEditingKey] : NO;
        
        _onlinePhotosRowCollapsed = [[NSUserDefaults standardUserDefaults] objectForKey:onlinePhotosRowCollapsedKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:onlinePhotosRowCollapsedKey] : NO;
        _mapillaryFirstDialogShown = [[NSUserDefaults standardUserDefaults] objectForKey:mapillaryFirstDialogShownKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:mapillaryFirstDialogShownKey] : NO;
        
        _useMapillaryFilter = [[NSUserDefaults standardUserDefaults] objectForKey:useMapillaryFilterKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:useMapillaryFilterKey] : NO;
        _mapillaryFilterUserKey = [[NSUserDefaults standardUserDefaults] objectForKey:mapillaryFilterUserKeyKey] ? [[NSUserDefaults standardUserDefaults] stringForKey:mapillaryFilterUserKeyKey] : nil;
        _mapillaryFilterUserName = [[NSUserDefaults standardUserDefaults] objectForKey:mapillaryFilterUserNameKey] ? [[NSUserDefaults standardUserDefaults] stringForKey:mapillaryFilterUserNameKey] : nil;
        _mapillaryFilterStartDate = [[NSUserDefaults standardUserDefaults] objectForKey:mapillaryFilterStartDateKey] ? [[NSUserDefaults standardUserDefaults] doubleForKey:mapillaryFilterStartDateKey] : 0;
        _mapillaryFilterEndDate = [[NSUserDefaults standardUserDefaults] objectForKey:mapillaryFilterEndDateKey] ? [[NSUserDefaults standardUserDefaults] doubleForKey:mapillaryFilterEndDateKey] : 0;
        _mapillaryFilterPano = [[NSUserDefaults standardUserDefaults] objectForKey:mapillaryFilterPanoKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:mapillaryFilterPanoKey] : NO;

        _quickActionIsOn = [OAProfileBoolean withKey:quickActionIsOnKey defValue:NO];
        _quickActionsList = [[NSUserDefaults standardUserDefaults] objectForKey:quickActionsListKey] ? [[NSUserDefaults standardUserDefaults] stringForKey:quickActionsListKey] : nil;
        
        [_registeredPreferences setObject:_quickActionIsOn forKey:@"quick_action_state"];
        
        _quickActionPortraitX = [OAProfileDouble withKey:quickActionPortraitXKey defValue:0];
        _quickActionPortraitY = [OAProfileDouble withKey:quickActionPortraitYKey defValue:0];
        _quickActionLandscapeX = [OAProfileDouble withKey:quickActionLandscapeXKey defValue:0];
        _quickActionLandscapeY = [OAProfileDouble withKey:quickActionLandscapeYKey defValue:0];
        [_registeredPreferences setObject:_quickActionPortraitX forKey:@"quick_fab_margin_x_portrait_margin"];
        [_registeredPreferences setObject:_quickActionPortraitY forKey:@"quick_fab_margin_y_portrait_margin"];
        [_registeredPreferences setObject:_quickActionLandscapeX forKey:@"quick_fab_margin_x_landscape_margin"];
        [_registeredPreferences setObject:_quickActionLandscapeY forKey:@"quick_fab_margin_y_landscape_margin"];
    
        _contourLinesZoom = [OAProfileString withKey:contourLinesZoomKey defValue:@""];
        [_registeredPreferences setObject:_contourLinesZoom forKey:@"contour_lines_zoom"];
        
        // riirection Appearance
        _activeMarkers = [OAProfileActiveMarkerConstant withKey:activeMarkerKey defValue:ONE_ACTIVE_MARKER];
        [_registeredPreferences setObject:_activeMarkers forKey:@"displayed_markers_widgets_count"];
        _distanceIndicationVisibility = [OAProfileBoolean withKey:mapDistanceIndicationVisabilityKey defValue:YES];
        [_registeredPreferences setObject:_distanceIndicationVisibility forKey:@"markers_distance_indication_enabled"];
        _distanceIndication = [OAProfileDistanceIndicationConstant withKey:mapDistanceIndicationKey defValue:TOP_BAR_DISPLAY];
        [_registeredPreferences setObject:_distanceIndication forKey:@"map_markers_mode"];
        _arrowsOnMap = [OAProfileBoolean withKey:mapArrowsOnMapKey defValue:YES];
        [_registeredPreferences setObject:_arrowsOnMap forKey:@"show_arrows_to_first_markers"];
        _directionLines = [OAProfileBoolean withKey:mapDirectionLinesKey defValue:YES];
        [_registeredPreferences setObject:_directionLines forKey:@"show_lines_to_first_markers"];
        
        [self fetchImpassableRoads];
    }
    return self;
}

- (void) registerPreference:(OAProfileSetting *)pref forKey:(NSString *)key
{
    [_registeredPreferences setObject:pref forKey:key];
}

- (NSMapTable<NSString *, OAProfileSetting *> *) getRegisteredSettings
{
    return _registeredPreferences;
}

- (OAProfileSetting *) getSettingById:(NSString *)stringId
{
    return [_registeredPreferences objectForKey:stringId];
}

- (void) resetPreferencesForProfile:(OAApplicationMode *)appMode
{
    for (OAProfileSetting *value in [_registeredPreferences objectEnumerator].allObjects)
    {
        [value resetModeToDefault:appMode];
    }
    
    for (OAProfileBoolean *value in [_customBooleanRoutingProps objectEnumerator].allObjects)
    {
        [value resetModeToDefault:appMode];
    }
    
    for (OAProfileString *value in [_customRoutingProps objectEnumerator].allObjects)
    {
        [value resetModeToDefault:appMode];
    }
    
    if (!appMode.isCustomProfile)
    {
        [self.userProfileName resetModeToDefault:appMode];
        [self.profileIconName resetModeToDefault:appMode];
        [self.profileIconColor resetModeToDefault:appMode];
    }
    
    [OAAppData.defaults resetProfileSettingsForMode:appMode];
    [[[OsmAndApp instance] widgetSettingResetObservable] notifyEventWithKey:appMode];
}

// Common Settings
- (void) setSettingShowMapRulet:(BOOL)settingShowMapRulet {
    _settingShowMapRulet = settingShowMapRulet;
    [[NSUserDefaults standardUserDefaults] setBool:_settingShowMapRulet forKey:settingShowMapRuletKey];
}

- (void) setSettingMapLanguage:(int)settingMapLanguage {
    _settingMapLanguage = settingMapLanguage;
    [[NSUserDefaults standardUserDefaults] setInteger:_settingMapLanguage forKey:settingMapLanguageKey];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
}

- (void) setSettingPrefMapLanguage:(NSString *)settingPrefMapLanguage
{
    _settingPrefMapLanguage = settingPrefMapLanguage;
    [[NSUserDefaults standardUserDefaults] setObject:_settingPrefMapLanguage forKey:settingPrefMapLanguageKey];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
}

- (void) setSettingMapLanguageShowLocal:(BOOL)settingMapLanguageShowLocal
{
    _settingMapLanguageShowLocal = settingMapLanguageShowLocal;
    [[NSUserDefaults standardUserDefaults] setBool:_settingMapLanguageShowLocal forKey:settingMapLanguageShowLocalKey];
}

- (void) setSettingMapLanguageTranslit:(BOOL)settingMapLanguageTranslit
{
    _settingMapLanguageTranslit = settingMapLanguageTranslit;
    [[NSUserDefaults standardUserDefaults] setBool:_settingMapLanguageTranslit forKey:settingMapLanguageTranslitKey];
}

- (void) setAppearanceMode:(int)appearanceMode
{
    [_appearanceMode set:appearanceMode];
    [_dayNightHelper forceUpdate];
}

- (void) setFirstMapIsDownloaded:(BOOL)firstMapIsDownloaded
{
    _firstMapIsDownloaded = firstMapIsDownloaded;
    [[NSUserDefaults standardUserDefaults] setBool:_firstMapIsDownloaded forKey:firstMapIsDownloadedKey];
}

- (void) setSettingShowZoomButton:(BOOL)settingShowZoomButton
{
    _settingShowZoomButton = settingShowZoomButton;
    [[NSUserDefaults standardUserDefaults] setInteger:_settingShowZoomButton forKey:settingZoomButtonKey];
}

- (void) setSettingMapArrows:(int)settingMapArrows
{
    _settingMapArrows = settingMapArrows;
    [[NSUserDefaults standardUserDefaults] setInteger:_settingMapArrows forKey:settingMapArrowsKey];
}

- (void) setSettingShowAltInDriveMode:(BOOL)settingShowAltInDriveMode
{
    _settingShowAltInDriveMode = settingShowAltInDriveMode;
    [[NSUserDefaults standardUserDefaults] setBool:_settingShowAltInDriveMode forKey:settingMapShowAltInDriveModeKey];
}

- (void) setSettingDoNotShowPromotions:(BOOL)settingDoNotShowPromotions
{
    _settingDoNotShowPromotions = settingDoNotShowPromotions;
    [[NSUserDefaults standardUserDefaults] setBool:_settingDoNotShowPromotions forKey:settingDoNotShowPromotionsKey];
}

- (void) setSettingUseAnalytics:(BOOL)settingUseAnalytics
{
    _settingUseAnalytics = settingUseAnalytics;
    [[NSUserDefaults standardUserDefaults] setBool:_settingUseAnalytics forKey:settingUseFirebaseKey];
}

- (void) setLiveUpdatesPurchased:(BOOL)liveUpdatesPurchased
{
    _liveUpdatesPurchased = liveUpdatesPurchased;
    [[NSUserDefaults standardUserDefaults] setBool:_liveUpdatesPurchased forKey:liveUpdatesPurchasedKey];
}

- (void) setSettingOsmAndLiveEnabled:(BOOL)settingOsmAndLiveEnabled
{
    _settingOsmAndLiveEnabled = settingOsmAndLiveEnabled;
    [[NSUserDefaults standardUserDefaults] setBool:_settingOsmAndLiveEnabled forKey:settingOsmAndLiveEnabledKey];
}

- (void) setBillingUserId:(NSString *)billingUserId
{
    _billingUserId = billingUserId;
    [[NSUserDefaults standardUserDefaults] setObject:_billingUserId forKey:billingUserIdKey];
}

-  (void) setBillingUserName:(NSString *)billingUserName
{
    _billingUserName = billingUserName;
    [[NSUserDefaults standardUserDefaults] setObject:_billingUserName forKey:billingUserNameKey];
}

- (void) setBillingUserToken:(NSString *)billingUserToken
{
    _billingUserToken = billingUserToken;
    [[NSUserDefaults standardUserDefaults] setObject:_billingUserToken forKey:billingUserTokenKey];
}

- (void) setBillingUserEmail:(NSString *)billingUserEmail
{
    _billingUserEmail = billingUserEmail;
    [[NSUserDefaults standardUserDefaults] setObject:_billingUserEmail forKey:billingUserEmailKey];
}

- (void) setBillingUserCountry:(NSString *)billingUserCountry
{
    _billingUserCountry = billingUserCountry;
    [[NSUserDefaults standardUserDefaults] setObject:_billingUserCountry forKey:billingUserCountryKey];
}

- (void) setBillingUserCountryDownloadName:(NSString *)billingUserCountryDownloadName
{
    _billingUserCountryDownloadName = billingUserCountryDownloadName;
    [[NSUserDefaults standardUserDefaults] setObject:_billingUserCountryDownloadName forKey:billingUserCountryDownloadNameKey];
}

- (void) setBillingHideUserName:(BOOL)billingHideUserName
{
    _billingHideUserName = billingHideUserName;
    [[NSUserDefaults standardUserDefaults] setBool:_billingHideUserName forKey:billingHideUserNameKey];
}

- (void) setLiveUpdatesPurchaseCancelledTime:(NSTimeInterval)liveUpdatesPurchaseCancelledTime
{
    _liveUpdatesPurchaseCancelledTime = liveUpdatesPurchaseCancelledTime;
    [[NSUserDefaults standardUserDefaults] setDouble:_liveUpdatesPurchaseCancelledTime forKey:liveUpdatesPurchaseCancelledTimeKey];
}

- (void) setLiveUpdatesPurchaseCancelledFirstDlgShown:(BOOL)liveUpdatesPurchaseCancelledFirstDlgShown
{
    _liveUpdatesPurchaseCancelledFirstDlgShown = liveUpdatesPurchaseCancelledFirstDlgShown;
    [[NSUserDefaults standardUserDefaults] setBool:_liveUpdatesPurchaseCancelledFirstDlgShown forKey:liveUpdatesPurchaseCancelledFirstDlgShownKey];
}

- (void) setLiveUpdatesPurchaseCancelledSecondDlgShown:(BOOL)liveUpdatesPurchaseCancelledSecondDlgShown
{
    _liveUpdatesPurchaseCancelledSecondDlgShown = liveUpdatesPurchaseCancelledSecondDlgShown;
    [[NSUserDefaults standardUserDefaults] setBool:_liveUpdatesPurchaseCancelledSecondDlgShown forKey:liveUpdatesPurchaseCancelledSecondDlgShownKey];
}

- (void) setEmailSubscribed:(BOOL)emailSubscribed
{
    _emailSubscribed = emailSubscribed;
    [[NSUserDefaults standardUserDefaults] setBool:_emailSubscribed forKey:emailSubscribedKey];
}

- (void) setDisplayDonationSettings:(BOOL)displayDonationSettings
{
    _displayDonationSettings = displayDonationSettings;
    [[NSUserDefaults standardUserDefaults] setBool:_displayDonationSettings forKey:displayDonationSettingsKey];
}

- (void) setLastReceiptValidationDate:(NSDate *)lastReceiptValidationDate
{
    _lastReceiptValidationDate = lastReceiptValidationDate;
    [[NSUserDefaults standardUserDefaults] setDouble:[_lastReceiptValidationDate timeIntervalSince1970] forKey:lastReceiptValidationDateKey];
}

- (void) setEligibleForIntroductoryPrice:(BOOL)eligibleForIntroductoryPrice
{
    _eligibleForIntroductoryPrice = eligibleForIntroductoryPrice;
    [[NSUserDefaults standardUserDefaults] setBool:_eligibleForIntroductoryPrice forKey:eligibleForIntroductoryPriceKey];
}

- (void) setEligibleForSubscriptionOffer:(BOOL)eligibleForSubscriptionOffer
{
    _eligibleForSubscriptionOffer = eligibleForSubscriptionOffer;
    [[NSUserDefaults standardUserDefaults] setBool:_eligibleForSubscriptionOffer forKey:eligibleForSubscriptionOfferKey];
}

- (void) setShouldShowWhatsNewScreen:(BOOL)shouldShowWhatsNewScreen
{
    _shouldShowWhatsNewScreen = shouldShowWhatsNewScreen;
    [[NSUserDefaults standardUserDefaults] setBool:_shouldShowWhatsNewScreen forKey:shouldShowWhatsNewScreenKey];
}

// Map Settings
- (void) setShowFavorites:(BOOL)mapSettingShowFavorites
{
    //if (_mapSettingShowFavorites == mapSettingShowFavorites)
    //    return;
    
    [_mapSettingShowFavorites set:mapSettingShowFavorites];

    OsmAndAppInstance app = [OsmAndApp instance];
    if ([_mapSettingShowFavorites get])
    {
        if (![app.data.mapLayersConfiguration isLayerVisible:kFavoritesLayerId])
        {
            [app.data.mapLayersConfiguration setLayer:kFavoritesLayerId
                                           Visibility:YES];
        }
    }
    else
    {
        if ([app.data.mapLayersConfiguration isLayerVisible:kFavoritesLayerId])
        {
            [app.data.mapLayersConfiguration setLayer:kFavoritesLayerId
                                           Visibility:NO];
        }
    }
}

- (void) setShowPoiLabel:(BOOL)mapSettingShowPoiLabel
{
    [_mapSettingShowPoiLabel set:mapSettingShowPoiLabel];
    [[[OsmAndApp instance] mapSettingsChangeObservable] notifyEvent];
}

- (void) setShowOfflineEdits:(BOOL)mapSettingShowOfflineEdits
{
    [_mapSettingShowOfflineEdits set:mapSettingShowOfflineEdits];
    
    OsmAndAppInstance app = [OsmAndApp instance];
    if ([_mapSettingShowOfflineEdits get])
    {
        if (![app.data.mapLayersConfiguration isLayerVisible:kOsmEditsLayerId])
        {
            [app.data.mapLayersConfiguration setLayer:kOsmEditsLayerId
                                           Visibility:YES];
        }
    }
    else
    {
        if ([app.data.mapLayersConfiguration isLayerVisible:kOsmEditsLayerId])
        {
            [app.data.mapLayersConfiguration setLayer:kOsmEditsLayerId
                                           Visibility:NO];
        }
    }
}

- (void) setShowOnlineNotes:(BOOL)mapSettingShowOnlineNotes
{
    [_mapSettingShowOnlineNotes set:mapSettingShowOnlineNotes];
    
    OsmAndAppInstance app = [OsmAndApp instance];
    if ([_mapSettingShowOnlineNotes get])
    {
        if (![app.data.mapLayersConfiguration isLayerVisible:kOsmBugsLayerId])
        {
            [app.data.mapLayersConfiguration setLayer:kOsmBugsLayerId
                                           Visibility:YES];
        }
    }
    else
    {
        if ([app.data.mapLayersConfiguration isLayerVisible:kOsmBugsLayerId])
        {
            [app.data.mapLayersConfiguration setLayer:kOsmBugsLayerId
                                           Visibility:NO];
        }
    }
}

- (void) setMapSettingTrackRecording:(BOOL)mapSettingTrackRecording
{
    _mapSettingTrackRecording = mapSettingTrackRecording;
    [[NSUserDefaults standardUserDefaults] setBool:_mapSettingTrackRecording forKey:mapSettingTrackRecordingKey];
    [[[OsmAndApp instance] trackStartStopRecObservable] notifyEvent];
}

- (void) setMapSettingVisibleGpx:(NSArray *)mapSettingVisibleGpx
{
    _mapSettingVisibleGpx = mapSettingVisibleGpx;
    [[NSUserDefaults standardUserDefaults] setObject:_mapSettingVisibleGpx forKey:mapSettingVisibleGpxKey];
}

- (void) setPlugins:(NSSet<NSString *> *)plugins
{
    _plugins = plugins;
    [[NSUserDefaults standardUserDefaults] setObject:[_plugins allObjects] forKey:pluginsKey];
}

- (NSSet<NSString *> *) getEnabledPlugins
{
    NSMutableSet<NSString *> *res = [NSMutableSet set];
    for (NSString *p in _plugins)
    {
        if (![p hasPrefix:@"-"])
            [res addObject:p];
    }
    return [NSSet setWithSet:res];
}

- (NSSet<NSString *> *) getPlugins
{
    return _plugins;
}

- (void) enablePlugin:(NSString *)pluginId enable:(BOOL)enable
{
    NSMutableSet<NSString*> *set = [NSMutableSet setWithSet:[self getPlugins]];
    if (enable)
    {
        [set removeObject:[@"-"  stringByAppendingString:pluginId]];
        [set addObject:pluginId];
    }
    else
    {
        [set removeObject:pluginId];
        [set addObject:[@"-" stringByAppendingString:pluginId]];
    }
    if (![set isEqualToSet:_plugins])
        [self setPlugins:set];
}

- (void) setMapSettingShowRecordingTrack:(BOOL)mapSettingShowRecordingTrack
{
    _mapSettingShowRecordingTrack = mapSettingShowRecordingTrack;
    [[NSUserDefaults standardUserDefaults] setBool:_mapSettingShowRecordingTrack forKey:mapSettingShowRecordingTrackKey];
}

- (void) setMapSettingActiveRouteFilePath:(NSString *)mapSettingActiveRouteFilePath
{
    _mapSettingActiveRouteFilePath = mapSettingActiveRouteFilePath;
    [[NSUserDefaults standardUserDefaults] setObject:_mapSettingActiveRouteFilePath forKey:mapSettingActiveRouteFilePathKey];
}

- (void) setMapSettingActiveRouteVariantType:(int)mapSettingActiveRouteVariantType
{
    _mapSettingActiveRouteVariantType = mapSettingActiveRouteVariantType;
    [[NSUserDefaults standardUserDefaults] setInteger:_mapSettingActiveRouteVariantType forKey:mapSettingActiveRouteVariantTypeKey];
}

- (void) setDiscountId:(NSInteger)discountId
{
    _discountId = discountId;
    [[NSUserDefaults standardUserDefaults] setInteger:discountId forKey:discountIdKey];
}

- (void) setDiscountShowNumberOfStarts:(NSInteger)discountShowNumberOfStarts
{
    _discountShowNumberOfStarts = discountShowNumberOfStarts;
    [[NSUserDefaults standardUserDefaults] setInteger:discountShowNumberOfStarts forKey:discountShowNumberOfStartsKey];
}

- (void) setDiscountTotalShow:(NSInteger)discountTotalShow
{
    _discountTotalShow = discountTotalShow;
    [[NSUserDefaults standardUserDefaults] setInteger:discountTotalShow forKey:discountTotalShowKey];
}

- (void) setDiscountShowDatetime:(double)discountShowDatetime
{
    _discountShowDatetime = discountShowDatetime;
    [[NSUserDefaults standardUserDefaults] setInteger:discountShowDatetime forKey:discountShowDatetimeKey];
}

- (void) setLastSearchedCity:(unsigned long long)lastSearchedCity
{
    _lastSearchedCity = lastSearchedCity;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedLongLong:lastSearchedCity] forKey:lastSearchedCityKey];
}

- (void)  setLastSearchedCityName:(NSString *)lastSearchedCityName
{
    _lastSearchedCityName = lastSearchedCityName;
    [[NSUserDefaults standardUserDefaults] setObject:lastSearchedCityName forKey:lastSearchedCityNameKey];
}

- (void)  setLastSearchedPoint:(CLLocation *)lastSearchedPoint
{
    _lastSearchedPoint = lastSearchedPoint;
    if (lastSearchedPoint)
    {
        [[NSUserDefaults standardUserDefaults] setDouble:lastSearchedPoint.coordinate.latitude forKey:lastSearchedPointLatKey];
        [[NSUserDefaults standardUserDefaults] setDouble:lastSearchedPoint.coordinate.longitude forKey:lastSearchedPointLonKey];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:lastSearchedPointLatKey];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:lastSearchedPointLonKey];
    }
}

- (void) setApplicationMode:(OAApplicationMode *)applicationMode
{
    OAApplicationMode *prevAppMode = _applicationMode;
    _applicationMode = applicationMode;
    if (prevAppMode != _applicationMode)
    {
        [[NSUserDefaults standardUserDefaults] setObject:applicationMode.stringKey forKey:applicationModeKey];
        [[[OsmAndApp instance].data applicationModeChangedObservable] notifyEventWithKey:prevAppMode];
    }
}

- (void) setDefaultApplicationMode:(OAApplicationMode *)defaultApplicationMode
{
    _defaultApplicationMode = defaultApplicationMode;
    [[NSUserDefaults standardUserDefaults] setObject:defaultApplicationMode.stringKey forKey:defaultApplicationModeKey];
}

- (void) setAvailableApplicationModes:(NSString *)availableApplicationModes
{
    _availableApplicationModes = availableApplicationModes;
    [[NSUserDefaults standardUserDefaults] setObject:availableApplicationModes forKey:availableApplicationModesKey];
    [[[OsmAndApp instance] availableAppModesChangedObservable] notifyEvent];
}

- (void) showGpx:(NSArray<NSString *> *)filePaths update:(BOOL)update
{
    BOOL added = NO;
    NSMutableArray *arr = [NSMutableArray arrayWithArray:_mapSettingVisibleGpx];
    for (NSString *filePath in filePaths)
    {
        if (![arr containsObject:filePath])
        {
            [arr addObject:filePath];
            added = YES;
        }
    }
    
    if (added)
    {
        self.mapSettingVisibleGpx = arr;
        if (update)
        {
            [[[OsmAndApp instance] updateGpxTracksOnMapObservable] notifyEvent];
        }
    }
}

- (void) showGpx:(NSArray<NSString *> *)filePaths
{
    [self showGpx:filePaths update:YES];
}

- (void) updateGpx:(NSArray<NSString *> *)filePaths
{
    BOOL added = NO;
    BOOL removed = NO;
    NSMutableArray *arr = [NSMutableArray arrayWithArray:_mapSettingVisibleGpx];
    for (NSString *filePath in filePaths)
    {
        if (![arr containsObject:filePath])
        {
            added = YES;
            break;
        }
    }
    for (NSString *visible in arr)
    {
        if (![filePaths containsObject:visible])
        {
            removed = YES;
            break;
        }
    }

    if (added || removed)
    {
        self.mapSettingVisibleGpx = [NSMutableArray arrayWithArray:filePaths];
        [[[OsmAndApp instance] updateGpxTracksOnMapObservable] notifyEvent];
    }
}

- (void) hideGpx:(NSArray<NSString *> *)filePaths
{
    [self hideGpx:filePaths update:YES];
}

- (void) hideGpx:(NSArray<NSString *> *)filePaths update:(BOOL)update
{
    BOOL removed = NO;
    NSMutableArray *arr = [NSMutableArray arrayWithArray:_mapSettingVisibleGpx];
    NSMutableArray *arrToDelete = [NSMutableArray array];
    for (NSString *filePath in filePaths)
    {
        if ([arr containsObject:filePath])
        {
            [arrToDelete addObject:filePath];
            removed = YES;
        }
    }
    [arr removeObjectsInArray:arrToDelete];
    self.mapSettingVisibleGpx = arr;
    
    if (removed && update)
        [[[OsmAndApp instance] updateGpxTracksOnMapObservable] notifyEvent];
}

- (void) hideRemovedGpx
{
    OsmAndAppInstance app = [OsmAndApp instance];
    NSMutableArray *arr = [NSMutableArray arrayWithArray:_mapSettingVisibleGpx];
    NSMutableArray *arrToDelete = [NSMutableArray array];
    for (NSString *filepath in arr)
    {
        OAGPX *gpx = [[OAGPXDatabase sharedDb] getGPXItem:filepath];
        NSString *fileName = filepath.lastPathComponent;
        NSString *filenameWithoutPrefix = nil;
        if ([fileName hasSuffix:@"_osmand_backup"])
            filenameWithoutPrefix = [fileName stringByReplacingOccurrencesOfString:@"_osmand_backup" withString:@""];
        
        NSString *path = [app.gpxPath stringByAppendingPathComponent:filenameWithoutPrefix ? filenameWithoutPrefix : gpx.file];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path] || !gpx)
            [arrToDelete addObject:filepath];
    }
    [arr removeObjectsInArray:arrToDelete];
    self.mapSettingVisibleGpx = [NSArray arrayWithArray:arr];
}

- (NSString *) getFormattedTrackInterval:(int)value
{
    NSString *res;
    if (value == 0)
        res = OALocalizedString(@"rec_interval_minimum");
    else if (value > 90)
        res = [NSString stringWithFormat:@"%d %@", (int)(value / 60.0), OALocalizedString(@"units_minutes_short")];
    else
        res = [NSString stringWithFormat:@"%d %@", value, OALocalizedString(@"units_seconds_short")];
    return res;
}

- (NSString *) getModeKey:(NSString *)key mode:(OAApplicationMode *)mode
{
    return [NSString stringWithFormat:@"%@_%@", key, mode.stringKey];
}

- (OAProfileBoolean *) getCustomRoutingBooleanProperty:(NSString *)attrName defaultValue:(BOOL)defaultValue
{
    OAProfileBoolean *value = [_customBooleanRoutingProps objectForKey:attrName];
    if (!value)
    {
        value = [OAProfileBoolean withKey:[NSString stringWithFormat:@"prouting_%@", attrName] defValue:defaultValue];
        [_customBooleanRoutingProps setObject:value forKey:attrName];
    }
    return value;
}

- (OAProfileString *) getCustomRoutingProperty:(NSString *)attrName defaultValue:(NSString *)defaultValue
{
    OAProfileString *value = [_customRoutingProps objectForKey:attrName];
    if (!value)
    {
        value = [OAProfileString withKey:[NSString stringWithFormat:@"prouting_%@", attrName] defValue:defaultValue];
        [_customRoutingProps setObject:value forKey:attrName];
    }
    return value;
}


// navigation settings
- (void) setUseFastRecalculation:(BOOL)useFastRecalculation
{
    _useFastRecalculation = useFastRecalculation;
    [[NSUserDefaults standardUserDefaults] setBool:_useFastRecalculation forKey:useFastRecalculationKey];
}

- (void) setDisableComplexRouting:(BOOL)disableComplexRouting
{
    _disableComplexRouting = disableComplexRouting;
    [[NSUserDefaults standardUserDefaults] setBool:_disableComplexRouting forKey:disableComplexRoutingKey];
}

- (void) setFollowTheRoute:(BOOL)followTheRoute
{
    _followTheRoute = followTheRoute;
    [[NSUserDefaults standardUserDefaults] setBool:_followTheRoute forKey:followTheRouteKey];
    [[[OsmAndApp instance] followTheRouteObservable] notifyEvent];
}

- (void)setFollowTheGpxRoute:(NSString *)followTheGpxRoute
{
    _followTheGpxRoute = followTheGpxRoute;
    [[NSUserDefaults standardUserDefaults] setObject:_followTheGpxRoute forKey:followTheGpxRouteKey];
}

- (void) setUseIntermediatePointsNavigation:(BOOL)useIntermediatePointsNavigation
{
    _useIntermediatePointsNavigation = useIntermediatePointsNavigation;
    [[NSUserDefaults standardUserDefaults] setBool:_useIntermediatePointsNavigation forKey:useIntermediatePointsNavigationKey];
}

- (void) setGpxRouteCalcOsmandParts:(BOOL)gpxRouteCalcOsmandParts
{
    _gpxRouteCalcOsmandParts = gpxRouteCalcOsmandParts;
    [[NSUserDefaults standardUserDefaults] setBool:_gpxRouteCalcOsmandParts forKey:gpxRouteCalcOsmandPartsKey];
}

- (void) setShowGpxWpt:(BOOL)showGpxWpt
{
    _showGpxWpt = showGpxWpt;
    [[NSUserDefaults standardUserDefaults] setBool:_showGpxWpt forKey:showGpxWptKey];
}

- (void) setSimulateRouting:(BOOL)simulateRouting
{
    _simulateRouting = simulateRouting;
    [[NSUserDefaults standardUserDefaults] setBool:_simulateRouting forKey:simulateRoutingKey];
    [[[OsmAndApp instance] simulateRoutingObservable] notifyEvent];
}

- (void) setUseOsmLiveForRouting:(BOOL)useOsmLiveForRouting
{
    _useOsmLiveForRouting = useOsmLiveForRouting;
    [[NSUserDefaults standardUserDefaults] setBool:_useOsmLiveForRouting forKey:useOsmLiveForRoutingKey];
}

- (void) setGpxCalculateRtept:(BOOL)gpxCalculateRtept
{
    _gpxCalculateRtept = gpxCalculateRtept;
    [[NSUserDefaults standardUserDefaults] setBool:_gpxCalculateRtept forKey:gpxCalculateRteptKey];
}

- (void) setGpxRouteCalc:(BOOL)gpxRouteCalc
{
    _gpxRouteCalc = gpxRouteCalc;
    [[NSUserDefaults standardUserDefaults] setBool:_gpxRouteCalc forKey:gpxRouteCalcKey];
}

- (void) setOsmUserName:(NSString *)osmUserName
{
    _osmUserName = osmUserName;
    [[NSUserDefaults standardUserDefaults] setObject:_osmUserName forKey:osmUserNameKey];
}

- (void) setOsmUserPassword:(NSString *)osmUserPassword
{
    _osmUserPassword = osmUserPassword;
    [[NSUserDefaults standardUserDefaults] setObject:_osmUserPassword forKey:osmPasswordKey];
}

-(void) setOfflineEditing:(BOOL)offlineEditing
{
    _offlineEditing = offlineEditing;
    [[NSUserDefaults standardUserDefaults] setBool:_offlineEditing forKey:offlineEditingKey];
}

- (void)setOnlinePhotosRowCollapsed:(BOOL)onlinePhotosRowCollapsed
{
    _onlinePhotosRowCollapsed = onlinePhotosRowCollapsed;
    [[NSUserDefaults standardUserDefaults] setBool:_onlinePhotosRowCollapsed forKey:onlinePhotosRowCollapsedKey];
}

- (void)setMapillaryFirstDialogShown:(BOOL)mapillaryFirstDialogShown
{
    _mapillaryFirstDialogShown = mapillaryFirstDialogShown;
    [[NSUserDefaults standardUserDefaults] setBool:_mapillaryFirstDialogShown forKey:mapillaryFirstDialogShownKey];
}

- (void) setUseMapillaryFilter:(BOOL)useMapillaryFilter
{
    _useMapillaryFilter = useMapillaryFilter;
    [[NSUserDefaults standardUserDefaults] setBool:_useMapillaryFilter forKey:useMapillaryFilterKey];
}

- (void)setMapillaryFilterUserKey:(NSString *)mapillaryFilterUserKey
{
    _mapillaryFilterUserKey = mapillaryFilterUserKey;
    [[NSUserDefaults standardUserDefaults] setObject:_mapillaryFilterUserKey forKey:mapillaryFilterUserKeyKey];
}

- (void)setMapillaryFilterUserName:(NSString *)mapillaryFilterUserName
{
    _mapillaryFilterUserName = mapillaryFilterUserName;
    [[NSUserDefaults standardUserDefaults] setObject:_mapillaryFilterUserName forKey:mapillaryFilterUserNameKey];
}

- (void)setMapillaryFilterStartDate:(double)mapillaryFilterStartDate
{
    _mapillaryFilterStartDate = mapillaryFilterStartDate;
    [[NSUserDefaults standardUserDefaults] setInteger:_mapillaryFilterStartDate forKey:mapillaryFilterStartDateKey];
}

- (void)setMapillaryFilterEndDate:(double)mapillaryFilterEndDate
{
    _mapillaryFilterEndDate = mapillaryFilterEndDate;
    [[NSUserDefaults standardUserDefaults] setInteger:_mapillaryFilterEndDate forKey:mapillaryFilterEndDateKey];
}

- (void) setMapillaryFilterPano:(BOOL)mapillaryFilterPano
{
    _mapillaryFilterPano = mapillaryFilterPano;
    [[NSUserDefaults standardUserDefaults] setBool:_mapillaryFilterPano forKey:mapillaryFilterPanoKey];
}

- (void) setQuickActionsList:(NSString *)quickActionsList
{
    _quickActionsList = quickActionsList;
    [[NSUserDefaults standardUserDefaults] setObject:_quickActionsList forKey:quickActionsListKey];
}

- (void) setQuickActionCoordinatesPortrait:(float)x y:(float)y
{
    [_quickActionPortraitX set:x];
    [_quickActionPortraitY set:y];
}

- (void) setQuickActionCoordinatesLandscape:(float)x y:(float)y
{
    [_quickActionLandscapeX set:x];
    [_quickActionLandscapeY set:y];
}

- (NSString *) getDefaultVoiceProvider
{
    NSString *currentLang = [OAUtilities currentLang];
    for (NSString *lang in _ttsAvailableVoices)
    {
        if ([lang isEqualToString:currentLang])
        {
            return lang;
        }
    }
    return @"en";
}

- (BOOL) getOverlayOpacitySliderVisibility
{
    return [_layerTransparencySeekbarMode get] == LAYER_TRANSPARENCY_SEEKBAR_MODE_OVERLAY || [_layerTransparencySeekbarMode get] == LAYER_TRANSPARENCY_SEEKBAR_MODE_ALL;
}

- (void) setOverlayOpacitySliderVisibility:(BOOL)visibility
{
    if (visibility)
        if ([_layerTransparencySeekbarMode get] == LAYER_TRANSPARENCY_SEEKBAR_MODE_UNDERLAY || [_layerTransparencySeekbarMode get] == LAYER_TRANSPARENCY_SEEKBAR_MODE_ALL)
            [_layerTransparencySeekbarMode set:LAYER_TRANSPARENCY_SEEKBAR_MODE_ALL];
        else
            [_layerTransparencySeekbarMode set:LAYER_TRANSPARENCY_SEEKBAR_MODE_OVERLAY];
   else
        if ([_layerTransparencySeekbarMode get] == LAYER_TRANSPARENCY_SEEKBAR_MODE_ALL)
            [_layerTransparencySeekbarMode set:LAYER_TRANSPARENCY_SEEKBAR_MODE_UNDERLAY];
        else
            [_layerTransparencySeekbarMode set:LAYER_TRANSPARENCY_SEEKBAR_MODE_OFF];
}

- (BOOL) getUnderlayOpacitySliderVisibility
{
    return [_layerTransparencySeekbarMode get] == LAYER_TRANSPARENCY_SEEKBAR_MODE_UNDERLAY || [_layerTransparencySeekbarMode get] == LAYER_TRANSPARENCY_SEEKBAR_MODE_ALL;
}

- (void) setUnderlayOpacitySliderVisibility:(BOOL)visibility
{
    if (visibility)
        if ([_layerTransparencySeekbarMode get] == LAYER_TRANSPARENCY_SEEKBAR_MODE_OVERLAY || [_layerTransparencySeekbarMode get] == LAYER_TRANSPARENCY_SEEKBAR_MODE_ALL)
            [_layerTransparencySeekbarMode set:LAYER_TRANSPARENCY_SEEKBAR_MODE_ALL];
        else
            [_layerTransparencySeekbarMode set:LAYER_TRANSPARENCY_SEEKBAR_MODE_OVERLAY];
   else
        if ([_layerTransparencySeekbarMode get] == LAYER_TRANSPARENCY_SEEKBAR_MODE_ALL)
            [_layerTransparencySeekbarMode set:LAYER_TRANSPARENCY_SEEKBAR_MODE_OVERLAY];
        else
            [_layerTransparencySeekbarMode set:LAYER_TRANSPARENCY_SEEKBAR_MODE_OFF];
}

- (BOOL) nightMode
{
    return [_dayNightHelper isNightMode];
}

- (void) fetchImpassableRoads
{
    id avoidRoadsInfoObjects = [[NSUserDefaults standardUserDefaults] objectForKey:impassableRoadsKey];
    NSMutableArray<OAAvoidRoadInfo *> *res = [NSMutableArray array];
    if (avoidRoadsInfoObjects)
    {
        NSArray<NSDictionary<NSString *, NSString *> *> *avoidRoadsInfoArray = avoidRoadsInfoObjects;
        for (NSDictionary<NSString *, NSString *> *avoidRoadInfoDict in avoidRoadsInfoArray)
        {
            OAAvoidRoadInfo *info = [[OAAvoidRoadInfo alloc] initWithDict:avoidRoadInfoDict];
            [res addObject:info];
        }
    }
    _impassableRoads = res;
}

- (void) clearImpassableRoads
{
    _impassableRoads = @[];
    [[NSUserDefaults standardUserDefaults] setObject:@[] forKey:impassableRoadsKey];
}

- (void) setImpassableRoads:(NSArray<OAAvoidRoadInfo *> *)impassableRoads
{
    _impassableRoads = impassableRoads;
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *avoidRoadsInfoArray = [NSMutableArray array];
    for (OAAvoidRoadInfo *info in impassableRoads)
        [avoidRoadsInfoArray addObject:[info toDict]];

    [[NSUserDefaults standardUserDefaults] setObject:avoidRoadsInfoArray forKey:impassableRoadsKey];
}

- (void) addImpassableRoad:(OAAvoidRoadInfo *)roadInfo;
{
    if (![_impassableRoads containsObject:roadInfo])
    {
        NSArray<OAAvoidRoadInfo *> *arr = [_impassableRoads arrayByAddingObject:roadInfo];
        [self setImpassableRoads:arr];
    }
}

- (void) updateImpassableRoad:(OAAvoidRoadInfo *)roadInfo
{
    NSMutableArray<OAAvoidRoadInfo *> *arr = [NSMutableArray arrayWithArray:_impassableRoads];
    for (OAAvoidRoadInfo *r in arr)
    {
        if ([OAUtilities isCoordEqual:roadInfo.location.coordinate.latitude srcLon:roadInfo.location.coordinate.longitude destLat:r.location.coordinate.latitude destLon:r.location.coordinate.longitude])
        {
            r.roadId = roadInfo.roadId;
            r.name = roadInfo.name;
            r.appModeKey = roadInfo.appModeKey;
            break;
        }
    }
    [self setImpassableRoads:arr];
}

- (BOOL) removeImpassableRoad:(CLLocation *)location
{
    BOOL res = NO;
    NSMutableArray<OAAvoidRoadInfo *> *arr = [NSMutableArray arrayWithArray:_impassableRoads];
    for (OAAvoidRoadInfo *r in arr)
    {
        if ([OAUtilities isCoordEqual:location.coordinate.latitude srcLon:location.coordinate.longitude destLat:r.location.coordinate.latitude destLon:r.location.coordinate.longitude])
        {
            res = YES;
            [arr removeObject:r];
            break;
        }
    }
    
    if (![arr isEqualToArray:_impassableRoads])
        [self setImpassableRoads:arr];
    
    return res;
}

- (void) setRulerMode:(EOARulerWidgetMode)rulerMode
{
    _rulerMode = rulerMode;
    [[NSUserDefaults standardUserDefaults] setInteger:_rulerMode forKey:rulerModeKey];
}

- (NSSet<NSString *> *) getCustomAppModesKeys
{
    NSString *appModeKeys = self.customAppModes;
    NSArray<NSString *> *keysArr = [appModeKeys componentsSeparatedByString:@","];
    return [NSSet setWithArray:keysArr];
}

- (void)setCustomAppModes:(NSString *)customAppModes
{
    _customAppModes = customAppModes;
    [[NSUserDefaults standardUserDefaults] setObject:_customAppModes forKey:customAppModesKey];
}

- (void) setupAppMode
{
    _applicationMode = [OAApplicationMode valueOfStringKey:[[NSUserDefaults standardUserDefaults] objectForKey:applicationModeKey] def:[OAApplicationMode DEFAULT]];
    _defaultApplicationMode = [OAApplicationMode valueOfStringKey:[[NSUserDefaults standardUserDefaults] objectForKey:defaultApplicationModeKey] def:[OAApplicationMode DEFAULT]];
}

@end
