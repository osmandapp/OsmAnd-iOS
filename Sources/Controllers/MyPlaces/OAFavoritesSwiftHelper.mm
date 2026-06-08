//
//  OAFavoritesSwiftHelper.mm
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 05.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAFavoritesSwiftHelper.h"
#import "OAAppSettings.h"
#import "OAEditGroupViewController.h"
#import "OAFavoriteItem.h"
#import "OAFavoriteGroupEditorViewController.h"
#import "OAFavoritesHelper.h"
#import "OAGPXDatabase.h"
#import "OAIndexConstants.h"
#import "OALocationServices.h"
#import "OAMapPanelViewController.h"
#import "OAOpenAddTrackViewController.h"
#import "OAOsmAndFormatter.h"
#import "OAPointDescription.h"
#import "OARootViewController.h"
#import "OASavingTrackHelper.h"
#import "OASelectedGPXHelper.h"
#import "OATargetPointsHelper.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"
#import "OsmAndSharedWrapper.h"
#import <QuartzCore/QuartzCore.h>

#include <OsmAndCore/Utilities.h>

@implementation OAFavoriteFolderBridgeItem

- (instancetype)initWithGroup:(OAFavoriteGroup *)group index:(NSUInteger)index lastModifiedDate:(nullable NSDate *)lastModifiedDate fileSize:(long long)fileSize
{
    self = [super init];
    if (self)
    {
        NSString *groupName = group.name ?: @"";
        _identifier = [NSString stringWithFormat:@"%@-%lu", groupName, (unsigned long)index];
        _groupName = groupName;
        _title = [OAFavoriteGroup getDisplayName:groupName] ?: groupName;
        _pointsCount = group.points.count;
        _isVisible = group.isVisible;
        _isPinned = group.isPinned;
        _color = group.color;
        _lastModifiedDate = lastModifiedDate;
        _fileSize = fileSize;
    }

    return self;
}

@end

@interface OAFavoritePointBridgeItem ()

+ (NSString *)subtitleForFavorite:(OAFavoriteItem *)favorite;
+ (NSString *)formattedDistanceForFavorite:(OAFavoriteItem *)favorite;
+ (NSString *)formattedDate:(NSDate *)date;

@end

@implementation OAFavoritePointBridgeItem

- (instancetype)initWithFavorite:(OAFavoriteItem *)favorite
{
    self = [super init];
    if (self)
    {
        _identifier = [favorite getKey] ?: @"";
        _groupName = [favorite getCategory] ?: @"";
        _title = [favorite getDisplayName] ?: @"";
        _address = [favorite getAddress];
        _distance = [self.class distanceForFavorite:favorite];
        _timestampDate = [favorite getTimestamp];
        _icon = [favorite getCompositeIcon];
        _isVisible = [favorite isVisible];
    }
    
    return self;
}

+ (nullable NSNumber *)distanceForFavorite:(OAFavoriteItem *)favorite
{
    CLLocation *location = [OsmAndApp instance].locationServices.lastKnownLocation;
    if (!location || !favorite.favorite)
        return nil;
    
    const auto &favoritePosition31 = favorite.favorite->getPosition31();
    const auto favoriteLon = OsmAnd::Utilities::get31LongitudeX(favoritePosition31.x);
    const auto favoriteLat = OsmAnd::Utilities::get31LatitudeY(favoritePosition31.y);
    const auto distance = OsmAnd::Utilities::distance(location.coordinate.longitude, location.coordinate.latitude, favoriteLon, favoriteLat);
    return @(distance);
}

+ (NSString *)subtitleForFavorite:(OAFavoriteItem *)favorite
{
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    NSString *distance = [self formattedDistanceForFavorite:favorite];
    if (distance.length > 0)
        [parts addObject:distance];

    NSString *address = [favorite getAddress];
    if (address.length > 0)
        [parts addObject:address];

    NSDate *timestamp = [favorite getTimestamp];
    if (timestamp)
        [parts addObject:[self formattedDate:timestamp]];

    return parts.count > 0 ? [parts componentsJoinedByString:@" • "] : nil;
}

