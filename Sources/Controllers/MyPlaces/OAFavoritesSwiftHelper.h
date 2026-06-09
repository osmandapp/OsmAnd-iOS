//
//  OAFavoritesSwiftHelper.h
//  OsmAnd
//
//  Created by Vladyslav Lysenko on 05.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class UIColor, UIImage, OAFavoriteItem, OASGpxUtilitiesPointsGroup;

@interface OAFavoriteFolderBridgeItem : NSObject

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *groupName;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSUInteger pointsCount;
@property (nonatomic, readonly) NSUInteger subtreePointsCount;
@property (nonatomic, readonly) BOOL isVisible;
@property (nonatomic, readonly) BOOL isPinned;
@property (nonatomic, readonly, nullable) UIColor *color;
@property (nonatomic, readonly, nullable) NSDate *lastModifiedDate;
@property (nonatomic, readonly) long long fileSize;

@end

@interface OAFavoritePointBridgeItem : NSObject

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *groupName;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly, nullable) NSString *address;
@property (nonatomic, readonly, nullable) NSNumber *distance;
@property (nonatomic, readonly, nullable) NSDate *timestampDate;
@property (nonatomic, readonly, nullable) UIImage *icon;
@property (nonatomic, readonly) BOOL isVisible;

- (instancetype)initWithFavorite:(OAFavoriteItem *)favorite;

@end

@interface OAFavoritesSwiftHelper : NSObject

+ (NSArray<OAFavoriteFolderBridgeItem *> *)favoriteFolders;
+ (NSArray<OAFavoritePointBridgeItem *> *)favoritePointsForGroupName:(NSString *)groupName;

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
+ (BOOL)moveFavoriteGroup:(NSString *)groupName toGroupName:(NSString *)targetGroupName;
+ (void)moveFavoriteItems:(NSArray *)favoriteItems toGroupName:(NSString *)targetGroupName;
+ (NSArray<NSString *> *)favoriteGroupNamesForMovingFavoriteItems:(NSArray *)favoriteItems;
+ (void)changeFavoriteItems:(NSArray *)favoriteItems colorIndex:(NSInteger)colorIndex;

+ (OASGpxUtilitiesPointsGroup *)pointsGroupForGroupName:(NSString *)groupName;
+ (NSArray<NSString *> *)favoriteGroupsToMoveForGroupName:(NSString *)groupName;
+ (BOOL)canUseGroupWithName:(NSString *)groupName;

+ (nullable NSURL *)shareFavoriteGroupName:(NSString *)groupName;
+ (nullable NSURL *)shareFavoriteItems:(NSArray *)favoriteItems;

+ (BOOL)deleteFavoriteGroup:(NSString *)groupName;
+ (BOOL)deleteFavoriteItems:(NSArray *)favoriteItems;

+ (void)openFavoritePointWithIdentifier:(NSString *)identifier;
+ (void)addFavoriteGroupToMapMarkers:(NSString *)groupName;
+ (void)addFavoriteItemsToMapMarkers:(NSArray *)favoriteItems;
+ (void)addFavoriteGroupToTrack:(NSString *)groupName gpxFileName:(nullable NSString *)gpxFileName;
+ (void)addFavoriteGroupToNavigation:(NSString *)groupName;
+ (void)addFavoriteItemsToTrack:(NSArray *)favoriteItems gpxFileName:(nullable NSString *)gpxFileName;
+ (void)addFavoriteItemsToNavigation:(NSArray *)favoriteItems;

@end

NS_ASSUME_NONNULL_END
