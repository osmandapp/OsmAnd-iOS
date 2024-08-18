//
//  OAChoosePlanHelper.m
//  OsmAnd
//
//  Created by Alexey on 22/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAChoosePlanHelper.h"
#import "OAChoosePlanViewController.h"
#import "OAIAPHelper.h"
#import "OAProducts.h"
#import "Localization.h"

static OAFeature * OSMAND_CLOUD;
static OAFeature * ADVANCED_WIDGETS;
static OAFeature * HOURLY_MAP_UPDATES;
static OAFeature * CROSS_BUY;
static OAFeature * MONTHLY_MAP_UPDATES;
static OAFeature * UNLIMITED_MAP_DOWNLOADS;
static OAFeature * CARPLAY;
static OAFeature * COMBINED_WIKI;
static OAFeature * WIKIPEDIA;
static OAFeature * WIKIVOYAGE;
static OAFeature * RELIEF_3D;
static OAFeature * TERRAIN;
static OAFeature * NAUTICAL;
static OAFeature * WEATHER;
static OAFeature * SENSORS;

static NSArray<OAFeature *> * OSMAND_PRO_FEATURES;
static NSArray<OAFeature *> * OSMAND_PRO_PREVIEW_FEATURES;
static NSArray<OAFeature *> * MAPS_PLUS_FEATURES;
static NSArray<OAFeature *> * MAPS_PLUS_PREVIEW_FEATURES;

@implementation OAFeature
{
    EOAFeature _feature;
}

- (instancetype) initWithFeature:(EOAFeature)feature
{
    self = [super init];
    if (self)
    {
        _feature = feature;
    }
    return self;
}

- (NSString *)getTitle
{
    switch (_feature)
    {
        case EOAFeatureCloud:
            return OALocalizedString(@"osmand_cloud");
        case EOAFeatureAdvancedWidgets:
            return OALocalizedString(@"pro_features");
        case EOAFeatureSensors:
            return OALocalizedString(@"external_sensors_support");
        case EOAFeatureHourlyMapUpdates:
            return OALocalizedString(@"daily_map_updates");
        case EOAFeatureCrossBuy:
            return OALocalizedString(@"shared_string_cross_buy");
        case EOAFeatureMonthlyMapUpdates:
            return OALocalizedString(@"monthly_map_updates");
        case EOAFeatureUnlimitedMapDownloads:
            return OALocalizedString(@"unlimited_map_downloads");
        case EOAFeatureCarPlay:
            return OALocalizedString(@"carplay");
        case EOAFeatureCombinedWiki:
            return OALocalizedString(@"wikipedia_and_wikivoyage_offline");
        case EOAFeatureWikipedia:
            return OALocalizedString(@"wikipedia_offline");
        case EOAFeatureWikivoyage:
            return OALocalizedString(@"offline_wikivoyage");
        case EOAFeatureRelief3D:
            return OALocalizedString(@"shared_string_relief_3d");
        case EOAFeatureTerrain:
            return OALocalizedString(@"contour_lines_hillshade_maps");
        case EOAFeatureNautical:
            return OALocalizedString(@"nautical_depth");
        case EOAFeatureWeather:
            return OALocalizedString(@"shared_string_weather");
        case EOAFeatureRegionAfrica:
            return OALocalizedString(@"product_desc_africa");
        case EOAFeatureRegionRussia:
            return OALocalizedString(@"product_desc_russia");
        case EOAFeatureRegionAsia:
            return OALocalizedString(@"product_desc_asia");
        case EOAFeatureRegionAustralia:
            return OALocalizedString(@"product_desc_australia");
        case EOAFeatureRegionEurope:
            return OALocalizedString(@"product_desc_europe");
        case EOAFeatureRegionCentralAmerica:
            return OALocalizedString(@"product_desc_centralamerica");
        case EOAFeatureRegionNorthAmerica:
            return OALocalizedString(@"product_desc_northamerica");
        case EOAFeatureRegionSouthAmerica:
            return OALocalizedString(@"product_desc_southamerica");
        default:
            return @"";
    }
}

- (NSString *)getListTitle
{
    switch (_feature)
    {
        case EOAFeatureTerrain:
            return OALocalizedString(@"terrain_maps");
        default:
            return [self getTitle];
    }
}

