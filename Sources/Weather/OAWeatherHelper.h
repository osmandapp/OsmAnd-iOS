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

typedef NS_ENUM(NSInteger, EOAWeatherForecastDownloadState)
{
    EOAWeatherForecastDownloadStateUndefined = -1,
    EOAWeatherForecastDownloadStateInProgress,
    EOAWeatherForecastDownloadStateFinished
};

@class OAWorldRegion, OAResourceItem, OAObservable;

//NS_ASSUME_NONNULL_BEGIN

@interface OAWeatherHelper : NSObject

@property (nonatomic, readonly) NSArray<OAWeatherBand *> *bands;
@property (nonatomic, readonly) OAMapPresentationEnvironment *mapPresentationEnvironment;

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
- (void)downloadForecastByRegion:(OAWorldRegion *)region;
- (void)prepareToStopDownloading:(NSString *)regionId;

- (void)calculateCacheSize:(OAWorldRegion *)region onComplete:(void (^)())onComplete;
- (void)calculateFullCacheSize:(BOOL)localData
                    onComplete:(void (^)(unsigned long long))onComplete;

- (void)clearCache:(BOOL)localData regionIds:(NSArray<NSString *> *)regionIds;
- (void)clearOutdatedCache;
- (void)removeLocalForecast:(NSString *)regionId refreshMap:(BOOL)refreshMap;
- (void)removeLocalForecasts:(NSArray<NSString *> *)regionIds refreshMap:(BOOL)refreshMap;

- (BOOL)isContainsInOfflineRegions:(NSArray<NSNumber *> *)tileId excludeRegion:(NSString *)excludeRegionId;

+ (BOOL)isForecastOutdated:(NSString *)regionId;
- (void)firstInitForecast:(NSString *)region;

- (NSArray<NSString *> *)getTempForecastsWithDownloadStates:(NSArray<NSNumber *> *)states;

- (uint64_t)getOfflineForecastSizeInfo:(NSString *)regionId local:(BOOL)local;
- (BOOL)isOfflineForecastSizesInfoCalculated:(NSString *)regionId;
- (NSInteger)getOfflineForecastProgressInfo:(NSString *)regionId;
- (NSInteger)getProgressDestination:(NSString *)regionId;

- (OAResourceItem *)generateResourceItem:(OAWorldRegion *)region;
+ (NSAttributedString *)getStatusInfoDescription:(NSString *)regionId;
+ (NSString *)getAccuracyDescription:(NSString *)regionId;
+ (NSString *)getUpdatesDateFormat:(NSString *)regionId next:(BOOL)next;
+ (NSString *)getFrequencyFormat:(EOAWeatherForecastUpdatesFrequency)frequency;

+ (EOAWeatherForecastDownloadState)getPreferenceDownloadState:(NSString *)regionId;
+ (void)setPreferenceDownloadState:(NSString *)regionId value:(EOAWeatherForecastDownloadState)value;

+ (NSTimeInterval)getPreferenceLastUpdate:(NSString *)regionId;
+ (void)setPreferenceLastUpdate:(NSString *)regionId value:(NSTimeInterval)value;

+ (NSArray<NSArray<NSNumber *> *> *)getPreferenceTileIds:(NSString *)regionId;
+ (void)setPreferenceTileIds:(NSString *)regionId value:(NSArray<NSArray<NSNumber *> *> *)value;

+ (BOOL)getPreferenceWifi:(NSString *)regionId;
+ (void)setPreferenceWifi:(NSString *)regionId value:(BOOL)value;

+ (EOAWeatherForecastUpdatesFrequency)getPreferenceFrequency:(NSString *)regionId;
+ (void)setPreferenceFrequency:(NSString *)regionId value:(EOAWeatherForecastUpdatesFrequency)value;

+ (NSArray<NSString *> *)getPreferenceKeys:(NSString *)regionId;
+ (void)removePreferences:(NSString *)regionId;

@end

//NS_ASSUME_NONNULL_END
