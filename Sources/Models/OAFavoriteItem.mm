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
#import "OAGPXDocumentPrimitives.h"
#import "OAPlugin.h"
#import "OAParkingPositionPlugin.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/IFavoriteLocationsCollection.h>
#include <OsmAndCore/Utilities.h>

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
        OAParkingPositionPlugin *plugin = (OAParkingPositionPlugin *)[OAPlugin getPlugin:OAParkingPositionPlugin.class];
        if (plugin && plugin.getParkingType)
            return @"special_parking_time_limited";
        else
            return @"amenity_parking";
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
        [self initPersonalType];
    }
    return self;
}

- (instancetype)initWithLat:(double)lat lon:(double)lon name:(NSString *)name category:(NSString *)category
{
    self = [super init];
    if (self) {
        _favorite = [self createFavoritePointWithLat:lat lon:lon altitude:0 timestamp:NSDate.date name:name description:nil address:nil category:category iconName:nil backgroundIconName:nil color:nil visible:YES];
        
        if (!name)
            [self setName:name];
        
        [self setTimestamp:[NSDate date]];
        [self initPersonalType];
    }
    return self;
}

- (instancetype)initWithLat:(double)lat lon:(double)lon name:(NSString *)name category:(NSString *)category altitude:(double)altitude timestamp:(NSDate *)timestamp
{
    self = [super init];
    if (self) {
        _favorite = [self createFavoritePointWithLat:lat lon:lon altitude:altitude timestamp:timestamp name:name description:nil address:nil category:category iconName:nil backgroundIconName:nil color:nil visible:YES];
        
        if (!name)
            [self setName:name];
        
        [self setAltitude:altitude];
        [self setTimestamp:timestamp ? timestamp : [NSDate date]];
        [self initPersonalType];
    }
    return self;
}

- (std::shared_ptr<OsmAnd::IFavoriteLocation>) createFavoritePointWithLat:(double)lat lon:(double)lon altitude:(double)altitude timestamp:(NSDate *)timestamp name:(NSString *)name description:(NSString *)description address:(NSString *)address category:(NSString *)category iconName:(NSString *)iconName backgroundIconName:(NSString *)backgroundIconName color:(UIColor *)color visible:(BOOL)visible
{
    OsmAnd::PointI locationPoint;
    locationPoint.x = OsmAnd::Utilities::get31TileNumberX(lon);
    locationPoint.y = OsmAnd::Utilities::get31TileNumberY(lat);

    QString qElevation = altitude > 0 ? QString::fromNSString([self toStringAltitude:altitude]) : QString();
    QString qTime = timestamp ? QString::fromNSString([self.class toStringDate:timestamp]) : QString();
    QString qCreationTime = QString::fromNSString([self.class toStringDate:[NSDate date]]);
    
    QString qName = name ? QString::fromNSString(name) : QString();
    QString qDescription = description ? QString::fromNSString(description) : QString();
    QString qAddress = address ? QString::fromNSString(address) : QString();
    QString qCategory = category ? QString::fromNSString(category) : QString();
    QString qIconName = iconName ? QString::fromNSString(iconName) : QString();
    QString qBackgroundIconName = backgroundIconName ? QString::fromNSString(backgroundIconName) : QString();
    
    UIColor *iconColor = color ? color : ((OAFavoriteColor *)[OADefaultFavorite builtinColors][0]).color;
    CGFloat r,g,b,a;
    [iconColor getRed:&r
                green:&g
                blue:&b
                alpha:&a];

    std::shared_ptr<OsmAnd::IFavoriteLocation> favorite = [OsmAndApp instance].favoritesCollection->createFavoriteLocation(locationPoint,
                                                                     qElevation,
                                                                     qTime,
                                                                     qCreationTime,
                                                                     qName,
                                                                     qDescription,
                                                                     qAddress,
                                                                     qCategory,
                                                                     qIconName,
                                                                     qBackgroundIconName,
                                                                     OsmAnd::FColorRGB(r,g,b));
    
    favorite->setIsHidden(!visible);
    return favorite;
}

- (void) initPersonalType
{
    if ([[self getCategory] isEqualToString:kPersonalCategory])
    {
        for (OASpecialPointType *pointType in [OASpecialPointType VALUES])
        {
            if ([[pointType getName] isEqualToString:[self getName]])
            {
                self.specialPointType = pointType;
                return;
            }
        }
    }
    self.specialPointType = nil;
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
    auto newFavorite = [self createFavoritePointWithLat:lat lon:lon altitude:[self getAltitude] timestamp:[self getTimestamp] name:[self getName] description:[self getDisplayName] address:[self getAddress] category:[self getCategory] iconName:[self getIcon] backgroundIconName:[self getBackgroundIcon] color:[self getColor] visible:[self isVisible]];
    
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
    return [self getIcon];
}

