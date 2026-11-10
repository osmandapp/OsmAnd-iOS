//
//  OAQuickSearchHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 27/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAQuickSearchHelper.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAWorldRegion.h"
#import "OAObfFileList.h"
#import "OASearchUICore.h"
#import "OALocationServices.h"
#import "OASearchPhrase.h"
#import "OAObservable.h"
#import "OAAtomicInteger.h"
#import "OASearchSettings.h"
#import "OASearchResultMatcher.h"
#import "OASearchResult+cpp.h"
#import "OAHistoryItem.h"
#import "OAHistoryHelper.h"
#import "OAPOIFiltersHelper.h"
#import "OAPOIUIFilter.h"
#import "OACustomSearchPoiFilter.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OASearchWord.h"
#import "Localization.h"
#import "OAAutoObserverProxy.h"
#import "OAGPXDatabase.h"
#import "OAPointDescription.h"
#import "OAPOIHelper.h"
#import "OAFavoritesHelper.h"
#import "OAFavoriteItem.h"
#import "OAPOIType.h"
#import "OAPOI.h"
#import "OAResultMatcher.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAResourcesUIHelper.h"
#import "OAManageResourcesViewController.h"
#import "OASharedSearchUICore.h"
#import "OASharedSearchObjects.h"
#import "OsmAndSharedWrapper.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>

static const int SEARCH_FAVORITE_API_PRIORITY = 150;
static const int SEARCH_FAVORITE_API_CATEGORY_PRIORITY = 150;
static const int SEARCH_FAVORITE_OBJECT_PRIORITY = 150;
static const int SEARCH_FAVORITE_CATEGORY_PRIORITY = 151;
static const int SEARCH_WPT_API_PRIORITY = 150;
static const int SEARCH_WPT_OBJECT_PRIORITY = 152;
static const int SEARCH_HISTORY_API_PRIORITY = 150;
static const int SEARCH_HISTORY_OBJECT_PRIORITY = 154;
static const int SEARCH_TRACK_API_PRIORITY = 150;
static const int SEARCH_TRACK_OBJECT_PRIORITY = 153;
static const int SEARCH_INDEX_ITEM_API_PRIORITY = 150;
// NOTE: Android uses 150, but sometimes the values of ITEM_PRIORITY are mixed. (search: "den")
static const int SEARCH_INDEX_ITEM_PRIORITY = 149;

static NSString * const GPX_TEMP_FOLDER_NAME = @"Temp";

@implementation SearchIndexItemAPI

- (BOOL)search:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    OAWorldRegion *worldRegion = [[OsmAndApp instance] worldRegion];
    [self processGroups:worldRegion search:phrase resultMatcher:resultMatcher];
    return YES;
}

- (void)processGroups:(OAWorldRegion *)group
               search:(OASearchPhrase *)phrase
        resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    OARepositoryResourceItem *indexItem = nil;
    NSString *name = nil;
    OAWorldRegion *region = group;
    if (region)
    {
        name = [[region.allNames componentsJoinedByString:@" "] ?: group.name lowerCase];
    }
    
    if (group.superregion
        && group.superregion.superregion
        && group.superregion.superregion.resourceTypes
        && [self isMatch:phrase text:name]
        && [group.resourceTypes containsObject:@((int)OsmAnd::ResourcesManager::ResourceType::MapRegion)])
    {
        NSArray<NSString *> *ids = [OAManageResourcesViewController getResourcesInRepositoryIdsByRegion:group];
        if (ids.count > 0)
        {
            indexItem = [OAResourcesUIHelper uninstalledMapFromResourceIds:ids region:region];
        }
    }
    
    if (indexItem)
    {
        [resultMatcher publish:[self createSearchResultWithPhrase:phrase item:indexItem localeName:indexItem.title]];
    }
    
    if (group.subregions)
    {
        for (OAWorldRegion *subregion in group.subregions)
        {
            [self processGroups:subregion search:phrase resultMatcher:resultMatcher];
        }
    }
}

