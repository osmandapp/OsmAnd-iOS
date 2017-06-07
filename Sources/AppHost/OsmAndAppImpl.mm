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
#import "OAManageResourcesViewController.h"
#import "OAPOIHelper.h"
#import "OAIAPHelper.h"
#import "Localization.h"
#import "OASavingTrackHelper.h"
#import "OAMapStyleSettings.h"
#import "OAGPXRouter.h"
#import "OAHillshadeLayer.h"
#import "OAMapCreatorHelper.h"
#import "OAOcbfHelper.h"
#import "OAQuickSearchHelper.h"
#import "OADiscountHelper.h"


#include <algorithm>

#include <QList>

#include <OsmAndCore.h>
#import "OAAppSettings.h"
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/IWebClient.h>
#include "OAWebClient.h"
#include "binaryRead.h"
#define _(name)
@implementation OsmAndAppImpl
{
    NSString* _worldMiniBasemapFilename;

    OAAppMode _appMode;
    OAMapMode _mapMode;
    OAMapMode _prevMapMode;

    OAResourcesInstaller* _resourcesInstaller;
    std::shared_ptr<OsmAnd::IWebClient> _webClient;

    OAAutoObserverProxy* _downloadsManagerActiveTasksCollectionChangeObserver;
    
    NSString *_unitsKm;
    NSString *_unitsm;
    NSString *_unitsMi;
    NSString *_unitsYd;
    NSString *_unitsFt;
    NSString *_unitsKmh;
    NSString *_unitsMph;
}

@synthesize dataPath = _dataPath;
@synthesize dataDir = _dataDir;
@synthesize documentsPath = _documentsPath;
@synthesize documentsDir = _documentsDir;
@synthesize gpxPath = _gpxPath;
@synthesize cachePath = _cachePath;

@synthesize resourcesManager = _resourcesManager;
@synthesize localResourcesChangedObservable = _localResourcesChangedObservable;
@synthesize resourcesRepositoryUpdatedObservable = _resourcesRepositoryUpdatedObservable;

@synthesize favoritesCollection = _favoritesCollection;

@synthesize dayNightModeObservable = _dayNightModeObservable;
@synthesize mapSettingsChangeObservable = _mapSettingsChangeObservable;
@synthesize updateGpxTracksOnMapObservable = _updateGpxTracksOnMapObservable;
@synthesize updateRecTrackOnMapObservable = _updateRecTrackOnMapObservable;
@synthesize updateRouteTrackOnMapObservable = _updateRouteTrackOnMapObservable;
@synthesize trackStartStopRecObservable = _trackStartStopRecObservable;
@synthesize addonsSwitchObservable = _addonsSwitchObservable;

@synthesize trackRecordingObservable = _trackRecordingObservable;
@synthesize isRepositoryUpdating = _isRepositoryUpdating;

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
        _gpxPath = [_documentsPath stringByAppendingPathComponent:@"GPX"];

        _cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];

        [self buildFolders];
        
        // Init units localization
        _unitsKm = OALocalizedString(@"units_km");
        _unitsm = OALocalizedString(@"units_m");
        _unitsMi = OALocalizedString(@"units_mi");
        _unitsYd = OALocalizedString(@"units_yd");
        _unitsFt = OALocalizedString(@"units_ft");
        _unitsKmh = OALocalizedString(@"units_kmh");
        _unitsMph = OALocalizedString(@"units_mph");
        
        // First of all, initialize user defaults
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults registerDefaults:[self inflateInitialUserDefaults]];
        NSDictionary *defHideAllGPX = [NSDictionary dictionaryWithObject:@"NO" forKey:@"hide_all_gpx"];
        [defaults registerDefaults:defHideAllGPX];
        NSDictionary *defResetSettings = [NSDictionary dictionaryWithObject:@"NO" forKey:@"reset_settings"];
        [defaults registerDefaults:defResetSettings];

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

- (void) buildFolders
{
    NSError *error;
    BOOL success;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:_gpxPath])
    {
        success = [[NSFileManager defaultManager]
                   createDirectoryAtPath:_gpxPath
                   withIntermediateDirectories:NO
                   attributes:nil error:&error];
        
        if (!success)
        {
            OALog(@"Error creating GPX folder: %@", error.localizedFailureReason);
            return;
        }
        
    }
}

