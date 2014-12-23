//
//  OsmAndAppImpl.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OsmAndAppImpl.h"

#import <UIKit/UIKit.h>
#import <QuickDialog.h>
#import <QElement.h>
#import <QElement+Appearance.h>

#import "OsmAndApp.h"
#import "OAResourcesInstaller.h"
#import "OADaytimeAppearance.h"
#import "OANighttimeAppearance.h"
#import "OAQFlatAppearance.h"
#import "OAAutoObserverProxy.h"
#import "OAUtilities.h"
#import "OALog.h"
#import <Reachability.h>

#include <algorithm>

#include <QList>

#include <OsmAndCore.h>
#import "OAAppSettings.h"
#include <OsmAndCore/IFavoriteLocation.h>

#define _(name)
@implementation OsmAndAppImpl
{
    NSString* _worldMiniBasemapFilename;

    OAAppMode _appMode;
    OAMapMode _mapMode;

    OAResourcesInstaller* _resourcesInstaller;

    OAAutoObserverProxy* _downloadsManagerActiveTasksCollectionChangeObserver;
}

@synthesize dataPath = _dataPath;
@synthesize dataDir = _dataDir;
@synthesize documentsPath = _documentsPath;
@synthesize documentsDir = _documentsDir;
@synthesize cachePath = _cachePath;
@synthesize cacheDir = _cacheDir;

@synthesize resourcesManager = _resourcesManager;
@synthesize localResourcesChangedObservable = _localResourcesChangedObservable;
@synthesize resourcesRepositoryUpdatedObservable = _resourcesRepositoryUpdatedObservable;

@synthesize favoritesCollection = _favoritesCollection;
@synthesize gpxCollection = _gpxCollection;

#if defined(OSMAND_IOS_DEV)
@synthesize debugSettings = _debugSettings;
#endif // defined(OSMAND_IOS_DEV)

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Get default paths
        _dataPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
        _dataDir = QDir(QString::fromNSString(_dataPath));
        _documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        _documentsDir = QDir(QString::fromNSString(_documentsPath));
        _cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        _cacheDir = QDir(QString::fromNSString(_cachePath));

        // First of all, initialize user defaults
        [[NSUserDefaults standardUserDefaults] registerDefaults:[self inflateInitialUserDefaults]];

#if defined(OSMAND_IOS_DEV)
        _debugSettings = [[OADebugSettings alloc] init];
#endif // defined(OSMAND_IOS_DEV)
    }
    return self;
}

- (void)dealloc
{
    _resourcesManager->localResourcesChangeObservable.detach((__bridge const void*)self);
    _resourcesManager->repositoryUpdateObservable.detach((__bridge const void*)self);

    _favoritesCollection->collectionChangeObservable.detach((__bridge const void*)self);
    _favoritesCollection->favoriteLocationChangeObservable.detach((__bridge const void*)self);
}

#define kAppData @"app_data"

