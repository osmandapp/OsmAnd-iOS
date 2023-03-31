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
#import "OAIAPHelper.h"
#import "OAWeatherPlugin.h"
#import "OAColors.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>

#include <OsmAndCore/Map/WeatherTileResourceProvider.h>
#include <OsmAndCore/Map/WeatherTileResourcesManager.h>
#include <OsmAndCore/FunctorQueryController.h>
#include <OsmAndCore/WorldRegions.h>
#include <qqueue.h>

#define kWeatherForecastDownloadStatePrefix @"forecast_download_state_"
#define kWeatherForecastLastUpdatePrefix @"forecast_last_update_"
#define kWeatherForecastFrequencyPrefix @"forecast_frequency_"
#define kWeatherForecastTileIdsPrefix @"forecast_tile_ids_"
#define kWeatherForecastWifiPrefix @"forecast_download_via_wifi_"

#define kTileSize 40000
#define kForecastDatesCount (24 + (6 * 8) + 1)

#define kSimultaneousTasksLimit 30

#define kWeatherForecastFrequencyHalfDay 43200
#define kWeatherForecastFrequencyDay 86400
#define kWeatherForecastFrequencyWeek 604800

@implementation OAWeatherHelper
{
    OsmAndAppInstance _app;
    std::shared_ptr<OsmAnd::WeatherTileResourcesManager> _weatherResourcesManager;
    NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *_offlineForecastsInfo;
    dispatch_queue_t _forecastSerialDownloader;
    dispatch_group_t _forecastGroupDownloader;
    
    QMutex _downloadsLock;
    QHash<QString, QQueue<OsmAnd::WeatherTileResourcesManager::DownloadGeoTileRequest>> _requestsByRegion;
    QHash<QString, int> _activeDownloadsByRegion;
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
        _forecastSerialDownloader = dispatch_queue_create("forecast_downloader", DISPATCH_QUEUE_SERIAL);
        _forecastGroupDownloader = dispatch_group_create();

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

        auto settings = std::make_shared<const OsmAnd::GeoBandSettings>(
            QString::fromNSString([band getBandUnit].symbol),
            QString::fromNSString([band getBandGeneralUnitFormat]),
            QString::fromNSString([band getBandPreciseUnitFormat]),
            QString::fromNSString([band getInternalBandUnit]),
            [band getBandOpacity],
            QString::fromNSString([band getColorFilePath]),
            contourStyleName,
            contourLevelsMap
        );
        result.insert((OsmAnd::BandIndex)band.bandIndex, settings);
    }
    return result;
}

+ (BOOL)shouldHaveWeatherForecast:(OAWorldRegion *)region
{
    NSString *regionId = [self.class checkAndGetRegionId:region];
    NSString *unitedKingdomRegionId = [NSString stringWithFormat:@"%@_gb", OsmAnd::WorldRegions::EuropeRegionId.toNSString()];
    NSString *russiaRegionId = OsmAnd::WorldRegions::RussiaRegionId.toNSString();
    NSInteger level = [region getLevel];
    return [regionId isEqualToString:kWeatherEntireWorldRegionId]
            || (level == 1 && [regionId isEqualToString:russiaRegionId])
            || (level > 1 && ![regionId hasPrefix:russiaRegionId]
            && ((level == 2 && ![regionId hasPrefix:unitedKingdomRegionId])
            || (level == 3 && [regionId hasPrefix:unitedKingdomRegionId])));
}

+ (NSString *)checkAndGetRegionId:(OAWorldRegion *)region
{
    return region.regionId == nil ? kWeatherEntireWorldRegionId : region.regionId;
}

+ (NSString *)checkAndGetRegionName:(OAWorldRegion *)region
{
    return region.regionId == nil ? OALocalizedString(@"weather_entire_world") : region.name;
}

