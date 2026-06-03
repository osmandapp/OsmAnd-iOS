//
//  FavoriteFoldersBridge.mm
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 03.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "FavoriteFoldersBridge.h"
#import "Localization.h"
#import "OAAppSettings.h"
#import "OAEditGroupViewController.h"
#import "OAFavoriteItem.h"
#import "OAFavoriteGroupEditorViewController.h"
#import "OAFavoritesHelper.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocumentPrimitives.h"
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
#import "OsmAndApp.h"
#import "OsmAnd_Maps-Swift.h"

#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

static NSString * const FavoriteFoldersBridgeGroupsDidChangeNotification = @"FavoriteFoldersBridgeGroupsDidChangeNotification";

@interface FavoriteFolderBridgeItem ()

- (instancetype)initWithGroup:(OAFavoriteGroup *)group index:(NSUInteger)index;

@end

@implementation FavoriteFolderBridgeItem

- (instancetype)initWithGroup:(OAFavoriteGroup *)group index:(NSUInteger)index
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
    }
    return self;
}

@end

@interface FavoritePointBridgeItem ()

- (instancetype)initWithFavorite:(OAFavoriteItem *)favorite;
+ (NSString *)subtitleForFavorite:(OAFavoriteItem *)favorite;
+ (NSString *)formattedDistanceForFavorite:(OAFavoriteItem *)favorite;
+ (NSString *)formattedDate:(NSDate *)date;

@end

@interface FavoriteFoldersBridge ()

+ (NSArray<OAFavoriteItem *> *)sortedFavoritePoints:(NSArray<OAFavoriteItem *> *)points;
+ (OAFavoriteItem *)favoritePointWithIdentifier:(NSString *)identifier;
+ (OAFavoriteGroup *)favoriteGroupWithName:(NSString *)groupName;
+ (BOOL)moveFavoriteGroup:(NSString *)groupName toGroupName:(NSString *)targetGroupName;
+ (BOOL)isGroupName:(NSString *)groupName insideOrEqualToGroupName:(NSString *)parentGroupName;
+ (NSString *)groupNameByMovingGroupName:(NSString *)groupName toParentGroupName:(NSString *)parentGroupName;
+ (NSString *)lastComponentForGroupName:(NSString *)groupName;
+ (void)notifyFavoriteGroupsChanged;
+ (void)addFavoriteGroupToTrack:(NSString *)groupName gpxFileName:(NSString *)gpxFileName;
+ (CLLocation *)locationForFavorite:(OAFavoriteItem *)favorite;

@end

@interface FavoriteGroupMoveDelegate : NSObject <OAEditGroupViewControllerDelegate>

@property (nonatomic, copy) NSString *groupName;
@property (nonatomic, weak) OAEditGroupViewController *controller;

@end

@implementation FavoriteGroupMoveDelegate

- (void)groupChanged
{
    if (self.controller.saveChanges)
    {
        if ([FavoriteFoldersBridge moveFavoriteGroup:self.groupName toGroupName:self.controller.groupName])
            [FavoriteFoldersBridge notifyFavoriteGroupsChanged];
    }
}

@end

@interface FavoriteGroupAddToTrackDelegate : NSObject <OAOpenAddTrackDelegate>

@property (nonatomic, copy) NSString *groupName;

@end

@implementation FavoriteGroupAddToTrackDelegate

- (void)onFileSelected:(NSString *)gpxFileName
{
    [FavoriteFoldersBridge addFavoriteGroupToTrack:self.groupName gpxFileName:gpxFileName];
}

@end

@implementation FavoritePointBridgeItem

