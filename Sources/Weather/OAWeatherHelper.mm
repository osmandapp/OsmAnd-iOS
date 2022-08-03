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
#import "OAColors.h"

#include <OsmAndCore/Map/WeatherTileResourceProvider.h>
#include <OsmAndCore/Map/WeatherTileResourcesManager.h>
#include <OsmAndCore/FunctorQueryController.h>
#include <OsmAndCore/WorldRegions.h>

#define kWeatherForecastStatusPrefix @"forecast_status_"
#define kWeatherForecastLastUpdatePrefix @"forecast_last_update_"
#define kWeatherForecastFrequencyPrefix @"forecast_frequency_"
#define kWeatherForecastSizeLocalPrefix @"forecast_size_local_"
#define kWeatherForecastSizeUpdatesPrefix @"forecast_size_updates_"
#define kWeatherForecastTileIdsPrefix @"forecast_tile_ids_"
#define kWeatherForecastWifiPrefix @"forecast_download_via_wifi_"

#define kTileSize 40000
#define kForecastDatesCount (24 + (6 * 8) + 1)

@implementation OAWeatherHelper
{
    OsmAndAppInstance _app;
    std::shared_ptr<OsmAnd::WeatherTileResourcesManager> _weatherResourcesManager;
    NSMutableDictionary<NSString *, NSNumber *> *_offlineRegionsWithProgress;
    dispatch_queue_t _forecastSerialDownloader;
    dispatch_group_t _forecastGroupDownloader;
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
        _offlineRegionsWithProgress = [NSMutableDictionary dictionary];
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

+ (BOOL)shouldHaveWeatherForecast:(OAWorldRegion *)region
{
    NSString *unitedKingdomRegionId = [NSString stringWithFormat:@"%@_gb", OsmAnd::WorldRegions::EuropeRegionId.toNSString()];
    return ([region getLevel] == 2 && ![region.regionId hasPrefix:unitedKingdomRegionId]) || ([region getLevel] == 3 && [region.regionId hasPrefix:unitedKingdomRegionId]);
}

- (void)downloadForecastsByRegionIds:(NSArray<NSString *> *)regionIds;
{
    NSInteger forecastsDownloading = 0;
    for (OAWorldRegion *region in _app.worldRegion.flattenedSubregions)
    {
        if ([regionIds containsObject:region.regionId])
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
    OsmAnd::LatLon latLonTopLeft = OsmAnd::LatLon(region.bboxTopLeft.latitude, region.bboxTopLeft.longitude);
    OsmAnd::LatLon latLonBottomRight = OsmAnd::LatLon(region.bboxBottomRight.latitude, region.bboxBottomRight.longitude);

    [self.class updatePreferenceTileIdsIfNeeded:region];

    [self setProgress:region.regionId value:0];
    [self.class setPreferenceStatus:region.regionId value:EOAWeatherForecastStatusDownloading];
    [_weatherForecastDownloadingObserver notifyEventWithKey:self andValue:region];

    std::shared_ptr<const OsmAnd::IQueryController> queryController;
    queryController.reset(new OsmAnd::FunctorQueryController(
        [self, region]
        (const OsmAnd::IQueryController *const controller) -> bool
        {
            return [self.class hasStatus:EOAWeatherForecastStatusUndefined regionId:region.regionId];
        }
    ));

    dispatch_block_t forecastDownload = ^{
        dispatch_group_wait(_forecastGroupDownloader, DISPATCH_TIME_FOREVER);
        dispatch_group_enter(_forecastGroupDownloader);

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
                    (bool succeeded,
                     const uint64_t downloadedTiles,
                     const uint64_t totalTiles,
                     const std::shared_ptr<OsmAnd::Metric> &metric)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self onProgressUpdate:region success:succeeded];
                        });
                    };

            _weatherResourcesManager->downloadGeoTilesAsync(request, callback);
            date = [calendar dateByAddingUnit:NSCalendarUnitHour value:(i < 24 ? 1 : 3) toDate:date options:0];
        }
    };

    dispatch_group_notify(_forecastGroupDownloader, _forecastSerialDownloader, ^{
        dispatch_async(_forecastSerialDownloader, forecastDownload);
    });
}