- (void)checkAndDownloadForecastsByRegionIds:(NSArray<NSString *> *)regionIds
{
    AFNetworkReachabilityManager *networkManager = [AFNetworkReachabilityManager sharedManager];
    if (!networkManager.isReachable)
        return;

    NSInteger forecastsDownloading = 0;
    for (OAWorldRegion *region in [@[_app.worldRegion] arrayByAddingObjectsFromArray:_app.worldRegion.flattenedSubregions])
    {
        NSString *regionId = [self.class checkAndGetRegionId:region];
        if ([regionIds containsObject:regionId])
        {
            forecastsDownloading++;
            if (!networkManager.isReachableViaWiFi && [self.class getPreferenceWifi:regionId])
                continue;

            NSTimeInterval lastUpdateTime = [self.class getPreferenceLastUpdate:regionId];
            NSTimeInterval nowTime = [NSDate date].timeIntervalSince1970;
            EOAWeatherForecastUpdatesFrequency updateFrequency = [self.class getPreferenceFrequency:regionId];
            int secondsRequired = updateFrequency == EOAWeatherForecastUpdatesSemiDaily ? kWeatherForecastFrequencyHalfDay
                    : updateFrequency == EOAWeatherForecastUpdatesDaily ? kWeatherForecastFrequencyDay
                            : kWeatherForecastFrequencyWeek;
            if (nowTime >= lastUpdateTime + secondsRequired)
                [self downloadForecastByRegion:region];
        }

        if (forecastsDownloading == regionIds.count)
            break;
    }
}

- (void)downloadForecastsByRegionIds:(NSArray<NSString *> *)regionIds;
{
    NSInteger forecastsDownloading = 0;
    for (OAWorldRegion *region in [@[_app.worldRegion] arrayByAddingObjectsFromArray:_app.worldRegion.flattenedSubregions])
    {
        if ([regionIds containsObject:[self.class checkAndGetRegionId:region]])
        {
            [self downloadForecastByRegion:region];
            forecastsDownloading++;
        }

        if (forecastsDownloading == regionIds.count)
            break;
    }
}

- (void)downloadForecastByRegion:(OAWorldRegion *)region
{
    if (![[OAPlugin getPlugin:OAWeatherPlugin.class] isEnabled] || ![OAIAPHelper isOsmAndProAvailable])
        return;

    NSString *regionId = [self.class checkAndGetRegionId:region];

    AFNetworkReachabilityManager *networkManager = [AFNetworkReachabilityManager sharedManager];
    if (!networkManager.isReachable)
        return;
    else if (!networkManager.isReachableViaWiFi && [self.class getPreferenceWifi:regionId])
        return;

    BOOL isEntireWorld = [regionId isEqualToString:kWeatherEntireWorldRegionId];
    OsmAnd::LatLon latLonTopLeft = OsmAnd::LatLon(isEntireWorld ? 90. : region.bboxTopLeft.latitude, isEntireWorld ? -180. : region.bboxTopLeft.longitude);
    OsmAnd::LatLon latLonBottomRight = OsmAnd::LatLon(isEntireWorld ? -90. : region.bboxBottomRight.latitude, isEntireWorld ? 180. : region.bboxBottomRight.longitude);

    [self.class updatePreferenceTileIdsIfNeeded:region];

    [self setOfflineForecastProgressInfo:regionId value:0];
    [self.class setPreferenceDownloadState:regionId value:EOAWeatherForecastDownloadStateInProgress];
    [_weatherForecastDownloadingObserver notifyEventWithKey:self andValue:region];

    std::shared_ptr<const OsmAnd::IQueryController> queryController;
    queryController.reset(new OsmAnd::FunctorQueryController(
            [self, regionId]
            (const OsmAnd::IQueryController *const controller) -> bool
            {
                return [self.class getPreferenceDownloadState:regionId] != EOAWeatherForecastDownloadStateInProgress;
            }
    ));

    dispatch_block_t forecastDownload = ^{
        dispatch_group_wait(_forecastGroupDownloader, DISPATCH_TIME_FOREVER);
        dispatch_group_enter(_forecastGroupDownloader);

        NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
        calendar.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        NSDate *date = [calendar startOfDayForDate:[NSDate date]];
        QQueue<OsmAnd::WeatherTileResourcesManager::DownloadGeoTileRequest> requests;
        for (NSInteger i = 0; i < kForecastDatesCount; i++)
        {
            int64_t dateTime = date.timeIntervalSince1970 * 1000;

            OsmAnd::WeatherTileResourcesManager::DownloadGeoTileRequest request;
            request.dateTime = dateTime;
            request.topLeft = latLonTopLeft;
            request.bottomRight = latLonBottomRight;
            request.forceDownload = true;
            request.localData = true;
            request.queryController = queryController;
            requests.enqueue(request);
            
            date = [calendar dateByAddingUnit:NSCalendarUnitHour value:(i < 24 ? 1 : 3) toDate:date options:0];
        }
        const auto regionId = QString::fromNSString(region.regionId);
        _requestsByRegion[regionId] = requests;
        _activeDownloadsByRegion[regionId] = 0;
        
        for (NSInteger i = 0; i < kSimultaneousTasksLimit; i++)
        {
            [self enqueTask:region];
        }
    };

    dispatch_group_notify(_forecastGroupDownloader, _forecastSerialDownloader, ^{
        dispatch_async(_forecastSerialDownloader, forecastDownload);
    });
}

