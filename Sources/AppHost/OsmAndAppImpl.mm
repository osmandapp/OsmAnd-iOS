//
//  OsmAndAppImpl.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OsmAndAppImpl.h"

#import <UIKit/UIKit.h>

#import "OsmAndApp.h"
#import "OAResourcesInstaller.h"
#import "OADaytimeAppearance.h"
#import "OANighttimeAppearance.h"
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
#import "OATerrainLayer.h"
#import "OAMapCreatorHelper.h"
#import "OAOcbfHelper.h"
#import "OAQuickSearchHelper.h"
#import "OADiscountHelper.h"
#import "OARoutingHelper.h"
#import "OATargetPointsHelper.h"
#import "OAVoiceRouter.h"
#import "OAPlugin.h"
#import "OAPOIFiltersHelper.h"
#import "OATTSCommandPlayerImpl.h"
#import "OAOsmAndLiveHelper.h"
#import "OAAvoidSpecificRoads.h"
#import "OAIndexConstants.h"

#include <algorithm>

#include <QList>

#include <OsmAndCore.h>
#import "OAAppSettings.h"
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/IWebClient.h>
#include "OAWebClient.h"

#include <CommonCollections.h>
#include <binaryRead.h>
#include <routingContext.h>
#include <routingConfiguration.h>
#include <binaryRoutePlanner.h>
#include <routePlannerFrontEnd.h>
#include <OsmAndCore/Utilities.h>
#include <openingHoursParser.h>

#define MILS_IN_DEGREE 17.777778f

#define VERSION_3_10 3.10
#define VERSION_3_14 3.14

#define kAppData @"app_data"

#define _(name)
@implementation OsmAndAppImpl
{
    NSString* _worldMiniBasemapFilename;

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
    NSString *_unitsNm;
    NSString *_unitsKmh;
    NSString *_unitsMph;
    
    BOOL _firstLaunch;
    UNORDERED_map<std::string, std::shared_ptr<RoutingConfigurationBuilder>> _customRoutingConfigs;
    
    BOOL _carPlayActive;
}

@synthesize dataPath = _dataPath;
@synthesize dataDir = _dataDir;
@synthesize documentsPath = _documentsPath;
@synthesize documentsDir = _documentsDir;
@synthesize gpxPath = _gpxPath;
@synthesize cachePath = _cachePath;

@synthesize initialURLMapState = _initialURLMapState;

@synthesize resourcesManager = _resourcesManager;
@synthesize localResourcesChangedObservable = _localResourcesChangedObservable;
@synthesize osmAndLiveUpdatedObservable = _osmAndLiveUpdatedObservable;
@synthesize resourcesRepositoryUpdatedObservable = _resourcesRepositoryUpdatedObservable;
@synthesize defaultRoutingConfig = _defaultRoutingConfig;

@synthesize favoritesCollection = _favoritesCollection;

@synthesize dayNightModeObservable = _dayNightModeObservable;
@synthesize mapSettingsChangeObservable = _mapSettingsChangeObservable;
@synthesize updateGpxTracksOnMapObservable = _updateGpxTracksOnMapObservable;
@synthesize updateRecTrackOnMapObservable = _updateRecTrackOnMapObservable;
@synthesize updateRouteTrackOnMapObservable = _updateRouteTrackOnMapObservable;
@synthesize trackStartStopRecObservable = _trackStartStopRecObservable;
@synthesize addonsSwitchObservable = _addonsSwitchObservable;
@synthesize availableAppModesChangedObservable = _availableAppModesChangedObservable;
@synthesize followTheRouteObservable = _followTheRouteObservable;
@synthesize osmEditsChangeObservable = _osmEditsChangeObservable;
@synthesize mapillaryImageChangedObservable = _mapillaryImageChangedObservable;
@synthesize simulateRoutingObservable = _simulateRoutingObservable;

@synthesize widgetSettingResetObservable = _widgetSettingResetObservable;

@synthesize trackRecordingObservable = _trackRecordingObservable;
@synthesize isRepositoryUpdating = _isRepositoryUpdating;

@synthesize carPlayActive = _carPlayActive;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
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
        _unitsNm = OALocalizedString(@"units_nm");
        _unitsKmh = OALocalizedString(@"units_kmh");
        _unitsMph = OALocalizedString(@"units_mph");
        
        [self initOpeningHoursParser];

        // First of all, initialize user defaults
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _firstLaunch = [defaults objectForKey:kAppData] == nil;
        [defaults registerDefaults:[self inflateInitialUserDefaults]];
        NSDictionary *defHideAllGPX = [NSDictionary dictionaryWithObject:@"NO" forKey:@"hide_all_gpx"];
        [defaults registerDefaults:defHideAllGPX];
        NSDictionary *defResetSettings = [NSDictionary dictionaryWithObject:@"NO" forKey:@"reset_settings"];
        [defaults registerDefaults:defResetSettings];
        NSDictionary *defResetRouting = [NSDictionary dictionaryWithObject:@"NO" forKey:@"reset_routing"];
        [defaults registerDefaults:defResetRouting];
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

