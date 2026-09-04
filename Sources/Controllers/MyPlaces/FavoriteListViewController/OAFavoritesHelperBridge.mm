//
//  OAFavoritesHelperBridge.mm
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 05.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAFavoritesHelperBridge.h"
#import "OAAppSettings.h"
#import "OAEditPointViewController.h"
#import "OAFavoriteItem.h"
#import "OAFavoriteGroupEditorViewController.h"
#import "OAFavoritesHelper.h"
#import "OAGPXDatabase.h"
#import "OAIndexConstants.h"
#import "OALocationServices.h"
#import "OAMapActions.h"
#import "OAMapRendererView.h"
#import "OAMapViewController.h"
#import "OAMapPanelViewController.h"
#import "OAAutoObserverProxy.h"
#import "OAOpenAddTrackViewController.h"
#import "OAObservable.h"
#import "OADefaultFavorite.h"
#import "OAOsmAndFormatter.h"
#import "OAPointDescription.h"
#import "OARootViewController.h"
#import "OARTargetPoint.h"
#import "OASavingTrackHelper.h"
#import "OASelectedGPXHelper.h"
#import "OATargetPointsHelper.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"
#import "OsmAndSharedWrapper.h"
#import <QuartzCore/QuartzCore.h>
#import "OAFavoriteFolderBridgeItem.h"
#import "OAFavoritePointBridgeItem.h"

#include <OsmAndCore/Utilities.h>

static NSString * const kFavoritesStorageChangedNotification = @"FavoritesStorageChangedNotification";

@implementation OAFavoritesHelperBridge
{
    NSArray<OAFavoriteFolderBridgeItem *> *_favoriteFoldersCache;
    OAAutoObserverProxy *_favoritesStorageChangedObserver;
}

+ (OAFavoritesHelperBridge *)shared
{
    static OAFavoritesHelperBridge *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[OAFavoritesHelperBridge alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
        [self registerFavoritesStorageObserver];

    return self;
}

- (void)dealloc
{
    [_favoritesStorageChangedObserver detach];
}

- (void)invalidateFavoriteFoldersCache
{
    @synchronized (self)
    {
        _favoriteFoldersCache = nil;
    }
}

- (void)registerFavoritesStorageObserver
{
    _favoritesStorageChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                 withHandler:@selector(onFavoritesStorageChanged)
                                                                  andObserve:OAFavoritesHelper.favoritesStorageChangedObservable];
}

- (void)onFavoritesStorageChanged
{
    [self invalidateFavoriteFoldersCache];
    [self notifyFavoriteFoldersDidChange];
}

- (void)notifyFavoriteFoldersDidChange
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:
         kFavoritesStorageChangedNotification object:nil userInfo:nil];
    });
}

- (NSArray<NSString *> *)collapsedSections
{
    return [OAAppSettings.sharedManager.favoriteCollapsedSections get];
}

- (void)updateCollapsedSections:(NSArray<NSString *> *)sections
{
    [OAAppSettings.sharedManager.favoriteCollapsedSections set:sections];
}

- (NSArray<OAFavoriteFolderBridgeItem *> *)favoriteFolders
{
    @synchronized (self)
    {
        if (_favoriteFoldersCache)
            return _favoriteFoldersCache;

        NSArray<OAFavoriteGroup *> *groups = [OAFavoritesHelper favoriteGroups] ?: @[];
        NSDictionary<NSString *, NSDictionary<NSFileAttributeKey, id> *> *fileAttributesByGroupName = [self favoriteStorageAttributesForGroups:groups];
        NSMutableArray<OAFavoriteFolderBridgeItem *> *folders = [NSMutableArray arrayWithCapacity:groups.count];
        [groups enumerateObjectsUsingBlock:^(OAFavoriteGroup * _Nonnull group, NSUInteger index, BOOL * _Nonnull stop) {
            NSString *groupName = group.name;
            NSDictionary<NSFileAttributeKey, id> *fileAttributes = fileAttributesByGroupName[groupName];
            NSDate *lastModifiedDate = [self lastModifiedDateForGroupName:groupName groups:groups fileAttributesByGroupName:fileAttributesByGroupName];
            long long fileSize = [fileAttributes[NSFileSize] longLongValue];
            [folders addObject:[[OAFavoriteFolderBridgeItem alloc] initWithGroup:group index:index lastModifiedDate:lastModifiedDate fileSize:fileSize]];
        }];

        _favoriteFoldersCache = [folders copy];
        return _favoriteFoldersCache;
    }
}

- (NSArray<NSString *> *)favoriteGroupNames
{
    NSMutableArray<NSString *> *groupNames = [NSMutableArray array];
    for (OAFavoriteGroup *group in [OAFavoritesHelper favoriteGroups])
        [groupNames addObject:group.name];

    return [groupNames copy];
}

- (BOOL)hasFavoriteGroup:(NSString *)groupName
{
    return [[OAFavoritesHelper getGroups].allKeys containsObject:groupName];
}