- (void) enqueTask:(OAWorldRegion *)region
{
    QMutexLocker scopedLocker(&_downloadsLock);
    const auto regionId = QString::fromNSString(region.regionId);
    auto &requests = _requestsByRegion[regionId];
    int activeDownloads = _activeDownloadsByRegion[regionId];
    if (activeDownloads < kSimultaneousTasksLimit && !requests.isEmpty())
    {
        activeDownloads += 1;
        const auto &request = requests.dequeue();
        if (request.queryController->isAborted())
        {
            requests.clear();
            _activeDownloadsByRegion[regionId] = 0;
            return;
        }
        OsmAnd::WeatherTileResourcesManager::DownloadGeoTilesAsyncCallback callback =
                [self, region]
                (bool succeeded,
                 const uint64_t downloadedTiles,
                 const uint64_t totalTiles,
                 const std::shared_ptr<OsmAnd::Metric> &metric)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self onProgressUpdate:region success:succeeded];
                    });
                    if (downloadedTiles == totalTiles)
                    {
                        const auto regId = QString::fromNSString(region.regionId);
                        int activeDownloads = _activeDownloadsByRegion[regId];
                        activeDownloads -= 1;
                        _activeDownloadsByRegion[regId] = activeDownloads;
                        [self enqueTask:region];
                    }
                };
        _weatherResourcesManager->downloadGeoTilesAsync(request, callback);
        _activeDownloadsByRegion[regionId] = activeDownloads;
    }
    else if (requests.isEmpty())
    {
        _requestsByRegion.remove(regionId);
        _activeDownloadsByRegion.remove(regionId);
    }
}

- (void)prepareToStopDownloading:(NSString *)regionId
{
    _offlineCacheSize = 0.;
    if ([self.class getPreferenceDownloadState:regionId] == EOAWeatherForecastDownloadStateFinished)
    {
        return;
    }
    else if ([self.class getPreferenceDownloadState:regionId] == EOAWeatherForecastDownloadStateInProgress)
    {
        if ([self getOfflineForecastProgressInfo:regionId] > 0)
            dispatch_group_leave(_forecastGroupDownloader);

        [self.class setPreferenceDownloadState:regionId value:EOAWeatherForecastDownloadStateUndefined];
        if ([self.class getPreferenceLastUpdate:regionId] == -1)
        {
            [self removeOfflineForecastInfo:regionId];
        }
        else
        {
            [self.class setPreferenceDownloadState:regionId value:EOAWeatherForecastDownloadStateFinished];
            [self setOfflineForecastProgressInfo:regionId value:[self getProgressDestination:regionId]];
        }
    }
}

