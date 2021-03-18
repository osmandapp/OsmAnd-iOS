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
    
    NSMutableArray *loadedPoints = [NSMutableArray new];
    for (const auto& favorite : allFavorites)
    {
        OAFavoriteItem* favData = [[OAFavoriteItem alloc] init];
        favData.favorite = favorite;
        [loadedPoints addObject:favData];
    }
    NSArray *sortedLoadedPoints = [loadedPoints sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem *obj1, OAFavoriteItem *obj2) {
        NSString *title1 = [obj1 getFavoriteName];
        NSString *title2 = [obj2 getFavoriteName];
        return [title1 compare:title2 options:NSCaseInsensitiveSearch];
    }];
    
    [OAFavoritesHelper createDefaultCategories];
    
    for (OAFavoriteItem *favorite : sortedLoadedPoints)
    {
        OAFavoriteGroup *group = [OAFavoritesHelper getOrCreateGroup:favorite defColor:nil];
        [group addPoint:favorite];
        
        if (group.points.count == 1)
            group.color = [favorite getFavoriteColor];
    }
    
    [OAFavoritesHelper sortAll];
    [OAFavoritesHelper recalculateCachedFavPoints];

    favoritesLoaded = YES;
}

+ (void) createDefaultCategories
{
    
    [OAFavoritesHelper addEmptyCategory:OALocalizedString(@"favorite_home_category")];
    [OAFavoritesHelper addEmptyCategory:OALocalizedString(@"favorite_friends_category")];
    [OAFavoritesHelper addEmptyCategory:OALocalizedString(@"favorite_places_category")];
    [OAFavoritesHelper addEmptyCategory:OALocalizedString(@"shared_string_others")];
}

+ (void) recalculateCachedFavPoints
{
    NSMutableArray *allPoints = [NSMutableArray new];
    for (OAFavoriteGroup *group in favoriteGroups)
        [allPoints addObjectsFromArray:group.points];
    
    cachedFavoritePoints = allPoints;
}

+ (void) import:(QList< std::shared_ptr<OsmAnd::IFavoriteLocation> >)favorites
{
    for (const auto& favorite : favorites)
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
}

+ (NSArray<OAFavoriteItem *> *) getFavoriteItems
{
    return cachedFavoritePoints;
}

+ (OAFavoriteGroup *) getGroupByName:(NSString *)nameId
{
    return flatGroups[nameId];
}

+ (OAFavoriteGroup *) getGroupByPoint:(OAFavoriteItem *)favoriteItem
{
    if (favoriteItem)
    {
        return flatGroups[[favoriteItem getFavoriteGroup]];
    }
    return nil;
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

+ (void) editFavoriteName:(OAFavoriteItem *)item newName:(NSString *)newName group:(NSString *)group descr:(NSString *)descr address:(NSString *)address
{
    NSString *oldGroup = [item getFavoriteGroup];
    [item setFavoriteName:newName];
    [item setFavoriteGroup:group];
    [item setFavoriteDesc:descr];
    [item setFavoriteAddress:address];
    
    if (![oldGroup isEqualToString:group])
    {
        OAFavoriteGroup *old = flatGroups[oldGroup];
        if (old)
            [old.points removeObject:item];
        
        OAFavoriteGroup *newGroup = [OAFavoritesHelper getOrCreateGroup:item defColor:nil];
        [item setFavoriteHidden:newGroup.isHidden];
        
        //TODO: change icon for parking points

        UIColor *defaultColor = ((OAFavoriteColor *)[OADefaultFavorite builtinColors][0]).color;
        if (![item getFavoriteColor] && [item getFavoriteColor] == defaultColor)
            [item setFavoriteColor:newGroup.color];

        [newGroup.points addObject:item];
    }
    
    [OAFavoritesHelper sortAll];
    [[OsmAndApp instance] saveFavoritesToPermamentStorage];
}

+ (void) sortAll
{
    NSArray *sortedGroups = [favoriteGroups sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteGroup *obj1, OAFavoriteGroup *obj2) {
        if ([obj1 isPersonal])
            return NSOrderedAscending;
        else if ([obj2 isPersonal])
            return NSOrderedDescending;
        else
            return [obj1.name compare:obj2.name options:NSCaseInsensitiveSearch];
    }];
    favoriteGroups = [NSMutableArray arrayWithArray:sortedGroups];
    
    for (OAFavoriteGroup *group in favoriteGroups)
    {
        NSArray *sortedPoints = [group.points sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem *obj1, OAFavoriteItem *obj2) {
            NSString *title1 = [obj1 getFavoriteName];
            NSString *title2 = [obj2 getFavoriteName];
            return [title1 compare:title2 options:NSCaseInsensitiveSearch];
        }];
        group.points = [NSMutableArray arrayWithArray:sortedPoints];
        
    }
    
    if (cachedFavoritePoints)
    {
        NSArray *sortedCachedPoints = [cachedFavoritePoints sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem *obj1, OAFavoriteItem *obj2) {
            NSString *title1 = [obj1 getFavoriteName];
            NSString *title2 = [obj2 getFavoriteName];
            return [title1 compare:title2 options:NSCaseInsensitiveSearch];
        }];
        cachedFavoritePoints = [NSMutableArray arrayWithArray:sortedCachedPoints];
    }
}

