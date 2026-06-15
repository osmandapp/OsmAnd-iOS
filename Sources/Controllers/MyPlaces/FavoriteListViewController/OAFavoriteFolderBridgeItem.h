//
//  OAFavoriteFolderBridgeItem.h
//  OsmAnd
//
//  Created by Vladyslav Lysenko on 15.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@class OAFavoriteGroup;

NS_ASSUME_NONNULL_BEGIN

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

- (instancetype)initWithGroup:(OAFavoriteGroup *)group index:(NSUInteger)index lastModifiedDate:(nullable NSDate *)lastModifiedDate fileSize:(long long)fileSize subtreePointsCount:(NSUInteger)subtreePointsCount;

@end

NS_ASSUME_NONNULL_END
