//
//  OAPOI.h
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OAPOIType.h"

#define OSM_REF_TAG @"ref"

@interface OAPOIRoutePoint : NSObject

@property (nonatomic) double deviateDistance;
@property (nonatomic) BOOL deviationDirectionRight;
@property (nonatomic) CLLocation *pointA;
@property (nonatomic) CLLocation *pointB;

@end

@interface OAPOI : NSObject

@property (nonatomic) unsigned long long obfId;
@property (nonatomic) NSString *name;
@property (nonatomic) OAPOIType *type;
@property (nonatomic) NSString *nameLocalized;
@property (nonatomic, assign) BOOL hasOpeningHours;
@property (nonatomic) NSString *openingHours;
@property (nonatomic) NSString *desc;
@property (nonatomic) BOOL isPlace;
@property (nonatomic) NSString *buildingNumber;

@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@property (nonatomic, assign) double distanceMeters;
@property (nonatomic) NSString *distance;
@property (nonatomic, assign) double direction;

@property (nonatomic) NSDictionary *values;
@property (nonatomic) NSDictionary *localizedNames;
@property (nonatomic) NSDictionary *localizedContent;

@property (nonatomic) OAPOIRoutePoint *routePoint;

- (UIImage *)icon;
- (NSString *)iconName;

- (BOOL) isClosed;
- (NSSet<NSString *> *)getSupportedContentLocales;
- (NSArray<NSString *> *)getNames:(NSString *)tag defTag:(NSString *)defTag;
- (NSString *) getTagContent:(NSString *)tag lang:(NSString *)lang;

- (NSDictionary<NSString *, NSString *> *) getAdditionalInfo;

@end
