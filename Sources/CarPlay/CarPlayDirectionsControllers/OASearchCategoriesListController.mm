//
//  OASearchCategoriesListController.m
//  OsmAnd Maps
//
//  Created by Paul on 18.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OASearchCategoriesListController.h"
#import "OAQuickSearchHelper.h"
#import "OAQuickSearchListItem.h"
#import "OASearchUICore.h"
#import "OACustomSearchPoiFilter.h"
#import "OAPOIBaseType.h"
#import "OAPOICategory.h"
#import "OAQuickSearchTableController.h"
#import "OACarPlayCategoryResultListController.h"
#import "Localization.h"

#import <CarPlay/CarPlay.h>

@interface OASearchCategoriesListController() <CPListTemplateDelegate>

@end

@implementation OASearchCategoriesListController
{
	CPListTemplate *_listTemplate;
	
	OAQuickSearchHelper *_quickSearchHelper;
	
	NSArray<OAQuickSearchListItem *> *_searchItems;
}

- (void) commonInit
{
	_quickSearchHelper = OAQuickSearchHelper.instance;
}

- (void) present
{
	_listTemplate = [[CPListTemplate alloc] initWithTitle:OALocalizedString(@"poi_categories") sections:[self generateSections]];
	_listTemplate.delegate = self;
	[self.interfaceController pushTemplate:_listTemplate animated:YES];
}

- (NSArray<CPListSection *> *) generateSections
{
	OASearchResultCollection *res = [[_quickSearchHelper getCore] shallowSearch:[OASearchAmenityTypesAPI class] text:@"" matcher:nil];
	NSMutableArray<OAQuickSearchListItem *> *rows = [NSMutableArray array];
	NSMutableArray<CPListItem *> *items = [NSMutableArray new];
	if (res)
	{
		for (NSInteger i = 0; i < res.getCurrentSearchResults.count; i++)
		{
			OASearchResult *sr = res.getCurrentSearchResults[i];
			OAQuickSearchListItem *item = [[OAQuickSearchListItem alloc] initWithSearchResult:sr];
			[rows addObject:item];
			CPListItem *listItem = [self createListItem:item index:i];
			if (@available(iOS 14.0, *)) {
				[listItem setHandler:^(id <CPSelectableListItem> item,
									  dispatch_block_t completionBlock) {
					[self listTemplate:_listTemplate didSelectListItem:item completionHandler:completionBlock];
				}];
			}
			[items addObject:listItem];
		}
	}
	_searchItems = rows;
	CPListSection *section = [[CPListSection alloc] initWithItems:items header:nil sectionIndexTitle:nil];
	return @[section];
}

- (CPListItem *) createListItem:(OAQuickSearchListItem *)item index:(NSInteger)index
{
	OASearchResult *res = item.getSearchResult;
	CPListItem *listItem = nil;
	if ([res.object isKindOfClass:[OACustomSearchPoiFilter class]])
	{
		OACustomSearchPoiFilter *filter = (OACustomSearchPoiFilter *) res.object;
		NSString *name = [item getName];
		UIImage *icon;
		NSObject *res = [filter getIconResource];
		if ([res isKindOfClass:[NSString class]])
		{
			NSString *iconName = (NSString *)res;
			icon = [OAUtilities getMxIcon:iconName];
		}
		if (!icon)
			icon = [OAUtilities getMxIcon:@"user_defined"];
		
		listItem = [[CPListItem alloc] initWithText:name detailText:nil image:icon showsDisclosureIndicator:YES];
	}
	else if ([res.object isKindOfClass:[OAPOIBaseType class]])
	{
		NSString *name = [item getName];
		NSString *typeName = [OAQuickSearchTableController applySynonyms:res];
		UIImage *icon = [((OAPOIBaseType *)res.object) icon];
		
		listItem = [[CPListItem alloc] initWithText:name detailText:typeName image:icon showsDisclosureIndicator:YES];
	}
	else if ([res.object isKindOfClass:[OAPOICategory class]])
	{
		listItem = [[CPListItem alloc] initWithText:item.getName detailText:nil image:((OAPOICategory *)res.object).icon showsDisclosureIndicator:YES];
	}
	
	if (listItem)
		listItem.userInfo = @(index);
	
	return listItem;
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
	OACarPlayCategoryResultListController *results = [[OACarPlayCategoryResultListController alloc] initWithInterfaceController:self.interfaceController searchResult:searchItem.getSearchResult];
	[results present];
	
	completionHandler();
}

@end
