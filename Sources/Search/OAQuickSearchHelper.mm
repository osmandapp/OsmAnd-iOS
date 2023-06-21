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
#import "OASearchUICore.h"
#import "OASearchPhrase.h"
#import "OASearchSettings.h"
#import "OASearchResultMatcher.h"
#import "OAHistoryItem.h"
#import "OAHistoryHelper.h"
#import "OAPOIFiltersHelper.h"
#import "OAPOIUIFilter.h"
#import "OACustomSearchPoiFilter.h"
#import "OARootViewController.h"
#import "OASearchWord.h"
#import "Localization.h"
#import "OAAutoObserverProxy.h"
#import "OAGPXDatabase.h"
#import "OAPointDescription.h"
#import "OAPOIHelper.h"

#include "OAGPXDocument+cpp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>

static const int SEARCH_FAVORITE_API_PRIORITY = 50;
static const int SEARCH_FAVORITE_API_CATEGORY_PRIORITY = 50;
static const int SEARCH_FAVORITE_OBJECT_PRIORITY = 50;
static const int SEARCH_FAVORITE_CATEGORY_PRIORITY = 51;
static const int SEARCH_WPT_API_PRIORITY = 50;
static const int SEARCH_WPT_OBJECT_PRIORITY = 52;
static const int SEARCH_HISTORY_API_PRIORITY = 50;
static const int SEARCH_HISTORY_OBJECT_PRIORITY = 53;
static const int SEARCH_TRACK_API_PRIORITY = 50;
static const int SEARCH_TRACK_OBJECT_PRIORITY = 53;


@implementation OASearchFavoritesAPI

-(BOOL)isSearchMoreAvailable:(OASearchPhrase *)phrase
{
    return NO;
}

