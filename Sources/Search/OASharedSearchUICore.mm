//
//  OASharedSearchUICore.mm
//  OsmAnd
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OASharedSearchUICore.h"
#import "OASharedSearchObjects.h"
#import "OASearchCoreFactory.h"
#import "OASearchWord.h"
#import "OANameStringMatcher.h"
#import "OAResultMatcher.h"
#import "OAAtomicInteger.h"
#import "OAPOIHelper.h"
#import "OAWorldRegion.h"
#import "QuadRect.h"
#import "OsmAndSharedWrapper.h"
#import "OsmAnd_Maps-Swift.h"

/** A name matcher of the shared search where the search screens take one of the app. */
@interface OASharedNameStringMatcher : OANameStringMatcher

- (instancetype)initWithShared:(OASNameStringMatcher *)shared;

@end

@implementation OASharedNameStringMatcher
{
    OASNameStringMatcher *_shared;
}

- (instancetype)initWithShared:(OASNameStringMatcher *)shared
{
    self = [super init];
    if (self)
        _shared = shared;
    return self;
}

- (BOOL)matches:(NSString *)name
{
    return name && [_shared matchesName:name];
}

- (BOOL)matchesMap:(NSArray<NSString *> *)map
{
    return [_shared matchesMap:map];
}

@end

@implementation OASharedSearchSettings
{
    // the ids the readers were opened for, kept to open them again after a change of the installed maps
    NSArray<NSString *> *_resourceIds;
    BOOL _addressSearch;
    OAWorldRegion *_regions;
}

- (instancetype)initWithShared:(OASSearchSettings *)shared
{
    self = [super init];
    if (self)
        _shared = shared;
    return self;
}

- (instancetype)initWithSettings:(OASearchSettings *)s
{
    OASharedSearchSettings *settings = (OASharedSearchSettings *) s;
    return [settings copyWithShared:[[OASSearchSettings alloc] initWithS:settings.shared]];
}

- (OASharedSearchSettings *)copyWithShared:(OASSearchSettings *)shared
{
    OASharedSearchSettings *s = [[OASharedSearchSettings alloc] initWithShared:shared];
    s->_resourceIds = _resourceIds;
    s->_addressSearch = _addressSearch;
    s->_regions = _regions;
    return s;
}

+ (OASharedSearchSettings *)settingsOfJSON:(NSString *)json
{
    id object = [OASKotlinx_serialization_jsonJsonDefault.shared parseToJsonElementString:json];
    return [[OASharedSearchSettings alloc] initWithShared:[OASSearchSettings.companion parseJSONJson:object]];
}

- (OASSearchSettings *)sharedWithCurrentReaders
{
    // settings made of the shared ones, as those of a phrase, may hold readers of any time before
    if (![OASharedSearchReaders.shared areCurrent:[_shared getOfflineIndexes]])
        [self setOfflineIndexes:[self getOfflineIndexes]];
    return _shared;
}

- (NSArray<NSString *> *)getOfflineIndexes
{
    return _resourceIds ?: [OASharedSearchReaders.shared resourceIdsOf:[_shared getOfflineIndexes]];
}

- (void)setOfflineIndexes:(NSArray<NSString *> *)resourceIds
{
    _resourceIds = [resourceIds copy] ?: @[];
    [_shared setOfflineIndexesOfflineIndexes:[OASharedSearchReaders.shared readersForResourceIds:_resourceIds]];
}

- (int)getRadiusLevel
{
    return [_shared getRadiusLevel];
}

- (OASearchSettings *)setRadiusLevel:(int)radiusLevel
{
    return [self copyWithShared:[_shared setRadiusLevelRadiusLevel:radiusLevel]];
}

- (NSString *)getLang
{
    return [_shared getLang];
}

- (OASearchSettings *)setLang:(NSString *)lang transliterateIfMissing:(BOOL)transliterateIfMissing
{
    return [self copyWithShared:[_shared setLangLang:lang transliterateIfMissing:transliterateIfMissing]];
}

- (BOOL)isTransliterate
{
    return [_shared isTransliterate];
}

- (NSString *)getRegionLang
{
    return [_shared getRegionLang];
}

