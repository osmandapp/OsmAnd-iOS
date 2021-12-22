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
#import "OAGPXMutableDocument.h"
#import "OAParkingPositionPlugin.h"
#import "OAPlugin.h"

#import <EventKit/EventKit.h>

#include <OsmAndCore.h>

@implementation OAFavoritesHelper

static NSMutableArray<OAFavoriteItem *> *_cachedFavoritePoints;
static NSMutableArray<OAFavoriteGroup *> *_favoriteGroups;
static NSMutableDictionary<NSString *, OAFavoriteGroup *> *_flatGroups;
static NSDictionary<NSString *, NSArray<NSString *> *> *_poiIcons;
static NSArray<NSString *> *_poiIconsCatagories;
static NSArray<NSString *> *_flatPoiIcons;
static NSArray<NSString *> *_flatBackgroundIcons;
static NSArray<NSString *> *_flatBackgroundContourIcons;
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
            group.color = [favorite getColor];
    }
    
    [OAFavoritesHelper sortAll];
    [OAFavoritesHelper recalculateCachedFavPoints];

    _favoritesLoaded = YES;
}

+ (void) createDefaultCategories
{
    [OAFavoritesHelper addEmptyCategory:OALocalizedString(@"home_pt")];
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
    for (auto it = favorites.begin(); it != favorites.end(); ++it)
    {
        OAFavoriteItem* favData = [[OAFavoriteItem alloc] initWithFavorite:*it];
        [_cachedFavoritePoints addObject:favData];
        
        NSString *groupName = [favData getCategory];
        UIColor *color = [OADefaultFavorite nearestFavColor:[favData getColor]].color;
        OAFavoriteGroup *group = [_flatGroups objectForKey:groupName];
        if (!group)
        {
            group = [[OAFavoriteGroup alloc] initWithName:groupName isVisible:[favData isVisible] color:color];
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
        [item initPersonalType];
        if (item.specialPointType == specialType)
            return item;
    }
    return nil;
}

+ (void) setParkingPoint:(double)lat lon:(double)lon address:(NSString *)address pickupDate:(NSDate *)pickupDate addToCalendar:(BOOL)addToCalendar
{
    OASpecialPointType *specialType = OASpecialPointType.PARKING;
    OAFavoriteItem *point = [OAFavoritesHelper getSpecialPoint:specialType];
    if (point)
    {
        [point setIcon:[specialType getIconName]];
        [point setAddress:address];
        [point setTimestamp:pickupDate];
        [point setCalendarEvent:addToCalendar];
        [OAFavoritesHelper editFavorite:point lat:lat lon:lon description:[point getDescription]];
    }
    else
    {
        OAFavoriteItem *point = [[OAFavoriteItem alloc] initWithLat:lat lon:lon name:[specialType getName] category:[specialType getCategory]];
        [point setAddress:address];
        [point setIcon:[specialType getIconName]];
        [point setColor:[specialType getIconColor]];
        [point setTimestamp:pickupDate];
        [point setCreationTime:[NSDate date]];
        [point setCalendarEvent:addToCalendar];
        [self addFavorite:point];
    }
}

+ (void) setSpecialPoint:(OASpecialPointType *)specialType lat:(double)lat lon:(double)lon address:(NSString *)address
{
    OAFavoriteItem *point = [OAFavoritesHelper getSpecialPoint:specialType];
    if (point)
    {
        [point setIcon:[specialType getIconName]];
        [point setAddress:address];
        [OAFavoritesHelper editFavorite:point lat:lat lon:lon description:[point getDescription]];
    }
    else
    {
        OAFavoriteItem *point = [[OAFavoriteItem alloc] initWithLat:lat lon:lon name:[specialType getName] category:[specialType getCategory]];
        [point setAddress:address];
        [point setIcon:[specialType getIconName]];
        [point setColor:[specialType getIconColor]];
        [self addFavorite:point];
    }
}

+ (BOOL) addFavorite:(OAFavoriteItem *)point
{
    return [self addFavorite:point saveImmediately:YES];
}

+ (BOOL) addFavorite:(OAFavoriteItem *)point saveImmediately:(BOOL)saveImmediately
{
    if ([point getAltitude] == 0)
        [point initAltitude];
    
    if ([point getName].length == 0 && _flatGroups[[point getCategory]])
        return YES;
    
    if (![point isAddressSpecified])
        [OAFavoritesHelper lookupAddress:point];
    
    [[OAAppSettings sharedManager] setShowFavorites:YES];
    
    OAFavoriteGroup *group = [OAFavoritesHelper getOrCreateGroup:point defColor:nil];
    
    if ([point getName].length > 0)
    {
        [point setVisible:group.isVisible];
        if (point.specialPointType == [OASpecialPointType PARKING])
            [point setColor:[point.specialPointType getIconColor]];
        else if (![point getColor])
            [point setColor:group.color];
        
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
        if ([item isVisible] && [OAUtilities isCoordEqual:[item getLatitude] srcLon:[item getLongitude] destLat:lat destLon:lon upToDigits:6])
            return item;
    }
    return nil;
}

+ (NSMutableDictionary<NSString *, OAFavoriteGroup *> *) getGroups
{
    return _flatGroups;
}

+ (OAFavoriteGroup *) getGroupByName:(NSString *)nameId
{
    return _flatGroups[nameId];
}

+ (OAFavoriteGroup *) getGroupByPoint:(OAFavoriteItem *)favoriteItem
{
    if (favoriteItem)
    {
        return _flatGroups[[favoriteItem getCategory]];
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
    NSString *oldGroup = [item getCategory];
    [item setName:newName];
    [item setCategory:group];
    [item setDescription:descr];
    [item setAddress:address];
    
    if (![oldGroup isEqualToString:group])
    {
        OAFavoriteGroup *old = _flatGroups[oldGroup];
        if (old)
            [old.points removeObject:item];
        
        OAFavoriteGroup *newGroup = [OAFavoritesHelper getOrCreateGroup:item defColor:nil];
        [item setVisible:newGroup.isVisible];
        
        //TODO: change icon for parking points here

        UIColor *defaultColor = ((OAFavoriteColor *)[OADefaultFavorite builtinColors][0]).color;
        if (![item getColor] && [item getColor] == defaultColor)
            [item setColor:newGroup.color];

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
    [item initAltitude];
    
    if (description)
        [item setDescription:description];
    
    [OAFavoritesHelper saveCurrentPointsIntoFile];
    return YES;
}

+ (BOOL) editFavoriteGroup:(OAFavoriteGroup *)group newName:(NSString *)newName color:(UIColor*)color visible:(BOOL)visible
{
    //TODO: implement
    return NO;
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
            NSString *title1 = [obj1 getDisplayName];
            NSString *title2 = [obj2 getDisplayName];
            return [title1 compare:title2 options:NSCaseInsensitiveSearch];
        }];
        group.points = [NSMutableArray arrayWithArray:sortedPoints];
        
    }
    
    if (_cachedFavoritePoints)
    {
        NSArray *sortedCachedPoints = [_cachedFavoritePoints sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem *obj1, OAFavoriteItem *obj2) {
            NSString *title1 = [obj1 getDisplayName];
            NSString *title2 = [obj2 getDisplayName];
            return [title1 compare:title2 options:NSCaseInsensitiveSearch];
        }];
        _cachedFavoritePoints = [NSMutableArray arrayWithArray:sortedCachedPoints];
    }
}

