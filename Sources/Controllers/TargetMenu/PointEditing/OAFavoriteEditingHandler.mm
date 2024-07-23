//
//  OAFavoriteEditingHandler.m
//  OsmAnd Maps
//
//  Created by Paul on 01.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAFavoriteEditingHandler.h"
#import "OAFavoriteItem.h"
#import "OADefaultFavorite.h"
#import "OAFavoritesHelper.h"
#import "OAPOI.h"
#import "OsmAndApp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>

#import <CoreLocation/CoreLocation.h>

@implementation OAFavoriteEditingHandler
{
    OAFavoriteItem *_favorite;
    OsmAndAppInstance _app;
    NSString *_iconName;
}

- (instancetype) initWithItem:(OAFavoriteItem *)favorite
{
    self = [super init];
    if (self)
    {
        _favorite = favorite;
        _iconName = [favorite getIcon];
        [self commonInit];
    }
    return self;
}

- (instancetype) initWithLocation:(CLLocationCoordinate2D)location title:(NSString*)formattedTitle address:(NSString*)formattedLocation poi:(OAPOI *)poi
{
    self = [super init];
    if (self)
    {
        [self commonInit];

        _iconName = [self.class getPoiIconName:poi];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *groupName = [userDefaults objectForKey:kFavoriteDefaultGroupKey] ? [userDefaults stringForKey:kFavoriteDefaultGroupKey] : @"";

        OAFavoriteColor *favCol = [OADefaultFavorite builtinColors].firstObject;
        _favorite = [[OAFavoriteItem alloc] initWithLat:location.latitude
                                                    lon:location.longitude
                                                   name:formattedTitle
                                               category:groupName];
        [_favorite setAddress:formattedLocation];
        [_favorite setTimestamp:[NSDate date]];
        [_favorite setIcon:_iconName];
        [_favorite setColor:favCol.color];
        [_favorite setAmenity:poi];
        [_favorite setAmenityOriginName:poi.toStringEn];
    }
    return self;
}

- (void) commonInit
{
    _app = [OsmAndApp instance];
}

- (UIColor *)getColor
{
    return _favorite.getColor;
}

- (NSString *)getGroupTitle
{
    return _favorite.getCategoryDisplayName;
}

- (NSString *)getName
{
    return _favorite.getName;
}

- (NSString *)getIcon
{
    return _iconName;
}

- (NSString *)getBackgroundIcon
{
    return _favorite.getBackgroundIcon;
}

- (BOOL)isSpecialPoint
{
    return _favorite.isSpecialPoint;
}

- (void)deleteItem
{
    if (_favorite)
        [OAFavoritesHelper deleteNewFavoriteItem:_favorite];
}

- (void) deleteItem:(BOOL)isNewItemAdding
{
    if (_favorite)
        [OAFavoritesHelper deleteFavoriteGroups:nil andFavoritesItems:@[_favorite] isNewFavorite:isNewItemAdding];
}

- (NSDictionary *)checkDuplicates:(NSString *)name group:(NSString *)group
{
    OAFavoriteItem *comparingPoint = [[OAFavoriteItem alloc] initWithLat:_favorite.getLatitude lon:_favorite.getLongitude name:name category:group];
    NSDictionary *result = [OAFavoritesHelper checkDuplicates:comparingPoint];
    [OAFavoritesHelper deleteNewFavoriteItem:comparingPoint];
    return result;
}

- (void)savePoint:(OAPointEditingData *)data newPoint:(BOOL)newPoint
{
    [_favorite setName:data.name];
    [_favorite setDescription:data.descr];
    [_favorite setColor:data.color];
    [_favorite setIcon:data.icon];
    [_favorite setBackgroundIcon:data.backgroundIcon];
    [_favorite setAddress:data.address];
    if (newPoint)
    {
        [_favorite setCategory:data.category];
        [OAFavoritesHelper addFavorite:_favorite];
    }
    else
    {
        // Category will be setted in editFavoriteName()
        [OAFavoritesHelper editFavoriteName:_favorite newName:data.name group:data.category descr:[_favorite getDescription] address:[_favorite getAddress]];
    }
}

- (OAFavoriteItem *) getFavoriteItem
{
    return _favorite;
}

@end