- (BOOL)initialize
{
    NSError* versionError = nil;

    OALog(@"Data path: %@", _dataPath);
    OALog(@"Documents path: %@", _documentsPath);
    OALog(@"Cache path: %@", _cachePath);

    // Unpack app data
    _data = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:kAppData]];

    // Get location of a shipped world mini-basemap and it's version stamp
    _worldMiniBasemapFilename = [[NSBundle mainBundle] pathForResource:@"WorldMiniBasemap"
                                                                ofType:@"obf"
                                                           inDirectory:@"Shipped"];
    NSString* worldMiniBasemapStamp = [[NSBundle mainBundle] pathForResource:@"WorldMiniBasemap.obf"
                                                                      ofType:@"stamp"
                                                                 inDirectory:@"Shipped"];
    NSString* worldMiniBasemapStampContents = [NSString stringWithContentsOfFile:worldMiniBasemapStamp
                                                                        encoding:NSASCIIStringEncoding
                                                                           error:&versionError];
    NSString* worldMiniBasemapVersion = [worldMiniBasemapStampContents stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    OALog(@"Located shipped world mini-basemap (version %@) at %@", worldMiniBasemapVersion, _worldMiniBasemapFilename);

    _localResourcesChangedObservable = [[OAObservable alloc] init];
    _resourcesRepositoryUpdatedObservable = [[OAObservable alloc] init];
    _resourcesManager.reset(new OsmAnd::ResourcesManager(_dataDir.absoluteFilePath(QLatin1String("Resources")),
                                                         _documentsDir.absolutePath(),
                                                         QList<QString>(),
                                                         _worldMiniBasemapFilename != nil
                                                            ? QString::fromNSString(_worldMiniBasemapFilename)
                                                            : QString::null,
                                                         QString::fromNSString(NSTemporaryDirectory())));
    _resourcesManager->localResourcesChangeObservable.attach((__bridge const void*)self,
                                                             [self]
                                                             (const OsmAnd::ResourcesManager* const resourcesManager,
                                                              const QList< QString >& added,
                                                              const QList< QString >& removed,
                                                              const QList< QString >& updated)
                                                             {
                                                                 [_localResourcesChangedObservable notifyEventWithKey:self];
                                                             });
    _resourcesManager->repositoryUpdateObservable.attach((__bridge const void*)self,
                                                         [self]
                                                         (const OsmAnd::ResourcesManager* const resourcesManager)
                                                         {
                                                             [_resourcesRepositoryUpdatedObservable notifyEventWithKey:self];
                                                         });

    // Load favorites
    _favoritesCollectionChangedObservable = [[OAObservable alloc] init];
    _favoriteChangedObservable = [[OAObservable alloc] init];
    _favoritesFilename = _documentsDir.filePath(QLatin1String("Favorites.gpx")).toNSString();
    _favoritesCollection.reset(new OsmAnd::FavoriteLocationsGpxCollection());
    _favoritesCollection->loadFrom(QString::fromNSString(_favoritesFilename));
    _favoritesCollection->collectionChangeObservable.attach((__bridge const void*)self,
                                                            [self]
                                                            (const OsmAnd::IFavoriteLocationsCollection* const collection)
                                                            {
                                                                [_favoritesCollectionChangedObservable notifyEventWithKey:self];
                                                            });
    _favoritesCollection->favoriteLocationChangeObservable.attach((__bridge const void*)self,
                                                                  [self]
                                                                  (const OsmAnd::IFavoriteLocationsCollection* const collection,
                                                                   const std::shared_ptr<const OsmAnd::IFavoriteLocation>& favoriteLocation)
                                                                  {
                                                                      [_favoriteChangedObservable notifyEventWithKey:self
                                                                                                            andValue:favoriteLocation->getTitle().toNSString()];
                                                                  });
    
    
    // Load GPX
//    _gpxCollectionChangedObservable = [[OAObservable alloc] init];
//    _gpxChangedObservable = [[OAObservable alloc] init];
    _gpxFilename = _documentsDir.filePath(QLatin1String("GPX.gpx")).toNSString();
    _gpxCollection.reset(new OsmAnd::GpxDocument());
    _gpxCollection = OsmAnd::GpxDocument::loadFrom(QString::fromNSString(_gpxFilename));
    
//    _gpxCollection->collectionChangeObservable.attach((__bridge const void*)self,
//                                                            [self]
//                                                            (const OsmAnd::IFavoriteLocationsCollection* const collection)
//                                                            {
//                                                                [_gpxCollectionChangedObservable notifyEventWithKey:self];
//                                                            });
//    _gpxCollection->favoriteLocationChangeObservable.attach((__bridge const void*)self,
//                                                                  [self]
//                                                                  (const OsmAnd::IFavoriteLocationsCollection* const collection,
//                                                                   const std::shared_ptr<const OsmAnd::IFavoriteLocation>& favoriteLocation)
//                                                                  {
//                                                                      [_gpxChangedObservable notifyEventWithKey:self
//                                                                                                            andValue:favoriteLocation->getTitle().toNSString()];
//                                                                  });
    
    
    
    

    // Load resources list
    
    // If there's no repository available and there's internet connection, just update it
    if (!self.resourcesManager->isRepositoryAvailable() && [Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            self.resourcesManager->updateRepository();
        });
    }
    
    // Load world regions
    NSString* worldRegionsFilename = [[NSBundle mainBundle] pathForResource:@"regions"
                                                                     ofType:@"ocbf"];
    _worldRegion = [OAWorldRegion loadFrom:worldRegionsFilename];

    _appMode = OAAppModeBrowseMap;
    _appModeObservable = [[OAObservable alloc] init];

    _mapMode = OAMapModeFree;
    _mapModeObservable = [[OAObservable alloc] init];

    _locationServices = [[OALocationServices alloc] initWith:self];
    if (_locationServices.available && _locationServices.allowed)
        [_locationServices start];

    _downloadsManager = [[OADownloadsManager alloc] init];
    _downloadsManagerActiveTasksCollectionChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                                     withHandler:@selector(onDownloadManagerActiveTasksCollectionChanged)
                                                                                      andObserve:_downloadsManager.activeTasksCollectionChangedObservable];
    
    _resourcesInstaller = [[OAResourcesInstaller alloc] init];

    [self updateScreenTurnOffSetting];

    _appearance = [[OADaytimeAppearance alloc] init];
    _appearanceChangeObservable = [[OAObservable alloc] init];
    if ([OAUtilities iosVersionIsAtLeast:@"7.0"])
        QElement.appearance = [[OAQFlatAppearance alloc] init];

    return YES;
}

