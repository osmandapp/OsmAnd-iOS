//
//  OAObjectType.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  revision 878491110c391829cc1f42eace8dc582cb35e08e

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, EOAObjectType)
{
    CITY = 0,
    VILLAGE,
    POSTCODE,
    STREET,
    HOUSE,
    STREET_INTERSECTION,
    // POI
    POI_TYPE,
    POI,
    // LOCATION
    LOCATION,
    PARTIAL_LOCATION,
    // UI OBJECTS
    FAVORITE,
    WPT,
    RECENT_OBJ,

    REGION,
    SEARCH_API_FINISHED,
    SEARCH_API_REGION_FINISHED,
    UNKNOWN_NAME_FILTER
};

@interface OAObjectType : NSObject

+ (BOOL) hasLocation:(EOAObjectType)objecType;
+ (BOOL) isAddress:(EOAObjectType)objecType;
+ (NSString *)toString:(EOAObjectType)objecType;

@end
