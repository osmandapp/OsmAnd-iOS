//
//  OAHistoryItem.h
//  OsmAnd
//
//  Created by Alexey Kulish on 05/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAPointDescription;

@interface OAHistoryItem : NSObject

typedef NS_ENUM(NSInteger, OAHistoryType)
{
    OAHistoryTypeUnknown = -1,
    OAHistoryTypeDirection,
    OAHistoryTypeParking,
    OAHistoryTypeRouteWpt,
    OAHistoryTypeFavorite,
    OAHistoryTypePOI NS_SWIFT_NAME(poi),
    OAHistoryTypeAddress,
    OAHistoryTypeWpt,
    OAHistoryTypeLocation,
    OAHistoryTypePoiType,
    OAHistoryTypePoiFilter,
};

@property (nonatomic) int64_t hId;
@property (nonatomic) int64_t hHash;

@property (nonatomic) double latitude;
@property (nonatomic) double longitude;

@property (nonatomic) NSDate *date;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *iconName;
@property (nonatomic) NSString *typeName;

@property (nonatomic) OAHistoryType hType;
@property (nonatomic, assign) BOOL fromNavigation;

@property (nonatomic) NSString *objectType;
@property (nonatomic) NSString *cityType;
@property (nonatomic) NSString *displayName;
@property (nonatomic) NSString *poiCategoryKey;
@property (nonatomic) NSString *poiSubtypeKey;
@property (nonatomic) NSString *address;
@property (nonatomic) NSString *relatedObjectName;
@property (nonatomic) NSString *openingHours;
@property (nonatomic) NSString *alternateName;
@property (nonatomic) NSString *photoUrl;
@property (nonatomic) NSNumber *osmId;

@property (nonatomic) NSString *distance;
@property (nonatomic, assign) double distanceMeters;
@property (nonatomic, assign) double direction;

+ (NSArray<NSString *> *)metadataKeys;

- (instancetype)initWithPointDescription:(OAPointDescription *)pointDescription;

- (BOOL)fillMissingMetadataFrom:(OAHistoryItem *)item;

- (UIImage *)icon;
- (NSString *) getPointDescriptionType;
- (BOOL)hasLocation;

- (float)preferredZoom;

@end