- (NSString *)getDescription
{
    switch (_feature)
    {
        case EOAFeatureCloud:
            return OALocalizedString(@"purchases_feature_desc_osmand_cloud");
        case EOAFeatureAdvancedWidgets:
            return OALocalizedString(@"purchases_feature_desc_pro_widgets");
        case EOAFeatureSensors:
            return OALocalizedString(@"purchases_feature_desc_external_sensors");
        case EOAFeatureHourlyMapUpdates:
            return OALocalizedString(@"purchases_feature_desc_hourly_map_updates");
        case EOAFeatureCrossBuy:
            return OALocalizedString(@"purchases_feature_desc_cross_buy");
        case EOAFeatureMonthlyMapUpdates:
            return OALocalizedString(@"purchases_feature_desc_monthly_map_updates");
        case EOAFeatureUnlimitedMapDownloads:
            return OALocalizedString(@"purchases_feature_desc_unlimited_map_download");
        case EOAFeatureCarPlay:
            return OALocalizedString(@"purchases_feature_desc_carplay");
        case EOAFeatureCombinedWiki:
            return OALocalizedString(@"purchases_feature_desc_combined_wiki");
        case EOAFeatureWikipedia:
            return OALocalizedString(@"purchases_feature_desc_wikipedia");
        case EOAFeatureWikivoyage:
            return OALocalizedString(@"purchases_feature_desc_wikivoyage");
        case EOAFeatureRelief3D:
            return OALocalizedString(@"purchases_feature_relief_3d_description");
        case EOAFeatureTerrain:
            return OALocalizedString(@"purchases_feature_desc_terrain");
        case EOAFeatureNautical:
            return OALocalizedString(@"purchases_feature_desc_nautical");
        case EOAFeatureWeather:
            return OALocalizedString(@"purchases_feature_weather");
        default:
            return @"";
    }
}

- (UIImage *)getIcon
{
    switch (_feature)
    {
        case EOAFeatureCloud:
            return [UIImage imageNamed:@"ic_custom_cloud_upload_colored"];
        case EOAFeatureAdvancedWidgets:
            return [UIImage imageNamed:@"ic_custom_pro_features_colored"];
        case EOAFeatureSensors:
            return [UIImage imageNamed:@"ic_custom_external_sensor_colored"];
        case EOAFeatureHourlyMapUpdates:
            return [UIImage imageNamed:@"ic_custom_map_updates_colored"];
        case EOAFeatureCrossBuy:
            return [UIImage imageNamed:@"ic_custom_cross_buy_colored"];
        case EOAFeatureMonthlyMapUpdates:
            return [UIImage imageNamed:@"ic_custom_monthly_map_updates_colored"];
        case EOAFeatureUnlimitedMapDownloads:
        case EOAFeatureRegionAfrica:
        case EOAFeatureRegionRussia:
        case EOAFeatureRegionAsia:
        case EOAFeatureRegionAustralia:
        case EOAFeatureRegionEurope:
        case EOAFeatureRegionCentralAmerica:
        case EOAFeatureRegionNorthAmerica:
        case EOAFeatureRegionSouthAmerica:
            return [UIImage imageNamed:@"ic_custom_unlimited_downloads_colored"];
        case EOAFeatureCarPlay:
            return [UIImage imageNamed:@"ic_custom_carplay_colored"];
        case EOAFeatureCombinedWiki:
            return [UIImage imageNamed:@"ic_custom_wikipedia_download_colored"];
        case EOAFeatureWikipedia:
            return [UIImage imageNamed:@"ic_custom_wikipedia_download_colored"];
        case EOAFeatureWikivoyage:
            return [UIImage imageNamed:@"ic_custom_backpack_colored"];
        case EOAFeatureRelief3D:
            return [UIImage imageNamed:@"ic_custom_3d_relief_colored"];
        case EOAFeatureTerrain:
            return [UIImage imageNamed:@"ic_custom_contour_lines_colored"];
        case EOAFeatureNautical:
            return [UIImage imageNamed:@"ic_custom_nautical_depth_colored"];
        case EOAFeatureWeather:
            return [UIImage imageNamed:@"ic_custom_umbrella_colored"];
        default:
            return nil;
    }
}