+ (NSString *)formattedDistanceForFavorite:(OAFavoriteItem *)favorite
{
    CLLocation *location = [OsmAndApp instance].locationServices.lastKnownLocation;
    if (!location || !favorite.favorite)
        return nil;

    const auto &favoritePosition31 = favorite.favorite->getPosition31();
    const auto favoriteLon = OsmAnd::Utilities::get31LongitudeX(favoritePosition31.x);
    const auto favoriteLat = OsmAnd::Utilities::get31LatitudeY(favoritePosition31.y);
    const auto distance = OsmAnd::Utilities::distance(location.coordinate.longitude, location.coordinate.latitude, favoriteLon, favoriteLat);
    return [OAOsmAndFormatter getFormattedDistance:distance];
}

+ (NSString *)formattedDate:(NSDate *)date
{
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterShortStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
    });

    return [dateFormatter stringFromDate:date];
}

@end

@interface OAFavoritesSwiftHelper ()

+ (NSArray<OAFavoriteItem *> *)sortedFavoritePoints:(NSArray<OAFavoriteItem *> *)points;
+ (NSArray<OAFavoriteItem *> *)sortedFavoritePointsForGroup:(OAFavoriteGroup *)group;
+ (NSArray<OAFavoriteGroup *> *)favoriteGroupsInsideOrEqualToGroupName:(NSString *)groupName;
+ (OAFavoriteItem *)favoritePointWithIdentifier:(NSString *)identifier;
+ (OAFavoriteGroup *)favoriteGroupWithName:(NSString *)groupName;
+ (BOOL)renameFavoriteGroupTreeFromGroupName:(NSString *)sourceGroupName toGroupName:(NSString *)targetGroupName;
+ (BOOL)isGroupName:(NSString *)groupName insideOrEqualToGroupName:(NSString *)parentGroupName;
+ (NSString *)groupNameByMovingGroupName:(NSString *)groupName toParentGroupName:(NSString *)parentGroupName;
+ (NSString *)suffixForGroupName:(NSString *)groupName parentGroupName:(NSString *)parentGroupName;
+ (NSString *)lastComponentForGroupName:(NSString *)groupName;
+ (OAFavoriteGroup *)favoriteGroupForSharingGroup:(OAFavoriteGroup *)group points:(NSArray<OAFavoriteItem *> *)points;
+ (nullable NSURL *)fileURLForSharingFavoriteGroups:(NSArray<OAFavoriteGroup *> *)favoriteGroups;
+ (CLLocation *)locationForFavorite:(OAFavoriteItem *)favorite;

@end

@implementation OAFavoritesSwiftHelper

+ (NSArray<OAFavoriteFolderBridgeItem *> *)favoriteFolders
{
    NSArray<OAFavoriteGroup *> *groups = [OAFavoritesHelper getFavoriteGroups] ?: @[];
    NSDictionary<NSString *, NSDictionary<NSFileAttributeKey, id> *> *fileAttributesByGroupName = [self favoriteStorageAttributesForGroups:groups];
    NSMutableArray<OAFavoriteFolderBridgeItem *> *folders = [NSMutableArray arrayWithCapacity:groups.count];
    [groups enumerateObjectsUsingBlock:^(OAFavoriteGroup * _Nonnull group, NSUInteger index, BOOL * _Nonnull stop) {
        NSString *groupName = group.name ?: @"";
        NSDictionary<NSFileAttributeKey, id> *fileAttributes = fileAttributesByGroupName[groupName];
        NSDate *lastModifiedDate = [self lastModifiedDateForGroupName:groupName groups:groups fileAttributesByGroupName:fileAttributesByGroupName];
        long long fileSize = [fileAttributes[NSFileSize] longLongValue];
        [folders addObject:[[OAFavoriteFolderBridgeItem alloc] initWithGroup:group index:index lastModifiedDate:lastModifiedDate fileSize:fileSize]];
    }];
    
    return [folders copy];
}

+ (NSArray<OAFavoritePointBridgeItem *> *)favoritePointsForGroupName:(NSString *)groupName
{
    NSArray<OAFavoriteItem *> *points = [self sortedFavoritePointsForGroup:[self favoriteGroupWithName:groupName]];
    NSMutableArray<OAFavoritePointBridgeItem *> *items = [NSMutableArray arrayWithCapacity:points.count];
    for (OAFavoriteItem *point in points)
        [items addObject:[[OAFavoritePointBridgeItem alloc] initWithFavorite:point]];

    return items.copy;
}

