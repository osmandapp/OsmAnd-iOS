//
//  OsmAndAppProtocol.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 2/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <TTTLocationFormatter.h>

#import "OACommonTypes.h"
#import "OAObservable.h"
#import "OAAppData.h"
#import "OALocationServices.h"
#import "OAWorldRegion.h"
#import "OADownloadsManager.h"
#import "OAAppearanceProtocol.h"
#if defined(OSMAND_IOS_DEV)
#   import "OADebugSettings.h"
#endif // defined(OSMAND_IOS_DEV)

@protocol OsmAndAppProtocol <NSObject>
@required

- (BOOL)initialize;
- (void)shutdown;

@property(nonatomic, readonly) NSString* dataPath;
@property(nonatomic, readonly) NSString* documentsPath;
@property(nonatomic, readonly) NSString* cachePath;
@property(nonatomic, readonly) NSString* gpxPath;

@property(readonly) OAAppData* data;
@property(readonly) OAWorldRegion* worldRegion;

@property(readonly) OALocationServices* locationServices;

@property(readonly) OADownloadsManager* downloadsManager;

@property(readonly) id<UIAlertViewDelegate> commonResponder;

@property(readonly) OAObservable* localResourcesChangedObservable;
@property(readonly) OAObservable* resourcesRepositoryUpdatedObservable;

@property(nonatomic) OAAppMode appMode;
@property(readonly) OAObservable* appModeObservable;

@property(nonatomic) OAMapMode mapMode;
@property(readonly) OAObservable* mapModeObservable;

- (void)saveDataToPermamentStorage;

- (double)calculateRoundedDist:(double) baseMetersDist;
- (NSString*) getFormattedDistance:(float) meters;

@property(readonly) OAObservable* favoritesCollectionChangedObservable;
@property(readonly) OAObservable* favoriteChangedObservable;
@property(readonly) NSString* favoritesStorageFilename;

@property(readonly) OAObservable* gpxCollectionChangedObservable;
@property(readonly) OAObservable* gpxChangedObservable;
@property(readonly) NSString* gpxStorageFilename;

- (void)saveFavoritesToPermamentStorage;
- (void)saveGPXToPermamentStorage;

- (TTTLocationFormatter*)locationFormatterDigits;
- (TTTLocationFormatter*)locationFormatter;

@property(readonly) unsigned long long freeSpaceAvailableOnDevice;

@property(readonly) BOOL allowScreenTurnOff;

@property(readonly) id<OAAppearanceProtocol> appearance;
@property(readonly) OAObservable* appearanceChangeObservable;

@property(readonly) OAObservable* dayNightModeObservable;
@property(readonly) OAObservable* mapSettingsChangeObservable;

#if defined(OSMAND_IOS_DEV)
@property(readonly) OADebugSettings* debugSettings;
#endif // defined(OSMAND_IOS_DEV)

@end
