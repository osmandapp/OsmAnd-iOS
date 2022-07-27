//
//  OAWeatherHelper.mm
//  OsmAnd Maps
//
//  Created by Alexey on 13.02.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAWeatherHelper.h"
#import "OsmAndApp.h"
#import "OAResourcesUIHelper.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAMapLayers.h"
#import "OALog.h"

#include <OsmAndCore/Map/WeatherTileResourceProvider.h>
#include <OsmAndCore/Map/WeatherTileResourcesManager.h>
#include <OsmAndCore/FunctorQueryController.h>

#define kWeatherForecastStatusPrefix @"forecast_status_"
#define kWeatherForecastLastUpdatePrefix @"forecast_last_update_"
#define kWeatherForecastFrequencyPrefix @"forecast_frequency_"
#define kWeatherForecastSizeLocalPrefix @"forecast_size_local_"
#define kWeatherForecastSizeUpdatesPrefix @"forecast_size_updates_"
#define kWeatherForecastTileIdsPrefix @"forecast_tile_ids_"
#define kWeatherForecastWifiPrefix @"forecast_download_via_wifi_"

@implementation OAWeatherHelper
{
    OsmAndAppInstance _app;
    std::shared_ptr<OsmAnd::WeatherTileResourcesManager> _weatherResourcesManager;
    NSMutableDictionary<NSString *, NSNumber *> *_offlineRegionsWithProgress;
}

@synthesize weatherSizeLocalCalculateObserver = _weatherSizeLocalCalculateObserver;
@synthesize weatherSizeUpdatesCalculateObserver = _weatherSizeUpdatesCalculateObserver;
@synthesize weatherForecastDownloadingObserver = _weatherForecastDownloadingObserver;

+ (OAWeatherHelper *) sharedInstance
{
    static OAWeatherHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OAWeatherHelper alloc] init];
    });
    return _sharedInstance;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _weatherResourcesManager = _app.resourcesManager->getWeatherResourcesManager();
        _offlineRegionsWithProgress = [NSMutableDictionary dictionary];

        _bands = @[
            [OAWeatherBand withWeatherBand:WEATHER_BAND_TEMPERATURE],
            [OAWeatherBand withWeatherBand:WEATHER_BAND_PRESSURE],
            [OAWeatherBand withWeatherBand:WEATHER_BAND_WIND_SPEED],
            [OAWeatherBand withWeatherBand:WEATHER_BAND_CLOUD],
            [OAWeatherBand withWeatherBand:WEATHER_BAND_PRECIPITATION]
        ];

        _weatherSizeLocalCalculateObserver = [[OAObservable alloc] init];
        _weatherSizeUpdatesCalculateObserver = [[OAObservable alloc] init];
        _weatherForecastDownloadingObserver = [[OAObservable alloc] init];
    }
    return self;
}

- (void) updateMapPresentationEnvironment:(OAMapPresentationEnvironment *)mapPresentationEnvironment
{
    _mapPresentationEnvironment = mapPresentationEnvironment;
}

- (QList<OsmAnd::BandIndex>) getVisibleBands
{
    QList<OsmAnd::BandIndex> res;
    for (OAWeatherBand *band in _bands)
        if ([band isBandVisible])
            res << band.bandIndex;
    
    return res;
}

