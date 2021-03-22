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
#import "OAAppSettings.h"

#include <OsmAndCore.h>

#define kPersonalCategory @"personal"

@implementation OAFavoritesHelper

static NSMutableArray<OAFavoriteItem *> *_cachedFavoritePoints;
static NSMutableArray<OAFavoriteGroup *> *_favoriteGroups;
static NSMutableDictionary<NSString *, OAFavoriteGroup *> *_flatGroups;
static BOOL _favoritesLoaded = NO;

+ (BOOL) isFavoritesLoaded
{
    return _favoritesLoaded;
}

+ (void) loadFavorites
{
    _cachedFavoritePoints = [NSMutableArray array];
    _favoriteGroups = [NSMutableArray array];
    _flatGroups = [NSMutableDictionary dictionary];
        
    const auto& allFavorites = [OsmAndApp instance].favoritesCollection->getFavoriteLocations();
    
    NSMutableArray *loadedPoints = [NSMutableArray new];
    for (const auto& favorite : allFavorites)
    {
        OAFavoriteItem* favData = [[OAFavoriteItem alloc] initWithFavorite:favorite];
        [loadedPoints addObject:favData];
    }
    NSArray *sortedLoadedPoints = [loadedPoints sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem *obj1, OAFavoriteItem *obj2) {
        NSString *title1 = [obj1 getDisplayName];
        NSString *title2 = [obj2 getDisplayName];
        return [title1 compare:title2 options:NSCaseInsensitiveSearch];
    }];
    
    //[OAFavoritesHelper createDefaultCategories];
    
    for (OAFavoriteItem *favorite : sortedLoadedPoints)
    {
        OAFavoriteGroup *group = [OAFavoritesHelper getOrCreateGroup:favorite defColor:nil];
        [group addPoint:favorite];
        
        if (group.points.count == 1)
            group.color = [favorite getFavoriteColor];
    }
    
    [OAFavoritesHelper sortAll];
    [OAFavoritesHelper recalculateCachedFavPoints];

    _favoritesLoaded = YES;
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
    for (OAFavoriteGroup *group in _favoriteGroups)
        [allPoints addObjectsFromArray:group.points];
    
    _cachedFavoritePoints = allPoints;
}

+ (void) import:(QList< std::shared_ptr<OsmAnd::IFavoriteLocation> >)favorites
{
    for (const auto& favorite : favorites)
    {
        OAFavoriteItem* favData = [[OAFavoriteItem alloc] initWithFavorite:favorite];
        [_cachedFavoritePoints addObject:favData];
        
        NSString *groupName = [favData getFavoriteGroup];
        UIColor *color = [favData getFavoriteColor];
        OAFavoriteGroup *group = [_flatGroups objectForKey:groupName];
        if (!group)
        {
            group = [[OAFavoriteGroup alloc] initWithName:groupName isVisible:[favData getFavoriteVisible] color:color];
            [_flatGroups setObject:group forKey:groupName];
            [_favoriteGroups addObject:group];
        }
        [group addPoint:favData];
    }
}

+ (OAFavoriteItem *) getSpecialPoint:(OASpecialPointType *)specialType
{
    for (OAFavoriteItem *item in _cachedFavoritePoints)
    {
        if (item.specialPointType == specialType)
            return item;
    }
    return nil;
}

+ (void) setSpecialPoint:(OASpecialPointType *)specialType lat:(double)lat lon:(double)lon address:(NSString *)address
{
    OAFavoriteItem *point = [OAFavoritesHelper getSpecialPoint:specialType];
    if (point)
    {
        [point setFavoriteIcon:[specialType getIconName]];
        [point setFavoriteAddress:address];
        [OAFavoritesHelper editFavorite:point lat:lat lon:lon description:[point getFavoriteDesc]];
    }
    else
    {
        OAFavoriteItem *point = [[OAFavoriteItem alloc] initWithLat:lat lon:lon name:[specialType getName] group:[specialType getCategory]];
        [point setFavoriteAddress:address];
        [point setFavoriteIcon:[specialType getIconName]];
        [point setFavoriteColor:[specialType getIconColor]];
        [self addFavorite:point];
    }
}