- (void)prepareToStopDownloading:(NSString *)regionId
{
    if ([self.class hasStatus:EOAWeatherForecastStatusDownloading regionId:regionId] && [self getProgress:regionId] > 0)
        dispatch_group_leave(_forecastGroupDownloader);
    [self.class setPreferenceStatus:regionId value:EOAWeatherForecastStatusUndefined];
    [self removeOfflineRegion:regionId];
}

- (void)calculateCacheSize:(OAWorldRegion *)region
                onComplete:(void (^)(unsigned long long, unsigned long long))onComplete
{
    [_weatherForecastDownloadingObserver notifyEventWithKey:self andValue:region];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.class setPreferenceSizeLocal:region.regionId value:0];
        [self.class setPreferenceSizeUpdates:region.regionId value:0];

        [self.class removeStatus:EOAWeatherForecastStatusLocalCalculated regionId:region.regionId];
        [self.class removeStatus:EOAWeatherForecastStatusUpdatesCalculated regionId:region.regionId];

        [self.class addStatus:EOAWeatherForecastStatusCalculating regionId:region.regionId];

        [self.class updatePreferenceTileIdsIfNeeded:region];
        NSArray<NSArray<NSNumber *> *> *tileIds = [self.class getPreferenceTileIds:region.regionId];
        QList<OsmAnd::TileId> qTileIds = [OANativeUtilities convertToQListTileIds:tileIds];
        OsmAnd::ZoomLevel zoom = OsmAnd::WeatherTileResourceProvider::getGeoTileZoom();
        unsigned long long sizeLocal = 0;
        unsigned long long sizeUpdates = 0;
        if (!qTileIds.isEmpty())
        {
            sizeLocal = _weatherResourcesManager->calculateDbCacheSize(qTileIds, QList<OsmAnd::TileId>(), zoom);
            sizeUpdates = kTileSize * tileIds.count * 24 * 7;
        }

        [self.class removeStatus:EOAWeatherForecastStatusCalculating regionId:region.regionId];

        [self.class setPreferenceSizeLocal:region.regionId value:sizeLocal];
        [self.class addStatus:EOAWeatherForecastStatusLocalCalculated regionId:region.regionId];

        [self.class setPreferenceSizeUpdates:region.regionId value:sizeUpdates];
        [self.class addStatus:EOAWeatherForecastStatusUpdatesCalculated regionId:region.regionId];

        [_weatherSizeCalculatedObserver notifyEventWithKey:self andValue:region];

        if (onComplete)
            onComplete(sizeLocal, sizeUpdates);
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
        for (NSString *regionId in [self getOfflineRegions])
        {
            NSString *tileIdsKey = [kWeatherForecastTileIdsPrefix stringByAppendingString:regionId];
            [self.class removePreferences:regionId excludeKeys:@[tileIdsKey]];
            [self removeOfflineRegion:regionId];
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
    for (OAWorldRegion *region in _app.worldRegion.flattenedSubregions)
    {
        if (![self.class hasStatus:EOAWeatherForecastStatusUndefined regionId:region.regionId] && [self.class getPreferenceSizeLocal:region.regionId] > 0)
            [self calculateCacheSize:region onComplete:nil];
    }
}

- (void)removeLocalForecast:(NSString *)regionId refreshMap:(BOOL)refreshMap
{
    [self removeLocalForecasts:@[regionId] refreshMap:refreshMap];
}

