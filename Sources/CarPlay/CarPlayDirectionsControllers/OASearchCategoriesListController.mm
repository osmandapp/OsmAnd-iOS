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

@implementation OASearchCategoriesListController
{
    OAQuickSearchHelper *_quickSearchHelper;
    
    OACarPlayCategoryResultListController *_categoryResultController;
}

- (void) commonInit
{
    _quickSearchHelper = OAQuickSearchHelper.instance;
}

- (NSString *) screenTitle
{
    return OALocalizedString(@"poi_categories");
}

- (NSArray<CPListSection *> *) generateSections
{
    OASearchResultCollection *res = [[_quickSearchHelper getCore] shallowSearch:[OASearchAmenityTypesAPI class] text:@"" matcher:nil];
    NSMutableArray<CPListItem *> *items = [NSMutableArray new];
    if (res)
    {
        NSInteger maximumItemCount = CPListTemplate.maximumItemCount;
        [res.getCurrentSearchResults enumerateObjectsUsingBlock:^(OASearchResult * _Nonnull sr, NSUInteger idx, BOOL * _Nonnull stop) {
            OAQuickSearchListItem *item = [[OAQuickSearchListItem alloc] initWithSearchResult:sr];
            CPListItem *listItem = [self createListItem:item];
            [items addObject:listItem];
            if (items.count >= maximumItemCount)
                *stop = YES;
        }];
    }
    CPListSection *section = [[CPListSection alloc] initWithItems:items header:nil sectionIndexTitle:nil];
    return @[section];
}

- (CPListItem *) createListItem:(OAQuickSearchListItem *)item
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
        
        listItem = [[CPListItem alloc] initWithText:name detailText:nil image:icon accessoryImage:nil accessoryType:CPListItemAccessoryTypeDisclosureIndicator];
    }
    else if ([res.object isKindOfClass:[OAPOIBaseType class]])
    {
        NSString *name = [item getName];
        NSString *typeName = [OAQuickSearchTableController applySynonyms:res];
        UIImage *icon = [((OAPOIBaseType *)res.object) icon];

        listItem = [[CPListItem alloc] initWithText:name detailText:typeName image:icon accessoryImage:nil accessoryType:CPListItemAccessoryTypeDisclosureIndicator];
    }
    else if ([res.object isKindOfClass:[OAPOICategory class]])
    {
        listItem = [[CPListItem alloc] initWithText:item.getName detailText:nil image:((OAPOICategory *)res.object).icon accessoryImage:nil accessoryType:CPListItemAccessoryTypeDisclosureIndicator];
    }
    
    if (listItem)
        listItem.userInfo = item;

    listItem.handler = ^(id <CPSelectableListItem> item, dispatch_block_t completionBlock) {
        [self onItemSelected:item completionHandler:completionBlock];
    };
    return listItem;
}

- (void)onItemSelected:(CPListItem * _Nonnull)item completionHandler:(dispatch_block_t)completionBlock
{
    OAQuickSearchListItem *searchItem = item.userInfo;
    if (!searchItem)
    {
        if (completionBlock)
            completionBlock();
        return;
    }
    _categoryResultController = [[OACarPlayCategoryResultListController alloc] initWithInterfaceController:self.interfaceController searchResult:searchItem.getSearchResult];
    [_categoryResultController present];

    if (completionBlock)
        completionBlock();
}

@end
