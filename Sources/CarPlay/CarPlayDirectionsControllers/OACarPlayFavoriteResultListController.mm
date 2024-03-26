//
//  OACarPlayFavoriteResultListController.mm
//  OsmAnd
//
//  Created by Skalii on 01.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OACarPlayFavoriteResultListController.h"
#import "OAOsmAndFormatter.h"
#import "OAFavoriteItem.h"
#import "OAPointDescription.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import <CarPlay/CarPlay.h>

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/IFavoriteLocation.h>

@implementation OACarPlayFavoriteResultListController
{
    NSString *_folderName;
    NSArray<OAFavoriteItem *> *_favoriteList;
}

- (instancetype)initWithInterfaceController:(CPInterfaceController *)interfaceController
                                 folderName:(NSString *)folderName
                               favoriteList:(NSArray<OAFavoriteItem *> *)favoriteList
{
    self = [super initWithInterfaceController:interfaceController];
    if (self)
    {
        _folderName = folderName;
        _favoriteList = favoriteList;
    }
    return self;
}

- (NSString *)screenTitle
{
    return _folderName;
}

- (NSArray<CPListSection *> *)generateSections
{
    if (_favoriteList.count > 0)
    {
        NSInteger maximumItemCount = CPListTemplate.maximumItemCount;

        NSMutableArray<CPListItem *> *listItems = [NSMutableArray new];
        for (OAFavoriteItem *favoriteItem in _favoriteList)
        {
            if (listItems.count >= maximumItemCount)
                break;

            CPListItem *listItem = [[CPListItem alloc] initWithText:favoriteItem.favorite->getTitle().toNSString()
                                                         detailText:[self calculateDistanceToItem:favoriteItem]
                                                              image:[favoriteItem getCompositeIcon]
                                                     accessoryImage:nil
                                                      accessoryType:CPListItemAccessoryTypeDisclosureIndicator];
            listItem.userInfo = favoriteItem;
            listItem.handler = ^(id <CPSelectableListItem> item, dispatch_block_t completionBlock) {
                [self onItemSelected:item completionHandler:completionBlock];
            };
            [listItems addObject:listItem];
        }
        return @[[[CPListSection alloc] initWithItems:listItems header:nil sectionIndexTitle:nil]];
    }
    else
    {
        return [self generateSingleItemSectionWithTitle:OALocalizedString(@"favorites_empty")];
    }
}

- (NSString *)calculateDistanceToItem:(OAFavoriteItem *)item
{
    OsmAndAppInstance app = OsmAndApp.instance;
    CLLocation *newLocation = app.locationServices.lastKnownLocation;
    if (!newLocation)
        return nil;

    const auto& favoritePosition31 = item.favorite->getPosition31();
    const auto favoriteLon = OsmAnd::Utilities::get31LongitudeX(favoritePosition31.x);
    const auto favoriteLat = OsmAnd::Utilities::get31LatitudeY(favoritePosition31.y);
    const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                      newLocation.coordinate.latitude,
                                                      favoriteLon, favoriteLat);
    return [OAOsmAndFormatter getFormattedDistance:distance];
}

- (void)onItemSelected:(CPListItem * _Nonnull)item completionHandler:(dispatch_block_t)completionBlock
{
    OAFavoriteItem *favoritePoint = item.userInfo;
    if (!favoritePoint)
    {
        if (completionBlock)
            completionBlock();
        return;
    }
    OAPointDescription *historyName = [[OAPointDescription alloc] initWithType:POINT_TYPE_FAVORITE name:[favoritePoint getName]];
    [self startNavigationGivenLocation:[[CLLocation alloc] initWithLatitude:favoritePoint.getLatitude longitude:favoritePoint.getLongitude] historyName:historyName];
    [self.interfaceController popToRootTemplateAnimated:YES completion:nil];

    if (completionBlock)
        completionBlock();
}

@end