+ (long long)favoriteGroupSizeForGroupName:(NSString *)groupName
{
    NSString *filePath = [OsmAndApp.instance favoritesStorageFilename:groupName ?: @""];
    NSDictionary<NSFileAttributeKey, id> *attributes = [NSFileManager.defaultManager attributesOfItemAtPath:filePath error:nil];
    return [attributes[NSFileSize] longLongValue];
}

+ (void)setFavoriteGroupVisible:(NSString *)groupName visible:(BOOL)visible
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    if (!group)
        return;

    [OAFavoritesHelper updateGroup:group visible:visible saveImmediately:YES];
}

+ (void)setFavoriteGroupPinned:(NSString *)groupName pinned:(BOOL)pinned
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    if (!group)
        return;

    [OAFavoritesHelper updateGroup:group pinned:pinned saveImmediately:YES];
}

+ (BOOL)addFavoriteGroup:(NSString *)name
         parentGroupName:(nullable NSString *)parentGroupName
                iconName:(nullable NSString *)iconName
                   color:(nullable UIColor *)color
      backgroundIconName:(nullable NSString *)backgroundIconName
{
    NSString *trimmedName = [(name ?: @"") stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *parent = parentGroupName ?: @"";
    NSString *groupName = parent.length > 0 && trimmedName.length > 0 ? [NSString stringWithFormat:@"%@/%@", parent, trimmedName] : trimmedName;
    if (groupName.length == 0 || [self favoriteGroupWithName:groupName])
        return NO;

    [OAFavoritesHelper addFavoriteGroup:groupName
                                  color:color
                               iconName:iconName
                     backgroundIconName:backgroundIconName];
    [OAFavoritesHelper saveCurrentPointsIntoFile];
    return YES;
}

+ (void)renameFavoriteGroup:(NSString *)groupName newName:(NSString *)newName
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    NSString *trimmedName = [newName stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!group || trimmedName.length == 0)
        return;

    NSString *sourceGroupName = group.name ?: @"";
    if ([sourceGroupName isEqualToString:trimmedName])
        return;

    [self renameFavoriteGroupTreeFromGroupName:sourceGroupName toGroupName:trimmedName];
}

+ (BOOL)moveFavoriteGroup:(NSString *)groupName toGroupName:(NSString *)targetGroupName
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    if (!group)
        return NO;

    NSString *sourceGroupName = group.name ?: @"";
    NSString *parentGroupName = targetGroupName ?: @"";
    if (sourceGroupName.length == 0 || [self isGroupName:parentGroupName insideOrEqualToGroupName:sourceGroupName])
        return NO;

    NSString *newGroupName = [self groupNameByMovingGroupName:sourceGroupName toParentGroupName:parentGroupName];
    if ([sourceGroupName isEqualToString:newGroupName])
        return NO;

    return [self renameFavoriteGroupTreeFromGroupName:sourceGroupName toGroupName:newGroupName];
}

+ (void)moveFavoriteItems:(NSArray *)favoriteItems toGroupName:(NSString *)targetGroupName
{
    if (favoriteItems.count == 0)
        return;

    NSString *groupName = targetGroupName ?: @"";
    NSMutableSet<NSString *> *movedGroupNames = [NSMutableSet set];
    NSMutableSet<NSString *> *movedItemKeys = [NSMutableSet set];

    for (id item in favoriteItems)
    {
        if (![item isKindOfClass:OAFavoriteFolderBridgeItem.class])
            continue;

        OAFavoriteFolderBridgeItem *folderItem = (OAFavoriteFolderBridgeItem *) item;
        OAFavoriteGroup *group = [self favoriteGroupWithName:folderItem.groupName];
        if (!group)
            continue;

        NSString *sourceGroupName = group.name ?: @"";
        if ([self moveFavoriteGroup:sourceGroupName toGroupName:groupName])
            [movedGroupNames addObject:sourceGroupName];
    }

    for (id item in favoriteItems)
    {
        if (![item isKindOfClass:OAFavoritePointBridgeItem.class])
            continue;

        OAFavoritePointBridgeItem *pointItem = (OAFavoritePointBridgeItem *) item;
        BOOL isInsideMovedGroup = NO;
        for (NSString *movedGroupName in movedGroupNames)
        {
            if ([self isGroupName:pointItem.groupName insideOrEqualToGroupName:movedGroupName])
            {
                isInsideMovedGroup = YES;
                break;
            }
        }

        if (isInsideMovedGroup)
            continue;

        OAFavoriteItem *favorite = [self favoritePointWithIdentifier:pointItem.identifier];
        if (!favorite)
            continue;

        NSString *itemKey = [favorite getKey] ?: pointItem.identifier;
        if ([movedItemKeys containsObject:itemKey])
            continue;

        if ([OAFavoritesHelper editFavoriteName:favorite
                                        newName:[favorite getDisplayName]
                                          group:groupName
                                          descr:[favorite getDescription]
                                        address:[favorite getAddress]])
            [movedItemKeys addObject:itemKey];
    }
}

