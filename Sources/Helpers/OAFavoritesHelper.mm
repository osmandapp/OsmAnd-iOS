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

#define kPersonalCategory @"personal"

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

+ (NSArray<OAFavoriteGroup *> *) getGroupedFavorites:(QList< std::shared_ptr<OsmAnd::IFavoriteLocation> >)allFavorites
{
    NSMutableDictionary<NSString *, OAFavoriteGroup *> *flatGroups = [NSMutableDictionary dictionary];
    NSMutableArray<OAFavoriteGroup *> *favorites = [NSMutableArray array];
    for (const auto& favorite : allFavorites)
    {
        OAFavoriteItem* favData = [[OAFavoriteItem alloc] init];
        favData.favorite = favorite;
        NSString *groupName = favData.favorite->getGroup().toNSString();
        BOOL isHidden = favData.favorite->isHidden();
        UIColor *color = favData.getColor;
        OAFavoriteGroup *group = [flatGroups objectForKey:groupName];
        if (!group)
        {
            group = [[OAFavoriteGroup alloc] initWithName:groupName isHidden:isHidden color:color];
            [flatGroups setObject:group forKey:groupName];
            [favorites addObject:group];
        }
        [group addPoint:favData];
    }
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [favorites sortUsingDescriptors:[NSArray arrayWithObject:sort]];
    return favorites;
}

@end

@implementation OAFavoriteGroup

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

- (void) addPoint:(OAFavoriteItem *)point
{
    [_points addObject:point];
}

- (BOOL) isPersonalCategoryDisplayName:(NSString *)name
{
    return [name isEqualToString:OALocalizedString(@"personal_category_name")];
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

+ (NSString *) convertDisplayNameToGroupIdName:(NSString *)name
{
    if ([self.class isPersonalCategoryDisplayName:name])
        return kPersonalCategory;
    else if ([name isEqualToString:OALocalizedString(@"favorites")])
        return @"";
    return name;
}

@end