- (void) initOpeningHoursParser
{
    OpeningHoursParser::setAdditionalString("off", [OALocalizedString(@"day_off_label") UTF8String]);
    OpeningHoursParser::setAdditionalString("is_open", [OALocalizedString(@"time_open") UTF8String]);
    OpeningHoursParser::setAdditionalString("is_open_24_7", [OALocalizedString(@"shared_string_is_open_24_7") UTF8String]);
    OpeningHoursParser::setAdditionalString("will_open_at", [OALocalizedString(@"will_open_at") UTF8String]);
    OpeningHoursParser::setAdditionalString("open_from", [OALocalizedString(@"open_from") UTF8String]);
    OpeningHoursParser::setAdditionalString("will_close_at", [OALocalizedString(@"will_close_at") UTF8String]);
    OpeningHoursParser::setAdditionalString("open_till", [OALocalizedString(@"open_till") UTF8String]);
    OpeningHoursParser::setAdditionalString("will_open_tomorrow_at", [OALocalizedString(@"will_open_tomorrow_at") UTF8String]);
    OpeningHoursParser::setAdditionalString("will_open_on", [OALocalizedString(@"will_open_on") UTF8String]);
}

- (BOOL) initialize
{
    NSError* versionError = nil;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL hideAllGPX = [defaults boolForKey:@"hide_all_gpx"];
    BOOL resetSettings = [defaults boolForKey:@"reset_settings"];
    BOOL resetRouting = [defaults boolForKey:@"reset_routing"];
    OAAppSettings *settings = [OAAppSettings sharedManager];
    if (hideAllGPX)
    {
        [settings.mapSettingVisibleGpx set:@[]];
        [defaults setBool:NO forKey:@"hide_all_gpx"];
        [defaults synchronize];
    }
    if (resetRouting)
    {
        [settings clearImpassableRoads];
        [defaults setBool:NO forKey:@"reset_routing"];
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
        NSDictionary *defResetRouting = [NSDictionary dictionaryWithObject:@"NO" forKey:@"reset_routing"];
        [defaults registerDefaults:defResetRouting];

        _data = [OAAppData defaults];
        [defaults setObject:[NSKeyedArchiver archivedDataWithRootObject:_data]
                         forKey:kAppData];
        [defaults setBool:NO forKey:@"hide_all_gpx"];
        [defaults setBool:NO forKey:@"reset_settings"];
        [defaults setBool:NO forKey:@"reset_routing"];
        [defaults synchronize];
    }

    OALog(@"Data path: %@", _dataPath);
    OALog(@"Documents path: %@", _documentsPath);
    OALog(@"GPX path: %@", _gpxPath);
    OALog(@"Cache path: %@", _cachePath);

    [OAUtilities clearTmpDirectory];
    
    // Unpack app data
    _data = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:kAppData]];

    settings.applicationMode = settings.defaultApplicationMode.get;
    [_data setLastMapSourceVariant:settings.applicationMode.variantKey];
    
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
    _osmAndLiveUpdatedObservable = [[OAObservable alloc] init];
    _resourcesManager.reset(new OsmAnd::ResourcesManager(_dataDir.absoluteFilePath(QLatin1String("Resources")),
                                                         _documentsDir.absolutePath(),
                                                         QList<QString>() << QString::fromNSString([[NSBundle mainBundle] resourcePath]),
                                                         _worldMiniBasemapFilename != nil
                                                         ? QString::fromNSString(_worldMiniBasemapFilename)
                                                         : QString::null,
                                                         QString::fromNSString(NSTemporaryDirectory()),
                                                         QString::fromNSString(_cachePath),
                                                         QString::fromNSString([[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"]),
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
                                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                                     [[OAAvoidSpecificRoads instance] initRouteObjects:YES];
                                                                 });
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
    
    for (NSString *filePath in [OAMapCreatorHelper sharedInstance].files.allValues)
    {
        [self applyExcludedFromBackup:filePath];
    }
    
    float currentVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"] floatValue];
    float prevVersion = [[NSUserDefaults standardUserDefaults] objectForKey:@"appVersion"] ? [[NSUserDefaults standardUserDefaults] floatForKey:@"appVersion"] : 0.;
    if (_firstLaunch)
    {
        [[NSUserDefaults standardUserDefaults] setFloat:currentVersion forKey:@"appVersion"];
        _resourcesManager->installOsmAndOnlineTileSource();
        [OAAppSettings sharedManager].shouldShowWhatsNewScreen = YES;
    }
    else if (currentVersion != prevVersion)
    {
        if (prevVersion < VERSION_3_10)
        {
            // Reset map sources
            _data.overlayMapSource = nil;
            _data.underlayMapSource = nil;
            _data.lastMapSource = [OAAppData defaultMapSource];
            _resourcesManager->installOsmAndOnlineTileSource();
            
            [self clearUnsupportedTilesCache];
        }
        if (prevVersion < VERSION_3_14)
        {
            [OAAppSettings.sharedManager.availableApplicationModes set:@"car,bicycle,pedestrian,public_transport,"];
        }
        [[NSUserDefaults standardUserDefaults] setFloat:currentVersion forKey:@"appVersion"];
        [OAAppSettings sharedManager].shouldShowWhatsNewScreen = YES;
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
    
    // Sync favorites filename with android version
    NSString *oldfFavoritesFilename = _documentsDir.filePath(QLatin1String("Favorites.gpx")).toNSString();
    _favoritesFilename = _documentsDir.filePath(QLatin1String("favourites.gpx")).toNSString();
    if ([[NSFileManager defaultManager] fileExistsAtPath:oldfFavoritesFilename] && ![[NSFileManager defaultManager] fileExistsAtPath:_favoritesFilename])
    {
        NSError *error = nil;
        [[NSFileManager defaultManager] moveItemAtPath:oldfFavoritesFilename toPath:_favoritesFilename error:&error];
        if (error)
            NSLog(@"Error moving file: %@ to %@ - %@", oldfFavoritesFilename, _favoritesFilename, [error localizedDescription]);
    }
    
    // Load favorites
    _favoritesCollectionChangedObservable = [[OAObservable alloc] init];
    _favoriteChangedObservable = [[OAObservable alloc] init];
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

    _defaultRoutingConfig = [self getDefaultRoutingConfig];
    [[OAAvoidSpecificRoads instance] initRouteObjects:NO];
    [self loadRoutingFiles];
    
    _dayNightModeObservable = [[OAObservable alloc] init];
    _mapSettingsChangeObservable = [[OAObservable alloc] init];
    _updateGpxTracksOnMapObservable = [[OAObservable alloc] init];
    _updateRecTrackOnMapObservable = [[OAObservable alloc] init];
    _updateRouteTrackOnMapObservable = [[OAObservable alloc] init];
    _addonsSwitchObservable = [[OAObservable alloc] init];
    _availableAppModesChangedObservable = [[OAObservable alloc] init];
    _followTheRouteObservable = [[OAObservable alloc] init];
    _osmEditsChangeObservable = [[OAObservable alloc] init];
    _mapillaryImageChangedObservable = [[OAObservable alloc] init];
    _simulateRoutingObservable = [[OAObservable alloc] init];
    
    _widgetSettingResetObservable = [[OAObservable alloc] init];

    _trackRecordingObservable = [[OAObservable alloc] init];
    _trackStartStopRecObservable = [[OAObservable alloc] init];

    _mapMode = OAMapModeFree;
    _prevMapMode = OAMapModeFree;
    _mapModeObservable = [[OAObservable alloc] init];

    _downloadsManager = [[OADownloadsManager alloc] init];
    _downloadsManagerActiveTasksCollectionChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                                     withHandler:@selector(onDownloadManagerActiveTasksCollectionChanged)
                                                                                      andObserve:_downloadsManager.activeTasksCollectionChangedObservable];
    
    _resourcesInstaller = [[OAResourcesInstaller alloc] init];

    _locationServices = [[OALocationServices alloc] initWith:self];
    if (_locationServices.available && _locationServices.allowed)
        [_locationServices start];

    [self updateScreenTurnOffSetting];

    _appearance = [[OADaytimeAppearance alloc] init];
    _appearanceChangeObservable = [[OAObservable alloc] init];
    
    [OAMapStyleSettings sharedInstance];

    [[OATargetPointsHelper sharedInstance] removeAllWayPoints:NO clearBackup:NO];
    
    // Init track recorder
    [OASavingTrackHelper sharedInstance];
    
    // Init gpx router
    [OAGPXRouter sharedInstance];
    
    [OAMapCreatorHelper sharedInstance];
    [OATerrainLayer sharedInstanceHillshade];
    [OATerrainLayer sharedInstanceSlope];
    
    [[OAIAPHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success) {}];
    [OAPlugin initPlugins];
    
    [OAApplicationMode onApplicationStart];
    
    [OAPOIHelper sharedInstance];
    [OAQuickSearchHelper instance];
    OAPOIFiltersHelper *helper = [OAPOIFiltersHelper sharedInstance];
    [helper reloadAllPoiFilters];
    [helper loadSelectedPoiFilters];
    
    [[Reachability reachabilityForInternetConnection] startNotifier];
    [self askReview];
    
    return YES;
}

- (void) askReview
{
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    double appInstalledTime = [settings doubleForKey:kAppInstalledDate];
    int appInstalledDays = (int)((currentTime - appInstalledTime) / (24 * 60 * 60));
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL isReviewed = [userDefaults boolForKey:@"isReviewed"];
    if (appInstalledDays < 15 || appInstalledDays > 45)
        return;
    if (!isReviewed)
    {
        [SKStoreReviewController requestReview];
        [userDefaults setBool:true forKey:@"isReviewed"];
    }
}

- (void) clearUnsupportedTilesCache
{
    // Clear old cache
    NSArray<NSString *> *folders = @[@"osmand_hd", @"bing_earth", @"bing_maps", @"bing_hybrid", @"hike_bike", @"hike_hillshade"];
    NSFileManager *manager = [NSFileManager defaultManager];
    for (NSString *folderName in folders)
    {
        NSString *pathToCache = [self.cachePath stringByAppendingPathComponent:folderName];
        BOOL success = [manager removeItemAtPath:pathToCache error:nil];
        NSLog(@"Removing tiles at path: %@ %@", pathToCache, success ? @"successful" : @"failed - No such directory");
    }
}

- (std::vector<std::shared_ptr<RoutingConfigurationBuilder>>) getAllRoutingConfigs
{
    std::vector<std::shared_ptr<RoutingConfigurationBuilder>> values;
    for (auto it = _customRoutingConfigs.begin(); it != _customRoutingConfigs.end(); ++it)
        values.push_back(it->second);
    values.push_back(self.defaultRoutingConfig);
    return values;
}

- (std::shared_ptr<RoutingConfigurationBuilder>) getDefaultRoutingConfig
{
    float tm = [[NSDate date] timeIntervalSince1970];
    @try
    {
        return parseRoutingConfigurationFromXml([[[NSBundle mainBundle] pathForResource:@"routing" ofType:@"xml"] UTF8String], "");
    }
    @finally
    {
        float te = [[NSDate date] timeIntervalSince1970];
        if (te - tm > 30)
            NSLog(@"Defalt routing config init took %f ms", (te - tm));
    }
}

- (UNORDERED_map<std::string, std::shared_ptr<RoutingConfigurationBuilder>>) getCustomRoutingConfigs
{
    return _customRoutingConfigs;
}

- (std::shared_ptr<RoutingConfigurationBuilder>) getCustomRoutingConfig:(std::string &)key
{
    return _customRoutingConfigs[key];
}

- (std::shared_ptr<RoutingConfigurationBuilder>) getRoutingConfigForMode:(OAApplicationMode *)mode
{
    std::shared_ptr<RoutingConfigurationBuilder> builder = self.defaultRoutingConfig;
    NSString *routingProfileKey = [mode getRoutingProfile];
    if (routingProfileKey.length > 0)
    {
        int index = [routingProfileKey indexOf:@".xml"];
        if (index != -1)
        {
            NSString *configKey = [routingProfileKey substringToIndex:index + @".xml".length];
            if (_customRoutingConfigs.find(configKey.UTF8String) != _customRoutingConfigs.end())
                builder = _customRoutingConfigs[configKey.UTF8String];
        }
    }
    return builder;
}

- (void) loadRoutingFiles
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        const auto defaultAttributes = [self getDefaultAttributes];
        UNORDERED_map<std::string, std::shared_ptr<RoutingConfigurationBuilder>> customConfigs;
        
        NSFileManager *fileManager = NSFileManager.defaultManager;
        BOOL isDir = NO;
        NSString *routingPath = [self.documentsPath stringByAppendingPathComponent:ROUTING_PROFILES_DIR];
        BOOL exists = [fileManager fileExistsAtPath:routingPath isDirectory:&isDir];
        if (exists && isDir)
        {
            NSArray<NSString *> *files = [fileManager contentsOfDirectoryAtPath:routingPath error:nil];
            if (files != nil && files.count > 0)
            {
                for (NSString *f : files)
                {
                    NSString *fullPath = [routingPath stringByAppendingPathComponent:f];
                    [fileManager fileExistsAtPath:fullPath isDirectory:&isDir];
                    if (!isDir && [f.lastPathComponent hasSuffix:ROUTING_FILE_EXT])
                    {
                        NSString *fileName = fullPath.lastPathComponent;
                        auto builder = parseRoutingConfigurationFromXml(fullPath.UTF8String, fullPath.lastPathComponent.UTF8String);
                        if (builder)
                        {
                            for (auto it = defaultAttributes.begin(); it != defaultAttributes.end(); ++it)
                                builder->addAttribute(it->first, it->second);
                            
                            customConfigs[fileName.UTF8String] = builder;
                        }
                    }
                }
            }
        }
        _customRoutingConfigs = customConfigs;
    });
}

