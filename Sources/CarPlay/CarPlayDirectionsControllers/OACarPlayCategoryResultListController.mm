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

@interface OACarPlayCategoryResultListController() <CPListTemplateDelegate>

@end

@implementation OACarPlayCategoryResultListController
{
	OASearchResult *_searchResult;
	OASearchUICore *_searchUICore;
	OAQuickSearchHelper *_searchHelper;
	
	CPListTemplate *_listTemplate;
	NSArray<OAQuickSearchListItem *> *_searchItems;
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

- (void) present
{
	_listTemplate = [[CPListTemplate alloc] initWithTitle:_searchResult.localeName sections:[self generateSingleItemSectionWithTitle:OALocalizedString(@"search_preogress")]];
	_listTemplate.delegate = self;
	
	[self.interfaceController pushTemplate:_listTemplate animated:YES];
	[self searchAndDisplayResult];
}

- (NSArray<CPListSection *> *) generateSingleItemSectionWithTitle:(NSString *)title
{
	CPListItem *item = [[CPListItem alloc] initWithText:title detailText:nil];
	CPListSection *section = [[CPListSection alloc] initWithItems:@[item]];
	return @[section];
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
	
	OASearchResultCollection *result = [_searchUICore shallowSearch:OASearchAmenityByTypeAPI.class text:txt matcher:nil resortAll:YES removeDuplicates:YES];
	
	[self updateSearchResult:result];
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
	_searchItems = data;
	[_listTemplate updateSections:[self generateSections]];
}

- (NSArray<CPListSection *> *) generateSections
{
	NSMutableArray<CPListItem *> *items = [NSMutableArray new];
	// Since the number of items is limited by the system, no need to do extra computations
	NSInteger maximumItemsCount = MIN(500, _searchItems.count);
	if (@available(iOS 14.0, *))
		maximumItemsCount = MIN(CPListTemplate.maximumItemCount, _searchItems.count);
	
	
	for (NSInteger i = 0; i < maximumItemsCount; i++)
	{
		OAQuickSearchListItem *item = _searchItems[i];
		CPListItem *listItem = [self createListItem:item];
		if (@available(iOS 14.0, *)) {
			[listItem setHandler:^(id <CPSelectableListItem> item,
								   dispatch_block_t completionBlock) {
				[self listTemplate:_listTemplate didSelectListItem:item completionHandler:completionBlock];
			}];
			listItem.userInfo = @(i);
		}
		[items addObject:listItem];
	}
	
	if (_searchItems.count > 0)
		return @[[[CPListSection alloc] initWithItems:items header:nil sectionIndexTitle:nil]];
	else
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
	
	if (distDir && distDir.distance.length > 0)
	{
		[res appendString:distDir.distance];
	}
	if (typeName.length > 0)
	{
		[res appendString:@" • "];
		[res appendString:typeName];
	}
	if (poi.hasOpeningHours)
	{
		[res appendString:@" • "];
		[res appendString:poi.openingHours];
	}
	
	return res;
}

// MARK: - CPListTemplateDelegate

- (void)listTemplate:(CPListTemplate *)listTemplate didSelectListItem:(CPListItem *)item completionHandler:(void (^)())completionHandler
{
	NSNumber *indexNum = item.userInfo;
	if (!indexNum)
	{
		completionHandler();
		return;
	}
	NSInteger index = indexNum.integerValue;
	OAQuickSearchListItem *searchItem = _searchItems[index];
	CLLocation *loc = searchItem.getSearchResult.location;
	[self startNavigationGivenLocation:loc];
	[self.interfaceController popToRootTemplateAnimated:YES];
		
	completionHandler();
}

@end
