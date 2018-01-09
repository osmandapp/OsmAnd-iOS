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

@interface OAAvoidSpecificRoads : NSObject

+ (OAAvoidSpecificRoads *) instance;

- (const QList<std::shared_ptr<const OsmAnd::Road>>) getImpassableRoads;
- (CLLocation *) getLocation:(const std::shared_ptr<const OsmAnd::Road>)road;
- (void) addImpassableRoad:(CLLocation *)loc showDialog:(BOOL)showDialog skipWritingSettings:(BOOL)skipWritingSettings;
- (void) removeImpassableRoad:(const std::shared_ptr<const OsmAnd::Road>)road;
- (std::shared_ptr<const OsmAnd::Road>) getRoadById:(unsigned long long)id;

- (void) addListener:(id<OAStateChangedListener>)l;
- (void) removeListener:(id<OAStateChangedListener>)l;

@end
