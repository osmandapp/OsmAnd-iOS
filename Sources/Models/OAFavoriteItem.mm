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
#import "OAGPXDocument.h"
#import "OAPlugin.h"
#import "OAParkingPositionPlugin.h"
#import "OAPOI.h"
#import "OAPluginsHelper.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/IFavoriteLocationsCollection.h>
#include <OsmAndCore/Utilities.h>

#define kDelimiter @"__"

@implementation OASpecialPointType
{
    NSString *_typeName;
    NSString * _resId;
    NSString *_iconName;
    UIColor *_iconColor;
}

static OASpecialPointType* _home = [[OASpecialPointType alloc] initWithTypeName:@"home" resId:@"favorite_home_category" iconName:@"special_house"];
static OASpecialPointType* _work = [[OASpecialPointType alloc] initWithTypeName:@"work" resId:@"work_button" iconName:@"special_building"];
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
        OAParkingPositionPlugin *plugin = (OAParkingPositionPlugin *)[OAPluginsHelper getPlugin:OAParkingPositionPlugin.class];
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
{
    NSString *_name;
}

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

- (instancetype)initWithLat:(double)lat lon:(double)lon name:(NSString *)name category:(NSString *)category altitude:(double)altitude timestamp:(int)timestamp
{
    self = [super init];
    if (self) {
        _favorite = [self createFavoritePointWithLat:lat lon:lon altitude:altitude timestamp:[NSDate dateWithTimeIntervalSince1970:timestamp] name:name description:nil address:nil category:category iconName:nil backgroundIconName:nil color:nil visible:YES];
        
        if (!name)
            [self setName:name];
        
        if (timestamp > 0)
            [self setTimestamp:[NSDate dateWithTimeIntervalSince1970:timestamp]];
        else
            [self setTimestamp:[NSDate date]];
        
        [self setAltitude:altitude];
        
        [self initPersonalType];
    }
    return self;
}

- (std::shared_ptr<OsmAnd::IFavoriteLocation>) createFavoritePointWithLat:(double)lat lon:(double)lon altitude:(double)altitude timestamp:(NSDate *)timestamp name:(NSString *)name description:(NSString *)description address:(NSString *)address category:(NSString *)category iconName:(NSString *)iconName backgroundIconName:(NSString *)backgroundIconName color:(UIColor *)color visible:(BOOL)visible
{
    OsmAnd::LatLon locationPoint(lat, lon);

    QString qElevation = altitude > 0 ? QString::fromNSString([self toStringAltitude:altitude]) : QString();
    QString qTime = timestamp ? QString::fromNSString([self.class toStringDate:timestamp]) : QString();
    QString qPickupTime;
    
    QString qName = name ? QString::fromNSString(name) : QString();
    QString qDescription = description ? QString::fromNSString(description) : QString();
    QString qAddress = address ? QString::fromNSString(address) : QString();
    QString qCategory = category ? QString::fromNSString(category) : QStringLiteral("");
    QString qIconName = iconName ? QString::fromNSString(iconName) : QString();
    QString qBackgroundIconName = backgroundIconName ? QString::fromNSString(backgroundIconName) : QString();
    
    UIColor *iconColor = color ? color : [OADefaultFavorite getDefaultColor];
    CGFloat r,g,b,a;
    [iconColor getRed:&r
                green:&g
                blue:&b
                alpha:&a];

    std::shared_ptr<OsmAnd::IFavoriteLocation> favorite = [OAFavoritesHelper getFavoritesCollection]->createFavoriteLocation(locationPoint,
                                                                     qElevation,
                                                                     qTime,
                                                                     qPickupTime,
                                                                     qName,
                                                                     qDescription,
                                                                     qAddress,
                                                                     qCategory,
                                                                     qIconName,
                                                                     qBackgroundIconName,
                                                                     OsmAnd::FColorARGB(a,r,g,b));
    
    favorite->setIsHidden(!visible);
    return favorite;
}

