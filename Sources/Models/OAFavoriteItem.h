//
//  OAFavoriteItem.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 07.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OALocationPoint.h"
#include <OsmAndCore/IFavoriteLocation.h>

#define EXTENSION_HIDDEN @"hidden"

@class OAWptPt;

@interface OASpecialPointType : NSObject

- (instancetype)initWithTypeName:(NSString *)typeName resId:(NSString *)resId iconName:(NSString *)iconName;
+ (OASpecialPointType *) HOME;
+ (OASpecialPointType *) WORK;
+ (OASpecialPointType *) PARKING;
+ (NSArray<OASpecialPointType *> *) VALUES;
- (NSString *) getCategory;
- (NSString *) getName;
- (NSString *) getIconName;
- (UIColor *) getIconColor;
- (NSString *) getHumanString;

@end


@interface OAFavoriteItem : NSObject<OALocationPoint>

@property std::shared_ptr<OsmAnd::IFavoriteLocation> favorite;
@property CGFloat direction;
@property NSString* distance;
@property double distanceMeters;
@property OASpecialPointType *specialPointType;

- (instancetype)initWithFavorite:(std::shared_ptr<OsmAnd::IFavoriteLocation>)favorite;
- (instancetype)initWithLat:(double)lat lon:(double)lon name:(NSString *)name category:(NSString *)catagory;
- (instancetype)initWithLat:(double)lat lon:(double)lon name:(NSString *)name category:(NSString *)category altitude:(double)altitude timestamp:(NSDate *)timestamp;

- (void) initPersonalType;
- (BOOL) isSpecialPoint;
- (BOOL) isAddressSpecified;

- (NSString *) getOverlayIconName;
- (void) setLat:(double)lat lon:(double)lon;

- (NSString *) getName;
- (NSString *) getDisplayName;
- (void) setName:(NSString *)name;

- (NSString *) getDescription;
- (void) setDescription:(NSString *)description;

- (NSString *) getAddress;
- (void) setAddress:(NSString *)address;

- (NSString *) getIcon;
- (void) setIcon:(NSString *)icon;

- (NSString *) getBackgroundIcon;
- (void) setBackgroundIcon:(NSString *)backgroundIcon;

- (UIColor *) getColor;
- (void) setColor:(UIColor *)color;

- (BOOL) isVisible;
- (void) setVisible:(BOOL)isVisible;

- (NSString *) getCategory;
- (NSString *) getCategoryDisplayName;
- (void) setCategory:(NSString *)category;

- (void) initAltitude;
- (double) getAltitude;
- (void) setAltitude:(double)altitude;

- (NSDate *) getTimestamp;
- (void) setTimestamp:(NSDate *)timestamp;

- (NSDate *) getCreationTime;
- (void) setCreationTime:(NSDate *)timestamp;

- (bool) getCalendarEvent;
- (void) setCalendarEvent:(BOOL)calendarEvent;

+ (NSString *) toStringDate:(NSDate *)date;

- (OAWptPt *) toWpt;

- (UIImage *) getCompositeIcon;

@end