- (QHash<OsmAnd::BandIndex, std::shared_ptr<const OsmAnd::GeoBandSettings>>) getBandSettings
{
    QHash<OsmAnd::BandIndex, std::shared_ptr<const OsmAnd::GeoBandSettings>> result;
    for (OAWeatherBand *band in _bands)
    {
        auto contourStyleName = QString::fromNSString([band getContourStyleName]);
        
        NSDictionary<NSNumber *, NSArray<NSNumber *> *> *contourLevels = [band getContourLevels:self.mapPresentationEnvironment];
        QHash<OsmAnd::ZoomLevel, QList<double>> contourLevelsMap;
        for (NSNumber * zoomNum in contourLevels.allKeys)
        {
            NSArray<NSNumber *> *levelsList = contourLevels[zoomNum];
            QList<double> levels;
            for (NSNumber *level in levelsList)
                levels << level.doubleValue;
            
            contourLevelsMap.insert((OsmAnd::ZoomLevel)zoomNum.intValue, levels);
        }
        NSDictionary<NSNumber *, NSArray<NSString *> *> *contourTypes = [band getContourTypes:self.mapPresentationEnvironment];
        QHash<OsmAnd::ZoomLevel, QStringList> contourTypesMap;
        for (NSNumber * zoomNum in contourTypes.allKeys)
        {
            NSArray<NSString *> *typesList = contourTypes[zoomNum];
            QStringList types;
            for (NSString *type in typesList)
                types << QString::fromNSString(type);
            
            contourTypesMap.insert((OsmAnd::ZoomLevel)zoomNum.intValue, types);
        }

        auto settings = std::make_shared<const OsmAnd::GeoBandSettings>(
            QString::fromNSString([band getBandUnit].symbol),
            QString::fromNSString([band getBandGeneralUnitFormat]),
            QString::fromNSString([band getBandPreciseUnitFormat]),
            QString::fromNSString([band getInternalBandUnit]),
            [band getBandOpacity],
            QString::fromNSString([band getColorFilePath]),
            contourStyleName,
            contourLevelsMap,
            contourTypesMap
        );
        result.insert((OsmAnd::BandIndex)band.bandIndex, settings);
    }
    return result;
}

- (void)downloadForecast:(OAWorldRegion *)region
{
    [self addOperationWithRegion:region calculateSizeLocal:NO calculateSizeUpdates:NO];
}

- (void)calculateCacheSize:(OAWorldRegion *)region localData:(BOOL)localData
{
    [self addOperationWithRegion:region calculateSizeLocal:localData calculateSizeUpdates:!localData];
}