- (void)calculateCacheSize:(OAWorldRegion *)region onComplete:(void (^)())onComplete
{
    NSString *regionId = [self.class checkAndGetRegionId:region];
    [self setOfflineForecastSizeInfo:regionId value:0 local:YES];
    [self setOfflineForecastSizeInfo:regionId value:0 local:NO];
    [self setOfflineForecastSizesInfoCalculated:regionId value:NO];
    [self.class updatePreferenceTileIdsIfNeeded:region];

    NSArray<NSArray<NSNumber *> *> *tileIds = [self.class getPreferenceTileIds:regionId];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        QList<OsmAnd::TileId> qTileIds = [OANativeUtilities convertToQListTileIds:tileIds];
        OsmAnd::ZoomLevel zoom = OsmAnd::WeatherTileResourceProvider::getGeoTileZoom();
        if (!qTileIds.isEmpty())
        {
            [self setOfflineForecastSizeInfo:regionId
                                       value:_weatherResourcesManager->calculateDbCacheSize(qTileIds, QList<OsmAnd::TileId>(), zoom)
                                       local:YES];
            [self setOfflineForecastSizeInfo:regionId
                                       value:kTileSize * tileIds.count * kForecastDatesCount
                                       local:NO];
            [self setOfflineForecastSizesInfoCalculated:regionId value:YES];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [_weatherSizeCalculatedObserver notifyEventWithKey:self andValue:region];
            if (onComplete)
                onComplete();
        });
    });
}

- (void)calculateFullCacheSize:(BOOL)localData
                    onComplete:(void (^)(unsigned long long))onComplete
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        QList<OsmAnd::TileId> qTileIds = [OANativeUtilities convertToQListTileIds:[self getOfflineTileIds:nil]];
        OsmAnd::ZoomLevel zoom = OsmAnd::WeatherTileResourceProvider::getGeoTileZoom();;
        unsigned long long size = localData ? self.offlineCacheSize : self.onlineCacheSize;
        if (size == 0 && (!localData || (localData && !qTileIds.isEmpty())))
        {
            size = _weatherResourcesManager->calculateDbCacheSize(
                    localData ? qTileIds : QList<OsmAnd::TileId>(),
                    localData ? QList<OsmAnd::TileId>() : qTileIds,
                    zoom);

            if (localData)
                _offlineCacheSize = size;
            else
                _onlineCacheSize = size;
        }

        if (onComplete)
            onComplete(size);
    });
}

- (void)clearCache:(BOOL)localData regionIds:(NSArray<NSString *> *)regionIds
{
    if (localData)
    {
        if (!regionIds)
        {
            regionIds = [self getTempForecastsWithDownloadStates:@[
                    @(EOAWeatherForecastDownloadStateInProgress),
                    @(EOAWeatherForecastDownloadStateFinished)
            ]];
        }

        for (NSString *regionId in regionIds)
        {
            [self setOfflineForecastSizeInfo:regionId value:0 local:YES];
            [self prepareToStopDownloading:regionId];
        }
    }
    _onlineCacheSize = 0.;

    QList<OsmAnd::TileId> qTileIds = [OANativeUtilities convertToQListTileIds:[self getOfflineTileIds:regionIds]];
    OsmAnd::ZoomLevel zoom = OsmAnd::WeatherTileResourceProvider::getGeoTileZoom();
    _weatherResourcesManager->clearDbCache(
            localData ? qTileIds : QList<OsmAnd::TileId>(),
            localData ? QList<OsmAnd::TileId>() : qTileIds,
            zoom);

    dispatch_async(dispatch_get_main_queue(), ^{
        OAMapViewController *mapViewController = [OARootViewController instance].mapPanel.mapViewController;
        [mapViewController.mapLayers.weatherLayerLow updateWeatherLayer];
        [mapViewController.mapLayers.weatherLayerHigh updateWeatherLayer];
        [mapViewController.mapLayers.weatherContourLayer updateWeatherLayer];
    });
}

- (void)clearOutdatedCache
{
    _offlineCacheSize = 0.;
    _onlineCacheSize = 0.;
    NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
    calendar.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    NSDate *date = [calendar startOfDayForDate:[NSDate date]];
    int64_t dateTime = date.timeIntervalSince1970 * 1000;
    _weatherResourcesManager->clearDbCache(dateTime);

    NSArray<NSString *> *downloadedRegionIds = [self getTempForecastsWithDownloadStates:@[@(EOAWeatherForecastDownloadStateFinished)]];
    for (OAWorldRegion *region in [@[_app.worldRegion] arrayByAddingObjectsFromArray:_app.worldRegion.flattenedSubregions])
    {
        if ([downloadedRegionIds containsObject:[self.class checkAndGetRegionId:region]])
            [self calculateCacheSize:region onComplete:nil];
    }
}

