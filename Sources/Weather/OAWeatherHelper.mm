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
#import "OAManageResourcesViewController.h"
#import "OAMapLayers.h"
#import "OALog.h"
#import "OANativeUtilities.h"
#import "OAIAPHelper.h"
#import "OAWeatherPlugin.h"
#import "OAColors.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import "OsmAnd_Maps-Swift.h"
#import "OAPluginsHelper.h"

#include <OsmAndCore/Map/WeatherTileResourceProvider.h>
#include <OsmAndCore/Map/WeatherTileResourcesManager.h>
#include <OsmAndCore/FunctorQueryController.h>
#include <OsmAndCore/WorldRegions.h>

#define kWeatherForecastLastUpdatePrefix @"forecast_last_update_"
#define kWeatherForecastFrequencyPrefix @"forecast_frequency_"
#define kWeatherForecastAutoUpdatePrefix @"forecast_auto_update_"
#define kWeatherForecastTileIdsPrefix @"forecast_tile_ids_"
// needed for flag compatibility kWeatherForecastAutoUpdatePrefix
#define kWeatherForecastWifiPrefix @"forecast_download_via_wifi_"

#define kForecastDatesCount (24 + (6 * 8) + 1)

#define kWeatherForecastFrequencyHalfDay 43200
#define kWeatherForecastFrequencyDay 86400
#define kWeatherForecastFrequencyWeek 604800

@implementation OAWeatherHelper
{
    OsmAndAppInstance _app;
    std::shared_ptr<OsmAnd::WeatherTileResourcesManager> _weatherResourcesManager;
    OAAutoObserverProxy* _downloadTaskProgressObserver;
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
    OsmAndAppInstance app = [OsmAndApp instance];
    NSArray<NSString *> *ids = [OAManageResourcesViewController getResourcesInRepositoryIdsByRegion:region];
    for (NSString *resourceId in ids)
    {
        const auto& resource = app.resourcesManager->getResourceInRepository(QString::fromNSString(resourceId));
        if (resource && resource->type == OsmAnd::ResourcesManager::ResourceType::WeatherForecast)
            return YES;
    }
    return NO;
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
            EOAWeatherAutoUpdate state = [OAWeatherHelper getPreferenceWeatherAutoUpdate:regionId];
            if (state == EOAWeatherAutoUpdateDisabled)
                continue;
            
            if (!networkManager.isReachableViaWiFi && state == EOAWeatherAutoUpdateOverWIFIOnly)
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

- (id<OADownloadTask>) getDownloadTaskFor:(NSString*)resourceId
{
    return [[_app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resourceId]] firstObject];
}

- (void)downloadForecastByRegion:(OAWorldRegion *)region
{
    if (![[OAPluginsHelper getPlugin:OAWeatherPlugin.class] isEnabled] || ![OAIAPHelper isOsmAndProAvailable])
        return;

    NSString *regionId = [self.class checkAndGetRegionId:region];

    AFNetworkReachabilityManager *networkManager = [AFNetworkReachabilityManager sharedManager];
    if (!networkManager.isReachable)
        return;
    else if (!networkManager.isReachableViaWiFi && [OAWeatherHelper getPreferenceWeatherAutoUpdate:regionId] == EOAWeatherAutoUpdateOverWIFIOnly)
        return;
    NSString *resourceId = [region.downloadsIdPrefix stringByAppendingString:@"tifsqlite"];
    const auto localResource = _app.resourcesManager->getLocalResource(QString::fromNSString(resourceId));
    OAResourceItem *localResourceItem;
    if (localResource)
    {
        OALocalResourceItem *item = [[OALocalResourceItem alloc] init];
        item.resourceId = localResource->id;
        item.resourceType = localResource->type;
        item.resource = localResource;
        item.downloadTask = [self getDownloadTaskFor:localResource->id.toNSString()];
        item.size = localResource->size;
        item.worldRegion = region;
        const auto repositoryResource = _app.resourcesManager->getResourceInRepository(item.resourceId);
        item.sizePkg = repositoryResource->packageSize;
        NSString *localResourcePath = _app.resourcesManager->getLocalResource(item.resourceId)->localPath.toNSString();
        item.date = [[[NSFileManager defaultManager] attributesOfItemAtPath:localResourcePath error:NULL] fileModificationDate];
        localResourceItem = item;
    }
    else
    {
        const auto& resource = _app.resourcesManager->getResourceInRepository(QString::fromNSString(resourceId));
        if (resource) {
            OARepositoryResourceItem* item = [[OARepositoryResourceItem alloc] init];
            item.resourceId = resource->id;
            item.resourceType = resource->type;
            item.resource = resource;
            item.downloadTask = [[_app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]] firstObject];
            item.size = resource->size;
            item.sizePkg = resource->packageSize;
            item.worldRegion = region;
            item.date = [NSDate dateWithTimeIntervalSince1970:(resource->timestamp / 1000)];
            localResourceItem = item;
        }
    }
    if (localResourceItem) {
        [OAResourcesUIHelper offerDownloadAndInstallOf:(OARepositoryResourceItem *)localResourceItem onTaskCreated:nil onTaskResumed:nil];
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

- (void)preparingForDownloadForecastByRegion:(OAWorldRegion *)region regionId:(NSString *)regionId
{
    [self.class updatePreferenceTileIdsIfNeeded:region];
    [_weatherForecastDownloadingObserver notifyEventWithKey:self andValue:region];
}

- (void)calculateCacheSize:(OAWorldRegion *)region onComplete:(void (^)())onComplete
{
    [self.class updatePreferenceTileIdsIfNeeded:region];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_weatherSizeCalculatedObserver notifyEventWithKey:self andValue:region];
        if (onComplete)
            onComplete();
    });
}