- (void)addOperationWithRegion:(OAWorldRegion *)region
            calculateSizeLocal:(BOOL)calculateSizeLocal
          calculateSizeUpdates:(BOOL)calculateSizeUpdates
{
    OsmAnd::LatLon latLonTopLeft = OsmAnd::LatLon(region.bboxTopLeft.latitude, region.bboxTopLeft.longitude);
    OsmAnd::LatLon latLonBottomRight = OsmAnd::LatLon(region.bboxBottomRight.latitude, region.bboxBottomRight.longitude);
    OsmAnd::ZoomLevel zoom = OsmAnd::WeatherTileResourceProvider::getGeoTileZoom();
    if ([self.class getPreferenceTileIds:region.regionId].count == 0)
    {
        QVector<OsmAnd::TileId> qTileIds = OsmAnd::WeatherTileResourcesManager::generateGeoTileIds(latLonTopLeft, latLonBottomRight, zoom);
        NSMutableArray<NSArray<NSNumber *> *> *tileIds = [NSMutableArray array];
        for (auto &qTileId: qTileIds)
        {
            [tileIds addObject:@[@(qTileId.x), @(qTileId.y)]];
        }
        [self.class setPreferenceTileIds:region.regionId value:tileIds];
    }

    [self setProgress:region value:0];

    if (calculateSizeUpdates)
    {
        [self.class setPreferenceSizeUpdates:region.regionId value:0];
        [self.class removeStatus:EOAWeatherForecastStatusUpdatesCalculated region:region];
        [self.class addStatus:EOAWeatherForecastStatusCalculating region:region];
    }
    else
    {
        [self.class setPreferenceSizeLocal:region.regionId value:0];

        if (calculateSizeLocal)
        {
            [self.class removeStatus:EOAWeatherForecastStatusLocalCalculated region:region];
            [self.class addStatus:EOAWeatherForecastStatusCalculating region:region];
        }
        else
        {
            if ([self.class hasStatus:EOAWeatherForecastStatusUpdatesCalculated region:region])
            {
                [self.class setPreferenceStatus:region.regionId value:EOAWeatherForecastStatusDownloading];
                [self.class addStatus:EOAWeatherForecastStatusUpdatesCalculated region:region];
            }
            else
            {
                [self.class setPreferenceStatus:region.regionId value:EOAWeatherForecastStatusDownloading];
            }
        }
    }
    [_weatherForecastDownloadingObserver notifyEventWithKey:self andValue:region];

    NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
    NSDate *date = [calendar startOfDayForDate:[NSDate date]];
    for (NSInteger i = 0; i < 7 * 24; i++)
    {
        QDateTime dateTime = QDateTime::fromNSDate(date).toUTC();

        if (calculateSizeLocal || calculateSizeUpdates)
        {
            OsmAnd::WeatherTileResourcesManager::FileRequest request;
            request.dataTime = dateTime;
            request.topLeft = latLonTopLeft;
            request.bottomRight = latLonBottomRight;
            request.localData = calculateSizeLocal;

            OsmAnd::WeatherTileResourcesManager::FileAsyncCallback callback =
                    [self, region, calculateSizeLocal, calculateSizeUpdates]
                            (const bool succeeded,
                             const long long fileSize,
                             const std::shared_ptr<OsmAnd::Metric> &metric)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self onProgressUpdate:region
                                              size:fileSize
                                calculateSizeLocal:calculateSizeLocal
                              calculateSizeUpdates:calculateSizeUpdates
                                           success:YES];
                        });
                    };

            _weatherResourcesManager->obtainFileAsync(request, callback);
        }
        else
        {
            std::shared_ptr<const OsmAnd::IQueryController> queryController;
            queryController.reset(new OsmAnd::FunctorQueryController(
                    [self, region]
                    (const OsmAnd::IQueryController* const controller) -> bool
                    {
                        return [self.class hasStatus:EOAWeatherForecastStatusUndefined region:region];
                    }
            ));

            OsmAnd::WeatherTileResourcesManager::DownloadGeoTileRequest request;
            request.dataTime = dateTime;
            request.topLeft = latLonTopLeft;
            request.bottomRight = latLonBottomRight;
            request.forceDownload = true;
            request.localData = true;
            request.queryController = queryController;

            OsmAnd::WeatherTileResourcesManager::DownloadGeoTilesAsyncCallback callback =
                    [self, region, calculateSizeLocal, calculateSizeUpdates]
                            (const bool succeeded,
                             const uint64_t downloadedTiles,
                             const uint64_t totalTiles,
                             const int downloadedTileSize,
                             const std::shared_ptr<OsmAnd::Metric> &metric)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self onProgressUpdate:region
                                              size:downloadedTileSize
                                calculateSizeLocal:calculateSizeLocal
                              calculateSizeUpdates:calculateSizeUpdates
                                           success:succeeded];
                            });
                    };

            _weatherResourcesManager->downloadGeoTilesAsync(request, callback);
        }

        date = [calendar dateByAddingUnit:NSCalendarUnitHour value:1 toDate:date options:0];
    }
}

- (void)calculateCacheSize:(BOOL)localData onComplete:(void (^)(unsigned long long size))onComplete
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager *fm = [NSFileManager defaultManager];
        unsigned long long size = 0;
        NSString *path = [_app.weatherForecastPath stringByAppendingPathComponent:localData ? @"offline" : @"online"];
        NSArray *cacheFilePaths = [fm contentsOfDirectoryAtPath:path error:nil];
        for (NSString *filePath in cacheFilePaths)
        {
            if ([filePath hasSuffix:@".raster.db"] || [filePath hasSuffix:@".tiff.db"])
                size += [[fm attributesOfItemAtPath:[path stringByAppendingPathComponent:filePath] error:nil] fileSize];
        }
        if (onComplete)
            onComplete(size);
    });
}

