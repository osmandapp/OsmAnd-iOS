//
//  OAFavoriteItem.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 07.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAFavoriteItem.h"
#import "OAPointDescription.h"
#import "Localization.h"
#import "OADefaultFavorite.h"
#import "OsmAndApp.h"
#import "OAColors.h"
#import "OAFavoritesHelper.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/IFavoriteLocationsCollection.h>
#include <OsmAndCore/Utilities.h>
#define kPersonalCategory @"personal"

@implementation OASpecialPointType
{
    NSString *_typeName;
    NSString * _resId;
    NSString *_iconName;
    UIColor *_iconColor;
}

static OASpecialPointType* _home = [[OASpecialPointType alloc] initWithTypeName:@"home" resId:@"home_pt" iconName:@"special_house"];
static OASpecialPointType* _work = [[OASpecialPointType alloc] initWithTypeName:@"work" resId:@"work_pt" iconName:@"special_building"];
static OASpecialPointType* _parking = [[OASpecialPointType alloc] initWithTypeName:@"parking" resId:@"map_widget_parking" iconName:@"parking"];
static NSArray<OASpecialPointType *> *_values = @[_home, _work, _parking];

- (instancetype)initWithTypeName:(NSString *)typeName resId:(NSString *)resId iconName:(NSString *)iconName
{
    self = [super init];
    if (self) {
        _typeName = typeName;
        _resId = resId;
        _iconName = iconName;
    }
    return self;
}

+ (OASpecialPointType *) HOME
{
    return _home;
}

+ (OASpecialPointType *) WORK
{
    return _work;
}

+ (OASpecialPointType *) PARKING
{
    return _parking;
}

+ (NSArray<OASpecialPointType *> *) VALUES
{
    return _values;
}

- (NSString *) getCategory
{
    return kPersonalCategory;
}

- (NSString *) getName
{
    return _typeName;
}

- (NSString *) getIconName
{
    if (self == _parking)
    {
        //TODO: parking plugin code here
        return @"special_parking_time_limited";
    }
    return _iconName;
}

- (UIColor *) getIconColor
{
    if (self == _parking)
        return ((OAFavoriteColor *)[OADefaultFavorite builtinColors][0]).color;
    else
        return ((OAFavoriteColor *)[OADefaultFavorite builtinColors][2]).color;
}

- (NSString *) getHumanString
{
    return OALocalizedString(_resId);
}

@end



@implementation OAFavoriteItem

- (instancetype)initWithFavorite:(std::shared_ptr<OsmAnd::IFavoriteLocation>)favorite
{
    self = [super init];
    if (self) {
        _favorite = favorite;
        
        //TODO: setTimeStamp here
        
        [self initPersonalType];
    }
    return self;
}

- (instancetype)initWithLat:(double)lat lon:(double)lon name:(NSString *)name group:(NSString *)group
{
    self = [super init];
    if (self) {
        _favorite = [self createFavoritePointWithLat:lat lon:lon name:name description:nil address:nil group:group iconName:nil backgroundIconName:nil color:nil visible:YES];
        
        if (!name)
            [self setFavoriteName:name];
        
        //TODO: setTimeStamp here
        
        [self initPersonalType];
    }
    return self;
}

