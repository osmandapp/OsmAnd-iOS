//
//  OACarPlayAddressSearchController.m
//  OsmAnd Maps
//
//  Created by Paul on 19.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACarPlayAddressSearchController.h"
#import "OASearchUICore.h"
#import "OAQuickSearchHelper.h"
#import "OAAppSettings.h"
#import "OASearchSettings.h"
#import "OAQuickSearchListItem.h"
#import "OsmAndApp.h"
#import "OAAddress.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapRendererView.h"
#import "OAResultMatcher.h"
#import "OASearchResult.h"
#import <CarPlay/CarPlay.h>

#include <OsmAndCore/Utilities.h>

@interface OACarPlayAddressSearchController() <CPSearchTemplateDelegate>

@end

@implementation OACarPlayAddressSearchController
{
    OASearchUICore *_searchUICore;
    OAQuickSearchHelper *_searchHelper;

    CPSearchTemplate *_searchTemplate;
    CPListTemplate *_resultsListTemplate;

    NSArray<OAQuickSearchListItem *> *_searchItems;
    NSArray<CPListItem *> *_cpItems;
    CPListItem *_searchingItem;
    CPListItem *_emptyItem;

    NSString *_currentSearchPhrase;
    BOOL _cancelPrev;
    BOOL _searching;
}

- (void) commonInit
{
    _searchingItem = [[CPListItem alloc] initWithText:OALocalizedString(@"searching") detailText:nil];
    _emptyItem = [[CPListItem alloc] initWithText:OALocalizedString(@"nothing_found") detailText:nil];
    _searchItems = @[];
    _cpItems = @[];

    _resultsListTemplate = [[CPListTemplate alloc] initWithTitle:OALocalizedString(@"shared_string_search")
                                                        sections:@[[[CPListSection alloc] initWithItems:_cpItems]]];

    _searchHelper = [OAQuickSearchHelper instance];
    _searchUICore = [_searchHelper getCore];
    _currentSearchPhrase = @"";

    OASearchSettings *settings = [_searchUICore getSearchSettings];
    [_searchHelper setResultCollection:nil];
    [_searchUICore resetPhrase];

    OAMapRendererView *mapView = (OAMapRendererView *) [OARootViewController instance].mapPanel.mapViewController.view;
    BOOL isMyLocationVisible = [[OARootViewController instance].mapPanel.mapViewController isMyLocationVisible];
    
    OsmAnd::PointI searchLocation;
    
    CLLocation *newLocation = [OsmAndApp instance].locationServices.lastKnownLocation;
    OsmAnd::PointI myLocation;
    double distanceFromMyLocation = 0;
    if (newLocation)
    {
        myLocation = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(newLocation.coordinate.latitude, newLocation.coordinate.longitude));
        if (!isMyLocationVisible)
        {
            distanceFromMyLocation = OsmAnd::Utilities::distance31(myLocation, mapView.target31);
            if (distanceFromMyLocation > 15000)
                searchLocation = mapView.target31;
            else
                searchLocation = myLocation;
        }
        else
        {
            searchLocation = myLocation;
        }
    }
    else
    {
        searchLocation = mapView.target31;
    }
    
    OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(searchLocation);
    settings = [[_searchUICore getSearchSettings] setOriginalLocation:[[CLLocation alloc] initWithLatitude:latLon.latitude
                                                                                                 longitude:latLon.longitude]];
    
    NSString *locale = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
    BOOL transliterate = [OAAppSettings sharedManager].settingMapLanguageTranslit.get;
    settings = [settings setLang:locale ? locale : @"" transliterateIfMissing:transliterate];
    [_searchUICore updateSettings:settings];
}

- (void)present
{
    _searchTemplate = [[CPSearchTemplate alloc] init];
    _searchTemplate.delegate = self;
    [self.interfaceController pushTemplate:_searchTemplate animated:YES completion:nil];
}

- (void)onItemSelected:(CPListItem * _Nonnull)item
{
    NSNumber *indexNum = item.userInfo;
    if (!indexNum || _searchItems.count == 0 || indexNum.integerValue >= _searchItems.count)
        return;
    
    NSInteger index = indexNum.integerValue;
    OAQuickSearchListItem *searchItem = _searchItems[index];
    CLLocation *loc = searchItem.getSearchResult.location;
    [self startNavigationGivenLocation:loc historyName:nil];
    [self.interfaceController popToRootTemplateAnimated:YES completion:nil];
}