- (void)clearCache:(BOOL)localData
{
    _weatherResourcesManager->clearDbCache(localData);
    if (localData)
    {
        for (OAWorldRegion *region in _app.worldRegion.flattenedSubregions)
        {
            NSString *sizeUpdatesKey = [kWeatherForecastSizeUpdatesPrefix stringByAppendingString:region.regionId];
            NSString *tileIdsKey = [kWeatherForecastTileIdsPrefix stringByAppendingString:region.regionId];
            NSArray<NSString *> *excludeKeys = [self.class hasStatus:EOAWeatherForecastStatusUpdatesCalculated region:region] ? @[tileIdsKey, sizeUpdatesKey] : @[tileIdsKey];
            [self.class removePreferences:region.regionId excludeKeys:excludeKeys];
            [self removeOfflineRegion:region];
            if ([excludeKeys containsObject:sizeUpdatesKey])
                [self.class addStatus:EOAWeatherForecastStatusUpdatesCalculated region:region];
        }
    }

    OAMapViewController *mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    [mapViewController.mapLayers.weatherLayerLow updateWeatherLayer];
    [mapViewController.mapLayers.weatherLayerHigh updateWeatherLayer];
    [mapViewController.mapLayers.weatherContourLayer updateWeatherLayer];
}

- (void)clearOutdatedCache
{
    NSDate *date = [NSCalendar.autoupdatingCurrentCalendar startOfDayForDate:[NSDate date]];
    QDateTime dateTime = QDateTime::fromNSDate(date).toUTC();
    _weatherResourcesManager->clearDbCache(false, dateTime);
    _weatherResourcesManager->clearDbCache(true, dateTime);
    for (OAWorldRegion *region in _app.worldRegion.flattenedSubregions)
    {
        if (![self.class hasStatus:EOAWeatherForecastStatusUndefined region:region] && [self.class getPreferenceSizeLocal:region.regionId] > 0)
            [self calculateCacheSize:region localData:YES];
    }
}

- (void)removeLocalForecast:(OAWorldRegion *)region refreshMap:(BOOL)refreshMap
{
    NSString *sizeUpdatesKey = [kWeatherForecastSizeUpdatesPrefix stringByAppendingString:region.regionId];
    NSString *tileIdsKey = [kWeatherForecastTileIdsPrefix stringByAppendingString:region.regionId];
    NSArray<NSString *> *excludeKeys = [self.class hasStatus:EOAWeatherForecastStatusUpdatesCalculated region:region] ? @[tileIdsKey, sizeUpdatesKey] : @[tileIdsKey];
    [self.class removePreferences:region.regionId excludeKeys:excludeKeys];
    [self setOfflineRegion:region];
    if ([excludeKeys containsObject:sizeUpdatesKey])
        [self.class addStatus:EOAWeatherForecastStatusUpdatesCalculated region:region];

    NSArray<NSArray<NSNumber *> *> *tileIds = [self.class getPreferenceTileIds:region.regionId];
    QVector<OsmAnd::TileId> qTileIds;
    for (NSArray<NSNumber *> *tileId in tileIds)
    {
        if (![self isContainsInOfflineRegions:tileId excludeRegion:region])
        {
            OsmAnd::TileId qTileId = OsmAnd::TileId::fromXY([tileId.firstObject intValue], [tileId.lastObject intValue]);
            qTileIds.append(qTileId);
        }
    }

    OsmAnd::ZoomLevel zoom = OsmAnd::WeatherTileResourceProvider::getGeoTileZoom();
    if (!qTileIds.isEmpty())
        _weatherResourcesManager->clearLocalDbCache(qTileIds, zoom);

    if (refreshMap)
    {
        OAMapViewController *mapViewController = [OARootViewController instance].mapPanel.mapViewController;
        [mapViewController.mapLayers.weatherLayerLow updateWeatherLayer];
        [mapViewController.mapLayers.weatherLayerHigh updateWeatherLayer];
        [mapViewController.mapLayers.weatherContourLayer updateWeatherLayer];
    }
}

