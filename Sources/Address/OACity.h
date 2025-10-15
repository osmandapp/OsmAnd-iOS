//
//  OACity.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAAddress.h"

#include <OsmAndCore/Data/StreetGroup.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EOACityType) // CityType
{
    CITY_TYPE_UNKNOWN = -1,
    
    CITY_TYPE_CITY = 0,      // 0. City
    CITY_TYPE_TOWN,          // 1. Town
    CITY_TYPE_VILLAGE,       // 2. Village
    CITY_TYPE_HAMLET,        // 3. Hamlet - Small village
    CITY_TYPE_SUBURB,        // 4. Mostly district of the city (introduced to avoid duplicate streets in city) -
                             //    however BOROUGH, DISTRICT, NEIGHBOURHOOD could be used as well for that purpose
                             //    Main difference stores own streets to search and list by it
    CITY_TYPE_BOUNDARY,      // 5. boundary no streets
    CITY_TYPE_POSTCODE,      // 6. write this could be activated after 5.2 release
    
    // not stored entities but registered to uniquely identify streets as SUBURB
    CITY_TYPE_BOROUGH,
    CITY_TYPE_DISTRICT,
    CITY_TYPE_NEIGHBOURHOOD,
    CITY_TYPE_CENSUS
};

@interface OACity : OAAddress

@property (nonatomic, assign) std::shared_ptr<const OsmAnd::StreetGroup> city;

@property (nonatomic, readonly) EOACityType type;

- (instancetype)initWithCity:(const std::shared_ptr<const OsmAnd::StreetGroup>&)city;

+ (NSString *)getLocalizedTypeStr:(EOACityType)type;
+ (NSString *)getTypeStr:(EOACityType)type;
+ (EOACityType)getType:(NSString *)typeStr;
+ (CGFloat)getRadius:(NSString *)typeStr;

@end

NS_ASSUME_NONNULL_END
