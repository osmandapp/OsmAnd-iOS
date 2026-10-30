//
//  OAAddress.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAAddress.h"
#import "Localization.h"
#import "OsmAndSharedWrapper.h"

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

- (instancetype)initWithSharedAddress:(OASMapObject *)address type:(EOAAddressType)type
{
    self = [super init];
    if (self)
    {
        _sharedAddress = address;
        _addressType = type;
        _addrId = (unsigned long long) address.id.longLongValue;
        OASKLatLon *location = [address getLocation];
        _latitude = location.latitude;
        _longitude = location.longitude;
    }
    return self;
}

- (NSString *) getName:(NSString *)lang transliterate:(BOOL)transliterate
{
    if (_sharedAddress)
        return [_sharedAddress getNameLang:lang transliterate:transliterate];
    return self.address->getName(QString::fromNSString(lang), transliterate).toNSString();
}

- (NSString *) getNameQ:(QString)lang transliterate:(BOOL)transliterate
{
    if (_sharedAddress)
        return [_sharedAddress getNameLang:lang.toNSString() transliterate:transliterate];
    return self.address->getName(lang, transliterate).toNSString();
}

- (NSString *) name
{
    if (_sharedAddress)
        return [_sharedAddress getName];
    return self.address->nativeName.toNSString();
}

- (NSDictionary<NSString *, NSString *> *) localizedNames
{
    if (_sharedAddress)
        return [_sharedAddress getNamesMapIncludeEn:YES];

    NSMutableDictionary *localizedNames = [NSMutableDictionary dictionary];
    for(const auto& entry : OsmAnd::rangeOf(OsmAnd::constOf(self.address->localizedNames)))
        [localizedNames setObject:entry.value().toNSString() forKey:entry.key().toNSString()];
    
    return localizedNames;
}

- (NSMutableArray<NSString *> *)getOtherNames:(BOOL)transliterate
{
    NSMutableArray<NSString *> *otherNames = [NSMutableArray array];
    NSString * enName = [self getName:@"en" transliterate:transliterate];
    if (enName != nil && enName.length > 0)
    {
        [otherNames addObject:enName];
    }
    if (_sharedAddress)
    {
        [self.localizedNames enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
            if (![key isEqualToString:@"admin_level"] && ![key isEqualToString:@"place"])
                [otherNames addObject:value];
        }];
        return otherNames;
    }
    for(const auto& entry : OsmAnd::rangeOf(OsmAnd::constOf(self.address->localizedNames)))
    {
        if (entry.key() == QStringLiteral("admin_level") || entry.key() == QStringLiteral("place"))
            continue;
        [otherNames addObject:entry.value().toNSString()];
    }
    return otherNames;
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
            return OALocalizedString(@"search_address_street");
        case ADDRESS_TYPE_BUILDING:
            return OALocalizedString(@"search_address_building_option");
        case ADDRESS_TYPE_STREET_INTERSECTION:
            return OALocalizedString(@"shared_string_street_intersection");
            
        default:
            return OALocalizedString(@"shared_string_address");
    }
}

@end
