//
//  OAAddress.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <OsmAndCore/Data/Address.h>

@class OASMapObject;

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

// The same address out of the shared search, which the getters read instead of the C++ one
@property (nonatomic, readonly) OASMapObject *sharedAddress;

@property (nonatomic, readonly) EOAAddressType addressType;

@property (nonatomic, readonly) unsigned long long addrId;
@property (nonatomic, readonly) double latitude;
@property (nonatomic, readonly) double longitude;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSDictionary<NSString *, NSString *> *localizedNames;

- (instancetype)initWithAddress:(const std::shared_ptr<const OsmAnd::Address>&)address;
- (instancetype)initWithSharedAddress:(OASMapObject *)address type:(EOAAddressType)type;

- (NSString *) getName:(NSString *)lang transliterate:(BOOL)transliterate;
- (NSString *) getNameQ:(QString)lang transliterate:(BOOL)transliterate;

- (UIImage *)icon;
- (NSString *)iconName;

- (NSString *)getAddressTypeName;
- (NSMutableArray<NSString *> *)getOtherNames:(BOOL)transliterate;

@end
