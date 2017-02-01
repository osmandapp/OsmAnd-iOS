//
//  OAStreetIntersection.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAStreetIntersection.h"
#import "OAStreet.h"

@interface OAStreetIntersection ()

@property (nonatomic) EOAAddressType addressType;

@end

@implementation OAStreetIntersection
{
    OAStreet *_street;
}

@dynamic addressType;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.addressType = ADDRESS_TYPE_STREET_INTERSECTION;
    }
    return self;
}

- (instancetype)initWithStreetIntersection:(const std::shared_ptr<const OsmAnd::StreetIntersection>&)streetIntersection;
{
    self = [super initWithAddress:streetIntersection];
    if (self)
    {
        self.streetIntersection = streetIntersection;
    }
    return self;
}

- (OAStreet *) street
{
    if (!_street && self.streetIntersection->street)
    {
        _street = [[OAStreet alloc] initWithStreet:self.streetIntersection->street];
    }
    return _street;
}

-(NSString *)iconName
{
    return @"ic_action_intersection";
}

@end