- (BOOL)initialize
{
    NSError* versionError = nil;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL hideAllGPX = [defaults boolForKey:@"hide_all_gpx"];
    BOOL resetSettings = [defaults boolForKey:@"reset_settings"];
    if (hideAllGPX)
    {
        OAAppSettings *settings = [OAAppSettings sharedManager];
        [settings setMapSettingVisibleGpx:@[]];
        [defaults setBool:NO forKey:@"hide_all_gpx"];
        [defaults synchronize];
    }
    if (resetSettings)
    {
        int freeMaps = -1;
        if ([defaults objectForKey:@"freeMapsAvailable"]) {
            freeMaps = (int)[defaults integerForKey:@"freeMapsAvailable"];
        }

        NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
        [defaults removePersistentDomainForName:appDomain];
        [defaults synchronize];
        
        if (freeMaps != -1) {
            [defaults setInteger:freeMaps forKey:@"freeMapsAvailable"];
        }
        
        [defaults registerDefaults:[self inflateInitialUserDefaults]];
        NSDictionary *defHideAllGPX = [NSDictionary dictionaryWithObject:@"NO" forKey:@"hide_all_gpx"];
        [defaults registerDefaults:defHideAllGPX];
        NSDictionary *defResetSettings = [NSDictionary dictionaryWithObject:@"NO" forKey:@"reset_settings"];
        [defaults registerDefaults:defResetSettings];

        _data = [OAAppData defaults];
        [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:_data]
                         forKey:kAppData];
        [defaults setBool:NO forKey:@"hide_all_gpx"];
        [defaults setBool:NO forKey:@"reset_settings"];
        [defaults synchronize];
    }

    OALog(@"Data path: %@", _dataPath);
    OALog(@"Documents path: %@", _documentsPath);
    OALog(@"GPX path: %@", _gpxPath);
    OALog(@"Cache path: %@", _cachePath);

    [OAUtilities clearTmpDirectory];
    
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
    
    _webClient = std::make_shared<OAWebClient>();
    
    _localResourcesChangedObservable = [[OAObservable alloc] init];
    _resourcesRepositoryUpdatedObservable = [[OAObservable alloc] init];
    _resourcesManager.reset(new OsmAnd::ResourcesManager(_dataDir.absoluteFilePath(QLatin1String("Resources")),
                                                         _documentsDir.absolutePath(),
                                                         QList<QString>() << QString::fromNSString([[NSBundle mainBundle] resourcePath]),
                                                         _worldMiniBasemapFilename != nil
                                                         ? QString::fromNSString(_worldMiniBasemapFilename)
                                                         : QString::null,
                                                         QString::fromNSString(NSTemporaryDirectory()),
                                                         QString::fromNSString(@"http://download.osmand.net"),
                                                         _webClient));
    
    _resourcesManager->localResourcesChangeObservable.attach((__bridge const void*)self,
                                                             [self]
                                                             (const OsmAnd::ResourcesManager* const resourcesManager,
                                                              const QList< QString >& added,
                                                              const QList< QString >& removed,
                                                              const QList< QString >& updated)
                                                             {
                                                                 [_localResourcesChangedObservable notifyEventWithKey:self];
                                                                 [OAResourcesBaseViewController setDataInvalidated];
                                                             });
    
    _resourcesManager->repositoryUpdateObservable.attach((__bridge const void*)self,
                                                         [self]
                                                         (const OsmAnd::ResourcesManager* const resourcesManager)
                                                         {
                                                             [_resourcesRepositoryUpdatedObservable notifyEventWithKey:self];
                                                         });

    // Check for NSURLIsExcludedFromBackupKey and setup if needed
    const auto& localResources = _resourcesManager->getLocalResources();
    for (const auto& resource : localResources)
    {
        if (resource->origin == OsmAnd::ResourcesManager::ResourceOrigin::Installed)
        {
            NSString *localPath = resource->localPath.toNSString();
            [self applyExcludedFromBackup:localPath];
        }
    }
    
    // Copy regions.ocbf to Library/Resources if needed
    NSString *ocbfPathBundle = [[NSBundle mainBundle] pathForResource:@"regions" ofType:@"ocbf"];
    NSString *ocbfPathLib = [NSHomeDirectory() stringByAppendingString:@"/Library/Resources/regions.ocbf"];
    
    if ([OAOcbfHelper isBundledOcbfNewer])
        [[NSFileManager defaultManager] removeItemAtPath:ocbfPathLib error:nil];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:ocbfPathLib])
    {
        NSError *error = nil;
        [[NSFileManager defaultManager] copyItemAtPath:ocbfPathBundle toPath:ocbfPathLib error:&error];
        if (error)
            NSLog(@"Error copying file: %@ to %@ - %@", ocbfPathBundle, ocbfPathLib, [error localizedDescription]);
    }
    [self applyExcludedFromBackup:ocbfPathLib];
    
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
    


    // Load resources list
    
    // If there's no repository available and there's internet connection, just update it
    if (!self.resourcesManager->isRepositoryAvailable() && [Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
    {
        [self startRepositoryUpdateAsync:YES];
    }

    // Load world regions
    [self loadWorldRegions];
    [OAManageResourcesViewController prepareData];
    
    [OAPOIHelper sharedInstance];
    [OAQuickSearchHelper instance];
    
    _appMode = OAAppModeBrowseMap;
    _appModeObservable = [[OAObservable alloc] init];

    _dayNightModeObservable = [[OAObservable alloc] init];
    _mapSettingsChangeObservable = [[OAObservable alloc] init];
    _updateGpxTracksOnMapObservable = [[OAObservable alloc] init];
    _updateRecTrackOnMapObservable = [[OAObservable alloc] init];
    _updateRouteTrackOnMapObservable = [[OAObservable alloc] init];
    _addonsSwitchObservable = [[OAObservable alloc] init];
 
    _trackRecordingObservable = [[OAObservable alloc] init];
    _trackStartStopRecObservable = [[OAObservable alloc] init];

    _mapMode = OAMapModeFree;
    _prevMapMode = OAMapModeFree;
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
    
    [OAMapStyleSettings sharedInstance];
    
    // Init track recorder
    [OASavingTrackHelper sharedInstance];
    
    // Init gpx router
    [OAGPXRouter sharedInstance];
    
    [OAMapCreatorHelper sharedInstance];
    [OAHillshadeLayer sharedInstance];
    
    [[OAIAPHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success) {}];
    
    [[Reachability reachabilityForInternetConnection] startNotifier];
    
    return YES;
}

- (void)startRepositoryUpdateAsync:(BOOL)async
{
    _isRepositoryUpdating = YES;
    
    if (async)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            
            self.resourcesManager->updateRepository();
            
            dispatch_async(dispatch_get_main_queue(), ^{
                _isRepositoryUpdating = NO;
            });
        });
    }
    else
    {
        self.resourcesManager->updateRepository();
        _isRepositoryUpdating = NO;
    }
}