- (OASearchResult *)createSearchResultWithPhrase:(OASearchPhrase *)phrase
                                            item:(OARepositoryResourceItem *)item
                                      localeName:(NSString *)localeName
{
    OASearchResult *sr = [[OASearchResult alloc] initWithPhrase:phrase];
    sr.localeName = localeName;
    // NOTE: for duplicate detection, if regions/subregions and city search return the same results
    sr.resourceId = item.resourceId.toNSString();
    // NOTE: skip the EOAUnknownPhraseMatchWeight search stage
     sr.unknownPhraseMatchWeight = -1;
    sr.priority = SEARCH_INDEX_ITEM_PRIORITY;
    sr.objectType = EOAObjectTypeIndexItem;
    sr.relatedObject = item;
    sr.preferredZoom = 17;

    return sr;
}

- (BOOL)isMatch:(OASearchPhrase *)phrase text:(NSString *)text
{
    OANameStringMatcher *matcher = [[OANameStringMatcher alloc] initWithNamePart:[phrase getFullSearchPhrase] mode:CHECK_EQUALS_FROM_SPACE];
    return [matcher matches:text];
}

- (int)getSearchPriority:(OASearchPhrase *)phrase
{
    if (![phrase isNoSelectedType])
    {
        return -1;
    }
    return SEARCH_INDEX_ITEM_API_PRIORITY;
}

- (BOOL)isSearchMoreAvailable:(OASearchPhrase *)phrase
{
    return NO;
}

@end


@implementation OASearchFavoritesAPI

-(BOOL)isSearchMoreAvailable:(OASearchPhrase *)phrase
{
    return NO;
}

-(BOOL)search:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    for (OAFavoriteItem *point in [OAFavoritesHelper getFavoriteItems])
    {
        if (![point isVisible])
            continue;

        OASearchResult *sr = [[OASearchResult alloc] initWithPhrase:phrase];
        sr.localeName = [point getDisplayName];
        sr.favorite = point.favorite;
        sr.priority = SEARCH_FAVORITE_OBJECT_PRIORITY;
        sr.objectType = EOAObjectTypeFavorite;
        sr.location = [[CLLocation alloc] initWithLatitude:point.favorite->getLatLon().latitude
                                                 longitude:point.favorite->getLatLon().longitude];
        sr.preferredZoom = PREFERRED_FAVORITE_ZOOM;
        if ([phrase getFullSearchPhrase].length <= 1 && [phrase isNoSelectedType])
        {
            [resultMatcher publish:sr];
        }
        else
        {
            OANameStringMatcher *matcher = [[OANameStringMatcher alloc] initWithNamePart:[phrase getFullSearchPhrase] mode:CHECK_CONTAINS];
            if ([matcher matches:sr.localeName])
                [resultMatcher publish:sr];
        }
    }
    return YES;
}

- (int) getSearchPriority:(OASearchPhrase *)p
{
    if (![p isNoSelectedType] || ![p isUnknownSearchWordPresent])
        return -1;
    
    return SEARCH_FAVORITE_API_PRIORITY;
}

@end


@implementation OASearchFavoritesCategoryAPI

- (BOOL) isSearchMoreAvailable:(OASearchPhrase *)phrase
{
    return NO;
}

- (BOOL) search:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    for (OAFavoriteItem *point in [OAFavoritesHelper getFavoriteItems])
    {
        if (![point isVisible])
            continue;

        OASearchResult *sr = [[OASearchResult alloc] initWithPhrase:phrase];
        sr.localeName = [point getDisplayName];
        sr.favorite = point.favorite;
        sr.priority = SEARCH_FAVORITE_CATEGORY_PRIORITY;
        sr.objectType = EOAObjectTypeFavorite;
        sr.location = [[CLLocation alloc] initWithLatitude:point.favorite->getLatLon().latitude
                                                 longitude:point.favorite->getLatLon().longitude];
        sr.preferredZoom = PREFERRED_FAVORITES_GROUP_ZOOM;
        NSString *group = [point getCategory];
        if (group && group.length > 0 && [[phrase getFirstUnknownNameStringMatcher] matches:group])
            [resultMatcher publish:sr];
    }
    return YES;
}

- (int) getSearchPriority:(OASearchPhrase *)p
{
    if (![p isNoSelectedType] || ![p isUnknownSearchWordPresent])
        return -1;
    
    return SEARCH_FAVORITE_API_CATEGORY_PRIORITY;
}

