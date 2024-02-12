//
//  OACity.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OACity.h"
#import "Localization.h"

@interface OACity ()

@property (nonatomic) EOAAddressType addressType;

@end

@implementation OACity

@dynamic addressType;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.addressType = ADDRESS_TYPE_CITY;
    }
    return self;
}

- (instancetype)initWithCity:(const std::shared_ptr<const OsmAnd::StreetGroup>&)city;
{
    self = [super initWithAddress:city];
    if (self)
    {
        self.city = city;
        _type = (EOACityType)city->type;
        _subType = (EOACitySubType)city->subtype;
    }
    return self;
}

-(NSString *)iconName
{
    return @"ic_action_building_number";
}

+ (NSString *)getLocalizedTypeStr:(EOACitySubType)type
{
    switch (type)
    {
        case CITY_SUBTYPE_CITY:
            return OALocalizedString(@"city_type_city");
        case CITY_SUBTYPE_TOWN:
            return OALocalizedString(@"city_type_town");
        case CITY_SUBTYPE_VILLAGE:
            return OALocalizedString(@"city_type_village");
        case CITY_SUBTYPE_HAMLET:
            return OALocalizedString(@"city_type_hamlet");
        case CITY_SUBTYPE_SUBURB:
            return OALocalizedString(@"city_type_suburb");
        case CITY_SUBTYPE_DISTRICT:
            return OALocalizedString(@"city_type_district");
        case CITY_SUBTYPE_NEIGHBOURHOOD:
            return OALocalizedString(@"city_type_neighbourhood");
        default:
            return OALocalizedString(@"city_type_city");
    }
}

+ (NSString *)getTypeStr:(EOACitySubType)type
{
    switch (type)
    {
        case CITY_SUBTYPE_CITY:
            return @"city";
        case CITY_SUBTYPE_TOWN:
            return @"town";
        case CITY_SUBTYPE_VILLAGE:
            return @"village";
        case CITY_SUBTYPE_HAMLET:
            return @"hamlet";
        case CITY_SUBTYPE_SUBURB:
            return @"suburb";
        case CITY_SUBTYPE_DISTRICT:
            return @"district";
        case CITY_SUBTYPE_NEIGHBOURHOOD:
            return @"neighbourhood";
        default:
            return @"";
    }
}

+ (EOACitySubType)getType:(NSString *)typeStr;
{
    if ([typeStr isEqualToString:@"city"])
        return CITY_SUBTYPE_CITY;
    if ([typeStr isEqualToString:@"town"])
        return CITY_SUBTYPE_TOWN;
    if ([typeStr isEqualToString:@"village"])
        return CITY_SUBTYPE_VILLAGE;
    if ([typeStr isEqualToString:@"hamlet"])
        return CITY_SUBTYPE_HAMLET;
    if ([typeStr isEqualToString:@"suburb"])
        return CITY_SUBTYPE_SUBURB;
    if ([typeStr isEqualToString:@"district"])
        return CITY_SUBTYPE_DISTRICT;
    if ([typeStr isEqualToString:@"neighbourhood"])
        return CITY_SUBTYPE_NEIGHBOURHOOD;
    return CITY_SUBTYPE_UNKNOWN;
}

+ (CGFloat)getRadius:(NSString *)typeStr
{
    EOACitySubType type = [self getType:typeStr];
    switch (type)
    {
        case CITY_SUBTYPE_CITY:
            return 10000.;
        case CITY_SUBTYPE_TOWN:
            return 4000.;
        case CITY_SUBTYPE_VILLAGE:
            return 1300.;
        case CITY_SUBTYPE_HAMLET:
            return 1000.;
        case CITY_SUBTYPE_SUBURB:
            return 400.;
        case CITY_SUBTYPE_DISTRICT:
            return 400.;
        case CITY_SUBTYPE_NEIGHBOURHOOD:
            return 300.;
        default:
            return 1000.;
    }
}

@end
