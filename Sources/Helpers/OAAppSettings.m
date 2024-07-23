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
#import "OADayNightHelper.h"
#import "OAColors.h"
#import "OAAvoidRoadInfo.h"
#import "OAGPXDatabase.h"
#import "OAIAPHelper.h"
#import "OsmAnd_Maps-Swift.h"

static NSString * const settingShowMapRuletKey = @"settingShowMapRuletKey";
static NSString * const metricSystemKey = @"settingMetricSystemKey";
static NSString * const drivingRegionAutomaticKey = @"drivingRegionAutomatic";
static NSString * const preciseDistanceNumbersKey = @"precise_distance_numbers";
static NSString * const drivingRegionKey = @"settingDrivingRegion";
static NSString * const settingZoomButtonKey = @"settingZoomButtonKey";
static NSString * const settingGeoFormatKey = @"settingGeoFormatKey";
static NSString * const settingMapArrowsKey = @"settingMapArrowsKey";
static NSString * const settingMapShowAltInDriveModeKey = @"settingMapShowAltInDriveModeKey";
static NSString * const settingDoNotShowPromotionsKey = @"settingDoNotShowPromotionsKey";
static NSString * const settingUseFirebaseKey = @"settingUseFirebaseKey";
static NSString * const metricSystemChangedManuallyKey = @"metricSystemChangedManuallyKey";
static NSString * const liveUpdatesPurchasedKey = @"liveUpdatesPurchasedKey";
static NSString * const settingOsmAndLiveEnabledKey = @"settingOsmAndLiveEnabledKey";
static NSString * const liveUpdatesRetriesKey = @"liveUpdatesRetriesKey";
static NSString * const settingExternalInputDeviceKey = @"settingExternalInputDeviceKey";

static NSString * const mapSettingShowFavoritesKey = @"mapSettingShowFavoritesKey";
static NSString * const mapSettingShowPoiLabelKey = @"mapSettingShowPoiLabelKey";
static NSString * const mapSettingShowBordersOfDownloadedMapsKey = @"mapSettingShowBordersOfDownloadedMapsKey";
static NSString * const mapSettingShowOfflineEditsKey = @"mapSettingShowOfflineEditsKey";
static NSString * const mapSettingShowOnlineNotesKey = @"mapSettingShowOnlineNotesKey";
static NSString * const layerTransparencySeekbarModeKey = @"layerTransparencySeekbarModeKey";
static NSString * const mapSettingVisibleGpxKey = @"selected_gpx";

static NSString * const billingUserIdKey = @"billingUserIdKey";
static NSString * const billingUserNameKey = @"billingUserNameKey";
static NSString * const billingUserTokenKey = @"billingUserTokenKey";
static NSString * const billingUserEmailKey = @"billingUserEmailKey";
static NSString * const billingUserCountryKey = @"billingUserCountryKey";
static NSString * const billingUserCountryDownloadNameKey = @"billingUserCountryDownloadNameKey";
static NSString * const billingHideUserNameKey = @"billingHideUserNameKey";
static NSString * const billingPurchaseTokenSentKey = @"billingPurchaseTokenSentKey";
static NSString * const billingPurchaseTokensSentKey = @"billingPurchaseTokensSentKey";
static NSString * const liveUpdatesPurchaseCancelledFirstDlgShownKey = @"liveUpdatesPurchaseCancelledFirstDlgShownKey";
static NSString * const liveUpdatesPurchaseCancelledSecondDlgShownKey = @"liveUpdatesPurchaseCancelledSecondDlgShownKey";
static NSString * const fullVersionPurchasedKey = @"fullVersionPurchasedKey";
static NSString * const depthContoursPurchasedKey = @"depthContoursPurchasedKey";
static NSString * const contourLinesPurchasedKey = @"contourLinesPurchasedKey";
static NSString * const wikipediaPurchasedKey = @"wikipediaPurchasedKey";
static NSString * const emailSubscribedKey = @"emailSubscribedKey";
static NSString * const osmandProPurchasedKey = @"osmandProPurchasedKey";
static NSString * const osmandMapsPurchasedKey = @"osmandMapsPurchasedKey";
static NSString * const lastReceiptValidationDateKey = @"lastReceiptValidationDateKey";
static NSString * const eligibleForIntroductoryPriceKey = @"eligibleForIntroductoryPriceKey";
static NSString * const eligibleForSubscriptionOfferKey = @"eligibleForSubscriptionOfferKey";
static NSString * const shouldShowWhatsNewScreenKey = @"shouldShowWhatsNewScreenKey";

static NSString * const mapSettingTrackRecordingKey = @"mapSettingTrackRecordingKey";

static NSString * const mapSettingSaveGlobalTrackToGpxKey = @"mapSettingSaveGlobalTrackToGpxKey";
static NSString * const mapSettingSaveTrackIntervalGlobalKey = @"mapSettingSaveTrackIntervalGlobalKey";
static NSString * const mapSettingSaveTrackIntervalApprovedKey = @"mapSettingSaveTrackIntervalApprovedKey";
static NSString * const mapSettingShowRecordingTrackKey = @"mapSettingShowRecordingTrackKey";
static NSString * const mapSettingShowTripRecordingStartDialogKey = @"mapSettingShowTripRecordingStartDialogKey";

static NSString * const mapSettingSaveTrackIntervalKey = @"mapSettingSaveTrackIntervalKey";
static NSString * const mapSettingRecordingIntervalKey = @"mapSettingRecordingIntervalKey";

static NSString * const settingMapLanguageKey = @"settingMapLanguageKey";
static NSString * const settingPrefMapLanguageKey = @"settingPrefMapLanguageKey";
static NSString * const settingMapLanguageShowLocalKey = @"settingMapLanguageShowLocalKey";
static NSString * const settingMapLanguageTranslitKey = @"settingMapLanguageTranslitKey";

static NSString * const selectedPoiFiltersKey = @"selectedPoiFiltersKey";
static NSString * const pluginsKey = @"pluginsKey";
static NSString * const impassableRoadsKey = @"impassableRoadsKey";

static NSString * const discountIdKey = @"discountId";
static NSString * const discountShowNumberOfStartsKey = @"discountShowNumberOfStarts";
static NSString * const discountTotalShowKey = @"discountTotalShow";
static NSString * const discountShowDatetimeKey = @"discountShowDatetime";

static NSString * const lastSearchedCityKey = @"lastSearchedCity";
static NSString * const lastSearchedCityNameKey = @"lastSearchedCityName";
static NSString * const lastSearchedPointLatKey = @"lastSearchedPointLat";
static NSString * const lastSearchedPointLonKey = @"lastSearchedPointLon";

static NSString * const lastStartLatkey = @"lastStartLatkey";
static NSString * const lastStartLonkey = @"lastStartLonkey";

static NSString * const applicationModeKey = @"applicationMode";
static NSString * const defaultApplicationModeKey = @"default_application_mode_string";
static NSString * const defaultCarplayModeKey = @"default_carplay_mode_string";
static NSString * const carPlayModeIsDefaultKey = @"carplay_mode_is_default_string";
static NSString * const availableApplicationModesKey = @"available_application_modes";
static NSString * const customAppModesKey = @"customAppModes";

static NSString * const mapInfoControlsKey = @"mapInfoControls";
static NSString * const transparentMapThemeKey = @"transparentMapTheme";
static NSString * const showStreetNameKey = @"showStreetName";
static NSString * const positionPlacementOnMapKey = @"positionPlacementOnMap";
static NSString * const rotateMapKey = @"rotateMap";
static NSString * const firstMapIsDownloadedKey = @"firstMapIsDownloaded";

// App profiles
static NSString * const appModeBeanPrefsIdsKey = @"appModeBeanPrefsIds";
static NSString * const routingProfileKey = @"routingProfile";
static NSString * const derivedProfileKey = @"derivedProfile";
static NSString * const profileIconNameKey = @"profileIconName";
static NSString * const profileIconColorKey = @"profileIconColor";
static NSString * const profileCustomIconColorKey = @"profileCustomIconColor";
static NSString * const userProfileNameKey = @"userProfileName";
static NSString * const parentAppModeKey = @"parentAppMode";
static NSString * const routeServiceKey = @"routeService";
static NSString * const navigationIconKey = @"navigationIcon";
static NSString * const locationIconKey = @"locationIcon";
static NSString * const use3dIconsByDefaultKey = @"use3dIconsByDefault";
static NSString * const appModeOrderKey = @"appModeOrder";
static NSString * const defaultSpeedKey = @"defaultSpeed";
static NSString * const minSpeedKey = @"minSpeed";
static NSString * const maxSpeedKey = @"maxSpeed";
static NSString * const routeStraightAngleKey = @"routeStraightAngle";

static NSString * const rendererKey = @"renderer";

// navigation settings
static NSString * const useFastRecalculationKey = @"useFastRecalculation";
static NSString * const forcePrivateAccessRoutingAskedKey = @"forcePrivateAccessRoutingAsked";
static NSString * const fastRouteModeKey = @"fastRouteMode";
static NSString * const disableComplexRoutingKey = @"disableComplexRouting";
static NSString * const followTheRouteKey = @"followTheRoute";
static NSString * const followTheGpxRouteKey = @"followTheGpxRoute";
static NSString * const arrivalDistanceFactorKey = @"arrivalDistanceFactor";
static NSString * const enableTimeConditionalRoutingKey = @"enableTimeConditionalRouting";
static NSString * const useIntermediatePointsNavigationKey = @"useIntermediatePointsNavigation";
static NSString * const disableOffrouteRecalcKey = @"disableOffrouteRecalc";
static NSString * const disableWrongDirectionRecalcKey = @"disableWrongDirectionRecalc";
static NSString * const hazmatTransportingEnabledKey = @"hazmatTransportingEnabled";
static NSString * const routerServiceKey = @"routerService";
static NSString * const snapToRoadKey = @"snapToRoad";
static NSString * const autoFollowRouteKey = @"autoFollowRoute";
static NSString * const autoZoomMapKey = @"autoZoomMap";
static NSString * const useV1AutoZoomKey = @"useV1AutoZoom";
static NSString * const autoZoomMapScaleKey = @"autoZoomMapScale";
static NSString * const keepInformingKey = @"keepInforming";
static NSString * const speedSystemKey = @"speedSystem";
static NSString * const angularUnitsKey = @"angularUnits";
static NSString * const speedLimitExceedKey = @"speedLimitExceed";
static NSString * const showArrivalTimeKey = @"showArrivalTime";
static NSString * const showIntermediateArrivalTimeKey = @"showIntermediateArrivalTime";
static NSString * const showRelativeBearingKey = @"showRelativeBearing";
static NSString * const routeRecalculationDistanceKey = @"routeRecalculationDistance";
static NSString * const customRouteColorDayKey = @"customRouteColorDay";
static NSString * const customRouteColorNightKey = @"customRouteColorNight";
static NSString * const routeColoringTypeKey = @"routeColoringType";
static NSString * const routeGradientPaletteKey = @"route_gradient_palette";
static NSString * const routeInfoAttributeKey = @"routeInfoAttribute";
static NSString * const routeLineWidthKey = @"routeLineWidth";
static NSString * const routeShowTurnArrowsKey = @"routeShowTurnArrows";
static NSString * const showCompassControlRulerKey = @"showCompassRuler";
static NSString * const showTrafficWarningsKey = @"showTrafficWarnings";
static NSString * const showPedestrianKey = @"showPedestrian";
static NSString * const showSpeedLimitWarningsKey = @"showSpeedLimitWarnings";
static NSString * const showCamerasKey = @"showCameras";
static NSString * const showTunnelsKey = @"showTunnels";
static NSString * const showLanesKey = @"showLanes";
static NSString * const showGpxWptKey = @"showGpxWpt";
static NSString * const showNearbyFavoritesKey = @"showNearbyFavorites";
static NSString * const showNearbyPoiKey = @"showNearbyPoi";

static NSString * const speakStreetNamesKey = @"speakStreetNames";
static NSString * const speakTrafficWarningsKey = @"speakTrafficWarnings";
static NSString * const speakPedestrianKey = @"speakPedestrian";
static NSString * const speakSpeedLimitKey = @"speakSpeedLimit";
static NSString * const speakCamerasKey = @"speakCameras";
static NSString * const speakExitNumberNamesKey = @"speakExitNumberNames";
static NSString * const speakGpsSignalStatusKey = @"speakGpsSignalStatus";
static NSString * const speakRouteRecalculationKey = @"speakRouteRecalculation";
static NSString * const speakRouteDeviationKey = @"speakRouteDeviation";
static NSString * const announceWptKey = @"announceWpt";
static NSString * const announceNearbyFavoritesKey = @"announceNearbyFavorites";
static NSString * const announceNearbyPoiKey = @"announceNearbyPoi";
static NSString * const speakTunnels = @"speakTunnels";

static NSString * const voiceMuteKey = @"voiceMute";
static NSString * const voiceProviderKey = @"voiceProvider";
static NSString * const interruptMusicKey = @"interruptMusic";
static NSString * const showScreenAlertsKey = @"showScreenAlerts";

static NSString * const gpxRouteCalcOsmandPartsKey = @"gpxRouteCalcOsmandParts";
static NSString * const gpxCalculateRteptKey = @"gpxCalculateRtept";
static NSString * const gpxRouteCalcKey = @"gpxRouteCalc";
static NSString * const gpxRouteSegmentKey = @"gpxRouteSegment";
static NSString * const showStartFinishIconsKey = @"showStartFinishIcons";
static NSString * const useOsmLiveForRoutingKey = @"useOsmLiveForRouting";

static NSString * const saveTrackToGPXKey = @"saveTrackToGPX";
static NSString * const saveTrackMinDistanceKey = @"saveTrackMinDistance";
static NSString * const saveTrackPrecisionKey = @"saveTrackPrecision";
static NSString * const saveTrackMinSpeedKey = @"saveTrackMinSpeed";
static NSString * const autoSplitRecordingKey = @"autoSplitRecording";
static NSString * const saveHeadingToGpxKey = @"saveHeadingToGpx";

static NSString * const rulerModeKey = @"rulerMode";
static NSString * const showDistanceRulerKey = @"showDistanceRuler";
static NSString * const showElevationProfileWidgetKey = @"show_elevation_profile_widget";
static NSString * const showSlopesOnElevationWidget = @"show_slopes_on_elevation_widget";
static NSString * const customWidgetKeys = @"custom_widgets_keys";
static NSString * const showSpeedometerKey = @"show_speedometer";
static NSString * const speedometerSizeKey = @"speedometer_size";
static NSString * const showSpeedLimitWarningKey = @"show_speed_limit_warning";

static NSString * const osmUserAccessTokenKey = @"osm_user_access_token";
static NSString * const osmUserAccessTokenSecretKey = @"osm_user_access_token_secret";
static NSString * const oprAccessTokenKey = @"opr_access_token";
static NSString * const oprUsernameKey = @"opr_username";
static NSString * const oprBlockchainNameKey = @"opr_blockchain_name";
static NSString * const oprUseDevUrlKey = @"opr_use_dev_url";
static NSString * const offlineEditingKey = @"offline_editing";
static NSString * const osmUseDevUrlKey = @"use_dev_url";
static NSString * const mapperLiveUpdatesExpireTimeKey = @"mapper_live_updates_expire_time";

static NSString * const showMapillaryKey = @"show_mapillary";
static NSString * const onlinePhotosRowCollapsedKey = @"onlinePhotosRowCollapsed";
static NSString * const mapillaryFirstDialogShownKey = @"mapillaryFirstDialogShown";
static NSString * const useMapillaryFilterKey = @"useMapillaryFilter";
static NSString * const mapillaryFilterUserKeyKey = @"mapillaryFilterUserKey";
static NSString * const mapillaryFilterUserNameKey = @"mapillaryFilterUserName";
static NSString * const mapillaryFilterStartDateKey = @"mapillaryFilterStartDate";
static NSString * const mapillaryFilterEndDateKey = @"mapillaryFilterEndDate";
static NSString * const mapillaryFilterPanoKey = @"mapillaryFilterPano";

static NSString * const isQuickActionTutorialShownKey = @"isQuickActionTutorialShown";
static NSString * const quickActionButtonsKey = @"quick_action_buttons";

static NSString * const contourLinesZoomKey = @"contourLinesZoom";
static NSString * const hikingRoutesParameterKey = @"hikingRoutesParameter";
static NSString * const cycleRoutesParameterKey = @"cycleRoutesParameter";
static NSString * const mountainBikeRoutesParameterKey = @"mountainBikeRoutesParameter";
static NSString * const mapManuallyRotatingAngleKey = @"mapManuallyRotatingAngle";
static NSString * const mapScreenOrientationKey = @"mapScreenOrientation";

static NSString * const activeMarkerKey = @"activeMarkerKey";
static NSString * const mapDistanceIndicationVisabilityKey = @"mapDistanceIndicationVisabilityKey";
static NSString * const mapDistanceIndicationKey = @"mapDistanceIndicationKey";
static NSString * const mapArrowsOnMapKey = @"mapArrowsOnMapKey";
static NSString * const mapDirectionLinesKey = @"mapDirectionLinesKey";

static NSString * const poiFiltersOrderKey = @"poi_filters_order";
static NSString * const inactivePoiFiltersKey = @"inactive_poi_filters";

static NSString * const customPluginsJsonKey = @"customPluginsJson";

// global

static NSString * const wikiArticleShowImagesAskedKey = @"wikivoyageShowImagesAsked";
static NSString * const wikivoyageShowImgsKey = @"wikivoyageShowImgs";

static NSString * const coordsInputUseRightSideKey = @"coordsInputUseRightSide";
static NSString * const coordsInputFormatKey = @"coordsInputFormat";
static NSString * const coordsInputUseOsmandKeyboardKey = @"coordsInputUseOsmandKeyboard";
static NSString * const coordsInputTwoDigitsLongitudeKey = @"coordsInputTwoDigitsLongitude";

static NSString * const showCardToChooseDrawerKey = @"showCardToChooseDrawer";
static NSString * const shouldShowDashboardOnStartKey = @"shouldShowDashboardOnStart";
static NSString * const showDashboardOnMapScreenKey = @"showDashboardOnMapScreen";
static NSString * const showOsmandWelcomeScreenKey = @"showOsmandWelcomeScreen";
static NSString * const apiNavDrawerItemsJsonKey = @"apiNavDrawerItemsJson";
static NSString * const apiConnectedAppsJsonKey = @"apiConnectedAppsJson";
static NSString * const numberOfStartsFirstXmasShownKey = @"numberOfStartsFirstXmasShown";

static NSString * const lastFavCategoryEnteredKey = @"lastFavCategoryEntered";
static NSString * const useLastApplicationModeByDefaultKey = @"useLastApplicationModeByDefault";
static NSString * const lastUsedApplicationModeKey = @"lastUsedApplicationMode";
static NSString * const lastRouteApplicationModeBackupStringKey = @"lastRouteApplicationModeBackupString";
static NSString * const searchHistoryKey = @"searchHistoy";
static NSString * const navigationHistoryKey = @"navigationHistory";
static NSString * const mapMarkersHistoryKey = @"mapMarkersHistory";

static NSString * const onlineRoutingEnginesKey = @"onlineRoutingEngines";

static NSString * const doNotShowStartupMessagesKey = @"doNotShowStartupMessages";
static NSString * const showDownloadMapDialogKey = @"showDownloadMapDialog";

static NSString * const sendAnonymousMapDownloadsDataKey = @"sendAnonymousMapDownloadsData";
static NSString * const sendAnonymousAppUsageDataKey = @"sendAnonymousAppUsageData";
static NSString * const sendAnonymousDataRequestProcessedKey = @"sendAnonymousDataRequestProcessed";
static NSString * const sendAnonymousDataRequestCountKey = @"sendAnonymousDataRequestCount";
static NSString * const sendAnonymousDataLastRequestNsKey = @"sendAnonymousDataLastRequestNs";

static NSString * const webglSupportedKey = @"webglSupported";

static NSString * const osmUserDisplayNameKey = @"osmUserDisplayName";
static NSString * const osmUploadVisibilityKey = @"osmUploadVisibility";

static NSString * const inappsReadKey = @"inappsRead";

static NSString * const backupUserEmailKey = @"backupUserEmail";
static NSString * const backupUserIdKey = @"backupUserId";
static NSString * const backupDeviceIdKey = @"backupDeviceId";
static NSString * const backupNativeDeviceIdKey = @"backupNativeDeviceId";
static NSString * const backupAccessTokenKey = @"backupAccessToken";
static NSString * const backupAccessTokenUpdateTimeKey = @"backupAccessTokenUpdateTime";
static NSString * const backupFreePlanRegistrationTime = @"backupFreePlanRegistrationTime";

static NSString * const backupPromocodeKey = @"backupPromocode";
static NSString * const backupPurchaseActiveKey = @"backupPurchaseActive";
static NSString * const backupPurchaseStartTimeKey = @"backupPurchaseStartTime";
static NSString * const backupPurchaseExpireTimeKey = @"backupPurchaseExpireTime";
static NSString * const backupPurchaseStateKey = @"backupPurchaseState";
static NSString * const proSubscriptionOriginKey = @"proSubscriptionOrigin";
static NSString * const proSubscriptionDurationKey = @"proSubscriptionDuration";
static NSString * const purchaseIdentifiersKey = @"purchaseIdentifiers";

static NSString * const userIosIdKey = @"userIosId";

static NSString * const favoritesLastUploadedTimeKey = @"favoritesLastUploadedTime";
static NSString * const backupLastUploadedTimeKey = @"backupLastUploadedTime";

static NSString * const delayToStartNavigationKey = @"delayToStartNavigation";

static NSString * const enableProxyKey = @"enableProxy";
static NSString * const proxyHostKey = @"proxyHost";
static NSString * const proxyPortKey = @"proxyPort";
static NSString * const userAndroidIdKey = @"userAndroidId";

static NSString * const speedCamerasUninstalledKey = @"speedCamerasUninstalled";
static NSString * const speedCamerasAlertShownKey = @"speedCamerasAlertShown";

static NSString * const lastUpdatesCardRefreshKey = @"lastUpdatesCardRefresh";

static NSString * const currentTrackColorKey = @"currentTrackColor";
static NSString * const currentTrackColoringTypeKey = @"currentTrackColoringType";
static NSString * const currentTrackSpeedGradientPaletteKey = @"currentTrackSpeedGradientPalette";
static NSString * const currentTrackAltitudeGradientPaletteKey = @"currentTrackAltitudeGradientPalette";
static NSString * const currentTrackSlopeGradientPaletteKey = @"currentTrackSlopeGradientPalette";
static NSString * const currentTrackWidthKey = @"currentTrackWidth";
static NSString * const currentTrackShowArrowsKey = @"currentTrackShowArrows";
static NSString * const currentTrackShowStartFinishKey = @"currentTrackShowStartFinish";
static NSString * const currentTrackVerticalExaggerationScaleKey = @"currentTrackVerticalExaggerationScale";
static NSString * const currentTrackElevationMetersKey = @"currentTrackElevationMeters";
static NSString * const currentTrackVisualization3dByTypeKey = @"currentTrackVisualization3dByType";
static NSString * const currentTrackVisualization3dWallColorTypeKey = @"currentTrackVisualization3dWallColorType";
static NSString * const currentTrackVisualization3dPositionTypeKey = @"currentTrackVisualization3dPositionType";

static NSString * const customTrackColorsKey = @"customTrackColors";
static NSString * const customTrackColorsLastUsedKey = @"customTrackColorsLastUsed";
static NSString * const lastUsedFavIconsKey = @"lastUsedFavIcons";

static NSString * const gpsStatusAppKey = @"gpsStatusApp";

static NSString * const debugRenderingInfoKey = @"debugRenderingInfo";

static NSString * const levelToSwitchVectorRasterKey = @"levelToSwitchVectorRaster";

static NSString * const voicePromptDelay0Key = @"voicePromptDelay0";
static NSString * const voicePromptDelay3Key = @"voicePromptDelay3";
static NSString * const voicePromptDelay5Key = @"voicePromptDelay5";

