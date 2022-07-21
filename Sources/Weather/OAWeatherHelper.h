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

#define kWeatherProgressDownloadingSuffix @"_downloading"
#define kWeatherProgressCalculateSizeLocalSuffix @"_calculate_size_local"
#define kWeatherProgressCalculateSizeUpdatesSuffix @"_calculate_size_updates"
#define kWeatherProgressDestinationSuffix @"_destination"

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

@protocol OAWeatherDownloaderDelegate

- (void)onProgressUpdate:(OAWorldRegion *)region
             sizeUpdates:(NSInteger)sizeUpdates
               sizeLocal:(NSInteger)sizeLocal
      calculateSizeLocal:(BOOL)calculateSizeLocal
    calculateSizeUpdates:(BOOL)calculateSizeUpdates
                 success:(BOOL)success;

@end

@interface OAWeatherHelper : NSObject

@property (nonatomic, readonly) NSArray<OAWeatherBand *> *bands;
@property (nonatomic, readonly) OAMapPresentationEnvironment *mapPresentationEnvironment;

@property (readonly) OAObservable *weatherSizeLocalCalculateObserver;
@property (readonly) OAObservable *weatherSizeUpdatesCalculateObserver;
@property (readonly) OAObservable *weatherForecastDownloadingObserver;

+ (OAWeatherHelper *) sharedInstance;

- (void) updateMapPresentationEnvironment:(OAMapPresentationEnvironment *)mapPresentationEnvironment;

- (QList<OsmAnd::BandIndex>) getVisibleBands;
- (QHash<OsmAnd::BandIndex, std::shared_ptr<const OsmAnd::GeoBandSettings>>) getBandSettings;

- (void)downloadForecast:(OAWorldRegion *)region;

- (void)calculateCacheSize:(OAWorldRegion *)region localData:(BOOL)localData;
- (void)calculateCacheSize:(BOOL)localData onComplete:(void (^)(unsigned long long))onComplete;

- (void)clearCache:(BOOL)localData;
- (void)clearOutdatedCache;
- (void)removeLocalForecast:(OAWorldRegion *)region refreshMap:(BOOL)refreshMap;
- (void)removeIncompleteDownloads:(OAWorldRegion *)region;

- (void)updatePreferences:(OAWorldRegion *)region;

+ (OAResourceItem *)generateResourceItem:(OAWorldRegion *)region;

+ (BOOL)hasStatus:(NSInteger)status region:(OAWorldRegion *)region;
+ (void)addStatus:(NSInteger)status region:(OAWorldRegion *)region;
+ (void)removeStatus:(NSInteger)status region:(OAWorldRegion *)region;

+ (NSInteger)getPreferenceStatus:(NSString *)regionId;
+ (void)setPreferenceStatus:(NSString *)regionId value:(NSInteger)value;

+ (NSTimeInterval)getPreferenceLastUpdate:(NSString *)regionId;
+ (void)setPreferenceLastUpdate:(NSString *)regionId value:(NSTimeInterval)value;

+ (BOOL)getPreferenceWifi:(NSString *)regionId;
+ (void)setPreferenceWifi:(NSString *)regionId value:(BOOL)value;

+ (EOAWeatherForecastUpdatesFrequency)getPreferenceFrequency:(NSString *)regionId;
+ (void)setPreferenceFrequency:(NSString *)regionId value:(EOAWeatherForecastUpdatesFrequency)value;

+ (NSInteger)getPreferenceSizeLocal:(NSString *)regionId;
+ (void)setPreferenceSizeLocal:(NSString *)regionId value:(NSInteger)value;

+ (NSInteger)getPreferenceSizeUpdates:(NSString *)regionId;
+ (void)setPreferenceSizeUpdates:(NSString *)regionId value:(NSInteger)value;

+ (NSArray<NSString *> *)getPreferenceKeys:(NSString *)regionId;
+ (void)setDefaultPreferences:(NSString *)regionId;
+ (void)removePreferences:(NSString *)regionId excludeKeys:(NSArray<NSString *> *)excludeKeys;

- (NSInteger)getProgress:(OAWorldRegion *)region key:(NSString *)key;

@end

//NS_ASSUME_NONNULL_END
