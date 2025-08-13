//
//  OAAddress.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <OsmAndCore/Data/Address.h>

typedef NS_ENUM(NSInteger, EOAAddressType)
{
    ADDRESS_TYPE_UNDEFINED = 0,
    ADDRESS_TYPE_CITY,
    ADDRESS_TYPE_STREET,
    ADDRESS_TYPE_BUILDING,
    ADDRESS_TYPE_STREET_INTERSECTION
};

@interface OAAddress : NSObject

@property (nonatomic, assign) std::shared_ptr<const OsmAnd::Address> address;

@property (nonatomic, readonly) EOAAddressType addressType;

@property (nonatomic, readonly) unsigned long long addrId;
@property (nonatomic, readonly) double latitude;
@property (nonatomic, readonly) double longitude;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> *localizedNames;

- (instancetype)initWithAddress:(const std::shared_ptr<const OsmAnd::Address>&)address;

- (NSString *) getName:(NSString *)lang transliterate:(BOOL)transliterate;
- (NSString *) getNameQ:(QString)lang transliterate:(BOOL)transliterate;

- (UIImage *)icon;
- (NSString *)iconName;

- (NSString *)getAddressTypeName;

@end