- (void)removeIncompleteForecast:(OAWorldRegion *)region
{
    [self.class removeStatus:EOAWeatherForecastStatusCalculating region:region];
    if ([self.class hasStatus:EOAWeatherForecastStatusDownloading region:region])
    {
        NSDate *dateChecked = [NSDate dateWithTimeIntervalSince1970:[OAWeatherHelper getPreferenceLastUpdate:region.regionId]];
        if ([dateChecked isEqualToDate:[NSDate dateWithTimeIntervalSince1970:-1]])
            [self removeLocalForecast:region refreshMap:NO];
    }
}

- (void)updatePreferences:(OAWorldRegion *)region
{
    NSInteger daysGone = 0;
    NSDate *dateChecked = [NSDate dateWithTimeIntervalSince1970:[self.class getPreferenceLastUpdate:region.regionId]];
    if (![dateChecked isEqualToDate:[NSDate dateWithTimeIntervalSince1970:-1]])
    {
        NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
        NSDate *dayNow = [calendar startOfDayForDate:[NSDate date]];
        daysGone = [calendar components:NSCalendarUnitDay fromDate:dateChecked toDate:dayNow options:0].day;
    }

    if (daysGone >= 1 && ([self.class hasStatus:EOAWeatherForecastStatusDownloaded region:region] || [self.class hasStatus:EOAWeatherForecastStatusOutdated region:region]))
    {
        [self calculateCacheSize:region localData:NO];
        [self calculateCacheSize:region localData:YES];
    }
    else
    {
        if ([self.class getPreferenceSizeUpdates:region.regionId] == 0)
            [self calculateCacheSize:region localData:NO];
        if ([self.class getPreferenceSizeLocal:region.regionId] == 0 && [self.class hasStatus:EOAWeatherForecastStatusDownloaded region:region])
            [self calculateCacheSize:region localData:YES];
    }

    if (daysGone >= 7 && [self.class hasStatus:EOAWeatherForecastStatusDownloaded region:region])
    {
        [self.class removeStatus:EOAWeatherForecastStatusDownloaded region:region];
        [self.class addStatus:EOAWeatherForecastStatusOutdated region:region];
    }
}

- (BOOL)isContainsInOfflineRegions:(NSArray<NSNumber *> *)tileId excludeRegion:(OAWorldRegion *)excludeRegion
{
    for (NSString *regionId in _offlineRegionsWithProgress.allKeys)
    {
        if (![regionId isEqualToString:excludeRegion.regionId])
        {
            NSArray<NSArray<NSNumber *> *> *offlineTileIds = [self.class getPreferenceTileIds:regionId];
            for (NSArray<NSNumber *> *offlineTileId in offlineTileIds)
            {
                if ([offlineTileId isEqualToArray:tileId])
                    return YES;
            }
        }
    }
    return NO;
}

- (void)setOfflineRegion:(OAWorldRegion *)region
{
    BOOL isDownloaded = [self.class hasStatus:EOAWeatherForecastStatusDownloaded region:region];
    BOOL isOutdated = [self.class hasStatus:EOAWeatherForecastStatusOutdated region:region];
    if (isDownloaded || isOutdated)
        [self setProgress:region value:0];
    else
        [self removeOfflineRegion:region];
}

- (NSArray<NSString *> *)getOfflineRegions
{
    return _offlineRegionsWithProgress.allKeys;
}

- (void)removeOfflineRegion:(OAWorldRegion *)region
{
    [_offlineRegionsWithProgress removeObjectForKey:region.regionId];
}

- (void)setProgress:(OAWorldRegion *)region value:(NSInteger)value
{
    _offlineRegionsWithProgress[region.regionId] = @(value);
}