- (void)shutdown
{
    [_locationServices stop];
    _locationServices = nil;

    _downloadsManager = nil;
}

- (NSDictionary*)inflateInitialUserDefaults
{
    NSMutableDictionary* initialUserDefaults = [[NSMutableDictionary alloc] init];

    [initialUserDefaults setValue:[NSKeyedArchiver archivedDataWithRootObject:[OAAppData defaults]]
                           forKey:kAppData];

    return initialUserDefaults;
}

@synthesize data = _data;
@synthesize worldRegion = _worldRegion;

@synthesize locationServices = _locationServices;
@synthesize downloadsManager = _downloadsManager;

- (OAAppMode)appMode
{
    return _appMode;
}

- (void)setAppMode:(OAAppMode)appMode
{
    if (_appMode == appMode)
        return;
    _appMode = appMode;
    [_appModeObservable notifyEvent];
}

@synthesize appModeObservable = _appModeObservable;

- (OAMapMode)mapMode
{
    return _mapMode;
}

- (void)setMapMode:(OAMapMode)mapMode
{
    if (_mapMode == mapMode)
        return;
    _mapMode = mapMode;
    [[NSUserDefaults standardUserDefaults] setInteger:_mapMode forKey:kUDLastMapModePositionTrack];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [_mapModeObservable notifyEvent];
}

@synthesize mapModeObservable = _mapModeObservable;

@synthesize favoritesCollectionChangedObservable = _favoritesCollectionChangedObservable;
@synthesize favoriteChangedObservable = _favoriteChangedObservable;

@synthesize gpxCollectionChangedObservable = _gpxCollectionChangedObservable;
@synthesize gpxChangedObservable = _gpxChangedObservable;

@synthesize favoritesStorageFilename = _favoritesFilename;
@synthesize gpxStorageFilename = _gpxFilename;

- (void)saveDataToPermamentStorage
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

    // App data
    [userDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:_data]
                                              forKey:kAppData];
    [userDefaults synchronize];

    // Favorites
    [self saveFavoritesToPermamentStorage];

    // GPX
    [self saveGPXToPermamentStorage];
}

- (void)saveFavoritesToPermamentStorage
{
    _favoritesCollection->saveTo(QString::fromNSString(_favoritesFilename));
}

- (void)saveGPXToPermamentStorage
{
    _gpxCollection->saveTo(QString::fromNSString(_gpxFilename));
}

- (TTTLocationFormatter*)locationFormatterDigits
{
    TTTLocationFormatter* formatter = [[TTTLocationFormatter alloc] init];

    OAAppSettings* settings = [OAAppSettings sharedManager];

    if (settings.settingGeoFormat == 0) // Degree
        formatter.coordinateStyle = TTTDegreesFormat;
    else
        formatter.coordinateStyle = TTTDegreesMinutesSecondsFormat;

    [formatter.numberFormatter setMaximumSignificantDigits:7];
    
    if (settings.settingMetricSystem == METRIC_SYSTEM_METERS)
        formatter.unitSystem = TTTMetricSystem;
    else
        formatter.unitSystem = TTTImperialSystem;
        

    return formatter;
}
-(NSString*) getFormattedDistance:(float) meters {
    OAAppSettings* settings = [OAAppSettings sharedManager];
    NSString* mainUnitStr = @"km";
    float mainUnitInMeters;
    if (settings.settingMetricSystem == METRIC_SYSTEM_METERS) {
        mainUnitInMeters = METERS_IN_KILOMETER;
    } else {
        mainUnitStr = @"mi";
        mainUnitInMeters = METERS_IN_ONE_MILE;
    }
    if (meters >= 100 * mainUnitInMeters) {
        return [NSString stringWithFormat:@"%0.d %@",  (int) (meters / mainUnitInMeters + 0.5), mainUnitStr];
    } else if (meters > 9.99f * mainUnitInMeters) {
        return [NSString stringWithFormat:@"%0.0f %@",  ((float) meters) / mainUnitInMeters, mainUnitStr];
    } else if (meters > 0.999f * mainUnitInMeters) {
        return [NSString stringWithFormat:@"%0.00f %@",  ((float) meters) / mainUnitInMeters, mainUnitStr];
    } else {
        if (settings.settingMetricSystem == METRIC_SYSTEM_METERS) {
            return [NSString stringWithFormat:@"%0.d %@",   ((int) (meters + 0.5)), @"m"];
        } else if (settings.settingMetricSystem == METRIC_SYSTEM_FEET) {
            int foots = (int) (meters * FOOTS_IN_ONE_METER + 0.5);
            return [NSString stringWithFormat:@"%0.d %@", foots, @"ft"];
        } else if (settings.settingMetricSystem == METRIC_SYSTEM_YARDS) {
            int yards = (int) (meters * YARDS_IN_ONE_METER + 0.5);
            return [NSString stringWithFormat:@"%0.d %@", yards, @"yd"];
        }
        return [NSString stringWithFormat:@"%0.d %@",   ((int) (meters + 0.5)), @"m"];
    }
}