- (int)getTotalLimit
{
    return [_shared getTotalLimit];
}

- (OASearchSettings *)setTotalLimit:(int)totalLimit
{
    return [self copyWithShared:[_shared setTotalLimitTotalLimit:totalLimit]];
}

- (CLLocation *)getOriginalLocation
{
    return [OASharedSearchObjects appObjectFor:[_shared getOriginalLocation]];
}

- (OASearchSettings *)setOriginalLocation:(CLLocation *)l
{
    // the shared settings throw on dropping a location they have: the copy keeps it, and
    // the callers that may hand nil in, those of the cities search, set the location they search around next
    if (!l && [_shared getOriginalLocation])
        return [self copyWithShared:[[OASSearchSettings alloc] initWithS:_shared]];
    return [self copyWithShared:[_shared setOriginalLocationL:[OASharedSearchObjects sharedObjectFor:l]]];
}

- (QuadRect *)getSearchBBox31
{
    OASKQuadRect *r = [_shared getSearchBBox31];
    return r ? [[QuadRect alloc] initWithLeft:r.left top:r.top right:r.right bottom:r.bottom] : nil;
}

- (OASearchSettings *)setSearchBBox31:(QuadRect *)searchBBox31
{
    OASKQuadRect *r = searchBBox31 ? [[OASKQuadRect alloc] initWithLeft:searchBBox31.left top:searchBBox31.top right:searchBBox31.right bottom:searchBBox31.bottom] : nil;
    return [self copyWithShared:[_shared setSearchBBox31SearchBBox31:r]];
}

- (NSArray<OAObjectType *> *)getSearchTypes
{
    OASKotlinArray<OASObjectType *> *types = [_shared getSearchTypes];
    if (!types)
        return nil;
    NSMutableArray<OAObjectType *> *result = [NSMutableArray array];
    for (int i = 0; i < types.size; i++)
        [result addObject:[OAObjectType withType:[OASharedSearchObjects appObjectType:[types getIndex:i]]]];
    return result;
}

- (BOOL)isCustomSearch
{
    return [_shared isCustomSearch];
}

- (OASearchSettings *)setSearchTypes:(NSArray<OAObjectType *> *)searchTypes
{
    NSMutableArray<OASObjectType *> *shared = [NSMutableArray array];
    for (OAObjectType *type in searchTypes)
    {
        OASObjectType *sharedType = [OASharedSearchObjects sharedObjectType:type.type];
        if (sharedType)
            [shared addObject:sharedType];
    }
    OASKotlinArray<OASObjectType *> *types = [OASKotlinArray arrayWithSize:(int32_t) shared.count init:^id(OASInt *i) {
        return shared[i.intValue];
    }];
    return [self copyWithShared:[_shared setSearchTypesSearchTypes:types]];
}

- (OASearchSettings *)resetSearchTypes
{
    return [self copyWithShared:[_shared resetSearchTypes]];
}

- (BOOL)isEmptyQueryAllowed
{
    return [_shared isEmptyQueryAllowed];
}

- (OASearchSettings *)setEmptyQueryAllowed:(BOOL)emptyQueryAllowed
{
    return [self copyWithShared:[_shared setEmptyQueryAllowedEmptyQueryAllowed:emptyQueryAllowed]];
}

- (BOOL)isSortByName
{
    return [_shared getSortType] == OASSearchSettingsSortType.ignoreDistance;
}

- (OASearchSettings *)setSortByName:(BOOL)sortByName
{
    return [self copyWithShared:[_shared setSortByNameSortByName:sortByName]];
}

// nothing reads it, in the C++ search either
- (BOOL)isInAddressSearch
{
    return _addressSearch;
}

- (OASearchSettings *)setAddressSearch:(BOOL)addressSearch
{
    OASharedSearchSettings *s = [self copyWithShared:[[OASSearchSettings alloc] initWithS:_shared]];
    s->_addressSearch = addressSearch;
    return s;
}

- (OAWorldRegion *)getRegions
{
    return _regions;
}

// the shared search finds the regions in those it reads at start, the same file the app's are of
- (void)setRegions:(OAWorldRegion *)regions
{
    _regions = regions;
    [_shared setRegionsRegions:[OASOsmandRegions.companion getDefault]];
}

