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
#import "OANativeUtilities.h"

#include <OsmAndCore/Map/WeatherTileResourceProvider.h>
#include <OsmAndCore/Map/WeatherTileResourcesManager.h>
#include <OsmAndCore/FunctorQueryController.h>

#define kWeatherForecastDownloadStatePrefix @"forecast_download_state_"
#define kWeatherForecastLastUpdatePrefix @"forecast_last_update_"
#define kWeatherForecastFrequencyPrefix @"forecast_frequency_"
#define kWeatherForecastTileIdsPrefix @"forecast_tile_ids_"
#define kWeatherForecastWifiPrefix @"forecast_download_via_wifi_"

#define kTileSize 40000
#define kForecastDatesCount (24 + (6 * 8) + 1)

@implementation OAWeatherHelper
{
    OsmAndAppInstance _app;
    std::shared_ptr<OsmAnd::WeatherTileResourcesManager> _weatherResourcesManager;
    NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *_offlineForecastsInfo;
}

@synthesize weatherSizeCalculatedObserver = _weatherSizeCalculatedObserver;
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
        _offlineForecastsInfo = [NSMutableDictionary dictionary];

        _bands = @[
            [OAWeatherBand withWeatherBand:WEATHER_BAND_TEMPERATURE],
            [OAWeatherBand withWeatherBand:WEATHER_BAND_PRESSURE],
            [OAWeatherBand withWeatherBand:WEATHER_BAND_WIND_SPEED],
            [OAWeatherBand withWeatherBand:WEATHER_BAND_CLOUD],
            [OAWeatherBand withWeatherBand:WEATHER_BAND_PRECIPITATION]
        ];

        _weatherSizeCalculatedObserver = [[OAObservable alloc] init];
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
    OsmAnd::LatLon latLonTopLeft = OsmAnd::LatLon(region.bboxTopLeft.latitude, region.bboxTopLeft.longitude);
    OsmAnd::LatLon latLonBottomRight = OsmAnd::LatLon(region.bboxBottomRight.latitude, region.bboxBottomRight.longitude);
    OsmAnd::ZoomLevel zoom = OsmAnd::WeatherTileResourceProvider::getGeoTileZoom();

    [self.class updatePreferenceTileIdsIfNeeded:region];

    [self setOfflineForecastProgressInfo:region.regionId value:0];
    [self.class setPreferenceDownloadState:region.regionId value:EOAWeatherForecastDownloadStateInProgress];
    [_weatherForecastDownloadingObserver notifyEventWithKey:self andValue:region];

    std::shared_ptr<const OsmAnd::IQueryController> queryController;
    queryController.reset(new OsmAnd::FunctorQueryController(
            [self, region]
            (const OsmAnd::IQueryController *const controller) -> bool
            {
                return [self.class getPreferenceDownloadState:region.regionId] == EOAWeatherForecastDownloadStateUndefined;
            }
    ));

    NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
    calendar.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    NSDate *date = [calendar startOfDayForDate:[NSDate date]];
    for (NSInteger i = 0; i < kForecastDatesCount; i++)
    {
        QDateTime dateTime = QDateTime::fromNSDate(date).toUTC();

        OsmAnd::WeatherTileResourcesManager::DownloadGeoTileRequest request;
        request.dataTime = dateTime;
        request.topLeft = latLonTopLeft;
        request.bottomRight = latLonBottomRight;
        request.forceDownload = true;
        request.localData = true;
        request.queryController = queryController;

        OsmAnd::WeatherTileResourcesManager::DownloadGeoTilesAsyncCallback callback =
                [self, region]
                (const bool succeeded,
                        const uint64_t downloadedTiles,
                        const uint64_t totalTiles,
                        const std::shared_ptr<OsmAnd::Metric> &metric)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self onProgressUpdate:region
                                       success:succeeded];
                    });
                };

        _weatherResourcesManager->downloadGeoTilesAsync(request, callback);

        date = [calendar dateByAddingUnit:NSCalendarUnitHour value:(i < 24 ? 1 : 3) toDate:date options:0];
    }
}

