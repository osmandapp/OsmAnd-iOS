//
//  OAFavoriteItem.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 07.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAFavoriteItem.h"
#import "OAPointDescription.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>

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

#pragma mark - Getters and setters

- (NSString *) getFavoriteName
{
    if (!self.favorite->getTitle().isNull())
        return self.favorite->getTitle().toNSString();
    else
        return @"";
}

- (void) setFavoriteName:(NSString *)name
{
    self.favorite->setTitle(QString::fromNSString(name));
}

- (NSString *) getFavoriteDesc
{
    if (!self.favorite->getDescription().isNull())
        return self.favorite->getDescription().toNSString();
    else
        return @"";
}

- (void) setFavoriteDesc:(NSString *)desc
{
    self.favorite->setDescription(QString::fromNSString(desc));
}

- (NSString *) getFavoriteAddress
{
    if (!self.favorite->getAddress().isNull())
        return self.favorite->getAddress().toNSString();
    else
        return @"";
}

- (void) setFavoriteAddress:(NSString *)address
{
    self.favorite->setAddress(QString::fromNSString(address));
}

- (NSString *) getFavoriteIcon
{
    return self.favorite->getIcon().toNSString();
}

- (void) setFavoriteIcon:(NSString *)icon
{
    self.favorite->setIcon(QString::fromNSString(icon));
}

- (NSString *) getFavoriteBackground
{
    return self.favorite->getBackground().toNSString();
}

- (void) setFavoriteBackground:(NSString *)background
{
    self.favorite->setBackground(QString::fromNSString(background));
}

- (UIColor *) getFavoriteColor
{
    return [UIColor colorWithRed:self.favorite->getColor().r/255.0 green:self.favorite->getColor().g/255.0 blue:self.favorite->getColor().b/255.0 alpha:1.0];
}

- (void) setFavoriteColor:(UIColor *)color
{
    CGFloat r,g,b,a;
    [color getRed:&r
            green:&g
             blue:&b
            alpha:&a];
    
    self.favorite->setColor(OsmAnd::FColorRGB(r,g,b));
}

- (BOOL) getFavoriteHidden
{
    return self.favorite->isHidden();
}

- (void) setFavoriteHidden:(BOOL)isHidden
{
    self.favorite->setIsHidden(isHidden);
}

- (NSString *) getFavoriteGroup
{
    if (!self.favorite->getGroup().isNull())
        return self.favorite->getGroup().toNSString();
    else
        return @"";
}

- (void) setFavoriteGroup:(NSString *)groupName
{
    self.favorite->setGroup(QString::fromNSString(groupName));
}

@end