- (OASearchSortType)getSortType
{
    OASSearchSettingsSortType *type = [_shared getSortType];
    if (type == OASSearchSettingsSortType.byRelevance)
        return OASearchSortTypeByRelevance;
    if (type == OASSearchSettingsSortType.onlyByDistance)
        return OASearchSortTypeOnlyByDistance;
    if (type == OASSearchSettingsSortType.ignoreDistance)
        return OASearchSortTypeIgnoreDistance;
    return OASearchSortTypeUnknown;
}

- (OASearchSettings *)setSortType:(OASearchSortType)sortType
{
    OASSearchSettingsSortType *type = nil;
    if (sortType == OASearchSortTypeByRelevance)
        type = OASSearchSettingsSortType.byRelevance;
    else if (sortType == OASearchSortTypeOnlyByDistance)
        type = OASSearchSettingsSortType.onlyByDistance;
    else if (sortType == OASearchSortTypeIgnoreDistance)
        type = OASSearchSettingsSortType.ignoreDistance;
    [_shared setSortTypeSortType:type];
    return self;
}

@end

@implementation OASharedSearchPhrase

- (instancetype)initWithShared:(OASSearchPhrase *)shared
{
    self = [super init];
    if (self)
        _shared = shared;
    return self;
}

- (OASearchSettings *)getSettings
{
    OASSearchSettings *settings = [_shared getSettings];
    return settings ? [[OASharedSearchSettings alloc] initWithShared:settings] : nil;
}

- (NSArray<NSString *> *)getOfflineIndexes
{
    return [OASharedSearchReaders.shared resourceIdsOf:[_shared getOfflineIndexes]];
}

- (NSString *)getText:(BOOL)includeUnknownPart
{
    return [_shared getTextIncludeUnknownPart:includeUnknownPart];
}

- (NSString *)getTextWithoutLastWord
{
    return [_shared getTextWithoutLastWord];
}

- (NSString *)getFullSearchPhrase
{
    return [_shared getFullSearchPhrase];
}

- (NSString *)getUnknownSearchPhrase
{
    return [_shared getUnknownSearchPhrase];
}

- (NSString *)getFirstUnknownSearchWord
{
    return [_shared getFirstUnknownSearchWord];
}

- (NSString *)getUnknownWordToSearch
{
    return [_shared getUnknownWordToSearch];
}

- (OANameStringMatcher *)getMainUnknownNameStringMatcher
{
    return [[OASharedNameStringMatcher alloc] initWithShared:[_shared getMainUnknownNameStringMatcher]];
}

- (OASearchWord *)getLastSelectedWord
{
    OASSearchWord *word = [_shared getLastSelectedWord];
    if (!word)
        return nil;
    OASSearchResult *result = [word getResult];
    return [[OASearchWord alloc] initWithWord:[word getWord] res:result ? [OASearchResult resultOfShared:result phrase:self] : nil];
}

- (int)getRadiusLevel
{
    return [_shared getRadiusLevel];
}

- (BOOL)isNoSelectedType
{
    return [_shared isNoSelectedType];
}

- (BOOL)isEmpty
{
    return [_shared isEmpty];
}

- (BOOL)isLastWord:(EOAObjectType)p
{
    OASObjectType *type = [OASharedSearchObjects sharedObjectType:p];
    if (!type)
        return NO;
    return [_shared isLastWordP:[OASKotlinArray arrayWithSize:1 init:^id(OASInt *i) {
        return type;
    }]];
}

- (void)syncWordsWithResults
{
    [_shared syncWordsWithResults];
}

- (OAPOIBaseType *)getUnselectedPoiType
{
    return [OASharedSearchObjects appObjectFor:[_shared getUnselectedPoiType]];
}

- (NSString *)toString
{
    return [_shared description];
}

@end

// A result of the shared search. What the shared search may change after publishing it, uniting the
// results of one object and making the addresses, is read from it when asked, not copied: the weight,
// the object, the names and the address.
@interface OASharedSearchResult : OASearchResult

@end

@implementation OASharedSearchResult
{
    // the shared object the app's one was made of
    id _sharedObject;
    NSObject *_appObject;
}