- (instancetype)initWithFavorite:(OAFavoriteItem *)favorite
{
    self = [super init];
    if (self)
    {
        _identifier = [favorite getKey] ?: @"";
        _groupName = [favorite getCategory] ?: @"";
        _title = [favorite getDisplayName] ?: @"";
        _subtitle = [self.class subtitleForFavorite:favorite];
        _icon = [favorite getCompositeIcon];
        _isVisible = [favorite isVisible];
    }
    return self;
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
    const auto distance = OsmAnd::Utilities::distance(location.coordinate.longitude,
                                                      location.coordinate.latitude,
                                                      favoriteLon,
                                                      favoriteLat);
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

@implementation FavoriteFoldersBridge

+ (NSArray<FavoriteFolderBridgeItem *> *)favoriteFolders
{
    NSArray<OAFavoriteGroup *> *groups = [OAFavoritesHelper getFavoriteGroups] ?: @[];
    NSMutableArray<FavoriteFolderBridgeItem *> *folders = [NSMutableArray arrayWithCapacity:groups.count];
    [groups enumerateObjectsUsingBlock:^(OAFavoriteGroup * _Nonnull group, NSUInteger index, BOOL * _Nonnull stop) {
        [folders addObject:[[FavoriteFolderBridgeItem alloc] initWithGroup:group index:index]];
    }];
    return folders.copy;
}

+ (NSArray<FavoritePointBridgeItem *> *)favoritePointsForGroupName:(NSString *)groupName
{
    OAFavoriteGroup *group = [OAFavoritesHelper getGroupByName:groupName ?: @""];
    NSArray<OAFavoriteItem *> *points = [self sortedFavoritePoints:group.points ?: @[]];
    NSMutableArray<FavoritePointBridgeItem *> *items = [NSMutableArray arrayWithCapacity:points.count];
    for (OAFavoriteItem *point in points)
        [items addObject:[[FavoritePointBridgeItem alloc] initWithFavorite:point]];

    return items.copy;
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
    [rootViewController.mapPanel openTargetViewWithFavorite:favorite pushed:YES];
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

+ (void)renameFavoriteGroup:(NSString *)groupName newName:(NSString *)newName
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    NSString *trimmedName = [newName stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!group || trimmedName.length == 0)
        return;

    [OAFavoritesHelper updateGroup:group newName:trimmedName saveImmediately:YES];
}

+ (void)openFavoriteGroupAppearance:(NSString *)groupName navigationController:(UINavigationController *)navigationController
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    if (!group || !navigationController)
        return;

    OAFavoriteGroupEditorViewController *viewController = [[OAFavoriteGroupEditorViewController alloc] initWithGroup:[group toPointsGroup]];
    [navigationController pushViewController:viewController animated:YES];
}

+ (void)shareFavoriteGroup:(NSString *)groupName sourceView:(UIView *)sourceView viewController:(UIViewController *)viewController
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    if (!group || !viewController)
        return;

    OAFavoriteGroup *groupToShare = [[OAFavoriteGroup alloc] initWithPoints:group.points.copy
                                                                       name:group.name
                                                                  isVisible:group.isVisible
                                                                      color:group.color];
    groupToShare.isPinned = group.isPinned;
    groupToShare.iconName = group.iconName;
    groupToShare.backgroundType = group.backgroundType;

    OsmAndAppInstance app = [OsmAndApp instance];
    NSString *groupFileName = [app getGroupFileName:group.name];
    NSString *filename = [NSString stringWithFormat:@"%@%@%@%@",
                          app.favoritesFilePrefix,
                          groupFileName.length > 0 ? app.favoritesGroupNameSeparator : @"",
                          groupFileName ?: @"",
                          GPX_FILE_EXT];
    NSString *fullFilename = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    [OAFavoritesHelper saveFile:@[groupToShare] file:fullFilename];

    NSURL *favoritesUrl = [NSURL fileURLWithPath:fullFilename];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[favoritesUrl]
                                                                                         applicationActivities:nil];
    activityViewController.completionWithItemsHandler = ^(UIActivityType _Nullable activityType,
                                                          BOOL completed,
                                                          NSArray * _Nullable returnedItems,
                                                          NSError * _Nullable activityError) {
        [NSFileManager.defaultManager removeItemAtURL:favoritesUrl error:nil];
    };

    UIPopoverPresentationController *popover = activityViewController.popoverPresentationController;
    if (popover)
    {
        UIView *popoverSourceView = sourceView ?: viewController.view;
        popover.sourceView = popoverSourceView;
        popover.sourceRect = popoverSourceView.bounds;
        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }

    [viewController presentViewController:activityViewController animated:YES completion:nil];
}

+ (void)openFavoriteGroupMove:(NSString *)groupName navigationController:(UINavigationController *)navigationController
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    if (!group || !navigationController)
        return;

    NSMutableArray<NSString *> *groupNames = [NSMutableArray array];
    for (OAFavoriteGroup *favoriteGroup in [OAFavoritesHelper getFavoriteGroups])
    {
        NSString *favoriteGroupName = favoriteGroup.name ?: @"";
        if (![self isGroupName:favoriteGroupName insideOrEqualToGroupName:group.name ?: @""])
            [groupNames addObject:favoriteGroupName];
    }
    if (![groupNames containsObject:@""])
        [groupNames addObject:@""];

    OAEditGroupViewController *groupController = [[OAEditGroupViewController alloc] initWithGroupName:nil groups:groupNames];
    FavoriteGroupMoveDelegate *delegate = [[FavoriteGroupMoveDelegate alloc] init];
    delegate.groupName = group.name ?: @"";
    delegate.controller = groupController;
    groupController.delegate = delegate;
    objc_setAssociatedObject(groupController, @selector(groupChanged), delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    UINavigationController *modalNavigationController = [[UINavigationController alloc] initWithRootViewController:groupController];
    [navigationController presentViewController:modalNavigationController animated:YES completion:nil];
}

