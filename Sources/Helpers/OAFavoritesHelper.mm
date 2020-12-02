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
#import "Localization.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>

#define kPersonalCategory @"personal"

@implementation OAFavoritesHelper
{
    NSArray<OAFavoriteGroup *> *_favoriteGroups;
    NSMutableDictionary<NSString *, OAFavoriteGroup *> *_flatGroups;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _favoriteGroups = [NSArray arrayWithArray:[self getGroupedFavorites:[self.class getFavoriteItems]]];
        _flatGroups = [NSMutableDictionary dictionary];
    }
    return self;
}

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

+ (NSString *) getDisplayName:(NSString *)name
{
    if ([name isEqualToString:kPersonalCategory])
        return OALocalizedString(@"personal_category_name");
    else if (name.length == 0)
        return OALocalizedString(@"favorites");
    else
        return name;
}

- (NSArray<OAFavoriteGroup *> *) getFavoriteGroups;
{
    return _favoriteGroups;
}

- (NSArray<OAFavoriteGroup *> *) getGroupedFavorites:(NSArray<OAFavoriteItem *> *)items
{
    NSMutableArray<OAFavoriteGroup *> *groupedItems = [NSMutableArray array];
    for (OAFavoriteItem *item in items)
    {
        OAFavoriteItem* favData = [[OAFavoriteItem alloc] init];
        favData.favorite = item.favorite;
        NSString *groupName = item.favorite->getGroup().toNSString();
        BOOL isHidden = favData.favorite->isHidden();
        UIColor *color = favData.getColor;
        OAFavoriteGroup *group = [_flatGroups objectForKey:groupName];
        if (!group)
        {
            group = [[OAFavoriteGroup alloc] initWithName:groupName isHidden:isHidden color:color];
            [_flatGroups setObject:group forKey:groupName];
            [groupedItems addObject:group];
        }
        [group addPoint:item];
    }
    return groupedItems;
}

- (OAFavoriteGroup *) getGroup:(NSString *)nameId
{
    if ([_flatGroups objectForKey:nameId])
        return [_flatGroups objectForKey:nameId];
    else
        return nil;
}

@end

@implementation OAFavoriteGroup
{
    NSMutableArray<OAFavoriteItem*> *_points;
}

- (instancetype) initWithName:(NSString *)name isHidden:(BOOL)isHidden color:(UIColor *)color
{
    self = [super init];
    if (self)
    {
        _name = name;
        _isHidden = isHidden;
        _color = color;
        _points = [NSMutableArray array];
    }
    return self;
}

- (instancetype) initWithPoints:(NSArray<OAFavoriteItem *> *)points name:(NSString *)name isHidden:(BOOL)isHidden color:(UIColor *)color
{
    self = [super init];
    if (self)
    {
        _name = name;
        _isHidden = isHidden;
        _color = color;
        _points = [NSMutableArray arrayWithArray:points];
    }
    return self;
}

- (NSArray<OAFavoriteItem*> *) getPoints
{
    return _points;
}

- (void) addPoint:(OAFavoriteItem *)point
{
    [_points addObject:point];
}

@end
