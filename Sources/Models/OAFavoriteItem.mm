//
//  OAFavoriteItem.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 07.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAFavoriteItem.h"
#import "OAPointDescription.h"

@implementation OAFavoriteItem

- (double) getLatitude
{
    return self.favorite->getLatLon().latitude;
}

- (double) getLongitude
{
    return self.favorite->getLatLon().longitude;
}

- (UIColor *) getColor
{
    const auto& color = self.favorite->getColor();
    return [UIColor colorWithRed:color.r/255.0 green:color.g/255.0 blue:color.b/255.0 alpha:1.0];
}

- (BOOL) isVisible
{
    return !self.favorite->isHidden();
}

- (OAPointDescription *) getPointDescription
{
    return [[OAPointDescription alloc] initWithType:POINT_TYPE_FAVORITE name:self.favorite->getTitle().toNSString()];
}

- (NSUInteger) hash
{
    return self.favorite->hash();
}

- (BOOL) isEqual:(id)obj
{
    if (self == obj)
        return YES;
    
    if (!obj)
        return NO;
    
    if (![self isKindOfClass:[obj class]])
        return NO;
    
    OAFavoriteItem *other = (OAFavoriteItem *) obj;
    if (!self.favorite)
    {
        if (other.favorite)
            return NO;
    }
    else if (!self.favorite->isEqual(other.favorite.get()))
    {
        return NO;
    }
    return YES;
}

@end