- (void)removeLocalForecast:(NSString *)regionId refreshMap:(BOOL)refreshMap
{
    [self removeLocalForecasts:@[regionId] refreshMap:refreshMap];
}

- (void)removeLocalForecasts:(NSArray<NSString *> *)regionIds refreshMap:(BOOL)refreshMap
{
    _offlineCacheSize = 0.;
    _onlineCacheSize = 0.;
    NSMutableArray<NSArray<NSNumber *> *> *tileIds = [NSMutableArray array];
    for (NSString *regionId in regionIds)
    {
        NSArray<NSArray<NSNumber *> *> *regionTileIds = [self.class getPreferenceTileIds:regionId];
        for (NSArray<NSNumber *> *tileId in regionTileIds)
        {
            if (![tileIds containsObject:tileId] && ![self isContainsInOfflineRegions:tileId excludeRegion:regionId])
                [tileIds addObject:tileId];
        }

        NSArray<NSArray<NSNumber *> *> *originalTileIds = [self.class getPreferenceTileIds:regionId];
        [self.class removePreferences:regionId];
        [self removeOfflineForecastInfo:regionId];
        [self setOfflineForecastSizeInfo:regionId
                                   value:kTileSize * originalTileIds.count * kForecastDatesCount
                                   local:NO];
    }

    QList<OsmAnd::TileId> qTileIds = [OANativeUtilities convertToQListTileIds:tileIds];
    OsmAnd::ZoomLevel zoom = OsmAnd::WeatherTileResourceProvider::getGeoTileZoom();
    if (!qTileIds.isEmpty())
        _weatherResourcesManager->clearDbCache(qTileIds, QList<OsmAnd::TileId>(), zoom);

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

- (NSArray<NSArray<NSNumber *> *> *)getOfflineTileIds:(NSArray<NSString *> *)regionIds
{
    if (!regionIds)
    {
        regionIds = [self getTempForecastsWithDownloadStates:@[
                @(EOAWeatherForecastDownloadStateInProgress),
                @(EOAWeatherForecastDownloadStateFinished)
        ]];
    }

    NSMutableArray<NSArray<NSNumber *> *> *offlineTileIds = [NSMutableArray array];
    for (NSString *regionId in regionIds)
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

- (void)firstInitForecast:(NSString *)regionId
{
    EOAWeatherForecastDownloadState downloadState = [self.class getPreferenceDownloadState:regionId];
    if (downloadState == EOAWeatherForecastDownloadStateInProgress)
    {
        if ([self.class getPreferenceLastUpdate:regionId] == -1)
            [self removeLocalForecast:regionId refreshMap:NO];
    }
    else if (downloadState == EOAWeatherForecastDownloadStateFinished)
    {
        [self setOfflineForecastProgressInfo:regionId value:[self getProgressDestination:regionId]];
    }
}

- (BOOL)isContainsInOfflineRegions:(NSArray<NSNumber *> *)tileId excludeRegion:(NSString *)excludeRegionId
{
    NSArray<NSString *> *regionIds = [self getTempForecastsWithDownloadStates:@[
            @(EOAWeatherForecastDownloadStateInProgress),
            @(EOAWeatherForecastDownloadStateFinished)
    ]];
    for (NSString *regionId in regionIds)
    {
        if (![regionId isEqualToString:excludeRegionId])
        {
            NSArray<NSArray<NSNumber *> *> *regionTileIds = [self.class getPreferenceTileIds:regionId];
            for (NSArray<NSNumber *> *offlineTileId in regionTileIds)
            {
                if ([offlineTileId isEqualToArray:tileId])
                    return YES;
            }
        }
    }
    return NO;
}

- (NSArray<NSString *> *)getTempForecastsWithDownloadStates:(NSArray<NSNumber *> *)states
{
    NSMutableArray<NSString *> *forecasts = [NSMutableArray array];
    for (NSString *regionId in _offlineForecastsInfo.allKeys)
    {
        if ([states containsObject:@([self.class getPreferenceDownloadState:regionId])])
            [forecasts addObject:regionId];
    }
    return forecasts;
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

    return NO;
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

- (NSInteger)getOfflineForecastProgressInfo:(NSString *)regionId
{
    NSMutableDictionary<NSString *, id> *forecastInfo = _offlineForecastsInfo[regionId];
    if (forecastInfo && [forecastInfo.allKeys containsObject:@"progress_download"])
    {
        return [forecastInfo[@"progress_download"] integerValue];
    }

    return 0;
}

- (NSInteger)getProgressDestination:(NSString *)regionId
{
    return [self.class getPreferenceTileIds:regionId].count * kForecastDatesCount;
}

- (void)onProgressUpdate:(OAWorldRegion *)region success:(BOOL)success
{
    NSString *regionId = [self.class checkAndGetRegionId:region];
    if ([self.class getPreferenceDownloadState:regionId] != EOAWeatherForecastDownloadStateInProgress)
    {
        OALog(@"Weather offline forecast download %@ : cancel", regionId);
        return;
    }

    NSInteger progressDestination = [self getProgressDestination:regionId];
    NSInteger progressDownloading = [self getOfflineForecastProgressInfo:regionId];
    [self setOfflineForecastProgressInfo:regionId value:++progressDownloading];
    CGFloat progress = (CGFloat) progressDownloading / progressDestination;

    OALog(@"Weather offline forecast download %@ : %f %@", regionId, progress, success ? @"done" : @"error");
    [_weatherForecastDownloadingObserver notifyEventWithKey:self andValue:region];

    if (progress == 1.)
    {
        [self.class setPreferenceDownloadState:regionId value:EOAWeatherForecastDownloadStateFinished];
        NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
        calendar.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        NSTimeInterval timeInterval = [NSDate date].timeIntervalSince1970;
        [self.class setPreferenceLastUpdate:regionId value:timeInterval];
        _offlineCacheSize = 0.;
        _onlineCacheSize = 0.;
        [_weatherForecastDownloadingObserver notifyEventWithKey:self andValue:region];

        dispatch_async(dispatch_get_main_queue(), ^{
            OAMapViewController *mapViewController = [OARootViewController instance].mapPanel.mapViewController;
            [mapViewController.mapLayers.weatherLayerLow updateWeatherLayer];
            [mapViewController.mapLayers.weatherLayerHigh updateWeatherLayer];
            [mapViewController.mapLayers.weatherContourLayer updateWeatherLayer];

            [self calculateCacheSize:region onComplete:^() {
                dispatch_group_leave(_forecastGroupDownloader);
            }];
        });
    }
}

- (OAResourceItem *)generateResourceItem:(OAWorldRegion *)region
{
    NSString *regionId = [self.class checkAndGetRegionId:region];
    BOOL isEntireWorld = [regionId isEqualToString:kWeatherEntireWorldRegionId];
    OAResourceItem *item;
    if ([self.class getPreferenceDownloadState:regionId] == EOAWeatherForecastDownloadStateUndefined
            || [self.class getPreferenceDownloadState:regionId] == EOAWeatherForecastDownloadStateInProgress)
    {
        item = [[OARepositoryResourceItem alloc] init];
        NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
        calendar.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        item.date = [calendar startOfDayForDate:[NSDate date]];
    }
    else
    {
        if ([self.class getPreferenceDownloadState:regionId] == EOAWeatherForecastDownloadStateFinished)
            item = [[OALocalResourceItem alloc] init];
        else
            item = [[OAOutdatedResourceItem alloc] init];

        item.date = [NSDate dateWithTimeIntervalSince1970:[self.class getPreferenceLastUpdate:regionId]];
    }
    if (item)
    {
        item.resourceId = QString::fromNSString([regionId stringByAppendingString:@"_weather_forecast"]);
        item.resourceType = OsmAndResourceType::WeatherForecast;
        item.title = isEntireWorld ? OALocalizedString(@"weather_forecast_entire_world") : OALocalizedString(@"weather_forecast");
        item.size = [self getOfflineForecastSizeInfo:regionId local:YES];
        item.sizePkg = [self getOfflineForecastSizeInfo:regionId local:NO];
        item.worldRegion = region;
    }
    return item;
}

+ (NSAttributedString *)getStatusInfoDescription:(NSString *)regionId
{
    NSMutableAttributedString *attributedDescription = [NSMutableAttributedString new];
    BOOL downloaded = [self getPreferenceDownloadState:regionId] == EOAWeatherForecastDownloadStateFinished;
    BOOL outdated = [self isForecastOutdated:regionId];
    NSString *statusStr = outdated ? OALocalizedString(@"weather_forecast_is_outdated") : @"";
    if (outdated)
    {
        NSDictionary *outdatedStrAttributes = @{
                NSFontAttributeName: [UIFont scaledSystemFontOfSize:13.],
                NSForegroundColorAttributeName: UIColorFromRGB(color_primary_red)
        };
        [attributedDescription appendAttributedString:[[NSAttributedString alloc] initWithString:[statusStr stringByAppendingString:@" "] attributes:outdatedStrAttributes]];
    }
    statusStr = [OALocalizedString(@"shared_string_updated") stringByAppendingString:@": "];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = NSLocale.currentLocale;
    NSDate *lastUpdateDate = [NSDate dateWithTimeIntervalSince1970:[self getPreferenceLastUpdate:regionId]];
    NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
    if ([calendar isDateInToday:lastUpdateDate])
    {
        statusStr = [[statusStr stringByAppendingString:OALocalizedString(@"today").lowercaseString] stringByAppendingString:@" "];
    }
    else if ([calendar isDateInYesterday:lastUpdateDate])
    {
        statusStr = [[statusStr stringByAppendingString:OALocalizedString(@"yesterday").lowercaseString] stringByAppendingString:@" "];
    }
    else
    {
        formatter.dateStyle = NSDateFormatterLongStyle;
        formatter.timeStyle = NSDateFormatterNoStyle;
        statusStr = [statusStr stringByAppendingString:[[formatter stringFromDate:lastUpdateDate] stringByAppendingString:@", "]];
    }
    formatter.dateStyle = NSDateFormatterNoStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    statusStr = [statusStr stringByAppendingString:[formatter stringFromDate:lastUpdateDate]];

    if (downloaded)
    {
        statusStr = [[statusStr stringByAppendingString:@", "] stringByAppendingString:OALocalizedString(@"shared_string_available_until").lowercaseString];
        formatter.locale = NSLocale.currentLocale;
        [formatter setLocalizedDateFormatFromTemplate:@"MMMd"];
        lastUpdateDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:7 toDate:lastUpdateDate options:0];
        statusStr = [[statusStr stringByAppendingString:@" " ] stringByAppendingString:[formatter stringFromDate:lastUpdateDate]];
    }

    NSDictionary *updatedStrAttributes = @{
            NSFontAttributeName: [UIFont scaledSystemFontOfSize:13.],
            NSForegroundColorAttributeName: UIColorFromRGB(color_text_footer)
    };
    [attributedDescription appendAttributedString:[[NSAttributedString alloc] initWithString:statusStr attributes:updatedStrAttributes]];

    return attributedDescription;
}

+ (NSString *)getAccuracyDescription:(NSString *)regionId
{
    NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = NSLocale.currentLocale;
    [formatter setLocalizedDateFormatFromTemplate:@"MMMd"];

    NSDate *initialDate = [NSDate dateWithTimeIntervalSince1970:[self getPreferenceLastUpdate:regionId]];
    NSString *initialStr = [formatter stringFromDate:initialDate];

    NSDate *destinationDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:7 toDate:initialDate options:0];
    NSString *destinationStr = [formatter stringFromDate:destinationDate];

    NSDate *nextInitialDayDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:initialDate options:0];
    NSDateIntervalFormatter *intervalFormatter = [[NSDateIntervalFormatter alloc] init];
    intervalFormatter.locale = NSLocale.currentLocale;
    intervalFormatter.dateTemplate = @"MMMMd";
    NSString *interval3hStr = [intervalFormatter stringFromDate:nextInitialDayDate toDate:destinationDate];

    return [NSString stringWithFormat:OALocalizedString(@"weather_accuracy_forecast_description"), destinationStr, initialStr, interval3hStr];
}