- (void) updateSearchResult:(OASearchResultCollection *)res
          completionHandler:(void (^)(NSArray<CPListItem *> *searchResults))completionHandler
{
    NSMutableArray<OAQuickSearchListItem *> *searchItems = [NSMutableArray array];
    NSMutableArray<CPListItem *> *cpItems = [NSMutableArray array];

    if (_searching && _currentSearchPhrase.length > 0)
        [cpItems addObject:_searchingItem];

    NSInteger maximumItemCount = (NSInteger)CPListTemplate.maximumItemCount - 1;
    if (res && [res getCurrentSearchResults].count > 0)
    {
        NSArray<OASearchResult *> *searchResultItems = [res getCurrentSearchResults];
        __weak __typeof(self) weakSelf = self;
        for (NSInteger i = 0; i < searchResultItems.count; i++)
        {
            if (cpItems.count >= maximumItemCount)
                break;

            OASearchResult *sr = searchResultItems[i];
            OAQuickSearchListItem *qsItem = [[OAQuickSearchListItem alloc] initWithSearchResult:sr];
            CPListItem *cpItem = [[CPListItem alloc] initWithText:qsItem.getName
                                                       detailText:[self generateDescription:qsItem]
                                                            image:[UIImage mapSvgImageNamed:[OAQuickSearchListItem getIconName:sr]]
                                                   accessoryImage:nil
                                                    accessoryType:CPListItemAccessoryTypeDisclosureIndicator];
            cpItem.userInfo = @(i);
            cpItem.handler = ^(id <CPSelectableListItem> item, dispatch_block_t completionBlock) {
                [weakSelf onItemSelected:item];
                if (completionBlock)
                    completionBlock();
            };

            [searchItems addObject:qsItem];
            [cpItems addObject:cpItem];
        }
    }
    else if (!_searching && _currentSearchPhrase.length > 0)
    {
        [cpItems addObject:_emptyItem];
    }

    _searchItems = searchItems;
    _cpItems = cpItems;

    dispatch_async(dispatch_get_main_queue(), ^{
        [_resultsListTemplate updateSections:@[[[CPListSection alloc] initWithItems:_cpItems]]];
        if (completionHandler)
            completionHandler(@[]);
    });
}

- (NSString *) generateDescription:(OAQuickSearchListItem *)item
{
    NSMutableString *res = [NSMutableString new];
    NSString *typeName = [OAQuickSearchListItem getTypeName:item.getSearchResult];
    OADistanceDirection *distDir = [item getEvaluatedDistanceDirection:NO];
    BOOL needsSeparator = NO;
    
    if (distDir && distDir.distance.length > 0)
    {
        [res appendString:distDir.distance];
        needsSeparator = YES;
    }
    if (typeName.length > 0)
    {
        if (needsSeparator)
            [res appendString:@" • "];
        [res appendString:typeName];
    }
    return res;
}

