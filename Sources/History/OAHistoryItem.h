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
    OAHistoryTypePOI,
    OAHistoryTypeAddress,
    OAHistoryTypeWpt,
    OAHistoryTypeLocation,
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

@property (nonatomic) NSString *distance;
@property (nonatomic, assign) double distanceMeters;
@property (nonatomic, assign) double direction;

- (instancetype)initWithPointDescription:(OAPointDescription *)pointDescription;

- (UIImage *)icon;
- (NSString *) getPointDescriptionType;

@end
