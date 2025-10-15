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
    }
    return self;
}

-(NSString *)iconName
{
    return @"ic_action_building_number";
}

+ (NSString *)getLocalizedTypeStr:(EOACityType)type
{
    switch (type)
    {
        case CITY_TYPE_CITY:
            return OALocalizedString(@"city_type_city");
        case CITY_TYPE_TOWN:
            return OALocalizedString(@"city_type_town");
        case CITY_TYPE_VILLAGE:
            return OALocalizedString(@"city_type_village");
        case CITY_TYPE_HAMLET:
            return OALocalizedString(@"city_type_hamlet");
        case CITY_TYPE_SUBURB:
            return OALocalizedString(@"city_type_suburb");
        case CITY_TYPE_BOROUGH:
            return OALocalizedString(@"city_type_borough");
        case CITY_TYPE_CENSUS:
            return OALocalizedString(@"city_type_census");
        case CITY_TYPE_POSTCODE:
            return OALocalizedString(@"city_type_postcode");
        case CITY_TYPE_BOUNDARY:
            return OALocalizedString(@"city_type_boundary");
        case CITY_TYPE_DISTRICT:
            return OALocalizedString(@"city_type_district");
        case CITY_TYPE_NEIGHBOURHOOD:
            return OALocalizedString(@"city_type_neighbourhood");
        default:
            return OALocalizedString(@"city_type_city");
    }
}

+ (EOACityType)getType:(NSString *)typeStr;
{
    if ([typeStr isEqualToString:@"city"])
        return CITY_TYPE_CITY;
    if ([typeStr isEqualToString:@"town"])
        return CITY_TYPE_TOWN;
    if ([typeStr isEqualToString:@"village"])
        return CITY_TYPE_VILLAGE;
    if ([typeStr isEqualToString:@"hamlet"])
        return CITY_TYPE_HAMLET;
    if ([typeStr isEqualToString:@"suburb"])
        return CITY_TYPE_SUBURB;
    if ([typeStr isEqualToString:@"boundary"])
        return CITY_TYPE_BOUNDARY;
    if ([typeStr isEqualToString:@"postcode"])
        return CITY_TYPE_POSTCODE;
    if ([typeStr isEqualToString:@"borough"])
        return CITY_TYPE_BOROUGH;
    if ([typeStr isEqualToString:@"district"])
        return CITY_TYPE_DISTRICT;
    if ([typeStr isEqualToString:@"neighbourhood"])
        return CITY_TYPE_NEIGHBOURHOOD;
    if ([typeStr isEqualToString:@"census"])
        return CITY_TYPE_CENSUS;
    return CITY_TYPE_UNKNOWN;
}

+ (CGFloat)getRadius:(NSString *)typeStr
{
    EOACityType type = [self getType:typeStr];
    switch (type)
    {
        case CITY_TYPE_CITY:
            return 10000.;
        case CITY_TYPE_TOWN:
            return 4000.;
        case CITY_TYPE_VILLAGE:
            return 1300.;
        case CITY_TYPE_HAMLET:
            return 1000.;
        case CITY_TYPE_SUBURB:
            return 400.;
        case CITY_TYPE_BOUNDARY:
            return 0;
        case CITY_TYPE_POSTCODE:
            return 500.;
        case CITY_TYPE_BOROUGH:
        case CITY_TYPE_CENSUS:
        case CITY_TYPE_DISTRICT:
            return 400.;
        case CITY_TYPE_NEIGHBOURHOOD:
            return 300.;
        default:
            return 1000.;
    }
}

@end