+ (BOOL) addFavorite:(OAFavoriteItem *)point
{
    return [self addFavorite:point saveImmediately:YES];
}

+ (BOOL) addFavorite:(OAFavoriteItem *)point saveImmediately:(BOOL)saveImmediately
{
    //TODO:init alitude if empty
    
    if ([point getFavoriteName].length == 0 && _flatGroups[[point getFavoriteGroup]])
        return YES;
    
    if (![point isAddressSpecified])
        [OAFavoritesHelper lookupAddress:point];
    
    [[OAAppSettings sharedManager] setShowFavorites:YES];
    
    OAFavoriteGroup *group = [OAFavoritesHelper getOrCreateGroup:point defColor:nil];
    
    if ([point getFavoriteName].length > 0)
    {
        [point setFavoriteVisible:group.isVisible];
        if (point.specialPointType == [OASpecialPointType PARKING])
            [point setFavoriteColor:[point.specialPointType getIconColor]];
        else if (![point getFavoriteColor])
            [point setFavoriteColor:group.color];
        
        [group addPoint:point];
        [_cachedFavoritePoints addObject:point];
    }
    if (saveImmediately)
    {
        [OAFavoritesHelper sortAll];
        [OAFavoritesHelper saveCurrentPointsIntoFile];
    }
    
    return YES;
}

+ (void) lookupAddress:(OAFavoriteItem *)point
{
    //TODO: implement
}

+ (NSArray<OAFavoriteItem *> *) getFavoriteItems
{
    return _cachedFavoritePoints;
}

+ (OAFavoriteItem *) getVisibleFavByLat:(double)lat lon:(double)lon
{
    for (OAFavoriteItem *item in _cachedFavoritePoints)
    {
        if ([item getFavoriteVisible] && [OAFavoritesHelper isEqualCoordinatesOne:[item getLatitude] coordinateTwo:lat] && [OAFavoritesHelper isEqualCoordinatesOne:[item getLongitude] coordinateTwo:lon])
            return item;
    }
    return nil;
}

+ (BOOL) isEqualCoordinatesOne:(double)coord1 coordinateTwo:(double)coord2
{
    int roundedValue1 = (int)coord1 * 10;
    int roundedValue2 = (int)coord2 * 10;
    return roundedValue1 == roundedValue2;
}

+ (OAFavoriteGroup *) getGroupByName:(NSString *)nameId
{
    return _flatGroups[nameId];
}

+ (OAFavoriteGroup *) getGroupByPoint:(OAFavoriteItem *)favoriteItem
{
    if (favoriteItem)
    {
        return _flatGroups[[favoriteItem getFavoriteGroup]];
    }
    return nil;
}

+ (NSArray<OAFavoriteItem *> *) getVisibleFavoriteItems
{
    NSMutableArray<OAFavoriteItem *> *res = [NSMutableArray array];
    for (OAFavoriteItem *item in _cachedFavoritePoints)
    {
        if (item.isVisible)
            [res addObject:item];
    }
    return res;
}

+ (BOOL) editFavoriteName:(OAFavoriteItem *)item newName:(NSString *)newName group:(NSString *)group descr:(NSString *)descr address:(NSString *)address
{
    NSString *oldGroup = [item getFavoriteGroup];
    [item setFavoriteName:newName];
    [item setFavoriteGroup:group];
    [item setFavoriteDesc:descr];
    [item setFavoriteAddress:address];
    
    if (![oldGroup isEqualToString:group])
    {
        OAFavoriteGroup *old = _flatGroups[oldGroup];
        if (old)
            [old.points removeObject:item];
        
        OAFavoriteGroup *newGroup = [OAFavoritesHelper getOrCreateGroup:item defColor:nil];
        [item setFavoriteVisible:newGroup.isVisible];
        
        //TODO: change icon for parking points here

        UIColor *defaultColor = ((OAFavoriteColor *)[OADefaultFavorite builtinColors][0]).color;
        if (![item getFavoriteColor] && [item getFavoriteColor] == defaultColor)
            [item setFavoriteColor:newGroup.color];

        [newGroup.points addObject:item];
    }
    
    [OAFavoritesHelper sortAll];
    [OAFavoritesHelper saveCurrentPointsIntoFile];
    return YES;
}