// the shared result keeps the weight it computed first, so it is not read before the search sorts
- (double)unknownPhraseMatchWeight
{
    return [self.sharedResult getUnknownPhraseMatchWeight];
}

- (NSObject *)object
{
    id sharedObject = self.sharedResult.object;
    @synchronized (self)
    {
        if (sharedObject != _sharedObject)
        {
            _sharedObject = sharedObject;
            _appObject = [OASharedSearchObjects appObjectFor:sharedObject];
        }
        return _appObject;
    }
}

- (NSMutableArray<NSString *> *)otherNames
{
    id otherNames = self.sharedResult.otherNames;
    if ([otherNames isKindOfClass:NSArray.class])
        return [otherNames mutableCopy];
    if ([otherNames isKindOfClass:NSSet.class])
        return [[otherNames allObjects] mutableCopy];
    return nil;
}

- (NSMutableSet<NSString *> *)otherWordsMatch
{
    id otherWordsMatch = [self.sharedResult getOtherWordsMatch];
    return [otherWordsMatch isKindOfClass:NSSet.class] ? [otherWordsMatch mutableCopy] : nil;
}

- (NSString *)addressName
{
    return self.sharedResult.addressName;
}

@end

@implementation OASearchResult (Shared)

+ (nullable OASearchResult *)resultOfShared:(OASSearchResult *)shared phrase:(OASearchPhrase *)phrase
{
    OASSearchPhrase *sharedPhrase = shared.requiredSearchPhrase;
    if (![phrase isKindOfClass:OASharedSearchPhrase.class] || ((OASharedSearchPhrase *) phrase).shared != sharedPhrase)
        phrase = [[OASharedSearchPhrase alloc] initWithShared:sharedPhrase];

    OASearchResult *result = [[OASharedSearchResult alloc] initWithPhrase:phrase];
    result.sharedResult = shared;
    if (shared.object && !result.object)
        return nil;

    result.objectType = [OASharedSearchObjects appObjectType:shared.objectType];
    result.priority = shared.priority;
    result.priorityDistance = shared.priorityDistance;
    result.localeName = shared.localeName;
    result.alternateName = shared.alternateName;
    result.cityName = shared.cityName;
    result.localeRelatedObjectName = shared.localeRelatedObjectName;
    result.distRelatedObjectName = shared.distRelatedObjectName;
    result.relatedObject = [OASharedSearchObjects appObjectFor:shared.relatedObject];
    result.location = [OASharedSearchObjects appObjectFor:shared.location];
    result.preferredZoom = shared.preferredZoom;
    result.impreciseCoordinates = [shared hasImpreciseCoordinates];

    if (shared.file)
        result.resourceId = [OASharedSearchReaders.shared resourceIdsOf:@[shared.file]].firstObject;
    NSString *resource = [shared getResourceType].name;
    if ([resource isEqualToString:@"DETAILED"])
        result.searchResultResource = EOASearchResultResourceDetailed;
    else if ([resource isEqualToString:@"WIKIPEDIA"])
        result.searchResultResource = EOASearchResultResourceWikipedia;
    else if ([resource isEqualToString:@"BASEMAP"])
        result.searchResultResource = EOASearchResultResourceBasemap;
    else if ([resource isEqualToString:@"TRAVEL"])
        result.searchResultResource = EOASearchResultResourceTravel;

    if (shared.parentSearchResult)
        result.parentSearchResult = [self resultOfShared:shared.parentSearchResult phrase:phrase];
    return result;
}