- (NSInteger)getProgress:(OAWorldRegion *)region
{
    return [_offlineRegionsWithProgress.allKeys containsObject:region.regionId] ? [_offlineRegionsWithProgress[region.regionId] integerValue] : 0;
}

- (NSInteger)getProgressDestination:(OAWorldRegion *)region
{
    return [self.class getPreferenceTileIds:region.regionId].count * 7 * 24;
}

- (void)onProgressUpdate:(OAWorldRegion *)region
                    size:(NSInteger)size
      calculateSizeLocal:(BOOL)calculateSizeLocal
    calculateSizeUpdates:(BOOL)calculateSizeUpdates
                 success:(BOOL)success
{
    NSInteger progressDestination = [self getProgressDestination:region];
    if (calculateSizeLocal)
    {
        NSInteger progressCalculateSizeLocal = [self getProgress:region];
        [self setProgress:region value:++progressCalculateSizeLocal];
        CGFloat progress = (CGFloat) progressCalculateSizeLocal / progressDestination;

        NSInteger oldSizeLocal = [self.class getPreferenceSizeLocal:region.regionId];
        [self.class setPreferenceSizeLocal:region.regionId value:oldSizeLocal + size];

        if (progress == 1.)
        {
            [self.class removeStatus:EOAWeatherForecastStatusCalculating region:region];
            [self.class addStatus:EOAWeatherForecastStatusLocalCalculated region:region];
            [_weatherSizeLocalCalculateObserver notifyEventWithKey:self andValue:region];
        }
    }
    else if (calculateSizeUpdates)
    {
        NSInteger progressCalculateSizeUpdates = [self getProgress:region];
        [self setProgress:region value:++progressCalculateSizeUpdates];
        CGFloat progress = (CGFloat) progressCalculateSizeUpdates / progressDestination;

        NSInteger oldSizeUpdates = [self.class getPreferenceSizeUpdates:region.regionId];
        [self.class setPreferenceSizeUpdates:region.regionId value:oldSizeUpdates + size];

        if (progress == 1.)
        {
            [self.class removeStatus:EOAWeatherForecastStatusCalculating region:region];
            [self.class addStatus:EOAWeatherForecastStatusUpdatesCalculated region:region];
            [_weatherSizeUpdatesCalculateObserver notifyEventWithKey:self andValue:region];
        }
    }
    else
    {
        NSInteger progressDownloading = [self getProgress:region];
        [self setProgress:region value:++progressDownloading];
        CGFloat progress = (CGFloat) progressDownloading / progressDestination;

        NSInteger oldSizeLocal = [self.class getPreferenceSizeLocal:region.regionId];
        [self.class setPreferenceSizeLocal:region.regionId value:oldSizeLocal + size];

        OALog(@"Weather offline forecast download %@ : %f %@", region.regionId, progress, success ? @"done" : @"error");
        [_weatherForecastDownloadingObserver notifyEventWithKey:self andValue:region];

        if (progress == 1.)
        {
            [self.class setPreferenceStatus:region.regionId value:EOAWeatherForecastStatusDownloaded];
            [self.class addStatus:EOAWeatherForecastStatusLocalCalculated region:region];
            [self.class addStatus:EOAWeatherForecastStatusUpdatesCalculated region:region];
            NSTimeInterval timeInterval = [NSCalendar.autoupdatingCurrentCalendar startOfDayForDate:[NSDate date]].timeIntervalSince1970;
            [self.class setPreferenceLastUpdate:region.regionId value:timeInterval];
            [self setOfflineRegion:region];
            [_weatherForecastDownloadingObserver notifyEventWithKey:self andValue:region];

            OAMapViewController *mapViewController = [OARootViewController instance].mapPanel.mapViewController;
            [mapViewController.mapLayers.weatherLayerLow updateWeatherLayer];
            [mapViewController.mapLayers.weatherLayerHigh updateWeatherLayer];
            [mapViewController.mapLayers.weatherContourLayer updateWeatherLayer];
        }
    }
}

