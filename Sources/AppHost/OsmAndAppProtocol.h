//
//  OsmAndAppProtocol.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OACommonTypes.h"
#import "OAObservable.h"
#import "OAAppData.h"
#import "OAMapViewState.h"
#import "OALocationServices.h"
#import "OAWorldRegion.h"
#import "OADownloadsManager.h"
#import "OAAppearanceProtocol.h"
#import "OAApplicationMode.h"

@protocol OsmAndAppProtocol <NSObject>
@required

- (BOOL) initialize;
- (BOOL) initializeCore;
- (void) shutdown;

@property(nonatomic, readonly) NSString *dataPath;
@property(nonatomic, readonly) NSString *documentsPath;
@property(nonatomic, readonly) NSString *cachePath;
@property(nonatomic, readonly) NSString *weatherForecastPath;
@property(nonatomic, readonly) NSString *gpxPath;
@property(nonatomic, readonly) NSString *inboxPath;
@property(nonatomic, readonly) NSString *favoritesPath;
@property(nonatomic, readonly) NSString *travelGuidesPath;
@property(nonatomic, readonly) NSString *gpxTravelPath;
@property(nonatomic, readonly) NSString *hiddenMapsPath;
@property(nonatomic, readonly) NSString *routingMapsCachePath;


@property(readonly) BOOL initialized;

@property(readonly) OAAppData* data;
@property(readonly) OAWorldRegion* worldRegion;

@property(readonly) OALocationServices* locationServices;

@property(readonly) OADownloadsManager* downloadsManager;

@property(readonly) OAObservable* localResourcesChangedObservable;
@property(readonly) OAObservable* resourcesRepositoryUpdatedObservable;
@property(readonly) OAObservable* osmAndLiveUpdatedObservable;

@property(nonatomic) OAMapMode mapMode;
@property(nonatomic) OAMapMode prevMapMode;
@property(readonly) OAObservable* mapModeObservable;

@property(nonatomic) OAMapViewState* initialURLMapState;

@property (nonatomic) BOOL carPlayActive;
@property (nonatomic) BOOL isInBackground;
@property(readonly) OAObservable* backgroundStateObservable;

- (void) loadWorldRegions;

- (void) saveDataToPermamentStorage;

@property(readonly) NSString* favoritesFilePrefix;
@property(readonly) NSString* favoritesGroupNameSeparator;
@property(readonly) NSString* legacyFavoritesFilePrefix;
@property(readonly) NSString* favoritesLegacyStorageFilename;
@property(readonly) NSString* favoritesBackupPath;

@property(readonly) OAObservable* gpxCollectionChangedObservable;
@property(readonly) OAObservable* gpxChangedObservable;

- (void)updateScreenTurnOffSetting;

@property(readonly) unsigned long long freeSpaceAvailableOnDevice;

@property(readonly) BOOL allowScreenTurnOff;

@property(readonly) id<OAAppearanceProtocol> appearance;
@property(readonly) OAObservable* appearanceChangeObservable;

@property(readonly) OAObservable* dayNightModeObservable;
@property(readonly) OAObservable* mapSettingsChangeObservable;
@property(readonly) OAObservable* updateGpxTracksOnMapObservable;
@property(readonly) OAObservable* updateRecTrackOnMapObservable;
@property(readonly) OAObservable* updateRouteTrackOnMapObservable;
@property(readonly) OAObservable* trackStartStopRecObservable;
@property(readonly) OAObservable* addonsSwitchObservable;
@property(readonly) OAObservable* availableAppModesChangedObservable;
@property(readonly) OAObservable* followTheRouteObservable;
@property(readonly) OAObservable* osmEditsChangeObservable;
@property(readonly) OAObservable* mapillaryImageChangedObservable;
@property(readonly) OAObservable* simulateRoutingObservable;

@property(readonly) OAObservable* trackRecordingObservable;

@property(readonly) BOOL isRepositoryUpdating;

- (void) startRepositoryUpdateAsync:(BOOL)async;

- (void) initVoiceCommandPlayer:(OAApplicationMode *)applicationMode warningNoneProvider:(BOOL)warningNoneProvider showDialog:(BOOL)showDialog force:(BOOL)force;
- (void) stopNavigation;
- (void) setupDrivingRegion:(OAWorldRegion *)reg;

- (void) showToastMessage:(NSString *)message;
- (void) showShortToastMessage:(NSString *)message;

- (void) checkAndDownloadOsmAndLiveUpdates;
- (void) checkAndDownloadWeatherForecastsUpdates;

- (void) loadRoutingFiles;

- (NSString *) favoritesStorageFilename:(NSString *)groupName;
- (NSString *) getGroupFileName:(NSString *)groupName;
- (NSString *) getGroupName:(NSString *)fileName;

- (NSString *) getUserIosId;
- (int) getAppExecCount;
- (int) getAppInstalledDays;
- (NSString *) getLanguageCode;

// Tests only
- (BOOL) installTestResource:(NSString *)filePath;
- (BOOL) removeTestResource:(NSString *)filePath;

@end
