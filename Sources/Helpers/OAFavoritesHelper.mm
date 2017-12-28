//
//  OAFavoritesHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAFavoritesHelper.h"
#import "OsmAndApp.h"
#import "OALocationPoint.h"
#import "OAFavoriteItem.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>

@implementation OAFavoritesHelper

+ (NSArray<OAFavoriteItem *> *) getFavoriteItems
{
    NSMutableArray<OAFavoriteItem *> *res = [NSMutableArray array];
    
    const auto& allFavorites = [OsmAndApp instance].favoritesCollection->getFavoriteLocations();
    for(const auto& favorite : allFavorites)
    {
        OAFavoriteItem *item = [[OAFavoriteItem alloc] init];
        item.favorite = favorite;
        [res addObject:item];
    }
    
    return res;
}

+ (NSArray<OAFavoriteItem *> *) getVisibleFavoriteItems
{
    NSMutableArray<OAFavoriteItem *> *res = [NSMutableArray array];
    
    const auto& allFavorites = [OsmAndApp instance].favoritesCollection->getFavoriteLocations();
    for(const auto& favorite : allFavorites)
    {
        if (!favorite->isHidden())
        {
            OAFavoriteItem *item = [[OAFavoriteItem alloc] init];
            item.favorite = favorite;
            [res addObject:item];
        }
    }
    
    return res;
}

@end
