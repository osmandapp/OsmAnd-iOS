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
#import "OAColors.h"
#import "OAUtilities.h"
#import "OADefaultFavorite.h"

#include <OsmAndCore.h>

#define kPersonalCategory @"personal"

@implementation OAFavoritesHelper

static NSMutableArray<OAFavoriteItem *> *cachedFavoritePoints;
static NSMutableArray<OAFavoriteGroup *> *favoriteGroups;
static NSMutableDictionary<NSString *, OAFavoriteGroup *> *flatGroups;
static BOOL favoritesLoaded = NO;

+ (BOOL) isFavoritesLoaded
{
    return favoritesLoaded;
}

+ (void) loadFavorites
{
    cachedFavoritePoints = [NSMutableArray array];
    favoriteGroups = [NSMutableArray array];
    flatGroups = [NSMutableDictionary dictionary];
        
    const auto& allFavorites = [OsmAndApp instance].favoritesCollection->getFavoriteLocations();

    for (const auto& favorite : allFavorites)
    {
        OAFavoriteItem* favData = [[OAFavoriteItem alloc] init];
        favData.favorite = favorite;
        [cachedFavoritePoints addObject:favData];
        
        NSString *groupName = favData.favorite->getGroup().toNSString();
        BOOL isHidden = favData.favorite->isHidden();
        UIColor *color = favData.getColor;
        OAFavoriteGroup *group = [flatGroups objectForKey:groupName];
        if (!group)
        {
            group = [[OAFavoriteGroup alloc] initWithName:groupName isHidden:isHidden color:color];
            [flatGroups setObject:group forKey:groupName];
            [favoriteGroups addObject:group];
        }
        [group addPoint:favData];
    }
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [favoriteGroups sortUsingDescriptors:[NSArray arrayWithObject:sort]];

    favoritesLoaded = YES;
}


+ (NSArray<OAFavoriteItem *> *) getFavoriteItems
{
    return cachedFavoritePoints;
}

+ (NSArray<OAFavoriteItem *> *) getVisibleFavoriteItems
{
    NSMutableArray<OAFavoriteItem *> *res = [NSMutableArray array];
    for (OAFavoriteItem *item in cachedFavoritePoints)
    {
        if (item.isVisible)
            [res addObject:item];
    }
    return res;
}

+ (void) editFavorite:(OAFavoriteItem *)item name:(NSString *)name group:(NSString *)group
{
    NSString *oldGroup = [item getFavoriteGroup];
    [item setFavoriteName:name];
    [item setFavoriteGroup:group];
    
    if (![oldGroup isEqualToString:group])
    {
        OAFavoriteGroup *old = flatGroups[oldGroup];
        if (old)
            [old.points removeObject:item];
        
        OAFavoriteGroup *newGroup = [OAFavoritesHelper getOrCreateGroup:item defColor:nil];
        [item setFavoriteHidden:newGroup.isHidden];
        
        //TODO: change icon color to group default color here
        
        [newGroup.points addObject:item];
    }
}

+ (OAFavoriteGroup *) getOrCreateGroup:(OAFavoriteItem *)item defColor:(UIColor *)defColor
{
    if (flatGroups[[item getFavoriteGroup]])
        return flatGroups[[item getFavoriteGroup]];
    
    UIColor *color = defColor;
    if (!color)
        color = ((OAFavoriteColor *)[OADefaultFavorite builtinColors][0]).color;
    
    OAFavoriteGroup *group = [[OAFavoriteGroup alloc] initWithName:[item getFavoriteGroup] isHidden:[item getFavoriteHidden] color:color];
    
    [favoriteGroups addObject:group];
    flatGroups[[item getFavoriteGroup]] = group;
    
    return group;
}

+ (NSMutableArray<OAFavoriteGroup *> *) getFavoriteGroups
{
    return favoriteGroups;
}

+ (void) addEmptyCategory:(NSString *)name color:(UIColor *)color visible:(BOOL)visible
{
    OAFavoriteGroup *group = [[OAFavoriteGroup alloc] initWithName:name isHidden:visible color:color];
    [favoriteGroups addObject:group];
    flatGroups[name] = group;
}

+ (void) deleteFavoriteGroups:(NSArray<OAFavoriteGroup *> *)groupsToDelete andFavoritesItems:(NSArray<OAFavoriteItem *> *)favoritesItems
{
    if (favoritesItems)
    {
        for (OAFavoriteItem *item in favoritesItems)
        {
            OAFavoriteGroup *group = flatGroups[[item getFavoriteGroup]];
            if (group)
                [group.points removeObject:item];
            
            [cachedFavoritePoints removeObject:item];
            [OsmAndApp instance].favoritesCollection->removeFavoriteLocation(item.favorite);
        }
    }
    if (groupsToDelete)
    {
        for (OAFavoriteGroup *group in groupsToDelete)
        {
            [flatGroups removeObjectForKey:group.name];
            [favoriteGroups removeObject:group];
        }
    }
    [[OsmAndApp instance] saveFavoritesToPermamentStorage];
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

- (UIColor *) color
{
    return [OAUtilities areColorsEqual:_color color2:UIColor.whiteColor] ? UIColorFromRGB(color_chart_orange) : _color;
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
