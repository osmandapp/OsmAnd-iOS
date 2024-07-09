//
//  OAWeatherHelper.h
//  OsmAnd Maps
//
//  Created by Alexey on 13.02.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAWeatherBand.h"
#import "OAMapPresentationEnvironment.h"

#include <OsmAndCore/Map/GeoCommonTypes.h>
#include <OsmAndCore/Map/GeoBandSettings.h>

#define kWeatherEntireWorldRegionId @"entire_world"

typedef NS_ENUM(NSInteger, EOAWeatherForecastUpdatesFrequency)
{
    EOAWeatherForecastUpdatesUndefined = -1,
    EOAWeatherForecastUpdatesSemiDaily = 0,
    EOAWeatherForecastUpdatesDaily,
    EOAWeatherForecastUpdatesWeekly,
};

typedef NS_ENUM(NSInteger, EOAWeatherAutoUpdate)
{
    EOAWeatherAutoUpdateDisabled,
    EOAWeatherAutoUpdateOverWIFIOnly,
    EOAWeatherAutoUpdateOverAnyNetwork
};

@class OAWorldRegion, OAResourceItem, OAObservable;

//NS_ASSUME_NONNULL_BEGIN

@interface OAWeatherHelper : NSObject

@property (nonatomic, readonly) NSArray<OAWeatherBand *> *bands;
@property (nonatomic, readonly) OAMapPresentationEnvironment *mapPresentationEnvironment;
@property (nonatomic, readonly) CGFloat onlineCacheSize;

@property (readonly) OAObservable *weatherSizeCalculatedObserver;
@property (readonly) OAObservable *weatherForecastDownloadingObserver;

+ (OAWeatherHelper *) sharedInstance;

- (void) updateMapPresentationEnvironment:(OAMapPresentationEnvironment *)mapPresentationEnvironment;

- (QList<OsmAnd::BandIndex>) getVisibleBands;
- (QHash<OsmAnd::BandIndex, std::shared_ptr<const OsmAnd::GeoBandSettings>>) getBandSettings;

+ (BOOL)shouldHaveWeatherForecast:(OAWorldRegion *)region;
+ (NSString *)checkAndGetRegionId:(OAWorldRegion *)region;
+ (NSString *)checkAndGetRegionName:(OAWorldRegion *)region;

- (void)checkAndDownloadForecastsByRegionIds:(NSArray<NSString *> *)regionIds;
- (void)downloadForecastsByRegionIds:(NSArray<NSString *> *)regionIds;

- (uint64_t)getOfflineForecastSize:(OAWorldRegion *)region forUpdate:(BOOL)forUpdate;

- (void)calculateCacheSize:(OAWorldRegion *)region onComplete:(void (^)())onComplete;
- (void)calculateFullCacheSize:(BOOL)localData
                    onComplete:(void (^)(unsigned long long))onComplete;
- (uint64_t)getOfflineWeatherForecastCacheSize;
- (NSArray<NSString *> *)getRegionIdsForDownloadedWeatherForecast;
- (BOOL)isDownloadedWeatherForecastForRegionId:(NSString *)regionId;
- (BOOL)isUndefinedDownloadStateFor:(OAWorldRegion *)region;

- (void)clearCache:(BOOL)localData regionIds:(NSArray<NSString *> *)regionIds region:(OAWorldRegion *)region;
- (void)clearOutdatedCache;
- (void)removeLocalForecast:(NSString *)regionId region:(OAWorldRegion *)region refreshMap:(BOOL)refreshMap;
- (void)removeLocalForecasts:(NSArray<NSString *> *)regionIds region:(OAWorldRegion *)region refreshMap:(BOOL)refreshMap;
- (void)preparingForDownloadForecastByRegion:(OAWorldRegion *)region regionId:(NSString *)regionId;
- (void)setupDownloadStateFinished:(OAWorldRegion *)region regionId:(NSString *)regionId;

- (BOOL)isContainsInOfflineRegions:(NSArray<NSNumber *> *)tileId excludeRegion:(NSString *)excludeRegionId;

+ (BOOL)isForecastOutdated:(NSString *)regionId;

- (NSInteger)getProgressDestination:(NSString *)regionId;

- (OAResourceItem *)generateResourceItem:(OAWorldRegion *)region;
+ (NSAttributedString *)getStatusInfoDescription:(NSString *)regionId;
+ (NSString *)getAccuracyDescription:(NSString *)regionId;
+ (NSString *)getUpdatesDateFormat:(NSString *)regionId next:(BOOL)next;
+ (NSString *)getFrequencyFormat:(EOAWeatherForecastUpdatesFrequency)frequency;

+ (EOAWeatherAutoUpdate)getPreferenceWeatherAutoUpdate:(NSString *)regionId;
+ (void)setPreferenceWeatherAutoUpdate:(NSString *)regionId value:(EOAWeatherAutoUpdate)value;
+ (NSString *)getPreferenceWeatherAutoUpdateString:(EOAWeatherAutoUpdate)value;

+ (NSTimeInterval)getPreferenceLastUpdate:(NSString *)regionId;
+ (void)setPreferenceLastUpdate:(NSString *)regionId value:(NSTimeInterval)value;

+ (NSArray<NSArray<NSNumber *> *> *)getPreferenceTileIds:(NSString *)regionId;
+ (void)setPreferenceTileIds:(NSString *)regionId value:(NSArray<NSArray<NSNumber *> *> *)value;

+ (EOAWeatherForecastUpdatesFrequency)getPreferenceFrequency:(NSString *)regionId;
+ (void)setPreferenceFrequency:(NSString *)regionId value:(EOAWeatherForecastUpdatesFrequency)value;

+ (NSArray<NSString *> *)getPreferenceKeys:(NSString *)regionId;
+ (void)removePreferences:(NSString *)regionId;

+ (NSDate *) roundForecastTimeToHour:(NSDate *)date;
- (BOOL)allLayersAreDisabled;

@end

//NS_ASSUME_NONNULL_END