- (std::shared_ptr<OsmAnd::IFavoriteLocation>) createFavoritePointWithLat:(double)lat lon:(double)lon name:(NSString *)name description:(NSString *)description address:(NSString *)address group:(NSString *)group iconName:(NSString *)iconName backgroundIconName:(NSString *)backgroundIconName color:(UIColor *)color visible:(BOOL)visible
{
    OsmAnd::PointI locationPoint;
    locationPoint.x = OsmAnd::Utilities::get31TileNumberX(lon);
    locationPoint.y = OsmAnd::Utilities::get31TileNumberY(lat);

    QString qName = name ? QString::fromNSString(name) : QString::null;
    QString qDescription = description ? QString::fromNSString(description) : QString::null;
    QString qAddress = address ? QString::fromNSString(address) : QString::null;
    QString qGroup = group ? QString::fromNSString(group) : QString::null;
    QString qIconName = iconName ? QString::fromNSString(iconName) : QString::null;
    QString qBackgroundIconName = backgroundIconName ? QString::fromNSString(backgroundIconName) : QString::null;
    
    UIColor *iconColor = color ? color : ((OAFavoriteColor *)[OADefaultFavorite builtinColors][0]).color;
    CGFloat r,g,b,a;
    [iconColor getRed:&r
                green:&g
                blue:&b
                alpha:&a];

    std::shared_ptr<OsmAnd::IFavoriteLocation> favorite = [OsmAndApp instance].favoritesCollection->createFavoriteLocation(locationPoint,
                                                                     qName,
                                                                     qDescription,
                                                                     qAddress,
                                                                     qGroup,
                                                                     qIconName,
                                                                     qBackgroundIconName,
                                                                     OsmAnd::FColorRGB(r,g,b));
    
    favorite->setIsHidden(!visible);
    return favorite;
}

- (void) initPersonalType
{
    if ([[self getFavoriteGroup] isEqualToString:kPersonalCategory])
    {
        for (OASpecialPointType *pointType in [OASpecialPointType VALUES])
        {
            if ([[pointType getName] isEqualToString:[self getFavoriteName]])
                self.specialPointType = pointType;
        }
    }
}

- (double) getLatitude
{
    return self.favorite->getLatLon().latitude;
}

- (double) getLongitude
{
    return self.favorite->getLatLon().longitude;
}

- (void) setLat:(double)lat lon:(double)lon
{
    auto newFavorite = [self createFavoritePointWithLat:lat lon:lon name:[self getFavoriteName] description:[self getDisplayName] address:[self getFavoriteAddress] group:[self getFavoriteGroup] iconName:[self getFavoriteIcon] backgroundIconName:[self getFavoriteBackground] color:[self getColor] visible:[self getFavoriteVisible]];
    
    [OsmAndApp instance].favoritesCollection->removeFavoriteLocation(self.favorite);
    self.favorite = newFavorite;
}

- (BOOL) isSpecialPoint
{
    return self.specialPointType;
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

- (NSString *) getOverlayIconName
{
    if ([self isSpecialPoint])
        return [self.specialPointType getIconName];
    return [self getFavoriteIcon];
}

- (NSString *) getDisplayName
{
    if ([self isSpecialPoint])
        return [self.specialPointType getHumanString];
    return [self getFavoriteName];
}

- (BOOL) isAddressSpecified
{
    NSString *address = [self getFavoriteAddress];
    return address && address.length > 0;
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
    [self initPersonalType];
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

- (UIColor *) getColor
{
    return [self getFavoriteColor];
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

- (BOOL) getFavoriteVisible
{
    return !self.favorite->isHidden();
}

- (void) setFavoriteVisible:(BOOL)isVisible
{
    self.favorite->setIsHidden(!isVisible);
}

- (NSString *) getFavoriteGroup
{
    if (!self.favorite->getGroup().isNull())
        return self.favorite->getGroup().toNSString();
    else
        return @"";
}

- (NSString *) getFavoriteGroupDisplayName
{
    return [OAFavoriteGroup getDisplayName:[self getFavoriteGroup]];
}


- (void) setFavoriteGroup:(NSString *)groupName
{
    self.favorite->setGroup(QString::fromNSString(groupName));
    [self initPersonalType];
}

- (void) initAltitude
{
    //TODO: implement
}

- (double) getAltitude
{
    //TODO: implement
    return 0;
}

- (void) setAltitude:(double)altitude
{
    //TODO: implement
}

- (long) getTimestamp
{
    //TODO: implement
    return 0;
}

- (long) setTimestamp:(long)timestamp
{
    //TODO: implement
}

@end
