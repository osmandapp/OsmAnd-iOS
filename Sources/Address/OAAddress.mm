//
//  OAAddress.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAAddress.h"
#import "Localization.h"
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/QKeyValueIterator.h>


@implementation OAAddress

- (instancetype)initWithAddress:(const std::shared_ptr<const OsmAnd::Address>&)address
{
    self = [super init];
    if (self)
    {
        self.address = address;
        _addressType = (EOAAddressType)address->addressType;
        _addrId = address->id;
        OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(address->position31);
        _latitude = latLon.latitude;
        _longitude = latLon.longitude;
    }
    return self;
}

- (NSString *) getName:(NSString *)lang transliterate:(BOOL)transliterate
{
    return self.address->getName(QString::fromNSString(lang), transliterate).toNSString();
}

- (NSString *) getNameQ:(QString)lang transliterate:(BOOL)transliterate
{
    return self.address->getName(lang, transliterate).toNSString();
}

- (NSString *) name
{
    return self.address->nativeName.toNSString();
}

- (NSDictionary<NSString *, NSString *> *) localizedNames
{
    NSMutableDictionary *localizedNames = [NSMutableDictionary dictionary];
    for(const auto& entry : OsmAnd::rangeOf(OsmAnd::constOf(self.address->localizedNames)))
        [localizedNames setObject:entry.value().toNSString() forKey:entry.key().toNSString()];
    
    return localizedNames;
}

- (UIImage *) icon
{
    NSString *iconName = [self iconName];
    if (iconName)
        return [UIImage templateImageNamed:iconName];
    else
        return nil;
}

-(NSString *) iconName
{
    return nil;
}

- (NSString *)getAddressTypeName
{
    switch (self.addressType)
    {
        case ADDRESS_TYPE_CITY:
            return OALocalizedString(@"city_type_city");
        case ADDRESS_TYPE_STREET:
            return OALocalizedString(@"shared_string_street");
        case ADDRESS_TYPE_BUILDING:
            return OALocalizedString(@"shared_string_building");
        case ADDRESS_TYPE_STREET_INTERSECTION:
            return OALocalizedString(@"shared_string_street_intersection");
            
        default:
            return OALocalizedString(@"shared_string_address");
    }
}

@end