static NSString * const displayTtsUtteranceKey = @"displayTtsUtterance";

static NSString * const mapOverlayPreviousKey = @"mapOverlayPrevious";
static NSString * const mapUnderlayPreviousKey = @"mapUnderlayPrevious";
static NSString * const previousInstalledVersionKey = @"previousInstalledVersion";
static NSString * const shouldShowFreeVersionBannerKey = @"shouldShowFreeVersionBanner";

static NSString * const routeMapMarkersStartMyLocKey = @"routeMapMarkersStartMyLoc";
static NSString * const routeMapMarkersRoundTripKey = @"routeMapMarkersRoundTrip";

static NSString * const osmandUsageSpaceKey = @"osmandUsageSpace";

static NSString * const lastSelectedGpxTrackForNewPointKey = @"lastSelectedGpxTrackForNewPoint";

static NSString * const customRouteLineColorsKey = @"customRouteLineColors";

static NSString * const mapActivityEnabledKey = @"mapActivityEnabled";

static NSString * const safeModeKey = @"safeMode";
static NSString * const nativeRenderingFailedKey = @"nativeRenderingFailed";

static NSString * const useOpenglRenderKey = @"useOpenglRender";
static NSString * const openglRenderFailedKey = @"openglRenderFailed";

static NSString * const contributionInstallAppDateKey = @"contributionInstallAppDate";

static NSString * const selectedTravelBookKey = @"selectedTravelBook";

static NSString * const agpsDataLastTimeDownloadedKey = @"agpsDataLastTimeDownloaded";

static NSString * const searchTabKey = @"searchTab";
static NSString * const favoritesTabKey = @"favoritesTab";

static NSString * const fluorescentOverlaysKey = @"fluorescentOverlays";
static NSString * const keepMapLabelsVisibleKey = @"keepMapLabelsVisible";

static NSString * const numberOfFreeDownloadsKey = @"numberOfFreeDownloads";

static NSString * const lastDisplayTimeKey = @"lastDisplayTime";
static NSString * const lastCheckedUpdatesKey = @"lastCheckedUpdates";
static NSString * const numberOfAppStartsOnDislikeMomentKey = @"numberOfAppStartsOnDislikeMoment";
static NSString * const rateUsStateKey = @"rateUsState";

static NSString * const animateMyLocationKey = @"animateMyLocation";
static NSString * const doNotUseAnimationsKey = @"doNotUseAnimations";

static NSString * const lastGlobalSettingsModifiedTimeKey = @"lastGlobalSettingsModifiedTime";
static NSString * const lastProfileSettingsModifiedTimeKey = @"lastProfileSettingsModifiedTime";

static NSString * const lastUUIDChangeTimestampKey = @"lastUUIDChangeTimestamp";

static NSString * const kShowHeightmapsKey = @"showHeightmaps";

// Widgets
static NSString * const leftWidgetPanelOrderKey = @"left_widget_panel_order";
static NSString * const rightWidgetPanelOrderKey = @"right_widget_panel_order";
static NSString * const topWidgetPanelOrderKey = @"widget_top_panel_order";
static NSString * const bottomWidgetPanelOrderKey = @"widget_bottom_panel_order";

static NSString * const topWidgetPanelOrderOldKey = @"top_widget_panel_order";
static NSString * const bottomWidgetPanelOrderKeyOld = @"bottom_widget_panel_order";

static NSString * const useOldRoutingKey = @"useOldRoutingKey";

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
        case NAUTICAL_MILES_AND_METERS:
            return OALocalizedString(@"si_nm_mt");
        case NAUTICAL_MILES_AND_FEET:
            return OALocalizedString(@"si_nm_ft");

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
        case NAUTICAL_MILES_AND_METERS:
            return @"nm-m";
        case NAUTICAL_MILES_AND_FEET:
            return @"nm-f";

        default:
            return @"";
    }
}

+ (BOOL)shouldUseFeet:(EOAMetricsConstant)mc
{
    return mc == MILES_AND_FEET || mc == MILES_AND_YARDS || mc == NAUTICAL_MILES_AND_FEET;
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
            return OALocalizedString(@"km_h");
        case MILES_PER_HOUR:
            return OALocalizedString(@"mile_per_hour");
        case METERS_PER_SECOND:
            return OALocalizedString(@"m_s");
        case MINUTES_PER_MILE:
            return OALocalizedString(@"min_mile");
        case MINUTES_PER_KILOMETER:
            return OALocalizedString(@"min_km");
        case NAUTICALMILES_PER_HOUR:
            return OALocalizedString(@"units_nm_h");

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
@property (nonatomic) float minDistanceToDrive;

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
        obj.minDistanceToDrive = [self.class getMinDistanceToDrive:autoZoomMap];
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
            return 16.f;
        case AUTO_ZOOM_MAP_FAR:
            return 17.f;
        case AUTO_ZOOM_MAP_CLOSE:
            return 19.f;
        default:
            return 0;
    }
}

+ (float) getMinDistanceToDrive:(EOAAutoZoomMap)autoZoomMap
{
    switch (autoZoomMap)
    {
        case AUTO_ZOOM_MAP_FARTHEST:
            return 400.f;
        case AUTO_ZOOM_MAP_FAR:
            return 200.f;
        case AUTO_ZOOM_MAP_CLOSE:
            return 50.f;
        default:
            return 0;
    }
}

@end

@interface OAWikiArticleShowConstant()

@property (nonatomic) EOAWikiArticleShowConstant wasc;

@end

@implementation OAWikiArticleShowConstant

+ (instancetype)withWikiArticleShowConstant:(EOAWikiArticleShowConstant)wasc
{
    OAWikiArticleShowConstant *obj = [[OAWikiArticleShowConstant alloc] init];
    if (obj)
    {
        obj.wasc = wasc;
    }
    return obj;
}

+ (NSString *) toHumanString:(EOAWikiArticleShowConstant)wasc
{
    switch (wasc)
    {
        case EOAWikiArticleShowConstantOn:
            return OALocalizedString(@"shared_string_on");
        case EOAWikiArticleShowConstantOff:
            return OALocalizedString(@"shared_string_off");
        case EOAWikiArticleShowConstantWiFi:
            return OALocalizedString(@"shared_string_wifi_only");
        default:
            return @"";
    }
}

@end

@interface OAGradientScaleType()

@property (nonatomic) EOAGradientScaleType gst;

@end

@implementation OAGradientScaleType

+ (instancetype)withGradientScaleType:(EOAGradientScaleType)gst
{
    OAGradientScaleType *obj = [[OAGradientScaleType alloc] init];
    if (obj)
    {
        obj.gst = gst;
    }
    return obj;
}

+ (NSString *) toHumanString:(EOAGradientScaleType)gst
{
    switch (gst)
    {
        case EOAGradientScaleTypeSpeed:
            return OALocalizedString(@"shared_string_speed");
        case EOAGradientScaleTypeAltitude:
            return OALocalizedString(@"altitude");
        case EOAGradientScaleTypeSlope:
            return OALocalizedString(@"shared_string_slope");
        default:
            return @"";
    }
}

+ (NSString *) toTypeName:(EOAGradientScaleType)gst
{
    switch (gst)
    {
        case EOAGradientScaleTypeSpeed:
            return @"speed";
        case EOAGradientScaleTypeAltitude:
            return @"altitude";
        case EOAGradientScaleTypeSlope:
            return @"slope";
        default:
            return @"";
    }
}

+ (NSString *) toColorTypeName:(EOAGradientScaleType)gst
{
    switch (gst)
    {
        case EOAGradientScaleTypeSpeed:
            return @"gradient_speed_color";
        case EOAGradientScaleTypeAltitude:
            return @"gradient_altitude_color";
        case EOAGradientScaleTypeSlope:
            return @"gradient_slope_color";
        default:
            return @"";
    }
}

- (EOAColorizationType) toColorizationType
{
    if (self.gst == EOAGradientScaleTypeSpeed)
        return EOAColorizationTypeSpeed;
    else if (self.gst == EOAGradientScaleTypeAltitude)
        return EOAColorizationTypeElevation;
    else if (self.gst == EOAGradientScaleTypeSlope)
        return EOAColorizationTypeSlope;
    else
        return EOAColorizationTypeNone;
}

@end

@interface OAUploadVisibility()

@property (nonatomic) EOAUploadVisibility uv;

@end

@implementation OAUploadVisibility

+ (instancetype)withUploadVisibility:(EOAUploadVisibility)uv
{
    OAUploadVisibility *obj = [[OAUploadVisibility alloc] init];
    if (obj)
    {
        obj.uv = uv;
    }
    return obj;
}

+ (NSString *) toTitle:(EOAUploadVisibility)uv
{
    switch (uv)
    {
        case EOAUploadVisibilityPublic:
            return OALocalizedString(@"gpxup_public");
        case EOAUploadVisibilityIdentifiable:
            return OALocalizedString(@"gpxup_identifiable");
        case EOAUploadVisibilityTrackable:
            return OALocalizedString(@"gpxup_trackable");
        case EOAUploadVisibilityPrivate:
            return OALocalizedString(@"gpxup_private");
        default:
            return @"";
    }
}

+ (NSString *) toDescription:(EOAUploadVisibility)uv
{
    switch (uv)
    {
        case EOAUploadVisibilityPublic:
            return OALocalizedString(@"gpx_upload_public_visibility_descr");
        case EOAUploadVisibilityIdentifiable:
            return OALocalizedString(@"gpx_upload_identifiable_visibility_descr");
        case EOAUploadVisibilityTrackable:
            return OALocalizedString(@"gpx_upload_trackable_visibility_descr");
        case EOAUploadVisibilityPrivate:
            return OALocalizedString(@"gpx_upload_private_visibility_descr");
        default:
            return @"";
    }
}

@end

@interface OACoordinateInputFormats()

@property (nonatomic) EOACoordinateInputFormats cif;

@end

@implementation OACoordinateInputFormats

+ (instancetype)withUploadVisibility:(EOACoordinateInputFormats)cif
{
    OACoordinateInputFormats *obj = [[OACoordinateInputFormats alloc] init];
    if (obj)
    {
        obj.cif = cif;
    }
    return obj;
}

+ (NSString *) toHumanString:(EOACoordinateInputFormats)cif
{
    switch (cif)
    {
        case EOACoordinateInputFormatsDdMmMmm:
            return OALocalizedString(@"dd_mm_mmm_format");
        case EOACoordinateInputFormatsDdMmMmmm:
            return OALocalizedString(@"dd_mm_mmmm_format");
        case EOACoordinateInputFormatsDdDdddd:
            return OALocalizedString(@"dd_ddddd_format");
        case EOACoordinateInputFormatsDdDddddd:
            return OALocalizedString(@"dd_dddddd_format");
        case EOACoordinateInputFormatsDdMmSs:
            return OALocalizedString(@"dd_mm_ss_format");
        default:
            return @"";
    }
}

+ (BOOL) containsThirdPart:(EOACoordinateInputFormats)cif
{
    switch (cif)
    {
        case EOACoordinateInputFormatsDdMmMmm:
            return YES;
        case EOACoordinateInputFormatsDdMmMmmm:
            return YES;
        case EOACoordinateInputFormatsDdDdddd:
            return NO;
        case EOACoordinateInputFormatsDdDddddd:
            return NO;
        case EOACoordinateInputFormatsDdMmSs:
            return YES;
        default:
            return NO;
    }
}

+ (int) toSecondPartSymbolsCount:(EOACoordinateInputFormats)cif
{
    switch (cif)
    {
        case EOACoordinateInputFormatsDdMmMmm:
            return 2;
        case EOACoordinateInputFormatsDdMmMmmm:
            return 2;
        case EOACoordinateInputFormatsDdDdddd:
            return 5;
        case EOACoordinateInputFormatsDdDddddd:
            return 6;
        case EOACoordinateInputFormatsDdMmSs:
            return 2;
        default:
            return 0;
    }
}

+ (int) toThirdPartSymbolsCount:(EOACoordinateInputFormats)cif
{
    switch (cif)
    {
        case EOACoordinateInputFormatsDdMmMmm:
            return 3;
        case EOACoordinateInputFormatsDdMmMmmm:
            return 4;
        case EOACoordinateInputFormatsDdDdddd:
            return 0;
        case EOACoordinateInputFormatsDdDddddd:
            return 0;
        case EOACoordinateInputFormatsDdMmSs:
            return 2;
        default:
            return 0;
    }
}

+ (NSString *) toFirstSeparator:(EOACoordinateInputFormats)cif
{
    switch (cif)
    {
        case EOACoordinateInputFormatsDdMmMmm:
            return @"°";
        case EOACoordinateInputFormatsDdMmMmmm:
            return @"°";
        case EOACoordinateInputFormatsDdDdddd:
            return @".";
        case EOACoordinateInputFormatsDdDddddd:
            return @".";
        case EOACoordinateInputFormatsDdMmSs:
            return @"°";
        default:
            return @"";
    }
}

+ (NSString *) toSecondSeparator:(EOACoordinateInputFormats)cif
{
    switch (cif)
    {
        case EOACoordinateInputFormatsDdMmMmm:
            return @".";
        case EOACoordinateInputFormatsDdMmMmmm:
            return @".";
        case EOACoordinateInputFormatsDdDdddd:
            return @"°";
        case EOACoordinateInputFormatsDdDddddd:
            return @"°";
        case EOACoordinateInputFormatsDdMmSs:
            return @"′";
        default:
            return @"";
    }
}

@end

@interface OASimulationMode()

@property (nonatomic) EOASimulationMode mode;

@end

@implementation OASimulationMode
{
    EOASimulationMode _mode;
}

- (instancetype)initWithMode:(EOASimulationMode)mode
{
    self = [super init];
    if (self)
    {
        _mode = mode;
    }
    return self;
}

+ (instancetype)withMode:(EOASimulationMode)mode
{
    return [[OASimulationMode alloc] initWithMode:mode];
}

+ (NSArray<OASimulationMode *> *)values
{
    return @[[OASimulationMode withMode:EOASimulationModePreview],
             [OASimulationMode withMode:EOASimulationModeConstant],
             [OASimulationMode withMode:EOASimulationModeRealistic]];
}

+ (OASimulationMode *)getModeObject:(NSString *)key
{
    for (OASimulationMode *mode in [OASimulationMode values])
    {
        if ([[mode key] isEqualToString:key])
            return mode;
    }
    return nil;
}

+ (EOASimulationMode)getMode:(NSString *)key
{
    return [self getModeObject:key].mode;
}

+ (NSString *)toKey:(EOASimulationMode)mode
{
    switch (mode)
    {
        case EOASimulationModePreview:
            return @"preview_mode";
        case EOASimulationModeConstant:
            return @"const_mode";
        case EOASimulationModeRealistic:
            return @"real_mode";
        default:
            return @"";
    }
}

+ (NSString *)toTitle:(EOASimulationMode)mode
{
    switch (mode)
    {
        case EOASimulationModePreview:
            return OALocalizedString(@"simulation_preview_mode_title");
        case EOASimulationModeConstant:
            return OALocalizedString(@"simulation_constant_mode_title");
        case EOASimulationModeRealistic:
            return OALocalizedString(@"simulation_real_mode_title");
        default:
            return @"";
    }
}

+ (NSString *)toDescription:(EOASimulationMode)mode
{
    switch (mode)
    {
        case EOASimulationModePreview:
            return OALocalizedString(@"simulation_preview_mode_desc");
        case EOASimulationModeConstant:
            return OALocalizedString(@"simulation_constant_mode_desc");
        case EOASimulationModeRealistic:
            return OALocalizedString(@"simulation_real_mode_desc");
        default:
            return @"";
    }
}

- (NSString *)key
{
    return [OASimulationMode toKey:_mode];
}

- (NSString *)title
{
    return [OASimulationMode toTitle:_mode];
}

- (NSString *)description
{
    return [OASimulationMode toDescription:_mode];
}

@end

@interface OACommonPreference ()

@property (nonatomic, readonly) OAApplicationMode *appMode;
@property (nonatomic) NSString *key;
@property (nonatomic) NSMapTable<OAApplicationMode *, NSObject *> *cachedValues;
@property (nonatomic) NSMapTable<OAApplicationMode *, NSObject *> *defaultValues;
@property (nonatomic) NSObject *cachedValue;
@property (nonatomic) NSObject *defaultValue;

+ (instancetype) withKey:(NSString *)key;
- (NSObject *) getValue;
- (NSObject *) getValue:(OAApplicationMode *)mode;
- (void) setValue:(NSObject *)value;
- (void) setValue:(NSObject *)value mode:(OAApplicationMode *)mode;
- (void) setModeDefaultValue:(NSObject *)defValue mode:(OAApplicationMode *)mode;

@end

@implementation OACommonPreference

@synthesize global=_global, shared=_shared;

+ (instancetype)withKey:(NSString *)key
{
    OACommonPreference *obj = [[OACommonPreference alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.cachedValues = [NSMapTable strongToStrongObjectsMapTable];
    }
    return obj;
}

- (instancetype)makeGlobal
{
    _global = YES;
    return self;
}

- (instancetype)makeProfile
{
    _global = NO;
    return self;
}

- (instancetype)makeShared
{
    _shared = YES;
    return self;
}

- (instancetype)storeLastModifiedTime
{
    _lastModifiedTimeStored = YES;
    return self;
}

- (OAApplicationMode *)appMode
{
    return [OAAppSettings sharedManager].currentMode;
}

- (NSString *)getKey:(OAApplicationMode *)mode
{
    return self.global ? self.key : [NSString stringWithFormat:@"%@_%@", self.key, mode.stringKey];
}

- (NSObject *)getValue
{
    return [self getValue:self.global ? nil : self.appMode];
}

- (NSObject *)getValue:(OAApplicationMode *)mode
{
    NSObject *cachedValue = self.global ? self.cachedValue : [self.cachedValues objectForKey:mode];
    if (!cachedValue)
    {
        NSString *key = [self getKey:mode];
        cachedValue = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        if (self.global)
            self.cachedValue = cachedValue;
        else
            [self.cachedValues setObject:cachedValue forKey:mode];
    }
    if (!cachedValue)
    {
        cachedValue = [self getProfileDefaultValue:mode];
    }
    return cachedValue;
}

- (void)setValue:(NSObject *)value
{
    [self setValue:value mode:self.global ? nil : self.appMode];
}

- (void)setValue:(NSObject *)value mode:(OAApplicationMode *)mode
{
    id oldVal = [self getValue:mode];
    oldVal = oldVal ? oldVal : value;
    BOOL bothNil = value == nil && oldVal == nil;
    BOOL changed = !bothNil && ![value isEqual:oldVal];
    if (self.global)
    {
        self.cachedValue = value;
    }
    else
    {
        [self.cachedValues setObject:value forKey:mode];
    }
    if (changed)
    {
        if (self.global && self.shared)
            [[NSUserDefaults standardUserDefaults] setObject:@(NSDate.date.timeIntervalSince1970) forKey:lastGlobalSettingsModifiedTimeKey];
        else if (!self.global && mode)
            [[NSUserDefaults standardUserDefaults] setObject:@(NSDate.date.timeIntervalSince1970) forKey:[NSString stringWithFormat:@"%@_%@", lastProfileSettingsModifiedTimeKey, mode.stringKey]];
    }
    if (self.lastModifiedTimeStored)
       [self setLastModifiedTime:NSDate.date.timeIntervalSince1970];

    [[NSUserDefaults standardUserDefaults] setObject:value forKey:[self getKey:mode]];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSetProfileSetting object:self];
}

- (BOOL) isSetForMode:(OAApplicationMode *)mode
{
    return [self getValue:mode] != nil;
}

- (long)lastModifiedTime
{
    if (self.lastModifiedTimeStored)
        return [[[NSUserDefaults standardUserDefaults] objectForKey:self.getLastModifiedTimeId] longValue];
    else
        @throw [NSException exceptionWithName:@"IllegalStateException" reason:[NSString stringWithFormat:@"Setting %@  is not granted to store last modified time", self.key] userInfo:nil];
}

- (void)setLastModifiedTime:(long)lastModifiedTime
{
    if (self.lastModifiedTimeStored)
        [[NSUserDefaults standardUserDefaults] setObject:@(lastModifiedTime) forKey:self.getLastModifiedTimeId];
    else
        @throw [NSException exceptionWithName:@"IllegalStateException" reason:[NSString stringWithFormat:@"Setting %@  is not granted to store last modified time", self.key] userInfo:nil];
}

- (NSString *) getLastModifiedTimeId
{
    return [self.key stringByAppendingString:@"_last_modified"];
}

- (void)setModeDefaultValue:(NSObject *)defValue mode:(OAApplicationMode *)mode
{
    if (self.global)
    {
        self.defaultValue = defValue;
    }
    else
    {
        if (!self.defaultValues) {
            self.defaultValues = [NSMapTable strongToStrongObjectsMapTable];
        }
        [self.defaultValues setObject:defValue forKey:mode];
    }
}

- (void)resetModeToDefault:(OAApplicationMode *)mode
{
    if (_global)
    {
        [self resetToDefault];
    }
    else
    {
        NSObject *defValue = [self getProfileDefaultValue:mode];
        [self setValue:defValue mode:mode];
    }
}

- (void)resetToDefault
{
    OAApplicationMode *mode = [OAAppSettings sharedManager].currentMode;
    NSObject *defValue = [self getProfileDefaultValue:mode];
    [self setValue:defValue mode:mode];
}

- (NSObject *)getProfileDefaultValue:(OAApplicationMode *)mode
{

    if (self.global)
    {
        if (self.defaultValue)
            return self.defaultValue;
    }
    else
    {
        if (self.defaultValues && [self.defaultValues objectForKey:mode])
            return [self.defaultValues objectForKey:mode];
    }
    if (mode)
    {
        OAApplicationMode *pt = mode.parent;
        if (pt)
            return [self getProfileDefaultValue:pt];
    }

    return self.defaultValue;
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    return @"";
}

- (void)copyValueFromAppMode:(OAApplicationMode *)sourceAppMode targetAppMode:(OAApplicationMode *)targetAppMode
{
    [self setValue:[self getValue:sourceAppMode] mode:targetAppMode];
}

@end

@interface OACommonAppMode ()

@property (nonatomic) OAApplicationMode *defValue;

@end

@implementation OACommonAppMode