- (double) calculateRoundedDist:(double) distInMeters {
    OAAppSettings* settings = [OAAppSettings sharedManager];
    double mainUnitInMeter = 1;
    double metersInSecondUnit = METERS_IN_KILOMETER;
    if (settings.settingMetricSystem == METRIC_SYSTEM_FEET)
    {
        mainUnitInMeter = FOOTS_IN_ONE_METER;
        metersInSecondUnit = METERS_IN_ONE_MILE;
    }
    else if (settings.settingMetricSystem == METRIC_SYSTEM_YARDS)
    {
        mainUnitInMeter = YARDS_IN_ONE_METER;
        metersInSecondUnit = METERS_IN_ONE_MILE;
    }
    // 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000 ...
    
    int generator = 1;
    int pointer = 1;
    double point = mainUnitInMeter;
    while (distInMeters * point > generator) {
        if (pointer++ % 3 == 2) {
            generator = generator * 5 / 2;
        } else {
            generator *= 2;
        }
        if (point == mainUnitInMeter && metersInSecondUnit * mainUnitInMeter * 0.9f <= generator) {
            point = 1 / metersInSecondUnit;
            generator = 1;
            pointer = 1;
        }
    }
    
    return (generator / point);
}



- (TTTLocationFormatter*)locationFormatter
{
    TTTLocationFormatter* formatter = [[TTTLocationFormatter alloc] init];
    
    OAAppSettings* settings = [OAAppSettings sharedManager];
    
    if (settings.settingGeoFormat == 0) // Degree
        formatter.coordinateStyle = TTTDegreesFormat;
    else
        formatter.coordinateStyle = TTTDegreesMinutesSecondsFormat;
    
    if (settings.settingMetricSystem)
        formatter.unitSystem = TTTImperialSystem;
    else
        formatter.unitSystem = TTTMetricSystem;
    
    return formatter;
}



- (unsigned long long)freeSpaceAvailableOnDevice
{
    NSError* error = nil;

    NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:_dataPath
                                                                                       error:&error];
    if (error)
    {
        OALog(@"Failed to get free space: %@", error);
        return 0;
    }

    return [[attributes objectForKey:NSFileSystemFreeSize] unsignedLongLongValue];
}

- (BOOL)allowScreenTurnOff
{
    BOOL allowScreenTurnOff = YES;

    allowScreenTurnOff = allowScreenTurnOff && _downloadsManager.allowScreenTurnOff;
    allowScreenTurnOff = allowScreenTurnOff && (_appMode == OAAppModeBrowseMap);

    return allowScreenTurnOff;
}

- (void)updateScreenTurnOffSetting
{
    BOOL allowScreenTurnOff = self.allowScreenTurnOff;

    if (allowScreenTurnOff)
        OALog(@"Going to enable screen turn-off");
    else
        OALog(@"Going to disable screen turn-off");

    [UIApplication sharedApplication].idleTimerDisabled = !allowScreenTurnOff;
}

@synthesize appearance = _appearance;
@synthesize appearanceChangeObservable = _appearanceChangeObservable;

- (void)onDownloadManagerActiveTasksCollectionChanged
{
    // In background, don't change screen turn-off setting
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
        return;

    [self updateScreenTurnOffSetting];
}

- (void)onApplicationWillResignActive
{
}

- (void)onApplicationDidEnterBackground
{
    [self saveDataToPermamentStorage];

    // In background allow to turn off screen
    OALog(@"Going to enable screen turn-off");
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void)onApplicationWillEnterForeground
{
    [self updateScreenTurnOffSetting];
}

- (void)onApplicationDidBecomeActive
{
}

@end
