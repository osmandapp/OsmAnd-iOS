//
//  OAChoosePlanHelper.h
//  OsmAnd
//
//  Created by Alexey on 22/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAProduct;

typedef NS_ENUM(NSUInteger, EOAFeature)
{
    EOAFeatureCloud = 0,
    EOAFeatureAdvancedWidgets,
    EOAFeatureHourlyMapUpdates,
    EOAFeatureMonthlyMapUpdates,
    EOAFeatureUnlimitedMapDownloads,
    EOAFeatureCarPlay,
    EOAFeatureCombinedWiki,
    EOAFeatureWikipedia,
    EOAFeatureWikivoyage,
    EOAFeatureTerrain,
    EOAFeatureNautical,
    EOAFeatureWeather,

    EOAFeatureRegionAfrica,
    EOAFeatureRegionRussia,
    EOAFeatureRegionAsia,
    EOAFeatureRegionAustralia,
    EOAFeatureRegionEurope,
    EOAFeatureRegionCentralAmerica,
    EOAFeatureRegionNorthAmerica,
    EOAFeatureRegionSouthAmerica
};

@interface OAFeature : NSObject

- (instancetype) initWithFeature:(EOAFeature)feature;

- (NSString *)getTitle;
- (NSString *)getListTitle;
- (NSString *)getDescription;

- (UIImage *)getIcon;
- (UIImage *)getIconBig;

- (BOOL)isAvailableInMapsPlus;
- (BOOL)isAvailableInOsmAndPro;

+ (OAFeature *)OSMAND_CLOUD;
+ (OAFeature *)ADVANCED_WIDGETS;
+ (OAFeature *)HOURLY_MAP_UPDATES;
+ (OAFeature *)MONTHLY_MAP_UPDATES;
+ (OAFeature *)UNLIMITED_MAP_DOWNLOADS;
+ (OAFeature *)CARPLAY;
+ (OAFeature *)COMBINED_WIKI;
+ (OAFeature *)WIKIPEDIA;
+ (OAFeature *)WIKIVOYAGE;
+ (OAFeature *)TERRAIN;
+ (OAFeature *)NAUTICAL;
+ (OAFeature *)WEATHER;

+ (NSArray<OAFeature *> *)OSMAND_PRO_FEATURES;
+ (NSArray<OAFeature *> *)OSMAND_PRO_PREVIEW_FEATURES;
+ (NSArray<OAFeature *> *)MAPS_PLUS_FEATURES;
+ (NSArray<OAFeature *> *)MAPS_PLUS_PREVIEW_FEATURES;

+ (OAFeature *)getFeature:(EOAFeature)type;

@end

@interface OAChoosePlanHelper : NSObject

+ (void) showChoosePlanScreenWithSuffix:(NSString *)productIdentifierSuffix navController:(UINavigationController *)navController;
+ (void) showChoosePlanScreen:(UINavigationController *)navController;
+ (void) showChoosePlanScreenWithFeature:(OAFeature * _Nullable)feature navController:(UINavigationController *)navController;
+ (void) showChoosePlanScreenWithProduct:(OAProduct * _Nullable)product navController:(UINavigationController *)navController;

@end

NS_ASSUME_NONNULL_END
