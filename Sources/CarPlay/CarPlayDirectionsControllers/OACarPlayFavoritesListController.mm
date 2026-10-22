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
#import "OAPointDescription.h"
#import "OAOsmAndFormatter.h"
#import "OALocationServices.h"
#import "OsmAndApp.h"
#import "OAColors.h"
#import "Localization.h"
#import <CarPlay/CarPlay.h>
#import "GeneratedAssetSymbols.h"

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
    NSArray<OAFavoriteGroup *> *favoriteGroups = [OAFavoritesHelper favoriteGroups];
    if (favoriteGroups.count > 0)
    {
        NSMutableArray<CPListItem *> *listItems = [NSMutableArray new];
        NSMutableArray<OAFavoriteItem *> *lastModifiedList = [NSMutableArray new];
        [favoriteGroups enumerateObjectsUsingBlock:^(OAFavoriteGroup * _Nonnull group, NSUInteger idx, BOOL * _Nonnull stop) {
            // Copy: sorting or trimming group.points itself would drop favorites on the next save
            NSMutableArray<OAFavoriteItem *> *points = [group.points mutableCopy];
            [self sortFavoriteItems:points];
            if (points.count > CPListTemplate.maximumItemCount)
                [points removeObjectsInRange:NSMakeRange(CPListTemplate.maximumItemCount, points.count - CPListTemplate.maximumItemCount)];

            CPListItem *listItem = [[CPListItem alloc] initWithText:[OAFavoriteGroup getDisplayName:group.name]
                                                         detailText:[NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_space"),
                                                                                               OALocalizedString(@"points_count"),
                                                                                               @(points.count).stringValue]
                                                              image:[OAUtilities tintImageWithColor:[UIImage imageNamed:ACImageNameIcCustomFolder]
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
        CPListItem *homeItem = [self createHomeItem];
        NSInteger maximumItemCount = CPListTemplate.maximumItemCount;
        NSInteger maximumFolderCount = maximumItemCount - 1 - (homeItem ? 1 : 0);
        if (listItems.count > maximumFolderCount)
            [listItems removeObjectsInRange:NSMakeRange(maximumFolderCount, listItems.count - maximumFolderCount)];

        [self sortFavoriteItems:lastModifiedList];
        if (lastModifiedList.count > maximumItemCount)
            [lastModifiedList removeObjectsInRange:NSMakeRange(maximumItemCount, lastModifiedList.count - maximumItemCount)];
        CPListItem *lastModifiedItem = [[CPListItem alloc] initWithText:OALocalizedString(@"sort_last_modified")
                                                             detailText:@(lastModifiedList.count).stringValue
                                                                  image:[OAUtilities tintImageWithColor:[UIImage imageNamed:ACImageNameIcCustomHistory]
                                                                                                  color:UIColorFromRGB(color_primary_purple)]
                                                         accessoryImage:nil
                                                          accessoryType:CPListItemAccessoryTypeDisclosureIndicator];
        lastModifiedItem.userInfo = lastModifiedList;
        lastModifiedItem.handler = ^(id <CPSelectableListItem> item, dispatch_block_t completionBlock) {
            [self onItemSelected:item completionHandler:completionBlock];
        };
        [listItems insertObject:lastModifiedItem atIndex:0];
        if (homeItem)
            [listItems insertObject:homeItem atIndex:0];

        return @[[[CPListSection alloc] initWithItems:listItems header:nil sectionIndexTitle:nil]];
    }
    else
    {
        return [self generateSingleItemSectionWithTitle:OALocalizedString(@"favorites_empty")];
    }
}

- (nullable CPListItem *)createHomeItem
{
    OAFavoriteItem *home = [OAFavoritesHelper getSpecialPoint:OASpecialPointType.HOME];
    if (!home)
        return nil;

    NSString *distance = nil;
    CLLocation *location = OsmAndApp.instance.locationServices.lastKnownLocation;
    if (location)
    {
        CLLocation *homeLocation = [[CLLocation alloc] initWithLatitude:[home getLatitude] longitude:[home getLongitude]];
        distance = [OAOsmAndFormatter getFormattedDistance:[location distanceFromLocation:homeLocation]];
    }
    CPListItem *homeItem = [[CPListItem alloc] initWithText:[home getDisplayName]
                                                 detailText:distance
                                                      image:[home getCompositeIcon]
                                             accessoryImage:nil
                                              accessoryType:CPListItemAccessoryTypeNone];
    homeItem.handler = ^(id <CPSelectableListItem> item, dispatch_block_t completionBlock) {
        OAPointDescription *historyName = [[OAPointDescription alloc] initWithType:POINT_TYPE_FAVORITE name:[home getName]];
        [self startNavigationGivenLocation:[[CLLocation alloc] initWithLatitude:[home getLatitude] longitude:[home getLongitude]] historyName:historyName];
        [self safePopToRootTemplateAnimated:YES];
        if (completionBlock)
            completionBlock();
    };
    return homeItem;
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