@end

@implementation OASearchGpxAPI

- (BOOL) isSearchMoreAvailable:(OASearchPhrase *)phrase
{
    return NO;
}

- (BOOL) search:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    for (OASGpxDataItem *dataItem in OAGPXDatabase.sharedDb.getDataItems)
    {
        // Exclude temporary GPX tracks from search.
        if ([self shouldIgnoreGpxItem:dataItem])
            continue;
        
        OASearchResult *sr = [[OASearchResult alloc] initWithPhrase:phrase];
        sr.objectType = EOAObjectTypeGpxTrack;
        sr.localeName = [dataItem gpxFileName];
        sr.relatedObject = dataItem;
        sr.priority = SEARCH_TRACK_OBJECT_PRIORITY;
        sr.preferredZoom = PREFERRED_GPX_FILE_ZOOM;
        if ([phrase getFullSearchPhrase].length <= 1 && [phrase isNoSelectedType])
        {
            [resultMatcher publish:sr];
        }
        else
        {
            OANameStringMatcher *matcher = [[OANameStringMatcher alloc] initWithNamePart:[phrase getFullSearchPhrase] mode:CHECK_CONTAINS];
            if ([matcher matches:sr.localeName])
                [resultMatcher publish:sr];
        }
    }
    return YES;
}

- (int) getSearchPriority:(OASearchPhrase *)p
{
    if (![p isNoSelectedType] || ![p isUnknownSearchWordPresent])
        return -1;
    
    return SEARCH_TRACK_API_PRIORITY;
}

- (BOOL)shouldIgnoreGpxItem:(OASGpxDataItem *)dataItem
{
    return [self isTemporaryGpxItem:dataItem];
}

- (BOOL)isTemporaryGpxItem:(OASGpxDataItem *)dataItem
{
    return [dataItem.gpxFolderName hasPrefix:GPX_TEMP_FOLDER_NAME];
}

@end

@implementation OASearchWptAPI
{
    NSArray<OASGpxFile *> *_geoDocList;
    NSArray *_paths;
}

- (void)setWptData:(NSArray<OASGpxFile *> *)geoDocList paths:(NSArray *)paths
{
    _geoDocList = geoDocList;
    _paths = paths;
}

- (void) resetWptData
{
    _geoDocList = nil;
    _paths = nil;
}

- (BOOL) isSearchMoreAvailable:(OASearchPhrase *)phrase
{
    return NO;
}

- (BOOL) search:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    if ([phrase isEmpty])
        return NO;
    
    OASearchWptAPI * __weak weakSelf = self;
    dispatch_block_t onMain = ^{
        [[OARootViewController instance].mapPanel.mapViewController setWptData:weakSelf];
    };
    if ([NSThread isMainThread])
        onMain();
    else
        dispatch_sync(dispatch_get_main_queue(), onMain);

    int i = 0;
    for (OASGpxFile *gpx in _geoDocList)
    {
        if (!gpx || gpx.getPointsList.count == 0)
        {
            i++;
            continue;
        }
        
        for (OASWptPt *point in gpx.getPointsList) {
            NSString *pointName = [point.name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (pointName.length == 0)
                continue;

            OASearchResult *sr = [[OASearchResult alloc] initWithPhrase:phrase];
            sr.localeName = pointName;
            sr.wpt = point;
            sr.object = sr.wpt;
            sr.priority = SEARCH_WPT_OBJECT_PRIORITY;
            sr.objectType = EOAObjectTypeWpt;
            sr.location = [[CLLocation alloc] initWithLatitude:point.position.latitude longitude:point.position.longitude];
            //sr.localeRelatedObjectName = app.getRegions().getCountryName(sr.location);
            sr.localeRelatedObjectName = i < _paths.count ? [_paths[i] lastPathComponent] : OALocalizedString(@"shared_string_currently_recording_track");
            sr.relatedGpx = gpx;
            sr.preferredZoom = PREFERRED_WPT_ZOOM;
            if ([phrase getFullSearchPhrase].length <= 1 && [phrase isNoSelectedType])
                [resultMatcher publish:sr];
            else
            {
                OANameStringMatcher *matcher = [[OANameStringMatcher alloc] initWithNamePart:[phrase getFullSearchPhrase] mode:CHECK_CONTAINS];
                if ([matcher matches:sr.localeName])
                    [resultMatcher publish:sr];
            }
        }
        i++;
    }
    return YES;
}

