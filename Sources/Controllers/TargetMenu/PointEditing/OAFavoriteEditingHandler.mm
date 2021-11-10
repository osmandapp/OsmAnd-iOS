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
#import "OsmAndApp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>

#import <CoreLocation/CoreLocation.h>

@implementation OAFavoriteEditingHandler
{
    OAFavoriteItem *_favorite;
    OsmAndAppInstance _app;
}

- (instancetype) initWithItem:(OAFavoriteItem *)favorite
{
    self = [super init];
    if (self)
    {
        _favorite = favorite;
        [self commonInit];
    }
    return self;
}

- (instancetype) initWithLocation:(CLLocationCoordinate2D)location title:(NSString*)formattedTitle address:(NSString*)formattedLocation
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        
        // Create favorite
        OsmAnd::PointI locationPoint;
        locationPoint.x = OsmAnd::Utilities::get31TileNumberX(location.longitude);
        locationPoint.y = OsmAnd::Utilities::get31TileNumberY(location.latitude);
        
        QString elevation;
        QString time = QString::fromNSString([OAFavoriteItem toStringDate:[NSDate date]]);
        QString creationTime = QString::fromNSString([OAFavoriteItem toStringDate:[NSDate date]]);
        
        QString title = QString::fromNSString(formattedTitle);
        QString address = QString::fromNSString(formattedLocation);
        QString description;
        QString icon;
        QString background;
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *groupName;
        if ([userDefaults objectForKey:kFavoriteDefaultGroupKey])
            groupName = [userDefaults stringForKey:kFavoriteDefaultGroupKey];
        
        OAFavoriteColor *favCol = [OADefaultFavorite builtinColors].firstObject;
        
        UIColor* color_ = favCol.color;
        CGFloat r,g,b,a;
        [color_ getRed:&r
                 green:&g
                  blue:&b
                 alpha:&a];
        
        QString group;
        if (groupName)
            group = QString::fromNSString(groupName);
        
        auto favorite = _app.favoritesCollection->createFavoriteLocation(locationPoint,
                                                                        elevation,
                                                                        time,
                                                                        creationTime,
                                                                        title,
                                                                        description,
                                                                        address,
                                                                        group,
                                                                        icon,
                                                                        background,
                                                                        OsmAnd::FColorRGB(r,g,b));
        
        _favorite = [[OAFavoriteItem alloc] initWithFavorite:favorite];
        [_app saveFavoritesToPermamentStorage];
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
    return _favorite.getIcon;
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
        [OAFavoritesHelper deleteFavoriteGroups:nil andFavoritesItems:@[_favorite]];
}

- (NSDictionary *)checkDuplicates:(NSString *)name group:(NSString *)group
{
    OAFavoriteItem *comparingPoint = [[OAFavoriteItem alloc] initWithLat:_favorite.getLatitude lon:_favorite.getLatitude name:_favorite.getName category:_favorite.getCategory];
    NSDictionary *result = [OAFavoritesHelper checkDuplicates:comparingPoint newName:name newCategory:group];
    [OAFavoritesHelper deleteFavoriteGroups:nil andFavoritesItems:@[comparingPoint]];
    return result;
}

- (void)savePoint:(OAPointEditingData *)data newPoint:(BOOL)newPoint
{
    [_favorite setName:data.name];
    [_favorite setDescription:data.descr];
    [_favorite setCategory:data.category];
    [_favorite setColor:data.color];
    [_favorite setIcon:data.icon];
    [_favorite setBackgroundIcon:data.backgroundIcon];
    [_favorite setAddress:data.address];
    if (newPoint)
    {
        [OAFavoritesHelper addFavorite:_favorite];
    }
    else
    {
        [OAFavoritesHelper editFavoriteName:_favorite newName:data.name group:data.category descr:[_favorite getDescription] address:[_favorite getAddress]];
    }
    [OAFavoritesHelper loadFavorites];
}

@end