+ (OAFavoriteGroup *) getOrCreateGroup:(OAFavoriteItem *)item defColor:(UIColor *)defColor
{
    if (_flatGroups[[item getCategory]])
        return _flatGroups[[item getCategory]];
    
    OAFavoriteGroup *group = [[OAFavoriteGroup alloc] initWithName:[item getCategory] isVisible:[item isVisible] color:[item getColor]];
    
    [_favoriteGroups addObject:group];
    _flatGroups[[item getCategory]] = group;
    
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

+ (BOOL) deleteNewFavoriteItem:(OAFavoriteItem *)favoritesItem
{
    return [self.class deleteFavoriteGroups:nil andFavoritesItems:@[favoritesItem] isNewFavorite:YES];
}

+ (BOOL) deleteFavoriteGroups:(NSArray<OAFavoriteGroup *> *)groupsToDelete andFavoritesItems:(NSArray<OAFavoriteItem *> *)favoritesItems
{
    return [self.class deleteFavoriteGroups:groupsToDelete andFavoritesItems:favoritesItems isNewFavorite:NO];
}

+ (BOOL) deleteFavoriteGroups:(NSArray<OAFavoriteGroup *> *)groupsToDelete andFavoritesItems:(NSArray<OAFavoriteItem *> *)favoritesItems isNewFavorite:(BOOL)isNewFavorite
{
    if (favoritesItems)
    {
        for (OAFavoriteItem *item in favoritesItems)
        {
            OAFavoriteGroup *group = _flatGroups[[item getCategory]];
            if (group)
            {
                NSInteger indexItem = [group.points indexOfObject:item];
                if (indexItem != NSNotFound)
                    [group.points removeObjectAtIndex:indexItem];
            }
            if (group.points.count == 0 && (!isNewFavorite || (isNewFavorite && group.name.length > 0)))
            {
                [_flatGroups removeObjectForKey:group.name];
                [_favoriteGroups removeObject:group];
            }
            NSInteger cachedIndexItem = [_cachedFavoritePoints indexOfObject:item];
            if (cachedIndexItem != NSNotFound)
                [_cachedFavoritePoints removeObjectAtIndex:cachedIndexItem];
            [OsmAndApp instance].favoritesCollection->removeFavoriteLocation(item.favorite);
        }
    }
    if (groupsToDelete)
    {
        QList< std::shared_ptr<OsmAnd::IFavoriteLocation> > toDelete;
        for (OAFavoriteGroup *group in groupsToDelete)
        {
            [_flatGroups removeObjectForKey:group.name];
            [_favoriteGroups removeObject:group];

            NSArray<OAFavoriteItem *> *favoriteItems = group.points;
            for (OAFavoriteItem *favoriteItem in favoriteItems)
            {
                NSInteger cachedIndexItem = [_cachedFavoritePoints indexOfObject:favoriteItem];
                if (cachedIndexItem != NSNotFound)
                    [_cachedFavoritePoints removeObjectAtIndex:cachedIndexItem];

                toDelete.push_back(favoriteItem.favorite);
            }
        }
        [OsmAndApp instance].favoritesCollection->removeFavoriteLocations(toDelete);
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
        NSString *groupName = [favData getCategory];
        UIColor *color = [favData getColor];
        OAFavoriteGroup *group = [flatGroups objectForKey:groupName];
        if (!group)
        {
            group = [[OAFavoriteGroup alloc] initWithName:groupName isVisible:[favData isVisible] color:color];
            [flatGroups setObject:group forKey:groupName];
            [favorites addObject:group];
        }
        [group addPoint:favData];
    }
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    [favorites sortUsingDescriptors:[NSArray arrayWithObject:sort]];
    return favorites;
}

+ (NSDictionary<NSString *, NSString *> *) checkDuplicates:(OAFavoriteItem *)point newName:(NSString *)newName newCategory:(NSString *)newCategory
{
    BOOL emoticons = NO;
    NSString *index = @"";
    int number = 0;
    NSString *checkingName = newName ? newName : [point getName];
    NSString *checkingCategory = newCategory ? newCategory : [point getCategory];
    NSString *editedName = [OAFavoritesHelper checkEmoticons:checkingName];
    NSString *editedCategory = [OAFavoritesHelper checkEmoticons:checkingCategory];
    [point setCategory:editedCategory];
    
    NSString *description;
    if ([point getDescription])
        description = [OAFavoritesHelper checkEmoticons:[point getDescription]];
    [point setDescription:description];
    
    if (editedName.length != checkingName.length)
        emoticons = YES;
    
    BOOL fl = YES;
    while (fl)
    {
        fl = NO;
        for (OAFavoriteItem *favoritePoint in _cachedFavoritePoints)
        {
            if ([[favoritePoint getName] isEqualToString:editedName] &&
                [[favoritePoint getCategory] isEqualToString:[point getCategory]])
            {
                number++;
                index = [NSString stringWithFormat:@" (%i)",number];
                editedName = [checkingName stringByAppendingString:index];
                fl = YES;
                break;
            }
        }
    }
    
    if (index.length > 0 || emoticons)
    {
        [point setName:editedName];
        if (emoticons)
            return @{@"name" : editedName, @"status": @"emoji"};
        else
            return @{@"name" : editedName, @"status": @"duplicate"};
    }
    return nil;
}

+ (NSString *) checkEmoticons:(NSString *)text
{
    __block NSMutableString *tempString = [NSMutableString string];

    [text enumerateSubstringsInRange: NSMakeRange(0, text.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:
     ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {

         const unichar hs = [substring characterAtIndex:0];

        // surrogate pair
         if (0xd800 <= hs && hs <= 0xdbff)
         {
             const unichar ls = [substring characterAtIndex:1];
             const int uc = ((hs - 0xd800) * 0x400) + (ls - 0xdc00) + 0x10000;

             [tempString appendString:(0x1d000 <= uc && uc <= 0x1f77f) ? @"" : substring]; // U+1D000-1F77F

         // non surrogate
         }
         else
         {
             [tempString appendString:(0x2100 <= hs && hs <= 0x26ff && hs != 0x2116) ? @"" : substring]; // U+2100-26FF
         }
     }];
    
    return [NSString stringWithString:tempString];
}

+ (void) setupIcons
{
    NSString* path = [[NSBundle mainBundle] pathForResource:@"poi_categories" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSString* jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];

    NSMutableDictionary<NSString *, NSArray<NSString *> *> *tempIcons  = [NSMutableDictionary new];
    NSMutableArray<NSString *> *tempFlatIcons  = [NSMutableArray new];
    _flatPoiIcons = [NSMutableArray new];
    
    if (json)
    {
        NSDictionary *categories = json[@"categories"];
        if (categories)
        {
            for (NSString *categoryName in categories.allKeys)
            {
                NSArray<NSString *> *icons = categories[categoryName][@"icons"];
                if (icons)
                {
                    tempIcons[categoryName] = icons;
                    [tempFlatIcons addObjectsFromArray:icons];
                }
            }
        }
    }
    _poiIcons = [NSDictionary dictionaryWithDictionary:tempIcons];
    _flatPoiIcons = [NSArray arrayWithArray:tempFlatIcons];
    [self setupPoiIconCategoriesOrder:json jsonString:jsonString];
}

+ (void) setupPoiIconCategoriesOrder:(NSDictionary *)json jsonString:(NSString *)jsonString
{
    NSMutableDictionary<NSString *, NSNumber *> *categoriesOrder = [NSMutableDictionary dictionary];
    
    NSDictionary *categories = json[@"categories"];
    for (NSString *category in categories.allKeys)
    {
        NSNumber *order = [NSNumber numberWithInt: [jsonString indexOf:category]];
        categoriesOrder[category] = order;
    }
    
    _poiIconsCatagories = [categories.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString * obj1, NSString* obj2) {
        return [categoriesOrder[obj1] compare:categoriesOrder[obj2]];
    }];
}

+ (NSDictionary<NSString *, NSArray<NSString *> *> *) getCategirizedIconNames
{
    if (!_poiIcons)
        [self setupIcons];
    return _poiIcons;
}

+ (NSArray<NSString *> *) getOrderedPoiIconsCatagories
{
    return _poiIconsCatagories;
}

+ (NSArray<NSString *> *) getFlatIconNamesList
{
    if (!_flatPoiIcons)
        [self setupIcons];
    return _flatPoiIcons;
}

+ (NSArray<NSString *> *) getFlatBackgroundIconNamesList
{
    if (!_flatBackgroundIcons)
        _flatBackgroundIcons = @[@"circle", @"octagon", @"square"];
    return _flatBackgroundIcons;
}

+ (NSArray<NSString *> *) getFlatBackgroundContourIconNamesList
{
    if (!_flatBackgroundContourIcons)
        _flatBackgroundContourIcons = @[@"bg_point_circle_contour", @"bg_point_octagon_contour", @"bg_point_square_contour"];
    return _flatBackgroundContourIcons;
}

+ (OAGPXDocument *) asGpxFile:(NSArray<OAFavoriteItem *> *)favoritePoints
{
    OAGPXMutableDocument *gpx = [[OAGPXMutableDocument alloc] init];
    [gpx setVersion:[NSString stringWithFormat:@"%@ %@", @"OsmAnd",
                     [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"]]];
    for (OAFavoriteItem *p in favoritePoints)
    {
        [gpx addWpt:p.toWpt];
    }
    return gpx;
}

+ (void) addParkingReminderToCalendar
{
    EKEventStore *eventStore = [[EKEventStore alloc] init];
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error)
            {
                [[[UIAlertView alloc] initWithTitle:OALocalizedString(@"cannot_access_calendar") message:error.localizedDescription delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil] show];
            }
            else if (!granted)
            {
                [[[UIAlertView alloc] initWithTitle:OALocalizedString(@"cannot_access_calendar") message:OALocalizedString(@"reminder_not_set_text") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil] show];
            }
            else
            {
                EKEvent *event = [EKEvent eventWithEventStore:eventStore];
                event.title = OALocalizedString(@"pickup_car");
                
                OAParkingPositionPlugin *plugin = (OAParkingPositionPlugin *) [OAPlugin getPlugin:OAParkingPositionPlugin.class];
                if (plugin)
                {
                    if (plugin.getEventIdentifier)
                        [self.class removeParkingReminderFromCalendar];
                    NSDate *pickupDate = [NSDate dateWithTimeIntervalSince1970:plugin.getParkingTime / 1000];
                    event.startDate = pickupDate;
                    event.endDate = pickupDate;
                    
                    [event addAlarm:[EKAlarm alarmWithRelativeOffset:-60.0 * 5.0]];
                    
                    [event setCalendar:[eventStore defaultCalendarForNewEvents]];
                    NSError *err;
                    [eventStore saveEvent:event span:EKSpanThisEvent error:&err];
                    if (err)
                        [[[UIAlertView alloc] initWithTitle:nil message:error.localizedDescription delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil] show];
                    else
                        [plugin setEventIdentifier:[event.eventIdentifier copy]];
                }
            }
        });
    }];
}

+ (void) removeParkingReminderFromCalendar
{
    OAParkingPositionPlugin *plugin = (OAParkingPositionPlugin *) [OAPlugin getPlugin:OAParkingPositionPlugin.class];
    if (plugin)
    {
        if (plugin.getEventIdentifier)
        {
            EKEventStore *eventStore = [[EKEventStore alloc] init];
            EKEvent *event = [eventStore eventWithIdentifier:plugin.getEventIdentifier];
            NSError *error;
            if (![eventStore removeEvent:event span:EKSpanFutureEvents error:&error])
                NSLog(@"%@", [error localizedDescription]);
            else
                [plugin setEventIdentifier:nil];
        }
    }
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
    return [name isEqualToString:kPersonalCategory];
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
    if ([self isPersonalCategoryDisplayName:name])
        return kPersonalCategory;
    else if ([name isEqualToString:OALocalizedString(@"favorites")])
        return @"";
    return name;
}

@end