-(int)getSearchPriority:(OASearchPhrase *)p
{
    if (![p isNoSelectedType])
        return -1;
    
    return SEARCH_WPT_API_PRIORITY;
}

@end


@implementation OASearchHistoryAPI

- (BOOL) isSearchMoreAvailable:(OASearchPhrase *)phrase
{
    return NO;
}

- (BOOL) search:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    OAHistoryHelper *historyhelper = [OAHistoryHelper sharedInstance];
    int p = 0;
    for (OAHistoryItem *point in [historyhelper getPointsHavingTypes:historyhelper.searchTypes exceptNavigation:NO limit:0])
    {
        BOOL publish = NO;
        OASearchResult *sr = [[OASearchResult alloc] initWithPhrase:phrase];
        OAPointDescription *pd = [[OAPointDescription alloc] initWithType:[point getPointDescriptionType]
                                                                 typeName:point.typeName
                                                                     name:point.name];
        if ([pd isPoiType])
        {
            NSString *name = pd.name;
            OAPOIHelper *mapPoiTypes = [OAPOIHelper sharedInstance];
            OAPOIBaseType *pt = [mapPoiTypes getAnyPoiTypeByName:name];
            if (!pt)
            {
                pt = [mapPoiTypes getAnyPoiAdditionalTypeByKey:name];
            }
            if (pt)
            {
                if ([OSM_WIKI_CATEGORY isEqualToString:pt.name])
                    sr.localeName = [NSString stringWithFormat:@"%@ (%@)", pt.nameLocalized, [mapPoiTypes getAllLanguagesTranslationSuffix]];
                else
                    sr.localeName = [PoiAdditionalLabels getSearchName:pt];
                sr.object = pt;
                sr.relatedObject = point;
                sr.priorityDistance = 0;
                sr.objectType = EOAObjectTypePoiType;
                publish = YES;
            }
        }
        else if ([pd isCustomPoiFilter])
        {
            OAPOIUIFilter *filter = [[OAPOIFiltersHelper sharedInstance] getFilterById:pd.name includeDeleted:YES];
            if (filter)
            {
                sr.localeName = filter.name;
                sr.object = filter;
                sr.relatedObject = point;
                sr.objectType = EOAObjectTypePoiType;
                publish = YES;
            }
        }
        else if ([pd isGpxFile])
        {
            OASGpxDataItem *dataItem = [[OAGPXDatabase sharedDb] getGPXItemByFileName:pd.name];
            if (dataItem)
            {
                sr.localeName = [dataItem gpxFileName];
                sr.object = point;
                sr.objectType = EOAObjectTypeGpxTrack;
                sr.relatedObject = dataItem;
                publish = YES;
            }
        }
        else
        {
            sr.localeName = pd.name;
            sr.object = point;
            sr.objectType = EOAObjectTypeRecentObj;
            sr.location = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude];
            sr.preferredZoom = PREFERRED_DEFAULT_RECENT_ZOOM;
            publish = YES;
        }
        if (publish)
        {
            sr.priority = SEARCH_HISTORY_OBJECT_PRIORITY + (p++);
            if ([phrase getFullSearchPhrase].length <= 1 && [phrase isNoSelectedType])
                [resultMatcher publish:sr];
            else if ([[phrase getFirstUnknownNameStringMatcher] matches:sr.localeName])
                [resultMatcher publish:sr];
        }
    }
    return YES;
}

- (int) getSearchPriority:(OASearchPhrase *)p
{
    if (![p isEmpty])
        return -1;
    
    return SEARCH_HISTORY_API_PRIORITY;
}

@end


@implementation OAQuickSearchHelper
{
    OASearchUICore *_core;
    OASearchResultCollection *_resultCollection;
    OAAutoObserverProxy* _localResourcesChangedObserver;

    OAAtomicInteger *_searchRequestsCount;
    dispatch_queue_t _searchCitiesQueue;
    
    BOOL _resourcesInvalidated;
    OAAutoObserverProxy *_backgroundStateObserver;
}