- (void)calculateCacheSize:(OAWorldRegion *)region
{
    [self setOfflineForecastSizeInfo:region.regionId value:0 local:YES];
    [self setOfflineForecastSizeInfo:region.regionId value:0 local:NO];
    [self setOfflineForecastSizesInfoCalculated:region.regionId value:NO];

    [self.class updatePreferenceTileIdsIfNeeded:region];

    [_weatherForecastDownloadingObserver notifyEventWithKey:self andValue:region];

    NSArray<NSArray<NSNumber *> *> *tileIds = [self.class getPreferenceTileIds:region.regionId];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        QList<OsmAnd::TileId> qTileIds = [OANativeUtilities convertToQListTileIds:tileIds];
        OsmAnd::ZoomLevel zoom = OsmAnd::WeatherTileResourceProvider::getGeoTileZoom();
        if (!qTileIds.isEmpty())
        {
            [self setOfflineForecastSizeInfo:region.regionId
                                       value:_weatherResourcesManager->calculateDbCacheSize(qTileIds, QList<OsmAnd::TileId>(), zoom)
                                       local:YES];
            [self setOfflineForecastSizeInfo:region.regionId
                                       value:kTileSize * tileIds.count * kForecastDatesCount
                                       local:NO];
            [self setOfflineForecastSizesInfoCalculated:region.regionId value:YES];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [_weatherSizeCalculatedObserver notifyEventWithKey:self andValue:region];
        });
    });
}

- (void)calculateFullCacheSize:(BOOL)localData
                    onComplete:(void (^)(unsigned long long))onComplete
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        QList<OsmAnd::TileId> qTileIds = [OANativeUtilities convertToQListTileIds:[self getOfflineTileIds]];
        OsmAnd::ZoomLevel zoom = OsmAnd::WeatherTileResourceProvider::getGeoTileZoom();;
        unsigned long long size = 0;
        if (!localData || (localData && !qTileIds.isEmpty()))
        {
            size = _weatherResourcesManager->calculateDbCacheSize(
                    localData ? qTileIds : QList<OsmAnd::TileId>(),
                    localData ? QList<OsmAnd::TileId>() : qTileIds,
                    zoom);
        }

        if (onComplete)
            onComplete(size);
    });
}

- (void)clearCache:(BOOL)localData
{
    QList<OsmAnd::TileId> qTileIds = [OANativeUtilities convertToQListTileIds:[self getOfflineTileIds]];
    OsmAnd::ZoomLevel zoom = OsmAnd::WeatherTileResourceProvider::getGeoTileZoom();
    _weatherResourcesManager->clearDbCache(
            localData ? qTileIds : QList<OsmAnd::TileId>(),
            localData ? QList<OsmAnd::TileId>() : qTileIds,
            zoom);

    if (localData)
    {
        for (NSString *regionId in [self getOfflineForecastsRegionIds])
        {
            NSString *tileIdsKey = [kWeatherForecastTileIdsPrefix stringByAppendingString:regionId];
            NSArray<NSString *> *excludeKeys = @[tileIdsKey];
            [self.class removePreferences:regionId excludeKeys:excludeKeys];
            [self removeOfflineForecastInfo:regionId];
        }
    }

    OAMapViewController *mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    [mapViewController.mapLayers.weatherLayerLow updateWeatherLayer];
    [mapViewController.mapLayers.weatherLayerHigh updateWeatherLayer];
    [mapViewController.mapLayers.weatherContourLayer updateWeatherLayer];
}

- (void)clearOutdatedCache
{
    NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
    calendar.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    NSDate *date = [calendar startOfDayForDate:[NSDate date]];
    QDateTime dateTime = QDateTime::fromNSDate(date).toUTC();
    _weatherResourcesManager->clearDbCache(dateTime);
}