- (NSString *)displayNameForFavoriteGroup:(NSString *)groupName
{
    return [OAFavoriteGroup getDisplayName:groupName];
}

- (NSInteger)pointsCountForFavoriteGroup:(NSString *)groupName
{
    OAFavoriteGroup *group = [OAFavoritesHelper groupByName:groupName];
    if (group)
        return group.points.count;

    return groupName.length == 0 ? [OAFavoritesHelper getFavoriteItems].count : [self subtreePointsCountForGroupName:groupName groups:[OAFavoritesHelper favoriteGroups]];
}

- (UIColor *)colorForFavoriteGroup:(NSString *)groupName
{
    OAFavoriteGroup *group = [OAFavoritesHelper groupByName:groupName];
    return group.color ?: [OADefaultFavorite getDefaultColor];
}

- (NSArray<OAFavoritePointBridgeItem *> *)favoritePointsForGroupName:(NSString *)groupName
{
    NSArray<OAFavoriteItem *> *points = [self sortedFavoritePointsForGroup:[self favoriteGroupWithName:groupName]];
    NSMutableArray<OAFavoritePointBridgeItem *> *items = [NSMutableArray arrayWithCapacity:points.count];
    for (OAFavoriteItem *point in points)
        [items addObject:[[OAFavoritePointBridgeItem alloc] initWithFavorite:point]];

    return items.copy;
}

- (NSString *)sharePoiURLStringForFavoritePoint:(OAFavoritePointBridgeItem *)favoriteItem
{
    NSMutableArray<NSString *> *query = [NSMutableArray array];
    if (favoriteItem.encodedNameForLink.length > 0)
        [query addObject:[NSString stringWithFormat:@"name=%@", favoriteItem.encodedNameForLink]];

    NSString *pin = [NSString stringWithFormat:@"%.6f%%2C%.6f", favoriteItem.latitude, favoriteItem.longitude];
    [query addObject:[NSString stringWithFormat:@"pin=%@", pin]];

    int zoom = [self currentMapZoomLevel];
    NSString *queryPart = [query componentsJoinedByString:@"&"];
    NSString *fragment = [NSString stringWithFormat:@"%d/%.4f/%.4f", zoom, favoriteItem.latitude, favoriteItem.longitude];
    return [NSString stringWithFormat:@"%@?%@#%@", kSharePoiBaseUrl, queryPart, fragment];
}

- (NSString *)geoURLStringForFavoritePoint:(OAFavoritePointBridgeItem *)favoriteItem
{
    return [OAUtilities buildGeoUrl:favoriteItem.latitude
                          longitude:favoriteItem.longitude
                               zoom:[self currentMapZoomLevel]
                              label:favoriteItem.title];
}

- (NSString *)formattedCoordinatesForFavoritePoint:(OAFavoritePointBridgeItem *)favoriteItem
{
    NSInteger format = [OAAppSettings.sharedManager.settingGeoFormat get];
    return [OAOsmAndFormatter getFormattedCoordinatesWithLat:favoriteItem.latitude
                                                         lon:favoriteItem.longitude
                                                outputFormat:format];
}

- (void)setFavoriteGroupVisible:(NSString *)groupName visible:(BOOL)visible
{
    NSArray<OAFavoriteGroup *> *groups = [self favoriteGroupsInsideOrEqualToGroupName:groupName];
    if (groups.count == 0)
        return;

    for (OAFavoriteGroup *group in groups)
    {
        [OAFavoritesHelper updateGroup:group visible:visible saveImmediately:NO];
    }

    [OAFavoritesHelper notifyFavoritesStorageChanged];
    [OAFavoritesHelper saveCurrentPointsIntoFile];
}

- (void)setFavoriteGroupPinned:(NSString *)groupName pinned:(BOOL)pinned
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    if (!group)
        return;

    [OAFavoritesHelper updateGroup:group pinned:pinned saveImmediately:NO];
    [OAFavoritesHelper notifyFavoritesStorageChanged];
    [OAFavoritesHelper saveCurrentPointsIntoFile];
}

- (void)setFavoriteGroupsVisible:(NSArray<NSString *> *)groupNames visible:(BOOL)visible
{
    if (groupNames.count == 0)
        return;

    BOOL changed = NO;
    NSMutableSet<NSString *> *handledGroupNames = [NSMutableSet set];
    for (NSString *groupName in groupNames)
    {
        for (OAFavoriteGroup *group in [self favoriteGroupsInsideOrEqualToGroupName:groupName])
        {
            NSString *currentGroupName = group.name;
            if ([handledGroupNames containsObject:currentGroupName])
                continue;

            [handledGroupNames addObject:currentGroupName];
            [OAFavoritesHelper updateGroup:group visible:visible saveImmediately:NO];
            changed = YES;
        }
    }

    if (changed)
    {
        [OAFavoritesHelper notifyFavoritesStorageChanged];
        [OAFavoritesHelper saveCurrentPointsIntoFile];
    }
}