- (OASSearchResult *)toSharedResult
{
    if (self.sharedResult)
        return self.sharedResult;

    OASSearchPhrase *phrase = [self.requiredSearchPhrase isKindOfClass:OASharedSearchPhrase.class]
        ? ((OASharedSearchPhrase *) self.requiredSearchPhrase).shared : nil;
    OASSearchResult *shared = phrase ? [[OASSearchResult alloc] initWithSp:phrase] : [[OASSearchResult alloc] init];
    shared.object = [OASharedSearchObjects sharedObjectFor:self.object];
    shared.objectType = [OASharedSearchObjects sharedObjectType:self.objectType];
    shared.priority = self.priority;
    shared.priorityDistance = self.priorityDistance;
    shared.localeName = self.localeName;
    shared.alternateName = self.alternateName;
    shared.addressName = self.addressName;
    shared.cityName = self.cityName;
    shared.localeRelatedObjectName = self.localeRelatedObjectName;
    shared.distRelatedObjectName = self.distRelatedObjectName;
    shared.relatedObject = [OASharedSearchObjects sharedObjectFor:self.relatedObject];
    shared.location = [OASharedSearchObjects sharedObjectFor:self.location];
    shared.preferredZoom = self.preferredZoom;
    if (self.otherNames)
        shared.otherNames = [self.otherNames mutableCopy];
    if (self.parentSearchResult)
        shared.parentSearchResult = [self.parentSearchResult toSharedResult];
    self.sharedResult = shared;
    return shared;
}

@end

static NSMapTable<OASSearchResult *, OASearchResult *> *appResultsTable()
{
    return [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory | NSPointerFunctionsObjectPointerPersonality
                                 valueOptions:NSPointerFunctionsStrongMemory];
}

@implementation OASharedSearchResultCollection
{
    // the app's results of the shared ones in the collection, by identity, so that the same one comes back each time
    NSMapTable<OASSearchResult *, OASearchResult *> *_appResults;
    // made again once the shared results change, which they do only through this collection
    NSArray<OASearchResult *> *_currentResults;
}

- (instancetype)initWithShared:(OASSearchUICoreSearchResultCollection *)shared
{
    self = [super initWithPhrase:[[OASharedSearchPhrase alloc] initWithShared:[shared getPhrase]]];
    if (self)
    {
        _shared = shared;
        _appResults = appResultsTable();
    }
    return self;
}

- (instancetype)initWithPhrase:(OASearchPhrase *)phrase
{
    return [self initWithShared:[[OASSearchUICoreSearchResultCollection alloc] initWithPhrase:((OASharedSearchPhrase *) phrase).shared]];
}

- (NSArray<OASearchResult *> *)getCurrentSearchResults
{
    @synchronized (self)
    {
        if (_currentResults)
            return _currentResults;
        NSMutableArray<OASearchResult *> *results = [NSMutableArray array];
        // those the shared collection has dropped, as duplicates, are left out
        NSMapTable<OASSearchResult *, OASearchResult *> *appResults = appResultsTable();
        for (OASSearchResult *shared in [_shared getCurrentSearchResults])
        {
            OASearchResult *result = [_appResults objectForKey:shared] ?: [OASearchResult resultOfShared:shared phrase:self.phrase];
            if (!result)
                continue;
            [appResults setObject:result forKey:shared];
            [results addObject:result];
        }
        _appResults = appResults;
        _currentResults = [results copy];
        return _currentResults;
    }
}

- (NSMutableArray<OASearchResult *> *)getSearchResults
{
    return [[self getCurrentSearchResults] mutableCopy];
}

- (OASearchResultCollection *)addSearchResults:(NSArray<OASearchResult *> *)sr resortAll:(BOOL)resortAll removeDuplicates:(BOOL)removeDuplicates
{
    NSMutableArray<OASSearchResult *> *shared = [NSMutableArray arrayWithCapacity:sr.count];
    @synchronized (self)
    {
        for (OASearchResult *result in sr)
        {
            OASSearchResult *sharedResult = [result toSharedResult];
            // the one handed out already stays the result of the collection
            if (![_appResults objectForKey:sharedResult])
                [_appResults setObject:result forKey:sharedResult];
            [shared addObject:sharedResult];
        }
        [_shared addSearchResultsSr:shared resortAll:resortAll removeDuplicates:removeDuplicates];
        _currentResults = nil;
    }
    return self;
}

- (OASearchResultCollection *)combineWithCollection:(OASearchResultCollection *)collection resort:(BOOL)resort removeDuplicates:(BOOL)removeDuplicates
{
    OASharedSearchResultCollection *combined = [[OASharedSearchResultCollection alloc] initWithShared:
        [[OASSearchUICoreSearchResultCollection alloc] initWithPhrase:_shared.getPhrase]];
    [combined addSearchResults:[self getCurrentSearchResults] resortAll:NO removeDuplicates:NO];
    [combined addSearchResults:[collection getCurrentSearchResults] resortAll:resort removeDuplicates:removeDuplicates];
    return combined;
}