- (void)calculateFullCacheSize:(BOOL)localData
                    onComplete:(void (^)(unsigned long long))onComplete;

{
    if (localData)
    {
        if (onComplete)
            onComplete([self getOfflineWeatherForecastCacheSize]);
    }
    else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            QList<OsmAnd::TileId> qTileIds = [OANativeUtilities convertToQListTileIds:[self getOfflineTileIds:nil]];
            OsmAnd::ZoomLevel zoom = OsmAnd::WeatherTileResourceProvider::getGeoTileZoom();;
            unsigned long long size = self.onlineCacheSize;
            if (size == 0)
            {
                size = _weatherResourcesManager->calculateDbCacheSize(QList<OsmAnd::TileId>(), qTileIds, zoom);
                _onlineCacheSize = size;
            }

            if (onComplete)
                onComplete(size);
        });
    }
}

- (BOOL)isUndefinedDownloadStateFor:(OAWorldRegion *)region
{
    auto state = [self getDownloadTaskFor:[region.downloadsIdPrefix stringByAppendingString:@"tifsqlite"]].state;
    return state != OADownloadTaskStateRunning && state != OADownloadTaskStateFinished;
}

- (BOOL)isDownloadedWeatherForecastForRegionId:(NSString *)regionId
{
    OAWorldRegion *worldRegion = [OsmAndApp instance].worldRegion;
    OAWorldRegion *region = [worldRegion.regionId isEqualToString:regionId]
    	? worldRegion : [[OsmAndApp instance].worldRegion getFlattenedSubregion:regionId];
    if (region && region.downloadsIdPrefix.length > 1)
    {
        const auto downloadsIdPrefix = QString::fromNSString(region.downloadsIdPrefix);
        const auto& localResources = [OsmAndApp instance].resourcesManager->getLocalResources();
        for (const auto& localResource : localResources)
        {
            const auto localId = localResource->id.toLower();
            if (localResource->type == OsmAndResourceType::WeatherForecast && localId.startsWith(downloadsIdPrefix))
                return YES;
        }
    }
    return NO;
}

- (NSArray<NSString *> *)getRegionIdsForDownloadedWeatherForecast
{
    NSMutableArray<NSString *> *regionIds = [NSMutableArray new];
    const auto& localResources = [OsmAndApp instance].resourcesManager->getLocalResources();
    for (OAWorldRegion *region in [@[[OsmAndApp instance].worldRegion] arrayByAddingObjectsFromArray:[OsmAndApp instance].worldRegion.flattenedSubregions])
    {
		if (region.downloadsIdPrefix.length > 1)
        {
            const auto downloadsIdPrefix = QString::fromNSString(region.downloadsIdPrefix);
            for (const auto& localResource : localResources)
                if (localResource->type == OsmAndResourceType::WeatherForecast && localResource->id.toLower().startsWith(downloadsIdPrefix))
                    [regionIds addObject:region.regionId];
        }
    }
    return regionIds;
}

- (uint64_t)getOfflineWeatherForecastCacheSize
{
    uint64_t size = 0;
    const auto& localResources = [OsmAndApp instance].resourcesManager->getLocalResources();
    for (const auto& localResource : localResources)
        if (localResource->type == OsmAndResourceType::WeatherForecast)
        {
            const auto& repositoryResource = _app.resourcesManager->getResourceInRepository(localResource->id);
            size += repositoryResource != nil ? repositoryResource->size : localResource->size;
        }

    return size;
}