+ (OAQuickSearchHelper *) instance
{
    static dispatch_once_t once;
    static OAQuickSearchHelper * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
        [sharedInstance initSearchUICore];
    });
    return sharedInstance;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        NSString *lang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
        BOOL transliterate = [OAAppSettings sharedManager].settingMapLanguageTranslit.get;
        // read once: the results of one search cannot go to the other
        Class coreClass = [[OAAppSettings sharedManager].useSharedSearch get] ? OASharedSearchUICore.class : OASearchUICore.class;
        _core = [[coreClass alloc] initWithLang:lang ?: @"" transliterate:transliterate];

        _searchRequestsCount = [OAAtomicInteger atomicInteger:0];
        _searchCitiesQueue = dispatch_queue_create("net.osmand.downloadCities", DISPATCH_QUEUE_SERIAL);

        _backgroundStateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onBackgroundStateChanged)
                                                              andObserve:OsmAndApp.instance.backgroundStateObservable];

        _localResourcesChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                   withHandler:@selector(onLocalResourcesChanged:withKey:)
                                                                    andObserve:[OsmAndApp instance].localResourcesChangedObservable];
    }
    return self;
}

- (void) dealloc
{
    if (_localResourcesChangedObserver)
    {
        [_localResourcesChangedObserver detach];
        _localResourcesChangedObserver = nil;
    }
    if (_backgroundStateObserver)
    {
        [_backgroundStateObserver detach];
        _backgroundStateObserver = nil;
    }
}

- (OASearchUICore *) getCore
{
    return _core;
}

- (OASearchResultCollection *) getResultCollection
{
    return _resultCollection;
}

- (void) setResultCollection:(OASearchResultCollection *)resultCollection
{
    _resultCollection = resultCollection;
}

- (void) initSearchUICore
{
    [self setResourcesForSearchUICore];
    if ([_core isKindOfClass:OASharedSearchUICore.class])
    {
        // made again when the spatial search is switched
        OASharedSearchUICore *core = (OASharedSearchUICore *) _core;
        [core.shared clearAPIs];
        [core.shared resetSearch];
        _resultCollection = nil;
        // the rules files rules*.xml of resources/abbr
        NSString *searchRulesDir = [NSBundle.mainBundle pathForResource:@"abbr" ofType:nil];
        [core initApiUseSpatialSearch:[[OAAppSettings sharedManager].useSpatialTextSearch get] searchRulesDir:searchRulesDir ?: @""];
    }
    else
    {
        [_core initApi];
    }
    // Register map search api
    [_core registerAPI:[[SearchIndexItemAPI alloc] init]];
    
    // Register favorites search api
    [_core registerAPI:[[OASearchFavoritesAPI alloc] init]];

    // Register favorites by category search api
    [_core registerAPI:[[OASearchFavoritesCategoryAPI alloc] init]];
    
    // Register WptPt search api
    [_core registerAPI:[[OASearchWptAPI alloc] init]];
    [_core registerAPI:[[OASearchHistoryAPI alloc] init]];
    
    // Register Gpx search api
    [_core registerAPI:[[OASearchGpxAPI alloc] init]];
    
    [self refreshCustomPoiFilters];
}

- (void) refreshCustomPoiFilters
{
    [_core clearCustomSearchPoiFilters];
    OAPOIFiltersHelper *poiFilters = [OAPOIFiltersHelper sharedInstance];
    for (OACustomSearchPoiFilter *udf in [poiFilters getUserDefinedPoiFilters:NO])
        [_core addCustomSearchPoiFilter:udf priority:0];
    OAPOIUIFilter *topWikiPoiFilter = [poiFilters getTopWikiPoiFilter];
    if (topWikiPoiFilter && topWikiPoiFilter.isActive)
        [_core addCustomSearchPoiFilter:topWikiPoiFilter priority:1];
    OAPOIUIFilter *showAllPOIFilter = [poiFilters getShowAllPOIFilter];
    if (showAllPOIFilter != nil && showAllPOIFilter.isActive)
        [_core addCustomSearchPoiFilter:showAllPOIFilter priority:1];
    [self refreshFilterOrders];
}