- (void)setFavoriteGroupsPinned:(NSArray<NSString *> *)groupNames pinned:(BOOL)pinned
{
    if (groupNames.count == 0)
        return;

    BOOL changed = NO;
    NSMutableSet<NSString *> *handledGroupNames = [NSMutableSet set];
    for (NSString *groupName in groupNames)
    {
        OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
        if (!group)
            continue;

        [handledGroupNames addObject:groupName];
        [OAFavoritesHelper updateGroup:group pinned:pinned saveImmediately:NO];
        changed = YES;
    }

    if (changed)
    {
        [OAFavoritesHelper notifyFavoritesStorageChanged];
        [OAFavoritesHelper saveCurrentPointsIntoFile];
    }
}

- (BOOL)addFavoriteGroup:(NSString *)name
         parentGroupName:(nullable NSString *)parentGroupName
                iconName:(nullable NSString *)iconName
                   color:(nullable UIColor *)color
      backgroundIconName:(nullable NSString *)backgroundIconName
{
    NSString *trimmedName = [(name ?: @"") stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if ([trimmedName containsString:@"/"] || [trimmedName containsString:SUBFOLDER_PLACEHOLDER])
        return NO;

    NSString *parent = parentGroupName ?: @"";
    NSString *groupName = parent.length > 0 && trimmedName.length > 0 ? [NSString stringWithFormat:@"%@/%@", parent, trimmedName] : trimmedName;
    if (groupName.length == 0 || [OAFavoritesHelper groupByTrimmedName:groupName])
        return NO;

    [OAFavoritesHelper addFavoriteGroup:groupName
                                  color:color
                               iconName:iconName
                     backgroundIconName:backgroundIconName];
    [OAFavoritesHelper notifyFavoritesStorageChanged];
    [OAFavoritesHelper saveCurrentPointsIntoFile];
    return YES;
}

- (BOOL)renameFavoriteGroup:(NSString *)groupName newName:(NSString *)newName
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    NSString *targetGroupName = newName ?: @"";
    for (NSString *segment in [targetGroupName componentsSeparatedByString:@"/"])
        if (segment.length == 0 || [segment containsString:SUBFOLDER_PLACEHOLDER])
            return NO;

    NSString *sourceGroupName = group ? group.name : (groupName ?: @"");
    if ([sourceGroupName isEqualToString:targetGroupName] || (sourceGroupName.length > 0 && [self isGroupName:targetGroupName insideOrEqualToGroupName:sourceGroupName]))
        return NO;

    BOOL targetExists = sourceGroupName.length == 0 ? [OAFavoritesHelper groupByName:targetGroupName] != nil : [[self allFavoriteFolderPaths] containsObject:targetGroupName];
    if (targetExists)
        return NO;

    return [self renameFavoriteGroupTreeFromGroupName:sourceGroupName toGroupName:targetGroupName];
}

- (BOOL)moveFavoriteGroup:(NSString *)groupName toGroupName:(NSString *)targetGroupName
{
    NSString *sourceGroupName = groupName ?: @"";
    NSString *parentGroupName = targetGroupName ?: @"";
    if (sourceGroupName.length == 0 || [self isGroupName:parentGroupName insideOrEqualToGroupName:sourceGroupName])
        return NO;

    NSString *newGroupName = [self groupNameByMovingGroupName:sourceGroupName toParentGroupName:parentGroupName];
    if ([sourceGroupName isEqualToString:newGroupName])
        return NO;

    return [self renameFavoriteGroupTreeFromGroupName:sourceGroupName toGroupName:newGroupName notifyAndSave:NO];
}

- (BOOL)moveFavoriteItems:(NSArray *)favoriteItems toGroupName:(NSString *)targetGroupName
{
    if (favoriteItems.count == 0)
        return NO;

    NSString *groupName = targetGroupName ?: @"";
    NSMutableSet<NSString *> *movedItemKeys = [NSMutableSet set];
    BOOL movedGroups = NO;
    BOOL movedPoints = NO;

    NSSet<NSString *> *allFolderPaths = [self allFavoriteFolderPaths];
    if (groupName.length > 0 && ![allFolderPaths containsObject:groupName])
        return NO;

    NSMutableArray<NSString *> *selectedFolderPaths = [NSMutableArray array];
    for (id item in favoriteItems)
    {
        if ([item isKindOfClass:NSString.class] && ((NSString *) item).length > 0)
            [selectedFolderPaths addObject:(NSString *) item];
    }

    NSArray<NSString *> *movedFolderPaths = [self topLevelFavoriteFolderPaths:selectedFolderPaths];
    NSMutableSet<NSString *> *targetRootPaths = [NSMutableSet set];
    for (NSString *sourcePath in movedFolderPaths)
    {
        if (![allFolderPaths containsObject:sourcePath] || [self isGroupName:groupName insideOrEqualToGroupName:sourcePath])
            return NO;

        NSString *targetPath = [self groupNameByMovingGroupName:sourcePath toParentGroupName:groupName];
        if ([targetRootPaths containsObject:targetPath] || (![sourcePath isEqualToString:targetPath] && [allFolderPaths containsObject:targetPath]))
            return NO;

        [targetRootPaths addObject:targetPath];
    }

    for (NSString *sourcePath in movedFolderPaths)
    {
        if ([self moveFavoriteGroup:sourcePath toGroupName:groupName])
            movedGroups = YES;
    }

    for (id item in favoriteItems)
    {
        if (![item isKindOfClass:OAFavoritePointBridgeItem.class])
            continue;

        OAFavoritePointBridgeItem *pointItem = (OAFavoritePointBridgeItem *) item;
        BOOL isInsideMovedGroup = NO;
        for (NSString *movedGroupName in movedFolderPaths)
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
        {
            [movedItemKeys addObject:itemKey];
            movedPoints = YES;
        }
    }

    if (movedGroups || movedPoints)
    {
        [OAFavoritesHelper notifyFavoritesStorageChanged];
        if (movedGroups)
            [OAFavoritesHelper saveCurrentPointsIntoFile];
    }

    return movedFolderPaths.count > 0 || movedPoints;
}