+ (NSArray<NSString *> *)favoriteGroupNamesForMovingFavoriteItems:(NSArray *)favoriteItems
{
    NSMutableSet<NSString *> *selectedGroupNames = [NSMutableSet set];
    for (id item in favoriteItems)
    {
        if (![item isKindOfClass:OAFavoriteFolderBridgeItem.class])
            continue;

        OAFavoriteFolderBridgeItem *folderItem = (OAFavoriteFolderBridgeItem *) item;
        OAFavoriteGroup *group = [self favoriteGroupWithName:folderItem.groupName];
        if (group)
            [selectedGroupNames addObject:group.name ?: @""];
    }

    NSMutableArray<NSString *> *groupNames = [NSMutableArray array];
    for (OAFavoriteGroup *favoriteGroup in [OAFavoritesHelper getFavoriteGroups])
    {
        NSString *favoriteGroupName = favoriteGroup.name ?: @"";
        BOOL isInsideSelectedGroup = NO;
        for (NSString *selectedGroupName in selectedGroupNames)
        {
            if ([self isGroupName:favoriteGroupName insideOrEqualToGroupName:selectedGroupName])
            {
                isInsideSelectedGroup = YES;
                break;
            }
        }

        if (!isInsideSelectedGroup)
            [groupNames addObject:favoriteGroupName];
    }

    if (![groupNames containsObject:@""])
        [groupNames addObject:@""];

    return [groupNames copy];
}

+ (OASGpxUtilitiesPointsGroup *)pointsGroupForGroupName:(NSString *)groupName
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    if (!group)
        return nil;
    return group ? [group toPointsGroup] : nil;
}

+ (NSArray<NSString *> *)favoriteGroupsToMoveForGroupName:(NSString *)groupName
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    if (!group)
        return nil;

    NSMutableArray<NSString *> *groupNames = [NSMutableArray array];
    for (OAFavoriteGroup *favoriteGroup in [OAFavoritesHelper getFavoriteGroups])
    {
        NSString *favoriteGroupName = favoriteGroup.name ?: @"";
        if (![self isGroupName:favoriteGroupName insideOrEqualToGroupName:group.name ?: @""])
            [groupNames addObject:favoriteGroupName];
    }

    if (![groupNames containsObject:@""])
        [groupNames addObject:@""];
    
    return [groupNames copy];
}

+ (BOOL)canUseGroupWithName:(NSString *)groupName
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    return group && group.points.count > 0;
}

+ (nullable NSURL *)shareFavoriteGroupName:(NSString *)groupName
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    if (!group)
        return nil;

    OAFavoriteGroup *groupToShare = [self favoriteGroupForSharingGroup:group points:group.points.copy];
    return [self fileURLForSharingFavoriteGroups:@[groupToShare]];
}