+ (OAResourceItem *)generateResourceItem:(OAWorldRegion *)region
{
    OAResourceItem *item;
    if ([self.class hasStatus:EOAWeatherForecastStatusUndefined region:region] || [self.class hasStatus:EOAWeatherForecastStatusDownloading region:region])
    {
        item = [[OARepositoryResourceItem alloc] init];
        item.date = [NSCalendar.autoupdatingCurrentCalendar startOfDayForDate:[NSDate date]];
    }
    else
    {
        if ([self.class hasStatus:EOAWeatherForecastStatusDownloaded region:region])
            item = [[OALocalResourceItem alloc] init];
        else
            item = [[OAOutdatedResourceItem alloc] init];

        item.date = [NSDate dateWithTimeIntervalSince1970:[self getPreferenceLastUpdate:region.regionId]];
    }
    if (item)
    {
        item.resourceId = QString::fromNSString([region.regionId stringByAppendingString:@"_weather_forecast"]);
        item.resourceType = OsmAndResourceType::WeatherForecast;
        item.title = OALocalizedString(@"weather_forecast");
        item.size = [self getPreferenceSizeLocal:region.regionId];
        item.sizePkg = [self getPreferenceSizeUpdates:region.regionId];
        item.worldRegion = region;
    }
    return item;
}


+ (BOOL)hasStatus:(NSInteger)status region:(OAWorldRegion *)region
{
    NSInteger regionStatus = [self getPreferenceStatus:region.regionId];
    regionStatus &= status;
    return regionStatus != 0;
}

+ (void)addStatus:(NSInteger)status region:(OAWorldRegion *)region
{
    NSInteger regionStatus = [self getPreferenceStatus:region.regionId];
    regionStatus |= status;
    [self setPreferenceStatus:region.regionId value:regionStatus];
}

+ (void)removeStatus:(NSInteger)status region:(OAWorldRegion *)region
{
    NSInteger regionStatus = [self getPreferenceStatus:region.regionId];
    regionStatus &= ~status;
    [self setPreferenceStatus:region.regionId value:regionStatus];
}

+ (NSInteger)getPreferenceStatus:(NSString *)regionId
{
    NSString *prefKey = [kWeatherForecastStatusPrefix stringByAppendingString:regionId];
    return [[NSUserDefaults standardUserDefaults] objectForKey:prefKey] ? [[NSUserDefaults standardUserDefaults] integerForKey:prefKey] : EOAWeatherForecastStatusUndefined;
}

+ (void)setPreferenceStatus:(NSString *)regionId value:(NSInteger)value
{
    NSString *prefKey = [kWeatherForecastStatusPrefix stringByAppendingString:regionId];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:prefKey];
}

+ (NSTimeInterval)getPreferenceLastUpdate:(NSString *)regionId
{
    NSString *prefKey = [kWeatherForecastLastUpdatePrefix stringByAppendingString:regionId];
    return [[NSUserDefaults standardUserDefaults] objectForKey:prefKey] ? [[NSUserDefaults standardUserDefaults] doubleForKey:prefKey] : -1.;
}

+ (void)setPreferenceLastUpdate:(NSString *)regionId value:(NSTimeInterval)value
{
    NSString *prefKey = [kWeatherForecastLastUpdatePrefix stringByAppendingString:regionId];
    [[NSUserDefaults standardUserDefaults] setDouble:value forKey:prefKey];
}

+ (EOAWeatherForecastUpdatesFrequency)getPreferenceFrequency:(NSString *)regionId
{
    NSString *prefKey = [kWeatherForecastFrequencyPrefix stringByAppendingString:regionId];
    return [[NSUserDefaults standardUserDefaults] objectForKey:prefKey] ? (EOAWeatherForecastUpdatesFrequency) [[NSUserDefaults standardUserDefaults] integerForKey:prefKey] : EOAWeatherForecastUpdatesUndefined;
}