- (UIImage *)getIconBig
{
    switch (_feature)
    {
        case EOAFeatureCloud:
            return [UIImage imageNamed:@"ic_custom_cloud_upload_colored"];
        case EOAFeatureAdvancedWidgets:
            return [UIImage imageNamed:@"ic_custom_pro_features_colored_big"];
        case EOAFeatureSensors:
            return [UIImage imageNamed:@"ic_custom_external_sensor_colored"];
        case EOAFeatureHourlyMapUpdates:
            return [UIImage imageNamed:@"ic_custom_map_updates_colored"];
        case EOAFeatureCrossBuy:
            return [UIImage imageNamed:@"ic_custom_cross_buy_colored"];
        case EOAFeatureMonthlyMapUpdates:
            return [UIImage imageNamed:@"ic_custom_monthly_map_updates_colored"];
        case EOAFeatureUnlimitedMapDownloads:
        case EOAFeatureRegionAfrica:
        case EOAFeatureRegionRussia:
        case EOAFeatureRegionAsia:
        case EOAFeatureRegionAustralia:
        case EOAFeatureRegionEurope:
        case EOAFeatureRegionCentralAmerica:
        case EOAFeatureRegionNorthAmerica:
        case EOAFeatureRegionSouthAmerica:
            return [UIImage imageNamed:@"ic_custom_unlimited_downloads_colored"];
        case EOAFeatureCarPlay:
            return [UIImage imageNamed:@"ic_custom_carplay_colored"];
        case EOAFeatureCombinedWiki:
            return [UIImage imageNamed:@"ic_custom_wikipedia_download_colored"];
        case EOAFeatureWikipedia:
            return [UIImage imageNamed:@"ic_custom_wikipedia_download_colored"];
        case EOAFeatureWikivoyage:
            return [UIImage imageNamed:@"ic_custom_backpack_colored"];
        case EOAFeatureRelief3D:
            return [UIImage imageNamed:@"ic_custom_3d_relief_colored"];
        case EOAFeatureTerrain:
            return [UIImage imageNamed:@"ic_custom_contour_lines_colored"];
        case EOAFeatureNautical:
            return [UIImage imageNamed:@"ic_custom_nautical_depth_colored"];
        case EOAFeatureWeather:
            return [UIImage imageNamed:@"ic_custom_umbrella_colored"];
        default:
            return nil;
    }
}

- (BOOL)isAvailableInMapsPlus
{
    return [OAFeature.MAPS_PLUS_FEATURES containsObject:self];
}

- (BOOL)isAvailableInOsmAndPro
{
    return [OAFeature.OSMAND_PRO_FEATURES containsObject:self];
}

+ (OAFeature *)OSMAND_CLOUD
{
    if (!OSMAND_CLOUD)
        OSMAND_CLOUD = [[OAFeature alloc] initWithFeature:EOAFeatureCloud];
    return OSMAND_CLOUD;
}

+ (OAFeature *)ADVANCED_WIDGETS
{
    if (!ADVANCED_WIDGETS)
        ADVANCED_WIDGETS = [[OAFeature alloc] initWithFeature:EOAFeatureAdvancedWidgets];
    return ADVANCED_WIDGETS;
}

+ (OAFeature *)HOURLY_MAP_UPDATES
{
    if (!HOURLY_MAP_UPDATES)
        HOURLY_MAP_UPDATES = [[OAFeature alloc] initWithFeature:EOAFeatureHourlyMapUpdates];
    return HOURLY_MAP_UPDATES;
}

+ (OAFeature *)CROSS_BUY
{
    if (!CROSS_BUY)
        CROSS_BUY = [[OAFeature alloc] initWithFeature:EOAFeatureCrossBuy];
    return CROSS_BUY;
}

+ (OAFeature *)MONTHLY_MAP_UPDATES
{
    if (!MONTHLY_MAP_UPDATES)
        MONTHLY_MAP_UPDATES = [[OAFeature alloc] initWithFeature:EOAFeatureMonthlyMapUpdates];
    return MONTHLY_MAP_UPDATES;
}

+ (OAFeature *)UNLIMITED_MAP_DOWNLOADS
{
    if (!UNLIMITED_MAP_DOWNLOADS)
        UNLIMITED_MAP_DOWNLOADS = [[OAFeature alloc] initWithFeature:EOAFeatureUnlimitedMapDownloads];
    return UNLIMITED_MAP_DOWNLOADS;
}

+ (OAFeature *)CARPLAY
{
    if (!CARPLAY)
        CARPLAY = [[OAFeature alloc] initWithFeature:EOAFeatureCarPlay];
    return CARPLAY;
}

