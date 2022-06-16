//
//  OAOSMSettings.h
//  OsmAnd
//
//  Created by Paul on 1/22/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/osm/edit/OSMSettings.java
//  git revision b439f2dd5beb81e6bfe5ba04ee53f4d539c9e1f7

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EOAOsmTagKey)
{
    NAME = 0,
    NAME_EN,
    LOCK_NAME,
    
    // ways
    HIGHWAY,
    BUILDING,
    BOUNDARY,
    POSTAL_CODE,
    RAILWAY,
    STATION,
    ONEWAY,
    LAYER,
    BRIDGE,
    TUNNEL,
    TOLL,
    JUNCTION,
    
    // transport
    ROUTE,
    ROUTE_MASTER,
    BRAND,
    OPERATOR,
    REF,
    RCN_REF,
    RWN_REF,
    
    // address
    PLACE,
    ADDR_HOUSE_NUMBER,
    ADDR2_HOUSE_NUMBER,
    ADDR_HOUSE_NAME,
    ADDR_STREET,
    ADDR_STREET2,
    ADDR2_STREET,
    ADDR_CITY,
    ADDR_PLACE,
    ADDR_POSTCODE,
    ADDR_INTERPOLATION,
    ADDRESS_TYPE,
    ADDRESS_HOUSE,
    TYPE,
    IS_IN,
    LOCALITY,
    
    // POI
    AMENITY,
    SHOP,
    LANDUSE,
    OFFICE,
    EMERGENCY,
    MILITARY,
    ADMINISTRATIVE,
    MAN_MADE,
    BARRIER,
    LEISURE,
    TOURISM,
    SPORT,
    HISTORIC,
    NATURAL,
    INTERNET_ACCESS,
    
    
    CONTACT_WEBSITE,
    CONTACT_PHONE,
    
    OSM_TAG_OPENING_HOURS,
    PHONE,
    DESCRIPTION,
    WEBSITE,
    URL,
    WIKIPEDIA,
    
    ADMIN_LEVEL,
    PUBLIC_TRANSPORT,
    ENTRANCE,
    COLOUR
};
// Unused in Android
//typedef NS_ENUM(NSInteger, EOAOSMHighwayTypes)
//{
//    TRUNK, MOTORWAY, PRIMARY, SECONDARY, RESIDENTIAL, TERTIARY, SERVICE, TRACK,
//    // TODO is link needed?
//    TRUNK_LINK, MOTORWAY_LINK, PRIMARY_LINK, SECONDARY_LINK, RESIDENTIAL_LINK, TERTIARY_LINK, SERVICE_LINK, TRACK_LINK,
//
//};

@interface OAOSMSettings : NSObject

+(NSString *)getOSMKey:(EOAOsmTagKey)key;

// Unused
//+(BOOL) wayForCar:(NSString *) tagHighway;

@end

NS_ASSUME_NONNULL_END