- (void)removeLocalForecasts:(NSArray<NSString *> *)regionIds refreshMap:(BOOL)refreshMap
{
    NSMutableArray<NSArray<NSNumber *> *> *tileIds = [NSMutableArray array];
    for (NSString *regionId in regionIds)
    {
        NSArray<NSArray<NSNumber *> *> *regionTileIds = [self.class getPreferenceTileIds:regionId];
        for (NSArray<NSNumber *> *tileId in regionTileIds)
        {
            if (![tileIds containsObject:tileId] && ![self isContainsInOfflineRegions:tileId excludeRegion:regionId])
                [tileIds addObject:tileId];
        }

        NSString *tileIdsKey = [kWeatherForecastTileIdsPrefix stringByAppendingString:regionId];
        [self.class removePreferences:regionId excludeKeys:@[tileIdsKey]];
        [self setOfflineRegion:regionId];
    }

    QList<OsmAnd::TileId> qTileIds = [OANativeUtilities convertToQListTileIds:tileIds];
    OsmAnd::ZoomLevel zoom = OsmAnd::WeatherTileResourceProvider::getGeoTileZoom();
    if (!qTileIds.isEmpty())
        _weatherResourcesManager->clearDbCache(qTileIds, QList<OsmAnd::TileId>(), zoom);

    if (refreshMap)
    {
        OAMapViewController *mapViewController = [OARootViewController instance].mapPanel.mapViewController;
        [mapViewController.mapLayers.weatherLayerLow updateWeatherLayer];
        [mapViewController.mapLayers.weatherLayerHigh updateWeatherLayer];
        [mapViewController.mapLayers.weatherContourLayer updateWeatherLayer];
    }
}

- (void)removeIncompleteForecast:(NSString *)regionId
{
    [self.class removeStatus:EOAWeatherForecastStatusCalculating regionId:regionId];
    if ([self.class hasStatus:EOAWeatherForecastStatusDownloading regionId:regionId])
    {
        NSDate *dateChecked = [NSDate dateWithTimeIntervalSince1970:[self.class getPreferenceLastUpdate:regionId]];
        if ([dateChecked isEqualToDate:[NSDate dateWithTimeIntervalSince1970:-1]])
            [self removeLocalForecast:regionId refreshMap:NO];
    }
}