+ (OAFavoriteGroup *) getOrCreateGroup:(OAFavoriteItem *)item defColor:(UIColor *)defColor
{
    if (flatGroups[[item getFavoriteGroup]])
        return flatGroups[[item getFavoriteGroup]];
    
    OAFavoriteGroup *group = [[OAFavoriteGroup alloc] initWithName:[item getFavoriteGroup] isHidden:[item getFavoriteHidden] color:[item getColor]];
    
    [favoriteGroups addObject:group];
    flatGroups[[item getFavoriteGroup]] = group;
    
    if (!group.color)
        group.color = defColor ? defColor : ((OAFavoriteColor *)[OADefaultFavorite builtinColors][0]).color;
    
    return group;
}

+ (NSMutableArray<OAFavoriteGroup *> *) getFavoriteGroups
{
    return favoriteGroups;
}

+ (void) addEmptyCategory:(NSString *)name
{
    UIColor *defaultColor = ((OAFavoriteColor *)[OADefaultFavorite builtinColors][4]).color;
    [OAFavoritesHelper addEmptyCategory:name color:defaultColor visible:YES];
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

+ (NSDictionary<NSString *, NSString *> *) checkDuplicates:(OAFavoriteItem *)point
{
    BOOL emoticons = false;
    NSString *index = @"";
    int number = 0;
    NSString *name = [OAFavoritesHelper checkEmoticons:[point getFavoriteName]];
    NSString *category = [OAFavoritesHelper checkEmoticons:[point getFavoriteGroup]];
    [point setFavoriteGroup:category];
    
    NSString *description;
    if (![point getFavoriteDesc])
        description = [OAFavoritesHelper checkEmoticons:[point getFavoriteDesc]];
    [point setFavoriteDesc:description];
    
    if (name.length != [point getFavoriteName].length)
        emoticons = YES;
    
    BOOL fl = YES;
    while (fl)
    {
        fl = NO;
        for (OAFavoriteItem *favoritePoint in cachedFavoritePoints)
        {
            if ([[favoritePoint getFavoriteName] isEqualToString:name] &&
                //[favoritePoint getLatitude] != [point getLatitude] &&
                //[favoritePoint getLongitude] != [point getLongitude] &&
                [[favoritePoint getFavoriteGroup] isEqualToString:[point getFavoriteGroup]])
            {
                number++;
                index = [NSString stringWithFormat:@" (%i)",number];
                name = [[point getFavoriteName] stringByAppendingString:index];
                fl = YES;
                break;
            }
        }
    }
    
    if (index.length > 0 || emoticons)
    {
        [point setFavoriteName:name];
        if (emoticons)
            return @{@"name" : name, @"status": @"emojy"};
        else
            return @{@"name" : name, @"status": @"duplicate"};
    }
    return nil;
}



+ (NSString *) checkEmoticons:(NSString *)text
{
    __block NSMutableString* tempString = [NSMutableString string];
    
    [text enumerateSubstringsInRange: NSMakeRange(0, text.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:
     ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop){
         
         const unichar hs = [substring characterAtIndex: 0];
         
         // surrogate pair
         if (0xd800 <= hs && hs <= 0xdbff) {
             const unichar ls = [substring characterAtIndex: 1];
             const int uc = ((hs - 0xd800) * 0x400) + (ls - 0xdc00) + 0x10000;
             
             [tempString appendString: (0x1d000 <= uc && uc <= 0x1f77f)? @"": substring]; // U+1D000-1F77F
             
         // non surrogate
         } else {
             [tempString appendString: (0x2100 <= hs && hs <= 0x26ff)? @"": substring]; // U+2100-26FF
         }
     }];
    
    return [NSString stringWithString:tempString];
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

- (BOOL) isPersonal
{
    return [self isPersonalCategoryDisplayName:self.name];
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