+ (void)setPreferenceFrequency:(NSString *)regionId value:(EOAWeatherForecastUpdatesFrequency)value
{
    NSString *prefKey = [kWeatherForecastFrequencyPrefix stringByAppendingString:regionId];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:prefKey];
}

+ (NSInteger)getPreferenceSizeLocal:(NSString *)regionId
{
    NSString *prefKey = [kWeatherForecastSizeLocalPrefix stringByAppendingString:regionId];
    return [[NSUserDefaults standardUserDefaults] objectForKey:prefKey] ? [[NSUserDefaults standardUserDefaults] integerForKey:prefKey] : 0;
}

+ (void)setPreferenceSizeLocal:(NSString *)regionId value:(NSInteger)value
{
    NSString *prefKey = [kWeatherForecastSizeLocalPrefix stringByAppendingString:regionId];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:prefKey];
}

+ (NSInteger)getPreferenceSizeUpdates:(NSString *)regionId
{
    NSString *prefKey = [kWeatherForecastSizeUpdatesPrefix stringByAppendingString:regionId];
    return [[NSUserDefaults standardUserDefaults] objectForKey:prefKey] ? [[NSUserDefaults standardUserDefaults] integerForKey:prefKey] : 0;
}

+ (void)setPreferenceSizeUpdates:(NSString *)regionId value:(NSInteger)value
{
    NSString *prefKey = [kWeatherForecastSizeUpdatesPrefix stringByAppendingString:regionId];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:prefKey];
}

+ (NSArray<NSArray<NSNumber *> *> *)getPreferenceTileIds:(NSString *)regionId
{
    NSString *prefKey = [kWeatherForecastTileIdsPrefix stringByAppendingString:regionId];
    return [[NSUserDefaults standardUserDefaults] objectForKey:prefKey] ? [[NSUserDefaults standardUserDefaults] arrayForKey:prefKey] : @[];
}

+ (void)setPreferenceTileIds:(NSString *)regionId value:(NSArray<NSArray<NSNumber *> *> *)value
{
    NSString *prefKey = [kWeatherForecastTileIdsPrefix stringByAppendingString:regionId];
    [[NSUserDefaults standardUserDefaults] setObject:value forKey:prefKey];
}

+ (BOOL)getPreferenceWifi:(NSString *)regionId
{
    NSString *prefKey = [kWeatherForecastWifiPrefix stringByAppendingString:regionId];
    return [[NSUserDefaults standardUserDefaults] objectForKey:prefKey] ? [[NSUserDefaults standardUserDefaults] boolForKey:prefKey] : NO;
}

+ (void)setPreferenceWifi:(NSString *)regionId value:(BOOL)value
{
    NSString *prefKey = [kWeatherForecastWifiPrefix stringByAppendingString:regionId];
    [[NSUserDefaults standardUserDefaults] setBool:value forKey:prefKey];
}

+ (NSArray<NSString *> *)getPreferenceKeys:(NSString *)regionId
{
    return @[
        [kWeatherForecastStatusPrefix stringByAppendingString:regionId],
        [kWeatherForecastLastUpdatePrefix stringByAppendingString:regionId],
        [kWeatherForecastFrequencyPrefix stringByAppendingString:regionId],
        [kWeatherForecastSizeLocalPrefix stringByAppendingString:regionId],
        [kWeatherForecastSizeUpdatesPrefix stringByAppendingString:regionId],
        [kWeatherForecastTileIdsPrefix stringByAppendingString:regionId],
        [kWeatherForecastWifiPrefix stringByAppendingString:regionId]
    ];
}

+ (void)removePreferences:(NSString *)regionId excludeKeys:(NSArray<NSString *> *)excludeKeys
{
    NSArray<NSString *> *preferenceKeys = [self getPreferenceKeys:regionId];
    for (NSString *key in preferenceKeys)
    {
        if (![excludeKeys containsObject:key])
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
}

@end
