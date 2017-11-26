//
//  OATargetPoint.h
//  OsmAnd
//
//  Created by Alexey Kulish on 28/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class OAPointDescription;

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
    OATargetHistoryItem,
    OATargetAddress,
    OATargetTurn,
    OATargetRouteStart,
    OATargetRouteFinish,
};

@interface OATargetPoint : NSObject

@property (nonatomic) OATargetPointType type;
@property (nonatomic) UIImage *icon;
@property (nonatomic) CLLocationCoordinate2D location;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *titleSecond;
@property (nonatomic) NSString *titleAddress;

@property (nonatomic) NSDictionary *values;
@property (nonatomic) NSDictionary *localizedNames;
@property (nonatomic) NSDictionary *localizedContent;

@property (nonatomic) id targetObj;

@property (nonatomic) CGPoint touchPoint;
@property (nonatomic) int zoom;

@property (nonatomic) BOOL toolbarNeeded;
@property (nonatomic) NSInteger segmentIndex;
@property (nonatomic) BOOL centerMap;
@property (nonatomic) BOOL addressFound;
@property (nonatomic) BOOL minimized;

@property (nonatomic) NSAttributedString *ctrlAttrTypeStr;
@property (nonatomic) NSString *ctrlTypeStr;

@property (nonatomic, readonly) OAPointDescription *pointDescription;

@end
