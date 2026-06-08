//
//  OAFavoriteFoldersBridge.mm
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 04.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAFavoriteFoldersBridge.h"
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
#import "OAPointDescription.h"
#import "OARootViewController.h"
#import "OASavingTrackHelper.h"
#import "OASelectedGPXHelper.h"
#import "OATargetPointsHelper.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"
#import "OsmAndSharedWrapper.h"
#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>
#import "OAFavoritesSwiftHelper.h"

#include <OsmAndCore/Utilities.h>


@interface OAFavoriteFoldersBridge ()

+ (NSArray<OAFavoriteItem *> *)sortedFavoritePoints:(NSArray<OAFavoriteItem *> *)points;
+ (NSArray<OAFavoriteItem *> *)sortedFavoritePointsForGroup:(OAFavoriteGroup *)group;
+ (NSArray<OAFavoriteGroup *> *)favoriteGroupsInsideOrEqualToGroupName:(NSString *)groupName;
+ (OAFavoriteItem *)favoritePointWithIdentifier:(NSString *)identifier;
+ (OAFavoriteGroup *)favoriteGroupWithName:(NSString *)groupName;
+ (BOOL)moveFavoriteGroup:(NSString *)groupName toGroupName:(NSString *)targetGroupName;
+ (BOOL)renameFavoriteGroupTreeFromGroupName:(NSString *)sourceGroupName toGroupName:(NSString *)targetGroupName;
+ (BOOL)isGroupName:(NSString *)groupName insideOrEqualToGroupName:(NSString *)parentGroupName;
+ (NSString *)groupNameByMovingGroupName:(NSString *)groupName toParentGroupName:(NSString *)parentGroupName;
+ (NSString *)suffixForGroupName:(NSString *)groupName parentGroupName:(NSString *)parentGroupName;
+ (NSString *)lastComponentForGroupName:(NSString *)groupName;
+ (void)addFavoriteGroupToTrack:(NSString *)groupName gpxFileName:(NSString *)gpxFileName;
+ (CLLocation *)locationForFavorite:(OAFavoriteItem *)favorite;

@end

@interface OAFavoriteGroupMoveDelegate : NSObject <OAEditGroupViewControllerDelegate>

@property (nonatomic, copy) NSString *groupName;
@property (nonatomic, weak) OAEditGroupViewController *controller;
@property (nonatomic, copy, nullable) void (^completion)(void);

@end

@implementation OAFavoriteGroupMoveDelegate

- (void)groupChanged
{
    if (!self.controller.saveChanges)
        return;
    
    if ([OAFavoriteFoldersBridge moveFavoriteGroup:self.groupName toGroupName:self.controller.groupName] && self.completion)
        self.completion();
}

@end

@interface OAFavoriteGroupAddToTrackDelegate : NSObject <OAOpenAddTrackDelegate>

@property (nonatomic, copy) NSString *groupName;

@end

@implementation OAFavoriteGroupAddToTrackDelegate

- (void)onFileSelected:(NSString *)gpxFileName
{
    [OAFavoriteFoldersBridge addFavoriteGroupToTrack:self.groupName gpxFileName:gpxFileName];
}

@end

@interface OAFavoriteGroupCreationHandler : NSObject

@property (nonatomic, copy) NSString *parentGroupName;
@property (nonatomic, copy, nullable) void (^completion)(void);

@end

@implementation OAFavoriteGroupCreationHandler