-(BOOL)search:(OASearchPhrase *)phrase resultMatcher:(OASearchResultMatcher *)resultMatcher
{
    OsmAndAppInstance app = [OsmAndApp instance];
    for (const auto& point : app.favoritesCollection->getFavoriteLocations())
    {
        OASearchResult *sr = [[OASearchResult alloc] initWithPhrase:phrase];
        sr.localeName = point->getTitle().toNSString();
        sr.favorite = point;
        sr.priority = SEARCH_FAVORITE_OBJECT_PRIORITY;
        sr.objectType = FAVORITE;
        sr.location = [[CLLocation alloc] initWithLatitude:point->getLatLon().latitude longitude:point->getLatLon().longitude];
        sr.preferredZoom = 17;
        if ([phrase getFullSearchPhrase].length <= 1 && [phrase isNoSelectedType])
            [resultMatcher publish:sr];
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
    OsmAndAppInstance app = [OsmAndApp instance];
    for (const auto& point : app.favoritesCollection->getFavoriteLocations())
    {
        OASearchResult *sr = [[OASearchResult alloc] initWithPhrase:phrase];
        sr.localeName = point->getTitle().toNSString();
        sr.favorite = point;
        sr.priority = SEARCH_FAVORITE_CATEGORY_PRIORITY;
        sr.objectType = FAVORITE;
        sr.location = [[CLLocation alloc] initWithLatitude:point->getLatLon().latitude longitude:point->getLatLon().longitude];
        sr.preferredZoom = 17;
        if (!point->getGroup().isNull() && [[phrase getFirstUnknownNameStringMatcher] matches:point->getGroup().toNSString()])
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
    for (OAGPX *gpxInfo : [[OAGPXDatabase sharedDb] gpxList])
    {
        OASearchResult *sr = [[OASearchResult alloc] initWithPhrase:phrase];
        sr.objectType = GPX_TRACK;
        sr.localeName = gpxInfo.gpxTitle;
        sr.relatedObject = gpxInfo;
        sr.priority = SEARCH_TRACK_OBJECT_PRIORITY;
        sr.preferredZoom = 17;
        if ([phrase getFullSearchPhrase].length <= 1 && [phrase isNoSelectedType])
            [resultMatcher publish:sr];
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
    
    return SEARCH_TRACK_OBJECT_PRIORITY;
}

@end


@implementation OASearchWptAPI
{
    QList<std::shared_ptr<const OsmAnd::GpxDocument>> _geoDocList;
    NSArray *_paths;
}

- (void) setWptData:(QList<std::shared_ptr<const OsmAnd::GpxDocument>>&)geoDocList paths:(NSArray *)paths
{
    _geoDocList.append(geoDocList);
    _paths = [NSArray arrayWithArray:paths];
}

- (void) resetWptData
{
    _geoDocList.clear();
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
    for (auto gpxIt = _geoDocList.begin(); gpxIt != _geoDocList.end(); ++gpxIt)
    {
        const auto& gpx = *gpxIt;
        for (auto it = gpx->points.begin(); it != gpx->points.end(); ++it)
        {
            const auto& point = *it;
            OASearchResult *sr = [[OASearchResult alloc] initWithPhrase:phrase];
            sr.localeName = point->name.toNSString();
            sr.wpt = point;

            sr.object = [OAGPXDocument fetchWpt:std::const_pointer_cast<OsmAnd::GpxDocument::WptPt>(sr.wpt)];
            sr.priority = SEARCH_WPT_OBJECT_PRIORITY;
            sr.objectType = WPT;
            sr.location = [[CLLocation alloc] initWithLatitude:point->position.latitude longitude:point->position.longitude];
            //sr.localeRelatedObjectName = app.getRegions().getCountryName(sr.location);
            sr.localeRelatedObjectName = i < _paths.count ? [_paths[i] lastPathComponent] : OALocalizedString(@"shared_string_currently_recording_track");
            sr.relatedGpx = gpx;
            sr.preferredZoom = 17;
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
                    sr.localeName = pt.nameLocalized;
                sr.object = pt;
                sr.relatedObject = point;
                sr.priorityDistance = 0;
                sr.objectType = POI_TYPE;
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
                sr.objectType = POI_TYPE;
                publish = YES;
            }
        }
        else if ([pd isGpxFile])
        {
            OAGPX *gpxInfo = [[OAGPXDatabase sharedDb] getGPXItemByFileName:pd.name];
            if (gpxInfo)
            {
                sr.localeName = [gpxInfo gpxFileName];
                sr.object = point;
                sr.objectType = GPX_TRACK;
                sr.relatedObject = gpxInfo;
                publish = YES;
            }
        }
        else
        {
            sr.localeName = pd.name;
            sr.object = point;
            sr.objectType = RECENT_OBJ;
            sr.location = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude];
            sr.preferredZoom = 17;
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

    dispatch_queue_t _searchCitiesSerialQueue;
    dispatch_group_t _searchCitiesGroup;
    NSInteger _searchRequestsCount;
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
        _core = [[OASearchUICore alloc] initWithLang:lang ? lang : @"" transliterate:transliterate];

        _searchCitiesSerialQueue = dispatch_queue_create("quickSearch_OLCSearchQueue", DISPATCH_QUEUE_SERIAL);
        _searchCitiesGroup = dispatch_group_create();
        _searchRequestsCount = 0;

        _localResourcesChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                   withHandler:@selector(onLocalResourcesChanged:withKey:)
                                                                    andObserve:[OsmAndApp instance].localResourcesChangedObservable];
    }
    return self;
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
    [_core initApi];
    
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

- (void) setResourcesForSearchUICore
{
    OsmAndAppInstance app = [OsmAndApp instance];
    NSMutableArray<NSString *> *resIds = [NSMutableArray array];
    for (const auto& resource : app.resourcesManager->getLocalResources())
        if (resource->type == OsmAnd::ResourcesManager::ResourceType::MapRegion || resource->type == OsmAnd::ResourcesManager::ResourceType::WikiMapRegion || resource->type == OsmAnd::ResourcesManager::ResourceType::LiveUpdateRegion)
        {
            [resIds addObject:resource->id.toNSString()];
        }

    [resIds sortUsingComparator:^NSComparisonResult(NSString *first, NSString *second) {
        first = [[first stringByReplacingOccurrencesOfString:@".live.obf" withString:@""] stringByReplacingOccurrencesOfString:@".obf" withString:@""];
        second = [[second stringByReplacingOccurrencesOfString:@".live.obf" withString:@""] stringByReplacingOccurrencesOfString:@".obf" withString:@""];
        NSRange rangeFirst = [first rangeOfString:@"([0-9]+_){2}[0-9]+" options:NSRegularExpressionSearch];
        NSRange rangeSecond = [second rangeOfString:@"([0-9]+_){2}[0-9]+" options:NSRegularExpressionSearch];
        if (rangeFirst.location != NSNotFound && rangeSecond.location == NSNotFound)
        {
            NSString *base = [first substringToIndex:rangeFirst.location - 1];
            if ([base isEqualToString:second])
                return NSOrderedAscending;
            else
                [second compare:base];
        }
        else if (rangeFirst.location == NSNotFound && rangeSecond.location != NSNotFound)
        {
            NSString *base = [second substringToIndex:rangeSecond.location - 1];
            if ([base isEqualToString:first])
                return NSOrderedDescending;
            else
                [base compare:first];
        }
        
        return [first compare:second];
    }];
    [[_core getSearchSettings] setOfflineIndexes:[NSArray arrayWithArray:resIds]];
    [[_core getSearchSettings] setRegions:app.worldRegion];
}

- (void) onLocalResourcesChanged:(id<OAObservableProtocol>)observer withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setResourcesForSearchUICore];
    });
}

- (void)cancelSearchCities
{
    _searchRequestsCount = 0;
}

