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

struct RouteDataObject;

@interface OAAvoidSpecificRoads : NSObject

+ (OAAvoidSpecificRoads *) instance;

- (const QList<std::shared_ptr<RouteDataObject>>) getImpassableRoads;
- (CLLocation *) getLocation:(int64_t)roadId;
- (void) addImpassableRoad:(CLLocation *)loc skipWritingSettings:(BOOL)skipWritingSettings;
- (void) removeImpassableRoad:(const std::shared_ptr<RouteDataObject>)road;
- (std::shared_ptr<RouteDataObject>) getRoadById:(unsigned long long)id;

- (void) addListener:(id<OAStateChangedListener>)l;
- (void) removeListener:(id<OAStateChangedListener>)l;

@end
