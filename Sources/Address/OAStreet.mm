//
//  OAStreet.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAStreet.h"
#import "OACity.h"
#import "GeneratedAssetSymbols.h"
#import "OsmAndSharedWrapper.h"

@interface OAStreet ()

@property (nonatomic) EOAAddressType addressType;

@end

@implementation OAStreet
{
    OACity *_city;
}

@dynamic addressType;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.addressType = ADDRESS_TYPE_STREET;
    }
    return self;
}

- (instancetype)initWithStreet:(const std::shared_ptr<const OsmAnd::Street>&)street;
{
    self = [super initWithAddress:street];
    if (self)
    {
        self.street = street;
    }
    return self;
}

- (instancetype)initWithSharedStreet:(OASStreet *)street
{
    self = [super initWithSharedAddress:street type:ADDRESS_TYPE_STREET];
    if (self)
    {
        _sharedStreet = street;
    }
    return self;
}

- (OACity *) city
{
    if (!_city && _sharedStreet)
    {
        OASCity *city = [_sharedStreet getCity];
        if (city)
            _city = [[OACity alloc] initWithSharedCity:city];
    }
    else if (!_city && self.street->streetGroup)
    {
        _city = [[OACity alloc] initWithCity:self.street->streetGroup];
    }
    return _city;
}

-(NSString *)iconName
{
    return ACImageNameIcActionStreetName;
}

@end