- (void)loadWorldRegions
{
    NSString *ocbfPathLib = [NSHomeDirectory() stringByAppendingString:@"/Library/Resources/regions.ocbf"];
    _worldRegion = [OAWorldRegion loadFrom:ocbfPathLib];
}

- (void)applyExcludedFromBackup:(NSString *)localPath
{
    NSURL *url = [NSURL fileURLWithPath:localPath];
    
    id flag = nil;
    if ([url getResourceValue:&flag forKey:NSURLIsExcludedFromBackupKey error: nil])
    {
        OALog(@"NSURLIsExcludedFromBackupKey = %@ for %@", flag, localPath);
        if (!flag || [flag boolValue] == NO)
        {
            BOOL res = [url setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:nil];
            OALog(@"Set (%@) NSURLIsExcludedFromBackupKey for %@", (res ? @"OK" : @"FAILED"), localPath);
        }
    }
    else
    {
        OALog(@"NSURLIsExcludedFromBackupKey = %@ for %@", flag, localPath);
    }
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
    _prevMapMode = _mapMode;
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

- (void)saveDataToPermamentStorage
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

    // App data
    [userDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:_data]
                                              forKey:kAppData];
    [userDefaults synchronize];

    // Favorites
    [self saveFavoritesToPermamentStorage];

    // GPX Route
    [[OAGPXRouter sharedInstance] saveRoute];
}

