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
#import "OALocationServices.h"
#import "OAQuickSearchListItem.h"
#import "OsmAndApp.h"
#import "OAAddress.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAResultMatcher.h"
#import "OASearchResult.h"
#import "OAStreet.h"
#import "OASearchPhrase.h"
#import "OASearchWord.h"
#import <CarPlay/CarPlay.h>
#import "OAResourcesUIHelper.h"
#import "OAObservableProtocol.h"
#import "OADownloadTask.h"
#import "OADownloadsManager.h"
#import "OAAutoObserverProxy.h"
#import "OAObservable.h"

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
    OAAutoObserverProxy *_downloadTaskProgressObserver;
    OAAutoObserverProxy* _downloadTaskCompletedObserver;
    NSMutableDictionary<NSString *, CPListItem *> *_activeMapDownloads;
    OsmAndAppInstance _app;
    NSNumberFormatter *_percentFormatter;
}

- (NSNumberFormatter *)percentFormatter
{
    if (!_percentFormatter)
    {
        _percentFormatter = [[NSNumberFormatter alloc] init];
        _percentFormatter.numberStyle = NSNumberFormatterPercentStyle;
        _percentFormatter.maximumFractionDigits = 0;
        _percentFormatter.multiplier = @100; // 0.45 → "45%"
    }
    return _percentFormatter;
}

- (void)onStreetSelected:(OASearchResult *)street completionHandler:(void (^)(NSArray<CPListItem *> *searchResults))completionHandler {
    [_searchUICore selectSearchResult:street];
    _currentSearchPhrase =  [[_searchUICore getPhrase] getText:YES];
    _cpItems = @[];
    [_resultsListTemplate updateSections:@[[[CPListSection alloc] initWithItems:_cpItems]]];
    [self runSearch:completionHandler];
}

- (void) commonInit
{
    _searchingItem = [[CPListItem alloc] initWithText:OALocalizedString(@"searching") detailText:nil];
    _emptyItem = [[CPListItem alloc] initWithText:OALocalizedString(@"nothing_found") detailText:nil];
    _searchItems = @[];
    _cpItems = @[];
    _app = [OsmAndApp instance];

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
    
    _activeMapDownloads = [NSMutableDictionary dictionary];
    [self registerObservers];
}

- (void)registerObservers
{
    _downloadTaskProgressObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                              withHandler:@selector(onDownloadTaskProgressChanged:withKey:andValue:)
                                                               andObserve:_app.downloadsManager.progressCompletedObservable];
    _downloadTaskCompletedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onDownloadTaskFinished:withKey:andValue:)
                                                                andObserve:_app.downloadsManager.completedObservable];
}

- (void)present
{
    _searchTemplate = [[CPSearchTemplate alloc] init];
    _searchTemplate.delegate = self;
    [self.interfaceController pushTemplate:_searchTemplate animated:YES completion:nil];
}