- (void)sortSearchResults
{
    @synchronized (self)
    {
        [_shared sortSearchResults];
        _currentResults = nil;
    }
}

- (void)calculateAddressString
{
    @synchronized (self)
    {
        [_shared calculateAddressString];
    }
}

- (void)filterSearchDuplicateResults
{
    @synchronized (self)
    {
        [_shared filterSearchDuplicateResults];
        _currentResults = nil;
    }
}

- (BOOL)sameSearchResult:(OASearchResult *)r1 r2:(OASearchResult *)r2
{
    return [_shared sameSearchResultR1:[r1 toSharedResult] r2:[r2 toSharedResult]];
}

@end

@implementation OASharedSearchUICore
{
    OASharedSearchSettings *_settings;
    OASharedSearchPhrase *_phrase;
    OASharedSearchResultCollection *_currentSearchResult;
    // a search that started before the last cancel is cancelled: the shared one ends without a word
    OAAtomicInteger *_cancels;
}

- (instancetype)initWithLang:(NSString *)lang transliterate:(BOOL)transliterate
{
    self = [super init];
    if (self)
    {
        _shared = [[OASSearchUICore alloc] initWithPoiTypes:OAPOIHelper.sharedInstance.kPoiTypes locale:lang transliterate:transliterate];
        _settings = [[OASharedSearchSettings alloc] initWithShared:[_shared getSearchSettings]];
        _cancels = [OAAtomicInteger atomicInteger:0];
    }
    return self;
}

- (void)initApi
{
    [_shared doInit];
}

- (void)initApiUseSpatialSearch:(BOOL)useSpatialSearch searchRulesDir:(NSString *)searchRulesDir
{
    [_shared doInitUseSpatialSearch:useSpatialSearch searchRulesDir:searchRulesDir];
}

// the apis of the app search with the C++ search's phrase: theirs for the shared search come next
- (void)registerAPI:(OASearchCoreAPI *)api
{
}

- (OASearchCoreAPI *)getApiByClass:(Class)cl
{
    return nil;
}

// the shared api of the same kind as the C++ api of this class
- (nullable id<OASSearchCoreAPI>)sharedApiFor:(Class)cl
{
    NSDictionary<NSString *, Class> *sharedClasses = @{
        NSStringFromClass(OASearchAmenityTypesAPI.class) : OASSearchCoreFactorySearchAmenityTypesAPI.class,
        NSStringFromClass(OASearchAmenityByTypeAPI.class) : OASSearchCoreFactorySearchAmenityByTypeAPI.class,
        NSStringFromClass(OASearchAmenityByNameAPI.class) : OASSearchCoreFactorySearchAmenityByNameAPI.class,
        NSStringFromClass(OASearchLocationAndUrlAPI.class) : OASSearchCoreFactorySearchLocationAndUrlAPI.class,
        NSStringFromClass(OASearchAddressByNameAPI.class) : OASSearchCoreFactorySearchAddressByNameAPI.class,
        NSStringFromClass(OASearchStreetByCityAPI.class) : OASSearchCoreFactorySearchStreetByCityAPI.class,
        NSStringFromClass(OASearchBuildingAndIntersectionsByStreetAPI.class) : OASSearchCoreFactorySearchBuildingAndIntersectionsByStreetAPI.class,
    };
    Class sharedClass = sharedClasses[NSStringFromClass(cl)];
    if (!sharedClass)
        return nil;
    for (id<OASSearchCoreAPI> api in [_shared getApis])
    {
        if ([(NSObject *) api isKindOfClass:sharedClass])
            return api;
    }
    return nil;
}