- (void)saveFavoritesToPermamentStorage
{
    _favoritesCollection->saveTo(QString::fromNSString(_favoritesFilename));
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

-(NSString*) getFormattedTimeInterval:(NSTimeInterval)timeInterval shortFormat:(BOOL)shortFormat
{
    int hours, minutes, seconds;
    [OAUtilities getHMS:timeInterval hours:&hours minutes:&minutes seconds:&seconds];
    
    NSMutableString *time = [NSMutableString string];
    if (shortFormat)
    {
        if (hours > 0)
            [time appendFormat:@"%02d:", hours];
        
        [time appendFormat:@"%02d:", minutes];
        [time appendFormat:@"%02d", seconds];
    }
    else
    {
        if (hours > 0)
            [time appendFormat:@"%d %@", hours, OALocalizedString(@"units_hour")];
        if (minutes > 0)
        {
            if (time.length > 0)
                [time appendString:@" "];
            [time appendFormat:@"%d %@", minutes, OALocalizedString(@"units_min")];
        }
        if (minutes == 0 && hours == 0)
        {
            if (time.length > 0)
                [time appendString:@" "];
            [time appendFormat:@"%d %@", seconds, OALocalizedString(@"units_sec")];
        }
    }
    return time;
}

-(NSString*) getFormattedDistance:(float) meters
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    NSString* mainUnitStr = _unitsKm;
    float mainUnitInMeters;
    if (settings.settingMetricSystem == METRIC_SYSTEM_METERS) {
        mainUnitInMeters = METERS_IN_KILOMETER;
    } else {
        mainUnitStr = _unitsMi;
        mainUnitInMeters = METERS_IN_ONE_MILE;
    }
    if (meters >= 100 * mainUnitInMeters) {
        return [NSString stringWithFormat:@"%d %@",  (int) (meters / mainUnitInMeters + 0.5), mainUnitStr];
        
    } else if (meters > 9.99f * mainUnitInMeters) {
        float num = ((float) meters) / mainUnitInMeters;
        NSString *numStr = [NSString stringWithFormat:@"%.1f", num];
        if ([[numStr substringFromIndex:numStr.length - 1] isEqualToString:@"0"])
            numStr = [numStr substringToIndex:numStr.length - 2];
        return [NSString stringWithFormat:@"%@ %@", numStr, mainUnitStr];
        
    } else if (meters > 0.999f * mainUnitInMeters) {
        float num = ((float) meters) / mainUnitInMeters;
        NSString *numStr = [NSString stringWithFormat:@"%.2f", num];
        if ([[numStr substringFromIndex:numStr.length - 2] isEqualToString:@"00"])
            numStr = [numStr substringToIndex:numStr.length - 3];
        return [NSString stringWithFormat:@"%@ %@", numStr, mainUnitStr];
        
    } else {
        if (settings.settingMetricSystem == METRIC_SYSTEM_METERS) {
            return [NSString stringWithFormat:@"%d %@",   ((int) (meters + 0.5)), _unitsm];
        } else if (settings.settingMetricSystem == METRIC_SYSTEM_FEET) {
            int foots = (int) (meters * FOOTS_IN_ONE_METER + 0.5);
            return [NSString stringWithFormat:@"%d %@", foots, _unitsFt];
        } else if (settings.settingMetricSystem == METRIC_SYSTEM_YARDS) {
            int yards = (int) (meters * YARDS_IN_ONE_METER + 0.5);
            return [NSString stringWithFormat:@"%d %@", yards, _unitsYd];
        }
        return [NSString stringWithFormat:@"%d %@",   ((int) (meters + 0.5)), _unitsm];
    }
}

- (NSString *) getFormattedAlt:(double) alt
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    if (settings.settingMetricSystem == METRIC_SYSTEM_METERS) {
        return [NSString stringWithFormat:@"%d %@", ((int) (alt + 0.5)), _unitsm];
    } else {
        return [NSString stringWithFormat:@"%d %@", ((int) (alt * FOOTS_IN_ONE_METER + 0.5)), _unitsFt];
    }
}

- (NSString *) getFormattedSpeed:(float) metersperseconds
{
    return [self getFormattedSpeed:metersperseconds drive:NO];
}

- (NSString *) getFormattedSpeed:(float) metersperseconds drive:(BOOL)drive
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    float kmh = metersperseconds * 3.6f;
    if (settings.settingMetricSystem == METRIC_SYSTEM_METERS) {
        if (kmh >= 10 || drive) {
            // case of car
            return [NSString stringWithFormat:@"%d %@", ((int) round(kmh)), _unitsKmh];
        }
        int kmh10 = (int) (kmh * 10.0f);
        // calculate 2.0 km/h instead of 2 km/h in order to not stress UI text lengh
        return [NSString stringWithFormat:@"%g %@", (kmh10 / 10.0f), _unitsKmh];
    } else {
        float mph = kmh * METERS_IN_KILOMETER / METERS_IN_ONE_MILE;
        if (mph >= 10) {
            return [NSString stringWithFormat:@"%d %@", ((int) round(mph)), _unitsMph];
        } else {
            int mph10 = (int) (mph * 10.0f);
            return [NSString stringWithFormat:@"%g %@", (mph10 / 10.0f), _unitsMph];
        }
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
    [[OADiscountHelper instance] checkAndDisplay];
}

- (void)onApplicationDidBecomeActive
{
    [[OASavingTrackHelper sharedInstance] saveIfNeeded];
}

@end