- (void)addNewItemWithName:(NSString *)name iconName:(NSString *)iconName color:(UIColor *)color backgroundIconName:(NSString *)backgroundIconName
{
    NSString *trimmedName = [(name ?: @"") stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *groupName = self.parentGroupName.length > 0 && trimmedName.length > 0 ? [NSString stringWithFormat:@"%@/%@", self.parentGroupName, trimmedName] : trimmedName;
    if (groupName.length == 0 || [OAFavoritesHelper getGroupByName:groupName])
        return;
    
    [OAFavoritesHelper addFavoriteGroup:groupName color:color iconName:iconName backgroundIconName:backgroundIconName];
    [OAFavoritesHelper saveCurrentPointsIntoFile];
    if (self.completion)
        self.completion();
}

@end

@implementation OAFavoriteFoldersBridge

+ (NSArray<OAFavoriteFolderBridgeItem *> *)favoriteFolders
{
    return [OAFavoritesSwiftHelper favoriteFolders];
}

+ (NSArray<OAFavoritePointBridgeItem *> *)favoritePointsForGroupName:(NSString *)groupName
{
    NSArray<OAFavoriteItem *> *points = [self sortedFavoritePointsForGroup:[self favoriteGroupWithName:groupName]];
    NSMutableArray<OAFavoritePointBridgeItem *> *items = [NSMutableArray arrayWithCapacity:points.count];
    for (OAFavoriteItem *point in points)
        [items addObject:[[OAFavoritePointBridgeItem alloc] initWithFavorite:point]];
    
    return items.copy;
}

+ (void)openNewFavoriteGroupEditorWithParentGroupName:(nullable NSString *)parentGroupName navigationController:(UINavigationController *)navigationController completion:(void (^ _Nullable)(void))completion
{
    if (!navigationController)
        return;
    
    OAFavoriteGroupEditorViewController *viewController = [[OAFavoriteGroupEditorViewController alloc] initWithNew];
    OAFavoriteGroupCreationHandler *handler = [[OAFavoriteGroupCreationHandler alloc] init];
    handler.parentGroupName = parentGroupName ?: @"";
    handler.completion = completion;
    viewController.delegate = (id<OAEditorDelegate>) handler;
    objc_setAssociatedObject(viewController, @selector(openNewFavoriteGroupEditorWithParentGroupName:navigationController:completion:), handler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UINavigationController *modalNavigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [navigationController presentViewController:modalNavigationController animated:YES completion:nil];
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
    
    NSString *sourceGroupName = group.name ?: @"";
    if ([sourceGroupName isEqualToString:trimmedName])
        return;
    
    [self renameFavoriteGroupTreeFromGroupName:sourceGroupName toGroupName:trimmedName];
}

+ (void)openFavoriteGroupAppearance:(NSString *)groupName navigationController:(UINavigationController *)navigationController
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    if (!group || !navigationController)
        return;
    
    OAFavoriteGroupEditorViewController *viewController = [[OAFavoriteGroupEditorViewController alloc] initWithGroup:[group toPointsGroup]];
    [navigationController pushViewController:viewController animated:YES];
}

+ (void)shareFavoriteGroup:(NSString *)groupName sourceView:(nullable UIView *)sourceView viewController:(UIViewController *)viewController
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    if (!group || !viewController)
        return;
    
    OAFavoriteGroup *groupToShare = [[OAFavoriteGroup alloc] initWithPoints:group.points.copy name:group.name isVisible:group.isVisible color:group.color];
    groupToShare.isPinned = group.isPinned;
    groupToShare.iconName = group.iconName;
    groupToShare.backgroundType = group.backgroundType;
    OsmAndAppInstance app = [OsmAndApp instance];
    NSString *groupFileName = [app getGroupFileName:group.name];
    NSString *filename = [NSString stringWithFormat:@"%@%@%@%@", app.favoritesFilePrefix, groupFileName.length > 0 ? app.favoritesGroupNameSeparator : @"", groupFileName ?: @"", GPX_FILE_EXT];
    NSString *fullFilename = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    [OAFavoritesHelper saveFile:@[groupToShare] file:fullFilename];
    NSURL *favoritesUrl = [NSURL fileURLWithPath:fullFilename];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[favoritesUrl] applicationActivities:nil];
    activityViewController.completionWithItemsHandler = ^(UIActivityType _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
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

+ (void)openFavoriteGroupMove:(NSString *)groupName navigationController:(UINavigationController *)navigationController completion:(void (^ _Nullable)(void))completion
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
    OAFavoriteGroupMoveDelegate *delegate = [[OAFavoriteGroupMoveDelegate alloc] init];
    delegate.groupName = group.name ?: @"";
    delegate.controller = groupController;
    delegate.completion = completion;
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
    
    NSArray<OAFavoriteGroup *> *groupsToDelete = [self favoriteGroupsInsideOrEqualToGroupName:group.name ?: @""];
    if (groupsToDelete.count > 0)
        [OAFavoritesHelper deleteFavoriteGroups:groupsToDelete andFavoritesItems:nil];
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

+ (void)openFavoriteGroupAddToTrack:(NSString *)groupName navigationController:(UINavigationController *)navigationController
{
    OAFavoriteGroup *group = [self favoriteGroupWithName:groupName];
    if (!group || group.points.count == 0 || !navigationController)
        return;
    
    OAOpenAddTrackViewController *viewController = [[OAOpenAddTrackViewController alloc] initWithScreenType:EOAAddToATrack];
    OAFavoriteGroupAddToTrackDelegate *delegate = [[OAFavoriteGroupAddToTrackDelegate alloc] init];
    delegate.groupName = group.name ?: @"";
    viewController.delegate = delegate;
    objc_setAssociatedObject(viewController, @selector(onFileSelected:), delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UINavigationController *modalNavigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [navigationController presentViewController:modalNavigationController animated:YES completion:nil];
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

+ (NSArray<OAFavoriteItem *> *)sortedFavoritePointsForGroup:(OAFavoriteGroup *)group
{
    return [self sortedFavoritePoints:group.points ?: @[]];
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

+ (OAFavoriteGroup *)favoriteGroupWithName:(NSString *)groupName
{
    return [OAFavoritesHelper getGroupByName:groupName ?: @""];
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

+ (void)addFavoriteGroupToTrack:(NSString *)groupName gpxFileName:(NSString *)gpxFileName
{
    NSArray<OAFavoriteItem *> *points = [self sortedFavoritePointsForGroup:[self favoriteGroupWithName:groupName]];
    if (points.count == 0)
        return;
    
    if (gpxFileName.length == 0)
    {
        OASavingTrackHelper *savingTrackHelper = OASavingTrackHelper.sharedInstance;
        for (OAFavoriteItem *favorite in points)
        {
            [savingTrackHelper addWpt:[favorite toWpt]];
        }
        
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
    {
        [gpxFile addPointPoint:[favorite toWpt]];
    }
    
    [OASGpxUtilities.shared writeGpxFileFile:dataItem.file gpxFile:gpxFile];
    [gpxDatabase updateDataItem:dataItem];
    [OASelectedGPXHelper.instance markTrackForReload:[OAUtilities getGpxShortPath:dataItem.file.absolutePath]];
}

+ (CLLocation *)locationForFavorite:(OAFavoriteItem *)favorite
{
    if (!favorite.favorite)
        return nil;
    
    return [[CLLocation alloc] initWithLatitude:[favorite getLatitude] longitude:[favorite getLongitude]];
}

@end