- (NSArray<NSString *> *)favoriteGroupNamesForMovingFavoriteItems:(NSArray *)favoriteItems
{
    NSMutableSet<NSString *> *selectedGroupNames = [NSMutableSet set];
    for (id item in favoriteItems)
    {
        if ([item isKindOfClass:NSString.class])
            [selectedGroupNames addObject:(NSString *) item];
    }

    NSMutableArray<NSString *> *groupNames = [NSMutableArray array];
    for (NSString *favoriteGroupName in [self allFavoriteFolderPaths])
    {
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

    return [groupNames copy];
}

- (void)changeFavoriteItems:(NSArray *)favoriteItems colorIndex:(NSInteger)colorIndex
{
    if (favoriteItems.count == 0)
        return;

    NSArray<OAFavoriteColor *> *builtinColors = [OADefaultFavorite builtinColors];
    if (colorIndex < 0 || colorIndex >= builtinColors.count)
        return;

    UIColor *color = builtinColors[colorIndex].color;
    BOOL changed = NO;
    NSMutableSet<NSString *> *changedPointKeys = [NSMutableSet set];

    for (id item in favoriteItems)
    {
        if (![item isKindOfClass:NSString.class])
            continue;

        NSString *folderPath = (NSString *) item;
        OAFavoriteGroup *group = [self favoriteGroupWithName:folderPath];
        if (!group)
            continue;

        group.color = color;
        changed = YES;
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
        if ([changedPointKeys containsObject:pointKey])
            continue;

        [favorite setColor:color];
        [changedPointKeys addObject:pointKey];
        changed = YES;

        OAFavoriteGroup *group = [self favoriteGroupWithName:[favorite getCategory]];
        OAFavoriteItem *firstPoint = group.points.firstObject;
        if (firstPoint && ([[firstPoint getKey] isEqualToString:pointKey]))
            group.color = color;
    }

    if (changed)
    {
        [OAFavoritesHelper notifyFavoritesStorageChanged];
        [OAFavoritesHelper saveCurrentPointsIntoFile];
    }
}

- (OASGpxUtilitiesPointsGroup *)pointsGroupForGroupName:(NSString *)groupName
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    if (!group)
        return nil;
    return group ? [group toPointsGroup] : nil;
}

- (BOOL)canUseGroupWithName:(NSString *)groupName
{
    return [self favoriteItemsInsideOrEqualToGroupName:groupName].count > 0;
}