- (void)removeLocalForecast:(OAWorldRegion *)region refreshMap:(BOOL)refreshMap
{
    NSMutableArray<NSArray<NSNumber *> *> *tileIds = [NSMutableArray arrayWithArray:[self.class getPreferenceTileIds:region.regionId]];
    [tileIds enumerateObjectsUsingBlock:^(NSArray<NSNumber *> *tileId, NSUInteger idx, BOOL * stop) {
        if ([self isContainsInOfflineRegions:tileId excludeRegion:region])
            [tileIds removeObject:tileId];
    }];
    QList<OsmAnd::TileId> qTileIds = [OANativeUtilities convertToQListTileIds:tileIds];
    OsmAnd::ZoomLevel zoom = OsmAnd::WeatherTileResourceProvider::getGeoTileZoom();
    if (!qTileIds.isEmpty())
        _weatherResourcesManager->clearDbCache(qTileIds, QList<OsmAnd::TileId>(), zoom);

    NSString *tileIdsKey = [kWeatherForecastTileIdsPrefix stringByAppendingString:region.regionId];
    [self.class removePreferences:region.regionId excludeKeys:@[tileIdsKey]];
    [self removeOfflineForecastInfo:region.regionId];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (refreshMap)
        {
            OAMapViewController *mapViewController = [OARootViewController instance].mapPanel.mapViewController;
            [mapViewController.mapLayers.weatherLayerLow updateWeatherLayer];
            [mapViewController.mapLayers.weatherLayerHigh updateWeatherLayer];
            [mapViewController.mapLayers.weatherContourLayer updateWeatherLayer];
        }
    });
}

- (NSArray<NSArray<NSNumber *> *> *)getOfflineTileIds
{
    NSMutableArray<NSArray<NSNumber *> *> *offlineTileIds = [NSMutableArray array];
    for (NSString *regionId in [self getOfflineForecastsRegionIds])
    {
        NSArray<NSArray<NSNumber *> *> *regionTileIds = [self.class getPreferenceTileIds:regionId];
        for (NSArray<NSNumber *> *tileId in regionTileIds)
        {
            if (![offlineTileIds containsObject:tileId])
                [offlineTileIds addObject:tileId];
        }
    }
    return offlineTileIds;
}

+ (BOOL)isForecastOutdated:(NSString *)regionId
{
    if ([self getPreferenceDownloadState:regionId] == EOAWeatherForecastDownloadStateFinished)
    {
        NSInteger daysGone = 0;
        NSTimeInterval timeInterval = [self.class getPreferenceLastUpdate:regionId];
        if (timeInterval != -1)
        {
            NSDate *dateChecked = [NSDate dateWithTimeIntervalSince1970:timeInterval];
            NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
            calendar.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
            NSDate *dayNow = [calendar startOfDayForDate:[NSDate date]];
            daysGone = [calendar components:NSCalendarUnitDay fromDate:dateChecked toDate:dayNow options:0].day;
            return daysGone >= 7;
        }
    }
    return NO;
}

- (void)firstInitForecast:(OAWorldRegion *)region
{
    EOAWeatherForecastDownloadState downloadState = [self.class getPreferenceDownloadState:region.regionId];
    if (downloadState == EOAWeatherForecastDownloadStateInProgress)
    {
        NSDate *dateChecked = [NSDate dateWithTimeIntervalSince1970:[self.class getPreferenceLastUpdate:region.regionId]];
        if ([dateChecked isEqualToDate:[NSDate dateWithTimeIntervalSince1970:-1]])
            [self removeLocalForecast:region refreshMap:NO];
    }
    else if (downloadState == EOAWeatherForecastDownloadStateFinished)
    {
        [self setOfflineForecastProgressInfo:region.regionId value:[self getProgressDestination:region]];
    }
}

