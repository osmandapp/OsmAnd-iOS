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
        else if ([[phrase getFirstUnknownNameStringMatcher] matches:sr.localeName])
            [resultMatcher publish:sr];
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


@implementation OASearchWptAPI
{
    QList<std::shared_ptr<const OsmAnd::GeoInfoDocument>> _geoDocList;
    NSArray *_paths;
}

- (void) setWptData:(QList<std::shared_ptr<const OsmAnd::GeoInfoDocument>>&)geoDocList paths:(NSArray *)paths
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
        for (auto it = gpx->locationMarks.begin(); it != gpx->locationMarks.end(); ++it)
        {
            const auto& point = *it;
            OASearchResult *sr = [[OASearchResult alloc] initWithPhrase:phrase];
            sr.localeName = point->name.toNSString();
            sr.wpt = point;
            const auto& gpxWpt = std::dynamic_pointer_cast<const OsmAnd::GpxDocument::GpxWpt>(sr.wpt);
            sr.object = [OAGPXDocument fetchWpt:qMove(gpxWpt)];
            sr.priority = SEARCH_WPT_OBJECT_PRIORITY;
            sr.objectType = WPT;
            sr.location = [[CLLocation alloc] initWithLatitude:point->position.latitude longitude:point->position.longitude];
            //sr.localeRelatedObjectName = app.getRegions().getCountryName(sr.location);
            sr.localeRelatedObjectName = i < _paths.count ? [_paths[i] lastPathComponent] : OALocalizedString(@"track_recording_name");
            sr.relatedGpx = gpx;
            sr.preferredZoom = 17;
            if ([phrase getFullSearchPhrase].length <= 1 && [phrase isNoSelectedType])
                [resultMatcher publish:sr];
            else if ([[phrase getFirstUnknownNameStringMatcher] matches:sr.localeName])
                [resultMatcher publish:sr];
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
    OAHistoryHelper *helper = [OAHistoryHelper sharedInstance];
    NSArray *allItems = [helper getPointsHavingTypes:helper.searchTypes limit:0];
    int p = 0;
    for (OAHistoryItem *point in allItems)
    {
        OASearchResult *sr = [[OASearchResult alloc] initWithPhrase:phrase];
        sr.localeName = point.name;
        sr.object = point;
        sr.priority = SEARCH_HISTORY_OBJECT_PRIORITY + (p++);
        sr.objectType = RECENT_OBJ;
        sr.location = [[CLLocation alloc] initWithLatitude:point.latitude longitude:point.longitude];
        sr.preferredZoom = 17;
        if ([phrase getFullSearchPhrase].length <= 1 && [phrase isNoSelectedType])
            [resultMatcher publish:sr];
        else if ([[phrase getFirstUnknownNameStringMatcher] matches:sr.localeName])
            [resultMatcher publish:sr];
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
        first = [[first stringByReplacingOccurrencesOfString:@".map.obf" withString:@""] stringByReplacingOccurrencesOfString:@".live.obf" withString:@""];
        second = [[second stringByReplacingOccurrencesOfString:@".map.obf" withString:@""] stringByReplacingOccurrencesOfString:@".live.obf" withString:@""];
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
}

- (void) onLocalResourcesChanged:(id<OAObservableProtocol>)observer withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setResourcesForSearchUICore];
    });
}

@end