- (void) initPersonalType
{
    if ([OAFavoriteGroup isPersonal:[self getCategory]])
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
    self.favorite = [self createFavoritePointWithLat:lat
                                                 lon:lon
                                            altitude:[self getAltitude]
                                           timestamp:[self getTimestamp]
                                                name:[self getName]
                                         description:[self getDisplayName]
                                             address:[self getAddress]
                                            category:[self getCategory]
                                            iconName:[self getIcon]
                                  backgroundIconName:[self getBackgroundIcon]
                                               color:[self getColor]
                                             visible:[self isVisible]];
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

- (NSString *) getKey
{
    return [NSString stringWithFormat:@"%@%@%@", [self getName], kDelimiter, [self getCategory]];
}

- (NSString *) getName
{
    if (_name)
        return _name;
    
    QString title = self.favorite->getTitle();
    _name = title.isNull() ? @"" : title.toNSString();
    return _name;
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
        return self.favorite->getIcon().toNSString();
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
    const auto color = self.favorite->getColor();
    if (color.argb != 0)
    {
        return [UIColor colorWithRed:color.r/255.0
                               green:color.g/255.0
                                blue:color.b/255.0
                               alpha:color.a/255.0];
    }
    return [OADefaultFavorite getDefaultColor];
}

- (void) setColor:(UIColor *)color
{
    CGFloat r,g,b,a;
    [color getRed:&r
            green:&g
             blue:&b
            alpha:&a];
    
    self.favorite->setColor(OsmAnd::FColorARGB(a,r,g,b));
}

- (NSString *) getAmenityOriginName
{
    if (!self.favorite->getAmenityOriginName().isNull())
        return self.favorite->getAmenityOriginName().toNSString();
    return nil;
}

- (void) setAmenityOriginName:(NSString *)amenityOriginName
{
    self.favorite->setAmenityOriginName(QString::fromNSString(amenityOriginName));
}

- (NSString *) getComment
{
    if (!self.favorite->getAmenityOriginName().isNull())
        return self.favorite->getComment().toNSString();
    return nil;
}

- (void) setComment:(NSString *)comment
{
    self.favorite->setComment(QString::fromNSString(comment));
}

- (OAPOI *) getAmenity
{
    const QHash<QString, QString> extensionsToRead = self.favorite->getExtensions();
    if (!extensionsToRead.empty())
    {
        NSMutableDictionary<NSString *, NSString *> *extensions = [NSMutableDictionary dictionary];
        for (const auto& extension : OsmAnd::rangeOf(extensionsToRead))
            extensions[extension.key().toNSString()] = extension.value().toNSString();

        return [OAPOI fromTagValue:extensions privatePrefix:PRIVATE_PREFIX osmPrefix:OSM_PREFIX];
    }
    return nil;
}

- (void) setAmenity:(OAPOI *)amenity
{
    if (amenity)
    {
        NSDictionary<NSString *, NSString *> *extensions = [amenity toTagValue:PRIVATE_PREFIX osmPrefix:OSM_PREFIX];
        [extensions enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
            self.favorite->setExtension(QString::fromNSString(key), QString::fromNSString(value));
        }];
    }
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
    if (!self.favorite->getGroup().isEmpty())
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

- (NSDate *) getPickupTime
{
    if (!self.favorite->getPickupTime().isNull())
    {
        NSString *timeString = self.favorite->getPickupTime().toNSString();
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

- (void) setPickupTime:(NSDate *)timestamp
{
    NSString *savingString = [self.class toStringDate:timestamp];
    if (savingString)
        self.favorite->setPickupTime(QString::fromNSString(savingString));
    else
        self.favorite->setPickupTime(QString());
}

- (bool) getCalendarEvent
{
    return self.favorite->getCalendarEvent();
}
- (void) setCalendarEvent:(BOOL)calendarEvent
{
    self.favorite->setCalendarEvent(calendarEvent);
}

- (OAWptPt *) toWpt
{
    OAWptPt *pt = [[OAWptPt alloc] init];
    pt.position = CLLocationCoordinate2DMake(self.getLatitude, self.getLongitude);
    if (self.getAltitude > 0)
        pt.elevation = self.getAltitude;
    pt.time = self.getTimestamp ? self.getTimestamp.timeIntervalSince1970 : 0;
    NSMutableArray<OAGpxExtension *> *exts = [pt.extensions mutableCopy];
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
    if (self.getPickupTime)
    {
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = PICKUP_DATE_EXTENSION;
        e.value = self.favorite->getPickupTime().toNSString();
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
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = @"color";
        e.value = [self.getColor toHexARGBString].lowercaseString;
        [exts addObject:e];
    }
    if (self.getCalendarEvent)
    {
        OAGpxExtension *e = [[OAGpxExtension alloc] init];
        e.name = CALENDAR_EXTENSION;
        e.value = @"true";
        [exts addObject:e];
    }
    pt.extensions = exts;
    [pt setAmenity:[self getAmenity]];
    pt.name = self.getName;
    pt.desc = self.getDescription;
    if (self.getCategory.length > 0)
        pt.type = self.getCategory;
    if (self.getAmenityOriginName.length > 0)
        [pt setAmenityOriginName:self.getAmenityOriginName];
    return pt;
}

+ (OAFavoriteItem *)fromWpt:(OAWptPt *)pt category:(NSString *)category
{
    NSString *name = pt.name;
    NSString *categoryName = category != nil ? category : (pt.type != nil ? pt.type : @"");
    if (!name)
        name = @"";
    OAFavoriteItem *fp = [[OAFavoriteItem alloc] initWithLat:pt.position.latitude
                                                         lon:pt.position.longitude
                                                        name:name
                                                    category:categoryName
                                                    altitude:pt.elevation
                                                   timestamp:pt.time];
    [fp setDescription:pt.desc];
    [fp setComment:pt.comment];
    [fp setAmenityOriginName:pt.getAmenityOriginName];
    [fp setAmenity:[pt getAmenity]];
    
    // TODO: sync with Android

//    OAGpxExtension *visitedDateExt = [pt getExtensionByKey:VISITED_TIME_EXTENSION];
//    if (visitedDateExt)
//    {
//        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
//        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
//
//        NSString *time = visitedDateExt.value;
//        [fp setVisitedTime:[dateFormatter dateFromString:time]];
//    }

    OAGpxExtension *creationDateExt = [pt getExtensionByKey:CREATION_TIME_EXTENSION];
    if (creationDateExt)
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];

        NSString *time = creationDateExt.value;
        [fp setPickupTime:[dateFormatter dateFromString:time]];
    }

    OAGpxExtension *calendarExt = [pt getExtensionByKey:CALENDAR_EXTENSION];
    if (calendarExt)
        [fp setCalendarEvent:[calendarExt.value isEqualToString:@"true"]];

    [fp setColor:UIColorFromARGB([pt getColor:0])];

    OAGpxExtension *hiddenExt = [pt getExtensionByKey:EXTENSION_HIDDEN];
    [fp setVisible:hiddenExt ? [hiddenExt.value isEqualToString:@"true"] : YES];

    [fp setAddress:[pt getAddress]];
    [fp setIcon:[pt getIcon]];
    [fp setBackgroundIcon:[pt getBackgroundIcon]];

    return fp;
}

+ (NSString *) toStringDate:(NSDate *)date
{
    if (!date || [date timeIntervalSince1970] <= 0)
        return nil;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd_HH:mm:ss"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    dateString = [dateString stringByReplacingOccurrencesOfString:@"_" withString:@"T"];
    return  [dateString stringByAppendingString:@"Z"];
}

- (UIImage *) getCompositeIcon
{
    return [OAFavoritesHelper getCompositeIcon:[self getIcon] backgroundIcon:[self getBackgroundIcon] color:[self getColor]];
}

@end
