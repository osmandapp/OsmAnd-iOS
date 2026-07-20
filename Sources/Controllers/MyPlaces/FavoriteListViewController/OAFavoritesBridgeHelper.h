//
//  OAFavoritesBridgeHelper.h
//  OsmAnd
//
//  Created by Vladyslav Lysenko on 05.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class UIColor, OAFavoriteItem, OASGpxUtilitiesPointsGroup, OAEditPointViewController, OAFavoriteFolderBridgeItem, OAFavoritePointBridgeItem;

@interface OAFavoritesBridgeHelper : NSObject

+ (void)invalidateFavoriteFoldersCache;
+ (void)createMissingParentFolderIfNeeded;
+ (NSArray<OAFavoriteFolderBridgeItem *> *)favoriteFolders;
+ (NSArray<OAFavoritePointBridgeItem *> *)favoritePointsForGroupName:(NSString *)groupName;
+ (NSString *)sharePoiURLStringForFavoritePoint:(OAFavoritePointBridgeItem *)favoriteItem;
+ (NSString *)geoURLStringForFavoritePoint:(OAFavoritePointBridgeItem *)favoriteItem;
+ (NSString *)formattedCoordinatesForFavoritePoint:(OAFavoritePointBridgeItem *)favoriteItem;

+ (void)setFavoriteGroupVisible:(NSString *)groupName visible:(BOOL)visible;
+ (void)setFavoriteGroupPinned:(NSString *)groupName pinned:(BOOL)pinned;
+ (void)setFavoriteGroupsVisible:(NSArray<NSString *> *)groupNames visible:(BOOL)visible;
+ (void)setFavoriteGroupsPinned:(NSArray<NSString *> *)groupNames pinned:(BOOL)pinned;
+ (BOOL)addFavoriteGroup:(NSString *)name
         parentGroupName:(nullable NSString *)parentGroupName
                iconName:(nullable NSString *)iconName
                   color:(nullable UIColor *)color
      backgroundIconName:(nullable NSString *)backgroundIconName;
+ (void)renameFavoriteGroup:(NSString *)groupName newName:(NSString *)newName;
+ (void)moveFavoriteItems:(NSArray *)favoriteItems toGroupName:(NSString *)targetGroupName;
+ (NSArray<NSString *> *)favoriteGroupNamesForMovingFavoriteItems:(NSArray *)favoriteItems;
+ (void)changeFavoriteItems:(NSArray *)favoriteItems colorIndex:(NSInteger)colorIndex;

+ (OASGpxUtilitiesPointsGroup *)pointsGroupForGroupName:(NSString *)groupName;
+ (BOOL)canUseGroupWithName:(NSString *)groupName;

+ (nullable NSURL *)shareFavoriteItems:(NSArray *)favoriteItems;

+ (BOOL)deleteFavoriteGroup:(NSString *)groupName;
+ (BOOL)deleteFavoritePoint:(OAFavoritePointBridgeItem *)favoriteItem;
+ (BOOL)deleteFavoriteItems:(NSArray *)favoriteItems;

+ (void)openFavoritePointWithIdentifier:(NSString *)identifier;
+ (nullable OAEditPointViewController *)editPointViewControllerForFavoritePoint:(OAFavoritePointBridgeItem *)favoriteItem;
+ (void)addFavoriteItemsToMapMarkers:(NSArray *)favoriteItems;
+ (void)addFavoriteGroupToTrack:(NSString *)groupName gpxFileName:(nullable NSString *)gpxFileName;
+ (void)addFavoriteGroupToNavigation:(NSString *)groupName;
+ (void)addFavoriteItemsToTrack:(NSArray *)favoriteItems gpxFileName:(nullable NSString *)gpxFileName;
+ (void)addFavoriteItemsToNavigation:(NSArray *)favoriteItems;

@end

NS_ASSUME_NONNULL_END