+ (nullable NSURL *)shareFavoriteItems:(NSArray *)favoriteItems
{
    if (favoriteItems.count == 0)
        return nil;

    NSMutableDictionary<NSString *, OAFavoriteGroup *> *groupsByName = [NSMutableDictionary dictionary];
    NSMutableSet<NSString *> *sharedGroupNames = [NSMutableSet set];
    NSMutableSet<NSString *> *sharedPointKeys = [NSMutableSet set];

    for (id item in favoriteItems)
    {
        if (![item isKindOfClass:OAFavoriteFolderBridgeItem.class])
            continue;

        OAFavoriteFolderBridgeItem *folderItem = (OAFavoriteFolderBridgeItem *) item;
        OAFavoriteGroup *group = [self favoriteGroupWithName:folderItem.groupName];
        if (!group)
            continue;

        for (OAFavoriteGroup *groupToShare in [self favoriteGroupsInsideOrEqualToGroupName:group.name ?: @""])
        {
            NSString *sourceGroupName = groupToShare.name ?: @"";
            if (groupsByName[sourceGroupName])
                continue;

            groupsByName[sourceGroupName] = [self favoriteGroupForSharingGroup:groupToShare points:groupToShare.points.copy];
            [sharedGroupNames addObject:sourceGroupName];
            for (OAFavoriteItem *point in groupToShare.points)
            {
                NSString *pointKey = [point getKey];
                if (pointKey.length > 0)
                    [sharedPointKeys addObject:pointKey];
            }
        }
    }

    for (id item in favoriteItems)
    {
        if (![item isKindOfClass:OAFavoritePointBridgeItem.class])
            continue;

        OAFavoritePointBridgeItem *pointItem = (OAFavoritePointBridgeItem *) item;
        OAFavoriteItem *favorite = [self favoritePointWithIdentifier:pointItem.identifier];
        if (!favorite)
            continue;

        NSString *pointKey = [favorite getKey] ?: pointItem.identifier;
        if ([sharedPointKeys containsObject:pointKey])
            continue;

        NSString *groupName = [favorite getCategory] ?: @"";
        BOOL isInsideSharedGroup = NO;
        for (NSString *sharedGroupName in sharedGroupNames)
        {
            if ([self isGroupName:groupName insideOrEqualToGroupName:sharedGroupName])
            {
                isInsideSharedGroup = YES;
                break;
            }
        }

        if (isInsideSharedGroup)
            continue;

        OAFavoriteGroup *groupToShare = groupsByName[groupName];
        if (!groupToShare)
        {
            OAFavoriteGroup *sourceGroup = [self favoriteGroupWithName:groupName];
            groupToShare = sourceGroup ? [self favoriteGroupForSharingGroup:sourceGroup points:@[]] : [[OAFavoriteGroup alloc] initWithPoint:favorite];
            groupsByName[groupName] = groupToShare;
        }

        [groupToShare addPoint:favorite];
        if (pointKey.length > 0)
            [sharedPointKeys addObject:pointKey];
    }

    return [self fileURLForSharingFavoriteGroups:groupsByName.allValues];
}

+ (BOOL)deleteFavoriteGroup:(NSString *)groupName
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    if (!group)
        return NO;

    NSArray<OAFavoriteGroup *> *groupsToDelete = [self favoriteGroupsInsideOrEqualToGroupName:group.name ?: @""];
    if (groupsToDelete.count == 0)
        return NO;

    return [OAFavoritesHelper deleteFavoriteGroups:groupsToDelete andFavoritesItems:nil];
}

+ (BOOL)deleteFavoriteItems:(NSArray *)favoriteItems
{
    if (favoriteItems.count == 0)
        return NO;

    NSMutableArray<OAFavoriteGroup *> *groupsToDelete = [NSMutableArray array];
    NSMutableSet<NSString *> *deletedGroupNames = [NSMutableSet set];
    NSMutableArray<OAFavoriteItem *> *itemsToDelete = [NSMutableArray array];
    NSMutableSet<NSString *> *deletedItemKeys = [NSMutableSet set];

    for (id item in favoriteItems)
    {
        if (![item isKindOfClass:OAFavoriteFolderBridgeItem.class])
            continue;

        OAFavoriteFolderBridgeItem *folderItem = (OAFavoriteFolderBridgeItem *) item;
        OAFavoriteGroup *group = [self favoriteGroupWithName:folderItem.groupName];
        if (!group)
            continue;

        for (OAFavoriteGroup *groupToDelete in [self favoriteGroupsInsideOrEqualToGroupName:group.name ?: @""])
        {
            NSString *groupName = groupToDelete.name ?: @"";
            if ([deletedGroupNames containsObject:groupName])
                continue;

            [deletedGroupNames addObject:groupName];
            [groupsToDelete addObject:groupToDelete];
        }
    }

    for (id item in favoriteItems)
    {
        if (![item isKindOfClass:OAFavoritePointBridgeItem.class])
            continue;

        OAFavoritePointBridgeItem *pointItem = (OAFavoritePointBridgeItem *) item;
        BOOL isInsideDeletedGroup = NO;
        for (NSString *groupName in deletedGroupNames)
        {
            if ([self isGroupName:pointItem.groupName insideOrEqualToGroupName:groupName])
            {
                isInsideDeletedGroup = YES;
                break;
            }
        }

        if (isInsideDeletedGroup)
            continue;

        OAFavoriteItem *favorite = [self favoritePointWithIdentifier:pointItem.identifier];
        if (!favorite)
            continue;

        NSString *itemKey = [favorite getKey] ?: pointItem.identifier;
        if ([deletedItemKeys containsObject:itemKey])
            continue;

        [deletedItemKeys addObject:itemKey];
        [itemsToDelete addObject:favorite];
    }

    if (groupsToDelete.count == 0 && itemsToDelete.count == 0)
        return NO;

    return [OAFavoritesHelper deleteFavoriteGroups:groupsToDelete.count > 0 ? groupsToDelete : nil
                                andFavoritesItems:itemsToDelete.count > 0 ? itemsToDelete : nil];
}