- (MAP_STR_STR) getDefaultAttributes
{
    MAP_STR_STR defaultAttributes;
    for (auto it = self.defaultRoutingConfig->attributes.begin(); it != self.defaultRoutingConfig->attributes.end(); ++it)
    {
        if ("routerName" != it->first)
            defaultAttributes[it->first] = it->second;
    }
    return defaultAttributes;
}

- (std::shared_ptr<GeneralRouter>) getRouter:(OAApplicationMode *)am
{
    auto builder = [OsmAndApp.instance getRoutingConfigForMode:am];
    return [self getRouter:builder mode:am];
}

- (std::shared_ptr<GeneralRouter>) getRouter:(std::shared_ptr<RoutingConfigurationBuilder> &)builder mode:(OAApplicationMode *)am
{
    auto router = builder->getRouter([am.getRoutingProfile UTF8String]);
    if (!router && am.parent)
        router = builder->getRouter([am.parent.stringKey UTF8String]);
    return router;
}

- (void) initVoiceCommandPlayer:(OAApplicationMode *)applicationMode warningNoneProvider:(BOOL)warningNoneProvider showDialog:(BOOL)showDialog force:(BOOL)force
{
    NSString *voiceProvider = [[OAAppSettings sharedManager].voiceProvider get:applicationMode];
    OAVoiceRouter *vrt = [OARoutingHelper sharedInstance].getVoiceRouter;
    [vrt setPlayer:[[OATTSCommandPlayerImpl alloc] initWithVoiceRouter:vrt voiceProvider:voiceProvider]];
}

