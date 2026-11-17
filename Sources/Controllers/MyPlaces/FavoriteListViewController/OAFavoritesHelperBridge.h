//
//  OAFavoritesHelperBridge.h
//  OsmAnd
//
//  Created by Vladyslav Lysenko on 05.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAFavoriteGroup.h"

NS_ASSUME_NONNULL_BEGIN

@class UIColor, OAFavoriteItem, OASGpxUtilitiesPointsGroup, OAEditPointViewController, OAFavoriteFolderBridgeItem, OAFavoritePointBridgeItem;

@interface OAFavoritesHelperBridge : NSObject

+ (OAFavoritesHelperBridge *)shared;

- (NSArray<NSString *> *)collapsedSections;
- (void)updateCollapsedSections:(NSArray<NSString *> *)sections;
- (NSArray<OAFavoriteFolderBridgeItem *> *)favoriteFolders;
- (NSArray<NSString *> *)favoriteGroupNames;
- (NSArray<OAFavoriteGroup *> *)favoriteGroups;
- (nullable OAFavoriteGroup *)favoriteGroupWithName:(NSString *)groupName;
- (nullable OAFavoriteGroup *)groupByTrimmedName:(NSString *)groupName;
- (BOOL)hasFavoriteGroup:(NSString *)groupName;
- (NSString *)displayNameForFavoriteGroup:(NSString *)groupName;
- (NSInteger)pointsCountForFavoriteGroup:(NSString *)groupName;
- (UIColor *)colorForFavoriteGroup:(NSString *)groupName;
- (NSArray<NSString *> *)backgroundIconNames;
- (NSArray<OAFavoritePointBridgeItem *> *)favoritePointsForGroupName:(NSString *)groupName;
- (NSString *)sharePoiURLStringForFavoritePoint:(OAFavoritePointBridgeItem *)favoriteItem;
- (NSString *)geoURLStringForFavoritePoint:(OAFavoritePointBridgeItem *)favoriteItem;
- (NSString *)formattedCoordinatesForFavoritePoint:(OAFavoritePointBridgeItem *)favoriteItem;

- (void)setFavoriteGroupVisible:(NSString *)groupName visible:(BOOL)visible;
- (void)setFavoriteGroupPinned:(NSString *)groupName pinned:(BOOL)pinned;
- (void)setFavoriteGroupsVisible:(NSArray<NSString *> *)groupNames visible:(BOOL)visible;
- (void)setFavoriteGroupsPinned:(NSArray<NSString *> *)groupNames pinned:(BOOL)pinned;
- (BOOL)addFavoriteGroup:(NSString *)name
         parentGroupName:(nullable NSString *)parentGroupName
                iconName:(nullable NSString *)iconName
                   color:(nullable UIColor *)color
      backgroundIconName:(nullable NSString *)backgroundIconName;
- (BOOL)renameFavoriteGroup:(NSString *)groupName newName:(NSString *)newName;
- (BOOL)moveFavoriteItems:(NSArray *)favoriteItems toGroupName:(NSString *)targetGroupName;
- (NSArray<NSString *> *)favoriteGroupNamesForMovingFavoriteItems:(NSArray *)favoriteItems;
- (void)changeFavoritePoints:(NSArray<OAFavoritePointBridgeItem *> *)favoritePoints color:(nullable UIColor *)color iconName:(nullable NSString *)iconName backgroundIconName:(nullable NSString *)backgroundIconName;
- (OASGpxUtilitiesPointsGroup *)pointsGroupForGroupName:(NSString *)groupName;
- (BOOL)canUseGroupWithName:(NSString *)groupName;

- (void)updateGroup:(nullable OAFavoriteGroup *)group newName:(NSString *)newName saveImmediately:(BOOL)saveImmediately;
- (void)updateGroup:(nullable OAFavoriteGroup *)group iconName:(NSString *)iconName updatePoints:(BOOL)updatePoints updateGroupIcon:(BOOL)updateGroupIcon saveImmediately:(BOOL)saveImmediately completion:(void (^)(void))completion;
- (void)updateGroup:(nullable OAFavoriteGroup *)group color:(UIColor *)color updatePoints:(BOOL)updatePoints updateGroupColor:(BOOL)updateGroupColor saveImmediately:(BOOL)saveImmediately;
- (void)updateGroup:(nullable OAFavoriteGroup *)group backgroundIconName:(NSString *)backgroundIconName updatePoints:(BOOL)updatePoints updateGroupShape:(BOOL)updateGroupShape saveImmediately:(BOOL)saveImmediately;
- (void)notifyFavoritesStorageChanged;
- (void)saveCurrentPointsIntoFile;

- (nullable NSURL *)shareFavoriteItems:(NSArray *)favoriteItems;

- (BOOL)deleteFavoriteGroup:(NSString *)groupName;
- (BOOL)deleteFavoritePoint:(OAFavoritePointBridgeItem *)favoriteItem;
- (BOOL)deleteFavoriteItems:(NSArray *)favoriteItems;

- (void)openFavoritePointWithIdentifier:(NSString *)identifier;
- (nullable OAEditPointViewController *)editPointViewControllerForFavoritePoint:(OAFavoritePointBridgeItem *)favoriteItem;
- (void)addFavoriteItemsToMapMarkers:(NSArray *)favoriteItems;
- (void)addFavoriteGroupToTrack:(NSString *)groupName gpxFileName:(nullable NSString *)gpxFileName;
- (void)addFavoriteGroupToNavigation:(NSString *)groupName;
- (void)addFavoriteItemsToTrack:(NSArray *)favoriteItems gpxFileName:(nullable NSString *)gpxFileName;
- (void)addFavoriteItemsToNavigation:(NSArray *)favoriteItems;

@end

NS_ASSUME_NONNULL_END