+ (void)openFavoritePointWithIdentifier:(NSString *)identifier
{
    OAFavoriteItem *favorite = [self favoritePointWithIdentifier:identifier];
    if (!favorite)
        return;

    CATransition *transition = [CATransition animation];
    transition.duration = 0.4;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromRight;
    OARootViewController *rootViewController = [OARootViewController instance];
    [rootViewController.navigationController.view.layer addAnimation:transition forKey:nil];
    [rootViewController.navigationController popToRootViewControllerAnimated:NO];
    [rootViewController.navigationController setNavigationBarHidden:YES animated:NO];
    [rootViewController.mapPanel openTargetViewWithFavorite:favorite pushed:YES];
}

+ (void)addFavoriteGroupToMapMarkers:(NSString *)groupName
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    if (!group)
        return;

    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    for (OAFavoriteItem *favorite in [self sortedFavoritePointsForGroup:group])
    {
        CLLocation *location = [self locationForFavorite:favorite];
        if (!location)
            continue;

        [mapPanel addMapMarker:location.coordinate.latitude lon:location.coordinate.longitude description:[favorite getDisplayName]];
    }
}

+ (void)addFavoriteGroupToTrack:(NSString *)groupName gpxFileName:(nullable NSString *)gpxFileName
{
    NSArray<OAFavoriteItem *> *points = [self sortedFavoritePointsForGroup:[self favoriteGroupWithName:groupName]];
    if (points.count == 0)
        return;

    if (gpxFileName.length == 0)
    {
        OASavingTrackHelper *savingTrackHelper = OASavingTrackHelper.sharedInstance;
        for (OAFavoriteItem *favorite in points)
            [savingTrackHelper addWpt:[favorite toWpt]];

        if (![OAAppSettings.sharedManager.mapSettingShowRecordingTrack get])
            [OAAppSettings.sharedManager.mapSettingShowRecordingTrack set:YES];
        return;
    }

    OAGPXDatabase *gpxDatabase = OAGPXDatabase.sharedDb;
    OASGpxDataItem *dataItem = [gpxDatabase getGPXItem:gpxFileName];
    if (!dataItem)
        dataItem = [gpxDatabase getGPXItemByFileName:gpxFileName];
    if (!dataItem)
        return;

    OASGpxFile *gpxFile = [OASGpxUtilities.shared loadGpxFileFile:dataItem.file];
    if (!gpxFile)
        return;

    for (OAFavoriteItem *favorite in points)
        [gpxFile addPointPoint:[favorite toWpt]];

    [OASGpxUtilities.shared writeGpxFileFile:dataItem.file gpxFile:gpxFile];
    [gpxDatabase updateDataItem:dataItem];
    [OASelectedGPXHelper.instance markTrackForReload:[OAUtilities getGpxShortPath:dataItem.file.absolutePath]];
}

+ (void)addFavoriteGroupToNavigation:(NSString *)groupName
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    if (!group)
        return;

    NSArray<OAFavoriteItem *> *points = [self sortedFavoritePointsForGroup:group];
    if (points.count == 0)
        return;

    OATargetPointsHelper *targetPointsHelper = OATargetPointsHelper.sharedInstance;
    [targetPointsHelper clearAllPoints:NO];
    for (NSUInteger index = 0; index < points.count; index++)
    {
        OAFavoriteItem *favorite = points[index];
        CLLocation *location = [self locationForFavorite:favorite];
        if (!location)
            continue;

        OAPointDescription *description = [[OAPointDescription alloc] initWithType:POINT_TYPE_FAVORITE name:[favorite getDisplayName]];
        BOOL isDestination = index == points.count - 1;
        [targetPointsHelper navigateToPoint:location updateRoute:isDestination intermediate:isDestination ? -1 : (int)index historyName:description];
    }

    OARootViewController *rootViewController = [OARootViewController instance];
    [rootViewController.navigationController popToRootViewControllerAnimated:YES];
    [rootViewController.mapPanel showRouteInfo];
}

