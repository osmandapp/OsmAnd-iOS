//
//  OACarPlayCategoryResultListController.m
//  OsmAnd Maps
//
//  Created by Paul on 18.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACarPlayCategoryResultListController.h"
#import "OASearchUICore.h"
#import "OASearchResult.h"
#import "OASearchPhrase.h"
#import "OAQuickSearchHelper.h"
#import "OAPOIUIFilter.h"
#import "OAPOIFiltersHelper.h"
#import "OASearchSettings.h"
#import "OAQuickSearchListItem.h"
#import "OAPOIType.h"
#import "OAAddress.h"
#import "OAPOI.h"
#import "Localization.h"
#import "OADistanceDirection.h"
#import "OsmAndApp.h"
#import "OALocationServices.h"
#import "OAAppSettings.h"

#import <CarPlay/CarPlay.h>

@implementation OACarPlayCategoryResultListController
{
    OASearchResult *_searchResult;
    OASearchUICore *_searchUICore;
    OAQuickSearchHelper *_searchHelper;
}

- (instancetype) initWithInterfaceController:(CPInterfaceController *)interfaceController searchResult:(OASearchResult *)sr
{
    self = [super initWithInterfaceController:interfaceController];
    if (self) {
        _searchResult = sr;
    }
    return self;
}

- (void) commonInit
{
    _searchHelper = OAQuickSearchHelper.instance;
    _searchUICore = _searchHelper.getCore;
    
    NSString *locale = [OAAppSettings sharedManager].settingPrefMapLanguage;
    BOOL transliterate = [OAAppSettings sharedManager].settingMapLanguageTranslit;
    OASearchSettings *settings = [[_searchUICore getSearchSettings] setOriginalLocation:OsmAndApp.instance.locationServices.lastKnownLocation];
    settings = [settings setLang:locale ? locale : @"" transliterateIfMissing:transliterate];
    [_searchUICore updateSettings:settings];
}

- (NSString *)screenTitle
{
    return _searchResult.localeName;
}

- (void) present
{
    [super present];
    [self searchAndDisplayResult];
}

- (NSArray<CPListSection *> *) generateSections
{
    return [self generateSingleItemSectionWithTitle:OALocalizedString(@"search_preogress")];
}

- (void) searchAndDisplayResult
{
    [_searchUICore resetPhrase];
    [_searchUICore cancelSearch];
    
    if ([_searchResult.object isKindOfClass:[OAPOIType class]] && [((OAPOIType *) _searchResult.object) isAdditional])
    {
        OAPOIType *additional = (OAPOIType *) _searchResult.object;
        OAPOIBaseType *parent = additional.parentType;
        if (parent)
        {
            OAPOIUIFilter *custom = [[OAPOIFiltersHelper sharedInstance] getFilterById:[NSString stringWithFormat:@"%@%@", STD_PREFIX, parent.name]];
            if (custom)
            {
                [custom clearFilter];
                [custom updateTypesToAccept:parent];
                [custom setFilterByName:[[additional.name stringByReplacingOccurrencesOfString:@"_" withString:@":"] lowerCase]];
                
                OASearchPhrase *phrase = [_searchUICore getPhrase];
                _searchResult = [[OASearchResult alloc] initWithPhrase:phrase];
                _searchResult.localeName = custom.name;
                _searchResult.object = custom;
                _searchResult.priority = SEARCH_AMENITY_TYPE_PRIORITY;
                _searchResult.priorityDistance = 0;
                _searchResult.objectType = POI_TYPE;
            }
        }
    }
    [_searchUICore selectSearchResult:_searchResult];
    NSString *txt = [[_searchUICore getPhrase] getText:YES];
    OASearchSettings *settings = [_searchUICore getSearchSettings];
    if ([settings getRadiusLevel] != 1)
        [_searchUICore updateSettings:[settings setRadiusLevel:1]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OASearchResultCollection *result = [_searchUICore shallowSearch:OASearchAmenityByTypeAPI.class text:txt matcher:nil resortAll:YES removeDuplicates:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateSearchResult:result];
        });
    });
}

- (void) updateSearchResult:(OASearchResultCollection *)res
{
    NSMutableArray<OAQuickSearchListItem *> *rows = [NSMutableArray array];
    if (res && [res getCurrentSearchResults].count > 0)
        for (OASearchResult *sr in [res getCurrentSearchResults])
            [rows addObject:[[OAQuickSearchListItem alloc] initWithSearchResult:sr]];
    
    [self updateData:rows];
}

- (void) updateData:(NSArray<OAQuickSearchListItem *> *)data
{
    [self updateSections:[self generateSections:data]];
}

- (NSArray<CPListSection *> *) generateSections:(NSArray<OAQuickSearchListItem *> *)data
{
    NSMutableArray<CPListItem *> *items = [NSMutableArray new];
    
    if (data.count > 0)
    {
        // Since the number of items is limited by the system, no need to do extra computations
        NSInteger maximumItemsCount = MIN(500, data.count);
        if (@available(iOS 14.0, *))
            maximumItemsCount = MIN(CPListTemplate.maximumItemCount, data.count);
        
        for (NSInteger i = 0; i < maximumItemsCount; i++)
        {
            OAQuickSearchListItem *item = data[i];
            [items addObject:[self createListItem:item]];
        }
        return @[[[CPListSection alloc] initWithItems:items header:nil sectionIndexTitle:nil]];
    }
    return [self generateSingleItemSectionWithTitle:OALocalizedString(@"nothing_found_empty")];
}

- (CPListItem *) createListItem:(OAQuickSearchListItem *)item
{
    OASearchResult *res = [item getSearchResult];
    
    if (res)
    {
        switch (res.objectType)
        {
            case POI:
            {
                OAPOI *poi = (OAPOI *)res.object;
                CPListItem *listItem = [[CPListItem alloc] initWithText:item.getName detailText:[self generatePoiDescription:poi searchItem:item] image:poi.icon];
                listItem.userInfo = item;
                return listItem;
            }
            default:
            {
                return nil;
            }
        }
    }
    return nil;
}

- (NSString *) generatePoiDescription:(OAPOI *)poi searchItem:(OAQuickSearchListItem *)item
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
        needsSeparator = YES;
    }
    if (poi.hasOpeningHours)
    {
        if (needsSeparator)
            [res appendString:@" • "];
        [res appendString:poi.openingHours];
    }
    
    return res;
}

// MARK: - CPListTemplateDelegate

- (void)listTemplate:(CPListTemplate *)listTemplate didSelectListItem:(CPListItem *)item completionHandler:(void (^)())completionHandler
{
    OAQuickSearchListItem *searchItem = item.userInfo;
    if (!searchItem)
    {
        completionHandler();
        return;
    }
    CLLocation *loc = searchItem.getSearchResult.location;
    [self startNavigationGivenLocation:loc];
    [self.interfaceController popToRootTemplateAnimated:YES];
    
    completionHandler();
}

@end
