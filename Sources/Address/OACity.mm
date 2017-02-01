//
//  OACity.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OACity.h"

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

@end
