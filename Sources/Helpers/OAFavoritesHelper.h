//
//  OAFavoritesHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 23/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <OsmAndCore/IFavoriteLocation.h>

@class OAFavoriteItem, OAFavoriteGroup;

@interface OAFavoritesHelper : NSObject

+ (BOOL) isFavoritesLoaded;
+ (void) loadFavorites;
+ (void) import:(QList< std::shared_ptr<OsmAnd::IFavoriteLocation> >)favorites;

+ (NSArray<OAFavoriteItem *> *) getFavoriteItems;
+ (NSArray<OAFavoriteItem *> *) getVisibleFavoriteItems;
+ (NSArray<OAFavoriteGroup *> *) getGroupedFavorites:(QList< std::shared_ptr<OsmAnd::IFavoriteLocation> >)allFavorites;

+ (void) editFavorite:(OAFavoriteItem *)item name:(NSString *)name group:(NSString *)group;
+ (NSMutableArray<OAFavoriteGroup *> *) getFavoriteGroups;
+ (void) addEmptyCategory:(NSString *)name color:(UIColor *)color visible:(BOOL)visible;
+ (OAFavoriteGroup *) getOrCreateGroup:(OAFavoriteItem *)item defColor:(UIColor *)defColor;
+ (void) deleteFavoriteGroups:(NSArray<OAFavoriteGroup *> *)groupsToDelete andFavoritesItems:(NSArray<OAFavoriteItem *> *)favoritesItems;

@end

@interface OAFavoriteGroup : NSObject

@property (nonatomic) NSString* name;
@property (nonatomic) UIColor* color;
@property (nonatomic) BOOL isHidden;
@property (nonatomic) NSMutableArray<OAFavoriteItem*> *points;

- (instancetype) initWithName:(NSString *)name isHidden:(BOOL)isHidden color:(UIColor *)color;
- (instancetype) initWithPoints:(NSArray<OAFavoriteItem *> *)points name:(NSString *)name isHidden:(BOOL)isHidden color:(UIColor *)color;
- (void) addPoint:(OAFavoriteItem *)point;

+ (NSString *) getDisplayName:(NSString *)name;
+ (NSString *) convertDisplayNameToGroupIdName:(NSString *)name;

@end