- (NSString *) getDisplayName
{
    if ([self isSpecialPoint])
        return [self.specialPointType getHumanString];
    return [self getName];
}

- (BOOL) isAddressSpecified
{
    NSString *address = [self getAddress];
    return address && address.length > 0;
}

#pragma mark - Getters and setters

- (NSString *) getName
{
    if (!self.favorite->getTitle().isNull())
        return self.favorite->getTitle().toNSString();
    else
        return @"";
}

- (void) setName:(NSString *)name
{
    self.favorite->setTitle(QString::fromNSString(name));
    [self initPersonalType];
}

- (NSString *) getDescription
{
    if (!self.favorite->getDescription().isNull())
        return self.favorite->getDescription().toNSString();
    else
        return @"";
}

- (void) setDescription:(NSString *)description
{
    self.favorite->setDescription(QString::fromNSString(description));
}

- (NSString *) getAddress
{
    if (!self.favorite->getAddress().isNull())
        return self.favorite->getAddress().toNSString();
    else
        return @"";
}

- (void) setAddress:(NSString *)address
{
    self.favorite->setAddress(QString::fromNSString(address));
}

- (NSString *) getIcon
{
    if (!self.favorite->getIcon().isNull())
    {
        NSString *iconName = self.favorite->getIcon().toNSString();
        if ([[OAFavoritesHelper getFlatIconNamesList] containsObject:iconName])
            return iconName;
    }
    return @"special_star";
}

- (void) setIcon:(NSString *)icon
{
    self.favorite->setIcon(QString::fromNSString(icon));
}

- (NSString *) getBackgroundIcon
{
    
    if (!self.favorite->getBackground().isNull())
    {
        NSString *iconName = self.favorite->getBackground().toNSString();
        if ([[OAFavoritesHelper getFlatBackgroundIconNamesList] containsObject:iconName])
            return iconName;
    }
    return @"circle";
}

- (void) setBackgroundIcon:(NSString *)backgroundIcon
{
    self.favorite->setBackground(QString::fromNSString(backgroundIcon));
}

- (UIColor *) getColor
{
    UIColor *storedColor = [UIColor colorWithRed:self.favorite->getColor().r/255.0 green:self.favorite->getColor().g/255.0 blue:self.favorite->getColor().b/255.0 alpha:1.0];
    UIColor *nearestColor = [OADefaultFavorite nearestFavColor:storedColor].color;
    return nearestColor;
}

- (void) setColor:(UIColor *)color
{
    CGFloat r,g,b,a;
    [color getRed:&r
            green:&g
             blue:&b
            alpha:&a];
    
    self.favorite->setColor(OsmAnd::FColorRGB(r,g,b));
}

- (BOOL) isVisible
{
    return !self.favorite->isHidden();
}

- (void) setVisible:(BOOL)isVisible
{
    self.favorite->setIsHidden(!isVisible);
}

- (NSString *) getCategory
{
    if (!self.favorite->getGroup().isNull())
        return self.favorite->getGroup().toNSString();
    else
        return @"";
}

- (NSString *) getCategoryDisplayName
{
    return [OAFavoriteGroup getDisplayName:[self getCategory]];
}


- (void) setCategory:(NSString *)category
{
    self.favorite->setGroup(QString::fromNSString(category));
    [self initPersonalType];
}

- (void) initAltitude
{
    //TODO: implement
    [self setAltitude:0];
}

- (double) getAltitude
{
    if (!self.favorite->getElevation().isNull())
    {
        NSString *storedString = self.favorite->getElevation().toNSString();
        return [storedString doubleValue];
    }
    else
    {
        return 0;
    }
}

- (void) setAltitude:(double)altitude
{
    NSString *savingString = [self toStringAltitude:altitude];
    self.favorite->setElevation(QString::fromNSString(savingString));
}

- (NSString *) toStringAltitude:(double)altitude
{
    return [NSString stringWithFormat:@"%.1lf", altitude];
}

- (NSDate *) getTimestamp
{
    if (!self.favorite->getTime().isNull())
    {
        NSString *timeString = self.favorite->getTime().toNSString();
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        return [dateFormat dateFromString:timeString];
    }
    else
    {
        return nil;
    }
}