- (void) refreshFilterOrders
{
    OAPOIFiltersHelper *poiFilters = [OAPOIFiltersHelper sharedInstance];
    [_core setActivePoiFiltersByOrder:[poiFilters getPoiFilterOrders:YES]];
}

- (void) cancelSearch:(BOOL)sync
{
    [_core cancelSearch:sync];
}

- (void) setResourcesForSearchUICore
{
    OsmAndAppInstance app = [OsmAndApp instance];
    BOOL isCarPlayAppActive = UIApplication.sharedApplication.isCarPlayAppActive;
    if ([_core isKindOfClass:OASharedSearchUICore.class])
    {
        [(OASharedSearchUICore *) _core updateSearchResourcesIncludingTravel:!isCarPlayAppActive regions:app.worldRegion];
        return;
    }
    [[_core getSearchSettings] setOfflineIndexes:[OAObfFileList searchResourceIdsIncludingTravel:!isCarPlayAppActive]];
    [[_core getSearchSettings] setRegions:app.worldRegion];
}

- (void) onBackgroundStateChanged
{
    if (!OsmAndApp.instance.isInBackground && _resourcesInvalidated)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setResourcesForSearchUICore];
            _resourcesInvalidated = NO;
        });
    }
}

- (void) onLocalResourcesChanged:(id<OAObservableProtocol>)observer withKey:(id)key
{
    if (OsmAndApp.instance.isInBackground)
    {
        _resourcesInvalidated = YES;
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self setResourcesForSearchUICore];
    });
}

- (void)cancelSearchCities
{
    [_searchRequestsCount incrementAndGet];
}

- (id<OASAmenityIndexRepository>)citySearchRepository
{
    for (NSString *resourceId in @[@kWorldBasemapKey, kWorldMiniBasemapKey.lowercaseString])
    {
        id<OASAmenityIndexRepository> candidate = [OASharedObfResources.shared amenityRepositoryForResourceId:resourceId];
        if (candidate && [[candidate getFile] exists])
            return candidate;
    }
    return nil;
}

- (OASSearchRequest<OASAmenity *> *)citySearchRequest:(NSString *)text
                                       allowedTypes:(NSArray<NSString *> *)allowedTypes
                                          cityLimit:(NSInteger)cityLimit
                                        isCancelled:(BOOL (^)(void))isCancelled
                                             cities:(NSMutableArray<OASearchResult *> *)cities
{
    OASSearchSettings *settings = [[OASSearchSettings alloc] initWithS:nil];
    // The search origin supplies the regional abbreviation rules, not a distance limit.
    CLLocation *location = [[_core getSearchSettings] getOriginalLocation];
    if (location)
    {
        [settings setRegionsRegions:[OASOsmandRegions.companion getDefault]];
        settings = [settings setOriginalLocationL:[[OASKLatLon alloc] initWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude]];
    }
    OASNameStringMatcher *matcher = [[[OASSearchPhrase.companion emptyPhraseSettings:settings] generateNewPhraseText:text settings:settings] getFirstUnknownNameStringMatcher];
    NSString *lang = [OAAppSettings.sharedManager.settingPrefMapLanguage get];
    BOOL transliterate = [OAAppSettings.sharedManager.settingMapLanguageTranslit get];
    __block NSInteger count = 0;
    id<OASResultMatcher> resultMatcher = [OASharedBlockResultMatcher matcherWithPublish:^BOOL(OASAmenity *amenity) {
        if (count++ > cityLimit || (isCancelled && isCancelled()))
            return NO;
        NSString *localeName = [amenity getNameLang:lang transliterate:transliterate];
        if (![allowedTypes containsObject:[amenity getSubType] ?: @""]
            || (![matcher matchesName:localeName] && ![matcher matchesMap:[amenity getOtherNamesTransliterate:YES]]))
            return NO;
        OASKLatLon *location = [amenity getLocation];
        if (!location)
            return NO;
        OASearchResult *city = [[OASearchResult alloc] initWithPhrase:nil];
        city.object = amenity;
        city.localeName = localeName;
        city.location = [[CLLocation alloc] initWithLatitude:location.latitude longitude:location.longitude];
        [cities addObject:city];
        return NO;
    } cancelled:^BOOL{
        return count > cityLimit || (isCancelled && isCancelled());
    }];
    return [OASSearchRequest.companion buildSearchPoiRequestX:0 y:0 nameFilter:text
                                                                                        sleft:INT_MIN sright:INT_MAX stop:INT_MIN sbottom:INT_MAX
                                                                                poiTypeFilter:nil resultMatcher:resultMatcher rawDataCollector:nil];
}

