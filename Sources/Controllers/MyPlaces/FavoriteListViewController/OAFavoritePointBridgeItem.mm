//
//  OAFavoritePointBridgeItem.m
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 15.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAFavoritePointBridgeItem.h"
#import "OAFavoriteItem.h"
#import "OsmAndApp.h"
#import "OALocationServices.h"

#include <OsmAndCore/Utilities.h>

@implementation OAFavoritePointBridgeItem
{
    OAFavoriteItem *_favorite;
}

- (instancetype)initWithFavorite:(OAFavoriteItem *)favorite
{
    self = [super init];
    if (self)
    {
        _identifier = [favorite getKey] ?: @"";
        _groupName = [favorite getCategory] ?: @"";
        _title = [favorite getDisplayName] ?: @"";
        _address = [favorite getAddress];
        _displayGroupName = [favorite getCategoryDisplayName] ?: @"";
        _itemDescription = [favorite getDescription];
        _encodedNameForLink = [[favorite getName] escapeUrl] ?: @"";
        _distance = [self.class distanceForFavorite:favorite];
        _direction = [self.class directionForFavorite:favorite];
        _latitude = [favorite getLatitude];
        _longitude = [favorite getLongitude];
        _timestampDate = [favorite getTimestamp];
        _isVisible = [favorite isVisible];
        _favorite = favorite;
    }

    return self;
}

- (UIImage *)icon
{
    return [_favorite getCompositeIcon];
}

- (void)updateDistanceAndDirection
{
    _distance = [self.class distanceForFavorite:_favorite];
    _direction = [self.class directionForFavorite:_favorite];
}

- (void)updateDistanceAndDirectionFromMapCenter:(CLLocationCoordinate2D)mapCenterCoordinate mapAzimuth:(CLLocationDirection)mapAzimuth
{
    _distance = [self.class distanceForFavorite:_favorite fromCoordinate:mapCenterCoordinate];
    _direction = [self.class directionForFavorite:_favorite fromCoordinate:mapCenterCoordinate sourceDirection:mapAzimuth];
}

+ (NSNumber *)distanceForFavorite:(OAFavoriteItem *)favorite
{
    CLLocation *location = [OsmAndApp instance].locationServices.lastKnownLocation;
    if (!location || !favorite.favorite)
        return nil;

    const auto &favoritePosition31 = favorite.favorite->getPosition31();
    const auto favoriteLon = OsmAnd::Utilities::get31LongitudeX(favoritePosition31.x);
    const auto favoriteLat = OsmAnd::Utilities::get31LatitudeY(favoritePosition31.y);
    const auto distance = OsmAnd::Utilities::distance(location.coordinate.longitude, location.coordinate.latitude, favoriteLon, favoriteLat);
    return @(distance);
}

+ (NSNumber *)distanceForFavorite:(OAFavoriteItem *)favorite fromCoordinate:(CLLocationCoordinate2D)coordinate
{
    if (!favorite.favorite || !CLLocationCoordinate2DIsValid(coordinate))
        return nil;

    const auto &favoritePosition31 = favorite.favorite->getPosition31();
    const auto favoriteLon = OsmAnd::Utilities::get31LongitudeX(favoritePosition31.x);
    const auto favoriteLat = OsmAnd::Utilities::get31LatitudeY(favoritePosition31.y);
    const auto distance = OsmAnd::Utilities::distance(coordinate.longitude, coordinate.latitude, favoriteLon, favoriteLat);
    return @(distance);
}

+ (CGFloat)directionForFavorite:(OAFavoriteItem *)favorite fromCoordinate:(CLLocationCoordinate2D)coordinate sourceDirection:(CLLocationDirection)sourceDirection
{
    if (!favorite.favorite || !CLLocationCoordinate2DIsValid(coordinate))
        return favorite.direction;

    const auto &favoritePosition31 = favorite.favorite->getPosition31();
    const auto favoriteLon = OsmAnd::Utilities::get31LongitudeX(favoritePosition31.x);
    const auto favoriteLat = OsmAnd::Utilities::get31LatitudeY(favoritePosition31.y);
    double bearing;
    [OALocationServices computeDistanceAndBearing:coordinate.latitude lon1:coordinate.longitude lat2:favoriteLat lon2:favoriteLon distance:nil initialBearing:&bearing];
    CLLocationDirection direction = isnan(sourceDirection) ? 0.0 : sourceDirection;
    return OsmAnd::Utilities::normalizedAngleDegrees(bearing - direction) * (M_PI / 180);
}

+ (CGFloat)directionForFavorite:(OAFavoriteItem *)favorite
{
    OsmAndAppInstance app = [OsmAndApp instance];
    CLLocation *location = app.locationServices.lastKnownLocation;
    if (!location || !favorite.favorite)
        return favorite.direction;

    CLLocationDirection newHeading = app.locationServices.lastKnownHeading;
    CLLocationDirection newDirection = location.speed >= 1 && location.course >= 0.0 ? location.course : newHeading;
    const auto &favoritePosition31 = favorite.favorite->getPosition31();
    const auto favoriteLon = OsmAnd::Utilities::get31LongitudeX(favoritePosition31.x);
    const auto favoriteLat = OsmAnd::Utilities::get31LatitudeY(favoritePosition31.y);
    CGFloat itemDirection = [app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:favoriteLat longitude:favoriteLon]];
    return OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
}

@end