- (BOOL)isContainsInOfflineRegions:(NSArray<NSNumber *> *)tileId excludeRegion:(OAWorldRegion *)excludeRegion
{
    for (NSString *regionId in [self getOfflineForecastsRegionIds])
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

- (NSArray<NSString *> *)getOfflineForecastsRegionIds
{
    return _offlineForecastsInfo.allKeys;
}

- (void)removeOfflineForecastInfo:(NSString *)regionId
{
    [_offlineForecastsInfo removeObjectForKey:regionId];
}

- (void)setOfflineForecastSizeInfo:(NSString *)regionId value:(uint64_t)value local:(BOOL)local
{
    NSMutableDictionary<NSString *, id> *forecastInfo = _offlineForecastsInfo[regionId];
    if (!forecastInfo)
    {
        forecastInfo = [NSMutableDictionary dictionary];
        _offlineForecastsInfo[regionId] = forecastInfo;
    }
    forecastInfo[local ? @"local_size" : @"updates_size"] = @(value);
}

- (uint64_t)getOfflineForecastSizeInfo:(NSString *)regionId local:(BOOL)local
{
    NSMutableDictionary<NSString *, id> *forecastInfo = _offlineForecastsInfo[regionId];
    if (forecastInfo && ((local && [forecastInfo.allKeys containsObject:@"local_size"]) || (!local && [forecastInfo.allKeys containsObject:@"updates_size"])))
        return [forecastInfo[local ? @"local_size" : @"updates_size"] unsignedLongLongValue];

    return 0;
}

- (void)setOfflineForecastSizesInfoCalculated:(NSString *)regionId value:(BOOL)value
{
    NSMutableDictionary<NSString *, id> *forecastInfo = _offlineForecastsInfo[regionId];
    if (!forecastInfo)
    {
        forecastInfo = [NSMutableDictionary dictionary];
        _offlineForecastsInfo[regionId] = forecastInfo;
    }
    forecastInfo[@"sizes_calculated"] = @(value);
}

- (BOOL)isOfflineForecastSizesInfoCalculated:(NSString *)regionId
{
    NSMutableDictionary<NSString *, id> *forecastInfo = _offlineForecastsInfo[regionId];
    if (forecastInfo && [forecastInfo.allKeys containsObject:@"sizes_calculated"])
        return [forecastInfo[@"sizes_calculated"] boolValue];

    return YES;
}

- (void)setOfflineForecastProgressInfo:(NSString *)regionId value:(NSInteger)value
{
    NSMutableDictionary<NSString *, id> *forecastInfo = _offlineForecastsInfo[regionId];
    if (!forecastInfo)
    {
        forecastInfo = [NSMutableDictionary dictionary];
        _offlineForecastsInfo[regionId] = forecastInfo;
    }
    forecastInfo[@"progress_download"] = @(value);
}

- (NSInteger)getOfflineForecastProgressInfo:(OAWorldRegion *)region
{
    NSMutableDictionary<NSString *, id> *forecastInfo = _offlineForecastsInfo[region.regionId];
    if (forecastInfo && [forecastInfo.allKeys containsObject:@"progress_download"])
    {
        return [forecastInfo[@"progress_download"] integerValue];
    }

    return 0;
}

- (NSInteger)getProgressDestination:(OAWorldRegion *)region
{
    return [self.class getPreferenceTileIds:region.regionId].count * kForecastDatesCount;
}

- (void)onProgressUpdate:(OAWorldRegion *)region
                 success:(BOOL)success
{
    NSInteger progressDestination = [self getProgressDestination:region];
    NSInteger progressDownloading = [self getOfflineForecastProgressInfo:region];
    [self setOfflineForecastProgressInfo:region.regionId value:++progressDownloading];
    CGFloat progress = (CGFloat) progressDownloading / progressDestination;

    OALog(@"Weather offline forecast download %@ : %f %@", region.regionId, progress, success ? @"done" : @"error");
    [_weatherForecastDownloadingObserver notifyEventWithKey:self andValue:region];

    if (progress == 1.)
    {
        [self.class setPreferenceDownloadState:region.regionId value:EOAWeatherForecastDownloadStateFinished];
        NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
        calendar.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        NSTimeInterval timeInterval = [calendar startOfDayForDate:[NSDate date]].timeIntervalSince1970;
        [self.class setPreferenceLastUpdate:region.regionId value:timeInterval];
        [_weatherForecastDownloadingObserver notifyEventWithKey:self andValue:region];

        OAMapViewController *mapViewController = [OARootViewController instance].mapPanel.mapViewController;
        [mapViewController.mapLayers.weatherLayerLow updateWeatherLayer];
        [mapViewController.mapLayers.weatherLayerHigh updateWeatherLayer];
        [mapViewController.mapLayers.weatherContourLayer updateWeatherLayer];

        [self calculateCacheSize:region];
    }
}

- (OAResourceItem *)generateResourceItem:(OAWorldRegion *)region
{
    OAResourceItem *item;
    if ([self.class getPreferenceDownloadState:region.regionId] == EOAWeatherForecastDownloadStateUndefined
            || [self.class getPreferenceDownloadState:region.regionId] == EOAWeatherForecastDownloadStateInProgress)
    {
        item = [[OARepositoryResourceItem alloc] init];
        NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
        calendar.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        item.date = [calendar startOfDayForDate:[NSDate date]];
    }
    else
    {
        if ([self.class getPreferenceDownloadState:region.regionId] == EOAWeatherForecastDownloadStateFinished)
            item = [[OALocalResourceItem alloc] init];
        else
            item = [[OAOutdatedResourceItem alloc] init];

        item.date = [NSDate dateWithTimeIntervalSince1970:[self.class getPreferenceLastUpdate:region.regionId]];
    }
    if (item)
    {
        item.resourceId = QString::fromNSString([region.regionId stringByAppendingString:@"_weather_forecast"]);
        item.resourceType = OsmAndResourceType::WeatherForecast;
        item.title = OALocalizedString(@"weather_forecast");
        item.size = [self getOfflineForecastSizeInfo:region.regionId local:YES];
        item.sizePkg = [self getOfflineForecastSizeInfo:region.regionId local:NO];
        item.worldRegion = region;
    }
    return item;
}

+ (EOAWeatherForecastDownloadState)getPreferenceDownloadState:(NSString *)regionId
{
    NSString *prefKey = [kWeatherForecastDownloadStatePrefix stringByAppendingString:regionId];
    return [[NSUserDefaults standardUserDefaults] objectForKey:prefKey]
            ? (EOAWeatherForecastDownloadState) [[NSUserDefaults standardUserDefaults] integerForKey:prefKey]
            : EOAWeatherForecastDownloadStateUndefined;
}

+ (void)setPreferenceDownloadState:(NSString *)regionId value:(EOAWeatherForecastDownloadState)value
{
    NSString *prefKey = [kWeatherForecastDownloadStatePrefix stringByAppendingString:regionId];
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

+ (void)updatePreferenceTileIdsIfNeeded:(OAWorldRegion *)region
{
    OsmAnd::LatLon latLonTopLeft = OsmAnd::LatLon(region.bboxTopLeft.latitude, region.bboxTopLeft.longitude);
    OsmAnd::LatLon latLonBottomRight = OsmAnd::LatLon(region.bboxBottomRight.latitude, region.bboxBottomRight.longitude);
    OsmAnd::ZoomLevel zoom = OsmAnd::WeatherTileResourceProvider::getGeoTileZoom();

    if ([self getPreferenceTileIds:region.regionId].count == 0)
    {
        QVector<OsmAnd::TileId> qTileIds = OsmAnd::WeatherTileResourcesManager::generateGeoTileIds(latLonTopLeft, latLonBottomRight, zoom);
        NSMutableArray<NSArray<NSNumber *> *> *tileIds = [NSMutableArray array];
        for (auto &qTileId: qTileIds)
        {
            [tileIds addObject:@[@(qTileId.x), @(qTileId.y)]];
        }
        [self setPreferenceTileIds:region.regionId value:tileIds];
    }
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
        [kWeatherForecastDownloadStatePrefix stringByAppendingString:regionId],
        [kWeatherForecastLastUpdatePrefix stringByAppendingString:regionId],
        [kWeatherForecastFrequencyPrefix stringByAppendingString:regionId],
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