- (NSArray<NSArray<NSNumber *> *> *)getOfflineTileIds
{
    NSMutableArray<NSArray<NSNumber *> *> *offlineTileIds = [NSMutableArray array];
    for (NSString *regionId in [self getOfflineRegions])
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

- (BOOL)isContainsInOfflineRegions:(NSArray<NSNumber *> *)tileId excludeRegion:(NSString *)excludeRegionId
{
    for (NSString *regionId in [self getOfflineRegions])
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

- (void)setOfflineRegion:(NSString *)regionId
{
    BOOL isDownloaded = [self.class hasStatus:EOAWeatherForecastStatusDownloaded regionId:regionId];
    BOOL isOutdated = [self.class hasStatus:EOAWeatherForecastStatusOutdated regionId:regionId];
    if (isDownloaded || isOutdated)
        [self setProgress:regionId value:0];
    else
        [self removeOfflineRegion:regionId];
}

- (NSArray<NSString *> *)getOfflineRegions
{
    NSMutableArray<NSString *> *offlineRegions = [NSMutableArray array];
    for (NSString *regionId in _offlineRegionsWithProgress.allKeys)
    {
        if (![self.class hasStatus:EOAWeatherForecastStatusDownloading regionId:regionId])
            [offlineRegions addObject:regionId];
    }
    return offlineRegions;
}

- (NSArray<NSString *> *)getDownloadingRegions
{
    NSMutableArray<NSString *> *downloadingRegions = [NSMutableArray array];
    for (NSString *regionId in _offlineRegionsWithProgress.allKeys)
    {
        if ([self.class hasStatus:EOAWeatherForecastStatusDownloading regionId:regionId])
            [downloadingRegions addObject:regionId];
    }
    return downloadingRegions;
}

- (void)removeOfflineRegion:(NSString *)regionId
{
    [_offlineRegionsWithProgress removeObjectForKey:regionId];
}

- (void)setProgress:(NSString *)regionId value:(NSInteger)value
{
    _offlineRegionsWithProgress[regionId] = @(value);
}

- (NSInteger)getProgress:(NSString *)regionId
{
    return [_offlineRegionsWithProgress.allKeys containsObject:regionId] ? [_offlineRegionsWithProgress[regionId] integerValue] : 0;
}

- (NSInteger)getProgressDestination:(NSString *)regionId
{
    return [self.class getPreferenceTileIds:regionId].count * kForecastDatesCount;
}

- (void)onProgressUpdate:(OAWorldRegion *)region
                 success:(BOOL)success
{
    if ([self.class hasStatus:EOAWeatherForecastStatusUndefined regionId:region.regionId])
    {
        OALog(@"Weather offline forecast download %@ : cancel", region.regionId);
        return;
    }

    NSInteger progressDestination = [self getProgressDestination:region.regionId];
    NSInteger progressDownloading = [self getProgress:region.regionId];
    [self setProgress:region.regionId value:++progressDownloading];
    CGFloat progress = (CGFloat) progressDownloading / progressDestination;

    OALog(@"Weather offline forecast download %@ : %f %@", region.regionId, progress, success ? @"done" : @"error");
    [_weatherForecastDownloadingObserver notifyEventWithKey:self andValue:region];

    if (progress == 1.)
    {
        [self.class setPreferenceStatus:region.regionId value:EOAWeatherForecastStatusDownloaded];
        NSTimeInterval timeInterval = [NSDate date].timeIntervalSince1970;
        [self.class setPreferenceLastUpdate:region.regionId value:timeInterval];
        [self setOfflineRegion:region.regionId];
        [_weatherForecastDownloadingObserver notifyEventWithKey:self andValue:region];

        OAMapViewController *mapViewController = [OARootViewController instance].mapPanel.mapViewController;
        [mapViewController.mapLayers.weatherLayerLow updateWeatherLayer];
        [mapViewController.mapLayers.weatherLayerHigh updateWeatherLayer];
        [mapViewController.mapLayers.weatherContourLayer updateWeatherLayer];

        [self calculateCacheSize:region onComplete:^(unsigned long long sizeLocal, unsigned long long sizeUpdates)
        {
            dispatch_group_leave(_forecastGroupDownloader);
        }];
    }
}

+ (OAResourceItem *)generateResourceItem:(OAWorldRegion *)region
{
    OAResourceItem *item;
    if ([self.class hasStatus:EOAWeatherForecastStatusUndefined regionId:region.regionId] || [self.class hasStatus:EOAWeatherForecastStatusDownloading regionId:region.regionId])
    {
        item = [[OARepositoryResourceItem alloc] init];
        NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
        calendar.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        item.date = [calendar startOfDayForDate:[NSDate date]];
    }
    else
    {
        if ([self.class hasStatus:EOAWeatherForecastStatusDownloaded regionId:region.regionId])
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

+ (NSAttributedString *)getStatusInfoDescription:(NSString *)regionId
{
    NSMutableAttributedString *attributedDescription = [NSMutableAttributedString new];
    BOOL downloaded = [self hasStatus:EOAWeatherForecastStatusDownloaded regionId:regionId];
    BOOL outdated = [self hasStatus:EOAWeatherForecastStatusOutdated regionId:regionId];
    NSString *statusStr = outdated ? OALocalizedString(@"weather_forecast_is_outdated") : @"";
    if (outdated)
    {
        NSDictionary *outdatedStrAttributes = @{
                NSFontAttributeName: [UIFont systemFontOfSize:13.],
                NSForegroundColorAttributeName: UIColorFromRGB(color_primary_red)
        };
        [attributedDescription appendAttributedString:[[NSAttributedString alloc] initWithString:[statusStr stringByAppendingString:@" "] attributes:outdatedStrAttributes]];
    }
    statusStr = [OALocalizedString(@"shared_string_updated") stringByAppendingString:@": "];

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    NSDate *lastUpdateDate = [NSDate dateWithTimeIntervalSince1970:[self getPreferenceLastUpdate:regionId]];
    NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
    if ([calendar isDateInToday:lastUpdateDate])
    {
        statusStr = [[statusStr stringByAppendingString:OALocalizedString(@"today")] stringByAppendingString:@" "];
    }
    else if ([calendar isDateInYesterday:lastUpdateDate])
    {
        statusStr = [[statusStr stringByAppendingString:OALocalizedString(@"yesterday")] stringByAppendingString:@" "];
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
        statusStr = [[statusStr stringByAppendingString:@", "] stringByAppendingString:OALocalizedString(@"shared_string_available_until")];
        formatter.locale = NSLocale.currentLocale;
        [formatter setLocalizedDateFormatFromTemplate:@"MMMMd"];
        lastUpdateDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:7 toDate:lastUpdateDate options:0];
        statusStr = [[statusStr stringByAppendingString:@" " ] stringByAppendingString:[formatter stringFromDate:lastUpdateDate]];
    }

    NSDictionary *updatedStrAttributes = @{
            NSFontAttributeName: [UIFont systemFontOfSize:13.],
            NSForegroundColorAttributeName: UIColorFromRGB(color_text_footer)
    };
    [attributedDescription appendAttributedString:[[NSAttributedString alloc] initWithString:statusStr attributes:updatedStrAttributes]];

    return attributedDescription;
}

- (void)checkStatusOutdated:(OAWorldRegion *)region
{
    NSInteger daysGone = 0;
    NSDate *dateChecked = [NSDate dateWithTimeIntervalSince1970:[self.class getPreferenceLastUpdate:region.regionId]];
    if (![dateChecked isEqualToDate:[NSDate dateWithTimeIntervalSince1970:-1]])
    {
        NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
        calendar.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        NSDate *dayNow = [calendar startOfDayForDate:[NSDate date]];
        daysGone = [calendar components:NSCalendarUnitDay fromDate:dateChecked toDate:dayNow options:0].day;
    }

    if (daysGone >= 7 && [self.class hasStatus:EOAWeatherForecastStatusDownloaded regionId:region.regionId])
    {
        [self.class removeStatus:EOAWeatherForecastStatusDownloaded regionId:region.regionId];
        [self.class addStatus:EOAWeatherForecastStatusOutdated regionId:region.regionId];
    }
}

+ (BOOL)hasStatus:(NSInteger)status regionId:(NSString *)regionId
{
    NSInteger regionStatus = [self getPreferenceStatus:regionId];
    regionStatus &= status;
    return regionStatus != 0;
}

+ (void)addStatus:(NSInteger)status regionId:(NSString *)regionId
{
    NSInteger regionStatus = [self getPreferenceStatus:regionId];
    regionStatus |= status;
    [self setPreferenceStatus:regionId value:regionStatus];
}

+ (void)removeStatus:(NSInteger)status regionId:(NSString *)regionId
{
    NSInteger regionStatus = [self getPreferenceStatus:regionId];
    regionStatus &= ~status;
    [self setPreferenceStatus:regionId value:regionStatus];
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

+ (void)updatePreferenceTileIdsIfNeeded:(OAWorldRegion *)region
{
    if ([self getPreferenceTileIds:region.regionId].count == 0)
    {
        OsmAnd::LatLon latLonTopLeft = OsmAnd::LatLon(region.bboxTopLeft.latitude, region.bboxTopLeft.longitude);
        OsmAnd::LatLon latLonBottomRight = OsmAnd::LatLon(region.bboxBottomRight.latitude, region.bboxBottomRight.longitude);
        OsmAnd::ZoomLevel zoom = OsmAnd::WeatherTileResourceProvider::getGeoTileZoom();

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
