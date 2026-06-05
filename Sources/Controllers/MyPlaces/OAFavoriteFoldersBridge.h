//
//  OAFavoriteFoldersBridge.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 04.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class UIColor, UIImage, UINavigationController, UIView, UIViewController;

@interface OAFavoriteFolderBridgeItem : NSObject

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *groupName;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSUInteger pointsCount;
@property (nonatomic, readonly) BOOL isVisible;
@property (nonatomic, readonly) BOOL isPinned;
@property (nonatomic, readonly, nullable) UIColor *color;

- (instancetype)init NS_UNAVAILABLE;

@end

@interface OAFavoritePointBridgeItem : NSObject

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *groupName;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly, nullable) NSString *subtitle;
@property (nonatomic, readonly, nullable) UIImage *icon;
@property (nonatomic, readonly) BOOL isVisible;

- (instancetype)init NS_UNAVAILABLE;

@end

@interface OAFavoriteFoldersBridge : NSObject

+ (NSArray<OAFavoriteFolderBridgeItem *> *)favoriteFolders;
+ (NSArray<OAFavoritePointBridgeItem *> *)favoritePointsForGroupName:(NSString *)groupName;
+ (long long)favoriteGroupSizeForGroupName:(NSString *)groupName;
+ (void)openFavoritePointWithIdentifier:(NSString *)identifier;
+ (void)openNewFavoriteGroupEditorWithParentGroupName:(nullable NSString *)parentGroupName navigationController:(UINavigationController *)navigationController completion:(void (^ _Nullable)(void))completion;
+ (void)setFavoriteGroupVisible:(NSString *)groupName visible:(BOOL)visible;
+ (void)setFavoriteGroupPinned:(NSString *)groupName pinned:(BOOL)pinned;
+ (void)renameFavoriteGroup:(NSString *)groupName newName:(NSString *)newName;
+ (void)openFavoriteGroupAppearance:(NSString *)groupName navigationController:(UINavigationController *)navigationController;
+ (void)shareFavoriteGroup:(NSString *)groupName sourceView:(nullable UIView *)sourceView viewController:(UIViewController *)viewController;
+ (void)openFavoriteGroupMove:(NSString *)groupName navigationController:(UINavigationController *)navigationController completion:(void (^ _Nullable)(void))completion;
+ (void)deleteFavoriteGroup:(NSString *)groupName;
+ (void)addFavoriteGroupToMapMarkers:(NSString *)groupName;
+ (void)openFavoriteGroupAddToTrack:(NSString *)groupName navigationController:(UINavigationController *)navigationController;
+ (void)addFavoriteGroupToNavigation:(NSString *)groupName;

@end

NS_ASSUME_NONNULL_END