+ (NSString *)getUpdatesDateFormat:(NSString *)regionId next:(BOOL)next
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = NSLocale.currentLocale;
    NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;

    NSDate *updatesDate = [NSDate dateWithTimeIntervalSince1970:[self getPreferenceLastUpdate:regionId]];
    if (next)
    {
        EOAWeatherForecastUpdatesFrequency frequency = [self.class getPreferenceFrequency:regionId];
        NSInteger hours = frequency == EOAWeatherForecastUpdatesSemiDaily ? 12
                : frequency == EOAWeatherForecastUpdatesDaily ? 24
                        : 168;
        updatesDate = [calendar dateByAddingUnit:NSCalendarUnitHour value:hours toDate:updatesDate options:0];
    }
    NSMutableString *updatesStr = [NSMutableString string];
    BOOL isToday = [calendar isDateInToday:updatesDate];
    if (isToday || (next ? [calendar isDateInTomorrow:updatesDate] : [calendar isDateInYesterday:updatesDate]))
    {
        [updatesStr appendString:(isToday
                ? OALocalizedString(@"today") : (next ? OALocalizedString(@"tomorrow") : OALocalizedString(@"yesterday"))).capitalizedString];
    }
    else
    {
        [formatter setLocalizedDateFormatFromTemplate:@"MMMMd"];
        [updatesStr appendString:[formatter stringFromDate:updatesDate]];
    }
    [updatesStr appendString:@", "];
    formatter.dateStyle = NSDateFormatterNoStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    [updatesStr appendString:[formatter stringFromDate:updatesDate]];
    return updatesStr;
}

