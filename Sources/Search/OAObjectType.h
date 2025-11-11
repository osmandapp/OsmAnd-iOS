//
//  OAObjectType.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/search/core/ObjectType.java
//  git revision f1c7d7e276fd3f2ea7cb80699387c3e8cfb7d809

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, EOAObjectType)
{
    EOAObjectTypeUndefined = -1,            // Undefined state
    EOAObjectTypeCity = 0,                  // Represents a city
    EOAObjectTypeVillage,                   // Represents a village
    EOAObjectTypeBoundary,                  // Represents a boundary
    EOAObjectTypePostcode,                  // Represents a postcode
    EOAObjectTypeStreet,                    // Represents a street
    EOAObjectTypeHouse,                     // Represents a house
    EOAObjectTypeStreetIntersection,        // Represents a street intersection
    // POI
    EOAObjectTypePoiType,                   // Represents a POI type
    EOAObjectTypePoi,                       // Represents a POI
    // LOCATION
    EOAObjectTypeLocation,                  // Represents a location
    EOAObjectTypePartialLocation,           // Represents a partial location
    // UI OBJECTS
    EOAObjectTypeFavorite,                  // Represents a favorite
    EOAObjectTypeFavoriteGroup,             // Represents a favorite froup
    EOAObjectTypeWpt,                       // Represents a waypoint
    EOAObjectTypeRecentObj,                 // Represents a recent object
    EOAObjectTypeGpxTrack,                  // Represents a track

    EOAObjectTypeRegion,                    // Represents a region
    
    EOAObjectTypeSearchStarted,             // Represents a search started message
    EOAObjectTypeSearchFinished,            // Represents a search finished message
    EOAObjectTypeFilterFinished,            // Represents a filter finished message
    EOAObjectTypeSearchApiFinished,         // Represents a search api finished message
    EOAObjectTypeSearchApiRegionFinished,   // Represents a search api region finished message
    EOAObjectTypeUnknownNameFilter,         // Represents an unknown name filter
    EOAObjectTypeIndexItem                  // Represents a resource item (region, city, etc.)
};

@interface OAObjectType : NSObject

@property (nonatomic, readonly) EOAObjectType type;

+ (instancetype)withType:(EOAObjectType)type;

+ (BOOL) hasLocation:(EOAObjectType)objecType;
+ (BOOL) isAddress:(EOAObjectType)objecType;
+ (BOOL) isTopVisible:(EOAObjectType)objecType;
+ (NSString *) toString:(EOAObjectType)objecType;
+ (OAObjectType *) getExclusiveSearchType:(EOAObjectType)objectType;
+ (double) getTypeWeight:(EOAObjectType)objectType;

+ (OAObjectType *)valueOf:(NSString *)type;

@end
