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


#import <CarPlay/CarPlay.h>

@interface OACarPlayAddressSearchController() <CPSearchTemplateDelegate, CPListTemplateDelegate>

@end

@implementation OACarPlayAddressSearchController
{
    OASearchUICore *_searchUICore;
    OAQuickSearchHelper *_searchHelper;
    
    CPSearchTemplate *_searchTemplate;
    
    NSArray<OAQuickSearchListItem *> *_searchItems;
    
    NSString *_currentSearchPhrase;
    
    dispatch_queue_t _searchQueue;
}

- (void) commonInit
{
    _searchQueue = dispatch_queue_create("carPlay_searchQueue", DISPATCH_QUEUE_SERIAL);
    _searchHelper = OAQuickSearchHelper.instance;
    _searchUICore = _searchHelper.getCore;
    
    NSString *locale = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
    BOOL transliterate = [OAAppSettings sharedManager].settingMapLanguageTranslit.get;
    OASearchSettings *settings = [[_searchUICore getSearchSettings] setOriginalLocation:OsmAndApp.instance.locationServices.lastKnownLocation];
    settings = [settings setLang:locale ? locale : @"" transliterateIfMissing:transliterate];
    [_searchUICore updateSettings:settings];
    
    [_searchUICore cancelSearch];
    [_searchUICore resetPhrase];
}

- (void)present
{
    _searchTemplate = [[CPSearchTemplate alloc] init];
    _searchTemplate.delegate = self;
    [self.interfaceController pushTemplate:_searchTemplate animated:YES];
}

- (void)onItemSelected:(CPListItem * _Nonnull)item
{
    NSNumber *indexNum = item.userInfo;
    if (!indexNum || _searchItems.count == 0 || indexNum.integerValue >= _searchItems.count)
        return;
    
    NSInteger index = indexNum.integerValue;
    OAQuickSearchListItem *searchItem = _searchItems[index];
    CLLocation *loc = searchItem.getSearchResult.location;
    [self startNavigationGivenLocation:loc];
    [self.interfaceController popToRootTemplateAnimated:YES];
}

- (void) updateSearchResult:(OASearchResultCollection *)res
{
    NSMutableArray<OAQuickSearchListItem *> *rows = [NSMutableArray array];
    if (res && [res getCurrentSearchResults].count > 0)
    {
        for (OASearchResult *sr in [res getCurrentSearchResults])
        {
            [rows addObject:[[OAQuickSearchListItem alloc] initWithSearchResult:sr]];
        }
    }
    _searchItems = rows;
}

- (NSArray<CPListItem *> *)generateItemList
{
    NSMutableArray<CPListItem *> *res = [NSMutableArray new];
    if (_searchItems.count > 0)
    {
        for (NSInteger i = 0; i < _searchItems.count; i++)
        {
            OAQuickSearchListItem *item = _searchItems[i];
            OAAddress *address = (OAAddress *)item.getSearchResult.object;
            CPListItem *listItem = [[CPListItem alloc] initWithText:item.getName detailText:[self generateDescription:item] image:address.icon];
            listItem.userInfo = @(i);
            [res addObject:listItem];
        }
    }
    else if (_currentSearchPhrase.length > 0)
    {
        return @[[[CPListItem alloc] initWithText:OALocalizedString(@"nothing_found_empty") detailText:nil]];
    }
    return res;
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

// MARK: CPSearchTemplateDelegate

- (void)searchTemplate:(CPSearchTemplate *)searchTemplate selectedResult:(CPListItem *)item completionHandler:(void (^)())completionHandler
{
    [self onItemSelected:item];
    completionHandler();
}

- (void)searchTemplate:(CPSearchTemplate *)searchTemplate updatedSearchText:(NSString *)searchText completionHandler:(void (^)(NSArray<CPListItem *> * _Nonnull))completionHandler
{
    if ([_currentSearchPhrase isEqualToString:searchText] && _searchItems.count > 0)
        return;
    
    _currentSearchPhrase = searchText;
    [_searchUICore cancelSearch];
    [_searchUICore resetPhrase];
    
    dispatch_async(_searchQueue, ^{
        OASearchResultCollection *results = [_searchUICore shallowSearch:OASearchAddressByNameAPI.class text:searchText matcher:nil resortAll:YES removeDuplicates:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateSearchResult:results];
            completionHandler([self generateItemList]);
        });
    });
}

- (void)searchTemplateSearchButtonPressed:(CPSearchTemplate *)searchTemplate
{
    CPListSection *section = [[CPListSection alloc] initWithItems:[self generateItemList]];
    CPListTemplate *resultsList = [[CPListTemplate alloc] initWithTitle:OALocalizedString(@"shared_string_search") sections:@[section]];
    resultsList.delegate = self;
    [self.interfaceController pushTemplate:resultsList animated:YES];
}

// MARK: CPListTemplateDelegate

- (void)listTemplate:(CPListTemplate *)listTemplate didSelectListItem:(CPListItem *)item completionHandler:(void (^)())completionHandler
{
    [self onItemSelected:item];
    
    completionHandler();
}

@end