// Searches the world basemap independently of the main search engine and its selected phrase.
- (NSMutableArray<OASearchResult *> *)searchCities:(NSString *)text
                                      allowedTypes:(NSArray<NSString *> *)allowedTypes
                                         cityLimit:(NSInteger)cityLimit
                                       isCancelled:(BOOL (^)(void))isCancelled
{
    NSMutableArray<OASearchResult *> *cities = [NSMutableArray array];
    if (isCancelled && isCancelled())
        return cities;
    id<OASAmenityIndexRepository> repository = [self citySearchRepository];
    if (!repository)
        return cities;
    OASSearchRequest<OASAmenity *> *request = [self citySearchRequest:text allowedTypes:allowedTypes cityLimit:cityLimit isCancelled:isCancelled cities:cities];
    [repository searchPoiByNameSearchRequest:request];
    return cities;
}

- (void)searchCitiesAsync:(NSString *)text
             allowedTypes:(NSArray<NSString *> *)allowedTypes
                cityLimit:(NSInteger)cityLimit
               onComplete:(void (^)(NSMutableArray *amenities))onComplete
{
    int request = [_searchRequestsCount incrementAndGet];
    text = [text copy];
    allowedTypes = [allowedTypes copy];
    dispatch_async(_searchCitiesQueue, ^{
        NSMutableArray<OASearchResult *> *cities = [self searchCities:text allowedTypes:allowedTypes cityLimit:cityLimit isCancelled:^BOOL{
            return [_searchRequestsCount get] != request;
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([_searchRequestsCount get] == request && onComplete)
                onComplete(cities);
        });
    });
}

- (void) searchCityLocations:(NSString *)text
      searchLocation:(CLLocation *)searchLocation
        searchBBox31:(QuadRect *)searchBBox31
        allowedTypes:(NSArray<NSString *> *)allowedTypes
               limit:(NSInteger)limit
          onComplete:(void (^)(NSArray<OASearchResult *> *searchResults))onComplete
{
    int request = [_searchRequestsCount incrementAndGet];

    NSString *lang = [[OAAppSettings sharedManager].settingPrefMapLanguage get];
    BOOL transliterate = [[OAAppSettings sharedManager].settingMapLanguageTranslit get];
    NSMutableArray *results = [NSMutableArray array];

    OAQuickSearchHelper *searchHelper = [OAQuickSearchHelper instance];
    OASearchUICore *searchUICore = [searchHelper getCore];
    OASearchSettings *settings = [[searchUICore getSearchSettings] setOriginalLocation:[OsmAndApp instance].locationServices.lastKnownLocation];
    settings = [settings setLang:lang ? lang : @"" transliterateIfMissing:transliterate];
    settings = [settings setSortByName:NO];
    settings = [settings setAddressSearch:YES];
    settings = [settings setEmptyQueryAllowed:YES];
    settings = [settings setOriginalLocation:searchLocation];
    settings = [settings setSearchBBox31:searchBBox31];

    int __block count = 0;
    [searchUICore shallowSearchAsync:OASearchLocationAndUrlAPI.class
                           text:text
                        matcher:[[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OASearchResult *__autoreleasing *object) {
        OASearchResult *searchResult = *object;
        CLLocation *location = searchResult.location;
        if (!location)
            return NO;
            
        if (count++ > limit || [_searchRequestsCount get] != request)
            return NO;

        [results addObject:searchResult];
        return NO;
    } cancelledFunc:^BOOL{
        return count > limit || [_searchRequestsCount get] != request;
    }] resortAll:YES removeDuplicates:YES searchSettings:settings completion:^(OASearchResultCollection *collection) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([_searchRequestsCount get] == request && onComplete)
                onComplete(results);
        });
    }];
}

@end