// what the shared search publishes, as the app's results; cancelled with the matcher, and by cancelSearch for a search
- (id<OASResultMatcher>)sharedMatcherFor:(nullable OAResultMatcher<OASearchResult *> *)matcher cancelledBySearch:(BOOL)cancelledBySearch
{
    int cancels = [_cancels get];
    OAAtomicInteger *currentCancels = _cancels;
    __block OASSearchPhrase *lastShared = nil;
    __block OASharedSearchPhrase *lastPhrase = nil;
    return [OASharedBlockResultMatcher matcherWithPublish:^BOOL(id object) {
        OASSearchResult *shared = object;
        if (shared.requiredSearchPhrase != lastShared)
        {
            lastShared = shared.requiredSearchPhrase;
            lastPhrase = [[OASharedSearchPhrase alloc] initWithShared:lastShared];
        }
        OASearchResult *result = [OASearchResult resultOfShared:shared phrase:lastPhrase];
        if (!result)
            return NO;
        return !matcher || [matcher publish:result];
    } cancelled:^BOOL{
        return (cancelledBySearch && [currentCancels get] != cancels) || (matcher && [matcher isCancelled]);
    }];
}

- (OASearchResultCollection *)shallowSearch:(Class)cl text:(NSString *)text matcher:(OAResultMatcher<OASearchResult *> *)matcher
{
    return [self shallowSearch:cl text:text matcher:matcher resortAll:YES removeDuplicates:YES];
}

- (OASearchResultCollection *)shallowSearch:(Class)cl text:(NSString *)text matcher:(OAResultMatcher<OASearchResult *> *)matcher resortAll:(BOOL)resortAll removeDuplicates:(BOOL)removeDuplicates
{
    return [self shallowSearch:cl text:text matcher:matcher resortAll:resortAll removeDuplicates:removeDuplicates searchSettings:[self getSearchSettings]];
}

- (OASearchResultCollection *)shallowSearch:(Class)cl text:(NSString *)text matcher:(OAResultMatcher<OASearchResult *> *)matcher resortAll:(BOOL)resortAll removeDuplicates:(BOOL)removeDuplicates searchSettings:(OASearchSettings *)searchSettings
{
    id<OASSearchCoreAPI> api = [self sharedApiFor:cl];
    if (!api)
        return nil;

    OASharedSearchSettings *settings = [searchSettings isKindOfClass:OASharedSearchSettings.class]
        ? (OASharedSearchSettings *) searchSettings : (OASharedSearchSettings *) [self getSearchSettings];
    // it runs on the caller's thread, which the core does not wait for: its readers are held until it ends
    OASSearchSettings *shared = [[OASSearchSettings alloc] initWithS:settings.shared];
    [shared setOfflineIndexesOfflineIndexes:[OASharedSearchReaders.shared beginShallowSearchWithResourceIds:[settings getOfflineIndexes]]];
    OASSearchUICoreSearchResultCollection *collection = [_shared shallowSearchApi:api text:text
                                                                         matcher:[self sharedMatcherFor:matcher cancelledBySearch:NO]
                                                                       resortAll:resortAll removeDuplicates:removeDuplicates searchSettings:shared];
    [OASharedSearchReaders.shared endShallowSearch];
    return [[OASharedSearchResultCollection alloc] initWithShared:collection];
}

- (void)clearCustomSearchPoiFilters
{
    [_shared clearCustomSearchPoiFilters];
}

- (void)addCustomSearchPoiFilter:(OACustomSearchPoiFilter *)poiFilter priority:(int)priority
{
    [_shared addCustomSearchPoiFilterPoiFilter:[OASharedSearchObjects sharedPoiFilterFor:poiFilter] priority:priority];
}

- (void)setActivePoiFiltersByOrder:(NSArray<NSString *> *)filterOrders
{
    [_shared setActivePoiFiltersByOrderFilterOrders:filterOrders];
}

- (OASearchResultCollection *)getCurrentSearchResult
{
    OASSearchUICoreSearchResultCollection *shared = [_shared getCurrentSearchResult];
    @synchronized (self)
    {
        if (_currentSearchResult.shared != shared)
            _currentSearchResult = [[OASharedSearchResultCollection alloc] initWithShared:shared];
        return _currentSearchResult;
    }
}

- (OASearchPhrase *)getPhrase
{
    return [self wrapPhrase:[_shared getPhrase]];
}

- (OASearchPhrase *)wrapPhrase:(OASSearchPhrase *)shared
{
    @synchronized (self)
    {
        if (_phrase.shared != shared)
            _phrase = [[OASharedSearchPhrase alloc] initWithShared:shared];
        return _phrase;
    }
}

