//
//  OATargetPointsHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 15/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class OAPointDescription, OARTargetPoint;

@protocol OAStateChangedListener;

@interface OATargetPointsHelper : NSObject

+ (OATargetPointsHelper *) sharedInstance;

- (OARTargetPoint *) getPointToNavigate;
- (OARTargetPoint *) getPointToStart;
- (OAPointDescription *) getStartPointDescription;
- (NSArray<OARTargetPoint *> *) getIntermediatePoints;
- (NSArray<OARTargetPoint *> *) getIntermediatePointsNavigation;
- (NSArray<CLLocation *> *) getIntermediatePointsLatLon;
- (NSArray<CLLocation *> *) getIntermediatePointsLatLonNavigation;
- (NSArray<OARTargetPoint *> *) getAllPoints;
- (NSArray<OARTargetPoint *> *) getIntermediatePointsWithTarget;
- (OARTargetPoint *) getFirstIntermediatePoint;

- (void) lookupAllAddresses;

- (void) navigateToPoint:(CLLocation *)point updateRoute:(BOOL)updateRoute intermediate:(int)intermediate;
- (void) navigateToPoint:(CLLocation *)point updateRoute:(BOOL)updateRoute intermediate:(int)intermediate historyName:(OAPointDescription *)historyName;
- (void) setStartPoint:(CLLocation *)startPoint updateRoute:(BOOL)updateRoute name:(OAPointDescription *)name;
- (OARTargetPoint *)getHomePoint;
- (OARTargetPoint *)getWorkPoint;
- (void) setHomePoint:(CLLocation *) latLon description:(OAPointDescription *)name;
- (void) setWorkPoint:(CLLocation *) latLon description:(OAPointDescription *)name;

- (void) updateRouteAndRefresh:(BOOL)updateRoute;
- (void) addListener:(id<OAStateChangedListener>)l;
- (void) removeListener:(id<OAStateChangedListener>)l;
- (void) clearPointToNavigate:(BOOL)updateRoute;
- (void) clearStartPoint:(BOOL)updateRoute;
- (void) clearAllIntermediatePoints:(BOOL)updateRoute;
- (void) clearAllPoints:(BOOL)updateRoute;
- (void) reorderAllTargetPoints:(NSArray<OARTargetPoint *> *)point updateRoute:(BOOL)updateRoute;
- (void) makeWayPointDestination:(BOOL)updateRoute index:(int)index;
- (void) removeWayPoint:(BOOL)updateRoute index:(int)index;
- (void) restoreTargetPoints:(BOOL)updateRoute;
- (void) removeAllWayPoints:(BOOL)updateRoute clearBackup:(BOOL)clearBackup;
- (BOOL) checkPointToNavigateShort;

- (BOOL) hasTooLongDistanceToNavigate;

@end