+ (instancetype)withKey:(NSString *)key defValue:(OAApplicationMode *)defValue
{
    OACommonAppMode *obj = [[OACommonAppMode alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    return obj;
}

- (OAApplicationMode *)get
{
    return [self get:self.appMode];
}

- (OAApplicationMode *)get:(OAApplicationMode *)mode
{
    NSObject *value = [self getValue:mode];
    return value ? (OAApplicationMode *)value : self.defValue;
}

- (void)set:(OAApplicationMode *)appMode
{
    [self set:appMode mode:self.appMode];
}

- (void)set:(OAApplicationMode *)appMode mode:(OAApplicationMode *)mode
{
    [self setValue:appMode mode:mode];
}

- (NSObject *)getValue:(OAApplicationMode *)mode
{
    NSString *stringKey = [[NSUserDefaults standardUserDefaults] objectForKey:[self getKey:mode]];
    return [OAApplicationMode valueOfStringKey:stringKey def:OAApplicationMode.DEFAULT];
}

- (void)setValue:(NSObject *)value mode:(OAApplicationMode *)mode
{
    OAApplicationMode *appMode = (OAApplicationMode *) value;

    if ([self.key isEqualToString:applicationModeKey])
        [OAAppSettings sharedManager].currentMode = appMode;

    if (self.global)
        self.cachedValue = appMode;
    else
        [self.cachedValues setObject:appMode forKey:mode];

    [[NSUserDefaults standardUserDefaults] setObject:appMode.stringKey forKey:[self getKey:mode]];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSetProfileSetting object:self];
}

- (void)resetToDefault
{
    if ([self.key isEqualToString:applicationModeKey])
    {
        [self set:OAApplicationMode.DEFAULT];
    }
    else
    {
        OAApplicationMode *defaultValue = self.defValue;
        NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
        if (pDefault)
            defaultValue = (OAApplicationMode *) pDefault;

        [self set:defaultValue];
    }
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    [self set:[OAApplicationMode valueOfStringKey:strValue def:OAApplicationMode.DEFAULT] mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    return [self get:mode].stringKey;
}

@end

@interface OACommonBoolean ()

@property (nonatomic) BOOL defValue;

@end

@implementation OACommonBoolean

+ (instancetype) withKey:(NSString *)key defValue:(BOOL)defValue
{
    OACommonBoolean *obj = [[OACommonBoolean alloc] init];
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

- (BOOL) get:(OAApplicationMode *)mode
{
    NSObject *value = [self getValue:mode];
    if (value)
    {
        return ((NSNumber *) value).boolValue;
    }
    else
    {
        if ([self.key isEqualToString:settingMapLanguageTranslitKey])
            return [[OAAppSettings sharedManager].settingPrefMapLanguage.get isEqualToString:@"en"];
        else
            return self.defValue;
    }
}

- (void) set:(BOOL)boolean
{
    [self set:boolean mode:self.appMode];
}

- (void) set:(BOOL)boolean mode:(OAApplicationMode *)mode
{
    [self setValue:@(boolean) mode:mode];
}

- (void) resetToDefault
{
    BOOL defaultValue = [self.key isEqualToString:settingMapLanguageTranslitKey] ? [[OAAppSettings sharedManager].settingPrefMapLanguage.get isEqualToString:@"en"] : self.defValue;
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

@interface OACommonInteger ()

@property (nonatomic) int defValue;

@end

@implementation OACommonInteger

+ (instancetype) withKey:(NSString *)key defValue:(int)defValue
{
    OACommonInteger *obj = [[OACommonInteger alloc] init];
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

- (int) get:(OAApplicationMode *)mode
{
    NSObject *value = [self getValue:mode];
    if (value)
    {
        return ((NSNumber *) value).intValue;
    }
    else
    {
        if ([self.key isEqualToString:delayToStartNavigationKey])
            return [[OAAppSettings sharedManager].defaultApplicationMode.get isDerivedRoutingFrom:OAApplicationMode.CAR] ? 10 : -1;
        else
            return self.defValue;
    }
}

- (void) set:(int)integer
{
    [self set:integer mode:self.appMode];
}

- (void) set:(int)integer mode:(OAApplicationMode *)mode
{
    [self setValue:@(integer) mode:mode];
}

- (void) resetToDefault
{
    int defaultValue;
    if ([self.key isEqualToString:delayToStartNavigationKey])
        defaultValue = [[OAAppSettings sharedManager].defaultApplicationMode.get isDerivedRoutingFrom:OAApplicationMode.CAR] ? 10 : -1;
    else
        defaultValue = self.defValue;
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

@interface OACommonLong ()

@property (nonatomic) long defValue;

@end

@implementation OACommonLong

+ (instancetype) withKey:(NSString *)key defValue:(long)defValue
{
    OACommonLong *obj = [[OACommonLong alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    return obj;
}

- (long) get
{
    return [self get:self.appMode];
}

- (long) get:(OAApplicationMode *)mode
{
    NSObject *value = [self getValue:mode];
    if (value)
        return ((NSNumber *)value).longValue;
    else
        return self.defValue;
}

- (void) set:(long)_long
{
    [self set:_long mode:self.appMode];
}

- (void) set:(long)_long mode:(OAApplicationMode *)mode
{
    [self setValue:@(_long) mode:mode];
}

- (void) resetToDefault
{
    long defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = ((NSNumber *)pDefault).longValue;

    [self set:defaultValue];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    [self set:strValue.longLongValue mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    return [NSString stringWithFormat:@"%li", [self get:mode]];
}

@end

@interface OACommonString ()

@property (nonatomic) NSString *defValue;

@end

@implementation OACommonString

+ (instancetype) withKey:(NSString *)key defValue:(NSString *)defValue
{
    OACommonString *obj = [[OACommonString alloc] init];
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

- (NSString *) get:(OAApplicationMode *)mode
{
    NSObject *value = [self getValue:mode];
    if (value)
        return (NSString *)value;
    else
        return self.defValue;
}

- (void) set:(NSString *)string
{
    [self set:string mode:self.appMode];
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

@interface OACommonDouble ()

@property (nonatomic) double defValue;

@end

@implementation OACommonDouble

+ (instancetype) withKey:(NSString *)key defValue:(double)defValue
{
    OACommonDouble *obj = [[OACommonDouble alloc] init];
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

- (double) get:(OAApplicationMode *)mode
{
    NSObject *value = [self getValue:mode];
    if (value)
        return ((NSNumber *)value).doubleValue;
    else
        return self.defValue;
}

- (void) set:(double)dbl
{
    [self set:dbl mode:self.appMode];
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

@interface OACommonStringList ()

@property (nonatomic) NSArray<NSString *> *defValue;

@end

@implementation OACommonStringList

+ (instancetype) withKey:(NSString *)key defValue:(NSArray<NSString *> *)defValue
{
    OACommonStringList *obj = [[OACommonStringList alloc] init];
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

- (NSArray<NSString *> *) get:(OAApplicationMode *)mode
{
    NSObject *value = [self getValue:mode];
    return value ? (NSArray<NSString *> *)value : self.defValue;
}

- (void) set:(NSArray<NSString *> *)arr
{
    [self set:arr mode:self.appMode];
}

- (void) set:(NSArray<NSString *> *)arr mode:(OAApplicationMode *)mode
{
    [self setValue:arr mode:mode];
}

- (void) add:(NSString *)string
{
    [self set:[[self get] arrayByAddingObject:string]];
}

- (void) add:(NSString *)string appMode:(OAApplicationMode *)appMode
{
    [self set:[[self get:appMode] arrayByAddingObject:string] mode:appMode];
}

- (void) addUnique:(NSString *)string
{
    if (![self contains:string])
        [self add:string];
}

- (void) remove:(NSString *)string
{
    if ([self contains:string])
        [self set:[[self get] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != %@", string]]];
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

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    [self set:[strValue componentsSeparatedByString:@","] mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    NSArray<NSString *> *value = [self get:mode];
    return value ? [value componentsJoinedByString:@","] : @"";
}

@end

@interface OACommonListOfStringList ()

@property (nonatomic) NSArray<NSArray<NSString *> *> *defValue;

@end

@implementation OACommonListOfStringList

+ (instancetype) withKey:(NSString *)key defValue:(NSArray<NSArray<NSString *> *> *)defValue
{
    OACommonListOfStringList *obj = [[OACommonListOfStringList alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    return obj;
}

- (NSArray<NSArray<NSString *> *> *) get
{
    return [self get:self.appMode];
}

- (NSArray<NSArray<NSString *> *> *) get:(OAApplicationMode *)mode
{
    NSObject *value = [self getValue:mode];
    return value ? (NSArray<NSArray<NSString *> *> *)value : self.defValue;
}

- (void) set:(NSArray<NSArray<NSString *> *> *)arr
{
    [self set:arr mode:self.appMode];
}

- (void) set:(NSArray<NSArray<NSString *> *> *)arr mode:(OAApplicationMode *)mode
{
    [self setValue:arr mode:mode];
}

- (void) resetToDefault
{
    NSArray<NSArray<NSString *> *> *defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = (NSArray<NSArray<NSString *> *> *)pDefault;
    
    [self set:defaultValue];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    NSMutableArray<NSArray<NSString *> *> *res = [NSMutableArray array];
    NSArray<NSString *> *subarrays = [strValue componentsSeparatedByString:@";"];
    for (NSString *str in subarrays)
    {
        if (str.length > 0) {
            [res addObject:[str componentsSeparatedByString:@","]];
        }
    }
    [self set:res mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    NSArray<NSArray<NSString *> *> *val = [self get:mode];
    NSMutableString *result = [NSMutableString string];
    for (NSArray<NSString *> *innerArray in val) {
        NSString *string = [innerArray componentsJoinedByString:@","];
        [result appendString:string];
        [result appendString:@";"];
    }
    return result;
}

@end

@interface OACommonSubscriptionState ()

@property (nonatomic) OASubscriptionState *defValue;

@end

@implementation OACommonSubscriptionState

+ (instancetype) withKey:(NSString *)key defValue:(OASubscriptionState *)defValue
{
    OACommonSubscriptionState *obj = [[OACommonSubscriptionState alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    return obj;
}

- (OASubscriptionState *) get
{
    return [self get:self.appMode];
}

- (OASubscriptionState *) get:(OAApplicationMode *)mode
{
    NSObject *val = [self getValue:mode];
    return val ? [OASubscriptionState getByStateStr:(NSString *)val] : self.defValue;
}

- (void) set:(OASubscriptionState *)state
{
    [self set:state mode:self.appMode];
}

- (void) set:(OASubscriptionState *)state mode:(OAApplicationMode *)mode
{
    [self setValue:state.stateStr mode:mode];
}

- (void) resetToDefault
{
    OASubscriptionState *defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = (OASubscriptionState *) pDefault;

    [self set:defaultValue];
}

@end


@interface OACommonMapSource ()

@property (nonatomic) OAMapSource *defValue;

@end

@implementation OACommonMapSource

+ (instancetype) withKey:(NSString *)key defValue:(OAMapSource *)defValue
{
    OACommonMapSource *obj = [[OACommonMapSource alloc] init];
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

- (OAMapSource *) get:(OAApplicationMode *)mode
{
    NSObject *val = [self getValue:mode];
    return val ? [OAMapSource fromDictionary:(NSDictionary *)val] : self.defValue;
}

- (void) set:(OAMapSource *)mapSource
{
    [self set:mapSource mode:self.appMode];
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

@implementation OACommonSpeedLimitWarningState

@dynamic defValue;

static NSString *kStateAlwaysKey = @"ALWAYS";
static NSString *kWhenExceededKey = @"WHAN_EXCEEDED";

+ (instancetype) withKey:(NSString *)key defValue:(EOASpeedLimitWarningState)defValue
{
    OACommonSpeedLimitWarningState *obj = [[OACommonSpeedLimitWarningState alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    return obj;
}

- (EOASpeedLimitWarningState) get
{
    return [super get];
}

- (EOASpeedLimitWarningState) get:(OAApplicationMode *)mode
{
    return [super get:mode];
}

- (void) set:(EOASpeedLimitWarningState)value
{
    [super set:(int)value];
}

- (void) set:(EOASpeedLimitWarningState)value mode:(OAApplicationMode *)mode
{
    [super set:(int)value mode:mode];
}

- (void) resetToDefault
{
    EOASpeedLimitWarningState defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = (EOASpeedLimitWarningState)((NSNumber *)pDefault).intValue;

    [self set:defaultValue];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    if ([strValue isEqualToString:kStateAlwaysKey])
        return [self set:EOASpeedLimitWarningStateAlways mode:mode];
    else if ([strValue isEqualToString:kWhenExceededKey])
        return [self set:EOASpeedLimitWarningStateWhenExceeded mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    switch ([self get:mode])
    {
        case EOASpeedLimitWarningStateAlways:
            return kStateAlwaysKey;
        case EOASpeedLimitWarningStateWhenExceeded:
            return kWhenExceededKey;
        default:
            return @"";
    }
}

- (NSString *) toHumanString
{
    return [self toHumanString:[self appMode]];
}

- (NSString *) toHumanString:(OAApplicationMode *)mode
{
    return [self.class toHumanString:[self get:mode]];
}

+ (NSString *) toHumanString:(EOASpeedLimitWarningState)value
{
    switch (value)
    {
        case EOASpeedLimitWarningStateAlways:
            return OALocalizedString(@"shared_string_always");
        case EOASpeedLimitWarningStateWhenExceeded:
            return OALocalizedString(@"when_exceeded");
        default:
            return @"";
    }
}

@end

@implementation OACommonAutoZoomMap

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(EOAAutoZoomMap)defValue
{
    OACommonAutoZoomMap *obj = [[OACommonAutoZoomMap alloc] init];
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

- (EOAAutoZoomMap) get:(OAApplicationMode *)mode
{
    return [super get:mode];
}

- (void) set:(EOAAutoZoomMap)autoZoomMap
{
    [super set:autoZoomMap];
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
            return @"FARTHEST";
    }
}

@end

@implementation OACommonSpeedConstant

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(EOASpeedConstant)defValue
{
    OACommonSpeedConstant *obj = [[OACommonSpeedConstant alloc] init];
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

- (EOASpeedConstant) get:(OAApplicationMode *)mode
{
    return [super get:mode];
}

- (void) set:(EOASpeedConstant)speedConstant
{
    [super set:speedConstant];
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

    if (mc == NAUTICAL_MILES_AND_METERS || mc == NAUTICAL_MILES_AND_FEET)
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

@implementation OACommonAngularConstant

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(EOAAngularConstant)defValue
{
    OACommonAngularConstant *obj = [[OACommonAngularConstant alloc] init];
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

- (EOAAngularConstant) get:(OAApplicationMode *)mode
{
    return [super get:mode];
}

- (void) set:(EOAAngularConstant)angularConstant
{
    [super set:angularConstant];
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

@implementation OACommonActiveMarkerConstant

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(EOAActiveMarkerConstant)defValue
{
    OACommonActiveMarkerConstant *obj = [[OACommonActiveMarkerConstant alloc] init];
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

- (EOAActiveMarkerConstant) get:(OAApplicationMode *)mode
{
    return [super get:mode];
}

- (void) set:(EOAActiveMarkerConstant)activeMarkerConstant
{
    [super set:activeMarkerConstant];
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

@implementation OACommonDrivingRegion

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(EOADrivingRegion)defValue
{
    OACommonDrivingRegion *obj = [[OACommonDrivingRegion alloc] init];
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

- (EOADrivingRegion) get:(OAApplicationMode *)mode
{
    return [super get:mode];
}

- (void) set:(EOADrivingRegion)drivingRegionConstant
{
    [super set:drivingRegionConstant];
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

@implementation OACommonMetricSystem

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(EOAMetricsConstant)defValue
{
    OACommonMetricSystem *obj = [[OACommonMetricSystem alloc] init];
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

- (EOAMetricsConstant) get:(OAApplicationMode *)mode
{
    return [super get:mode];
}

- (void) set:(EOAMetricsConstant)metricsConstant
{
    [super set:metricsConstant];
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
    else if ([strValue isEqualToString:@"NAUTICAL_MILES_AND_METERS"])
        return [self set:NAUTICAL_MILES_AND_METERS mode:mode];
    else if ([strValue isEqualToString:@"NAUTICAL_MILES_AND_FEET"])
        return [self set:NAUTICAL_MILES_AND_FEET mode:mode];
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
        case NAUTICAL_MILES_AND_METERS:
            return @"NAUTICAL_MILES_AND_METERS";
        case NAUTICAL_MILES_AND_FEET:
            return @"NAUTICAL_MILES_AND_FEET";
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

@implementation OACommonRulerWidgetMode

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(EOARulerWidgetMode)defValue
{
    OACommonRulerWidgetMode *obj = [[OACommonRulerWidgetMode alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    return obj;
}

- (EOARulerWidgetMode) get
{
    return [super get];
}

- (void) set:(EOARulerWidgetMode)rulerWidgetMode
{
    [super set:rulerWidgetMode];
}

- (EOARulerWidgetMode) get:(OAApplicationMode *)mode
{
    return [super get:mode];
}

- (void) set:(EOARulerWidgetMode)rulerWidgetMode mode:(OAApplicationMode *)mode
{
    [super set:rulerWidgetMode mode:mode];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    if ([strValue isEqualToString:@"FIRST"])
        return [self set:RULER_MODE_DARK mode:mode];
    else if ([strValue isEqualToString:@"SECOND"])
        return [self set:RULER_MODE_LIGHT mode:mode];
    else if ([strValue isEqualToString:@"EMPTY"])
        return [self set:RULER_MODE_NO_CIRCLES mode:mode];
}

+ (NSString *) rulerWidgetModeToString:(EOARulerWidgetMode)rulerMode
{
    switch (rulerMode) {
        case RULER_MODE_DARK:
            return @"FIRST";
        case RULER_MODE_LIGHT:
            return @"SECOND";
        case RULER_MODE_NO_CIRCLES:
            return @"EMPTY";
        default:
            return @"FIRST";
    }
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    return [self.class rulerWidgetModeToString:[self get:mode]];
}

- (void) resetToDefault
{
    EOARulerWidgetMode defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = (EOARulerWidgetMode)((NSNumber *)pDefault).intValue;

    [self set:defaultValue];
}

@end

@implementation OACommonWikiArticleShowImages

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(EOAWikiArticleShowConstant)defValue
{
    OACommonWikiArticleShowImages *obj = [[OACommonWikiArticleShowImages alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    return obj;
}

- (EOAWikiArticleShowConstant) get
{
    return [super get];
}

- (void) set:(EOAWikiArticleShowConstant)wikiArticleShow
{
    [super set:wikiArticleShow];
}

- (EOAWikiArticleShowConstant) get:(OAApplicationMode *)mode
{
    return [super get:mode];
}

- (void) set:(EOAWikiArticleShowConstant)wikiArticleShow mode:(OAApplicationMode *)mode
{
    [super set:wikiArticleShow mode:mode];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    if ([strValue isEqualToString:@"ON"])
        return [self set:EOAWikiArticleShowConstantOn mode:mode];
    else if ([strValue isEqualToString:@"OFF"])
        return [self set:EOAWikiArticleShowConstantOff mode:mode];
    else if ([strValue isEqualToString:@"WIFI"])
        return [self set:EOAWikiArticleShowConstantWiFi mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    switch ([self get:mode])
    {
        case EOAWikiArticleShowConstantOn:
            return @"ON";
        case EOAWikiArticleShowConstantOff:
            return @"OFF";
        case EOAWikiArticleShowConstantWiFi:
            return @"WIFI";
        default:
            return @"OFF";
    }
}

- (void) resetToDefault
{
    EOAWikiArticleShowConstant defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = (EOAWikiArticleShowConstant)((NSNumber *)pDefault).intValue;

    [self set:defaultValue];
}

@end

@implementation OACommonRateUsState

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(EOARateUsState)defValue
{
    OACommonRateUsState *obj = [[OACommonRateUsState alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    return obj;
}

- (EOARateUsState) get
{
    return [super get];
}

- (void) set:(EOARateUsState)rateUsState
{
    [super set:rateUsState];
}

- (EOARateUsState) get:(OAApplicationMode *)mode
{
    return [super get:mode];
}

- (void) set:(EOARateUsState)rateUsState mode:(OAApplicationMode *)mode
{
    [super set:rateUsState mode:mode];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    if ([strValue isEqualToString:@"INITIAL_STATE"])
        return [self set:EOARateUsStateInitialState mode:mode];
    else if ([strValue isEqualToString:@"IGNORED"])
        return [self set:EOARateUsStateIgnored mode:mode];
    else if ([strValue isEqualToString:@"LIKED"])
        return [self set:EOARateUsStateLiked mode:mode];
    else if ([strValue isEqualToString:@"DISLIKED_WITH_MESSAGE"])
        return [self set:EOARateUsStateDislikedWithMessage mode:mode];
    else if ([strValue isEqualToString:@"DISLIKED_WITHOUT_MESSAGE"])
        return [self set:EOARateUsStateDislikedWithoutMessage mode:mode];
    else if ([strValue isEqualToString:@"DISLIKED_OR_IGNORED_AGAIN"])
        return [self set:EOARateUsStateDislikedOrIgnoredAgain mode:mode];

}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    switch ([self get:mode])
    {
        case EOARateUsStateInitialState:
            return @"INITIAL_STATE";
        case EOARateUsStateIgnored:
            return @"IGNORED";
        case EOARateUsStateLiked:
            return @"LIKED";
        case EOARateUsStateDislikedWithMessage:
            return @"DISLIKED_WITH_MESSAGE";
        case EOARateUsStateDislikedWithoutMessage:
            return @"DISLIKED_WITHOUT_MESSAGE";
        case EOARateUsStateDislikedOrIgnoredAgain:
            return @"DISLIKED_OR_IGNORED_AGAIN";
        default:
            return @"EOARateUsStateInitialState";
    }
}

- (void) resetToDefault
{
    EOARateUsState defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = (EOARateUsState)((NSNumber *)pDefault).intValue;

    [self set:defaultValue];
}

@end

@implementation OACommonGradientScaleType

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(EOAGradientScaleType)defValue
{
    OACommonGradientScaleType *obj = [[OACommonGradientScaleType alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    return obj;
}

- (EOAGradientScaleType) get
{
    return [super get];
}

- (void) set:(EOAGradientScaleType)gradientScaleType
{
    [super set:gradientScaleType];
}

- (EOAGradientScaleType) get:(OAApplicationMode *)mode
{
    return [super get:mode];
}

- (void) set:(EOAGradientScaleType)gradientScaleType mode:(OAApplicationMode *)mode
{
    [super set:gradientScaleType mode:mode];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    if ([strValue isEqualToString:@"SPEED"])
        return [self set:EOAGradientScaleTypeSpeed mode:mode];
    else if ([strValue isEqualToString:@"ALTITUDE"])
        return [self set:EOAGradientScaleTypeAltitude mode:mode];
    else if ([strValue isEqualToString:@"SLOPE"])
        return [self set:EOAGradientScaleTypeSlope mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    switch ([self get:mode])
    {
        case EOAGradientScaleTypeSpeed:
            return @"SPEED";
        case EOAGradientScaleTypeAltitude:
            return @"ALTITUDE";
        case EOAGradientScaleTypeSlope:
            return @"SLOPE";
        default:
            return @"SPEED";
    }
}

- (void) resetToDefault
{
    EOAGradientScaleType defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = (EOAGradientScaleType)((NSNumber *)pDefault).intValue;

    [self set:defaultValue];
}

@end

@implementation OACommonUploadVisibility

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(EOAUploadVisibility)defValue
{
    OACommonUploadVisibility *obj = [[OACommonUploadVisibility alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    return obj;
}

- (EOAUploadVisibility) get
{
    return [super get];
}

- (void) set:(EOAUploadVisibility)gradientScaleType
{
    [super set:gradientScaleType];
}

- (EOAUploadVisibility) get:(OAApplicationMode *)mode
{
    return [super get:mode];
}

- (void) set:(EOAUploadVisibility)gradientScaleType mode:(OAApplicationMode *)mode
{
    [super set:gradientScaleType mode:mode];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    if ([strValue isEqualToString:@"PUBLIC"])
        return [self set:EOAUploadVisibilityPublic mode:mode];
    else if ([strValue isEqualToString:@"IDENTIFIABLE"])
        return [self set:EOAUploadVisibilityIdentifiable mode:mode];
    else if ([strValue isEqualToString:@"TRACKABLE"])
        return [self set:EOAUploadVisibilityTrackable mode:mode];
    else if ([strValue isEqualToString:@"PRIVATE"])
        return [self set:EOAUploadVisibilityPrivate mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    switch ([self get:mode])
    {
        case EOAUploadVisibilityPublic:
            return @"PUBLIC";
        case EOAUploadVisibilityIdentifiable:
            return @"IDENTIFIABLE";
        case EOAUploadVisibilityTrackable:
            return @"TRACKABLE";
        case EOAUploadVisibilityPrivate:
            return @"PRIVATE";
        default:
            return @"PUBLIC";
    }
}

- (void) resetToDefault
{
    EOAUploadVisibility defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = (EOAUploadVisibility)((NSNumber *)pDefault).intValue;

    [self set:defaultValue];
}

@end

@implementation OACommonCoordinateInputFormats

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(EOACoordinateInputFormats)defValue
{
    OACommonCoordinateInputFormats *obj = [[OACommonCoordinateInputFormats alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    return obj;
}

- (EOACoordinateInputFormats) get
{
    return [super get];
}

- (void) set:(EOACoordinateInputFormats)coordinateInputFormats
{
    [super set:coordinateInputFormats];
}

- (EOACoordinateInputFormats) get:(OAApplicationMode *)mode
{
    return [super get:mode];
}

- (void) set:(EOACoordinateInputFormats)coordinateInputFormats mode:(OAApplicationMode *)mode
{
    [super set:coordinateInputFormats mode:mode];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    if ([strValue isEqualToString:@"DD_MM_MMM"])
        return [self set:EOACoordinateInputFormatsDdMmMmm mode:mode];
    else if ([strValue isEqualToString:@"DD_MM_MMMM"])
        return [self set:EOACoordinateInputFormatsDdMmMmmm mode:mode];
    else if ([strValue isEqualToString:@"DD_DDDDD"])
        return [self set:EOACoordinateInputFormatsDdDdddd mode:mode];
    else if ([strValue isEqualToString:@"DD_DDDDDD"])
        return [self set:EOACoordinateInputFormatsDdDddddd mode:mode];
    else if ([strValue isEqualToString:@"DD_MM_SS"])
        return [self set:EOACoordinateInputFormatsDdMmSs mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    switch ([self get:mode])
    {
        case EOACoordinateInputFormatsDdMmMmm:
            return @"DD_MM_MMM";
        case EOACoordinateInputFormatsDdMmMmmm:
            return @"DD_MM_MMMM";
        case EOACoordinateInputFormatsDdDdddd:
            return @"DD_DDDDD";
        case EOACoordinateInputFormatsDdDddddd:
            return @"DD_DDDDDD";
        case EOACoordinateInputFormatsDdMmSs:
            return @"DD_MM_SS";
        default:
            return @"DD_MM_MMM";
    }
}

- (void) resetToDefault
{
    EOACoordinateInputFormats defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = (EOACoordinateInputFormats)((NSNumber *)pDefault).intValue;

    [self set:defaultValue];
}

@end

@implementation OACommonDownloadMode
{
    NSArray<OADownloadMode *> *_values;
}

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(OADownloadMode *)defValue
{
    OACommonDownloadMode *obj = [[OACommonDownloadMode alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
        obj.values = [NSArray array];
    }
    return obj;
}

+ (instancetype) withKey:(NSString *)key defValue:(OADownloadMode *)defValue values:(NSArray<OADownloadMode *> *)values
{
    OACommonDownloadMode *obj = [[OACommonDownloadMode alloc] init];
    if (obj)
    {
        obj.key = key;
        NSUInteger indexOfValue = [values indexOfObject:defValue];
        obj.defValue = indexOfValue != NSNotFound ? indexOfValue : 0;
        obj.values = values;
    }
    return obj;
}

- (OADownloadMode *) get
{
    NSInteger indexOfValue = [super get:self.appMode];
    return self.values.count > indexOfValue ? self.values[indexOfValue] : self.values.firstObject;
}

- (void) set:(OADownloadMode *)downloadMode
{
    NSUInteger indexOfValue = [self.values indexOfObject:downloadMode];
    [super setValue:@(indexOfValue != NSNotFound ? indexOfValue : 0) mode:self.appMode];
}

- (OADownloadMode *) get:(OAApplicationMode *)mode
{
    NSInteger indexOfValue = [super get:mode];
    return self.values.count > indexOfValue ? self.values[indexOfValue] : self.values.firstObject;
}

- (void) set:(OADownloadMode *)downloadMode mode:(OAApplicationMode *)mode
{
    NSUInteger indexOfValue = [self.values indexOfObject:downloadMode];
    [super set:indexOfValue != NSNotFound ? indexOfValue : 0 mode:mode];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    if ([strValue isEqualToString:@"none"])
        return [self set:OADownloadMode.NONE mode:mode];
    else if ([strValue isEqualToString:@"wifi"])
        return [self set:OADownloadMode.WIFI_ONLY mode:mode];
    else if ([strValue isEqualToString:@"wifi"])
        return [self set:OADownloadMode.ANY_NETWORK mode:mode];
    
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    OADownloadMode *downloadMode = [OADownloadMode getDownloadModes][[super get:mode]];

    if ([downloadMode isEqual:OADownloadMode.NONE])
        return @"none";
    else if ([downloadMode isEqual:OADownloadMode.WIFI_ONLY])
        return @"wifi";
    else if ([downloadMode isEqual:OADownloadMode.ANY_NETWORK])
        return @"any";

    return @"any";
}

- (void) resetToDefault
{
    [self set:self.values.count > self.defValue ? self.values[self.defValue] : self.values.firstObject];
}

@end

@implementation OACommonColoringType
{
    NSArray<OAColoringType *> *_values;
}

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(OAColoringType *)defValue
{
    OACommonColoringType *obj = [[OACommonColoringType alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = 0;
        obj.values = [NSArray array];
    }
    return obj;
}

+ (instancetype) withKey:(NSString *)key defValue:(OAColoringType *)defValue values:(NSArray<OAColoringType *> *)values
{
    OACommonColoringType *obj = [[OACommonColoringType alloc] init];
    if (obj)
    {
        obj.key = key;
        NSUInteger indexOfValue = [values indexOfObject:defValue];
        obj.defValue = indexOfValue != NSNotFound ? indexOfValue : 0;
        obj.values = values;
    }
    return obj;
}

- (OAColoringType *) get
{
    NSInteger indexOfValue = [super get:self.appMode];
    return self.values.count > indexOfValue ? self.values[indexOfValue] : self.values.firstObject;
}

- (void) set:(OAColoringType *)coloringType
{
    NSUInteger indexOfValue = [self.values indexOfObject:coloringType];
    [super setValue:@(indexOfValue != NSNotFound ? indexOfValue : 0) mode:self.appMode];
}

- (OAColoringType *) get:(OAApplicationMode *)mode
{
    NSInteger indexOfValue = [super get:mode];
    return self.values.count > indexOfValue ? self.values[indexOfValue] : self.values.firstObject;
}

- (void) set:(OAColoringType *)coloringType mode:(OAApplicationMode *)mode
{
    NSUInteger indexOfValue = [self.values indexOfObject:coloringType];
    [super set:indexOfValue != NSNotFound ? indexOfValue : 0 mode:mode];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    if ([strValue isEqualToString:@"default"])
        return [self set:OAColoringType.DEFAULT mode:mode];
    else if ([strValue isEqualToString:@"custom_color"])
        return [self set:OAColoringType.CUSTOM_COLOR mode:mode];
    else if ([strValue isEqualToString:@"solid"])
        return [self set:OAColoringType.TRACK_SOLID mode:mode];
    else if ([strValue isEqualToString:@"speed"])
        return [self set:OAColoringType.SPEED mode:mode];
    else if ([strValue isEqualToString:@"altitude"])
        return [self set:OAColoringType.ALTITUDE mode:mode];
    else if ([strValue isEqualToString:@"slope"])
        return [self set:OAColoringType.SLOPE mode:mode];
    else if ([strValue isEqualToString:@"attribute"])
        return [self set:OAColoringType.ATTRIBUTE mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    OAColoringType *type = [OAColoringType getRouteColoringTypes][[super get:mode]];

    if ([type isEqual:OAColoringType.CUSTOM_COLOR])
        return @"custom_color";
    else if ([type isEqual:OAColoringType.TRACK_SOLID])
        return @"solid";
    else if ([type isEqual:OAColoringType.SPEED])
        return @"speed";
    else if ([type isEqual:OAColoringType.ALTITUDE])
        return @"altitude";
    else if ([type isEqual:OAColoringType.SLOPE])
        return @"slope";
    else if ([type isEqual:OAColoringType.ATTRIBUTE])
        return @"attribute";

    return @"default";
}

- (void) resetToDefault
{
    [self set:self.values.count > self.defValue ? self.values[self.defValue] : self.values.firstObject];
}

@end


@interface OACommonUnit ()

@property (nonatomic) NSUnit *defValue;

@end

@implementation OACommonUnit

+ (instancetype) withKey:(NSString *)key defValue:(NSUnit *)defValue
{
    OACommonUnit *obj = [[OACommonUnit alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    return obj;
}

- (NSUnit *) get
{
    return [self get:self.appMode];
}

- (NSUnit *) get:(OAApplicationMode *)mode
{
    NSObject *value = [self getValue:mode];
    return value ? (NSUnit *) value : self.defValue;
}

- (NSObject *) getValue:(OAApplicationMode *)mode
{
    NSObject *cachedValue = self.global ? self.cachedValue : [self.cachedValues objectForKey:mode];
    if (!cachedValue)
    {
        NSString *key = [self getKey:mode];
        cachedValue = [[NSUserDefaults standardUserDefaults] objectForKey:key];

        if ([cachedValue isKindOfClass:NSString.class])
            cachedValue = [NSUnit unitFromString:cachedValue];

        if ([cachedValue isKindOfClass:NSData.class])
            cachedValue = [NSKeyedUnarchiver unarchivedObjectOfClass:NSUnit.class fromData:cachedValue error:nil];

        if (self.global)
            self.cachedValue = cachedValue;
        else
            [self.cachedValues setObject:cachedValue forKey:mode];
    }
    else if ([cachedValue isKindOfClass:NSString.class])
    {
        cachedValue = [NSUnit unitFromString:cachedValue];
    }

    if (!cachedValue)
    {
        cachedValue = [self getProfileDefaultValue:mode];
    }
    return cachedValue;
}

- (void) set:(NSUnit *)unit
{
    [self set:unit mode:self.appMode];
}

- (void) set:(NSUnit *)unit mode:(OAApplicationMode *)mode
{
    [self setValue:unit mode:mode];
}

- (void) setValue:(NSObject *)value mode:(OAApplicationMode *)mode
{
    NSUnit *unit = (NSUnit *) value;

    if (self.global)
        self.cachedValue = unit;
    else
        [self.cachedValues setObject:unit forKey:mode];

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:unit requiringSecureCoding:NO error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:[self getKey:mode]];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSetProfileSetting object:self];
}

- (NSObject *)getProfileDefaultValue:(OAApplicationMode *)mode
{
    NSObject *value = [super getProfileDefaultValue:mode];
    if ([value isKindOfClass:NSString.class])
        value = [NSUnit unitFromString:value];
    return value;
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    [self set:[NSUnit unitFromString:strValue] mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    return [self get:mode].symbol;
}

@end

@implementation OACommonWidgetSizeStyle

@dynamic defValue;

+ (instancetype) withKey:(NSString *)key defValue:(EOAWidgetSizeStyle)defValue
{
    OACommonWidgetSizeStyle *obj = [[OACommonWidgetSizeStyle alloc] init];
    if (obj)
    {
        obj.key = key;
        obj.defValue = defValue;
    }
    return obj;
}

- (EOAWidgetSizeStyle) get
{
    return [super get];
}

- (void) set:(EOAWidgetSizeStyle)widgetSizeStyle
{
    [super set:widgetSizeStyle];
}

- (EOAWidgetSizeStyle) get:(OAApplicationMode *)mode
{
    return [super get:mode];
}

- (void) set:(EOAWidgetSizeStyle)widgetSizeStyle mode:(OAApplicationMode *)mode
{
    [super set:widgetSizeStyle mode:mode];
}

- (void)setValueFromString:(NSString *)strValue appMode:(OAApplicationMode *)mode
{
    if ([strValue isEqualToString:@"SMALL"])
        return [self set:EOAWidgetSizeStyleSmall mode:mode];
    else if ([strValue isEqualToString:@"MEDIUM"])
        return [self set:EOAWidgetSizeStyleMedium mode:mode];
    else if ([strValue isEqualToString:@"LARGE"])
        return [self set:EOAWidgetSizeStyleLarge mode:mode];
}

- (NSString *)toStringValue:(OAApplicationMode *)mode
{
    switch ([self get:mode])
    {
        case EOAWidgetSizeStyleSmall:
            return @"SMALL";
        case EOAWidgetSizeStyleLarge:
            return @"LARGE";
        default:
            return @"MEDIUM";
    }
}

- (void) resetToDefault
{
    EOAWidgetSizeStyle defaultValue = self.defValue;
    NSObject *pDefault = [self getProfileDefaultValue:self.appMode];
    if (pDefault)
        defaultValue = (EOAWidgetSizeStyle) ((NSNumber *) pDefault).intValue;

    [self set:defaultValue];
}

@end

@implementation OAAppSettings
{
    NSMapTable<NSString *, OACommonBoolean *> *_customBooleanRoutingProps;
    NSMapTable<NSString *, OACommonString *> *_customRoutingProps;
    NSMapTable<NSString *, OACommonPreference *> *_registeredPreferences;
    NSMapTable<NSString *, OACommonPreference *> *_globalPreferences;
    NSMapTable<NSString *, OACommonPreference *> *_profilePreferences;
    OADayNightHelper *_dayNightHelper;
    
    NSObject *_settingsLock;
    NSSet<NSString *> *_disabledTypes;
    
    OACommonDouble *_lastStartLat;
    OACommonDouble *_lastStartLon;
}

@synthesize settingShowMapRulet=_settingShowMapRulet, settingMapLanguageShowLocal=_settingMapLanguageShowLocal;
@synthesize mapSettingShowFavorites=_mapSettingShowFavorites, mapSettingShowPoiLabel=_mapSettingShowPoiLabel, mapSettingShowOfflineEdits=_mapSettingShowOfflineEdits, mapSettingShowOnlineNotes=_mapSettingShowOnlineNotes, mapSettingTrackRecording=_mapSettingTrackRecording;

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
        _settingsLock = [[NSObject alloc] init];
        _dayNightHelper = [OADayNightHelper instance];
        _customBooleanRoutingProps = [NSMapTable strongToStrongObjectsMapTable];
        _customRoutingProps = [NSMapTable strongToStrongObjectsMapTable];
        _registeredPreferences = [NSMapTable strongToStrongObjectsMapTable];
        _globalPreferences = [NSMapTable strongToStrongObjectsMapTable];
        _profilePreferences = [NSMapTable strongToStrongObjectsMapTable];
        
        _applicationMode = [[[OACommonAppMode withKey:applicationModeKey defValue:OAApplicationMode.DEFAULT] makeGlobal] makeShared];
        [_globalPreferences setObject:_applicationMode forKey:@"application_mode"];
        
        _trackIntervalArray = @[@0, @1, @2, @3, @5, @10, @15, @30, @60, @90, @120, @180, @300];
        
        _mapLanguages = @[
            @"af", @"als", @"ar", @"az", @"be", @"ber", @"bg", @"bn", @"bpy", @"br", @"bs", @"ca", @"ceb", @"ckb", @"cs", @"cy", @"da", @"de", @"el", @"eo", @"es", @"et", @"eu", @"fa", @"fi", @"fr", @"fy", @"ga", @"gl", @"he", @"hi", @"hsb", @"hr", @"ht", @"hu", @"hy", @"id", @"is", @"it", @"ja", @"ka", @"kab", @"kk", @"kn", @"ko", @"ku", @"la", @"lb", @"lo", @"lt", @"lv", @"mk", @"ml", @"mr", @"ms", @"nds", @"new", @"nl", @"nn", @"no", @"nv", @"oc", @"os", @"pl", @"pms", @"pt", @"ro", @"ru", @"sat", @"sc", @"sh", @"sk", @"sl", @"sq", @"sr", @"sr-Latn", @"sv", @"sw", @"ta", @"te", @"th", @"tl", @"tr", @"uk", @"vi", @"vo", @"zh", @"zh-Hans", @"zh-Hant"];
        
        _rtlLanguages = @[@"ar",@"dv",@"he",@"iw",@"fa",@"nqo",@"ps",@"sd",@"ug",@"ur",@"yi"];
        
        _ttsAvailableVoices = @[@"ar", @"bg", @"cs", @"ca", @"da", @"de", @"el", @"en-gb", @"en", @"es-ar", @"es", @"et", @"fa", @"fi", @"fr", @"hi", @"hr", @"hu-formal", @"hu", @"id", @"it", @"ja", @"ko", @"nb", @"nl", @"pl", @"pt-br", @"pt", @"ro", @"ru", @"sk", @"sl", @"sv", @"tr", @"uk", @"zh-hk", @"zh"];
        
        // Common Settings
        _settingMapLanguage = [[[OACommonInteger withKey:settingMapLanguageKey defValue:0] makeGlobal] makeShared];
        _settingPrefMapLanguage = [[[OACommonString withKey:settingPrefMapLanguageKey defValue:@""] makeGlobal] makeShared];
        _settingMapLanguageShowLocal = [[NSUserDefaults standardUserDefaults] objectForKey:settingMapLanguageShowLocalKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:settingMapLanguageShowLocalKey] : NO;
        _settingMapLanguageTranslit = [[[OACommonBoolean withKey:settingMapLanguageTranslitKey defValue: NO] makeGlobal] makeShared];
        
        [_globalPreferences setObject:_settingMapLanguage forKey:@"preferred_locale"];
        [_globalPreferences setObject:_settingPrefMapLanguage forKey:@"map_preferred_locale"];
        [_globalPreferences setObject:_settingMapLanguageTranslit forKey:@"map_transliterate_names"];
        
        _settingShowMapRulet = [[NSUserDefaults standardUserDefaults] objectForKey:settingShowMapRuletKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:settingShowMapRuletKey] : YES;
        _appearanceMode = [OACommonInteger withKey:settingAppModeKey defValue:APPEARANCE_MODE_DAY];
        [_appearanceMode setModeDefaultValue:@(APPEARANCE_MODE_AUTO) mode:OAApplicationMode.CAR];
        [_appearanceMode setModeDefaultValue:@(APPEARANCE_MODE_AUTO) mode:OAApplicationMode.BICYCLE];
        [_appearanceMode setModeDefaultValue:@(APPEARANCE_MODE_DAY) mode:OAApplicationMode.PEDESTRIAN];
        [_profilePreferences setObject:_appearanceMode forKey:@"daynight_mode"];
        
        _appearanceProfileTheme = [OACommonInteger withKey:appearanceProfileThemeKey defValue:0];
        [_profilePreferences setObject:_appearanceProfileTheme forKey:@"osmand_theme"];
        
        _mapManuallyRotatingAngle = [OACommonDouble withKey:mapManuallyRotatingAngleKey defValue:0];
        [_profilePreferences setObject:_appearanceMode forKey:mapManuallyRotatingAngleKey];
        
        _settingShowZoomButton = YES;//[[NSUserDefaults standardUserDefaults] objectForKey:settingZoomButtonKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:settingZoomButtonKey] : YES;
        _settingMapArrows = [[NSUserDefaults standardUserDefaults] objectForKey:settingMapArrowsKey] ? (int)[[NSUserDefaults standardUserDefaults] integerForKey:settingMapArrowsKey] : MAP_ARROWS_LOCATION;
        
        _settingShowAltInDriveMode = [[NSUserDefaults standardUserDefaults] objectForKey:settingMapShowAltInDriveModeKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:settingMapShowAltInDriveModeKey] : NO;
        
        _settingDoNotShowPromotions = [[[OACommonBoolean withKey:settingDoNotShowPromotionsKey defValue:NO] makeGlobal] makeShared];
        _settingUseAnalytics = [[[OACommonBoolean withKey:settingUseFirebaseKey defValue:YES] makeGlobal] makeShared];
        
        [_globalPreferences setObject:_settingDoNotShowPromotions forKey:@"do_not_show_promotions"];
        [_globalPreferences setObject:_settingUseAnalytics forKey:@"use_analytics"];
        [_globalPreferences setObject:_showDownloadMapDialog forKey:@"show_download_map_dialog"];
        
        _animateMyLocation = [OACommonBoolean withKey:animateMyLocationKey defValue:YES];
        _doNotUseAnimations = [OACommonBoolean withKey:doNotUseAnimationsKey defValue:NO];
        [_profilePreferences setObject:_animateMyLocation forKey:@"animate_my_location"];
        [_profilePreferences setObject:_animateMyLocation forKey:@"do_not_use_animations"];
        
        _liveUpdatesPurchased = [[OACommonBoolean withKey:liveUpdatesPurchasedKey defValue:NO] makeGlobal];
        _settingOsmAndLiveEnabled = [[[OACommonBoolean withKey:settingOsmAndLiveEnabledKey defValue:NO] makeGlobal] makeShared];
        _liveUpdatesRetries = [[OACommonInteger withKey:liveUpdatesRetriesKey defValue:2] makeGlobal];
        
        [_globalPreferences setObject:_liveUpdatesPurchased forKey:@"billing_live_updates_purchased"];
        [_globalPreferences setObject:_settingOsmAndLiveEnabled forKey:@"is_live_updates_on"];
        [_globalPreferences setObject:_liveUpdatesRetries forKey:@"live_updates_retryes"];
        
        _billingUserId = [[OACommonString withKey:billingUserIdKey defValue:@""] makeGlobal];
        _billingUserName = [[OACommonString withKey:billingUserNameKey defValue:@""] makeGlobal];
        _billingUserToken = [[OACommonString withKey:billingUserTokenKey defValue:@""] makeGlobal];
        _billingUserEmail = [[OACommonString withKey:billingUserEmailKey defValue:@""] makeGlobal];
        _billingUserCountry = [[OACommonString withKey:billingUserCountryKey defValue:@""] makeGlobal];
        _billingUserCountryDownloadName = [[OACommonString withKey:billingUserCountryDownloadNameKey defValue:kBillingUserDonationNone] makeGlobal];
        _billingHideUserName = [[OACommonBoolean withKey:billingHideUserNameKey defValue:NO] makeGlobal];
        _billingPurchaseTokenSent = [[OACommonBoolean withKey:billingPurchaseTokenSentKey defValue:NO] makeGlobal];
        _billingPurchaseTokensSent = [[OACommonString withKey:billingPurchaseTokensSentKey defValue:@""] makeGlobal];
        _liveUpdatesPurchaseCancelledFirstDlgShown = [[OACommonBoolean withKey:liveUpdatesPurchaseCancelledFirstDlgShownKey defValue:NO] makeGlobal];
        _liveUpdatesPurchaseCancelledSecondDlgShown = [[OACommonBoolean withKey:liveUpdatesPurchaseCancelledSecondDlgShownKey defValue:NO] makeGlobal];
        _fullVersionPurchased = [[OACommonBoolean withKey:fullVersionPurchasedKey defValue:NO] makeGlobal];
        _depthContoursPurchased = [[OACommonBoolean withKey:depthContoursPurchasedKey defValue:NO] makeGlobal];
        _contourLinesPurchased = [[OACommonBoolean withKey:contourLinesPurchasedKey defValue:NO] makeGlobal];
        _wikipediaPurchased = [[OACommonBoolean withKey:wikipediaPurchasedKey defValue:NO] makeGlobal];
        _emailSubscribed = [[OACommonBoolean withKey:emailSubscribedKey defValue:NO] makeGlobal];
        _osmandProPurchased = [[OACommonBoolean withKey:osmandProPurchasedKey defValue:NO] makeGlobal];
        _osmandMapsPurchased = [[OACommonBoolean withKey:osmandMapsPurchasedKey defValue:NO] makeGlobal];
        _mapperLiveUpdatesExpireTime = [[OACommonLong withKey:mapperLiveUpdatesExpireTimeKey defValue:0] makeGlobal];
        
        _lastReceiptValidationDate = [[NSUserDefaults standardUserDefaults] objectForKey:lastReceiptValidationDateKey] ? [NSDate dateWithTimeIntervalSince1970:[[NSUserDefaults standardUserDefaults] doubleForKey:lastReceiptValidationDateKey]] : [NSDate dateWithTimeIntervalSince1970:0];
        _eligibleForIntroductoryPrice = [[NSUserDefaults standardUserDefaults] objectForKey:eligibleForIntroductoryPriceKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:eligibleForIntroductoryPriceKey] : NO;
        _eligibleForSubscriptionOffer = [[NSUserDefaults standardUserDefaults] objectForKey:eligibleForSubscriptionOfferKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:eligibleForSubscriptionOfferKey] : NO;
        
        [_globalPreferences setObject:_billingUserId forKey:@"billing_user_id"];
        [_globalPreferences setObject:_billingUserName forKey:@"billing_user_name"];
        [_globalPreferences setObject:_billingUserToken forKey:@"billing_user_token"];
        [_globalPreferences setObject:_billingUserEmail forKey:@"billing_user_email"];
        [_globalPreferences setObject:_billingUserCountry forKey:@"billing_user_country"];
        [_globalPreferences setObject:_billingUserCountryDownloadName forKey:@"billing_user_country_download_name"];
        [_globalPreferences setObject:_billingHideUserName forKey:@"billing_hide_user_name"];
        [_globalPreferences setObject:_billingPurchaseTokenSent forKey:@"billing_purchase_token_sent"];
        [_globalPreferences setObject:_billingPurchaseTokensSent forKey:@"billing_purchase_tokens_sent"];
        [_globalPreferences setObject:_liveUpdatesPurchaseCancelledFirstDlgShown forKey:@"live_updates_cancelled_first_dlg_shown_time"];
        [_globalPreferences setObject:_liveUpdatesPurchaseCancelledSecondDlgShown forKey:@"live_updates_cancelled_second_dlg_shown_time"];
        [_globalPreferences setObject:_fullVersionPurchased forKey:@"billing_full_version_purchased"];
        [_globalPreferences setObject:_depthContoursPurchased forKey:@"billing_sea_depth_purchased"];
        [_globalPreferences setObject:_contourLinesPurchased forKey:@"billing_srtm_purchased"];
        [_globalPreferences setObject:_wikipediaPurchased forKey:@"billing_wiki_purchased"];
        [_globalPreferences setObject:_emailSubscribed forKey:@"email_subscribed"];
        [_globalPreferences setObject:_osmandProPurchased forKey:@"billing_osmand_pro_purchased"];
        [_globalPreferences setObject:_osmandMapsPurchased forKey:@"billing_osmand_maps_purchased"];
        [_globalPreferences setObject:_mapperLiveUpdatesExpireTime forKey:@"mapper_live_updates_expire_time"];
        
        _shouldShowWhatsNewScreen = [[NSUserDefaults standardUserDefaults] objectForKey:shouldShowWhatsNewScreenKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:shouldShowWhatsNewScreenKey] : YES;
        
        // Widgets
        _leftWidgetPanelOrder = [OACommonListOfStringList withKey:leftWidgetPanelOrderKey defValue:@[[[OAWidgetsPanel leftPanel] getOriginalOrder]]];
        _rightWidgetPanelOrder = [OACommonListOfStringList withKey:rightWidgetPanelOrderKey defValue:@[[[OAWidgetsPanel rightPanel] getOriginalOrder]]];
        _topWidgetPanelOrder = [OACommonListOfStringList withKey:topWidgetPanelOrderKey defValue:@[[[OAWidgetsPanel topPanel] getOriginalOrder]]];
        _bottomWidgetPanelOrder = [OACommonListOfStringList withKey:bottomWidgetPanelOrderKey defValue:@[[[OAWidgetsPanel bottomPanel] getOriginalOrder]]];

        _topWidgetPanelOrderOld = [OACommonListOfStringList withKey:topWidgetPanelOrderOldKey defValue:@[[[OAWidgetsPanel topPanel] getOriginalOrder]]];
        _bottomWidgetPanelOrderOld = [OACommonListOfStringList withKey:bottomWidgetPanelOrderKeyOld defValue:@[[[OAWidgetsPanel bottomPanel] getOriginalOrder]]];
        
        [_profilePreferences setObject:_leftWidgetPanelOrder forKey:_leftWidgetPanelOrder.key];
        [_profilePreferences setObject:_rightWidgetPanelOrder forKey:_rightWidgetPanelOrder.key];
        [_profilePreferences setObject:_topWidgetPanelOrder forKey:_topWidgetPanelOrder.key];
        [_profilePreferences setObject:_bottomWidgetPanelOrder forKey:_bottomWidgetPanelOrder.key];

        [_profilePreferences setObject:_topWidgetPanelOrderOld forKey:_topWidgetPanelOrderOld.key];
        [_profilePreferences setObject:_bottomWidgetPanelOrderOld forKey:_bottomWidgetPanelOrderOld.key];

        // Map Settings
        _mapSettingShowFavorites = [OACommonBoolean withKey:mapSettingShowFavoritesKey defValue:YES];
        _mapSettingShowPoiLabel = [OACommonBoolean withKey:mapSettingShowPoiLabelKey defValue:NO];
        _mapSettingShowBordersOfDownloadedMaps = [OACommonBoolean withKey:mapSettingShowBordersOfDownloadedMapsKey defValue:YES];
        _mapSettingShowOfflineEdits = [OACommonBoolean withKey:mapSettingShowOfflineEditsKey defValue:YES];
        _mapSettingShowOnlineNotes = [OACommonBoolean withKey:mapSettingShowOnlineNotesKey defValue:NO];
        _layerTransparencySeekbarMode = [OACommonInteger withKey:layerTransparencySeekbarModeKey defValue:LAYER_TRANSPARENCY_SEEKBAR_MODE_UNDEFINED];

        [_profilePreferences setObject:_mapSettingShowFavorites forKey:@"show_favorites"];
        [_profilePreferences setObject:_mapSettingShowPoiLabel forKey:@"show_poi_label"];
        [_profilePreferences setObject:_mapSettingShowBordersOfDownloadedMaps forKey:@"show_downloaded_borders"];
        [_profilePreferences setObject:_mapSettingShowOfflineEdits forKey:@"show_osm_edits"];
        [_profilePreferences setObject:_mapSettingShowOnlineNotes forKey:@"show_osm_bugs"];
        [_profilePreferences setObject:_layerTransparencySeekbarMode forKey:@"layer_transparency_seekbar_mode"];

        _mapSettingVisibleGpx = [[[OACommonStringList withKey:mapSettingVisibleGpxKey defValue:@[]] makeGlobal] makeShared];
        [_globalPreferences setObject:_mapSettingVisibleGpx forKey:@"selected_gpx"];
        
        _lastStartLat = [[OACommonDouble withKey:lastStartLatkey defValue:0] makeGlobal];
        _lastStartLon = [[OACommonDouble withKey:lastStartLonkey defValue:0] makeGlobal];
        [_globalPreferences setObject:_lastStartLat forKey:lastStartLatkey];
        [_globalPreferences setObject:_lastStartLon forKey:lastStartLonkey];

        _mapSettingTrackRecording = [[NSUserDefaults standardUserDefaults] objectForKey:mapSettingTrackRecordingKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:mapSettingTrackRecordingKey] : NO;

        _mapSettingSaveGlobalTrackToGpx = [[OACommonBoolean withKey:mapSettingSaveGlobalTrackToGpxKey defValue:NO] makeGlobal];
        _mapSettingSaveTrackIntervalGlobal = [OACommonInteger withKey:mapSettingSaveTrackIntervalGlobalKey defValue:SAVE_TRACK_INTERVAL_DEFAULT];
        _mapSettingSaveTrackIntervalApproved = [OACommonBoolean withKey:mapSettingSaveTrackIntervalApprovedKey defValue:NO];
        // TODO: redesign alert as in android to show/hide recorded trip on map
        _mapSettingShowRecordingTrack = [[[OACommonBoolean withKey:mapSettingShowRecordingTrackKey defValue:YES] makeGlobal] makeShared];
        _mapSettingShowTripRecordingStartDialog = [[[OACommonBoolean withKey:mapSettingShowTripRecordingStartDialogKey defValue:YES] makeGlobal] makeShared];
        _saveHeadingToGpx = [OACommonBoolean withKey:saveHeadingToGpxKey defValue:NO];

        [_globalPreferences setObject:_mapSettingSaveGlobalTrackToGpx forKey:@"save_global_track_to_gpx"];
        [_profilePreferences setObject:_mapSettingSaveTrackIntervalGlobal forKey:@"save_global_track_interval"];
        [_profilePreferences setObject:_mapSettingSaveTrackIntervalApproved forKey:@"save_global_track_remember"];
        [_globalPreferences setObject:_mapSettingShowRecordingTrack forKey:@"show_saved_track_remember"];
        [_globalPreferences setObject:_mapSettingShowTripRecordingStartDialog forKey:@"show_trip_recording_start_dialog"];
        [_globalPreferences setObject:_saveHeadingToGpx forKey:@"save_heading_to_gpx"];

        _selectedPoiFilters = [OACommonString withKey:selectedPoiFiltersKey defValue:@""];
        [_profilePreferences setObject:_selectedPoiFilters forKey:@"selected_poi_filter_for_map"];

        _plugins = [[[OACommonStringList withKey:pluginsKey defValue:@[]] makeGlobal] makeShared];
        [_globalPreferences setObject:_plugins forKey:@"enabled_plugins"];

        _discountId = [[OACommonInteger withKey:discountIdKey defValue:0] makeGlobal];
        _discountShowNumberOfStarts = [[OACommonInteger withKey:discountShowNumberOfStartsKey defValue:0] makeGlobal];
        _discountTotalShow = [[OACommonInteger withKey:discountTotalShowKey defValue:0] makeGlobal];
        _discountShowDatetime = [[OACommonDouble withKey:discountShowDatetimeKey defValue:0] makeGlobal];

        [_globalPreferences setObject:_discountId forKey:@"discount_id"];
        [_globalPreferences setObject:_discountShowNumberOfStarts forKey:@"number_of_starts_on_discount_show"];
        [_globalPreferences setObject:_discountTotalShow forKey:@"discount_total_show"];
        [_globalPreferences setObject:_discountShowDatetime forKey:@"show_discount_datetime_ms"];

        _lastSearchedCity = [[NSUserDefaults standardUserDefaults] objectForKey:lastSearchedCityKey] ? ((NSNumber *)[[NSUserDefaults standardUserDefaults] objectForKey:lastSearchedCityKey]).unsignedLongLongValue : 0;
        _lastSearchedCityName = [[NSUserDefaults standardUserDefaults] objectForKey:lastSearchedCityNameKey];

        double lastSearchedPointLat = [[NSUserDefaults standardUserDefaults] objectForKey:lastSearchedPointLatKey] ? [[NSUserDefaults standardUserDefaults] doubleForKey:lastSearchedPointLatKey] : 0.0;
        double lastSearchedPointLon = [[NSUserDefaults standardUserDefaults] objectForKey:lastSearchedPointLonKey] ? [[NSUserDefaults standardUserDefaults] doubleForKey:lastSearchedPointLonKey] : 0.0;
        if (lastSearchedPointLat != 0.0 && lastSearchedPointLon != 0.0)
        {
            _lastSearchedPoint = [[CLLocation alloc] initWithLatitude:lastSearchedPointLat longitude:lastSearchedPointLon];
        }

        // profile setting
        _appModeBeanPrefsIds = [[NSUserDefaults standardUserDefaults] objectForKey:appModeBeanPrefsIdsKey] ? [[NSUserDefaults standardUserDefaults] objectForKey:appModeBeanPrefsIdsKey] :
        @[
            @"app_mode_icon_color",
            @"custom_icon_color",
            @"user_profile_name",
            @"parent_app_mode",
            @"routing_profile",
            @"route_service",
            @"navigation_icon",
            @"location_icon",
            @"app_mode_order",
            @"app_mode_icon_res_name"
        ];

        _defaultApplicationMode = [[[OACommonAppMode withKey:defaultApplicationModeKey defValue:OAApplicationMode.DEFAULT] makeGlobal] makeShared];
        [_globalPreferences setObject:_defaultApplicationMode forKey:@"default_application_mode_string"];
        
        _carPlayMode = [[[OACommonAppMode withKey:defaultCarplayModeKey defValue:OAApplicationMode.CAR] makeGlobal] makeShared];
        [_globalPreferences setObject:_carPlayMode forKey:@"default_carplay_mode_string"];
        
        _isCarPlayModeDefault = [[[OACommonBoolean withKey:carPlayModeIsDefaultKey defValue:YES] makeGlobal] makeShared];
        [_globalPreferences setObject:_carPlayMode forKey:@"carplay_mode_is_default_string"];

        _availableApplicationModes = [[[OACommonString withKey:availableApplicationModesKey defValue:@"car,bicycle,pedestrian,public_transport,"] makeGlobal] makeShared];
        [_globalPreferences setObject:_availableApplicationModes forKey:@"available_application_modes"];

        _customAppModes = [[OACommonString withKey:customAppModesKey defValue:@""] makeGlobal];
        [_globalPreferences setObject:_customAppModes forKey:@"custom_app_modes_keys"];

        _mapInfoControls = [OACommonString withKey:mapInfoControlsKey defValue:@""];
        [_profilePreferences setObject:_mapInfoControls forKey:@"map_info_controls"];
        
        _derivedProfile = [OACommonString withKey:derivedProfileKey defValue:@"default"];
        [_derivedProfile setModeDefaultValue:@"motorcycle" mode:OAApplicationMode.MOTORCYCLE];
        [_derivedProfile setModeDefaultValue:@"truck" mode:OAApplicationMode.TRUCK];
        [_profilePreferences setObject:_derivedProfile forKey:@"derived_profile"];
        
        _routingProfile = [OACommonString withKey:routingProfileKey defValue:@""];
        [_routingProfile setModeDefaultValue:@"car" mode:OAApplicationMode.CAR];
        [_routingProfile setModeDefaultValue:@"bicycle" mode:OAApplicationMode.BICYCLE];
        [_routingProfile setModeDefaultValue:@"pedestrian" mode:OAApplicationMode.PEDESTRIAN];
        [_routingProfile setModeDefaultValue:@"public_transport" mode:OAApplicationMode.PUBLIC_TRANSPORT];
        [_routingProfile setModeDefaultValue:@"train" mode:OAApplicationMode.TRAIN];
        [_routingProfile setModeDefaultValue:@"boat" mode:OAApplicationMode.BOAT];
        [_routingProfile setModeDefaultValue:@"STRAIGHT_LINE_MODE" mode:OAApplicationMode.AIRCRAFT];
        [_routingProfile setModeDefaultValue:@"ski" mode:OAApplicationMode.SKI];
        [_routingProfile setModeDefaultValue:@"horsebackriding" mode:OAApplicationMode.HORSE];
        [_routingProfile setModeDefaultValue:@"moped" mode:OAApplicationMode.MOPED];
        [_profilePreferences setObject:_routingProfile forKey:@"routing_profile"];

        _profileIconName = [OACommonString withKey:profileIconNameKey defValue:@"ic_world_globe_dark"];
        [_profileIconName setModeDefaultValue:@"ic_world_globe_dark" mode:OAApplicationMode.DEFAULT];
        [_profileIconName setModeDefaultValue:@"ic_action_car_dark" mode:OAApplicationMode.CAR];
        [_profileIconName setModeDefaultValue:@"ic_action_bicycle_dark" mode:OAApplicationMode.BICYCLE];
        [_profileIconName setModeDefaultValue:@"ic_action_pedestrian_dark" mode:OAApplicationMode.PEDESTRIAN];
        [_profileIconName setModeDefaultValue:@"ic_action_bus_dark" mode:OAApplicationMode.PUBLIC_TRANSPORT];
        [_profileIconName setModeDefaultValue:@"ic_action_train" mode:OAApplicationMode.TRAIN];
        [_profileIconName setModeDefaultValue:@"ic_action_sail_boat_dark" mode:OAApplicationMode.BOAT];
        [_profileIconName setModeDefaultValue:@"ic_action_aircraft" mode:OAApplicationMode.AIRCRAFT];
        [_profileIconName setModeDefaultValue:@"ic_action_skiing" mode:OAApplicationMode.SKI];
        [_profileIconName setModeDefaultValue:@"ic_action_truck" mode:OAApplicationMode.TRUCK];
        [_profileIconName setModeDefaultValue:@"ic_action_motorcycle_dark" mode:OAApplicationMode.MOTORCYCLE];
        [_profileIconName setModeDefaultValue:@"ic_action_motor_scooter" mode:OAApplicationMode.MOPED];
        [_profileIconName setModeDefaultValue:@"ic_action_horse" mode:OAApplicationMode.HORSE];
        
        _profileIconColor = [OACommonInteger withKey:profileIconColorKey defValue:profile_icon_color_blue_dark_default];
        _profileCustomIconColor = [OACommonInteger withKey:profileCustomIconColorKey defValue:-1];
        _userProfileName = [OACommonString withKey:userProfileNameKey defValue:@""];
        _parentAppMode = [OACommonString withKey:parentAppModeKey defValue:nil];

        _routerService = [OACommonInteger withKey:routerServiceKey defValue:0]; // OSMAND

        // 2 = STRAIGHT
        [_routerService setModeDefaultValue:@2 mode:OAApplicationMode.AIRCRAFT];
        [_routerService setModeDefaultValue:@2 mode:OAApplicationMode.DEFAULT];
        [_routerService set:2 mode:OAApplicationMode.DEFAULT];

        [_profilePreferences setObject:_routerService forKey:@"route_service"];
        _navigationIcon = [OACommonString withKey:navigationIconKey defValue:[[OALocationIcon MOVEMENT_DEFAULT] name]];
        [_navigationIcon setModeDefaultValue:[[OALocationIcon MOVEMENT_NAUTICAL] name] mode:OAApplicationMode.BOAT];
        [_profilePreferences setObject:_navigationIcon forKey:@"navigation_icon"];

        _locationIcon = [OACommonString withKey:locationIconKey defValue:[[OALocationIcon DEFAULT] name]];
        [_locationIcon setModeDefaultValue:[[OALocationIcon CAR] name] mode:OAApplicationMode.CAR];
        [_locationIcon setModeDefaultValue:[[OALocationIcon BICYCLE] name] mode:OAApplicationMode.BICYCLE];
        [_locationIcon setModeDefaultValue:[[OALocationIcon DEFAULT] name] mode:OAApplicationMode.BOAT];
        [_locationIcon setModeDefaultValue:[[OALocationIcon CAR] name] mode:OAApplicationMode.AIRCRAFT];
        [_locationIcon setModeDefaultValue:[[OALocationIcon BICYCLE] name] mode:OAApplicationMode.SKI];
        [_locationIcon setModeDefaultValue:[[OALocationIcon BICYCLE] name] mode:OAApplicationMode.HORSE];
        [_profilePreferences setObject:_locationIcon forKey:@"location_icon"];

        _appModeOrder = [OACommonInteger withKey:appModeOrderKey defValue:0];
        [_profilePreferences setObject:_appModeOrder forKey:@"app_mode_order"];

        _defaultSpeed = [OACommonDouble withKey:defaultSpeedKey defValue:10.];
        [_defaultSpeed setModeDefaultValue:@1.5 mode:OAApplicationMode.DEFAULT];
        [_defaultSpeed setModeDefaultValue:@12.5 mode:OAApplicationMode.CAR];
        [_defaultSpeed setModeDefaultValue:@2.77 mode:OAApplicationMode.BICYCLE];
        [_defaultSpeed setModeDefaultValue:@1.11 mode:OAApplicationMode.PEDESTRIAN];
        [_defaultSpeed setModeDefaultValue:@1.38 mode:OAApplicationMode.BOAT];
        [_defaultSpeed setModeDefaultValue:@200.0 mode:OAApplicationMode.AIRCRAFT];
        [_defaultSpeed setModeDefaultValue:@1.38 mode:OAApplicationMode.SKI];
        [_defaultSpeed setModeDefaultValue:@1.66 mode:OAApplicationMode.HORSE];
        [_profilePreferences setObject:_defaultSpeed forKey:@"default_speed"];

        _minSpeed = [OACommonDouble withKey:minSpeedKey defValue:0.];
        _maxSpeed = [OACommonDouble withKey:maxSpeedKey defValue:0.];
        _routeStraightAngle = [OACommonDouble withKey:routeStraightAngleKey defValue:30.];
        [_profilePreferences setObject:_minSpeed forKey:@"min_speed"];
        [_profilePreferences setObject:_maxSpeed forKey:@"max_speed"];
        [_profilePreferences setObject:_routeStraightAngle forKey:@"routing_straight_angle"];

        _transparentMapTheme = [OACommonBoolean withKey:transparentMapThemeKey defValue:NO];
        [_profilePreferences setObject:_transparentMapTheme forKey:@"transparent_map_theme"];

        _showStreetName = [OACommonBoolean withKey:showStreetNameKey defValue:NO];
        [_showStreetName setModeDefaultValue:@NO mode:[OAApplicationMode DEFAULT]];
        [_showStreetName setModeDefaultValue:@YES mode:[OAApplicationMode CAR]];
        [_showStreetName setModeDefaultValue:@NO mode:[OAApplicationMode BICYCLE]];
        [_showStreetName setModeDefaultValue:@NO mode:[OAApplicationMode PEDESTRIAN]];
        [_profilePreferences setObject:_showStreetName forKey:@"show_street_name"];

        _showDistanceRuler = [OACommonBoolean withKey:showDistanceRulerKey defValue:NO];
        [_profilePreferences setObject:_showDistanceRuler forKey:@"show_distance_ruler"];
        
        _showElevationProfileWidget = [OACommonBoolean withKey:showElevationProfileWidgetKey defValue:NO];
        [_profilePreferences setObject:_showDistanceRuler forKey:showElevationProfileWidgetKey];
        _showSlopesOnElevationWidget = [OACommonBoolean withKey:showSlopesOnElevationWidget defValue:NO];
        [_profilePreferences setObject:_showDistanceRuler forKey:showSlopesOnElevationWidget];
        
        _customWidgetKeys = [OACommonStringList withKey:customWidgetKeys defValue:@[]];
        [_profilePreferences setObject:_customWidgetKeys forKey:customWidgetKeys];

        _showArrivalTime = [OACommonBoolean withKey:showArrivalTimeKey defValue:YES];
        _showIntermediateArrivalTime = [OACommonBoolean withKey:showIntermediateArrivalTimeKey defValue:YES];
        _showRelativeBearing = [OACommonBoolean withKey:showRelativeBearingKey defValue:YES];
        _showCompassControlRuler = [[[OACommonBoolean withKey:showCompassControlRulerKey defValue:YES] makeGlobal] makeShared];

        [_profilePreferences setObject:_showArrivalTime forKey:@"show_arrival_time"];
        [_profilePreferences setObject:_showIntermediateArrivalTime forKey:@"show_intermediate_arrival_time"];
        [_profilePreferences setObject:_showRelativeBearing forKey:@"show_relative_bearing"];
        [_globalPreferences setObject:_showCompassControlRuler forKey:@"show_compass_ruler"];

        _positionPlacementOnMap = [OACommonInteger withKey:positionPlacementOnMapKey defValue:EOAPositionPlacementAuto];
        [_profilePreferences setObject:_positionPlacementOnMap forKey:@"position_placement_on_map"];

        _rotateMap = [OACommonInteger withKey:rotateMapKey defValue:ROTATE_MAP_NONE];
        [_rotateMap setModeDefaultValue:@(ROTATE_MAP_BEARING) mode:[OAApplicationMode CAR]];
        [_rotateMap setModeDefaultValue:@(ROTATE_MAP_BEARING) mode:[OAApplicationMode BICYCLE]];
        [_rotateMap setModeDefaultValue:@(ROTATE_MAP_BEARING) mode:[OAApplicationMode PEDESTRIAN]];
        [_profilePreferences setObject:_rotateMap forKey:@"rotate_map"];

        _mapDensity = [OACommonDouble withKey:mapDensityKey defValue:MAGNIFIER_DEFAULT_VALUE];
        [_mapDensity setModeDefaultValue:@(MAGNIFIER_DEFAULT_CAR) mode:[OAApplicationMode CAR]];
        [_mapDensity setModeDefaultValue:@(MAGNIFIER_DEFAULT_VALUE) mode:[OAApplicationMode BICYCLE]];
        [_mapDensity setModeDefaultValue:@(MAGNIFIER_DEFAULT_VALUE) mode:[OAApplicationMode PEDESTRIAN]];
        [_profilePreferences setObject:_mapDensity forKey:@"map_density_n"];

        _textSize = [OACommonDouble withKey:textSizeKey defValue:MAGNIFIER_DEFAULT_VALUE];
        [_textSize setModeDefaultValue:@(MAGNIFIER_DEFAULT_CAR_TEXT) mode:[OAApplicationMode CAR]];
        [_textSize setModeDefaultValue:@(MAGNIFIER_DEFAULT_VALUE) mode:[OAApplicationMode BICYCLE]];
        [_textSize setModeDefaultValue:@(MAGNIFIER_DEFAULT_VALUE) mode:[OAApplicationMode PEDESTRIAN]];
        [_profilePreferences setObject:_textSize forKey:@"text_scale"];

        _renderer = [OACommonString withKey:rendererKey defValue:@"OsmAnd"];
        [_profilePreferences setObject:_renderer forKey:@"renderer"];

        _firstMapIsDownloaded = [[NSUserDefaults standardUserDefaults] objectForKey:firstMapIsDownloadedKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:firstMapIsDownloadedKey] : NO;

        // trip recording settings
        _saveTrackToGPX = [OACommonBoolean withKey:saveTrackToGPXKey defValue:NO];
        [_profilePreferences setObject:_saveTrackToGPX forKey:@"save_track_to_gpx"];

        _mapSettingSaveTrackInterval = [OACommonInteger withKey:mapSettingSaveTrackIntervalKey defValue:SAVE_TRACK_INTERVAL_DEFAULT];
        [_mapSettingSaveTrackInterval setModeDefaultValue:@3 mode:[OAApplicationMode CAR]];
        [_mapSettingSaveTrackInterval setModeDefaultValue:@5 mode:[OAApplicationMode BICYCLE]];
        [_mapSettingSaveTrackInterval setModeDefaultValue:@10 mode:[OAApplicationMode PEDESTRIAN]];
        [_profilePreferences setObject:_mapSettingSaveTrackInterval forKey:@"save_track_interval"];

        _saveTrackMinDistance = [OACommonDouble withKey:saveTrackMinDistanceKey defValue:REC_FILTER_DEFAULT];
        _saveTrackPrecision = [OACommonDouble withKey:saveTrackPrecisionKey defValue:REC_TRACK_PRECISION_DEFAULT];
        _saveTrackMinSpeed = [OACommonDouble withKey:saveTrackMinSpeedKey defValue:REC_FILTER_DEFAULT];
        _autoSplitRecording = [OACommonBoolean withKey:autoSplitRecordingKey defValue:YES];

        [_profilePreferences setObject:_saveTrackMinDistance forKey:@"save_track_min_distance"];
        [_profilePreferences setObject:_saveTrackPrecision forKey:@"save_track_precision"];
        [_profilePreferences setObject:_saveTrackMinSpeed forKey:@"save_track_min_speed"];
        [_profilePreferences setObject:_autoSplitRecording forKey:@"auto_split_recording"];

        // navigation settings
        _useFastRecalculation = [[NSUserDefaults standardUserDefaults] objectForKey:useFastRecalculationKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:useFastRecalculationKey] : YES;
        _forcePrivateAccessRoutingAsked = [OACommonBoolean withKey:forcePrivateAccessRoutingAskedKey defValue:NO];
        [_profilePreferences setObject:_forcePrivateAccessRoutingAsked forKey:@"force_private_access_routing"];
        _fastRouteMode = [OACommonBoolean withKey:fastRouteModeKey defValue:YES];
        [_profilePreferences setObject:_fastRouteMode forKey:@"fast_route_mode"];
        _disableComplexRouting = [[NSUserDefaults standardUserDefaults] objectForKey:disableComplexRoutingKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:disableComplexRoutingKey] : NO;
        _followTheRoute = [[OACommonBoolean withKey:followTheRouteKey defValue:NO] makeGlobal];
        [_globalPreferences setObject:_followTheRoute forKey:@"follow_to_route"];
        _followTheGpxRoute = [[OACommonString withKey:followTheGpxRouteKey defValue:nil] makeGlobal];
        [_globalPreferences setObject:_followTheGpxRoute forKey:@"follow_gpx"];
        _arrivalDistanceFactor = [OACommonDouble withKey:arrivalDistanceFactorKey defValue:1.0];
        [_profilePreferences setObject:_arrivalDistanceFactor forKey:@"arrival_distance_factor"];
        _enableTimeConditionalRouting = [OACommonBoolean withKey:enableTimeConditionalRoutingKey defValue:YES];
        [_profilePreferences setObject:_enableTimeConditionalRouting forKey:@"enable_time_conditional_routing"];
        _useIntermediatePointsNavigation = [[OACommonBoolean withKey:useIntermediatePointsNavigationKey defValue:NO] makeGlobal];
        [_globalPreferences setObject:_useIntermediatePointsNavigation forKey:@"use_intermediate_points_navigation"];

        _disableOffrouteRecalc = [OACommonBoolean withKey:disableOffrouteRecalcKey defValue:NO];
        _disableWrongDirectionRecalc = [OACommonBoolean withKey:disableWrongDirectionRecalcKey defValue:NO];
        _hazmatTransportingEnabled = [OACommonBoolean withKey:hazmatTransportingEnabledKey defValue:NO];

        [_profilePreferences setObject:_disableOffrouteRecalc forKey:@"disable_offroute_recalc"];
        [_profilePreferences setObject:_disableWrongDirectionRecalc forKey:@"disable_wrong_direction_recalc"];
        [_profilePreferences setObject:_hazmatTransportingEnabled forKey:@"hazmat_transporting_enabled"];

        _autoFollowRoute = [OACommonInteger withKey:autoFollowRouteKey defValue:0];
        [_autoFollowRoute setModeDefaultValue:@15 mode:[OAApplicationMode CAR]];
        [_autoFollowRoute setModeDefaultValue:@15 mode:[OAApplicationMode BICYCLE]];
        [_autoFollowRoute setModeDefaultValue:@0 mode:[OAApplicationMode PEDESTRIAN]];
        [_profilePreferences setObject:_autoFollowRoute forKey:@"auto_follow_route"];

        _autoZoomMap = [OACommonBoolean withKey:autoZoomMapKey defValue:NO];
        [_autoZoomMap setModeDefaultValue:@YES mode:[OAApplicationMode CAR]];
        [_autoZoomMap setModeDefaultValue:@NO mode:[OAApplicationMode BICYCLE]];
        [_autoZoomMap setModeDefaultValue:@NO mode:[OAApplicationMode PEDESTRIAN]];
        [_profilePreferences setObject:_autoZoomMap forKey:@"auto_zoom_map_on_off"];
        
        _useV1AutoZoom = [OACommonBoolean withKey:useV1AutoZoomKey defValue:NO];
        [_profilePreferences setObject:_useV1AutoZoom forKey:@"use_v1_auto_zoom"];

        _autoZoomMapScale = [OACommonAutoZoomMap withKey:autoZoomMapScaleKey defValue:AUTO_ZOOM_MAP_FAR];
        [_autoZoomMapScale setModeDefaultValue:@(AUTO_ZOOM_MAP_FAR) mode:[OAApplicationMode CAR]];
        [_autoZoomMapScale setModeDefaultValue:@(AUTO_ZOOM_MAP_CLOSE) mode:[OAApplicationMode BICYCLE]];
        [_autoZoomMapScale setModeDefaultValue:@(AUTO_ZOOM_MAP_CLOSE) mode:[OAApplicationMode PEDESTRIAN]];
        [_profilePreferences setObject:_autoZoomMapScale forKey:@"auto_zoom_map_scale"];

        _keepInforming = [OACommonInteger withKey:keepInformingKey defValue:0];
        [_keepInforming setModeDefaultValue:@0 mode:[OAApplicationMode CAR]];
        [_keepInforming setModeDefaultValue:@0 mode:[OAApplicationMode BICYCLE]];
        [_keepInforming setModeDefaultValue:@0 mode:[OAApplicationMode PEDESTRIAN]];
        [_profilePreferences setObject:_keepInforming forKey:@"keep_informing"];

        _drivingRegionAutomatic = [OACommonBoolean withKey:drivingRegionAutomaticKey defValue:YES];
        _drivingRegion = [OACommonDrivingRegion withKey:drivingRegionKey defValue:[OADrivingRegion getDefaultRegion]];
        _metricSystem = [OACommonMetricSystem withKey:metricSystemKey defValue:KILOMETERS_AND_METERS];
        _metricSystemChangedManually = [OACommonBoolean withKey:metricSystemChangedManuallyKey defValue:NO];
        _settingGeoFormat = [OACommonInteger withKey:settingGeoFormatKey defValue:MAP_GEO_FORMAT_DEGREES];
        _settingExternalInputDevice = [OACommonInteger withKey:settingExternalInputDeviceKey defValue:GENERIC_EXTERNAL_DEVICE];

        [_profilePreferences setObject:_drivingRegionAutomatic forKey:@"shared_string_automatic"];
        [_profilePreferences setObject:_drivingRegion forKey:@"default_driving_region"];
        [_profilePreferences setObject:_metricSystem forKey:@"default_metric_system"];
        [_profilePreferences setObject:_metricSystemChangedManually forKey:@"metric_system_changed_manually"];
        [_profilePreferences setObject:_settingGeoFormat forKey:@"coordinates_format"];
        [_profilePreferences setObject:_settingExternalInputDevice forKey:@"external_input_device"];

        _speedSystem = [OACommonSpeedConstant withKey:speedSystemKey defValue:KILOMETERS_PER_HOUR];
        _angularUnits = [OACommonAngularConstant withKey:angularUnitsKey defValue:DEGREES];
        _speedLimitExceedKmh = [OACommonDouble withKey:speedLimitExceedKey defValue:5.f];

        [_profilePreferences setObject:_speedLimitExceedKmh forKey:@"speed_limit_exceed"];
        [_profilePreferences setObject:_angularUnits forKey:@"angular_measurement"];
        [_profilePreferences setObject:_speedSystem forKey:@"default_speed_system"];
        
        _preciseDistanceNumbers = [OACommonBoolean withKey:preciseDistanceNumbersKey defValue:YES];
        [_preciseDistanceNumbers setModeDefaultValue:@NO mode:[OAApplicationMode CAR]];
        [_profilePreferences setObject:_preciseDistanceNumbers forKey:@"precise_distance_numbers"];

        _routeRecalculationDistance = [OACommonDouble withKey:routeRecalculationDistanceKey defValue:0.];
        [_profilePreferences setObject:_routeRecalculationDistance forKey:@"routing_recalc_distance"];

        _customRouteColorDay = [OACommonInteger withKey:customRouteColorDayKey defValue:[UIColorFromARGB(kDefaultRouteLineDayColor) toARGBNumber]];
        [_profilePreferences setObject:_customRouteColorDay forKey:@"route_line_color"];

        _customRouteColorNight = [OACommonInteger withKey:customRouteColorNightKey defValue:[UIColorFromARGB(kDefaultRouteLineNightColor) toARGBNumber]];
        [_profilePreferences setObject:_customRouteColorNight forKey:@"route_line_color_night"];

        _routeColoringType = [OACommonColoringType withKey:routeColoringTypeKey defValue:OAColoringType.DEFAULT values:[OAColoringType getRouteColoringTypes]];
        [_profilePreferences setObject:_routeColoringType forKey:@"route_line_coloring_type"];

        _routeGradientPalette = [OACommonString withKey:routeGradientPaletteKey defValue:@"default"];
        [_profilePreferences setObject:_routeGradientPalette forKey:routeGradientPaletteKey];

        _routeInfoAttribute = [OACommonString withKey:routeInfoAttributeKey defValue:nil];
        [_profilePreferences setObject:_routeInfoAttribute forKey:@"route_info_attribute"];

        _routeLineWidth = [OACommonString withKey:routeLineWidthKey defValue:nil];
        [_profilePreferences setObject:_routeLineWidth forKey:@"route_line_width"];

        _routeShowTurnArrows = [OACommonBoolean withKey:routeShowTurnArrowsKey defValue:YES];
        [_profilePreferences setObject:_routeShowTurnArrows forKey:@"route_show_turn_arrows"];

        _showTrafficWarnings = [OACommonBoolean withKey:showTrafficWarningsKey defValue:NO];
        [_showTrafficWarnings setModeDefaultValue:@YES mode:[OAApplicationMode CAR]];
        [_profilePreferences setObject:_showTrafficWarnings forKey:@"show_traffic_warnings"];

        _showPedestrian = [OACommonBoolean withKey:showPedestrianKey defValue:NO];
        [_showPedestrian setModeDefaultValue:@YES mode:[OAApplicationMode CAR]];
        [_profilePreferences setObject:_showPedestrian forKey:@"show_pedestrian"];

        _showSpeedLimitWarnings = [OACommonBoolean withKey:showSpeedLimitWarningsKey defValue:NO];
        [_profilePreferences setObject:_showSpeedLimitWarnings forKey:@"show_speed_limit_warnings"];

        _showCameras = [OACommonBoolean withKey:showCamerasKey defValue:NO];
        [_profilePreferences setObject:_showCameras forKey:@"show_cameras"];
        _showTunnels = [OACommonBoolean withKey:showTunnelsKey defValue:NO];
        [_showTunnels setModeDefaultValue:@YES mode:[OAApplicationMode CAR]];
        [_profilePreferences setObject:_showTunnels forKey:@"show_tunnels"];

        _showLanes = [OACommonBoolean withKey:showLanesKey defValue:NO];
        [_showLanes setModeDefaultValue:@YES mode:[OAApplicationMode CAR]];
        [_showLanes setModeDefaultValue:@YES mode:[OAApplicationMode BICYCLE]];
        [_profilePreferences setObject:_showLanes forKey:@"show_lanes"];

        _speakStreetNames = [OACommonBoolean withKey:speakStreetNamesKey defValue:YES];
        _speakTrafficWarnings = [OACommonBoolean withKey:speakTrafficWarningsKey defValue:YES];
        _speakPedestrian = [OACommonBoolean withKey:speakPedestrianKey defValue:NO];
        [_speakPedestrian setModeDefaultValue:@YES mode:[OAApplicationMode CAR]];
        _speakSpeedLimit = [OACommonBoolean withKey:speakSpeedLimitKey defValue:YES];
        _speakTunnels = [OACommonBoolean withKey:speakTunnels defValue:NO];
        _speakCameras = [OACommonBoolean withKey:speakCamerasKey defValue:NO];
        _speakExitNumberNames = [OACommonBoolean withKey:speakExitNumberNamesKey defValue:YES];
        _speakGpsSignalStatus = [OACommonBoolean withKey:speakGpsSignalStatusKey defValue:YES];
        _speakRouteRecalculation = [OACommonBoolean withKey:speakRouteRecalculationKey defValue:YES];
        _speakRouteDeviation = [OACommonBoolean withKey:speakRouteDeviationKey defValue:YES];
        _announceNearbyFavorites = [OACommonBoolean withKey:announceNearbyFavoritesKey defValue:NO];
        _announceNearbyPoi = [OACommonBoolean withKey:announceNearbyPoiKey defValue:NO];

        [_profilePreferences setObject:_speakStreetNames forKey:@"speak_street_names"];
        [_profilePreferences setObject:_speakTrafficWarnings forKey:@"speak_traffic_warnings"];
        [_profilePreferences setObject:_speakPedestrian forKey:@"speak_pedestrian"];
        [_profilePreferences setObject:_speakSpeedLimit forKey:@"speak_speed_limit"];
        [_profilePreferences setObject:_speakCameras forKey:@"speak_cameras"];
        [_profilePreferences setObject:_speakTunnels forKey:@"show_tunnels"];
        [_profilePreferences setObject:_speakExitNumberNames forKey:@"exit_number_names"];
        [_profilePreferences setObject:_speakGpsSignalStatus forKey:@"speak_gps_signal_status"];
        [_profilePreferences setObject:_speakRouteRecalculation forKey:@"speak_route_recalculation"];
        [_profilePreferences setObject:_speakRouteDeviation forKey:@"speak_route_deviation"];
        [_profilePreferences setObject:_announceNearbyFavorites forKey:@"announce_nearby_favorites"];
        [_profilePreferences setObject:_announceNearbyPoi forKey:@"announce_nearby_poi"];

        _voiceProvider = [OACommonString withKey:voiceProviderKey defValue:@""];
        _announceWpt = [OACommonBoolean withKey:announceWptKey defValue:YES];
        _showScreenAlerts = [OACommonBoolean withKey:showScreenAlertsKey defValue:YES];

        [_profilePreferences setObject:_voiceProvider forKey:@"voice_provider"];
        [_profilePreferences setObject:_announceWpt forKey:@"announce_wpt"];
        [_profilePreferences setObject:_showScreenAlerts forKey:@"show_routing_alarms"];

        _useOsmLiveForRouting = [[NSUserDefaults standardUserDefaults] objectForKey:useOsmLiveForRoutingKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:useOsmLiveForRoutingKey] : YES;

        _showGpxWpt = [[[OACommonBoolean withKey:showGpxWptKey defValue:YES] makeGlobal] makeShared];
        _showNearbyFavorites = [OACommonBoolean withKey:showNearbyFavoritesKey defValue:NO];
        _showNearbyPoi = [OACommonBoolean withKey:showNearbyPoiKey defValue:NO];
        [_globalPreferences setObject:_showGpxWpt forKey:@"show_gpx_wpt"];
        [_profilePreferences setObject:_showNearbyFavorites forKey:@"show_nearby_favorites"];
        [_profilePreferences setObject:_showNearbyPoi forKey:@"show_nearby_poi"];

        _gpxRouteCalcOsmandParts = [[[OACommonBoolean withKey:gpxRouteCalcOsmandPartsKey defValue:YES] makeGlobal] makeShared];
        _gpxCalculateRtept = [[[OACommonBoolean withKey:gpxCalculateRteptKey defValue:YES] makeGlobal] makeShared];
        _gpxRouteCalc = [[[OACommonBoolean withKey:gpxRouteCalcKey defValue:NO] makeGlobal] makeShared];
        _gpxRouteSegment = [[[OACommonInteger withKey:gpxRouteSegmentKey defValue:-1] makeGlobal] makeShared];
        _showStartFinishIcons = [[[OACommonBoolean withKey:showStartFinishIconsKey defValue:YES] makeGlobal] makeShared];

        [_globalPreferences setObject:_gpxRouteCalcOsmandParts forKey:@"gpx_routing_calculate_osmand_route"];
        [_globalPreferences setObject:_gpxCalculateRtept forKey:@"gpx_routing_calculate_rtept"];
        [_globalPreferences setObject:_gpxRouteCalc forKey:@"calc_gpx_route"];
        [_globalPreferences setObject:_gpxRouteSegment forKey:@"gpx_route_segment"];
        [_globalPreferences setObject:_showStartFinishIcons forKey:@"show_start_finish_icons"];

        _voiceMute = [OACommonBoolean withKey:voiceMuteKey defValue:NO];
        [_profilePreferences setObject:_voiceMute forKey:@"voice_mute"];

        _interruptMusic = [OACommonBoolean withKey:interruptMusicKey defValue:NO];
        [_profilePreferences setObject:_interruptMusic forKey:@"interrupt_music"];
        _snapToRoad = [OACommonBoolean withKey:snapToRoadKey defValue:NO];
        [_snapToRoad setModeDefaultValue:@YES mode:[OAApplicationMode CAR]];
        [_snapToRoad setModeDefaultValue:@YES mode:[OAApplicationMode BICYCLE]];
        [_snapToRoad setModeDefaultValue:@YES mode:[OAApplicationMode PEDESTRIAN]];
        [_profilePreferences setObject:_snapToRoad forKey:@"snap_to_road"];

        _poiFiltersOrder = [OACommonStringList withKey:poiFiltersOrderKey defValue:@[]];
        _inactivePoiFilters = [OACommonStringList withKey:inactivePoiFiltersKey defValue:@[]];
        [_profilePreferences setObject:_poiFiltersOrder forKey:@"poi_filters_order"];
        [_profilePreferences setObject:_inactivePoiFilters forKey:@"inactive_poi_filters"];

        _rulerMode = [[[OACommonRulerWidgetMode withKey:rulerModeKey defValue:RULER_MODE_DARK] makeGlobal] makeShared];
        [_globalPreferences setObject:_rulerMode forKey:@"ruler_mode"];

        _osmUserDisplayName = [[[OACommonString withKey:osmUserDisplayNameKey defValue:@""] makeGlobal] makeShared];
        _osmUploadVisibility = [[[OACommonUploadVisibility withKey:osmUploadVisibilityKey defValue:EOAUploadVisibilityPublic] makeGlobal] makeShared];
        _osmUserAccessToken = [[OACommonString withKey:osmUserAccessTokenKey defValue:@""] makeGlobal];
        _osmUserAccessTokenSecret = [[OACommonString withKey:osmUserAccessTokenSecretKey defValue:@""] makeGlobal];
        _oprAccessToken = [[OACommonString withKey:oprAccessTokenKey defValue:@""] makeGlobal];
        _oprUsername = [[OACommonString withKey:oprUsernameKey defValue:@""] makeGlobal];
        _oprBlockchainName = [[OACommonString withKey:oprBlockchainNameKey defValue:@""] makeGlobal];
        _oprUseDevUrl = [[[OACommonBoolean withKey:oprUseDevUrlKey defValue:NO] makeGlobal] makeShared];
        _offlineEditing = [[[OACommonBoolean withKey:offlineEditingKey defValue:YES] makeGlobal] makeShared];
        _osmUseDevUrl = [[[OACommonBoolean withKey:osmUseDevUrlKey defValue:NO] makeGlobal] makeShared];

        [_globalPreferences setObject:_osmUserDisplayName forKey:@"user_display_name"];
        [_globalPreferences setObject:_osmUploadVisibility forKey:@"upload_visibility"];
        [_globalPreferences setObject:_osmUserAccessToken forKey:@"user_access_token"];
        [_globalPreferences setObject:_osmUserAccessTokenSecret forKey:@"user_access_token_secret"];
        [_globalPreferences setObject:_oprAccessToken forKey:@"opr_user_access_token_secret"];
        [_globalPreferences setObject:_oprUsername forKey:@"opr_username_secret"];
        [_globalPreferences setObject:_oprBlockchainName forKey:@"opr_blockchain_name"];
        [_globalPreferences setObject:_oprUseDevUrl forKey:@"opr_use_dev_url"];
        [_globalPreferences setObject:_offlineEditing forKey:@"offline_osm_editing"];
        [_globalPreferences setObject:_osmUseDevUrl forKey:@"use_dev_url"];

        _showMapillary = [[[OACommonBoolean withKey:showMapillaryKey defValue:YES] makeGlobal] makeShared];
        _mapillaryFirstDialogShown = [[OACommonBoolean withKey:mapillaryFirstDialogShownKey defValue:NO] makeGlobal];
        _onlinePhotosRowCollapsed = [[[OACommonBoolean withKey:onlinePhotosRowCollapsedKey defValue:YES] makeGlobal] makeShared];
        _useMapillaryFilter = [[[OACommonBoolean withKey:useMapillaryFilterKey defValue:NO] makeGlobal] makeShared];
        _mapillaryFilterUserKey = [[[OACommonString withKey:mapillaryFilterUserKeyKey defValue:@""] makeGlobal] makeShared];
        _mapillaryFilterUserName = [[[OACommonString withKey:mapillaryFilterUserNameKey defValue:@""] makeGlobal] makeShared];
        _mapillaryFilterStartDate = [[[OACommonDouble withKey:mapillaryFilterStartDateKey defValue: 0] makeGlobal] makeShared];
        _mapillaryFilterEndDate = [[[OACommonDouble withKey:mapillaryFilterEndDateKey defValue: 0] makeGlobal] makeShared];
        _mapillaryFilterPano = [[[OACommonBoolean withKey:mapillaryFilterPanoKey defValue:NO] makeGlobal] makeShared];

        [_globalPreferences setObject:_showMapillary forKey:@"show_mapillary"];
        [_globalPreferences setObject:_mapillaryFirstDialogShown forKey:@"mapillary_first_dialog_shown"];
        [_globalPreferences setObject:_onlinePhotosRowCollapsed forKey:@"mapillary_menu_collapsed"];
        [_globalPreferences setObject:_useMapillaryFilter forKey:@"use_mapillary_filters"];
        [_globalPreferences setObject:_mapillaryFilterUserKey forKey:@"mapillary_filter_user_key"];
        [_globalPreferences setObject:_mapillaryFilterUserName forKey:@"mapillary_filter_username"];
        [_globalPreferences setObject:_mapillaryFilterStartDate forKey:@"mapillary_filter_from_date"];
        [_globalPreferences setObject:_mapillaryFilterEndDate forKey:@"mapillary_filter_to_date"];
        [_globalPreferences setObject:_mapillaryFilterPano forKey:@"mapillary_filter_pano"];

        _isQuickActionTutorialShown = [[[OACommonBoolean withKey:isQuickActionTutorialShownKey defValue:NO] makeGlobal] makeShared];
        _quickActionButtons = [[[[OACommonStringList withKey:quickActionButtonsKey defValue:@[QuickActionButtonState.defaultButtonId]] makeGlobal] makeShared] storeLastModifiedTime];

        [_globalPreferences setObject:_isQuickActionTutorialShown forKey:@"quick_action_tutorial"];
        [_globalPreferences setObject:_quickActionButtons forKey:quickActionButtonsKey];
        
        _showSpeedometer = [OACommonBoolean withKey:showSpeedometerKey defValue:NO];
        [_showSpeedometer setModeDefaultValue:@YES mode:OAApplicationMode.CAR];
        [_showSpeedometer setModeDefaultValue:@YES mode:OAApplicationMode.TRUCK];
        [_showSpeedometer setModeDefaultValue:@YES mode:OAApplicationMode.MOTORCYCLE];
        [_showSpeedometer setModeDefaultValue:@YES mode:OAApplicationMode.MOPED];
        [_profilePreferences setObject:_showSpeedometer forKey:@"show_speedometer"];
        
        _speedometerSize = [OACommonWidgetSizeStyle withKey:speedometerSizeKey defValue:EOAWidgetSizeStyleMedium];
        [_speedometerSize setModeDefaultValue:@(EOAWidgetSizeStyleSmall) mode:OAApplicationMode.CAR];
        [self registerPreference:_speedometerSize forKey:speedometerSizeKey];
        
        _showSpeedLimitWarning = [OACommonSpeedLimitWarningState withKey:showSpeedLimitWarningKey defValue:EOASpeedLimitWarningStateWhenExceeded];
        [self registerPreference:_showSpeedLimitWarning forKey:showSpeedLimitWarningKey];
        
        _contourLinesZoom = [OACommonString withKey:contourLinesZoomKey defValue:@""];
        [_profilePreferences setObject:_contourLinesZoom forKey:@"contour_lines_zoom"];
        
        _hikingRoutesParameter = [OACommonString withKey:hikingRoutesParameterKey defValue:@"walkingRoutesOSMC"];
        [_profilePreferences setObject:_hikingRoutesParameter forKey:@"hiking_routes_parameter"];
        
        _cycleRoutesParameter = [OACommonString withKey:cycleRoutesParameterKey defValue:@"false"];
        [_profilePreferences setObject:_cycleRoutesParameter forKey:@"cycle_routes_parameter"];
        
        _mountainBikeRoutesParameter = [OACommonString withKey:mountainBikeRoutesParameterKey defValue:@"showMtbScale"];
        [_profilePreferences setObject:_mountainBikeRoutesParameter forKey:@"mountain_bike_routes_parameter"];

        // Custom plugins
        _customPluginsJson = [[NSUserDefaults standardUserDefaults] objectForKey:customPluginsJsonKey] ? [[NSUserDefaults standardUserDefaults] stringForKey:customPluginsJsonKey] : @"";

        // Direction Appearance
        _activeMarkers = [OACommonActiveMarkerConstant withKey:activeMarkerKey defValue:ONE_ACTIVE_MARKER];
        [_profilePreferences setObject:_activeMarkers forKey:@"displayed_markers_widgets_count"];
        _arrowsOnMap = [OACommonBoolean withKey:mapArrowsOnMapKey defValue:NO];
        [_profilePreferences setObject:_arrowsOnMap forKey:@"show_arrows_to_first_markers"];
        _directionLines = [OACommonBoolean withKey:mapDirectionLinesKey defValue:YES];
        [_profilePreferences setObject:_directionLines forKey:@"show_lines_to_first_markers"];

        // global

        _wikiArticleShowImagesAsked = [[OACommonBoolean withKey:wikiArticleShowImagesAskedKey defValue:NO] makeGlobal];
        _wikivoyageShowImgs = [[[OACommonWikiArticleShowImages withKey:wikivoyageShowImgsKey defValue:EOAWikiArticleShowConstantOff] makeGlobal] makeShared];

        [_globalPreferences setObject:_wikiArticleShowImagesAsked forKey:@"wikivoyage_show_images_asked"];
        [_globalPreferences setObject:_wikivoyageShowImgs forKey:@"wikivoyage_show_imgs"];

        _coordsInputUseRightSide = [[[OACommonBoolean withKey:coordsInputUseRightSideKey defValue:YES] makeGlobal] makeShared];
        _coordsInputFormat = [[[OACommonCoordinateInputFormats withKey:coordsInputFormatKey defValue:EOACoordinateInputFormatsDdMmMmm] makeGlobal] makeShared];
        _coordsInputUseOsmandKeyboard = [[[OACommonBoolean withKey:coordsInputUseOsmandKeyboardKey defValue: YES] makeGlobal] makeShared];
        _coordsInputTwoDigitsLongitude = [[[OACommonBoolean withKey:coordsInputTwoDigitsLongitudeKey defValue: NO] makeGlobal] makeShared];

        [_globalPreferences setObject:_coordsInputUseRightSide forKey:@"coords_input_use_right_side"];
        [_globalPreferences setObject:_coordsInputFormat forKey:@"coords_input_format"];
        [_globalPreferences setObject:_coordsInputUseOsmandKeyboard forKey:@"coords_input_use_osmand_keyboard"];
        [_globalPreferences setObject:_coordsInputTwoDigitsLongitude forKey:@"coords_input_two_digits_longitude"];

        _showCardToChooseDrawer = [[[OACommonBoolean withKey:showCardToChooseDrawerKey defValue:NO] makeGlobal] makeShared];
        _shouldShowDashboardOnStart = [[[OACommonBoolean withKey:shouldShowDashboardOnStartKey defValue:NO] makeGlobal] makeShared];
        _showDashboardOnMapScreen = [[[OACommonBoolean withKey:showDashboardOnMapScreenKey defValue:NO] makeGlobal] makeShared];
        _showOsmandWelcomeScreen = [[OACommonBoolean withKey:showOsmandWelcomeScreenKey defValue:YES] makeGlobal];

        [_globalPreferences setObject:_showCardToChooseDrawer forKey:@"show_card_to_choose_drawer"];
        [_globalPreferences setObject:_shouldShowDashboardOnStart forKey:@"should_show_dashboard_on_start"];
        [_globalPreferences setObject:_showDashboardOnMapScreen forKey:@"show_dashboard_on_map_screen"];
        [_globalPreferences setObject:_showOsmandWelcomeScreen forKey:@"show_osmand_welcome_screen"];

        _apiNavDrawerItemsJson = [[[OACommonString withKey:apiNavDrawerItemsJsonKey defValue:@"{}"] makeGlobal] makeShared];
        _apiConnectedAppsJson = [[[OACommonString withKey:apiConnectedAppsJsonKey defValue:@"[]"] makeGlobal] makeShared];

        [_globalPreferences setObject:_apiNavDrawerItemsJson forKey:@"api_nav_drawer_items_json"];
        [_globalPreferences setObject:_apiConnectedAppsJson forKey:@"api_connected_apps_json"];

        _numberOfStartsFirstXmasShown = [[OACommonInteger withKey:numberOfStartsFirstXmasShownKey defValue:0] makeGlobal];
        _lastFavCategoryEntered = [[OACommonString withKey:lastFavCategoryEnteredKey defValue:@""] makeGlobal];
        _useLastApplicationModeByDefault = [[[OACommonBoolean withKey:useLastApplicationModeByDefaultKey defValue:NO] makeGlobal] makeShared];
        _lastUsedApplicationMode = [[[OACommonString withKey:lastUsedApplicationModeKey defValue:OAApplicationMode.DEFAULT.stringKey] makeGlobal] makeShared];
        _lastRouteApplicationMode = [[OACommonAppMode withKey:lastRouteApplicationModeBackupStringKey defValue:OAApplicationMode.DEFAULT] makeGlobal];
        _searchHistory = [[[OACommonBoolean withKey:searchHistoryKey defValue:YES] makeGlobal] makeShared];
        _navigationHistory = [[[OACommonBoolean withKey:navigationHistoryKey defValue:YES] makeGlobal] makeShared];
        _mapMarkersHistory = [[[OACommonBoolean withKey:mapMarkersHistoryKey defValue:YES] makeGlobal] makeShared];

        [_globalPreferences setObject:_numberOfStartsFirstXmasShown forKey:@"number_of_starts_first_xmas_shown"];
        [_globalPreferences setObject:_lastFavCategoryEntered forKey:@"last_fav_category"];
        [_globalPreferences setObject:_useLastApplicationModeByDefault forKey:@"use_last_application_mode_by_default"];
        [_globalPreferences setObject:_lastUsedApplicationMode forKey:@"last_used_application_mode"];
        [_globalPreferences setObject:_lastRouteApplicationMode forKey:@"last_route_application_mode_backup_string"];
        [_globalPreferences setObject:_searchHistory forKey:@"search_history"];
        [_globalPreferences setObject:_navigationHistory forKey:@"navigation_history"];
        [_globalPreferences setObject:_mapMarkersHistory forKey:@"map_markers_history"];
        
        // TODO: not sure we need to override this setting with import/export
        _userIosId = [[[OACommonString withKey:userIosIdKey defValue:@""] makeGlobal] makeShared];
//        [_globalPreferences setObject:_userIosId forKey:@"user_android_id"];

        _onlineRoutingEngines = [[OACommonString withKey:onlineRoutingEnginesKey defValue:nil] makeGlobal];
        [_globalPreferences setObject:_onlineRoutingEngines forKey:@"online_routing_engines"];

        _doNotShowStartupMessages = [[[OACommonBoolean withKey:doNotShowStartupMessagesKey defValue:NO] makeGlobal] makeShared];
        _showDownloadMapDialog = [[[OACommonBoolean withKey:showDownloadMapDialogKey defValue:YES] makeGlobal] makeShared];

        [_globalPreferences setObject:_doNotShowStartupMessages forKey:@"do_not_show_startup_messages"];
        [_globalPreferences setObject:_showDownloadMapDialog forKey:@"show_download_map_dialog"];

        _sendAnonymousMapDownloadsData = [[[OACommonBoolean withKey:sendAnonymousMapDownloadsDataKey defValue:NO] makeGlobal] makeShared];
        _sendAnonymousAppUsageData = [[[OACommonBoolean withKey:sendAnonymousAppUsageDataKey defValue:YES] makeGlobal] makeShared];
        _sendAnonymousDataRequestProcessed = [[[OACommonBoolean withKey:sendAnonymousDataRequestProcessedKey defValue:NO] makeGlobal] makeShared];
        _sendAnonymousDataRequestCount = [[OACommonInteger withKey:sendAnonymousDataRequestCountKey defValue:0] makeGlobal];
        _sendAnonymousDataLastRequestNs = [[OACommonInteger withKey:sendAnonymousDataLastRequestNsKey defValue:-1] makeGlobal];

        [_globalPreferences setObject:_sendAnonymousMapDownloadsData forKey:@"send_anonymous_map_downloads_data"];
        [_globalPreferences setObject:_sendAnonymousAppUsageData forKey:@"send_anonymous_app_usage_data"];
        [_globalPreferences setObject:_sendAnonymousDataRequestProcessed forKey:@"send_anonymous_data_request_processed"];
        [_globalPreferences setObject:_sendAnonymousDataRequestCount forKey:@"send_anonymous_data_requests_count"];
        [_globalPreferences setObject:_sendAnonymousDataLastRequestNs forKey:@"send_anonymous_data_last_request_ns"];

        _webglSupported = [[OACommonBoolean withKey:webglSupportedKey defValue:YES] makeGlobal];
        [_globalPreferences setObject:_webglSupported forKey:@"webgl_supported"];

        _inappsRead = [[OACommonBoolean withKey:inappsReadKey defValue:NO] makeGlobal];
        [_globalPreferences setObject:_inappsRead forKey:@"inapps_read"];
        
        _backupUserEmail = [[OACommonString withKey:backupUserEmailKey defValue:@""] makeGlobal];
        _backupUserId = [[OACommonString withKey:backupUserIdKey defValue:@""] makeGlobal];
        _backupDeviceId = [[OACommonString withKey:backupDeviceIdKey defValue:@""] makeGlobal];
        _backupNativeDeviceId = [[OACommonString withKey:backupNativeDeviceIdKey defValue:@""] makeGlobal];
        _backupAccessToken = [[OACommonString withKey:backupAccessTokenKey defValue:@""] makeGlobal];
        _backupAccessTokenUpdateTime = [[OACommonString withKey:backupAccessTokenUpdateTimeKey defValue:@""] makeGlobal];
        _backupFreePlanRegistrationTime = [[OACommonLong withKey:backupFreePlanRegistrationTime defValue:0] makeGlobal];

        [_globalPreferences setObject:_backupUserEmail forKey:@"backup_user_email"];
        [_globalPreferences setObject:_backupUserId forKey:@"backup_user_id"];
        [_globalPreferences setObject:_backupDeviceId forKey:@"backup_device_id"];
        [_globalPreferences setObject:_backupNativeDeviceId forKey:@"backup_native_device_id"];
        [_globalPreferences setObject:_backupAccessToken forKey:@"backup_access_token"];
        [_globalPreferences setObject:_backupAccessTokenUpdateTime forKey:@"backup_access_token_update_time"];
        [_globalPreferences setObject:_backupFreePlanRegistrationTime forKey:backupFreePlanRegistrationTime];
        
        _backupPromocode = [[OACommonString withKey:backupPromocodeKey defValue:@""] makeGlobal];
        _backupPurchaseActive = [[OACommonBoolean withKey:backupPurchaseActiveKey defValue:NO] makeGlobal];
        _backupPurchaseStartTime = [[OACommonLong withKey:backupPurchaseStartTimeKey defValue:0] makeGlobal];
        _backupPurchaseExpireTime = [[OACommonLong withKey:backupPurchaseExpireTimeKey defValue:0] makeGlobal];
        _backupPurchaseState = [[OACommonSubscriptionState withKey:backupPurchaseStateKey defValue:OASubscriptionState.UNDEFINED] makeGlobal];
        _proSubscriptionOrigin = [[OACommonInteger withKey:proSubscriptionOriginKey defValue:-1] makeGlobal];
        _proSubscriptionDuration = [[OACommonInteger withKey:proSubscriptionDurationKey defValue:-1] makeGlobal];
        
        [_globalPreferences setObject:_backupPromocode forKey:@"backup_promocode"];
        [_globalPreferences setObject:_backupPurchaseActive forKey:@"backup_promocode_active"];
        [_globalPreferences setObject:_backupPurchaseStartTime forKey:@"promo_website_start_time"];
        [_globalPreferences setObject:_backupPurchaseExpireTime forKey:@"promo_website_expire_time"];
        [_globalPreferences setObject:_backupPurchaseState forKey:@"promo_website_state"];
        [_globalPreferences setObject:_proSubscriptionOrigin forKey:@"pro_subscription_origin"];
        [_globalPreferences setObject:_proSubscriptionDuration forKey:@"backup_purchase_period"];
        
        _purchasedIdentifiers = [[OACommonString withKey:purchaseIdentifiersKey defValue:@""] makeGlobal];

        _favoritesLastUploadedTime = [[OACommonLong withKey:favoritesLastUploadedTimeKey defValue:0] makeGlobal];
        _backupLastUploadedTime = [[OACommonLong withKey:backupLastUploadedTimeKey defValue:0] makeGlobal];

        [_globalPreferences setObject:_favoritesLastUploadedTime forKey:@"favorites_last_uploaded_time"];
        [_globalPreferences setObject:_backupLastUploadedTime forKey:@"backup_last_uploaded_time"];

        _delayToStartNavigation = [[[OACommonInteger withKey:delayToStartNavigationKey defValue:-1] makeGlobal] makeShared];
        [_globalPreferences setObject:_delayToStartNavigation forKey:@"delay_to_start_navigation"];

        _enableProxy = [[[OACommonBoolean withKey:enableProxyKey defValue:NO] makeGlobal] makeShared];
        _proxyHost = [[[OACommonString withKey:proxyHostKey defValue:@"127.0.0.1"] makeGlobal] makeShared];
        _proxyPort = [[[OACommonInteger withKey:proxyPortKey defValue:8118] makeGlobal] makeShared];
//        _userAndroidId = [[OACommonString withKey:userAndroidIdKey defValue:@""] makeGlobal];

        [_globalPreferences setObject:_enableProxy forKey:@"enable_proxy"];
        [_globalPreferences setObject:_proxyHost forKey:@"proxy_host"];
        [_globalPreferences setObject:_proxyPort forKey:@"proxy_port"];
//        [_globalPreferences setObject:_userAndroidId forKey:@"user_android_id"];

        _speedCamerasUninstalled = [[[OACommonBoolean withKey:speedCamerasUninstalledKey defValue:NO] makeGlobal] makeShared];
        _speedCamerasAlertShown = [[[OACommonBoolean withKey:speedCamerasAlertShownKey defValue:NO] makeGlobal] makeShared];

        [_globalPreferences setObject:_speedCamerasUninstalled forKey:@"speed_cameras_uninstalled"];
        [_globalPreferences setObject:_speedCamerasAlertShown forKey:@"speed_cameras_alert_showed"];

        _lastUpdatesCardRefresh = [[OACommonLong withKey:lastUpdatesCardRefreshKey defValue:0] makeGlobal];
        [_globalPreferences setObject:_lastUpdatesCardRefresh forKey:@"last_updates_card_refresh"];

        _currentTrackColor = [[[OACommonInteger withKey:currentTrackColorKey defValue:0] makeGlobal] makeShared];
        _currentTrackColoringType = [[[OACommonColoringType withKey:currentTrackColoringTypeKey defValue:OAColoringType.TRACK_SOLID values:[OAColoringType getTrackColoringTypes]] makeGlobal] makeShared];
        _currentTrackSpeedGradientPalette = [[[OACommonString withKey:currentTrackSpeedGradientPaletteKey defValue:nil] makeGlobal] makeShared];
        _currentTrackAltitudeGradientPalette = [[[OACommonString withKey:currentTrackAltitudeGradientPaletteKey defValue:nil] makeGlobal] makeShared];
        _currentTrackSlopeGradientPalette = [[[OACommonString withKey:currentTrackSlopeGradientPaletteKey defValue:nil] makeGlobal] makeShared];
        _currentTrackWidth = [[[OACommonString withKey:currentTrackWidthKey defValue:@""] makeGlobal] makeShared];
        
        _currentTrackShowArrows = [[[OACommonBoolean withKey:currentTrackShowArrowsKey defValue:NO] makeGlobal] makeShared];
        
        _currentTrackShowStartFinish = [[[OACommonBoolean withKey:currentTrackShowStartFinishKey defValue:YES] makeGlobal] makeShared];
        
        _currentTrackVerticalExaggerationScale = [[[OACommonDouble withKey:currentTrackVerticalExaggerationScaleKey defValue:0.25] makeGlobal] makeShared];
        _currentTrackElevationMeters = [[[OACommonInteger withKey:currentTrackElevationMetersKey defValue:kElevationDefMeters] makeGlobal] makeShared];
        _currentTrackVisualization3dByType = [[[OACommonInteger withKey:currentTrackVisualization3dByTypeKey defValue:EOAGPX3DLineVisualizationByTypeNone] makeGlobal] makeShared];
        
        _currentTrackVisualization3dWallColorType = [[[OACommonInteger withKey:currentTrackVisualization3dWallColorTypeKey defValue:EOAGPX3DLineVisualizationWallColorTypeUpwardGradient] makeGlobal] makeShared];
        _currentTrackVisualization3dPositionType = [[[OACommonInteger withKey:currentTrackVisualization3dPositionTypeKey defValue:EOAGPX3DLineVisualizationPositionTypeTop] makeGlobal] makeShared];
        
        _customTrackColors = [[[OACommonStringList withKey:customTrackColorsKey defValue:@[]] makeGlobal] makeShared];
        _customTrackColorsLastUsed = [[[OACommonStringList withKey:customTrackColorsLastUsedKey defValue:@[]] makeGlobal] makeShared];
        _lastUsedFavIcons = [[[OACommonStringList withKey:lastUsedFavIconsKey defValue:@[]] makeGlobal] makeShared];

        [_globalPreferences setObject:_currentTrackColor forKey:@"current_track_color"];
        [_globalPreferences setObject:_currentTrackColoringType forKey:@"current_track_coloring_type"];
        [_globalPreferences setObject:_currentTrackSpeedGradientPalette forKey:@"current_track_speed_gradient_palette"];
        [_globalPreferences setObject:_currentTrackAltitudeGradientPalette forKey:@"current_track_altitude_gradient_palette"];
        [_globalPreferences setObject:_currentTrackSlopeGradientPalette forKey:@"current_track_slope_gradient_palette"];
        [_globalPreferences setObject:_currentTrackWidth forKey:@"current_track_width"];
        [_globalPreferences setObject:_currentTrackShowArrows forKey:@"current_track_show_arrows"];
        [_globalPreferences setObject:_currentTrackShowStartFinish forKey:@"current_track_show_start_finish"];
        
        [_globalPreferences setObject:_currentTrackVerticalExaggerationScale forKey:@"current_track_vertical_exaggeration_scale"];
        [_globalPreferences setObject:_currentTrackElevationMeters forKey:@"current_track_elevation_meters"];
        [_globalPreferences setObject:_currentTrackVisualization3dByType forKey:@"current_track_visualization_3d_by_type"];
        [_globalPreferences setObject:_currentTrackVisualization3dWallColorType forKey:@"current_track_visualization_3d_wall_color_type"];
        [_globalPreferences setObject:_currentTrackVisualization3dPositionType forKey:@"current_track_visualization_3d_position_type"];
        
        [_globalPreferences setObject:_customTrackColors forKey:@"custom_track_colors"];
        [_globalPreferences setObject:_customTrackColorsLastUsed forKey:@"custom_track_colors_last_used"];
        [_globalPreferences setObject:_lastUsedFavIcons forKey:@"last_used_favorite_icons"];

        _gpsStatusApp = [[[OACommonString withKey:gpsStatusAppKey defValue:@""] makeGlobal] makeShared];
        [_globalPreferences setObject:_gpsStatusApp forKey:@"gps_status_app"];

        _debugRenderingInfo = [[[OACommonBoolean withKey:debugRenderingInfoKey defValue:NO] makeGlobal] makeShared];
        [_globalPreferences setObject:_debugRenderingInfo forKey:@"debug_rendering"];

        _use3dIconsByDefault = [[[OACommonBoolean withKey:use3dIconsByDefaultKey defValue:YES] makeGlobal] makeShared];
        [_globalPreferences setObject:_use3dIconsByDefault forKey:@"_use3dIconsByDefault"];
        
        _levelToSwitchVectorRaster = [[OACommonInteger withKey:debugRenderingInfoKey defValue:1] makeGlobal];
        [_globalPreferences setObject:_levelToSwitchVectorRaster forKey:@"level_to_switch_vector_raster"];

        // For now this can be changed only in TestVoiceActivity
//        public final OsmandPreference<Integer>[] VOICE_PROMPT_DELAY = new IntPreference[10];
//
//        {
            // 1500 ms delay works for most configurations to establish a BT SCO link
//            VOICE_PROMPT_DELAY[0] = new IntPreference(this, "voice_prompt_delay_0", 1500).makeGlobal().makeShared().cache(); /*AudioManager.STREAM_VOICE_CALL*/
            // On most devices sound output works pomptly so usually no voice prompt delay needed
//            VOICE_PROMPT_DELAY[3] = new IntPreference(this, "voice_prompt_delay_3", 0).makeGlobal().makeShared().cache();    /*AudioManager.STREAM_MUSIC*/
//            VOICE_PROMPT_DELAY[5] = new IntPreference(this, "voice_prompt_delay_5", 0).makeGlobal().makeShared().cache();    /*AudioManager.STREAM_NOTIFICATION*/
//        }

        _displayTtsUtterance = [[[OACommonBoolean withKey:displayTtsUtteranceKey defValue:NO] makeGlobal] makeShared];
        [_globalPreferences setObject:_displayTtsUtterance forKey:@"display_tts_utterance"];

        _mapOverlayPrevious = [[OACommonString withKey:mapOverlayPreviousKey defValue:nil] makeGlobal];
        _mapUnderlayPrevious = [[OACommonString withKey:mapUnderlayPreviousKey defValue:nil] makeGlobal];
        _previousInstalledVersion = [[OACommonString withKey:previousInstalledVersionKey defValue:@""] makeGlobal];
        _shouldShowFreeVersionBanner = [[[OACommonBoolean withKey:shouldShowFreeVersionBannerKey defValue:NO] makeGlobal] makeShared];

        [_globalPreferences setObject:_mapOverlayPrevious forKey:@"map_overlay_previous"];
        [_globalPreferences setObject:_mapUnderlayPrevious forKey:@"map_underlay_previous"];
        [_globalPreferences setObject:_previousInstalledVersion forKey:@"previous_installed_version"];
        [_globalPreferences setObject:_shouldShowFreeVersionBanner forKey:@"should_show_free_version_banner"];

        _routeMapMarkersStartMyLoc = [[[OACommonBoolean withKey:routeMapMarkersStartMyLocKey defValue:NO] makeGlobal] makeShared];
        _routeMapMarkersRoundTrip = [[[OACommonBoolean withKey:routeMapMarkersRoundTripKey defValue:NO] makeGlobal] makeShared];

        [_globalPreferences setObject:_routeMapMarkersStartMyLoc forKey:@"route_map_markers_start_my_loc"];
        [_globalPreferences setObject:_routeMapMarkersRoundTrip forKey:@"route_map_markers_round_trip"];

        _osmandUsageSpace = [[OACommonLong withKey:osmandUsageSpaceKey defValue:0] makeGlobal];
        [_globalPreferences setObject:_osmandUsageSpace forKey:@"osmand_usage_space"];

        _lastSelectedGpxTrackForNewPoint = [[OACommonString withKey:lastSelectedGpxTrackForNewPointKey defValue:@""] makeGlobal];
        [_globalPreferences setObject:_lastSelectedGpxTrackForNewPoint forKey:@"last_selected_gpx_track_for_new_point"];

        _customRouteLineColors = [[[OACommonStringList withKey:customRouteLineColorsKey defValue:@[]] makeGlobal] makeShared];
        [_globalPreferences setObject:_customRouteLineColors forKey:@"custom_route_line_colors"];

        _mapActivityEnabled = [[OACommonBoolean withKey:mapActivityEnabledKey defValue: NO] makeGlobal];
        [_globalPreferences setObject:_mapActivityEnabled forKey:@"map_activity_enabled"];

        _safeMode = [[[OACommonBoolean withKey:safeModeKey defValue: NO] makeGlobal] makeShared];
        _nativeRenderingFailed = [[OACommonBoolean withKey:nativeRenderingFailedKey defValue: NO] makeGlobal];

        [_globalPreferences setObject:_safeMode forKey:@"safe_mode"];
        [_globalPreferences setObject:_nativeRenderingFailed forKey:@"native_rendering_failed_init"];

        _useOpenglRender = [[[OACommonBoolean withKey:useOpenglRenderKey defValue: NO] makeGlobal] makeShared];
        _openglRenderFailed = [[OACommonBoolean withKey:openglRenderFailedKey defValue: NO] makeGlobal];

        [_globalPreferences setObject:_useOpenglRender forKey:@"use_opengl_render"];
        [_globalPreferences setObject:_openglRenderFailed forKey:@"opengl_render_failed"];

        _contributionInstallAppDate = [[OACommonString withKey:contributionInstallAppDateKey defValue:@""] makeGlobal];
        [_globalPreferences setObject:_contributionInstallAppDate forKey:@"CONTRIBUTION_INSTALL_APP_DATE"];

        _selectedTravelBook = [[[OACommonString withKey:selectedTravelBookKey defValue:@""] makeGlobal] makeShared];
        [_globalPreferences setObject:_selectedTravelBook forKey:@"selected_travel_book"];

        _agpsDataLastTimeDownloaded = [[OACommonLong withKey:agpsDataLastTimeDownloadedKey defValue:0] makeGlobal];
        [_globalPreferences setObject:_agpsDataLastTimeDownloaded forKey:@"agps_data_downloaded"];

        _searchTab = [[OACommonInteger withKey:searchTabKey defValue:0] makeGlobal];
        _favoritesTab = [[OACommonInteger withKey:favoritesTabKey defValue:0] makeGlobal];

        [_globalPreferences setObject:_searchTab forKey:@"SEARCH_TAB"];
        [_globalPreferences setObject:_favoritesTab forKey:@"FAVORITES_TAB"];

        _fluorescentOverlays = [[[OACommonBoolean withKey:fluorescentOverlaysKey defValue:NO] makeGlobal] makeShared];
        [_globalPreferences setObject:_fluorescentOverlays forKey:@"fluorescent_overlays"];
        
        _keepMapLabelsVisible = [[[OACommonBoolean withKey:keepMapLabelsVisibleKey defValue:NO] makeGlobal] makeShared];
        [_globalPreferences setObject:_keepMapLabelsVisible forKey:@"keep_map_labels_visible"];

        _numberOfFreeDownloads = [[OACommonInteger withKey:numberOfFreeDownloadsKey defValue:0] makeGlobal];
        [_globalPreferences setObject:_numberOfFreeDownloads forKey:@"free_downloads_v3"];

        _lastDisplayTime = [[OACommonLong withKey:lastDisplayTimeKey defValue:0] makeGlobal];
        _lastCheckedUpdates = [[OACommonLong withKey:lastCheckedUpdatesKey defValue:0] makeGlobal];
        _numberOfAppStartsOnDislikeMoment = [[OACommonInteger withKey:numberOfAppStartsOnDislikeMomentKey defValue:0] makeGlobal];
        _rateUsState = [[OACommonRateUsState withKey:rateUsStateKey defValue:EOARateUsStateInitialState] makeGlobal];

        [_globalPreferences setObject:_lastDisplayTime forKey:@"last_display_time"];
        [_globalPreferences setObject:_lastCheckedUpdates forKey:@"last_checked_updates"];
        [_globalPreferences setObject:_numberOfAppStartsOnDislikeMoment forKey:@"number_of_app_starts_on_dislike_moment"];
        [_globalPreferences setObject:_rateUsState forKey:@"rate_us_state"];
        
        _lastUUIDChangeTimestamp = [[OACommonLong withKey:lastUUIDChangeTimestampKey defValue:0] makeGlobal];
        
        _mapScreenOrientation = [OACommonInteger withKey:mapScreenOrientationKey defValue:EOAScreenOrientationSystem];
        [_profilePreferences setObject:_mapScreenOrientation forKey:@"map_screen_orientation"];
        
        _useOldRouting = [[[OACommonBoolean withKey:useOldRoutingKey defValue:NO] makeGlobal] makeShared];
        [_globalPreferences setObject:_useOldRouting forKey:@"use_old_routing"];

        [self fetchImpassableRoads];

        for (NSString *key in _profilePreferences.keyEnumerator)
        {
            if ([key isEqualToString:topWidgetPanelOrderOldKey] || [key isEqualToString:bottomWidgetPanelOrderKeyOld])
                continue;

            [self registerPreference:[self getProfilePreference:key] forKey:key];
        }
        for (NSString *key in _globalPreferences.keyEnumerator)
        {
            [self registerPreference:[self getGlobalPreference:key] forKey:key];
        }
    }
    return self;
}

- (NSMapTable<NSString *, OACommonPreference *> *)getPreferences:(BOOL)global
{
    return global ? _globalPreferences : _profilePreferences;
}

- (OACommonPreference *)getGlobalPreference:(NSString *)key
{
    return [_globalPreferences objectForKey:key];
}

- (void)setGlobalPreference:(NSString *)value key:(NSString *)key
{
    OACommonPreference *setting = [_globalPreferences objectForKey:key];
    if (setting)
        [setting setValueFromString:value appMode:nil];
}

- (OACommonPreference *)getProfilePreference:(NSString *)key
{
    return [_profilePreferences objectForKey:key];
}

- (void)setProfilePreference:(NSString *)value key:(NSString *)key
{
    OACommonPreference *setting = [_profilePreferences objectForKey:key];
    if (setting)
        [setting setValueFromString:value appMode:nil];
}

- (NSMapTable<NSString *, OACommonPreference *> *)getRegisteredPreferences
{
    return _registeredPreferences;
}

- (NSMapTable<NSString *, OACommonPreference *> *)getGlobalPreferences
{
    return _globalPreferences;
}

- (OACommonPreference *)getPreferenceByKey:(NSString *)key
{
    return [_registeredPreferences objectForKey:key];
}

- (void)registerPreference:(OACommonPreference *)preference forKey:(NSString *)key
{
    [_registeredPreferences setObject:preference forKey:key];
}

- (OACommonBoolean *)registerBooleanPreference:(NSString *)key defValue:(BOOL)defValue
{
    if ([_registeredPreferences objectForKey:key])
        return (OACommonBoolean *)[_registeredPreferences objectForKey:key];
    
    OACommonBoolean *p = [OACommonBoolean withKey:key defValue:defValue];
    [self registerPreference:p forKey:key];
    return p;
}

- (OACommonString *)registerStringPreference:(NSString *)key defValue:(NSString *)defValue
{
    if ([_registeredPreferences objectForKey:key])
        return (OACommonString *)[_registeredPreferences objectForKey:key];
    
    OACommonString *p = [OACommonString withKey:key defValue:defValue];
    [self registerPreference:p forKey:key];
    return p;
}

- (OACommonStringList *)registerStringListPreference:(NSString *)key defValue:(NSArray<NSString *> *)defValue
{
    if ([_registeredPreferences objectForKey:key])
        return (OACommonStringList *)[_registeredPreferences objectForKey:key];
    
    OACommonStringList *p = [OACommonStringList withKey:key defValue:defValue ];
    [self registerPreference:p forKey:key];
    return p;
}

- (OACommonInteger *)registerIntPreference:(NSString *)key defValue:(int)defValue
{
    if ([_registeredPreferences objectForKey:key])
        return (OACommonInteger *)[_registeredPreferences objectForKey:key];
    
    OACommonInteger *p = [OACommonInteger withKey:key defValue:defValue];
    [self registerPreference:p forKey:key];
    return p;
}

- (OACommonLong *)registerLongPreference:(NSString *)key defValue:(long)defValue
{
    if ([_registeredPreferences objectForKey:key])
        return (OACommonLong *)[_registeredPreferences objectForKey:key];
    
    OACommonLong *p = [OACommonLong withKey:key defValue:defValue];
    [self registerPreference:p forKey:key];
    return p;
}

- (OACommonDouble *)registerFloatPreference:(NSString *)key defValue:(double)defValue
{
    if ([_registeredPreferences objectForKey:key])
        return (OACommonDouble *)[_registeredPreferences objectForKey:key];
    
    OACommonDouble *p = [OACommonDouble withKey:key defValue:defValue];
    [self registerPreference:p forKey:key];
    return p;
}

- (OACommonWidgetSizeStyle *)registerWidgetSizeStylePreference:(NSString *)key defValue:(EOAWidgetSizeStyle)defValue
{
    if ([_registeredPreferences objectForKey:key])
        return (OACommonWidgetSizeStyle *) [_registeredPreferences objectForKey:key];
    
    OACommonWidgetSizeStyle *p = [OACommonWidgetSizeStyle withKey:key defValue:defValue];
    [self registerPreference:p forKey:key];
    return p;
}

- (void)resetPreferencesForProfile:(OAApplicationMode *)mode
{
    for (OACommonPreference *value in [_profilePreferences objectEnumerator].allObjects)//todo
    {
        [value resetModeToDefault:mode];
    }

    for (OACommonBoolean *value in [_customBooleanRoutingProps objectEnumerator].allObjects)
    {
        [value resetModeToDefault:mode];
    }

    for (OACommonString *value in [_customRoutingProps objectEnumerator].allObjects)
    {
        [value resetModeToDefault:mode];
    }

    if (!mode.isCustomProfile)
    {
        [self.userProfileName resetModeToDefault:mode];
        [self.profileIconName resetModeToDefault:mode];
        [self.profileIconColor resetModeToDefault:mode];
    }

    [OAAppData.defaults resetProfileSettingsForMode:mode];
    [NSNotificationCenter.defaultCenter postNotificationName:kWidgetVisibilityChangedMotification object:nil];
}

// Common Settings
- (void) setSettingShowMapRulet:(BOOL)settingShowMapRulet {
    _settingShowMapRulet = settingShowMapRulet;
    [[NSUserDefaults standardUserDefaults] setBool:_settingShowMapRulet forKey:settingShowMapRuletKey];
}

- (void) setSettingMapLanguageShowLocal:(BOOL)settingMapLanguageShowLocal
{
    _settingMapLanguageShowLocal = settingMapLanguageShowLocal;
    [[NSUserDefaults standardUserDefaults] setBool:_settingMapLanguageShowLocal forKey:settingMapLanguageShowLocalKey];
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

- (void) setShowBordersOfDownloadedMaps:(BOOL)mapSettingShowBordersOfDownloadedMaps
{
    [_mapSettingShowBordersOfDownloadedMaps set:mapSettingShowBordersOfDownloadedMaps];
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

- (NSSet<NSString *> *) getEnabledPlugins
{
    NSMutableSet<NSString *> *res = [NSMutableSet set];
    for (NSString *p in _plugins.get)
    {
        if (![p hasPrefix:@"-"])
            [res addObject:p];
    }
    return [NSSet setWithSet:res];
}

- (NSSet<NSString *> *) getPlugins
{
    return [NSSet setWithArray:_plugins.get];
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
    NSArray *array = [set allObjects];
    if (![array isEqualToArray:_plugins.get])
        [_plugins set:array];
}

- (void) setLastSearchedCity:(unsigned long long)lastSearchedCity
{
    _lastSearchedCity = lastSearchedCity;
    [[NSUserDefaults standardUserDefaults] setObject:@(lastSearchedCity) forKey:lastSearchedCityKey];
}

- (void) setLastSearchedCityName:(NSString *)lastSearchedCityName
{
    _lastSearchedCityName = lastSearchedCityName;
    [[NSUserDefaults standardUserDefaults] setObject:lastSearchedCityName forKey:lastSearchedCityNameKey];
}

- (void) setLastSearchedPoint:(CLLocation *)lastSearchedPoint
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

- (void)setApplicationModePref:(OAApplicationMode *)applicationMode
{
    [self setApplicationModePref:applicationMode markAsLastUsed:YES];
}

- (void)setApplicationModePref:(OAApplicationMode *)applicationMode markAsLastUsed:(BOOL)markAsLastUsed
{
    OAApplicationMode *prevAppMode = [_applicationMode get];
    [_applicationMode set:applicationMode];
    if (prevAppMode != _applicationMode.get)
    {
        if (markAsLastUsed)
            [_lastUsedApplicationMode set:applicationMode.stringKey];
        [[ThemeManager shared] configureWithAppMode: applicationMode];
        [[[OsmAndApp instance].data applicationModeChangedObservable] notifyEventWithKey:prevAppMode];
    }
}

- (void) showGpx:(NSArray<NSString *> *)filePaths update:(BOOL)update
{
    BOOL added = NO;
    NSMutableArray *arr = [NSMutableArray arrayWithArray:_mapSettingVisibleGpx.get];
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
        [self.mapSettingVisibleGpx set:arr];
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
    NSMutableArray *arr = [NSMutableArray arrayWithArray:_mapSettingVisibleGpx.get];
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
        [self.mapSettingVisibleGpx set:[NSMutableArray arrayWithArray:filePaths]];
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
    NSMutableArray *arr = [NSMutableArray arrayWithArray:_mapSettingVisibleGpx.get];
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
    [self.mapSettingVisibleGpx set:arr];

    if (removed && update)
        [[[OsmAndApp instance] updateGpxTracksOnMapObservable] notifyEvent];
}

- (void) hideRemovedGpx
{
    OsmAndAppInstance app = [OsmAndApp instance];
    NSMutableArray *arr = [NSMutableArray arrayWithArray:_mapSettingVisibleGpx.get];
    NSMutableArray *arrToDelete = [NSMutableArray array];
    for (NSString *filepath in arr)
    {
        OAGPX *gpx = [[OAGPXDatabase sharedDb] getGPXItem:filepath];
        NSString *fileName = filepath.lastPathComponent;
        NSString *filenameWithoutPrefix = nil;
        if ([fileName hasSuffix:@"_osmand_backup"])
            filenameWithoutPrefix = [fileName stringByReplacingOccurrencesOfString:@"_osmand_backup" withString:@""];

        NSString *path = [app.gpxPath stringByAppendingPathComponent:filenameWithoutPrefix ? filenameWithoutPrefix : gpx.gpxFilePath];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path] || !gpx)
            [arrToDelete addObject:filepath];
    }
    [arr removeObjectsInArray:arrToDelete];
    [self.mapSettingVisibleGpx set:[NSArray arrayWithArray:arr]];
}

- (NSString *) getFormattedTrackInterval:(int)value
{
    NSString *res;
    if (value == 0)
        res = OALocalizedString(@"rec_interval_minimum");
    else if (value > 90)
        res = [NSString stringWithFormat:@"%d %@", (int)(value / 60.0), OALocalizedString(@"int_min")];
    else
        res = [NSString stringWithFormat:@"%d %@", value, OALocalizedString(@"shared_string_sec")];
    return res;
}

- (NSString *) getModeKey:(NSString *)key mode:(OAApplicationMode *)mode
{
    return [NSString stringWithFormat:@"%@_%@", key, mode.stringKey];
}

- (OACommonBoolean *)getCustomRoutingBooleanProperty:(NSString *)attrName defaultValue:(BOOL)defaultValue
{
    @synchronized (_settingsLock)
    {
        OACommonBoolean *value = [_customBooleanRoutingProps objectForKey:attrName];
        if (!value)
        {
            value = [OACommonBoolean withKey:[NSString stringWithFormat:@"prouting_%@", attrName] defValue:defaultValue];
            [_customBooleanRoutingProps setObject:value forKey:attrName];
        }
        return value;
    }
}

- (OACommonString *)getCustomRoutingProperty:(NSString *)attrName defaultValue:(NSString *)defaultValue
{
    @synchronized (_settingsLock)
    {
        OACommonString *value = [_customRoutingProps objectForKey:attrName];
        if (!value)
        {
            value = [OACommonString withKey:[NSString stringWithFormat:@"prouting_%@", attrName] defValue:defaultValue];
            [_customRoutingProps setObject:value forKey:attrName];
        }
        return value;
    }
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

- (void) setSimulateNavigation:(BOOL)simulateNavigation
{
    _simulateNavigation = simulateNavigation;
    [[[OsmAndApp instance] simulateRoutingObservable] notifyEvent];
}

- (void) setUseOsmLiveForRouting:(BOOL)useOsmLiveForRouting
{
    _useOsmLiveForRouting = useOsmLiveForRouting;
    [[NSUserDefaults standardUserDefaults] setBool:_useOsmLiveForRouting forKey:useOsmLiveForRoutingKey];
}

- (void)setCustomPluginsJson:(NSString *)customPluginsJson
{
    _customPluginsJson = customPluginsJson;
    [[NSUserDefaults standardUserDefaults] setObject:_customPluginsJson forKey:customPluginsJsonKey];
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
    {
        if ([_layerTransparencySeekbarMode get] == LAYER_TRANSPARENCY_SEEKBAR_MODE_UNDERLAY || [_layerTransparencySeekbarMode get] == LAYER_TRANSPARENCY_SEEKBAR_MODE_ALL)
            [_layerTransparencySeekbarMode set:LAYER_TRANSPARENCY_SEEKBAR_MODE_ALL];
        else
            [_layerTransparencySeekbarMode set:LAYER_TRANSPARENCY_SEEKBAR_MODE_OVERLAY];
    }
   else
   {
        if ([_layerTransparencySeekbarMode get] == LAYER_TRANSPARENCY_SEEKBAR_MODE_ALL)
            [_layerTransparencySeekbarMode set:LAYER_TRANSPARENCY_SEEKBAR_MODE_UNDERLAY];
        else
            [_layerTransparencySeekbarMode set:LAYER_TRANSPARENCY_SEEKBAR_MODE_OFF];
    }
}

- (BOOL) getUnderlayOpacitySliderVisibility
{
    return [_layerTransparencySeekbarMode get] == LAYER_TRANSPARENCY_SEEKBAR_MODE_UNDERLAY || [_layerTransparencySeekbarMode get] == LAYER_TRANSPARENCY_SEEKBAR_MODE_ALL;
}

- (void) setUnderlayOpacitySliderVisibility:(BOOL)visibility
{
    if (visibility)
    {
        if ([_layerTransparencySeekbarMode get] == LAYER_TRANSPARENCY_SEEKBAR_MODE_OVERLAY || [_layerTransparencySeekbarMode get] == LAYER_TRANSPARENCY_SEEKBAR_MODE_ALL)
            [_layerTransparencySeekbarMode set:LAYER_TRANSPARENCY_SEEKBAR_MODE_ALL];
        else
            [_layerTransparencySeekbarMode set:LAYER_TRANSPARENCY_SEEKBAR_MODE_UNDERLAY];
    }
   else
    {
        if ([_layerTransparencySeekbarMode get] == LAYER_TRANSPARENCY_SEEKBAR_MODE_ALL)
            [_layerTransparencySeekbarMode set:LAYER_TRANSPARENCY_SEEKBAR_MODE_OVERLAY];
        else
            [_layerTransparencySeekbarMode set:LAYER_TRANSPARENCY_SEEKBAR_MODE_OFF];
    }
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

- (NSSet<NSString *> *) getCustomAppModesKeys
{
    NSString *appModeKeys = self.customAppModes.get;
    NSArray<NSString *> *keysArr = [appModeKeys componentsSeparatedByString:@","];
    return [NSSet setWithArray:keysArr];
}

- (long) getLastGloblalSettingsModifiedTime
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:lastGlobalSettingsModifiedTimeKey] longValue];
}

- (void) setLastGlobalModifiedTime:(long)timestamp
{
    [[NSUserDefaults standardUserDefaults] setObject:@(timestamp) forKey:lastGlobalSettingsModifiedTimeKey];
}

- (long) getLastProfileSettingsModifiedTime:(OAApplicationMode *)mode
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_%@", lastProfileSettingsModifiedTimeKey, mode.stringKey]] longValue];
}

- (void) setLastProfileModifiedTime:(long)timestamp mode:(OAApplicationMode *)mode
{
    [[NSUserDefaults standardUserDefaults] setObject:@(timestamp) forKey:[NSString stringWithFormat:@"%@_%@", lastProfileSettingsModifiedTimeKey, mode.stringKey]];
}

- (void)setDisabledTypes:(NSSet<NSString *> *)disabledTypes
{
    _disabledTypes = disabledTypes;
}

- (NSSet<NSString *> *)getDisabledTypes
{
    return _disabledTypes;
}

- (BOOL)isTypeDisabled:(NSString *)typeName
{
    return [_disabledTypes containsObject:typeName];
}

- (CLLocation *) getLastStartPoint
{
    if (_lastStartLat && _lastStartLon)
    {
        return [[CLLocation alloc] initWithLatitude:[_lastStartLat get] longitude:[_lastStartLon get]];
    }
    return nil;
}

- (void) setLastStartPoint:(CLLocation *)location
{
    if (location)
    {
        [self setLastStartPoint:location.coordinate.latitude lon:location.coordinate.longitude];
    }
    else
    {
        [_lastStartLat resetToDefault];
        [_lastStartLon resetToDefault];
    }
}

- (void) setLastStartPoint:(double)lat lon:(double)lon
{
    [_lastStartLat set:lat];
    [_lastStartLon set:lon];
}

@end