+ (OAFeature *)COMBINED_WIKI
{
    if (!COMBINED_WIKI)
        COMBINED_WIKI = [[OAFeature alloc] initWithFeature:EOAFeatureCombinedWiki];
    return COMBINED_WIKI;
}

+ (OAFeature *)WIKIPEDIA
{
    if (!WIKIPEDIA)
        WIKIPEDIA = [[OAFeature alloc] initWithFeature:EOAFeatureWikipedia];
    return WIKIPEDIA;
}

+ (OAFeature *)WIKIVOYAGE
{
    if (!WIKIVOYAGE)
        WIKIVOYAGE = [[OAFeature alloc] initWithFeature:EOAFeatureWikivoyage];
    return WIKIVOYAGE;
}

+ (OAFeature *)RELIEF_3D
{
    if (!RELIEF_3D)
        RELIEF_3D = [[OAFeature alloc] initWithFeature:EOAFeatureRelief3D];
    return RELIEF_3D;
}

+ (OAFeature *)TERRAIN
{
    if (!TERRAIN)
        TERRAIN = [[OAFeature alloc] initWithFeature:EOAFeatureTerrain];
    return TERRAIN;
}

+ (OAFeature *)NAUTICAL
{
    if (!NAUTICAL)
        NAUTICAL = [[OAFeature alloc] initWithFeature:EOAFeatureNautical];
    return NAUTICAL;
}

+ (OAFeature *)WEATHER
{
    if (!WEATHER)
        WEATHER = [[OAFeature alloc] initWithFeature:EOAFeatureWeather];
    return WEATHER;
}

+ (OAFeature *)SENSORS
{
    if (!SENSORS)
        SENSORS = [[OAFeature alloc] initWithFeature:EOAFeatureSensors];
    return SENSORS;
}

+ (NSArray<OAFeature *> *)OSMAND_PRO_FEATURES
{
    if (!OSMAND_PRO_FEATURES)
    {
        OSMAND_PRO_FEATURES = @[
                OAFeature.OSMAND_CLOUD,
//                OAFeature.ADVANCED_WIDGETS,
                OAFeature.WEATHER,
                OAFeature.SENSORS,
                OAFeature.HOURLY_MAP_UPDATES,
                OAFeature.CROSS_BUY,
                OAFeature.RELIEF_3D,
                OAFeature.MONTHLY_MAP_UPDATES,
                OAFeature.UNLIMITED_MAP_DOWNLOADS,
                OAFeature.CARPLAY,
//                OAFeature.COMBINED_WIKI,
                OAFeature.WIKIPEDIA,
                OAFeature.WIKIVOYAGE,
                OAFeature.TERRAIN,
                OAFeature.NAUTICAL,
        ];
    }
    return OSMAND_PRO_FEATURES;
}

+ (NSArray<OAFeature *> *)OSMAND_PRO_PREVIEW_FEATURES
{
    if (!OSMAND_PRO_PREVIEW_FEATURES)
    {
        OSMAND_PRO_PREVIEW_FEATURES = @[
                OAFeature.OSMAND_CLOUD,
//                OAFeature.ADVANCED_WIDGETS,
                OAFeature.WEATHER,
                OAFeature.HOURLY_MAP_UPDATES,
                OAFeature.UNLIMITED_MAP_DOWNLOADS,
                OAFeature.CARPLAY,
//                OAFeature.COMBINED_WIKI,
                OAFeature.TERRAIN,
                OAFeature.NAUTICAL
        ];
    }
    return OSMAND_PRO_PREVIEW_FEATURES;
}

+ (NSArray<OAFeature *> *)MAPS_PLUS_FEATURES
{
    if (!MAPS_PLUS_FEATURES)
    {
        MAPS_PLUS_FEATURES = @[
                OAFeature.MONTHLY_MAP_UPDATES,
                OAFeature.UNLIMITED_MAP_DOWNLOADS,
                OAFeature.CARPLAY,
//                OAFeature.COMBINED_WIKI,
                OAFeature.WIKIPEDIA,
                OAFeature.WIKIVOYAGE,
                OAFeature.TERRAIN,
                OAFeature.NAUTICAL
        ];
    }
    return MAPS_PLUS_FEATURES;
}

