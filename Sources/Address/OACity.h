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

typedef NS_ENUM(NSInteger, EOACityType)
{
    CITY_TYPE_UNKNOWN = 0,
    CITY_TYPE_CITYORTOWN = 1,
    CITY_TYPE_VILLAGE = 3,
    CITY_TYPE_POSTCODE = 2,
};

typedef NS_ENUM(NSInteger, EOACitySubType)
{
    CITY_SUBTYPE_UNKNOWN = -1,
    
    CITY_SUBTYPE_CITY = 0,
    CITY_SUBTYPE_TOWN,
    CITY_SUBTYPE_VILLAGE,
    CITY_SUBTYPE_HAMLET,
    CITY_SUBTYPE_SUBURB,
    CITY_SUBTYPE_DISTRICT,
    CITY_SUBTYPE_NEIGHBOURHOOD
};

@interface OACity : OAAddress

@property (nonatomic, assign) std::shared_ptr<const OsmAnd::StreetGroup> city;

@property (nonatomic, readonly) EOACityType type;
@property (nonatomic, readonly) EOACitySubType subType;

- (instancetype)initWithCity:(const std::shared_ptr<const OsmAnd::StreetGroup>&)city;

+ (NSString *)getLocalizedTypeStr:(EOACitySubType)type;
+ (NSString *)getTypeStr:(EOACitySubType)type;
+ (EOACitySubType)getType:(NSString *)typeStr;
+ (CGFloat)getRadius:(NSString *)typeStr;

@end

NS_ASSUME_NONNULL_END
