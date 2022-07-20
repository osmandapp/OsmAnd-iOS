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
#import "OAWeatherDownloaderOperationQueue.h"
#import "OAWeatherDownloaderOperation.h"
#import "OALog.h"

#include <OsmAndCore/Map/WeatherTileResourceProvider.h>
#include <OsmAndCore/Map/WeatherTileResourcesManager.h>

#define kWeatherForecastStatusPrefix @"forecast_status_"
#define kWeatherForecastLastUpdatePrefix @"forecast_last_update_"
#define kWeatherForecastFrequencyPrefix @"forecast_frequency_"
#define kWeatherForecastSizeLocalPrefix @"forecast_size_local_"
#define kWeatherForecastSizeUpdatesPrefix @"forecast_size_updates_"
#define kWeatherForecastWifiPrefix @"forecast_download_via_wifi_"

@interface OAWeatherHelper () <OAWeatherDownloaderDelegate>

@end

@implementation OAWeatherHelper
{
    OsmAndAppInstance _app;
    OAWeatherDownloaderOperationQueue *_weatherDownloaderQueue;
    std::shared_ptr<OsmAnd::WeatherTileResourcesManager> _weatherResourcesManager;
    NSMutableDictionary<NSString *, NSNumber *> *_progress;
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
        _weatherDownloaderQueue = [[OAWeatherDownloaderOperationQueue alloc] init];
        _weatherDownloaderQueue.maxConcurrentOperationCount = 50;
        _progress = [NSMutableDictionary dictionary];

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
    if (calculateSizeLocal)
        [self.class setPreferenceSizeLocal:region.regionId value:0];
    else if (calculateSizeUpdates)
        [self.class setPreferenceSizeUpdates:region.regionId value:0];

    NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
    NSDate *date = [calendar startOfDayForDate:[NSDate date]];
    OsmAnd::LatLon latLonTopLeft = OsmAnd::LatLon(region.bboxTopLeft.latitude, region.bboxTopLeft.longitude);
    OsmAnd::LatLon latLonBottomRight = OsmAnd::LatLon(region.bboxBottomRight.latitude, region.bboxBottomRight.longitude);
    OsmAnd::ZoomLevel zoom = OsmAnd::WeatherTileResourceProvider::getGeoTileZoom();
    QVector<OsmAnd::TileId> tileIds = OsmAnd::WeatherTileResourcesManager::generateGeoTileIds(latLonTopLeft, latLonBottomRight, zoom);

    [self setProgress:region key:kWeatherProgressDestinationSuffix value:tileIds.size() * 7 * 24];
    NSString *operationKey = region.regionId;
    if (!calculateSizeLocal && !calculateSizeUpdates)
    {
        [self setProgress:region key:kWeatherProgressDownloadingSuffix value:0];
        operationKey = [operationKey stringByAppendingString:kWeatherProgressDownloadingSuffix];
        NSInteger status = [self.class getPreferenceStatus:region.regionId];
        if (status & EOAWeatherForecastStatusUpdatesCalculated)
            status = EOAWeatherForecastStatusUpdatesCalculated | EOAWeatherForecastStatusDownloading;
        else
            status = EOAWeatherForecastStatusDownloading;
        [self.class setPreferenceStatus:region.regionId value:status];
        [self.class setPreferenceSizeLocal:region.regionId value:0];
    }
    else if (calculateSizeLocal)
    {
        [self setProgress:region key:kWeatherProgressCalculateSizeLocalSuffix value:0];
        operationKey = [operationKey stringByAppendingString:kWeatherProgressCalculateSizeLocalSuffix];
        NSInteger status = [self.class getPreferenceStatus:region.regionId];
        if (status & EOAWeatherForecastStatusLocalCalculated)
            status &= ~EOAWeatherForecastStatusLocalCalculated;
        [self.class setPreferenceStatus:region.regionId value:status | EOAWeatherForecastStatusCalculating];
    }
    else
    {
        [self setProgress:region key:kWeatherProgressCalculateSizeUpdatesSuffix value:0];
        operationKey = [operationKey stringByAppendingString:kWeatherProgressCalculateSizeUpdatesSuffix];
        NSInteger status = [self.class getPreferenceStatus:region.regionId];
        if (status & EOAWeatherForecastStatusUpdatesCalculated)
            status &= ~EOAWeatherForecastStatusUpdatesCalculated;
        [self.class setPreferenceStatus:region.regionId value:status | EOAWeatherForecastStatusCalculating];
    }
    [self onProgressUpdate:region
               sizeUpdates:[self.class getPreferenceSizeUpdates:region.regionId]
                 sizeLocal:[self.class getPreferenceSizeLocal:region.regionId]
        calculateSizeLocal:calculateSizeLocal
      calculateSizeUpdates:calculateSizeUpdates
                   success:YES];

    for (NSInteger i = 0; i < 7 * 24; i++)
    {
        for (auto &tileId: tileIds)
        {
            OAWeatherDownloaderOperation *operation = [[OAWeatherDownloaderOperation alloc] initWithRegion:region
                                                                                                    tileId:tileId
                                                                                                      date:date
                                                                                                      zoom:zoom
                                                                                        calculateSizeLocal:calculateSizeLocal
                                                                                      calculateSizeUpdates:calculateSizeUpdates];
            operation.delegate = self;
            [_weatherDownloaderQueue addOperation:operation key:operationKey];
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
    [_weatherDownloaderQueue cancelAllOperations];
    _weatherResourcesManager->clearDbCache(localData);
    if (localData)
    {
        for (OAWorldRegion *region in _app.worldRegion.flattenedSubregions)
        {
            NSArray *excludeKeys = [self.class getPreferenceStatus:region.regionId] & EOAWeatherForecastStatusUpdatesCalculated
                    ? @[[kWeatherForecastSizeUpdatesPrefix stringByAppendingString:region.regionId]] : @[];
            [self.class removePreferences:region.regionId excludeKeys:excludeKeys];
            [_weatherDownloaderQueue clearOperations:region.regionId];
            [self clearProgress:region];
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
        NSInteger status = [self.class getPreferenceStatus:region.regionId];
        NSInteger localSize = [self.class getPreferenceSizeLocal:region.regionId];
        if (!(status & EOAWeatherForecastStatusUndefined) && localSize > 0)
            [self calculateCacheSize:region localData:YES];
    }
}

- (void)removeLocalForecast:(OAWorldRegion *)region refreshMap:(BOOL)refreshMap
{
    NSArray *excludeKeys = [self.class getPreferenceStatus:region.regionId] & EOAWeatherForecastStatusUpdatesCalculated
            ? @[[kWeatherForecastSizeUpdatesPrefix stringByAppendingString:region.regionId]] : @[];
    [self.class removePreferences:region.regionId excludeKeys:excludeKeys];
    [_weatherDownloaderQueue clearOperations:region.regionId];
    [self clearProgress:region];

    OsmAnd::LatLon latLonTopLeft = OsmAnd::LatLon(region.bboxTopLeft.latitude, region.bboxTopLeft.longitude);
    OsmAnd::LatLon latLonBottomRight = OsmAnd::LatLon(region.bboxBottomRight.latitude, region.bboxBottomRight.longitude);
    _weatherResourcesManager->clearLocalDbCache(latLonTopLeft, latLonBottomRight, OsmAnd::WeatherTileResourceProvider::getGeoTileZoom());

    if (refreshMap)
    {
        OAMapViewController *mapViewController = [OARootViewController instance].mapPanel.mapViewController;
        [mapViewController.mapLayers.weatherLayerLow updateWeatherLayer];
        [mapViewController.mapLayers.weatherLayerHigh updateWeatherLayer];
        [mapViewController.mapLayers.weatherContourLayer updateWeatherLayer];
    }
}

- (void)removeIncompleteDownloads:(OAWorldRegion *)region
{
    NSInteger status = [self.class getPreferenceStatus:region.regionId];
    NSDate *dateChecked = [NSDate dateWithTimeIntervalSince1970:[OAWeatherHelper getPreferenceLastUpdate:region.regionId]];
    if (status & EOAWeatherForecastStatusDownloading && [dateChecked isEqualToDate:[NSDate dateWithTimeIntervalSince1970:-1]])
        [self removeLocalForecast:region refreshMap:NO];
}

- (void)updatePreferences:(OAWorldRegion *)region
{
    NSInteger status = [self.class getPreferenceStatus:region.regionId];
    NSInteger daysGone = 0;
    NSDate *dateChecked = [NSDate dateWithTimeIntervalSince1970:[self.class getPreferenceLastUpdate:region.regionId]];
    if (![dateChecked isEqualToDate:[NSDate dateWithTimeIntervalSince1970:-1]])
    {
        NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
        NSDate *dateNow = [calendar startOfDayForDate:[NSDate date]];
        daysGone = [calendar components:NSCalendarUnitDay fromDate:dateChecked toDate:dateNow options:0].day;
    }

    if (daysGone >= 1 && (status & EOAWeatherForecastStatusDownloaded || status & EOAWeatherForecastStatusOutdated))
    {
        [self calculateCacheSize:region localData:NO];
        [self calculateCacheSize:region localData:YES];
    }
    else
    {
        if ([self.class getPreferenceSizeUpdates:region.regionId] == 0)
            [self calculateCacheSize:region localData:NO];
        if ([self.class getPreferenceSizeLocal:region.regionId] == 0 && status & EOAWeatherForecastStatusDownloaded)
            [self calculateCacheSize:region localData:YES];
    }

    if (daysGone >= 7 && status & EOAWeatherForecastStatusDownloaded)
    {
        status &= ~EOAWeatherForecastStatusDownloaded;
        [self.class setPreferenceStatus:region.regionId value:status | EOAWeatherForecastStatusOutdated];
    }
}

+ (OAResourceItem *)generateResourceItem:(OAWorldRegion *)region
{
    NSInteger status = [self getPreferenceStatus:region.regionId];
    OAResourceItem *item;
    if (status & EOAWeatherForecastStatusUndefined || status & EOAWeatherForecastStatusDownloading)
    {
        item = [[OARepositoryResourceItem alloc] init];
        item.date = [NSCalendar.autoupdatingCurrentCalendar startOfDayForDate:[NSDate date]];
    }
    else
    {
        if (status & EOAWeatherForecastStatusDownloaded)
            item = [[OALocalResourceItem alloc] init];
        else
            item = [[OAOutdatedResourceItem alloc] init];

        item.date = [NSDate dateWithTimeIntervalSince1970:[self getPreferenceLastUpdate:region.regionId]];
    }
    if (item)
    {
        item.resourceId = QString::fromNSString([self generateResourceId:region date:item.date]);
        item.resourceType = OsmAndResourceType::WeatherForecast;
        item.title = OALocalizedString(@"weather_forecast");
        item.size = [self getPreferenceSizeLocal:region.regionId];
        item.sizePkg = [self getPreferenceSizeUpdates:region.regionId];
        item.worldRegion = region;
    }
    return item;
}

+ (NSString *)generateResourceId:(OAWorldRegion *)region date:(NSDate *)date
{
    if (!date)
        return [region.regionId stringByAppendingString:@"_undefined"];

    NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
    NSDate *dateForForecast = [calendar startOfDayForDate:date];
    QDateTime dateTime = QDateTime::fromNSDate(dateForForecast).toUTC();
    NSInteger year = dateTime.date().year();
    NSInteger month = dateTime.date().month();
    NSInteger day = dateTime.date().day();
    NSInteger hour = dateTime.time().hour();
    NSInteger minute = dateTime.time().minute();

    NSString *resourceId = [NSString stringWithFormat:@"%@_weather_forecast_%li%@%li%@%li_%@%li%@%li",
                                                      region.regionId,
                                                      year,
                                                      month < 10 ? @"0" : @"", month,
                                                      day < 10 ? @"0" : @"", day,
                                                      hour < 10 ? @"0" : @"", hour,
                                                      minute < 10 ? @"0" : @"", minute];
    return resourceId;
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

+ (NSArray<NSString *> *)getPreferenceKeys:(NSString *)regionId
{
    return @[
        [kWeatherForecastStatusPrefix stringByAppendingString:regionId],
        [kWeatherForecastLastUpdatePrefix stringByAppendingString:regionId],
        [kWeatherForecastFrequencyPrefix stringByAppendingString:regionId],
        [kWeatherForecastWifiPrefix stringByAppendingString:regionId],
        [kWeatherForecastSizeLocalPrefix stringByAppendingString:regionId],
        [kWeatherForecastSizeUpdatesPrefix stringByAppendingString:regionId]
    ];
}

+ (void)setDefaultPreferences:(NSString *)regionId
{
    [self setPreferenceStatus:regionId value:EOAWeatherForecastStatusUndefined];
    [self setPreferenceLastUpdate:regionId value:-1];
    [self setPreferenceWifi:regionId value:NO];
    [self setPreferenceFrequency:regionId value:EOAWeatherForecastUpdatesUndefined];
    [self setPreferenceSizeLocal:regionId value:0];
    [self setPreferenceSizeUpdates:regionId value:0];
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

- (NSInteger)getProgress:(OAWorldRegion *)region key:(NSString *)key
{
    NSString *progressKey = [region.regionId stringByAppendingString:key];
    return [_progress.allKeys containsObject:progressKey] ? [_progress[progressKey] integerValue] : 0;
}

- (void)setProgress:(OAWorldRegion *)region key:(NSString *)key value:(NSInteger)value
{
    NSString *progressKey = [region.regionId stringByAppendingString:key];
    _progress[progressKey] = @(value);
}

- (void)removeProgress:(OAWorldRegion *)region key:(NSString *)key
{
    NSString *progressKey = [region.regionId stringByAppendingString:key];
    [_progress removeObjectForKey:progressKey];
}

- (void)clearProgress:(OAWorldRegion *)region
{
    for (NSString *key in _progress.allKeys)
    {
        if ([key hasPrefix:region.regionId])
            [_progress removeObjectForKey:key];
    }
}

#pragma mark - OAWeatherDownloaderDelegate

- (void)onProgressUpdate:(OAWorldRegion *)region
             sizeUpdates:(NSInteger)sizeUpdates
               sizeLocal:(NSInteger)sizeLocal
      calculateSizeLocal:(BOOL)calculateSizeLocal
    calculateSizeUpdates:(BOOL)calculateSizeUpdates
                 success:(BOOL)success
{
    NSInteger progressDestination = [self getProgress:region key:kWeatherProgressDestinationSuffix];
    if (calculateSizeLocal)
    {
        NSInteger progressCalculateSizeLocal = [self getProgress:region key:kWeatherProgressCalculateSizeLocalSuffix];
        [self setProgress:region key:kWeatherProgressCalculateSizeLocalSuffix value:++progressCalculateSizeLocal];
        CGFloat progress = (CGFloat) progressCalculateSizeLocal / progressDestination;

        NSInteger oldSizeLocal = [self.class getPreferenceSizeLocal:region.regionId];
        [self.class setPreferenceSizeLocal:region.regionId value:oldSizeLocal + sizeLocal];

        if (sizeLocal == 0 && oldSizeLocal == 0)
        {
            [_weatherForecastDownloadingObserver notifyEventWithKey:self andValue:region];
        }
        else if (progress == 1.)
        {
            NSInteger status = [self.class getPreferenceStatus:region.regionId];
            if (status & EOAWeatherForecastStatusCalculating)
                status &= ~EOAWeatherForecastStatusCalculating;
            [self.class setPreferenceStatus:region.regionId value:status | EOAWeatherForecastStatusLocalCalculated];
            [_weatherSizeLocalCalculateObserver notifyEventWithKey:self andValue:region];
            [_weatherDownloaderQueue removeOperations:[region.regionId stringByAppendingString:kWeatherProgressCalculateSizeLocalSuffix]];
            [self removeProgress:region key:kWeatherProgressCalculateSizeLocalSuffix];
            [self removeProgress:region key:kWeatherProgressDestinationSuffix];
        }
    }
    else if (calculateSizeUpdates)
    {
        NSInteger progressCalculateSizeLocal = [self getProgress:region key:kWeatherProgressCalculateSizeUpdatesSuffix];
        [self setProgress:region key:kWeatherProgressCalculateSizeUpdatesSuffix value:++progressCalculateSizeLocal];
        CGFloat progress = (CGFloat) progressCalculateSizeLocal / progressDestination;

        NSInteger oldSizeUpdates = [self.class getPreferenceSizeUpdates:region.regionId];
        [self.class setPreferenceSizeUpdates:region.regionId value:oldSizeUpdates + sizeUpdates];

        if (sizeUpdates == 0 && oldSizeUpdates == 0)
        {
            [_weatherForecastDownloadingObserver notifyEventWithKey:self andValue:region];
        }
        else if (progress == 1.)
        {
            NSInteger status = [self.class getPreferenceStatus:region.regionId];
            if (status & EOAWeatherForecastStatusCalculating)
                status &= ~EOAWeatherForecastStatusCalculating;
            [self.class setPreferenceStatus:region.regionId value:status | EOAWeatherForecastStatusUpdatesCalculated];
            [_weatherSizeUpdatesCalculateObserver notifyEventWithKey:self andValue:region];
            [_weatherDownloaderQueue removeOperations:[region.regionId stringByAppendingString:kWeatherProgressCalculateSizeUpdatesSuffix]];
            [self removeProgress:region key:kWeatherProgressCalculateSizeUpdatesSuffix];
            [self removeProgress:region key:kWeatherProgressDestinationSuffix];
        }
    }
    else
    {
        NSInteger progressDownloading = [self getProgress:region key:kWeatherProgressDownloadingSuffix];
        [self setProgress:region key:kWeatherProgressDownloadingSuffix value:++progressDownloading];
        CGFloat progress = (CGFloat) progressDownloading / progressDestination;

        NSInteger oldSizeLocal = [self.class getPreferenceSizeLocal:region.regionId];
        [self.class setPreferenceSizeLocal:region.regionId value:oldSizeLocal + sizeLocal];

        OALog(@"Weather offline forecast download %@ : %f %@", region.regionId, progress, success ? @"done" : @"error");

        if (progress < 1.)
        {
            [_weatherForecastDownloadingObserver notifyEventWithKey:self andValue:region];
        }
        else if (progress == 1.)
        {
            [self.class setPreferenceStatus:region.regionId value:EOAWeatherForecastStatusDownloaded | EOAWeatherForecastStatusLocalCalculated | EOAWeatherForecastStatusUpdatesCalculated];
            NSTimeInterval timeInterval = [NSCalendar.autoupdatingCurrentCalendar startOfDayForDate:[NSDate date]].timeIntervalSince1970;
            [self.class setPreferenceLastUpdate:region.regionId value:timeInterval];
            [_weatherForecastDownloadingObserver notifyEventWithKey:self andValue:region];

            [_weatherDownloaderQueue removeOperations:[region.regionId stringByAppendingString:kWeatherProgressDownloadingSuffix]];
            [self removeProgress:region key:kWeatherProgressDownloadingSuffix];
            [self removeProgress:region key:kWeatherProgressDestinationSuffix];

            OAMapViewController *mapViewController = [OARootViewController instance].mapPanel.mapViewController;
            [mapViewController.mapLayers.weatherLayerLow updateWeatherLayer];
            [mapViewController.mapLayers.weatherLayerHigh updateWeatherLayer];
            [mapViewController.mapLayers.weatherContourLayer updateWeatherLayer];
        }
    }
}

@end
