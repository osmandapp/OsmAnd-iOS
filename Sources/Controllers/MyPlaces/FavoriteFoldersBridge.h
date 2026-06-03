//
//  FavoriteFoldersBridge.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 03.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FavoriteFolderBridgeItem : NSObject

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *groupName;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSUInteger pointsCount;
@property (nonatomic, readonly) BOOL isVisible;
@property (nonatomic, readonly) BOOL isPinned;
@property (nonatomic, readonly, nullable) UIColor *color;

- (instancetype)init NS_UNAVAILABLE;

@end

@interface FavoritePointBridgeItem : NSObject

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *groupName;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly, nullable) NSString *subtitle;
@property (nonatomic, readonly, nullable) UIImage *icon;
@property (nonatomic, readonly) BOOL isVisible;

- (instancetype)init NS_UNAVAILABLE;

@end

@interface FavoriteFoldersBridge : NSObject

+ (NSArray<FavoriteFolderBridgeItem *> *)favoriteFolders;
+ (NSArray<FavoritePointBridgeItem *> *)favoritePointsForGroupName:(NSString *)groupName;
+ (void)openFavoritePointWithIdentifier:(NSString *)identifier;
+ (void)setFavoriteGroupVisible:(NSString *)groupName visible:(BOOL)visible;
+ (void)setFavoriteGroupPinned:(NSString *)groupName pinned:(BOOL)pinned;
+ (void)renameFavoriteGroup:(NSString *)groupName newName:(NSString *)newName;
+ (void)openFavoriteGroupAppearance:(NSString *)groupName navigationController:(UINavigationController *)navigationController;
+ (void)shareFavoriteGroup:(NSString *)groupName sourceView:(UIView *)sourceView viewController:(UIViewController *)viewController;
+ (void)openFavoriteGroupMove:(NSString *)groupName navigationController:(UINavigationController *)navigationController;
+ (void)deleteFavoriteGroup:(NSString *)groupName;
+ (void)addFavoriteGroupToMapMarkers:(NSString *)groupName;
+ (void)openFavoriteGroupAddToTrack:(NSString *)groupName navigationController:(UINavigationController *)navigationController;
+ (void)addFavoriteGroupToNavigation:(NSString *)groupName;

@end

NS_ASSUME_NONNULL_END