- (void) setTimestamp:(NSDate *)timestamp
{
    NSString *savingString = [self.class toStringDate:timestamp];
    if (savingString)
        self.favorite->setTime(QString::fromNSString(savingString));
    else
        self.favorite->setTime(QString());
}

- (NSDate *) getCreationTime
{
    if (!self.favorite->getCreationTime().isNull())
    {
        NSString *timeString = self.favorite->getCreationTime().toNSString();
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        return [dateFormat dateFromString:timeString];
    }
    else
    {
        return nil;
    }
}

- (void) setCreationTime:(NSDate *)timestamp
{
    NSString *savingString = [self.class toStringDate:timestamp];
    if (savingString)
        self.favorite->setCreationTime(QString::fromNSString(savingString));
    else
        self.favorite->setCreationTime(QString());
}

- (bool) getCalendarEvent
{
    return self.favorite->getCalendarEvent();
}
- (void) setCalendarEvent:(BOOL)calendarEvent
{
    self.favorite->setCalendarEvent(calendarEvent);
}

- (OAGpxWpt *) toWpt
{
    OAGpxWpt *pt = [[OAGpxWpt alloc] init];
    pt.position = CLLocationCoordinate2DMake(self.getLatitude, self.getLongitude);
    if (self.getAltitude > 0)
        pt.elevation = self.getAltitude;
    pt.time = self.getTimestamp ? self.getTimestamp.timeIntervalSince1970 : 0;
    if (!pt.extraData)
        pt.extraData = [[OAGpxExtensions alloc] init];
    NSMutableArray<OAGpxExtension *> *exts = [NSMutableArray arrayWithArray:((OAGpxExtensions *)pt.extraData).extensions];
    if (!self.isVisible)
    {
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = EXTENSION_HIDDEN;
        e.value = @"true";
        [exts addObject:e];
    }
    if (self.isAddressSpecified)
    {
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = ADDRESS_EXTENSION;
        e.value = self.getAddress;
        [exts addObject:e];
    }
    if (self.getCreationTime)
    {
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = CREATION_TIME_EXTENSION;
        e.value = self.favorite->getCreationTime().toNSString();
        [exts addObject:e];
    }
    if (self.getIcon)
    {
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = ICON_NAME_EXTENSION;
        e.value = self.getIcon;
        [exts addObject:e];
    }
    if (self.getBackgroundIcon)
    {
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = BACKGROUND_TYPE_EXTENSION;
        e.value = self.getBackgroundIcon;
        [exts addObject:e];
    }
    if (self.getColor)
    {
        [pt setColor:self.getColor.toHexString];
    }
    if (self.getCalendarEvent)
    {
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = CALENDAR_EXTENSION;
        e.value = @"true";
        [exts addObject:e];
    }
    ((OAGpxExtensions *)pt.extraData).extensions = exts;
    pt.name = self.getName;
    pt.desc = self.getDescription;
    if (self.getCategory.length > 0)
        pt.type = self.getCategory;
    // TODO: sync with Android after editing!
//    if (getOriginObjectName().length() > 0) {
//        pt.comment = getOriginObjectName();
//    }
    return pt;
}

+ (NSString *) toStringDate:(NSDate *)date
{
    if (!date)
        return nil;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [dateFormatter stringFromDate:date];
    return [NSString stringWithFormat:@"%@T%@Z",dateString, timeString];
}

- (UIImage *) getCompositeIcon
{
    UIImage *resultImg;
    NSString *backgrounfIconName = [@"bg_point_" stringByAppendingString:[self getBackgroundIcon]];
    UIImage *backgroundImg = [UIImage imageNamed:backgrounfIconName];
    backgroundImg = [OAUtilities tintImageWithColor:backgroundImg color:[self getColor]];

    NSString *iconName = [@"mx_" stringByAppendingString:[self getIcon]];
    UIImage *iconImgOrig = [UIImage imageNamed:[OAUtilities drawablePath:iconName]];
    UIImage *iconImg = [UIImage imageWithCGImage:iconImgOrig.CGImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
    iconImg = [OAUtilities tintImageWithColor:iconImg color:UIColor.whiteColor];

    CGFloat centredIconOffset = (backgroundImg.size.width - iconImg.size.width) / 2.0;
    UIGraphicsBeginImageContextWithOptions(backgroundImg.size, NO, [UIScreen mainScreen].scale);
    [backgroundImg drawInRect:CGRectMake(0.0, 0.0, backgroundImg.size.width, backgroundImg.size.height)];
    [iconImg drawInRect:CGRectMake(centredIconOffset, centredIconOffset, iconImg.size.width, iconImg.size.height)];
    resultImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resultImg;
}

@end
