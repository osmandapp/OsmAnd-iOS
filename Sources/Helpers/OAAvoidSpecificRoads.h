//
//  OAAvoidSpecificRoads.h
//  OsmAnd
//
//  Created by Alexey Kulish on 03/01/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#include <OsmAndCore/QtExtensions.h>
#include <QList>

#include <OsmAndCore.h>
#include <OsmAndCore/Data/Road.h>

@protocol OAStateChangedListener;

@interface OAAvoidRoadInfo : NSObject

@property (nonatomic) unsigned long long roadId;
@property (nonatomic) CLLocationCoordinate2D location;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *appModeKey;

@end

struct RouteDataObject;

@interface OAAvoidSpecificRoads : NSObject

+ (OAAvoidSpecificRoads *) instance;

- (const QList<std::shared_ptr<RouteDataObject>>) getImpassableRoads;
- (NSArray<OAAvoidRoadInfo *> *) getImpassableRoadsInfo;
- (CLLocation *) getLocation:(int64_t)roadId;
- (void) addImpassableRoad:(CLLocation *)loc skipWritingSettings:(BOOL)skipWritingSettings;
- (void) removeImpassableRoad:(const std::shared_ptr<RouteDataObject>)road;
- (std::shared_ptr<RouteDataObject>) getRoadById:(unsigned long long)id;
- (NSString *) getName:(RouteDataObject *)road loc:(CLLocation *)loc;

- (void) addListener:(id<OAStateChangedListener>)l;
- (void) removeListener:(id<OAStateChangedListener>)l;

@end