+ (NSArray<OAFavoriteItem *> *)sortedFavoritePoints:(NSArray<OAFavoriteItem *> *)points
{
    return [points sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem *obj1, OAFavoriteItem *obj2) {
        BOOL obj1Visible = obj1.isVisible;
        BOOL obj2Visible = obj2.isVisible;
        if (obj1Visible != obj2Visible)
            return obj1Visible ? NSOrderedAscending : NSOrderedDescending;

        return [[[obj1 getDisplayName] lowercaseString] compare:[[obj2 getDisplayName] lowercaseString]];
    }];
}

+ (NSArray<OAFavoriteItem *> *)sortedFavoritePointsForGroup:(OAFavoriteGroup *)group
{
    return [self sortedFavoritePoints:group.points ?: @[]];
}

+ (nullable NSDate *)lastModifiedDateForGroupName:(NSString *)groupName groups:(NSArray<OAFavoriteGroup *> *)groups fileAttributesByGroupName:(NSDictionary<NSString *, NSDictionary<NSFileAttributeKey, id> *> *)fileAttributesByGroupName
{
    NSDate *lastModifiedDate = nil;
    NSString *parentGroupName = groupName ?: @"";
    for (OAFavoriteGroup *favoriteGroup in groups)
    {
        NSString *currentGroupName = favoriteGroup.name ?: @"";
        if (![self isGroupName:currentGroupName insideOrEqualToGroupName:parentGroupName])
            continue;

        NSDate *fileModifiedDate = (NSDate *)fileAttributesByGroupName[currentGroupName][NSFileModificationDate];
        if (fileModifiedDate && (!lastModifiedDate || [fileModifiedDate compare:lastModifiedDate] == NSOrderedDescending))
            lastModifiedDate = fileModifiedDate;

        for (OAFavoriteItem *point in favoriteGroup.points)
        {
            NSDate *timestamp = [point getTimestamp];
            if (timestamp && (!lastModifiedDate || [timestamp compare:lastModifiedDate] == NSOrderedDescending))
                lastModifiedDate = timestamp;
        }
    }

    return lastModifiedDate;
}

+ (NSDictionary<NSString *, NSDictionary<NSFileAttributeKey, id> *> *)favoriteStorageAttributesForGroups:(NSArray<OAFavoriteGroup *> *)groups
{
    NSMutableDictionary<NSString *, NSDictionary<NSFileAttributeKey, id> *> *result = [NSMutableDictionary dictionaryWithCapacity:groups.count];
    for (OAFavoriteGroup *group in groups)
    {
        NSString *groupName = group.name ?: @"";
        NSString *filePath = [OsmAndApp.instance favoritesStorageFilename:groupName];
        NSDictionary<NSFileAttributeKey, id> *attributes = [NSFileManager.defaultManager attributesOfItemAtPath:filePath error:nil];
        if (attributes)
            result[groupName] = attributes;
    }

    return result.copy;
}

+ (NSArray<OAFavoriteGroup *> *)favoriteGroupsInsideOrEqualToGroupName:(NSString *)groupName
{
    NSMutableArray<OAFavoriteGroup *> *result = [NSMutableArray array];
    NSString *parentGroupName = groupName ?: @"";
    for (OAFavoriteGroup *favoriteGroup in [[OAFavoritesHelper getFavoriteGroups] copy])
    {
        if ([self isGroupName:favoriteGroup.name ?: @"" insideOrEqualToGroupName:parentGroupName])
            [result addObject:favoriteGroup];
    }

    return result.copy;
}

+ (OAFavoriteItem *)favoritePointWithIdentifier:(NSString *)identifier
{
    if (identifier.length == 0)
        return nil;

    for (OAFavoriteGroup *group in [OAFavoritesHelper getFavoriteGroups])
    {
        for (OAFavoriteItem *point in group.points)
        {
            if ([[point getKey] isEqualToString:identifier])
                return point;
        }
    }

    return nil;
}