- (void)runSearch:(void (^)(NSArray <CPListItem *> *searchResults))completionHandler
{
    OASearchSettings *settings = [_searchUICore getSearchSettings];
    if ([settings getRadiusLevel] != 1)
        [_searchUICore updateSettings:[settings setRadiusLevel:1]];

    _cancelPrev = YES;
    _searching = YES;

    OASearchResultCollection __block *regionResultCollection;
    OASearchCoreAPI __block *regionResultApi;
    NSMutableArray<OASearchResult *> __block *results = [NSMutableArray array];
    __weak __typeof(self) weakSelf = self;
    [_searchUICore search:_currentSearchPhrase
         delayedExecution:YES
                  matcher:[[OAResultMatcher<OASearchResult *> alloc] initWithPublishFunc:^BOOL(OASearchResult *__autoreleasing *object)
    {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf)
            return NO;

        OASearchResult *obj = *object;
        if (obj.objectType == SEARCH_STARTED)
            _cancelPrev = NO;

        if (_cancelPrev)
        {
            if (results.count > 0)
                [[_searchHelper getResultCollection] addSearchResults:results resortAll:YES removeDuplicates:YES];
            return NO;
        }

        switch (obj.objectType)
        {
            case FILTER_FINISHED:
            {
                [strongSelf updateSearchResult:[_searchUICore getCurrentSearchResult] completionHandler:completionHandler];
                break;
            }
            case SEARCH_FINISHED:
            {
                _searching = NO;
                [strongSelf updateSearchResult:[_searchHelper getResultCollection] completionHandler:completionHandler];
                break;
            }
            case SEARCH_API_FINISHED:
            {
                OASearchCoreAPI *searchApi = (OASearchCoreAPI *) obj.object;
                OASearchPhrase *phrase = obj.requiredSearchPhrase;
                OASearchCoreAPI *regionApi = regionResultApi;
                OASearchResultCollection *regionCollection = regionResultCollection;
                BOOL hasRegionCollection = (searchApi == regionApi && regionCollection);
                NSArray<OASearchResult *> *apiResults = hasRegionCollection ? [regionCollection getCurrentSearchResults] : results;

                regionResultApi = nil;
                regionResultCollection = nil;
                results = [NSMutableArray array];
                if (!_cancelPrev)
                {
                    BOOL append = [_searchHelper getResultCollection] != nil;
                    if (append)
                    {
                        [[_searchHelper getResultCollection] addSearchResults:apiResults resortAll:YES removeDuplicates:YES];
                    }
                    else
                    {
                        OASearchResultCollection *resCollection = [[OASearchResultCollection alloc] initWithPhrase:phrase];
                        [resCollection addSearchResults:apiResults resortAll:YES removeDuplicates:YES];
                        [_searchHelper setResultCollection:resCollection];
                    }
                    if (!hasRegionCollection)
                        [strongSelf updateSearchResult:[_searchHelper getResultCollection] completionHandler:completionHandler];
                }
                break;
            }
            case SEARCH_API_REGION_FINISHED:
            {
                regionResultApi = (OASearchCoreAPI *) obj.object;
                OASearchPhrase *regionPhrase = obj.requiredSearchPhrase;
                regionResultCollection = [[[OASearchResultCollection alloc] initWithPhrase:regionPhrase] addSearchResults:results
                                                                                                                resortAll:YES
                                                                                                         removeDuplicates:YES];
                if (!_cancelPrev)
                {
                    if ([_searchHelper getResultCollection])
                    {
                        OASearchResultCollection *resCollection = [[_searchHelper getResultCollection] combineWithCollection:regionResultCollection
                                                                                                                      resort:YES
                                                                                                            removeDuplicates:YES];
                        [strongSelf updateSearchResult:resCollection completionHandler:completionHandler];
                    }
                    else
                    {
                        [strongSelf updateSearchResult:regionResultCollection completionHandler:completionHandler];
                    }
                }
                break;
            }
            case SEARCH_STARTED:
            case PARTIAL_LOCATION:
            case POI_TYPE:
            {
                // do not show
                break;
            }
            default:
            {
                [results addObject:obj];
            }
        }
        return YES;
    } cancelledFunc:^BOOL {
        return _cancelPrev;
    }]];

    [_searchHelper setResultCollection:nil];
}

// MARK: CPSearchTemplateDelegate

- (void)searchTemplate:(CPSearchTemplate *)searchTemplate
        selectedResult:(CPListItem *)item
     completionHandler:(void (^)(void))completionHandler
{
    if (item != _searchingItem && item != _emptyItem)
        [self onItemSelected:item];
    completionHandler();
}

- (void)searchTemplate:(CPSearchTemplate *)searchTemplate
     updatedSearchText:(NSString *)searchText
     completionHandler:(void (^)(NSArray<CPListItem *> *searchResults))completionHandler
{
    if ([_currentSearchPhrase localizedCaseInsensitiveCompare:searchText] != NSOrderedSame)
    {
        _currentSearchPhrase = searchText;
        if (_currentSearchPhrase.length == 0)
        {
            [_searchUICore resetPhrase];
            [_searchUICore cancelSearch:NO];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateSearchResult:nil completionHandler:completionHandler];
            });
        }
        else
        {
            [self runSearch:completionHandler];
        }
    }
}

- (void)searchTemplateSearchButtonPressed:(CPSearchTemplate *)searchTemplate
{
    [_resultsListTemplate updateSections:@[[[CPListSection alloc] initWithItems:_cpItems]]];
    [self.interfaceController pushTemplate:_resultsListTemplate animated:YES completion:nil];
}

@end