- (void)searchCities:(NSString *)text
      searchLocation:(CLLocation *)searchLocation
        allowedTypes:(NSArray<NSString *> *)allowedTypes
           cityLimit:(NSInteger)cityLimit
          onComplete:(void (^)(NSMutableArray *amenities))onComplete
{
    NSInteger searchRequestsCount = ++_searchRequestsCount;
    dispatch_block_t searchCitiesFunc = ^{
        dispatch_group_enter(_searchCitiesGroup);

        OANameStringMatcher *nm = [[OANameStringMatcher alloc] initWithNamePart:text mode:CHECK_STARTS_FROM_SPACE];
        NSString *lang = [[OAAppSettings sharedManager].settingPrefMapLanguage get];
        BOOL transliterate = [[OAAppSettings sharedManager].settingMapLanguageTranslit get];
        NSMutableArray *amenities = [NSMutableArray array];

        OAQuickSearchHelper *searchHelper = [OAQuickSearchHelper instance];
        OASearchUICore *searchUICore = [searchHelper getCore];
        OASearchSettings *settings = [[searchUICore getSearchSettings] setOriginalLocation:[OsmAndApp instance].locationServices.lastKnownLocation];
        settings = [settings setLang:lang ? lang : @"" transliterateIfMissing:transliterate];
        settings = [settings setSortByName:NO];
        settings = [settings setAddressSearch:YES];
        settings = [settings setEmptyQueryAllowed:YES];
        settings = [settings setOriginalLocation:searchLocation];
        [searchUICore updateSettings:settings];

        int __block count = 0;

        [searchUICore shallowSearch:OASearchAmenityByNameAPI.class
                               text:text
                            matcher:[[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OASearchResult *__autoreleasing *object) {
            OASearchResult *searchResult = *object;
            std::shared_ptr<const OsmAnd::Amenity> amenity = searchResult.amenity;
            if (!amenity)
                return NO;

            if (count++ > cityLimit || _searchRequestsCount > searchRequestsCount || _searchRequestsCount == 0)
                return NO;

            NSArray<NSString *> *otherNames = searchResult.otherNames;
            NSString *localeName = amenity->getName(QString(lang.UTF8String), transliterate).toNSString();
            NSString *subType = amenity->subType.toNSString();

            if (![allowedTypes containsObject:subType] || (![nm matches:localeName] && ![nm matchesMap:otherNames]))
                return NO;

            [amenities addObject:searchResult];
            return NO;
        } cancelledFunc:^BOOL{
            return count > cityLimit || _searchRequestsCount > searchRequestsCount || _searchRequestsCount == 0;
        }] resortAll:YES removeDuplicates:YES];

        if (_searchRequestsCount == searchRequestsCount)
        {
            _searchRequestsCount = 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (onComplete)
                    onComplete(amenities);
            });
        }
        dispatch_group_leave(_searchCitiesGroup);
    };

    dispatch_group_notify(_searchCitiesGroup, _searchCitiesSerialQueue, ^{
        dispatch_async(_searchCitiesSerialQueue, searchCitiesFunc);
    });
}

- (void) searchCityLocations:(NSString *)text
          searchLocation:(CLLocation *)searchLocation
            searchBBox31:(QuadRect *)searchBBox31
            allowedTypes:(NSArray<NSString *> *)allowedTypes
                   limit:(NSInteger)limit
              onComplete:(void (^)(NSArray<OASearchResult *> *searchResults))onComplete
{
    NSInteger searchRequestsCount = ++_searchRequestsCount;
    dispatch_block_t searchCitiesFunc = ^{
        dispatch_group_enter(_searchCitiesGroup);

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
        [searchUICore updateSettings:settings];

        int __block count = 0;
        [searchUICore shallowSearch:OASearchLocationAndUrlAPI.class
                               text:text
                            matcher:[[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OASearchResult *__autoreleasing *object) {
            OASearchResult *searchResult = *object;
            CLLocation *location = searchResult.location;
            if (!location)
                return NO;
            
            if (count++ > limit || _searchRequestsCount > searchRequestsCount || _searchRequestsCount == 0)
                return NO;
            
            [results addObject:searchResult];
            return NO;
        } cancelledFunc:^BOOL{
            return count > limit || _searchRequestsCount > searchRequestsCount || _searchRequestsCount == 0;
        }] resortAll:YES removeDuplicates:YES];

        if (_searchRequestsCount == searchRequestsCount)
        {
            _searchRequestsCount = 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (onComplete)
                    onComplete(results);
            });
        }
        dispatch_group_leave(_searchCitiesGroup);
    };

    dispatch_group_notify(_searchCitiesGroup, _searchCitiesSerialQueue, ^{
        dispatch_async(_searchCitiesSerialQueue, searchCitiesFunc);
    });
}

@end
