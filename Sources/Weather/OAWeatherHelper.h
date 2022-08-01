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

typedef NS_ENUM(NSInteger, EOAWeatherForecastUpdatesFrequency)
{
    EOAWeatherForecastUpdatesUndefined = -1,
    EOAWeatherForecastUpdates12h = 0,
    EOAWeatherForecastUpdates24h,
    EOAWeatherForecastUpdatesWeek,
};

typedef NS_ENUM(NSInteger, EOAWeatherForecastStatus)
{
    EOAWeatherForecastStatusUndefined = 1 << 0,
    EOAWeatherForecastStatusOutdated = 1 << 1,
    EOAWeatherForecastStatusDownloading = 1 << 2,
    EOAWeatherForecastStatusDownloaded = 1 << 3,

    EOAWeatherForecastStatusCalculating = 1 << 4,
    EOAWeatherForecastStatusLocalCalculated = 1 << 5,
    EOAWeatherForecastStatusUpdatesCalculated = 1 << 6
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

- (void)downloadForecast:(OAWorldRegion *)region;

- (void)calculateCacheSize:(OAWorldRegion *)region
                onComplete:(void (^)(unsigned long long, unsigned long long))onComplete;
- (void)calculateFullCacheSize:(BOOL)localData
                    onComplete:(void (^)(unsigned long long))onComplete;

- (void)clearCache:(BOOL)localData;
- (void)clearOutdatedCache;
- (void)removeLocalForecast:(OAWorldRegion *)region refreshMap:(BOOL)refreshMap;
- (void)removeIncompleteForecast:(OAWorldRegion *)region;

- (void)updatePreferences:(OAWorldRegion *)region;

- (BOOL)isContainsInOfflineRegions:(NSArray<NSNumber *> *)tileId excludeRegion:(OAWorldRegion *)excludeRegion;
- (void)setOfflineRegion:(OAWorldRegion *)region;
- (NSArray<NSString *> *)getOfflineRegions;
- (NSInteger)getProgress:(OAWorldRegion *)region;
- (NSInteger)getProgressDestination:(OAWorldRegion *)region;

+ (OAResourceItem *)generateResourceItem:(OAWorldRegion *)region;

+ (BOOL)hasStatus:(NSInteger)status region:(NSString *)regionId;
+ (void)addStatus:(NSInteger)status region:(NSString *)regionId;
+ (void)removeStatus:(NSInteger)status region:(NSString *)regionId;

+ (NSInteger)getPreferenceStatus:(NSString *)regionId;
+ (void)setPreferenceStatus:(NSString *)regionId value:(NSInteger)value;

+ (NSTimeInterval)getPreferenceLastUpdate:(NSString *)regionId;
+ (void)setPreferenceLastUpdate:(NSString *)regionId value:(NSTimeInterval)value;

+ (NSArray<NSArray<NSNumber *> *> *)getPreferenceTileIds:(NSString *)regionId;
+ (void)setPreferenceTileIds:(NSString *)regionId value:(NSArray<NSArray<NSNumber *> *> *)value;

+ (BOOL)getPreferenceWifi:(NSString *)regionId;
+ (void)setPreferenceWifi:(NSString *)regionId value:(BOOL)value;

+ (EOAWeatherForecastUpdatesFrequency)getPreferenceFrequency:(NSString *)regionId;
+ (void)setPreferenceFrequency:(NSString *)regionId value:(EOAWeatherForecastUpdatesFrequency)value;

+ (NSInteger)getPreferenceSizeLocal:(NSString *)regionId;
+ (void)setPreferenceSizeLocal:(NSString *)regionId value:(NSInteger)value;

+ (NSInteger)getPreferenceSizeUpdates:(NSString *)regionId;
+ (void)setPreferenceSizeUpdates:(NSString *)regionId value:(NSInteger)value;

+ (NSArray<NSString *> *)getPreferenceKeys:(NSString *)regionId;
+ (void)removePreferences:(NSString *)regionId excludeKeys:(NSArray<NSString *> *)excludeKeys;

@end

//NS_ASSUME_NONNULL_END
