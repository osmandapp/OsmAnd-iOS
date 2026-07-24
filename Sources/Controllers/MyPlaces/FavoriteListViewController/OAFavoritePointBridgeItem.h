//
//  OAFavoritePointBridgeItem.h
//  OsmAnd
//
//  Created by Vladyslav Lysenko on 15.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@class OAFavoriteItem;

NS_ASSUME_NONNULL_BEGIN

@interface OAFavoritePointBridgeItem : NSObject

@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *groupName;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly, nullable) NSString *address;
@property (nonatomic, readonly) NSString *displayGroupName;
@property (nonatomic, readonly, nullable) NSString *itemDescription;
@property (nonatomic, readonly) NSString *encodedNameForLink;
@property (nonatomic, readonly, nullable) NSNumber *distance;
@property (nonatomic, readonly) CGFloat direction;
@property (nonatomic, readonly) double latitude;
@property (nonatomic, readonly) double longitude;
@property (nonatomic, readonly, nullable) NSDate *timestampDate;
@property (nonatomic, readonly) BOOL isVisible;

- (instancetype)initWithFavorite:(OAFavoriteItem *)favorite;
- (UIImage *)icon;
- (void)updateDistanceAndDirection;
- (void)updateDistanceAndDirectionFromMapCenter:(CLLocationCoordinate2D)mapCenterCoordinate mapAzimuth:(CLLocationDirection)mapAzimuth;

@end

NS_ASSUME_NONNULL_END
