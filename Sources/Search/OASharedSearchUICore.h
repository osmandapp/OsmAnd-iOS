//
//  OASharedSearchUICore.h
//  OsmAnd
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OASearchUICore.h"
#import "OASearchPhrase.h"
#import "OASearchSettings.h"
#import "OASearchResult.h"

@class OASSearchUICore, OASSearchPhrase, OASSearchSettings, OASSearchResult, OASSearchUICoreSearchResultCollection;

NS_ASSUME_NONNULL_BEGIN

/**
 The search of the app run by the shared search: the search screens keep calling OASearchUICore,
 OASearchPhrase, OASearchSettings, OASearchResultCollection and OASearchResult, and these subclasses
 hand the calls to the shared objects they hold. Results come back as the app's own, their objects
 made by OASharedSearchObjects.

 The app picks the shared spatial search at start with the useSharedSearch setting.
 App sources (favorites, history, GPX and downloadable regions)
 register their shared implementations through the same facade.
 */
@interface OASharedSearchUICore : OASearchUICore

@property (nonatomic, readonly) OASSearchUICore *shared;

/** The apis of the spatial search, with the rules files rules*.xml of searchRulesDir, or of the classic one as initApi. */
- (void)initApiUseSpatialSearch:(BOOL)useSpatialSearch searchRulesDir:(NSString *)searchRulesDir;

/** Prepares map readers off the calling thread and applies only the latest resource update.
 Searches requested during preparation resume with the prepared resources. */
- (void)updateSearchResourcesIncludingTravel:(BOOL)includeTravel regions:(nullable OAWorldRegion *)regions;

@end

/** Settings of the shared search: the setters make copies, as those of OASearchSettings do. */
@interface OASharedSearchSettings : OASearchSettings

@property (nonatomic, readonly) OASSearchSettings *shared;

- (instancetype)initWithShared:(OASSearchSettings *)shared;

/**
 The shared settings, with readers of the maps installed now: those of settings made before a change
 of the installed maps are closed after it.
 */
- (OASSearchSettings *)sharedWithCurrentReaders;

/** The settings of a case of the search tests, as the shared search reads them. */
+ (OASharedSearchSettings *)settingsOfJSON:(NSString *)json;

@end

/** A phrase of the shared search, with what the search screens ask of a phrase. */
@interface OASharedSearchPhrase : OASearchPhrase

@property (nonatomic, readonly) OASSearchPhrase *shared;

- (instancetype)initWithShared:(OASSearchPhrase *)shared;

@end

@interface OASharedSearchResultCollection : OASearchResultCollection

@property (nonatomic, readonly) OASSearchUICoreSearchResultCollection *shared;

- (instancetype)initWithShared:(OASSearchUICoreSearchResultCollection *)shared;

/** Call off the main thread to prepare a visible snapshot. Returns nil when cancelled. */
- (nullable NSArray<OASearchResult *> *)prepareVisibleResultsWithCancellation:(BOOL (^)(void))cancelled;

@end

@interface OASearchResult (Shared)

/** The app's result for one of the shared search, or nil when its object has no counterpart in the app. */
+ (nullable OASearchResult *)resultOfShared:(OASSearchResult *)result phrase:(OASearchPhrase *)phrase;

/** The shared result of this one: the one it was made of, or one made of its fields when the app made it. */
- (OASSearchResult *)toSharedResult;

@end

NS_ASSUME_NONNULL_END