+ (NSArray<OAFeature *> *)MAPS_PLUS_PREVIEW_FEATURES
{
    if (!MAPS_PLUS_PREVIEW_FEATURES)
    {
        MAPS_PLUS_PREVIEW_FEATURES = @[
                OAFeature.MONTHLY_MAP_UPDATES,
                OAFeature.UNLIMITED_MAP_DOWNLOADS,
                OAFeature.CARPLAY,
//                OAFeature.COMBINED_WIKI,
                OAFeature.TERRAIN,
                OAFeature.NAUTICAL
        ];
    }
    return MAPS_PLUS_PREVIEW_FEATURES;
}

+ (OAFeature *)getFeature:(EOAFeature)type
{
    switch (type)
    {
        case EOAFeatureCloud:
            return OAFeature.OSMAND_CLOUD;
        case EOAFeatureAdvancedWidgets:
            return OAFeature.ADVANCED_WIDGETS;
        case EOAFeatureSensors:
            return OAFeature.SENSORS;
        case EOAFeatureHourlyMapUpdates:
            return OAFeature.HOURLY_MAP_UPDATES;
        case EOAFeatureCrossBuy:
            return OAFeature.CROSS_BUY;
        case EOAFeatureMonthlyMapUpdates:
            return OAFeature.MONTHLY_MAP_UPDATES;
        case EOAFeatureUnlimitedMapDownloads:
        case EOAFeatureRegionAfrica:
        case EOAFeatureRegionRussia:
        case EOAFeatureRegionAsia:
        case EOAFeatureRegionAustralia:
        case EOAFeatureRegionEurope:
        case EOAFeatureRegionCentralAmerica:
        case EOAFeatureRegionNorthAmerica:
        case EOAFeatureRegionSouthAmerica:
            return OAFeature.UNLIMITED_MAP_DOWNLOADS;
        case EOAFeatureCarPlay:
            return OAFeature.CARPLAY;
        case EOAFeatureCombinedWiki:
            return OAFeature.COMBINED_WIKI;
        case EOAFeatureWikipedia:
            return OAFeature.WIKIPEDIA;
        case EOAFeatureWikivoyage:
            return OAFeature.WIKIVOYAGE;
        case EOAFeatureRelief3D:
            return OAFeature.RELIEF_3D;
        case EOAFeatureTerrain:
            return OAFeature.TERRAIN;
        case EOAFeatureNautical:
            return OAFeature.NAUTICAL;
        case EOAFeatureWeather:
            return OAFeature.WEATHER;
        default:
            return nil;
    }
}

@end

@implementation OAChoosePlanHelper

+ (void) showChoosePlanScreenWithSuffix:(NSString *)productIdentifierSuffix navController:(UINavigationController *)navController
{
    if (productIdentifierSuffix.length == 0 || [productIdentifierSuffix isEqualToString:@"osmlive"])
    {
        [self.class showChoosePlanScreen:navController];
    }
    else
    {
        for (OAProduct *product in [OAIAPHelper sharedInstance].inApps)
        {
            if ([product.productIdentifier hasSuffix:productIdentifierSuffix])
            {
                [self.class showChoosePlanScreenWithProduct:product navController:navController];
                break;
            }
        }
    }
}

+ (void) showChoosePlanScreen:(UINavigationController *)navController
{
    [self showChoosePlanScreenWithFeature:nil navController:navController];
}

+ (void) showChoosePlanScreenWithFeature:(OAFeature * _Nullable)feature navController:(UINavigationController *)navController
{
    OAChoosePlanViewController *choosePlanViewController =
            [[OAChoosePlanViewController alloc] initWithFeature:feature ? feature : OAFeature.OSMAND_PRO_FEATURES.firstObject];
    [self showImpl:choosePlanViewController navController:navController];
}

+ (void) showChoosePlanScreenWithProduct:(OAProduct * _Nullable)product navController:(UINavigationController *)navController
{
    OAChoosePlanViewController *choosePlanViewController =
            [[OAChoosePlanViewController alloc] initWithProduct:product ? product : [OAIAPHelper sharedInstance].proMonthly
                                                           type:EOAChoosePlan];
    [self showImpl:choosePlanViewController navController:navController];
}

+ (void) showImpl:(OAChoosePlanViewController *)viewController navController:(UINavigationController *)navController
{
    UINavigationController *modalController = [[UINavigationController alloc] initWithRootViewController:viewController];
    modalController.navigationBarHidden = YES;
    modalController.edgesForExtendedLayout = UIRectEdgeNone;
    [navController presentViewController:modalController animated:YES completion:nil];
}

@end
