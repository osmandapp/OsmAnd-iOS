//
//  OAFavoriteGroup.h
//  OsmAnd
//
//  Created by Dmitry Svetlichny on 09.10.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UIColor, OAFavoriteItem, OASGpxUtilitiesPointsGroup;

@interface OAFavoriteGroup : NSObject

@property (nonatomic) NSString *name;
@property (nonatomic) UIColor *color;
@property (nonatomic) BOOL isVisible;
@property (nonatomic) BOOL isPinned;
@property (nonatomic) NSString *iconName;
@property (nonatomic) NSString *backgroundType;
@property (nonatomic) NSMutableArray<OAFavoriteItem *> *points;

- (instancetype)initWithPoint:(OAFavoriteItem *)point;
- (instancetype)initWithName:(NSString *)name isVisible:(BOOL)isVisible color:(UIColor *)color;
- (instancetype)initWithPoints:(NSArray<OAFavoriteItem *> *)points name:(NSString *)name isVisible:(BOOL)isVisible color:(UIColor *)color;
- (void)addPoint:(OAFavoriteItem *)point;
- (BOOL)hasColor;
- (BOOL)isPersonal;
+ (BOOL)isPersonal:(NSString *)name;
+ (BOOL)isPersonalCategoryDisplayName:(NSString *)name;
- (BOOL)isEqual:(id)object;
+ (NSString *)getDisplayName:(NSString *)name;
+ (NSString *)convertDisplayNameToGroupIdName:(NSString *)name;
- (OASGpxUtilitiesPointsGroup *)toPointsGroup;
+ (OAFavoriteGroup *)fromPointsGroup:(OASGpxUtilitiesPointsGroup *)pointsGroup;

@end
