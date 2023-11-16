//
//  OACarPlayFavoritesListController.mm
//  OsmAnd Maps
//
//  Created by Paul on 12.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACarPlayFavoritesListController.h"
#import "OACarPlayFavoriteResultListController.h"
#import "OAFavoritesHelper.h"
#import "OAFavoriteItem.h"
#import "OsmAndApp.h"
#import "OAColors.h"
#import "Localization.h"
#import <CarPlay/CarPlay.h>

@implementation OACarPlayFavoritesListController
{
    OACarPlayFavoriteResultListController *_favoriteResultController;
}

- (NSString *)screenTitle
{
    return OALocalizedString(@"favorites_item");
}

- (NSArray<CPListSection *> *) generateSections
{
    NSArray<OAFavoriteGroup *> *favoriteGroups = [OAFavoritesHelper getFavoriteGroups];
    if (favoriteGroups.count > 0)
    {
        NSMutableArray<CPListItem *> *listItems = [NSMutableArray new];
        NSMutableArray<OAFavoriteItem *> *lastModifiedList = [NSMutableArray new];
        [favoriteGroups enumerateObjectsUsingBlock:^(OAFavoriteGroup * _Nonnull group, NSUInteger idx, BOOL * _Nonnull stop) {
            NSMutableArray<OAFavoriteItem *> *points = group.points;
            [self sortFavoriteItems:points];
            if (points.count > CPListTemplate.maximumItemCount)
                [points removeObjectsInRange:NSMakeRange(CPListTemplate.maximumItemCount, points.count - CPListTemplate.maximumItemCount)];

            CPListItem *listItem = [[CPListItem alloc] initWithText:[OAFavoriteGroup getDisplayName:group.name]
                                                         detailText:[NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_space"),
                                                                                               OALocalizedString(@"points_count"),
                                                                                               @(points.count).stringValue]
                                                              image:[OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_custom_folder"]
                                                                                              color:group.color]
                                                     accessoryImage:nil
                                                      accessoryType:CPListItemAccessoryTypeDisclosureIndicator];
            listItem.userInfo = points;
            listItem.handler = ^(id <CPSelectableListItem> item, dispatch_block_t completionBlock) {
                [self onItemSelected:item completionHandler:completionBlock];
            };
            [listItems addObject:listItem];
            [lastModifiedList addObjectsFromArray:group.points];
        }];
        [listItems sortUsingComparator:^NSComparisonResult(CPListItem *i1, CPListItem *i2) {
            return [i1.text compare:i2.text];
        }];
        NSInteger maximumItemCount = CPListTemplate.maximumItemCount;
        if (listItems.count > maximumItemCount - 1)
            [listItems removeObjectsInRange:NSMakeRange(maximumItemCount - 1, listItems.count - maximumItemCount - 1)];

        [self sortFavoriteItems:lastModifiedList];
        if (lastModifiedList.count > maximumItemCount)
            [lastModifiedList removeObjectsInRange:NSMakeRange(maximumItemCount, lastModifiedList.count - maximumItemCount)];
        CPListItem *lastModifiedItem = [[CPListItem alloc] initWithText:OALocalizedString(@"sort_last_modified")
                                                             detailText:@(lastModifiedList.count).stringValue
                                                                  image:[OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_custom_history"]
                                                                                                  color:UIColorFromRGB(color_primary_purple)]
                                                         accessoryImage:nil
                                                          accessoryType:CPListItemAccessoryTypeDisclosureIndicator];
        lastModifiedItem.userInfo = lastModifiedList;
        lastModifiedItem.handler = ^(id <CPSelectableListItem> item, dispatch_block_t completionBlock) {
            [self onItemSelected:item completionHandler:completionBlock];
        };
        [listItems insertObject:lastModifiedItem atIndex:0];

        return @[[[CPListSection alloc] initWithItems:listItems header:nil sectionIndexTitle:nil]];
    }
    else
    {
        return [self generateSingleItemSectionWithTitle:OALocalizedString(@"favorites_empty")];
    }
}

- (void)sortFavoriteItems:(NSMutableArray<OAFavoriteItem *> *)favoriteItems
{
    [favoriteItems sortUsingComparator:^NSComparisonResult(OAFavoriteItem *i1, OAFavoriteItem *i2) {
        NSDate *date1 = [i1 getTimestamp];
        NSDate *date2 = [i2 getTimestamp];
        if (!date1 || !date2)
            return NSOrderedDescending;
        NSTimeInterval lastTime1 = date1.timeIntervalSince1970;
        NSTimeInterval lastTime2 = date2.timeIntervalSince1970;
        return (lastTime1 < lastTime2) ? NSOrderedDescending : ((lastTime1 == lastTime2) ? NSOrderedSame : NSOrderedAscending);
    }];
}

- (void)onItemSelected:(CPListItem * _Nonnull)item completionHandler:(dispatch_block_t)completionBlock
{
    NSString *folderName = item.text;
    NSArray<OAFavoriteItem *> *favoriteList = item.userInfo;
    if (!favoriteList)
    {
        if (completionBlock)
            completionBlock();
        return;
    }
    _favoriteResultController = [[OACarPlayFavoriteResultListController alloc] initWithInterfaceController:self.interfaceController
                                                                                                folderName:folderName
                                                                                              favoriteList:favoriteList];
    [_favoriteResultController present];

    if (completionBlock)
        completionBlock();
}

@end