+ (void)deleteFavoriteGroup:(NSString *)groupName
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    if (!group)
        return;

    [OAFavoritesHelper deleteFavoriteGroups:@[group] andFavoritesItems:nil];
}

+ (void)addFavoriteGroupToMapMarkers:(NSString *)groupName
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    if (!group)
        return;

    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    for (OAFavoriteItem *favorite in [self sortedFavoritePoints:group.points ?: @[]])
    {
        CLLocation *location = [self locationForFavorite:favorite];
        if (!location)
            continue;

        [mapPanel addMapMarker:location.coordinate.latitude
                            lon:location.coordinate.longitude
                    description:[favorite getDisplayName]];
    }
}

+ (void)openFavoriteGroupAddToTrack:(NSString *)groupName navigationController:(UINavigationController *)navigationController
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    if (!group || group.points.count == 0 || !navigationController)
        return;

    OAOpenAddTrackViewController *viewController = [[OAOpenAddTrackViewController alloc] initWithScreenType:EOAAddToATrack];
    FavoriteGroupAddToTrackDelegate *delegate = [[FavoriteGroupAddToTrackDelegate alloc] init];
    delegate.groupName = group.name ?: @"";
    viewController.delegate = delegate;
    objc_setAssociatedObject(viewController, @selector(onFileSelected:), delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    UINavigationController *modalNavigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [navigationController presentViewController:modalNavigationController animated:YES completion:nil];
}

+ (void)addFavoriteGroupToNavigation:(NSString *)groupName
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    NSArray<OAFavoriteItem *> *points = [self sortedFavoritePoints:group.points ?: @[]];
    if (!group || points.count == 0)
        return;

    OATargetPointsHelper *targetPointsHelper = OATargetPointsHelper.sharedInstance;
    [targetPointsHelper clearAllPoints:NO];

    for (NSUInteger index = 0; index < points.count; index++)
    {
        OAFavoriteItem *favorite = points[index];
        CLLocation *location = [self locationForFavorite:favorite];
        if (!location)
            continue;

        OAPointDescription *description = [[OAPointDescription alloc] initWithType:POINT_TYPE_FAVORITE
                                                                              name:[favorite getDisplayName]];
        BOOL isDestination = index == points.count - 1;
        [targetPointsHelper navigateToPoint:location
                                updateRoute:isDestination
                                intermediate:isDestination ? -1 : (int)index
                                 historyName:description];
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

+ (BOOL)moveFavoriteGroup:(NSString *)groupName toGroupName:(NSString *)targetGroupName
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    NSString *sourceGroupName = group.name ?: @"";
    NSString *parentGroupName = targetGroupName ?: @"";
    if (!group || sourceGroupName.length == 0 || [self isGroupName:parentGroupName insideOrEqualToGroupName:sourceGroupName])
        return NO;

    NSString *newGroupName = [self groupNameByMovingGroupName:sourceGroupName toParentGroupName:parentGroupName];
    if ([sourceGroupName isEqualToString:newGroupName])
        return NO;

    BOOL changed = NO;
    NSArray<OAFavoriteGroup *> *groups = [[OAFavoritesHelper getFavoriteGroups] copy];
    for (OAFavoriteGroup *favoriteGroup in groups)
    {
        NSString *currentGroupName = favoriteGroup.name ?: @"";
        if (![self isGroupName:currentGroupName insideOrEqualToGroupName:sourceGroupName])
            continue;

        NSString *suffix = @"";
        if (currentGroupName.length > sourceGroupName.length)
            suffix = [currentGroupName substringFromIndex:sourceGroupName.length];

        NSString *renamedGroupName = [newGroupName stringByAppendingString:suffix];
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

+ (NSString *)lastComponentForGroupName:(NSString *)groupName
{
    NSArray<NSString *> *components = [(groupName ?: @"") componentsSeparatedByString:@"/"];
    return components.lastObject ?: @"";
}

+ (void)notifyFavoriteGroupsChanged
{
    [NSNotificationCenter.defaultCenter postNotificationName:FavoriteFoldersBridgeGroupsDidChangeNotification object:nil];
}

+ (void)addFavoriteGroupToTrack:(NSString *)groupName gpxFileName:(NSString *)gpxFileName
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    NSArray<OAFavoriteItem *> *points = [self sortedFavoritePoints:group.points ?: @[]];
    if (!group || points.count == 0)
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
    [OASelectedGPXHelper.instance markTrackForReload:dataItem.gpxFilePath];
}

+ (CLLocation *)locationForFavorite:(OAFavoriteItem *)favorite
{
    if (!favorite.favorite)
        return nil;

    return [[CLLocation alloc] initWithLatitude:[favorite getLatitude] longitude:[favorite getLongitude]];
}

@end
