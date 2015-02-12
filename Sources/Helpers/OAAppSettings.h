//
//  OADebugSettings.h
//  OsmAnd
//
//  Created by AntonRogachevskiy on 10/16/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define settingShowMapRuletKey @"settingShowMapRuletKey"
#define settingMapLanguageKey @"settingMapLanguageKey"
#define settingAppModeKey @"settingAppModeKey"
#define settingMetricSystemKey @"settingMetricSystemKey"
#define settingZoomButtonKey @"settingZoomButtonKey"
#define settingGeoFormatKey @"settingGeoFormatKey"


#define mapSettingShowFavoritesKey @"mapSettingShowFavoritesKey"

// --- Details ---
// <renderingProperty attr="moreDetailed" name="More details" description="More details on map" type="boolean" possibleValues="" category="details"/>
#define mapSettingMoreDetailsKey @"mapSettingMoreDetailsKey"
// <renderingProperty attr="showSurfaces" name="Road surface" description="Show road surfaces" type="boolean" possibleValues="" category="details"/>
#define mapSettingRoadSurfaceKey @"mapSettingRoadSurfaceKey"
// <renderingProperty attr="showSurfaceGrade" name="Road quality" description="Show road quality" type="boolean" possibleValues="" category="details"/>
#define mapSettingRoadQualityKey @"mapSettingRoadQualityKey"
// <renderingProperty attr="showAccess" name="Show access restrictions" description="Show access restrictions" type="boolean" possibleValues="" category="details"/>
#define mapSettingAccessRestrictionsKey @"mapSettingAccessRestrictionsKey"

// <renderingProperty attr="contourLines" name="Show contour lines" description="Select minimum zoom level to display in map if available. Separate contour file may be needed." type="string" possibleValues="--,16,15,14,13,12,11" category="details"/>
#define mapSettingContourLinesKey @"mapSettingContourLinesKey"
// <renderingProperty attr="coloredBuildings" name="Colored buildings" description="Buildings colored by type" type="boolean" possibleValues="" category="details"/>
#define mapSettingColoredBuildingsKey @"mapSettingColoredBuildingsKey"
// <renderingProperty attr="streetLighting" name="Street lighting" description="Show street lighting" type="boolean" possibleValues="" category="details"/>
#define mapSettingStreetLightingKey @"mapSettingStreetLightingKey"

// -- Hide ---
// <renderingProperty attr="noAdminboundaries" name="Hide boundaries" description="Suppress display of admin levels 5-9" type="boolean" possibleValues="" category="hide"/>
#define mapSettingNoAdminboundariesKey @"mapSettingNoAdminboundariesKey"
// <renderingProperty attr="noPolygons" name="Hide polygons" description="Make all areal land features on map transparent" type="boolean" possibleValues="" category="hide"/>
#define mapSettingNoPolygonsKey @"mapSettingNoPolygonsKey"
// <renderingProperty attr="hideBuildings" name="Hide buildings" description="Hide buildings" type="boolean" possibleValues="" category="hide"/>
#define mapSettingHideBuildingsKey @"mapSettingHideBuildingsKey"

// --- Routes ---
// <renderingProperty attr="showCycleRoutes" name="Show cycle routes" description="Show cycle routes (*cn_networks) in bicycle mode" type="boolean" possibleValues="" category="routes"/>
#define mapSettingShowCycleRoutesKey @"mapSettingShowCycleRoutesKey"
// <renderingProperty attr="osmcTraces" name="Hiking symbol overlay" description="Render symbols of OSMC hiking traces" type="boolean" possibleValues="" category="routes"/>
#define mapSettingOsmcTracesKey @"mapSettingOsmcTracesKey"
// <renderingProperty attr="alpineHiking" name="Alpine hiking view" description="Render paths according to SAC scale" type="boolean" possibleValues="" category="routes"/>
#define mapSettingAlpineHikingKey @"mapSettingAlpineHikingKey"
// <renderingProperty attr="roadStyle" name="Road style" description="Road style" type="string" possibleValues=",orange,germanRoadAtlas,americanRoadAtlas"/>
#define mapSettingRoadStyleKey @"mapSettingRoadStyleKey"


@interface OAAppSettings : NSObject

+ (OAAppSettings *)sharedManager;
@property (assign, nonatomic) BOOL settingShowMapRulet;
@property (assign, nonatomic) int settingMapLanguage;

#define METRIC_SYSTEM_METERS 0
#define METRIC_SYSTEM_FEET 1
#define METRIC_SYSTEM_YARDS 2

#define APPEARANCE_MODE_DAY 0
#define APPEARANCE_MODE_NIGHT 1
#define APPEARANCE_MODE_AUTO 2

@property (assign, nonatomic) int settingAppMode; // 0 - Day; 1 - Night; 2 - Auto
@property (assign, nonatomic) int settingMetricSystem; // 0 - Metric; 1 - English, 2 - 
@property (assign, nonatomic) BOOL settingShowZoomButton;
@property (assign, nonatomic) int settingGeoFormat; // 0 -

@property (assign, nonatomic) BOOL mapSettingShowFavorites;

// Details
@property (assign, nonatomic) BOOL mapSettingMoreDetails;
@property (assign, nonatomic) BOOL mapSettingRoadSurface;
@property (assign, nonatomic) BOOL mapSettingRoadQuality;
@property (assign, nonatomic) BOOL mapSettingAccessRestrictions;
@property (copy, nonatomic) NSString *mapSettingContourLines;
@property (assign, nonatomic) BOOL mapSettingColoredBuildings;
@property (assign, nonatomic) BOOL mapSettingStreetLighting;

// Hide
@property (assign, nonatomic) BOOL mapSettingNoAdminboundaries;
@property (assign, nonatomic) BOOL mapSettingNoPolygons;
@property (assign, nonatomic) BOOL mapSettingHideBuildings;

// Routes
@property (assign, nonatomic) BOOL mapSettingShowCycleRoutes;
@property (assign, nonatomic) BOOL mapSettingOsmcTraces;
@property (assign, nonatomic) BOOL mapSettingAlpineHiking;
@property (copy, nonatomic) NSString *mapSettingRoadStyle;


@end
