//
//  OAFavoritesHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 23/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <OsmAndCore/IFavoriteLocation.h>

@class OAFavoriteItem, OAFavoriteGroup, OASpecialPointType, OAGPXDocument;

@interface OAFavoritesHelper : NSObject

+ (BOOL) isFavoritesLoaded;
+ (void) loadFavorites;
+ (void) import:(QList< std::shared_ptr<OsmAnd::IFavoriteLocation> >)favorites;

+ (OAFavoriteItem *) getSpecialPoint:(OASpecialPointType *)specialType;
+ (void) setSpecialPoint:(OASpecialPointType *)specialType lat:(double)lat lon:(double)lon address:(NSString *)address;

+ (NSArray<OAFavoriteItem *> *) getFavoriteItems;
+ (NSArray<OAFavoriteItem *> *) getVisibleFavoriteItems;
+ (OAFavoriteItem *) getVisibleFavByLat:(double)lat lon:(double)lon;
+ (NSArray<OAFavoriteGroup *> *) getGroupedFavorites:(QList< std::shared_ptr<OsmAnd::IFavoriteLocation> >)allFavorites;
+ (NSMutableDictionary<NSString *, OAFavoriteGroup *> *) getGroups;
+ (OAFavoriteGroup *) getGroupByName:(NSString *)nameId;
+ (OAFavoriteGroup *) getGroupByPoint:(OAFavoriteItem *)favoriteItem;


+ (BOOL) addFavorite:(OAFavoriteItem *)point;
+ (BOOL) addFavorite:(OAFavoriteItem *)point saveImmediately:(BOOL)saveImmediately;

+ (BOOL) editFavoriteName:(OAFavoriteItem *)item newName:(NSString *)newName group:(NSString *)group descr:(NSString *)descr address:(NSString *)address;
+ (BOOL) editFavorite:(OAFavoriteItem *)item lat:(double)lat lon:(double)lon;
+ (BOOL) editFavorite:(OAFavoriteItem *)item lat:(double)lat lon:(double)lon description:(NSString *)description;
+ (BOOL) editFavoriteGroup:(OAFavoriteGroup *)group newName:(NSString *)newName color:(UIColor*)color visible:(BOOL)visible;
+ (void) saveCurrentPointsIntoFile;

+ (NSMutableArray<OAFavoriteGroup *> *) getFavoriteGroups;
+ (void) addEmptyCategory:(NSString *)name;
+ (void) addEmptyCategory:(NSString *)name color:(UIColor *)color visible:(BOOL)visible;
+ (OAFavoriteGroup *) getOrCreateGroup:(OAFavoriteItem *)item defColor:(UIColor *)defColor;
+ (BOOL) deleteFavoriteGroups:(NSArray<OAFavoriteGroup *> *)groupsToDelete andFavoritesItems:(NSArray<OAFavoriteItem *> *)favoritesItems;

+ (NSDictionary<NSString *, NSString *> *) checkDuplicates:(OAFavoriteItem *)point newName:(NSString *)newName newCategory:(NSString *)newCategory;
+ (NSString *) checkEmoticons:(NSString *)text;
+ (void) sortAll;
+ (void) recalculateCachedFavPoints;

+ (NSDictionary<NSString *, NSArray<NSString *> *> *) getCategirizedIconNames;
+ (NSArray<NSString *> *) getFlatIconNamesList;
+ (NSArray<NSString *> *) getFlatBackgroundIconNamesList;
+ (NSArray<NSString *> *) getFlatBackgroundContourIconNamesList;

+ (OAGPXDocument *) asGpxFile:(NSArray<OAFavoriteItem *> *)favoritePoints;

@end

@interface OAFavoriteGroup : NSObject

@property (nonatomic) NSString* name;
@property (nonatomic) UIColor* color;
@property (nonatomic) BOOL isVisible;
@property (nonatomic) NSMutableArray<OAFavoriteItem*> *points;

- (instancetype) initWithName:(NSString *)name isVisible:(BOOL)isVisible color:(UIColor *)color;
- (instancetype) initWithPoints:(NSArray<OAFavoriteItem *> *)points name:(NSString *)name isVisible:(BOOL)isVisible color:(UIColor *)color;
- (void) addPoint:(OAFavoriteItem *)point;

- (BOOL) isPersonal;

+ (BOOL) isPersonalCategoryDisplayName:(NSString *)name;
+ (NSString *) getDisplayName:(NSString *)name;
+ (NSString *) convertDisplayNameToGroupIdName:(NSString *)name;

@end