+ (OAFavoriteGroup *)favoriteGroupWithName:(NSString *)groupName
{
    return [OAFavoritesHelper getGroupByName:groupName ?: @""];
}

+ (BOOL)renameFavoriteGroupTreeFromGroupName:(NSString *)sourceGroupName toGroupName:(NSString *)targetGroupName
{
    NSString *source = sourceGroupName ?: @"";
    NSString *target = targetGroupName ?: @"";
    if ([source isEqualToString:target])
        return NO;

    BOOL changed = NO;
    for (OAFavoriteGroup *favoriteGroup in [self favoriteGroupsInsideOrEqualToGroupName:source])
    {
        NSString *currentGroupName = favoriteGroup.name ?: @"";
        NSString *renamedGroupName = [target stringByAppendingString:[self suffixForGroupName:currentGroupName parentGroupName:source]];
        if ([currentGroupName isEqualToString:renamedGroupName])
            continue;

        [OAFavoritesHelper updateGroup:favoriteGroup newName:renamedGroupName saveImmediately:NO];
        changed = YES;
    }

    if (changed)
        [OAFavoritesHelper saveCurrentPointsIntoFile];

    return changed;
}

+ (BOOL)isGroupName:(NSString *)groupName insideOrEqualToGroupName:(NSString *)parentGroupName
{
    NSString *name = groupName ?: @"";
    NSString *parent = parentGroupName ?: @"";
    if ([name isEqualToString:parent])
        return YES;

    if (parent.length == 0)
        return NO;

    return [name hasPrefix:[parent stringByAppendingString:@"/"]];
}

+ (NSString *)groupNameByMovingGroupName:(NSString *)groupName toParentGroupName:(NSString *)parentGroupName
{
    NSString *name = groupName ?: @"";
    NSString *parent = parentGroupName ?: @"";
    NSString *lastComponent = [self lastComponentForGroupName:name];
    return parent.length > 0 ? [NSString stringWithFormat:@"%@/%@", parent, lastComponent] : lastComponent;
}

+ (NSString *)suffixForGroupName:(NSString *)groupName parentGroupName:(NSString *)parentGroupName
{
    NSString *name = groupName ?: @"";
    NSString *parent = parentGroupName ?: @"";
    return name.length > parent.length ? [name substringFromIndex:parent.length] : @"";
}

+ (NSString *)lastComponentForGroupName:(NSString *)groupName
{
    NSArray<NSString *> *components = [(groupName ?: @"") componentsSeparatedByString:@"/"];
    return components.lastObject ?: @"";
}

+ (OAFavoriteGroup *)favoriteGroupForSharingGroup:(OAFavoriteGroup *)group points:(NSArray<OAFavoriteItem *> *)points
{
    OAFavoriteGroup *groupToShare = [[OAFavoriteGroup alloc] initWithPoints:points ?: @[]
                                                                       name:group.name ?: @""
                                                                  isVisible:group.isVisible
                                                                      color:group.color];
    groupToShare.isPinned = group.isPinned;
    groupToShare.iconName = group.iconName;
    groupToShare.backgroundType = group.backgroundType;
    return groupToShare;
}

+ (nullable NSURL *)fileURLForSharingFavoriteGroups:(NSArray<OAFavoriteGroup *> *)favoriteGroups
{
    if (favoriteGroups.count == 0)
        return nil;

    OsmAndAppInstance app = [OsmAndApp instance];
    NSString *filename = app.favoritesFilePrefix ?: @"";
    if (favoriteGroups.count == 1)
    {
        NSString *groupFileName = [app getGroupFileName:favoriteGroups.firstObject.name ?: @""];
        filename = [NSString stringWithFormat:@"%@%@%@",
                    filename,
                    groupFileName.length > 0 ? app.favoritesGroupNameSeparator : @"",
                    groupFileName ?: @""];
    }
    filename = [filename stringByAppendingString:GPX_FILE_EXT];
    NSString *fullFilename = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    [OAFavoritesHelper saveFile:favoriteGroups file:fullFilename];
    return [NSURL fileURLWithPath:fullFilename];
}

+ (CLLocation *)locationForFavorite:(OAFavoriteItem *)favorite
{
    if (!favorite.favorite)
        return nil;

    return [[CLLocation alloc] initWithLatitude:[favorite getLatitude] longitude:[favorite getLongitude]];
}

@end
