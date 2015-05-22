//
//  OATargetPoint.h
//  OsmAnd
//
//  Created by Alexey Kulish on 28/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM(NSInteger, OATargetPointType)
{
    OATargetLocation = 0,
    OATargetPOI,
    OATargetDestination,
    OATargetFavorite,
    OATargetParking,
};

@interface OATargetPoint : NSObject

@property (nonatomic) OATargetPointType type;
@property (nonatomic) UIImage *icon;
@property (nonatomic) CLLocationCoordinate2D location;
@property (nonatomic) NSString *title;

@property (nonatomic) NSString *phone;
@property (nonatomic) NSString *openingHours;
@property (nonatomic) NSString *url;
@property (nonatomic) NSString *desc;

@property (nonatomic) CGPoint touchPoint;
@property (nonatomic) int zoom;

@end