- (OASearchSettings *)getSearchSettings
{
    OASSearchSettings *shared = [_shared getSearchSettings];
    @synchronized (self)
    {
        if (_settings.shared != shared)
            _settings = [[OASharedSearchSettings alloc] initWithShared:shared];
        return _settings;
    }
}

- (void)updateSettings:(OASearchSettings *)settings
{
    if (![settings isKindOfClass:OASharedSearchSettings.class])
        return;
    OASharedSearchSettings *sharedSettings = (OASharedSearchSettings *) settings;
    @synchronized (self)
    {
        _settings = sharedSettings;
    }
    [_shared updateSettingsSettings:[sharedSettings sharedWithCurrentReaders]];
}

- (BOOL)selectSearchResult:(OASearchResult *)r
{
    return [_shared selectSearchResultR:[r toSharedResult]];
}

- (OASearchPhrase *)resetPhrase
{
    return [self wrapPhrase:[_shared resetPhrase]];
}

- (OASearchPhrase *)resetPhrase:(NSString *)text
{
    return [self wrapPhrase:[_shared resetPhraseText:text]];
}

- (void)search:(NSString *)text delayedExecution:(BOOL)delayedExecution matcher:(OAResultMatcher<OASearchResult *> *)matcher
{
    // the settings the core holds get the readers of the maps installed now, in place
    [(OASharedSearchSettings *) [self getSearchSettings] sharedWithCurrentReaders];
    [_shared searchText:text delayedExecution:delayedExecution matcher:[self sharedMatcherFor:matcher cancelledBySearch:YES]];
}

- (void)cancelSearch:(BOOL)sync
{
    [_cancels incrementAndGet];
    if (!sync)
        return;

    dispatch_semaphore_t ended = dispatch_semaphore_create(0);
    [_shared runAfterSearchTask:^{
        dispatch_semaphore_signal(ended);
    }];
    // a search waiting for the main thread cannot end while the main thread waits for it: not for ever
    dispatch_semaphore_wait(ended, dispatch_time(DISPATCH_TIME_NOW, (int64_t) (3 * NSEC_PER_SEC)));
}

- (BOOL)isSearchMoreAvailable:(OASearchPhrase *)phrase
{
    OASSearchPhrase *shared = [phrase isKindOfClass:OASharedSearchPhrase.class] ? ((OASharedSearchPhrase *) phrase).shared : nil;
    return shared && [_shared isSearchMoreAvailablePhrase:shared];
}

- (int)getMinimalSearchRadius:(OASearchPhrase *)phrase
{
    OASSearchPhrase *shared = [phrase isKindOfClass:OASharedSearchPhrase.class] ? ((OASharedSearchPhrase *) phrase).shared : nil;
    return shared ? [_shared getMinimalSearchRadiusPhrase:shared] : INT_MAX;
}

- (int)getNextSearchRadius:(OASearchPhrase *)phrase
{
    OASSearchPhrase *shared = [phrase isKindOfClass:OASharedSearchPhrase.class] ? ((OASharedSearchPhrase *) phrase).shared : nil;
    return shared ? [_shared getNextSearchRadiusPhrase:shared] : INT_MAX;
}

- (OAPOIBaseType *)getUnselectedPoiType
{
    return [OASharedSearchObjects appObjectFor:[_shared getUnselectedPoiType]];
}

- (NSString *)getCustomNameFilter
{
    return [_shared getCustomNameFilter];
}

- (void)setOnSearchStart:(OASearchUICoreRunnable)onSearchStart
{
    [super setOnSearchStart:onSearchStart];
    [_shared setOnSearchStartOnSearchStart:onSearchStart];
}

- (void)setOnResultsComplete:(OASearchUICoreRunnable)onResultsComplete
{
    [super setOnResultsComplete:onResultsComplete];
    [_shared setOnResultsCompleteOnResultsComplete:onResultsComplete];
}

// the C++ search's phrase and matcher: there is no such search here
- (void)searchInBackground:(OASearchPhrase *)phrase matcher:(OASearchResultMatcher *)matcher
{
}

@end