+ (BOOL) editFavorite:(OAFavoriteItem *)item lat:(double)lat lon:(double)lon
{
    return [OAFavoritesHelper editFavorite:item lat:lat lon:lon description:nil];
}

+ (BOOL) editFavorite:(OAFavoriteItem *)item lat:(double)lat lon:(double)lon description:(NSString *)description
{
    [item setLat:lat lon:lon];
    
    //TODO: set altitude here
    
    if (description)
        [item setFavoriteDesc:description];
    
    [OAFavoritesHelper saveCurrentPointsIntoFile];
    return YES;
}

+ (void) editFavoriteGroup:(OAFavoriteGroup *)group newName:(NSString *)newName color:(UIColor*)color visible:(BOOL)visible
{
    //TODO: implement
}

+ (void) saveCurrentPointsIntoFile
{
    [[OsmAndApp instance] saveFavoritesToPermamentStorage];
}


+ (void) sortAll
{
    NSArray *sortedGroups = [_favoriteGroups sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteGroup *obj1, OAFavoriteGroup *obj2) {
        if ([obj1 isPersonal])
            return NSOrderedAscending;
        else if ([obj2 isPersonal])
            return NSOrderedDescending;
        else
            return [obj1.name compare:obj2.name options:NSCaseInsensitiveSearch];
    }];
    _favoriteGroups = [NSMutableArray arrayWithArray:sortedGroups];
    
    for (OAFavoriteGroup *group in _favoriteGroups)
    {
        NSArray *sortedPoints = [group.points sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem *obj1, OAFavoriteItem *obj2) {
            NSString *title1 = [obj1 getFavoriteName];
            NSString *title2 = [obj2 getFavoriteName];
            return [title1 compare:title2 options:NSCaseInsensitiveSearch];
        }];
        group.points = [NSMutableArray arrayWithArray:sortedPoints];
        
    }
    
    if (_cachedFavoritePoints)
    {
        NSArray *sortedCachedPoints = [_cachedFavoritePoints sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem *obj1, OAFavoriteItem *obj2) {
            NSString *title1 = [obj1 getFavoriteName];
            NSString *title2 = [obj2 getFavoriteName];
            return [title1 compare:title2 options:NSCaseInsensitiveSearch];
        }];
        _cachedFavoritePoints = [NSMutableArray arrayWithArray:sortedCachedPoints];
    }
}

+ (OAFavoriteGroup *) getOrCreateGroup:(OAFavoriteItem *)item defColor:(UIColor *)defColor
{
    if (_flatGroups[[item getFavoriteGroup]])
        return _flatGroups[[item getFavoriteGroup]];
    
    OAFavoriteGroup *group = [[OAFavoriteGroup alloc] initWithName:[item getFavoriteGroup] isVisible:[item getFavoriteVisible] color:[item getColor]];
    
    [_favoriteGroups addObject:group];
    _flatGroups[[item getFavoriteGroup]] = group;
    
    if (!group.color)
        group.color = defColor ? defColor : ((OAFavoriteColor *)[OADefaultFavorite builtinColors][0]).color;
    
    return group;
}

+ (NSMutableArray<OAFavoriteGroup *> *) getFavoriteGroups
{
    return _favoriteGroups;
}

+ (void) addEmptyCategory:(NSString *)name
{
    UIColor *defaultColor = ((OAFavoriteColor *)[OADefaultFavorite builtinColors][4]).color;
    [OAFavoritesHelper addEmptyCategory:name color:defaultColor visible:YES];
}