- (void)onItemSelected:(CPListItem * _Nonnull)item completionHandler:(void (^)(NSArray<CPListItem *> *searchResults))completionHandler
{

    NSNumber *indexNum = item.userInfo[@"index"];
    
    if (!indexNum || _searchItems.count == 0 || indexNum.integerValue >= _searchItems.count)
        return;
    
    NSInteger index = indexNum.integerValue;
    OAQuickSearchListItem *searchItem = _searchItems[index];
    if (searchItem.getSearchResult.objectType == EOAObjectTypeStreet && completionHandler)
    {
        [self onStreetSelected:searchItem.getSearchResult completionHandler:completionHandler];
    }
    else if (searchItem.getSearchResult.objectType == EOAObjectTypeIndexItem && completionHandler)
    {
        OARepositoryResourceItem *resourceItem = (OARepositoryResourceItem *)searchItem.getSearchResult.relatedObject;
        if (resourceItem)
        {
            NSString *resourceId = resourceItem.resourceId.toNSString();
            
            if (_app.downloadsManager.hasActiveDownloadTasks)
            {
                id<OADownloadTask> task = [_app.downloadsManager firstDownloadTasksWithKey:[@"resource:" stringByAppendingString:resourceId]];
                if (task) {
                    [task cancel];
                    if (_activeMapDownloads[resourceId])
                        _activeMapDownloads[resourceId] = nil;
                    item.playbackProgress = 0;
                    OAQuickSearchListItem *searchListItem = item.userInfo[@"searchListItem"];
                    if (searchListItem)
                    {
                        [item setDetailText:[self generateDescription:searchListItem]];
                    }
                    
                    [item setAccessoryImage:[UIImage imageNamed:@"ic_custom_download"]];
                    return;
                }
            }
            
            __weak __typeof(self) weakSelf = self;
            [OAResourcesUIHelper offerDownloadAndInstallOf:resourceItem onTaskCreated:^(id<OADownloadTask> task) {
                __strong __typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf)
                    return;
                if (![task.key hasPrefix:@"resource:"])
                    return;
                NSString *dicKey = [task.key stringByReplacingOccurrencesOfString:@"resource:" withString:@""];
                if (!strongSelf->_activeMapDownloads[dicKey])
                {
                    strongSelf->_activeMapDownloads[dicKey] = item;
                    [item setAccessoryImage:nil];
                }
            } onTaskResumed:nil];
        }
    }
    else
    {
        CLLocation *loc = searchItem.getSearchResult.location;
        [self startNavigationGivenLocation:loc historyName:nil];
        [self.interfaceController popToRootTemplateAnimated:YES completion:nil];
    }
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
        OASearchWord* lastWord = res.phrase.getLastSelectedWord;
        NSInteger inc = 1;
        if (lastWord.getType == EOAObjectTypeStreet)
        {
            inc = searchResultItems.count / maximumItemCount;
        }
        __weak __typeof(self) weakSelf = self;
        for (NSInteger i = 0; i < searchResultItems.count; i+= inc)
        {
            if (cpItems.count >= maximumItemCount)
                break;

            OASearchResult *sr = searchResultItems[i];
            NSString *imageName = [OAQuickSearchListItem getIconName:sr] ?: @"";
            UIImage *image = [UIImage mapSvgImageNamed:imageName] ?: [UIImage imageNamed:imageName];
            OAQuickSearchListItem *qsItem = [[OAQuickSearchListItem alloc] initWithSearchResult:sr];
            CPListItem *cpItem = [[CPListItem alloc] initWithText:qsItem.getName
                                                       detailText:[self generateDescription:qsItem]
                                                            image:image
                                                   accessoryImage:[self getAccessoryImageFor:sr.objectType] accessoryType:CPListItemAccessoryTypeDisclosureIndicator];
            cpItem.userInfo = @{
                @"index": @(i),
                @"searchListItem": qsItem
            };
            cpItem.handler = ^(id <CPSelectableListItem> item, dispatch_block_t completionBlock) {
                [weakSelf onItemSelected:item completionHandler:completionHandler];
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

- (nullable UIImage *)getAccessoryImageFor:(EOAObjectType)objectType
{
    switch (objectType)
    {
        case EOAObjectTypeIndexItem:
            return [UIImage imageNamed:@"ic_custom_download"];
        default: break;
    }
    return nil;
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
        if (obj.objectType == EOAObjectTypeSearchStarted)
            _cancelPrev = NO;

        if (_cancelPrev)
        {
            if (results.count > 0)
                [[_searchHelper getResultCollection] addSearchResults:results resortAll:YES removeDuplicates:YES];
            return NO;
        }

        switch (obj.objectType)
        {
            case EOAObjectTypeFilterFinished:
            {
                [strongSelf updateSearchResult:[_searchUICore getCurrentSearchResult] completionHandler:completionHandler];
                break;
            }
            case EOAObjectTypeSearchFinished:
            {
                _searching = NO;
                [strongSelf updateSearchResult:[_searchHelper getResultCollection] completionHandler:completionHandler];
                break;
            }
            case EOAObjectTypeSearchApiFinished:
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
            case EOAObjectTypeSearchApiRegionFinished:
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
            case EOAObjectTypeSearchStarted:
            case EOAObjectTypePartialLocation:
            case EOAObjectTypePoiType:
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
        [self onItemSelected:item completionHandler:nil];
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


- (void)onDownloadTaskProgressChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;
    
    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"] || task.state != OADownloadTaskStateRunning)
        return;
    
    if (!task.silentInstall)
        task.silentInstall = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CPListItem *item = _activeMapDownloads[[task.key stringByReplacingOccurrencesOfString:@"resource:" withString:@""]];
        if (task)
        {
            NSArray<NSString *> *components = [item.detailText componentsSeparatedByString:@"•"];
            if (components.count >= 2)
            {
                NSMutableArray<NSString *> *trimmedComponents = [NSMutableArray array];
                
                NSString *replacement = [self.percentFormatter stringFromNumber:@([value floatValue])];
                [trimmedComponents addObject:[replacement stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                
                for (NSUInteger i = 1; i < components.count; i++)
                {
                    NSString *part = [components[i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    [trimmedComponents addObject:part];
                }

                NSString *result = [trimmedComponents componentsJoinedByString:@" • "];
                [item setDetailText:result];
            }
            item.playbackProgress = [value floatValue];
        }
    });
}

- (void)onDownloadTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;
    
    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;
    
    NSString *dicKey = [task.key stringByReplacingOccurrencesOfString:@"resource:" withString:@""];
    CPListItem *item = _activeMapDownloads[dicKey];
    if (item)
    {
        _activeMapDownloads[dicKey] = nil;
        if ([_cpItems containsObject:item])
        {
            // remove from search list 
            NSMutableArray<CPListItem *> *mutableItems = [_cpItems mutableCopy];
            [mutableItems removeObject:item];
            _cpItems = [mutableItems copy];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [_resultsListTemplate updateSections:@[[[CPListSection alloc] initWithItems:_cpItems]]];
            });
        }
    }
    if (task.progressCompleted < 1.0)
    {
        if ([_app.downloadsManager.keysOfDownloadTasks count] > 0)
        {
            id<OADownloadTask> nextTask = [_app.downloadsManager firstDownloadTasksWithKey:[_app.downloadsManager.keysOfDownloadTasks firstObject]];
            [item setAccessoryImage:nil];
            [nextTask resume];
        }
    }
}

- (void)dealloc
{
    if (_downloadTaskProgressObserver)
    {
        [_downloadTaskProgressObserver detach];
        _downloadTaskProgressObserver = nil;
    }
    if (_downloadTaskCompletedObserver)
    {
        [_downloadTaskCompletedObserver detach];
        _downloadTaskCompletedObserver = nil;
    }
}

@end