- (void)clearCache:(BOOL)localData regionIds:(NSArray<NSString *> *)regionIds region:(OAWorldRegion *)region
{
    if (localData)
    {
        if (!regionIds)
        {
            regionIds = [self getRegionIdsForDownloadedWeatherForecast];
        }
        
        if (region)
        {
            QString regionIdString = QString::fromNSString(region.downloadsIdPrefix).append("tifsqlite");
            const auto success = [OsmAndApp instance].resourcesManager->uninstallResource(regionIdString);
            if (!success)
            {
                OALog(@"[ERROR] clearCache fail uninstallResource for regionId: %@", regionIdString.toNSString());
            }
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
    _onlineCacheSize = 0.;
    NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
    calendar.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    NSDate *date = [calendar startOfDayForDate:[NSDate date]];
    int64_t dateTime = date.timeIntervalSince1970 * 1000;
    _weatherResourcesManager->clearDbCache(dateTime);

    NSArray<NSString *> *downloadedRegionIds = [self getRegionIdsForDownloadedWeatherForecast];
    for (OAWorldRegion *region in [@[_app.worldRegion] arrayByAddingObjectsFromArray:_app.worldRegion.flattenedSubregions])
    {
        if ([downloadedRegionIds containsObject:[self.class checkAndGetRegionId:region]])
            [self calculateCacheSize:region onComplete:nil];
    }
}

- (void)removeLocalForecast:(NSString *)regionId region:(OAWorldRegion *)region refreshMap:(BOOL)refreshMap
{
    [self removeLocalForecasts:@[regionId] region:(OAWorldRegion *)region refreshMap:refreshMap];
}

- (void)removeLocalForecasts:(NSArray<NSString *> *)regionIds region:(OAWorldRegion *)region refreshMap:(BOOL)refreshMap
{
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

        [self.class removePreferences:regionId];
        OsmAndAppInstance app = [OsmAndApp instance];
        QString regionIdString = QString::fromNSString(region.downloadsIdPrefix).append("tifsqlite");
        const auto success = app.resourcesManager->uninstallResource(regionIdString);
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
        regionIds = [self getRegionIdsForDownloadedWeatherForecast];
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
    if ([[OAWeatherHelper sharedInstance] isDownloadedWeatherForecastForRegionId:regionId])
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

- (BOOL)isContainsInOfflineRegions:(NSArray<NSNumber *> *)tileId excludeRegion:(NSString *)excludeRegionId
{
    NSArray<NSString *> *regionIds = [self getRegionIdsForDownloadedWeatherForecast];
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

- (uint64_t)getOfflineForecastSize:(OAWorldRegion *)region forUpdate:(BOOL)forUpdate
{
    NSString *resourceId = [region.downloadsIdPrefix stringByAppendingString:@"tifsqlite"];
    const auto repositoryResource = _app.resourcesManager->getResourceInRepository(QString::fromNSString(resourceId));
    if (repositoryResource)
    {
        if (forUpdate)
            return repositoryResource->packageSize;
        else
            return repositoryResource->size;
    }
    else
    {
        OALog(@"[WARNING] -> getOfflineForecastSize localResource is empty");
        return 0;
    }
}

- (NSInteger)getProgressDestination:(NSString *)regionId
{
    return [self.class getPreferenceTileIds:regionId].count * kForecastDatesCount;
}

- (void)setupDownloadStateFinished:(OAWorldRegion *)region regionId:(NSString *)regionId
{
    NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
    calendar.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    NSTimeInterval timeInterval = [NSDate date].timeIntervalSince1970;
    [self.class setPreferenceLastUpdate:regionId value:timeInterval];
    _onlineCacheSize = 0.;
    [_weatherForecastDownloadingObserver notifyEventWithKey:self andValue:region];

    dispatch_async(dispatch_get_main_queue(), ^{
        OAMapViewController *mapViewController = [OARootViewController instance].mapPanel.mapViewController;
        [mapViewController.mapLayers.weatherLayerLow updateWeatherLayer];
        [mapViewController.mapLayers.weatherLayerHigh updateWeatherLayer];
        [mapViewController.mapLayers.weatherContourLayer updateWeatherLayer];

        [self calculateCacheSize:region onComplete:nil];
    });
}

- (OAResourceItem *)generateResourceItem:(OAWorldRegion *)region
{
    NSString *regionId = [self.class checkAndGetRegionId:region];
    BOOL isEntireWorld = [regionId isEqualToString:kWeatherEntireWorldRegionId];
    OAResourceItem *item;
    auto state = [self getDownloadTaskFor:[region.downloadsIdPrefix stringByAppendingString:@"tifsqlite"]].state;
    if (state == OADownloadTaskStateRunning || state != OADownloadTaskStateFinished)
    {
        item = [[OARepositoryResourceItem alloc] init];
        NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
        calendar.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
        item.date = [calendar startOfDayForDate:[NSDate date]];
    }
    else
    {
        if ([self isDownloadedWeatherForecastForRegionId:regionId])
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
        item.size = [self getOfflineForecastSize:region forUpdate:NO];
        item.sizePkg = [self getOfflineForecastSize:region forUpdate:YES];
        item.worldRegion = region;
    }
    return item;
}

+ (NSAttributedString *)getStatusInfoDescription:(NSString *)regionId
{
    NSMutableAttributedString *attributedDescription = [NSMutableAttributedString new];
    BOOL downloaded = [[OAWeatherHelper sharedInstance] isDownloadedWeatherForecastForRegionId:regionId];
    BOOL outdated = [self isForecastOutdated:regionId];
    NSString *statusStr = outdated ? OALocalizedString(@"weather_forecast_is_outdated") : @"";
    if (outdated)
    {
        NSDictionary *outdatedStrAttributes = @{
                NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote],
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
            NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote],
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

+ (EOAWeatherAutoUpdate)getPreferenceWeatherAutoUpdate:(NSString *)regionId
{
    NSString *prefKey = [kWeatherForecastAutoUpdatePrefix stringByAppendingString:regionId];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:prefKey])
    {
        return (EOAWeatherAutoUpdate)[[NSUserDefaults standardUserDefaults] integerForKey:prefKey];
    }
    else
    {   // compatibility with old api
        BOOL isWIFI = [self getPreferenceWifi:regionId];
        if (isWIFI) {
            [[self class] setPreferenceWeatherAutoUpdate:regionId value:EOAWeatherAutoUpdateOverWIFIOnly];
            return EOAWeatherAutoUpdateOverWIFIOnly;
        }
        else
        {
            [[self class] setPreferenceWeatherAutoUpdate:regionId value:EOAWeatherAutoUpdateDisabled];
            return EOAWeatherAutoUpdateDisabled;
        }
    }
}

+ (void)setPreferenceWeatherAutoUpdate:(NSString *)regionId value:(EOAWeatherAutoUpdate)value
{
    NSString *prefKey = [kWeatherForecastAutoUpdatePrefix stringByAppendingString:regionId];
    [[NSUserDefaults standardUserDefaults] setInteger:value forKey:prefKey];
}

+ (NSString *)getPreferenceWeatherAutoUpdateString:(EOAWeatherAutoUpdate)value
{
    NSString *result = OALocalizedString(@"weather_update_disabled");
    switch (value) {
        case EOAWeatherAutoUpdateOverWIFIOnly:
            result = OALocalizedString(@"weather_update_over_wifi_only");
            break;
        case EOAWeatherAutoUpdateOverAnyNetwork:
            result = OALocalizedString(@"weather_update_over_any_network");
            break;
        default:break;
    }
    return result;
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

+ (NSArray<NSString *> *)getPreferenceKeys:(NSString *)regionId
{
    return @[
        [kWeatherForecastLastUpdatePrefix stringByAppendingString:regionId],
        [kWeatherForecastFrequencyPrefix stringByAppendingString:regionId],
        [kWeatherForecastTileIdsPrefix stringByAppendingString:regionId],
        [kWeatherForecastWifiPrefix stringByAppendingString:regionId],
        [kWeatherForecastAutoUpdatePrefix stringByAppendingString:regionId]
    ];
}

+ (void)removePreferences:(NSString *)regionId
{
    for (NSString *key in [self getPreferenceKeys:regionId])
    {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
}

+ (NSDate *) roundForecastTimeToHour:(NSDate *)date
{
    NSTimeInterval hour = 3600.0;
    return [NSDate dateWithTimeIntervalSince1970:round(date.timeIntervalSince1970 / hour) * hour];
}

- (BOOL)allLayersAreDisabled
{
    NSArray<OAWeatherBand *> *bandsArray = self.bands;
    NSMutableArray<NSNumber *> *isVisibleArray = [[NSMutableArray alloc] initWithCapacity:bandsArray.count];
    for (OAWeatherBand *band in bandsArray) {
        [isVisibleArray addObject:@([band isBandVisible])];
    }
    
    BOOL allDisabled = YES;
    for (NSNumber *isVisibleNumber in isVisibleArray) {
        BOOL isVisible = [isVisibleNumber boolValue];
        if (isVisible) {
            allDisabled = NO;
            break;
        }
    }
    
    return allDisabled;
}

@end
