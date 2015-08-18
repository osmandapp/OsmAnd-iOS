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
    OATargetNone = -1,
    OATargetLocation = 0,
    OATargetPOI,
    OATargetDestination,
    OATargetFavorite,
    OATargetParking,
    OATargetWiki,
    OATargetWpt,
    OATargetGPX,
    OATargetGPXRoute,
    OATargetGPXEdit,
};

@interface OATargetPoint : NSObject

@property (nonatomic) OATargetPointType type;
@property (nonatomic) UIImage *icon;
@property (nonatomic) CLLocationCoordinate2D location;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *titleSecond;
@property (nonatomic) NSString *titleAddress;

@property (nonatomic) NSString *phone;
@property (nonatomic) NSString *openingHours;
@property (nonatomic) NSString *url;
@property (nonatomic) NSString *desc;

@property (nonatomic) NSString *oper;
@property (nonatomic) NSString *brand;
@property (nonatomic) NSString *wheelchair;
@property (nonatomic) NSArray *fuelTags;

@property (nonatomic) NSDictionary *localizedNames;
@property (nonatomic) NSDictionary *localizedContent;

@property (nonatomic) id targetObj;

@property (nonatomic) CGPoint touchPoint;
@property (nonatomic) int zoom;

@property (nonatomic) BOOL toolbarNeeded;
@property (nonatomic) NSInteger segmentIndex;

@end