- (void) showToastMessage:(NSString *)message
{
    // TODO toast
}

- (void) showShortToastMessage:(NSString *)message
{
    // TODO toast
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


- (void)checkAndDownloadOsmAndLiveUpdates
{
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable)
        return;
    QList<std::shared_ptr<const OsmAnd::IncrementalChangesManager::IncrementalUpdate> > updates;
    for (const auto& localResource : _resourcesManager->getLocalResources())
    {
        [OAOsmAndLiveHelper downloadUpdatesForRegion:QString(localResource->id).remove(QStringLiteral(".map.obf")) resourcesManager:_resourcesManager];
    }
}

- (BOOL) installTestResource:(NSString *)filePath
{
    if(_resourcesManager == nullptr)
    {
        _resourcesManager.reset(new OsmAnd::ResourcesManager(_dataDir.absoluteFilePath(QLatin1String("Resources")),
                                                             _documentsDir.absolutePath(),
                                                             QList<QString>() << QString::fromNSString([[NSBundle mainBundle] resourcePath]),
                                                             _worldMiniBasemapFilename != nil
                                                             ? QString::fromNSString(_worldMiniBasemapFilename)
                                                             : QString::null,
                                                             QString::fromNSString(NSTemporaryDirectory()),
                                                             QString::fromNSString(_cachePath),
                                                             QString::fromNSString([[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"]),
                                                             QString::fromNSString(@"http://download.osmand.net"),
                                                             _webClient));
    }
    
    const auto filePathQ = QString::fromNSString(filePath);
    return _resourcesManager->addLocalResource(filePathQ);
}

- (BOOL) removeTestResource:(NSString *)filePath
{
    NSString *fileId = filePath.lastPathComponent.lowerCase;
    return _resourcesManager->uninstallResource(QString::fromNSString(fileId));
}

- (void) loadWorldRegions
{
    NSString *ocbfPathLib = [NSHomeDirectory() stringByAppendingString:@"/Library/Resources/regions.ocbf"];
    _worldRegion = [OAWorldRegion loadFrom:ocbfPathLib];
}

- (void) applyExcludedFromBackup:(NSString *)localPath
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

- (void) shutdown
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

- (OAMapMode) mapMode
{
    return _mapMode;
}

- (void) setMapMode:(OAMapMode)mapMode
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

- (NSString*) getFormattedTimeHM:(NSTimeInterval)timeInterval
{
    int hours, minutes, seconds;
    [OAUtilities getHMS:timeInterval hours:&hours minutes:&minutes seconds:&seconds];
    
    NSMutableString *time = [NSMutableString string];
    [time appendFormat:@"%02d:", hours];
    [time appendFormat:@"%02d", minutes];
    
    return time;
}

- (NSString*) getFormattedTimeInterval:(NSTimeInterval)timeInterval shortFormat:(BOOL)shortFormat
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

- (NSString *) getFormattedAlarmInfoDistance:(float)meters
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    BOOL kmAndMeters = [settings.metricSystem get] == KILOMETERS_AND_METERS;
    float mainUnitInMeters = kmAndMeters ? METERS_IN_KILOMETER : METERS_IN_ONE_MILE;
    return [NSString stringWithFormat:@"%.1f %@", meters / mainUnitInMeters, kmAndMeters ? _unitsKm : _unitsMi];
}

- (NSString *) getFormattedAzimuth:(float)bearing
{
    while (bearing < -180.0)
        bearing += 360;
    
    while (bearing > 360.0)
        bearing -= 360;
    
    int azimuth = (int) round(bearing);
    EOAAngularConstant angularConstant = [[OAAppSettings sharedManager].angularUnits get];
    switch (angularConstant)
    {
        case DEGREES360:
        {
            bearing += bearing < 0 ? 360 : 0;
            int b = round(bearing);
            b = b == 360 ? 0 : b;
            return [NSString stringWithFormat:@"%d%@", b, [OAAngularConstant getUnitSymbol:DEGREES360]];
        }
        case MILLIRADS:
        {
            bearing += bearing < 0 ? 360 : 0;
            return [NSString stringWithFormat:@"%d %@", (int) round(bearing * MILS_IN_DEGREE), [OAAngularConstant getUnitSymbol:MILLIRADS]];
        }
        default:
            return [NSString stringWithFormat:@"%d%@", azimuth, [OAAngularConstant getUnitSymbol:DEGREES]];
    }
}

- (NSString *) getFormattedDistance:(float)meters
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    EOAMetricsConstant mc = [settings.metricSystem get];
    
    NSString *mainUnitStr;
    float mainUnitInMeters;
    if (mc == KILOMETERS_AND_METERS)
    {
        mainUnitStr = _unitsKm;
        mainUnitInMeters = METERS_IN_KILOMETER;
    }
    else if (mc == NAUTICAL_MILES)
    {
        mainUnitStr = _unitsNm;
        mainUnitInMeters = METERS_IN_ONE_NAUTICALMILE;
    }
    else
    {
        mainUnitStr = _unitsMi;
        mainUnitInMeters = METERS_IN_ONE_MILE;
    }
    
    if (meters >= 100 * mainUnitInMeters)
    {
        return [NSString stringWithFormat:@"%d %@",  (int) (meters / mainUnitInMeters + 0.5), mainUnitStr];
    }
    else if (meters > 9.99f * mainUnitInMeters)
    {
        float num = meters / mainUnitInMeters;
        NSString *numStr = [NSString stringWithFormat:@"%.1f", num];
        if ([[numStr substringFromIndex:numStr.length - 1] isEqualToString:@"0"])
            numStr = [numStr substringToIndex:numStr.length - 2];
        return [NSString stringWithFormat:@"%@ %@", numStr, mainUnitStr];
    }
    else if (meters > 0.999f * mainUnitInMeters && mc != NAUTICAL_MILES)
    {
        return [self getMilesFormattedStringWithMeters:meters mainUnitInMeters:mainUnitInMeters mainUnitStr:mainUnitStr];
    }
    else if (mc == MILES_AND_FEET && meters > 0.249f * mainUnitInMeters && ![self isCleanValue:meters inUnits:FOOTS_IN_ONE_METER])
    {
        return [self getMilesFormattedStringWithMeters:meters mainUnitInMeters:mainUnitInMeters mainUnitStr:mainUnitStr];
    }
    else if (mc == MILES_AND_METERS && meters > 0.249f * mainUnitInMeters && ![self isCleanValue:meters inUnits:METERS_IN_ONE_METER])
    {
        return [self getMilesFormattedStringWithMeters:meters mainUnitInMeters:mainUnitInMeters mainUnitStr:mainUnitStr];
    }
    else if (mc == MILES_AND_YARDS && meters > 0.249f * mainUnitInMeters && ![self isCleanValue:meters inUnits:YARDS_IN_ONE_METER])
    {
        return [self getMilesFormattedStringWithMeters:meters mainUnitInMeters:mainUnitInMeters mainUnitStr:mainUnitStr];
    }
    else if (mc == NAUTICAL_MILES && meters > 0.99f * mainUnitInMeters && ![self isCleanValue:meters inUnits:METERS_IN_ONE_METER])
    {
        return [self getMilesFormattedStringWithMeters:meters mainUnitInMeters:mainUnitInMeters mainUnitStr:mainUnitStr];
    }
    else
    {
        if (mc == KILOMETERS_AND_METERS || mc == MILES_AND_METERS || mc == NAUTICAL_MILES)
        {
            return [NSString stringWithFormat:@"%d %@", ((int) (meters + 0.5)), _unitsm];
        }
        else if (mc == MILES_AND_FEET)
        {
            int feet = (int) (meters * FOOTS_IN_ONE_METER + 0.5);
            return [NSString stringWithFormat:@"%d %@", feet, _unitsFt];
        }
        else if (mc == MILES_AND_YARDS)
        {
            int yards = (int) (meters * YARDS_IN_ONE_METER + 0.5);
            return [NSString stringWithFormat:@"%d %@", yards, _unitsYd];
        }
        return [NSString stringWithFormat:@"%d %@", ((int) (meters + 0.5)), _unitsm];
    }
}

- (NSString *) getMilesFormattedStringWithMeters:(float)meters mainUnitInMeters:(float)mainUnitInMeters mainUnitStr:(NSString *)mainUnitStr
{
    float num = meters / mainUnitInMeters;
    NSString *numStr = [NSString stringWithFormat:@"%.2f", num];
    if ([[numStr substringFromIndex:numStr.length - 2] isEqualToString:@"00"])
        numStr = [numStr substringToIndex:numStr.length - 3];
    return [NSString stringWithFormat:@"%@ %@", numStr, mainUnitStr];
}

- (BOOL) isCleanValue:(float)meters inUnits:(float)unitsInOneMeter
{
    if ( int(meters) % int(METERS_IN_ONE_NAUTICALMILE) == 0)
        return NO;

    return (int((meters * unitsInOneMeter) * 100) % 100) < 1;
}

- (NSString *) getFormattedAlt:(double) alt
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    if ([settings.metricSystem get] == KILOMETERS_AND_METERS) {
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
    if ([settings.metricSystem get] == KILOMETERS_AND_METERS) {
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

- (double) calculateRoundedDist:(double)baseMetersDist
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    EOAMetricsConstant mc = [settings.metricSystem get];
    double mainUnitInMeter = 1;
    double metersInSecondUnit = METERS_IN_KILOMETER;
    if (mc == MILES_AND_FEET)
    {
        mainUnitInMeter = FOOTS_IN_ONE_METER;
        metersInSecondUnit = METERS_IN_ONE_MILE;
    }
    else if (mc == MILES_AND_METERS)
    {
        mainUnitInMeter = 1;
        metersInSecondUnit = METERS_IN_ONE_MILE;
    }
    else if (mc == NAUTICAL_MILES)
    {
        mainUnitInMeter = 1;
        metersInSecondUnit = METERS_IN_ONE_NAUTICALMILE;
    }
    else if (mc == MILES_AND_YARDS)
    {
        mainUnitInMeter = YARDS_IN_ONE_METER;
        metersInSecondUnit = METERS_IN_ONE_MILE;
    }
    
    // 1, 2, 5, 10, 20, 50, 100, 200, 500, 1000 ...
    int generator = 1;
    int pointer = 1;
    double point = mainUnitInMeter;
    double roundDist = 1;
    while (baseMetersDist * point > generator)
    {
        roundDist = (generator / point);
        if (pointer++ % 3 == 2)
            generator = generator * 5 / 2;
        else
            generator *= 2;
        
        if (point == mainUnitInMeter && metersInSecondUnit * mainUnitInMeter * 0.9f <= generator)
        {
            point = 1 / metersInSecondUnit;
            generator = 1;
            pointer = 1;
        }
    }
    //Miles exceptions: 2000ft->0.5mi, 1000ft->0.25mi, 1000yd->0.5mi, 500yd->0.25mi, 1000m ->0.5mi, 500m -> 0.25mi
    if (mc == MILES_AND_METERS && roundDist == 1000)
        roundDist = 0.5f * METERS_IN_ONE_MILE;
    else if (mc == MILES_AND_METERS && roundDist == 500)
        roundDist = 0.25f * METERS_IN_ONE_MILE;
    else if (mc == MILES_AND_FEET && roundDist == 2000 / (double) FOOTS_IN_ONE_METER)
        roundDist = 0.5f * METERS_IN_ONE_MILE;
    else if (mc == MILES_AND_FEET && roundDist == 1000 / (double) FOOTS_IN_ONE_METER)
        roundDist = 0.25f * METERS_IN_ONE_MILE;
    else if (mc == MILES_AND_YARDS && roundDist == 1000 / (double) YARDS_IN_ONE_METER)
        roundDist = 0.5f * METERS_IN_ONE_MILE;
    else if (mc == MILES_AND_YARDS && roundDist == 500 / (double) YARDS_IN_ONE_METER)
        roundDist = 0.25f * METERS_IN_ONE_MILE;

    return roundDist;
}

- (unsigned long long) freeSpaceAvailableOnDevice
{
    NSError* error = nil;
    unsigned long long deviceMemoryAvailable = 0;
    
    NSURL *home = [NSURL fileURLWithPath:NSHomeDirectory()];
    NSDictionary *results = [home resourceValuesForKeys:@[NSURLVolumeAvailableCapacityForImportantUsageKey] error:&error];
    if (results)
        deviceMemoryAvailable = [results[NSURLVolumeAvailableCapacityForImportantUsageKey] unsignedLongLongValue];
    
    if (deviceMemoryAvailable == 0)
    {
        NSDictionary* dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:_dataPath error:&error];
        if (dictionary)
        {
            NSNumber *fileSystemFreeSizeInBytes = [dictionary objectForKey: NSFileSystemFreeSize];
            deviceMemoryAvailable = [fileSystemFreeSizeInBytes unsignedLongLongValue];
        }
    }
    return deviceMemoryAvailable;
}

- (BOOL) allowScreenTurnOff
{
    BOOL allowScreenTurnOff = NO;

    allowScreenTurnOff = allowScreenTurnOff && _downloadsManager.allowScreenTurnOff;

    return allowScreenTurnOff;
}

- (void) updateScreenTurnOffSetting
{
    BOOL allowScreenTurnOff = self.allowScreenTurnOff;

    if (allowScreenTurnOff)
        OALog(@"Going to enable screen turn-off");
    else
        OALog(@"Going to disable screen turn-off");

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication sharedApplication].idleTimerDisabled = !allowScreenTurnOff;
    });
}