+ (NSString *)getFrequencyFormat:(EOAWeatherForecastUpdatesFrequency)frequency
{
    if (frequency == EOAWeatherForecastUpdatesSemiDaily || frequency == EOAWeatherForecastUpdatesDaily)
    {
        NSDateComponentsFormatter *formatter = [[NSDateComponentsFormatter alloc] init];
        formatter.unitsStyle = NSDateComponentsFormatterUnitsStyleAbbreviated;
        formatter.allowedUnits = NSCalendarUnitHour;
        NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
        [dateComponents setValue:frequency == EOAWeatherForecastUpdatesSemiDaily ? 12 : 24 forComponent:NSCalendarUnitHour];
        return [formatter stringFromDateComponents:dateComponents].capitalizedString;
    }
    else
    {
        return OALocalizedString(@"weekly");
    }
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
    NSString *regionId = [self.class checkAndGetRegionId:region];
    if ([self getPreferenceTileIds:regionId].count == 0)
    {
        BOOL isEntireWorld = [regionId isEqualToString:kWeatherEntireWorldRegionId];
        OsmAnd::LatLon latLonTopLeft = OsmAnd::LatLon(isEntireWorld ? 90. : region.bboxTopLeft.latitude, isEntireWorld ? -180. : region.bboxTopLeft.longitude);
        OsmAnd::LatLon latLonBottomRight = OsmAnd::LatLon(isEntireWorld ? -90. : region.bboxBottomRight.latitude, isEntireWorld ? 180. : region.bboxBottomRight.longitude);
        OsmAnd::ZoomLevel zoom = OsmAnd::WeatherTileResourceProvider::getGeoTileZoom();

        QVector<OsmAnd::TileId> qTileIds = OsmAnd::WeatherTileResourcesManager::generateGeoTileIds(latLonTopLeft, latLonBottomRight, zoom);
        NSMutableArray<NSArray<NSNumber *> *> *tileIds = [NSMutableArray array];
        for (auto &qTileId: qTileIds)
        {
            [tileIds addObject:@[@(qTileId.x), @(qTileId.y)]];
        }
        [self setPreferenceTileIds:regionId value:tileIds];
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

+ (void)removePreferences:(NSString *)regionId
{
    for (NSString *key in [self getPreferenceKeys:regionId])
    {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
}

@end
