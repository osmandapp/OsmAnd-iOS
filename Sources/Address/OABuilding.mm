//
//  OABuilding.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OABuilding.h"
#import "OAStreet.h"
#import "OACity.h"

@interface OABuilding ()

@property (nonatomic) EOAAddressType addressType;

@end

@implementation OABuilding
{
    OAStreet *_street;
    OACity *_city;
}

@dynamic addressType;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.addressType = ADDRESS_TYPE_BUILDING;
    }
    return self;
}

- (instancetype)initWithBuilding:(const std::shared_ptr<const OsmAnd::Building>&)building
{
    self = [super initWithAddress:building];
    if (self)
    {
        self.building = building;
    }
    return self;
}

- (OAStreet *) street
{
    if (!_street && self.building->street)
    {
        _street = [[OAStreet alloc] initWithStreet:self.building->street];
    }
    return _street;
}

- (OACity *) city
{
    if (!_city && self.building->streetGroup)
    {
        _city = [[OACity alloc] initWithCity:self.building->streetGroup];
    }
    return _city;
}

- (NSString *) postcode
{
    return self.building->postcode.toNSString();
}

- (NSString *) iconName
{
    return @"ic_action_building";
}

@end