- (NSURL *)shareFavoriteItems:(NSArray *)favoriteItems
{
    if (favoriteItems.count == 0)
        return nil;

    NSMutableDictionary<NSString *, OAFavoriteGroup *> *groupsByName = [NSMutableDictionary dictionary];
    NSMutableSet<NSString *> *sharedGroupNames = [NSMutableSet set];
    NSMutableSet<NSString *> *sharedPointKeys = [NSMutableSet set];

    for (id item in favoriteItems)
    {
        if (![item isKindOfClass:NSString.class])
            continue;

        NSString *folderPath = (NSString *) item;
        for (OAFavoriteGroup *groupToShare in [self favoriteGroupsInsideOrEqualToGroupName:folderPath])
        {
            NSString *sourceGroupName = groupToShare.name;
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

- (BOOL)deleteFavoriteGroup:(NSString *)groupName
{
    NSArray<OAFavoriteGroup *> *groupsToDelete = [self favoriteGroupsInsideOrEqualToGroupName:groupName];
    if (groupsToDelete.count == 0)
        return NO;

    BOOL didDelete = [OAFavoritesHelper deleteFavoriteGroups:groupsToDelete andFavoritesItems:nil];
    return didDelete;
}

- (BOOL)deleteFavoritePoint:(OAFavoritePointBridgeItem *)favoriteItem
{
    OAFavoriteItem *favorite = [self favoritePointWithIdentifier:favoriteItem.identifier];
    if (!favorite)
        return NO;

    [OAFavoritesHelper deleteFavorites:@[favorite] saveImmediately:NO];
    [OAFavoritesHelper notifyFavoritesStorageChanged];
    [OAFavoritesHelper saveCurrentPointsIntoFile];
    return YES;
}

- (BOOL)deleteFavoriteItems:(NSArray *)favoriteItems
{
    if (favoriteItems.count == 0)
        return NO;

    NSMutableArray<OAFavoriteGroup *> *groupsToDelete = [NSMutableArray array];
    NSMutableSet<NSString *> *deletedGroupNames = [NSMutableSet set];
    NSMutableArray<OAFavoriteItem *> *itemsToDelete = [NSMutableArray array];
    NSMutableSet<NSString *> *deletedItemKeys = [NSMutableSet set];

    for (id item in favoriteItems)
    {
        if (![item isKindOfClass:NSString.class])
            continue;

        NSString *folderPath = (NSString *) item;
        for (OAFavoriteGroup *groupToDelete in [self favoriteGroupsInsideOrEqualToGroupName:folderPath])
        {
            NSString *groupName = groupToDelete.name;
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

    BOOL didDelete = NO;
    if (groupsToDelete.count > 0)
        didDelete = [OAFavoritesHelper deleteFavoriteGroups:groupsToDelete andFavoritesItems:nil] || didDelete;

    if (itemsToDelete.count > 0)
    {
        [OAFavoritesHelper deleteFavorites:itemsToDelete saveImmediately:NO];
        [OAFavoritesHelper notifyFavoritesStorageChanged];
        [OAFavoritesHelper saveCurrentPointsIntoFile];
        didDelete = YES;
    }

    return didDelete;
}

- (void)openFavoritePointWithIdentifier:(NSString *)identifier
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

- (OAEditPointViewController *)editPointViewControllerForFavoritePoint:(OAFavoritePointBridgeItem *)favoriteItem
{
    OAFavoriteItem *favorite = [self favoritePointWithIdentifier:favoriteItem.identifier];
    if (!favorite)
        return nil;

    return [[OAEditPointViewController alloc] initWithFavorite:favorite];
}

- (void)addFavoriteItemsToMapMarkers:(NSArray *)favoriteItems
{
    if (favoriteItems.count == 0)
        return;

    NSArray<OAFavoriteItem *> *itemsToAdd = [self favoriteItemsForBridgeItemsToAdd:favoriteItems standalonePointItems:NO];
    if (itemsToAdd.count == 0)
        return;

    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    BOOL addedMarker = NO;
    for (OAFavoriteItem *favorite in itemsToAdd)
    {
        CLLocation *location = [self locationForFavorite:favorite];
        if (!location)
            continue;

        [mapPanel addMapMarker:location.coordinate.latitude lon:location.coordinate.longitude description:[favorite getDisplayName]];
        addedMarker = YES;
    }

    if (addedMarker)
        [mapPanel showDestinations];
}

- (void)addFavoriteGroupToTrack:(NSString *)groupName gpxFileName:(nullable NSString *)gpxFileName
{
    NSArray<OAFavoriteItem *> *points = [self favoriteItemsInsideOrEqualToGroupName:groupName];
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
    [OASelectedGPXHelper.instance markTrackForReload:dataItem.file.absolutePath];
    [OsmAndApp.instance.updateGpxTracksOnMapObservable notifyEvent];
}

- (void)addFavoriteGroupToNavigation:(NSString *)groupName
{
    NSArray<OAFavoriteItem *> *points = [self favoriteItemsInsideOrEqualToGroupName:groupName];
    NSMutableArray<OAFavoritePointBridgeItem *> *items = [NSMutableArray arrayWithCapacity:points.count];
    for (OAFavoriteItem *point in points)
    {
        [items addObject:[[OAFavoritePointBridgeItem alloc] initWithFavorite:point]];
    }

    [self addFavoriteItemsToNavigation:items];
}

- (void)addFavoriteItemsToTrack:(NSArray *)favoriteItems gpxFileName:(nullable NSString *)gpxFileName
{
    if (favoriteItems.count == 0)
        return;

    NSArray<OAFavoriteItem *> *itemsToAdd = [self favoriteItemsForBridgeItemsToAdd:favoriteItems standalonePointItems:YES];
    if (itemsToAdd.count == 0)
        return;

    if (gpxFileName.length == 0)
    {
        OASavingTrackHelper *savingTrackHelper = [OASavingTrackHelper sharedInstance];
        for (OAFavoriteItem *favorite in itemsToAdd)
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

    for (OAFavoriteItem *favorite in itemsToAdd)
        [gpxFile addPointPoint:[favorite toWpt]];

    [OASGpxUtilities.shared writeGpxFileFile:dataItem.file gpxFile:gpxFile];
    [gpxDatabase updateDataItem:dataItem];
    [OASelectedGPXHelper.instance markTrackForReload:dataItem.file.absolutePath];
    [[[OsmAndApp instance] updateGpxTracksOnMapObservable] notifyEvent];
}

- (void)addFavoriteItemsToNavigation:(NSArray *)favoriteItems
{
    if (favoriteItems.count == 0)
        return;

    NSArray<OAFavoriteItem *> *itemsToAdd = [self favoriteItemsForBridgeItemsToAdd:favoriteItems standalonePointItems:NO];
    if (itemsToAdd.count == 0)
        return;

    NSMutableArray<OARTargetPoint *> *targetPoints = [NSMutableArray arrayWithCapacity:itemsToAdd.count];
    for (OAFavoriteItem *favorite in itemsToAdd)
    {
        CLLocation *location = [self locationForFavorite:favorite];
        if (!location)
            continue;

        OAPointDescription *description = [[OAPointDescription alloc] initWithType:POINT_TYPE_FAVORITE name:[favorite getDisplayName]];
        OARTargetPoint *targetPoint = [OARTargetPoint create:location name:description];
        if (targetPoint)
            [targetPoints addObject:targetPoint];
    }

    if (targetPoints.count == 0)
        return;

    OATargetPointsHelper *targetPointsHelper = [OATargetPointsHelper sharedInstance];
    [targetPointsHelper clearAllPoints:NO];
    [targetPointsHelper reorderAllTargetPoints:targetPoints updateRoute:NO];
    OARootViewController *rootViewController = [OARootViewController instance];
    [rootViewController.navigationController popToRootViewControllerAnimated:YES];
    [rootViewController.mapPanel.mapActions enterRoutePlanningModeGivenGpx:nil
                                                                      from:nil
                                                                  fromName:nil
                                            useIntermediatePointsByDefault:YES
                                                                showDialog:YES];
}

- (NSArray<OAFavoriteItem *> *)sortedFavoritePoints:(NSArray<OAFavoriteItem *> *)points
{
    return [points sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem *obj1, OAFavoriteItem *obj2) {
        BOOL obj1Visible = obj1.isVisible;
        BOOL obj2Visible = obj2.isVisible;
        if (obj1Visible != obj2Visible)
            return obj1Visible ? NSOrderedAscending : NSOrderedDescending;

        return [[[obj1 getDisplayName] lowercaseString] compare:[[obj2 getDisplayName] lowercaseString]];
    }];
}

- (NSArray<OAFavoriteItem *> *)sortedFavoritePointsForGroup:(OAFavoriteGroup *)group
{
    return [self sortedFavoritePoints:group.points ?: @[]];
}

- (NSArray<OAFavoriteItem *> *)favoriteItemsForBridgeItemsToAdd:(NSArray *)favoriteItems standalonePointItems:(BOOL)standalonePointItems
{
    NSMutableArray<OAFavoriteItem *> *result = [NSMutableArray array];
    NSMutableSet<NSString *> *addedPointKeys = [NSMutableSet set];

    for (id item in favoriteItems)
    {
        if (![item isKindOfClass:NSString.class])
            continue;

        NSString *folderPath = (NSString *) item;
        [self addFavoriteItemsInsideOrEqualToGroupName:folderPath toArray:result addedPointKeys:addedPointKeys];
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
        OAFavoriteItem *favoriteToAdd = standalonePointItems ? [self standaloneFavoritePoint:favorite] : favorite;
        [self addFavoriteItem:favoriteToAdd pointKey:pointKey toArray:result addedPointKeys:addedPointKeys];
    }

    return [result copy];
}

- (NSArray<OAFavoriteItem *> *)favoriteItemsInsideOrEqualToGroupName:(NSString *)groupName
{
    NSMutableArray<OAFavoriteItem *> *result = [NSMutableArray array];
    NSMutableSet<NSString *> *addedPointKeys = [NSMutableSet set];
    [self addFavoriteItemsInsideOrEqualToGroupName:groupName toArray:result addedPointKeys:addedPointKeys];
    return [result copy];
}

- (void)addFavoriteItemsInsideOrEqualToGroupName:(NSString *)groupName
                                        toArray:(NSMutableArray<OAFavoriteItem *> *)result
                                 addedPointKeys:(NSMutableSet<NSString *> *)addedPointKeys
{
    for (OAFavoriteGroup *group in [self favoriteGroupsInsideOrEqualToGroupName:groupName])
    {
        for (OAFavoriteItem *favorite in [self sortedFavoritePointsForGroup:group])
            [self addFavoriteItem:favorite pointKey:[favorite getKey] toArray:result addedPointKeys:addedPointKeys];
    }
}

- (void)addFavoriteItem:(OAFavoriteItem *)favorite
               pointKey:(NSString *)pointKey
                toArray:(NSMutableArray<OAFavoriteItem *> *)result
         addedPointKeys:(NSMutableSet<NSString *> *)addedPointKeys
{
    if (!favorite)
        return;

    if (pointKey.length > 0 && [addedPointKeys containsObject:pointKey])
        return;

    if (pointKey.length > 0)
        [addedPointKeys addObject:pointKey];
    [result addObject:favorite];
}

- (NSDate *)lastModifiedDateForGroupName:(NSString *)groupName groups:(NSArray<OAFavoriteGroup *> *)groups fileAttributesByGroupName:(NSDictionary<NSString *, NSDictionary<NSFileAttributeKey, id> *> *)fileAttributesByGroupName
{
    NSDate *lastModifiedDate = nil;
    QString lastTimestamp;
    NSString *parentGroupName = groupName ?: @"";
    for (OAFavoriteGroup *favoriteGroup in groups)
    {
        NSString *currentGroupName = favoriteGroup.name;
        if (![self isGroupName:currentGroupName insideOrEqualToGroupName:parentGroupName])
            continue;

        NSDate *fileModifiedDate = (NSDate *)fileAttributesByGroupName[currentGroupName][NSFileModificationDate];
        if (fileModifiedDate && (!lastModifiedDate || [fileModifiedDate compare:lastModifiedDate] == NSOrderedDescending))
            lastModifiedDate = fileModifiedDate;

        for (OAFavoriteItem *point in favoriteGroup.points)
        {
            const auto timestamp = point.favorite->getTime();
            if (timestamp.isNull())
                continue;

            if (lastTimestamp.isNull() || timestamp.compare(lastTimestamp) > 0)
                lastTimestamp = timestamp;
        }
    }

    if (!lastTimestamp.isNull())
    {
        NSDate *timestamp = [[self favoriteTimestampFormatter] dateFromString:lastTimestamp.toNSString()];
        if (timestamp && (!lastModifiedDate || [timestamp compare:lastModifiedDate] == NSOrderedDescending))
            lastModifiedDate = timestamp;
    }

    return lastModifiedDate;
}

- (NSISO8601DateFormatter *)favoriteTimestampFormatter
{
    static NSISO8601DateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSISO8601DateFormatter new];
        formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    });
    return formatter;
}

- (NSUInteger)subtreePointsCountForGroupName:(NSString *)groupName groups:(NSArray<OAFavoriteGroup *> *)groups
{
    NSUInteger pointsCount = 0;
    NSString *parentGroupName = groupName ?: @"";
    for (OAFavoriteGroup *favoriteGroup in groups)
    {
        if ([self isGroupName:favoriteGroup.name insideOrEqualToGroupName:parentGroupName])
            pointsCount += favoriteGroup.points.count;
    }
    
    return pointsCount;
}

- (NSDictionary<NSString *, NSDictionary<NSFileAttributeKey, id> *> *)favoriteStorageAttributesForGroups:(NSArray<OAFavoriteGroup *> *)groups
{
    NSMutableDictionary<NSString *, NSDictionary<NSFileAttributeKey, id> *> *result = [NSMutableDictionary dictionaryWithCapacity:groups.count];
    for (OAFavoriteGroup *group in groups)
    {
        NSString *groupName = group.name;
        NSString *filePath = [OsmAndApp.instance favoritesStorageFilename:groupName];
        NSDictionary<NSFileAttributeKey, id> *attributes = [NSFileManager.defaultManager attributesOfItemAtPath:filePath error:nil];
        if (attributes)
            result[groupName] = attributes;
    }

    return result.copy;
}

- (NSArray<OAFavoriteGroup *> *)favoriteGroupsInsideOrEqualToGroupName:(NSString *)groupName
{
    NSMutableArray<OAFavoriteGroup *> *result = [NSMutableArray array];
    NSString *parentGroupName = groupName ?: @"";
    for (OAFavoriteGroup *favoriteGroup in [[OAFavoritesHelper favoriteGroups] copy])
    {
        if ([self isGroupName:favoriteGroup.name insideOrEqualToGroupName:parentGroupName])
            [result addObject:favoriteGroup];
    }

    return result.copy;
}

- (OAFavoriteItem *)favoritePointWithIdentifier:(NSString *)identifier
{
    if (identifier.length == 0)
        return nil;

    for (OAFavoriteGroup *group in [OAFavoritesHelper favoriteGroups])
    {
        for (OAFavoriteItem *point in group.points)
        {
            if ([[point getKey] isEqualToString:identifier])
                return point;
        }
    }

    return nil;
}

- (OAFavoriteGroup *)favoriteGroupWithName:(NSString *)groupName
{
    return [OAFavoritesHelper groupByName:groupName ?: @""];
}

- (BOOL)renameFavoriteGroupTreeFromGroupName:(NSString *)sourceGroupName toGroupName:(NSString *)targetGroupName
{
    return [self renameFavoriteGroupTreeFromGroupName:sourceGroupName toGroupName:targetGroupName notifyAndSave:YES];
}

- (BOOL)renameFavoriteGroupTreeFromGroupName:(NSString *)sourceGroupName toGroupName:(NSString *)targetGroupName notifyAndSave:(BOOL)notifyAndSave
{
    NSString *source = sourceGroupName ?: @"";
    NSString *target = targetGroupName ?: @"";
    if ([source isEqualToString:target])
        return NO;

    BOOL changed = NO;
    for (OAFavoriteGroup *favoriteGroup in [self favoriteGroupsInsideOrEqualToGroupName:source])
    {
        NSString *currentGroupName = favoriteGroup.name;
        NSString *renamedGroupName = [target stringByAppendingString:[self suffixForGroupName:currentGroupName parentGroupName:source]];
        if ([currentGroupName isEqualToString:renamedGroupName])
            continue;

        [OAFavoritesHelper updateGroup:favoriteGroup newName:renamedGroupName saveImmediately:NO];
        changed = YES;
    }

    if (changed && notifyAndSave)
    {
        [OAFavoritesHelper notifyFavoritesStorageChanged];
        [OAFavoritesHelper saveCurrentPointsIntoFile];
    }

    return changed;
}

- (BOOL)isGroupName:(NSString *)groupName insideOrEqualToGroupName:(NSString *)parentGroupName
{
    NSString *name = groupName ?: @"";
    NSString *parent = parentGroupName ?: @"";
    if ([name isEqualToString:parent])
        return YES;

    if (parent.length == 0)
        return NO;

    return [name hasPrefix:[parent stringByAppendingString:@"/"]];
}

- (NSString *)groupNameByMovingGroupName:(NSString *)groupName toParentGroupName:(NSString *)parentGroupName
{
    NSString *lastComponent = [self lastComponentForGroupName:groupName];
    return !parentGroupName || parentGroupName.length == 0 ? lastComponent : [NSString stringWithFormat:@"%@/%@", parentGroupName, lastComponent];
}

- (NSString *)suffixForGroupName:(NSString *)groupName parentGroupName:(NSString *)parentGroupName
{
    NSString *name = groupName ?: @"";
    NSString *parent = parentGroupName ?: @"";
    return name.length > parent.length ? [name substringFromIndex:parent.length] : @"";
}

- (NSString *)lastComponentForGroupName:(NSString *)groupName
{
    NSArray<NSString *> *components = [(groupName ?: @"") componentsSeparatedByString:@"/"];
    return components.lastObject ?: @"";
}

- (NSSet<NSString *> *)allFavoriteFolderPaths
{
    NSMutableSet<NSString *> *folderPaths = [NSMutableSet setWithObject:@""];
    for (OAFavoriteGroup *favoriteGroup in [OAFavoritesHelper favoriteGroups])
    {
        NSString *currentPath = @"";
        for (NSString *segment in [favoriteGroup.name componentsSeparatedByString:@"/"])
        {
            if (segment.length == 0)
                continue;

            currentPath = currentPath.length == 0 ? segment : [NSString stringWithFormat:@"%@/%@", currentPath, segment];
            [folderPaths addObject:currentPath];
        }
    }

    return folderPaths.copy;
}

- (NSArray<NSString *> *)topLevelFavoriteFolderPaths:(NSArray<NSString *> *)folderPaths
{
    NSArray<NSString *> *uniquePaths = [NSOrderedSet orderedSetWithArray:folderPaths].array;
    NSMutableArray<NSString *> *result = [NSMutableArray array];
    for (NSString *path in uniquePaths)
    {
        BOOL isInsideSelectedFolder = NO;
        for (NSString *otherPath in uniquePaths)
        {
            if (![path isEqualToString:otherPath] && [self isGroupName:path insideOrEqualToGroupName:otherPath])
            {
                isInsideSelectedFolder = YES;
                break;
            }
        }
        if (!isInsideSelectedFolder)
            [result addObject:path];
    }

    return result.copy;
}

- (OAFavoriteGroup *)favoriteGroupForSharingGroup:(OAFavoriteGroup *)group points:(NSArray<OAFavoriteItem *> *)points
{
    OAFavoriteGroup *groupToShare = [[OAFavoriteGroup alloc] initWithPoints:points ?: @[]
                                                                       name:group.name
                                                                  isVisible:group.isVisible
                                                                      color:group.color];
    groupToShare.isPinned = group.isPinned;
    groupToShare.iconName = group.iconName;
    groupToShare.backgroundType = group.backgroundType;
    return groupToShare;
}

- (NSURL *)fileURLForSharingFavoriteGroups:(NSArray<OAFavoriteGroup *> *)favoriteGroups
{
    if (favoriteGroups.count == 0)
        return nil;

    OsmAndAppInstance app = [OsmAndApp instance];
    NSString *filename = app.favoritesFilePrefix ?: @"";
    if (favoriteGroups.count == 1)
    {
        NSString *groupFileName = [app getGroupFileName:favoriteGroups.firstObject.name];
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

- (CLLocation *)locationForFavorite:(OAFavoriteItem *)favorite
{
    if (!favorite.favorite)
        return nil;

    return [[CLLocation alloc] initWithLatitude:[favorite getLatitude] longitude:[favorite getLongitude]];
}

- (int)currentMapZoomLevel
{
    return [OARootViewController instance].mapPanel.mapViewController.mapView.zoomLevel;
}

- (OAFavoriteItem *)standaloneFavoritePoint:(OAFavoriteItem *)favorite
{
    OASWptPt *point = [favorite toWpt];
    point.category = nil;
    return [OAFavoriteItem fromWpt:point category:@""];
}

@end