+ (void) addEmptyCategory:(NSString *)name color:(UIColor *)color visible:(BOOL)visible
{
    OAFavoriteGroup *group = [[OAFavoriteGroup alloc] initWithName:name isVisible:visible color:color];
    [_favoriteGroups addObject:group];
    _flatGroups[name] = group;
}

+ (BOOL) deleteFavoriteGroups:(NSArray<OAFavoriteGroup *> *)groupsToDelete andFavoritesItems:(NSArray<OAFavoriteItem *> *)favoritesItems
{
    if (favoritesItems)
    {
        for (OAFavoriteItem *item in favoritesItems)
        {
            OAFavoriteGroup *group = _flatGroups[[item getFavoriteGroup]];
            if (group)
                [group.points removeObject:item];
            
            [_cachedFavoritePoints removeObject:item];
            [OsmAndApp instance].favoritesCollection->removeFavoriteLocation(item.favorite);
        }
    }
    if (groupsToDelete)
    {
        for (OAFavoriteGroup *group in groupsToDelete)
        {
            [_flatGroups removeObjectForKey:group.name];
            [_favoriteGroups removeObject:group];
        }
    }
    [OAFavoritesHelper saveCurrentPointsIntoFile];
    return YES;
}

+ (NSArray<OAFavoriteGroup *> *) getGroupedFavorites:(QList< std::shared_ptr<OsmAnd::IFavoriteLocation> >)allFavorites
{
    NSMutableDictionary<NSString *, OAFavoriteGroup *> *flatGroups = [NSMutableDictionary dictionary];
    NSMutableArray<OAFavoriteGroup *> *favorites = [NSMutableArray array];
    for (const auto& favorite : allFavorites)
    {
        OAFavoriteItem* favData = [[OAFavoriteItem alloc] initWithFavorite:favorite];
        NSString *groupName = [favData getFavoriteGroup];
        UIColor *color = [favData getFavoriteColor];
        OAFavoriteGroup *group = [flatGroups objectForKey:groupName];
        if (!group)
        {
            group = [[OAFavoriteGroup alloc] initWithName:groupName isVisible:[favData getFavoriteVisible] color:color];
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
    if ([point getFavoriteDesc])
        description = [OAFavoritesHelper checkEmoticons:[point getFavoriteDesc]];
    [point setFavoriteDesc:description];
    
    if (name.length != [point getFavoriteName].length)
        emoticons = YES;
    
    BOOL fl = YES;
    while (fl)
    {
        fl = NO;
        for (OAFavoriteItem *favoritePoint in _cachedFavoritePoints)
        {
            if ([[favoritePoint getFavoriteName] isEqualToString:name] &&
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
            return @{@"name" : name, @"status": @"emoji"};
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

- (instancetype) initWithName:(NSString *)name isVisible:(BOOL)isVisible color:(UIColor *)color
{
    self = [super init];
    if (self)
    {
        _name = name;
        _isVisible = isVisible;
        _color = color;
        _points = [NSMutableArray array];
    }
    return self;
}

- (instancetype) initWithPoints:(NSArray<OAFavoriteItem *> *)points name:(NSString *)name isVisible:(BOOL)isVisible color:(UIColor *)color
{
    self = [super init];
    if (self)
    {
        _name = name;
        _isVisible = isVisible;
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
    return [OAFavoriteGroup isPersonalCategoryDisplayName:self.name];
}

+ (BOOL) isPersonal:(NSString *)name
{
    return [name isEqualToString:kPersonalCategory];
}

+ (BOOL) isPersonalCategoryDisplayName:(NSString *)name
{
    return [name isEqualToString:OALocalizedString(@"personal_category_name")];
}

+ (NSString *) getDisplayName:(NSString *)name
{
    if ([OAFavoriteGroup isPersonal:name])
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