@synthesize appearance = _appearance;
@synthesize appearanceChangeObservable = _appearanceChangeObservable;

- (void) onDownloadManagerActiveTasksCollectionChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // In background, don't change screen turn-off setting
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground)
            return;
        
        [self updateScreenTurnOffSetting];
    });
}

- (void) onApplicationWillResignActive
{
}

- (void) onApplicationDidEnterBackground
{
    [self saveDataToPermamentStorage];

    // In background allow to turn off screen
    OALog(@"Going to enable screen turn-off");
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (void) onApplicationWillEnterForeground
{
    [self updateScreenTurnOffSetting];
    [[OADiscountHelper instance] checkAndDisplay];
}

- (void) onApplicationDidBecomeActive
{
    [[OASavingTrackHelper sharedInstance] saveIfNeeded];
}

- (void) stopNavigation
{
    /* TODO
    if (locationProvider.getLocationSimulation().isRouteAnimating()) {
        locationProvider.getLocationSimulation().stop();
    }
     */
    
    OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
    OATargetPointsHelper *targetPointsHelper = [OATargetPointsHelper sharedInstance];
    
    [[routingHelper getVoiceRouter] interruptRouteCommands];
    [routingHelper clearCurrentRoute:nil newIntermediatePoints:@[]];
    [routingHelper setRoutePlanningMode:false];
    OAAppSettings* settings = [OAAppSettings sharedManager];
    settings.lastRoutingApplicationMode = settings.applicationMode;
    [targetPointsHelper removeAllWayPoints:NO clearBackup:NO];
    dispatch_async(dispatch_get_main_queue(), ^{
        settings.applicationMode = _carPlayActive ? [OAApplicationMode CARPLAY] : [settings.defaultApplicationMode get];
    });
}

- (void) setupDrivingRegion:(OAWorldRegion *)reg
{
    OADrivingRegion *drg = nil;
    BOOL americanSigns = [@"american" isEqualToString:reg.regionRoadSigns];
    BOOL leftHand = [@"yes" isEqualToString:reg.regionLeftHandDriving];
    //EOAMetricsConstant::KILOMETERS_AND_METERS
    EOAMetricsConstant mc1 = [@"miles" isEqualToString:reg.regionMetric] ? EOAMetricsConstant::MILES_AND_FEET : EOAMetricsConstant::KILOMETERS_AND_METERS;
    EOAMetricsConstant mc2 = [@"miles" isEqualToString:reg.regionMetric] ? EOAMetricsConstant::MILES_AND_METERS : EOAMetricsConstant::KILOMETERS_AND_METERS;
    
    for (OADrivingRegion *r in [OADrivingRegion values])
    {
        if ([OADrivingRegion isAmericanSigns:r.region] == americanSigns && [OADrivingRegion isLeftHandDriving:r.region] == leftHand && ([OADrivingRegion getDefMetrics:r.region] == mc1 || [OADrivingRegion getDefMetrics:r.region] == mc2))
        {
            drg = r;
            break;
        }
    }
    
    if (drg)
        [[OAAppSettings sharedManager].drivingRegion set:drg.region];
}

@end
